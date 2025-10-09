# This dockerfile builds an image for the backend package.
# Optimized for memory usage and x86_64 architecture

FROM node:22-bookworm-slim

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    python3 \
    python3-pip \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN groupadd -r backstage && useradd -r -g backstage backstage
WORKDIR /app

# Copy only package.json first for better caching
COPY --chown=backstage:backstage package.json ./

# Copy pre-built backend
COPY --chown=backstage:backstage packages/backend ./packages/backend

# Create app structure and copy the root package.json to satisfy app plugin requirements
RUN mkdir -p packages/app app
COPY --chown=backstage:backstage package.json ./packages/app/package.json
COPY --chown=backstage:backstage package.json ./app/package.json

# Copy app configs
COPY --chown=backstage:backstage app-config*.yaml ./

# Copy entrypoint script
COPY --chown=backstage:backstage entrypoint.sh ./
RUN chmod +x entrypoint.sh

# Switch to root for npm install with memory limits
USER root
RUN npm install --only=production --no-optional --max-old-space-size=2048 && \
    npm cache clean --force && \
    chown -R backstage:backstage /app

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:7007/healthcheck || exit 1

EXPOSE 7007
CMD ["./entrypoint.sh"]
