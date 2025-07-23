import os
import yaml
import subprocess
import glob
import json
import re
import logging
from packaging import version

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)


def get_latest_chart_version(chart_name, repo_url):
    """
    Get the latest version of a chart from the specified Helm repository
    """
    try:
        # Generate random repo name before checking out
        repo_name = f"temp-{chart_name.replace('/', '-')}-{hash(repo_url) % 10000}"

        # Checkout onto this repo
        subprocess.run(
            ['helm', 'repo', 'add', repo_name, repo_url],
            check=True, capture_output=True, text=True
        )
        subprocess.run(['helm', 'repo', 'update'], check=True, capture_output=True, text=True)

        # Now add chart name
        chart_full_name = f"{repo_name}/{chart_name}"

        # Search chart in repo
        result = subprocess.run(
            ['helm', 'search', 'repo', chart_full_name, '-o', 'json'],
            check=True, capture_output=True, text=True
        )

        charts = json.loads(result.stdout)
        if charts:
            # Get latest version of helm chart
            latest_version = charts[0]['version']

            # Remove temp repo
            subprocess.run(['helm', 'repo', 'remove', repo_name], check=True, capture_output=True, text=True)

            return latest_version

        # Remove repo even if there are no results
        subprocess.run(['helm', 'repo', 'remove', repo_name], check=True, capture_output=True, text=True)

    except Exception as e:
        logging.error("Error in get chart name %s for repo %s: %s", chart_name, repo_url, str(e))
        try:
            # Anyway remove temp repo!
            subprocess.run(['helm', 'repo', 'remove', repo_name], capture_output=True, text=True)
        except:
            pass

    return None


def compare_versions(current, latest):
    """
    Compare current version of helm chart and latest from repo
    True if there is an update, False if not
    """
    if not current or not latest:
        return False

    try:
        # Remove quotation marks
        current = current.strip('"\'')
        latest = latest.strip('"\'')

        return version.parse(latest) > version.parse(current)
    except Exception as e:
        logging.error("Error in version comparison %s and %s: %s", current, latest, str(e))
        return False


def check_helm_dependencies():
    chart_path = os.environ.get('CHART_PATH', 'kubernetes/argocd-apps/system')

    # Recursive search in kubernetes/argocd-apps/system
    chart_files = glob.glob(f'{chart_path}/**/Chart.yaml', recursive=True)
    logging.info("Found %s files Chart.yaml in %s", len(chart_files), chart_path)

    has_updates = False
    app_updates = {}

    for chart_file in chart_files:
        # Get app name
        app_name = os.path.basename(os.path.dirname(chart_file))

        try:
            with open(chart_file, 'r') as f:
                chart_data = yaml.safe_load(f)

            if 'dependencies' not in chart_data or not chart_data['dependencies']:
                continue

            chart_name = chart_data.get('name', app_name)

            logging.info("Checking dependencies in %s for %s...", chart_name, app_name)

            app_dependencies_updates = []

            for dependency in chart_data['dependencies']:
                dep_name = dependency.get('name')
                current_version = dependency.get('version')
                repository = dependency.get('repository')

                if not dep_name or not current_version or not repository:
                    continue

                logging.info("Checking %s@%s from %s", dep_name, current_version, repository)

                latest_version = get_latest_chart_version(dep_name, repository)

                if latest_version:
                    logging.info("Latest version is: %s", latest_version)

                    if compare_versions(current_version, latest_version):
                        logging.info("Update is available: %s %s -> %s", dep_name, current_version, latest_version)

                        app_dependencies_updates.append({
                            'name': dep_name,
                            'current_version': current_version,
                            'latest_version': latest_version,
                            'file_path': chart_file,
                        })
                    else:
                        logging.info("Latest version of helm chart is already there! %s@%s", dep_name, current_version)
                else:
                    logging.info("No info about latest version of %s", dep_name)

            if app_dependencies_updates:
                has_updates = True
                if app_name not in app_updates:
                    app_updates[app_name] = {
                        'chart_name': chart_name,
                        'updates': app_dependencies_updates
                    }

        except Exception as e:
            logging.error("Error parsing %s: %s", chart_file, str(e))

    # Dict to list
    app_updates_list = []
    for app_name, data in app_updates.items():
        app_updates_list.append({
            'app_name': app_name,
            'chart_name': data['chart_name'],
            'updates': data['updates']
        })

    return has_updates, app_updates_list


def update_chart_dependencies_for_app(app_data):
    """
    Universal function to update chart dependencies
    Works with both quoted and unquoted versions
    """
    updates = app_data['updates']

    for dep in updates:
        file_path = dep['file_path']
        current_version = str(dep['current_version']).strip('"\'')  # Remove quotes for comparison
        latest_version = str(dep['latest_version']).strip('"\'')  # Remove quotes for comparison

        try:
            with open(file_path, 'r') as f:
                content = f.read()

            logging.info("Updating %s from %s to %s in %s", dep['name'], current_version, latest_version, file_path)

            # Try multiple patterns to find and replace version
            patterns_tried = []
            updated = False

            # Pattern 1: Version with double quotes
            pattern1 = fr'(\s*version:\s*")({re.escape(current_version)})(")'
            if re.search(pattern1, content):
                content = re.sub(pattern1, fr'\1{latest_version}\3', content)
                updated = True
                patterns_tried.append('double quotes')

            # Pattern 2: Version with single quotes
            if not updated:
                pattern2 = fr"(\s*version:\s*')({re.escape(current_version)})(')"
                if re.search(pattern2, content):
                    content = re.sub(pattern2, fr'\1{latest_version}\3', content)
                    updated = True
                    patterns_tried.append('single quotes')

            # Pattern 3: Version without quotes
            if not updated:
                pattern3 = fr'(\s*version:\s*)({re.escape(current_version)})(\s*$)'
                if re.search(pattern3, content, re.MULTILINE):
                    content = re.sub(pattern3, fr'\1{latest_version}\3', content, flags=re.MULTILINE)
                    updated = True
                    patterns_tried.append('no quotes')

            # Pattern 4: Version without quotes followed by other content
            if not updated:
                pattern4 = fr'(\s*version:\s*)({re.escape(current_version)})(\s+)'
                if re.search(pattern4, content):
                    content = re.sub(pattern4, fr'\1{latest_version}\3', content)
                    updated = True
                    patterns_tried.append('no quotes with whitespace')

            # Pattern 5: Fallback - simple string replacement with context
            if not updated:
                # Look for the dependency block and replace version within it
                dependency_pattern = fr'(- name:\s*{re.escape(dep["name"])}\s*(?:\n|.)*?version:\s*)(["\']?)({re.escape(current_version)})(["\']?)'
                if re.search(dependency_pattern, content, re.MULTILINE | re.DOTALL):
                    def replace_func(match):
                        prefix = match.group(1)
                        open_quote = match.group(2)
                        version_value = match.group(3)
                        close_quote = match.group(4)
                        return f"{prefix}{open_quote}{latest_version}{close_quote}"

                    content = re.sub(dependency_pattern, replace_func, content, flags=re.MULTILINE | re.DOTALL)
                    updated = True
                    patterns_tried.append('dependency block pattern')

            if updated:
                with open(file_path, 'w') as f:
                    f.write(content)
                logging.info("Version has been updated for %s in %s (used pattern: %s)",
                             dep['name'], file_path, ', '.join(patterns_tried))
            else:
                logging.error("Could not find version pattern for %s (current: %s) in %s",
                              dep['name'], current_version, file_path)
                # Debug output
                logging.debug("File content around dependency:")
                lines = content.split('\n')
                for i, line in enumerate(lines):
                    if dep['name'] in line or current_version in line:
                        start = max(0, i - 2)
                        end = min(len(lines), i + 3)
                        for j in range(start, end):
                            marker = " --> " if j == i else "     "
                            logging.debug("%s%d: %s", marker, j + 1, lines[j])

        except Exception as e:
            logging.error("Error during update %s in %s: %s", dep['name'], file_path, str(e))


def main():
    has_updates, app_updates_list = check_helm_dependencies()

    if has_updates and app_updates_list:
        logging.info("Found updates for %s applications", len(app_updates_list))

        for app_data in app_updates_list:
            app_name = app_data['app_name']
            logging.info("Updating dependencies for %s...", app_name)
            update_chart_dependencies_for_app(app_data)

        # Create simple PR description
        summary_lines = ["# Helm Chart Dependencies Updates\n"]

        for app_data in app_updates_list:
            app_name = app_data['app_name']
            chart_name = app_data['chart_name']

            summary_lines.append(f"### {app_name} ({chart_name})")

            for update in app_data['updates']:
                summary_lines.append(f"- `{update['name']}`: {update['current_version']} → {update['latest_version']}")

            summary_lines.append("")

        summary_lines.append("Automatically created PR for helm chart dependencies updates. Please check before merge!")

        # Convert to JSON for safe passing to GitHub Actions
        update_summary_json = json.dumps("\n".join(summary_lines))

        # Output information for GitHub Actions
        with open(os.environ.get('GITHUB_OUTPUT', '/dev/null'), 'a') as f:
            f.write("has_updates=true\n")
            f.write(f"update_summary={update_summary_json}\n")

    else:
        logging.info("All Helm chart dependencies are up to date.")

        with open(os.environ.get('GITHUB_OUTPUT', '/dev/null'), 'a') as f:
            f.write("has_updates=false\n")


if __name__ == "__main__":
    main()
