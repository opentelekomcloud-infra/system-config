"""
Keycloak Inactive User Scanner
--------------------------------
Features:
- Uses /events API (LOGIN events)
- Detects per-client inactivity
- Identifies user source (ldap, github, local)
- Pagination support
- Optional filtering by source (--ldap/--github/--local)
- Optional disable mode (--disable-users)
- Optional dry-run mode (--dry-run)
- Optional username exclusion (--exclude)
"""

import os
import requests
import argparse
from datetime import datetime, timedelta

# Load Keycloak configuration from environment variables
KEYCLOAK_URL = os.getenv('KEYCLOAK_URL')
REALM_NAME = os.getenv('REALM_NAME')
CLIENT_ID = os.getenv('CLIENT_ID')
CLIENT_SECRET = os.getenv('CLIENT_SECRET')
USERNAME = os.getenv('KEYCLOAK_USERNAME')
PASSWORD = os.getenv('KEYCLOAK_PASSWORD')
GRANT_TYPE = os.getenv('GRANT_TYPE')

INACTIVITY_THRESHOLD = 35
PAGE_SIZE = 100


# ------------------------------
# Authentication
# ------------------------------

def get_access_token():
    """Obtain an admin access token using password grant."""
    url = f"{KEYCLOAK_URL}/realms/{REALM_NAME}/protocol/openid-connect/token"
    data = {
        'client_id': CLIENT_ID,
        'client_secret': CLIENT_SECRET,
        'username': USERNAME,
        'password': PASSWORD,
        'grant_type': GRANT_TYPE,
    }
    r = requests.post(url, data=data)
    r.raise_for_status()
    return r.json()['access_token']


# ------------------------------
# User Fetching
# ------------------------------

def get_users(access_token, page):
    """Retrieve a page of users (pagination enabled)."""
    url = f"{KEYCLOAK_URL}/admin/realms/{REALM_NAME}/users"
    headers = {'Authorization': f'Bearer {access_token}'}
    params = {'first': page * PAGE_SIZE, 'max': PAGE_SIZE}
    r = requests.get(url, headers=headers, params=params)
    r.raise_for_status()
    return r.json()


def get_user_details(user_id, access_token):
    """Retrieve full user details including federatedIdentities."""
    url = f"{KEYCLOAK_URL}/admin/realms/{REALM_NAME}/users/{user_id}"
    headers = {'Authorization': f'Bearer {access_token}'}
    r = requests.get(url, headers=headers)
    r.raise_for_status()
    return r.json()


# ------------------------------
# Event API: Login events
# ------------------------------

def get_user_login_events(user_id, access_token):
    """Fetch all LOGIN events for a user from /events API."""
    url = f"{KEYCLOAK_URL}/admin/realms/{REALM_NAME}/events"
    headers = {'Authorization': f'Bearer {access_token}'}
    params = {'type': 'LOGIN', 'user': user_id}
    r = requests.get(url, headers=headers, params=params)
    r.raise_for_status()
    return r.json()


# ------------------------------
# Helpers
# ------------------------------

def epoch_to_datetime(epoch_ms):
    """Convert Keycloak event epoch-milliseconds to human-readable UTC."""
    return datetime.utcfromtimestamp(epoch_ms / 1000).strftime('%Y-%m-%d %H:%M:%S')


def is_user_inactive(user_id, access_token):
    """
    Determine inactivity per client from LOGIN events.
    Returns: (all_clients_inactive, inactive_clients_set)
    """
    events = get_user_login_events(user_id, access_token)
    all_clients_inactive = True
    inactive_clients = set()

    for event in events:
        client = event['clientId']
        dt = datetime.utcfromtimestamp(event['time'] / 1000)

        if dt >= datetime.utcnow() - timedelta(days=INACTIVITY_THRESHOLD):
            all_clients_inactive = False
        else:
            inactive_clients.add(client)

    return all_clients_inactive, inactive_clients


def disable_user(user_id, access_token):
    """Disable a Keycloak user."""
    url = f"{KEYCLOAK_URL}/admin/realms/{REALM_NAME}/users/{user_id}"
    headers = {'Authorization': f'Bearer {access_token}', 'Content-Type': 'application/json'}
    r = requests.put(url, json={'enabled': False}, headers=headers)
    r.raise_for_status()


def get_user_source(user_data, access_token):
    """
    Determine user source:
    - LDAP if LDAP_ENTRY_DN attribute present
    - GitHub if federatedIdentities contains github
    - Otherwise local
    """
    if 'attributes' in user_data and 'LDAP_ENTRY_DN' in user_data['attributes']:
        return 'ldap'

#     if 'federatedIdentities' in user_data:
#         for fi in user_data['federatedIdentities']:
#             if fi['identityProvider'] == 'github':
#                 return 'github'

    details = get_user_details(user_data['id'], access_token)
    if 'federatedIdentities' in details:
        for fi in details['federatedIdentities']:
            if fi['identityProvider'] == 'github':
                return 'github'

    return 'local'


# ------------------------------
# Main Logic
# ------------------------------

def check_inactive_users(show_logged_in_only, disable_users, dry_run,
                         user_sources, exclude_usernames):

    access_token = get_access_token()

    # Load all users with pagination
    users = []
    page = 0
    while True:
        batch = get_users(access_token, page)
        if not batch:
            break
        users.extend(batch)
        page += 1

    active_count = 0
    inactive_count = 0
    disabled_count = 0

    print(f"Scanning for inactivity > {INACTIVITY_THRESHOLD} days...\n")

    for user in users:
        user_id = user['id']
        username = user['username']

        # Apply exclusion if disabling
        if disable_users and username in exclude_usernames:
            continue

        events = get_user_login_events(user_id, access_token)

        # Logged-in-only filter
        if show_logged_in_only and not events:
            continue

        # Detect source (ldap/github/local)
        user_source = get_user_source(user, access_token)

        # Apply source filter
        if user_sources and user_source not in user_sources:
            continue

        # Determine inactivity
        all_inactive, inactive_clients = is_user_inactive(user_id, access_token)
        status = "INACTIVE" if all_inactive else "ACTIVE"

        if status == "ACTIVE":
            active_count += 1
        else:
            inactive_count += 1

        # Compute last login human readable timestamp
        last_login = "Never"
        if events:
            last_event = max(events, key=lambda e: e['time'])
            last_login = epoch_to_datetime(last_event['time'])

        # Disable logic
        if disable_users and all_inactive and events:

            # Skip if already disabled — no need to disable again
            if user.get("enabled") is False:
                continue

            if dry_run:
                print(
                    f"{username} | {user.get('firstName','N/A')} {user.get('lastName','N/A')} | "
                    f"Enabled: {user.get('enabled')} | Last login: {last_login} | Status: {status} | "
                    f"Inactive Clients: {', '.join(sorted(inactive_clients)) or 'Across all clients'} | "
                    f"User Source: {user_source}"
                )
                print(f"[DRY-RUN] {username} | Last login: {last_login} | Source: {user_source} | Would be disabled")
            else:
                disable_user(user_id, access_token)
                disabled_count += 1
                print(
                    f"{username} | {user.get('firstName','N/A')} {user.get('lastName','N/A')} | "
                    f"Enabled: {user.get('enabled')} | Last login: {last_login} | Status: {status} | "
                    f"Inactive Clients: {', '.join(sorted(inactive_clients)) or 'Across all clients'} | "
                    f"User Source: {user_source}"
                )
                print(f"[DISABLED] {username} | Last login: {last_login} | Source: {user_source}")
            continue

        # When disabling mode active: do not print non-disabled users
        if disable_users:
            continue

        print(
            f"{username} | {user.get('firstName','N/A')} {user.get('lastName','N/A')} | "
            f"Enabled: {user.get('enabled')} | Last login: {last_login} | Status: {status} | "
            f"Inactive Clients: {', '.join(sorted(inactive_clients)) or 'Across all clients'} | "
            f"User Source: {user_source}"
        )

    # Summary
    print("\nSummary:")
    print(f"Total Users Scanned: {len(users)}")
    print(f"Active Users: {active_count}")
    print(f"Inactive Users: {inactive_count}")
    if disable_users:
        print(f"Users Disabled: {disabled_count}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Keycloak inactive-user scanner.")

    parser.add_argument('--logged-in', action='store_true', help="Only users who logged in at least once.")
    parser.add_argument('--disable-users', action='store_true', help="Disable users inactive > threshold.")
    parser.add_argument('--dry-run', action='store_true', help="Simulate disabling.")
    parser.add_argument('--ldap', action='store_true', help="Only process LDAP users.")
    parser.add_argument('--github', action='store_true', help="Only process GitHub users.")
    parser.add_argument('--local', action='store_true', help="Only process local users.")
    parser.add_argument('--exclude', type=str, help="Comma-separated usernames to exclude from disabling.")

    args = parser.parse_args()

    if args.exclude and not args.disable_users:
        print("ERROR: --exclude requires --disable-users.")
        exit(1)

    # Build user source filter
    user_sources = set(filter(None, [
        "ldap" if args.ldap else None,
        "github" if args.github else None,
        "local" if args.local else None
    ]))
    if not user_sources:
        user_sources = None

    exclude_usernames = set()
    if args.exclude:
        exclude_usernames = {u.strip() for u in args.exclude.split(',') if u.strip()}

    check_inactive_users(
        args.logged_in,
        args.disable_users,
        args.dry_run,
        user_sources,
        exclude_usernames
    )
