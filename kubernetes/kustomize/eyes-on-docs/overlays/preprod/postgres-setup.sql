-- ========================================
-- Eyes-on-Docs PostgreSQL Database Setup
-- ========================================
--
-- This script creates the required PostgreSQL databases and users for Eyes-on-Docs
-- Run as PostgreSQL superuser (postgres)
--
-- Usage:
--   psql -h postgresql-preprod.postgres.svc.cluster.local -U postgres -f postgres-setup.sql
--

-- Connect to postgres database
\c postgres

-- ========================================
-- 1. Create User
-- ========================================
CREATE USER eyes_on_docs WITH
    PASSWORD ''
    LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    INHERIT
    NOREPLICATION
    CONNECTION LIMIT -1;

COMMENT ON ROLE eyes_on_docs IS 'Eyes-on-Docs monitoring service user';

-- ========================================
-- 2. Create Main Database (eyes_on_docs)
-- ========================================
CREATE DATABASE eyes_on_docs
    WITH
    OWNER = eyes_on_docs
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    TEMPLATE = template0;

COMMENT ON DATABASE eyes_on_docs IS 'Main database for Eyes-on-Docs monitoring data';

-- ========================================
-- 3. Create Orphan Images Database
-- ========================================
CREATE DATABASE orphan_images
    WITH
    OWNER = eyes_on_docs
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    TEMPLATE = template0;

COMMENT ON DATABASE orphan_images IS 'Database for tracking orphan container images';

-- ========================================
-- 4. Create Zuul Stats Database
-- ========================================
CREATE DATABASE zuul_stats
    WITH
    OWNER = eyes_on_docs
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    TEMPLATE = template0;

COMMENT ON DATABASE zuul_stats IS 'Database for Zuul CI/CD statistics';

-- ========================================
-- 5. Grant Privileges on eyes_on_docs
-- ========================================
\c eyes_on_docs

-- Grant all privileges on schema
GRANT ALL PRIVILEGES ON SCHEMA public TO eyes_on_docs;
GRANT CREATE ON SCHEMA public TO eyes_on_docs;

-- Grant default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO eyes_on_docs;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO eyes_on_docs;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO eyes_on_docs;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TYPES TO eyes_on_docs;

-- Grant privileges on existing objects (if any)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO eyes_on_docs;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO eyes_on_docs;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO eyes_on_docs;

-- ========================================
-- 6. Grant Privileges on orphan_images
-- ========================================
\c orphan_images

GRANT ALL PRIVILEGES ON SCHEMA public TO eyes_on_docs;
GRANT CREATE ON SCHEMA public TO eyes_on_docs;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO eyes_on_docs;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO eyes_on_docs;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO eyes_on_docs;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TYPES TO eyes_on_docs;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO eyes_on_docs;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO eyes_on_docs;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO eyes_on_docs;

-- ========================================
-- 7. Grant Privileges on zuul_stats
-- ========================================
\c zuul_stats

GRANT ALL PRIVILEGES ON SCHEMA public TO eyes_on_docs;
GRANT CREATE ON SCHEMA public TO eyes_on_docs;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO eyes_on_docs;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO eyes_on_docs;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO eyes_on_docs;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TYPES TO eyes_on_docs;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO eyes_on_docs;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO eyes_on_docs;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO eyes_on_docs;

-- ========================================
-- 8. Configure Role Settings
-- ========================================
\c postgres

ALTER ROLE eyes_on_docs SET client_encoding TO 'utf8';
ALTER ROLE eyes_on_docs SET default_transaction_isolation TO 'read committed';
ALTER ROLE eyes_on_docs SET timezone TO 'UTC';
ALTER ROLE eyes_on_docs SET statement_timeout TO '300000'; -- 5 minutes
ALTER ROLE eyes_on_docs SET lock_timeout TO '10000'; -- 10 seconds
ALTER ROLE eyes_on_docs SET idle_in_transaction_session_timeout TO '600000'; -- 10 minutes

-- ========================================
-- 9. Verify Setup
-- ========================================
\echo ''
\echo '========================================'
\echo 'Verification'
\echo '========================================'
\echo ''
\echo 'User:'
\du eyes_on_docs

\echo ''
\echo 'Databases:'
\l eyes_on_docs
\l orphan_images
\l zuul_stats

\echo ''
\echo '========================================'
\echo '✓ Setup Complete!'
\echo '========================================'
\echo ''
\echo 'IMPORTANT NOTES:'
\echo '1. Remember to replace REPLACE_WITH_SECURE_DB_PASSWORD with your actual password'
\echo '2. Update the same password in Vault: secret/eyes-on-docs/postgresql'
\echo '3. The application will create tables automatically on first run'
\echo '4. Connection string format: postgresql://eyes_on_docs:PASSWORD@postgresql-preprod.postgres.svc.cluster.local:5432/DB_NAME'
\echo ''
\echo 'Test connection:'
\echo '  psql -h postgresql-preprod.postgres.svc.cluster.local -U eyes_on_docs -d eyes_on_docs'
