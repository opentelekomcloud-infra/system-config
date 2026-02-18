#!/bin/bash
# Run linters only on files changed in the current change/PR.
#
# In Zuul's check pipeline, the repo is checked out with the change
# applied as a commit on top of the target branch. Therefore
# `git diff --name-only HEAD~1` gives exactly the files changed in
# the PR vs the target branch.
#
# Set FULL_LINT=1 to force linting the entire repository.

set -eo pipefail

ROOT=$(readlink -fn "$(dirname "$0")/..")
cd "$ROOT"

# ── Determine changed files ────────────────────────────────────────
if [ "${FULL_LINT:-0}" = "1" ]; then
    echo "*** FULL_LINT=1 — running linters against entire repository ***"
    FULL=1
elif git rev-parse HEAD~1 >/dev/null 2>&1; then
    DIFF_FILES=$(git diff --name-only --diff-filter=ACMR HEAD~1 || true)
    if [ -z "$DIFF_FILES" ]; then
        echo "No files changed. Nothing to lint."
        exit 0
    fi
    echo "=== Files changed in this PR ==="
    echo "$DIFF_FILES"
    echo "================================="
    FULL=0
else
    echo "*** Cannot determine parent commit — running full lint ***"
    FULL=1
fi

ERRORS=0

# ── Helper: filter changed files by pattern ────────────────────────
changed() {
    # Usage: changed 'regex-pattern'
    # Prints matching changed files, one per line.
    echo "$DIFF_FILES" | grep -E "$1" || true
}

# ── 1. flake8 (Python) ─────────────────────────────────────────────
if [ "$FULL" = "1" ]; then
    echo "=== Running flake8 (full) ==="
    flake8 || ERRORS=$((ERRORS + 1))
else
    PY_FILES=$(changed '\.py$')
    if [ -n "$PY_FILES" ]; then
        echo "=== Running flake8 on changed Python files ==="
        echo "$PY_FILES" | xargs flake8 || ERRORS=$((ERRORS + 1))
    else
        echo "=== Skipping flake8 (no Python files changed) ==="
    fi
fi

# ── 2. bashate (Shell scripts) ─────────────────────────────────────
if [ "$FULL" = "1" ]; then
    echo "=== Running bashate (full) ==="
    "$ROOT/tools/run-bashate.sh" || ERRORS=$((ERRORS + 1))
else
    SH_FILES=$(changed '\.(sh)$|rc$|functions')
    if [ -n "$SH_FILES" ]; then
        echo "=== Running bashate on changed shell files ==="
        echo "$SH_FILES" | xargs bashate -i E006 -v || ERRORS=$((ERRORS + 1))
    else
        echo "=== Skipping bashate (no shell files changed) ==="
    fi
fi

# ── 3. check_clouds_yaml ───────────────────────────────────────────
if [ "$FULL" = "1" ]; then
    echo "=== Running check_clouds_yaml ==="
    python3 "$ROOT/tools/check_clouds_yaml.py" || ERRORS=$((ERRORS + 1))
else
    CLOUD_FILES=$(changed 'clouds.*\.yaml')
    if [ -n "$CLOUD_FILES" ]; then
        echo "=== Running check_clouds_yaml (cloud config changed) ==="
        python3 "$ROOT/tools/check_clouds_yaml.py" || ERRORS=$((ERRORS + 1))
    else
        echo "=== Skipping check_clouds_yaml (no cloud configs changed) ==="
    fi
fi

# ── 4. Ansible inventory validation ────────────────────────────────
if [ "$FULL" = "1" ]; then
    echo "=== Running Ansible inventory validation ==="
    ANSIBLE_INVENTORY_PLUGINS=./playbooks/roles/install-ansible/files/inventory_plugins \
        ansible -i ./inventory/base/hosts.yaml not_a_host -a 'true' || ERRORS=$((ERRORS + 1))
else
    INV_FILES=$(changed 'inventory/|inventory_plugins/')
    if [ -n "$INV_FILES" ]; then
        echo "=== Running Ansible inventory validation (inventory files changed) ==="
        ANSIBLE_INVENTORY_PLUGINS=./playbooks/roles/install-ansible/files/inventory_plugins \
            ansible -i ./inventory/base/hosts.yaml not_a_host -a 'true' || ERRORS=$((ERRORS + 1))
    else
        echo "=== Skipping Ansible inventory validation (no inventory files changed) ==="
    fi
fi

# ── 5. Inventory plugin unit tests ─────────────────────────────────
if [ "$FULL" = "1" ]; then
    echo "=== Running inventory plugin unit tests ==="
    python3 -m unittest playbooks/roles/install-ansible/files/inventory_plugins/test_yamlgroup.py \
        || ERRORS=$((ERRORS + 1))
else
    PLUGIN_FILES=$(changed 'inventory_plugins/')
    if [ -n "$PLUGIN_FILES" ]; then
        echo "=== Running inventory plugin unit tests (plugin files changed) ==="
        python3 -m unittest playbooks/roles/install-ansible/files/inventory_plugins/test_yamlgroup.py \
            || ERRORS=$((ERRORS + 1))
    else
        echo "=== Skipping inventory plugin unit tests (no plugin files changed) ==="
    fi
fi

# ── 6. yamllint (Kubernetes YAML) ──────────────────────────────────
if [ "$FULL" = "1" ]; then
    echo "=== Running yamllint (full) ==="
    yamllint kubernetes/ || ERRORS=$((ERRORS + 1))
else
    # Only lint kubernetes/ YAML files, excluding Helm templates
    # (consistent with .yamllint ignore pattern)
    K8S_YAML=$(changed '^kubernetes/.*\.(yaml|yml)$' | grep -v '/templates/' || true)
    if [ -n "$K8S_YAML" ]; then
        echo "=== Running yamllint on changed Kubernetes YAML files ==="
        echo "$K8S_YAML" | xargs yamllint || ERRORS=$((ERRORS + 1))
    else
        echo "=== Skipping yamllint (no Kubernetes YAML files changed) ==="
    fi
fi

# ── Summary ─────────────────────────────────────────────────────────
echo ""
if [ "$ERRORS" -gt 0 ]; then
    echo "=== FAILED: $ERRORS linter(s) reported errors ==="
    exit 1
fi
echo "=== All linters passed ==="
exit 0
