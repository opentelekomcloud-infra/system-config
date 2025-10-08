import { createBackend } from '@backstage/backend-defaults';

const backend = createBackend();

// App plugin
backend.add(import('@backstage/plugin-app-backend/alpha'));

// Auth plugin
backend.add(import('@backstage/plugin-auth-backend'));
backend.add(import('@backstage/plugin-auth-backend-module-guest-provider'));
backend.add(import('@backstage/plugin-auth-backend-module-github-provider'));

// Catalog plugin
backend.add(import('@backstage/plugin-catalog-backend/alpha'));
backend.add(import('@backstage/plugin-catalog-backend-module-scaffolder-entity-model'));

// Permission plugin
backend.add(import('@backstage/plugin-permission-backend/alpha'));

// Proxy plugin
backend.add(import('@backstage/plugin-proxy-backend/alpha'));

// Scaffolder plugin
backend.add(import('@backstage/plugin-scaffolder-backend/alpha'));

// Search plugin
backend.add(import('@backstage/plugin-search-backend/alpha'));
backend.add(import('@backstage/plugin-search-backend-module-catalog/alpha'));

// TechDocs plugin
backend.add(import('@backstage/plugin-techdocs-backend/alpha'));

// Kubernetes plugin
backend.add(import('@backstage/plugin-kubernetes-backend/alpha'));

backend.start();
