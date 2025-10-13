#!/bin/bash
set -e

# Copy the read-only config file to a writable location if it exists
if [ -f /app/app-config.production.yaml ]; then
    cp /app/app-config.production.yaml /tmp/app-config.production.yaml
    chown backstage:backstage /tmp/app-config.production.yaml
    chmod 644 /tmp/app-config.production.yaml
    CONFIG_ARGS="--config app-config.yaml --config /tmp/app-config.production.yaml"
else
    CONFIG_ARGS="--config app-config.yaml"
fi

# Switch to backstage user and execute the main command
exec runuser -u backstage -- node packages/backend/dist/index.cjs.js $CONFIG_ARGS
