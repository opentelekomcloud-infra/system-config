#!/bin/bash

# Build script for custom Backstage image

set -e

REGISTRY="quay.io/opentelekomcloud"
IMAGE_NAME="backstage"
TAG="${1:-$(date +%Y%m%d-%H%M%S)}"

echo "Building Backstage image: ${REGISTRY}/${IMAGE_NAME}:${TAG}"

# Build the podman image for x86_64 architecture
podman build --platform=linux/amd64 -t ${REGISTRY}/${IMAGE_NAME}:${TAG} .

# Tag as latest
podman tag ${REGISTRY}/${IMAGE_NAME}:${TAG} ${REGISTRY}/${IMAGE_NAME}:latest

echo "Image built successfully!"
echo "To push: podman push ${REGISTRY}/${IMAGE_NAME}:${TAG}"
echo "To push latest: podman push ${REGISTRY}/${IMAGE_NAME}:latest"

# Update the kustomize configuration
echo "Updating kustomize configuration..."
sed -i "s/newTag: .*/newTag: \"${TAG}\"/" ../../kubernetes/kustomize/backstage/overlays/preprod/kustomization.yaml

echo "Updated kustomization.yaml with new tag: ${TAG}"
echo "Don't forget to commit the changes!"
