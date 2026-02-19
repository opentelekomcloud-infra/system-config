#!/bin/bash
set -e

# Sync Zuul container images from upstream to opentelekomcloud registry
# Using skopeo - works on any architecture (including ARM64 Mac)

ZUUL_VERSION="13.1.1"
NODEPOOL_VERSION="11.0.0"  # Nodepool has different versioning
STORAGE_PROXY_VERSION="latest"  # zuul-storage-proxy uses latest tag

# Check if skopeo is available
if ! command -v skopeo &> /dev/null; then
    echo "Error: skopeo is not installed"
    echo "Install with: brew install skopeo (macOS) or apt install skopeo (Linux)"
    exit 1
fi

# Login to quay.io first (required for push)
echo "Please login to quay.io first:"
echo "  skopeo login quay.io"
echo ""
read -p "Press enter when ready..."

echo ""
echo "=== Syncing Zuul images version ${ZUUL_VERSION} ==="
echo ""

# Zuul components
for component in zuul-executor zuul-scheduler zuul-merger zuul-web; do
    echo "Syncing ${component}:${ZUUL_VERSION}..."

    skopeo copy --multi-arch all \
        docker://quay.io/zuul-ci/${component}:${ZUUL_VERSION} \
        docker://quay.io/opentelekomcloud/${component}:${ZUUL_VERSION}

    echo "✓ ${component}:${ZUUL_VERSION} synced"
    echo ""
done

echo "=== Syncing Nodepool images version ${NODEPOOL_VERSION} ==="
echo ""

# Nodepool components
for component in nodepool-launcher nodepool-builder; do
    echo "Syncing ${component}:${NODEPOOL_VERSION}..."

    skopeo copy --multi-arch all \
        docker://quay.io/zuul-ci/${component}:${NODEPOOL_VERSION} \
        docker://quay.io/opentelekomcloud/${component}:${NODEPOOL_VERSION}

    echo "✓ ${component}:${NODEPOOL_VERSION} synced"
    echo ""
done

echo "=== Syncing zuul-storage-proxy:${STORAGE_PROXY_VERSION} ==="
echo ""

skopeo copy --multi-arch all \
    docker://quay.io/zuul-ci/zuul-storage-proxy:${STORAGE_PROXY_VERSION} \
    docker://quay.io/opentelekomcloud/zuul-storage-proxy:${STORAGE_PROXY_VERSION}

echo "✓ zuul-storage-proxy:${STORAGE_PROXY_VERSION} synced"
echo ""

echo "=== All images synced successfully ==="
echo ""
echo "Images synced:"
echo "  - zuul-executor:${ZUUL_VERSION}"
echo "  - zuul-scheduler:${ZUUL_VERSION}"
echo "  - zuul-merger:${ZUUL_VERSION}"
echo "  - zuul-web:${ZUUL_VERSION}"
echo "  - nodepool-launcher:${NODEPOOL_VERSION}"
echo "  - nodepool-builder:${NODEPOOL_VERSION}"
echo "  - zuul-storage-proxy:${STORAGE_PROXY_VERSION}"
echo ""
echo "Next steps:"
echo "  1. Update kustomization.yaml with new versions"
echo "  2. git add && git commit"
echo "  3. Apply changes to the cluster"
