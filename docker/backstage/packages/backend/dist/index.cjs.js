const { createBackend } = require('@backstage/backend-defaults');

const backend = createBackend();

// App plugin
backend.add(require('@backstage/plugin-app-backend'));

// Auth plugin
backend.add(require('@backstage/plugin-auth-backend'));
backend.add(require('@backstage/plugin-auth-backend-module-guest-provider'));

// Catalog plugin
backend.add(require('@backstage/plugin-catalog-backend'));

// Permission plugin
backend.add(require('@backstage/plugin-permission-backend'));

// Proxy plugin
backend.add(require('@backstage/plugin-proxy-backend'));

// Scaffolder plugin
backend.add(require('@backstage/plugin-scaffolder-backend'));

// Search plugin
backend.add(require('@backstage/plugin-search-backend'));
backend.add(require('@backstage/plugin-search-backend-module-catalog'));

// TechDocs plugin
backend.add(require('@backstage/plugin-techdocs-backend'));

backend.start().catch(err => {
    console.error('Backend startup failed:', err);
    process.exit(1);
});
