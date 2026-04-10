-- Create Zuul database and user for PostgreSQL
-- Run this as postgres superuser: psql -U postgres -f setup-zuul-database.sql

-- Create the zuul user with a secure password
CREATE USER zuul WITH PASSWORD '';

-- Create the zuul database
CREATE DATABASE zuul OWNER zuul;

-- Grant necessary privileges
GRANT ALL PRIVILEGES ON DATABASE zuul TO zuul;

-- Connect to the zuul database to set additional permissions
\c zuul

-- Grant schema permissions
GRANT ALL ON SCHEMA public TO zuul;

-- Ensure the user can create tables and sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO zuul;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO zuul;
