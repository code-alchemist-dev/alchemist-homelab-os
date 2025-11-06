#!/bin/bash
set -e

echo "Creating additional databases and users for homelab services..."

# Create databases for common services
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create additional databases
    CREATE DATABASE n8n;
    CREATE DATABASE grafana;
    CREATE DATABASE nextcloud;
    CREATE DATABASE wordpress;
    CREATE DATABASE authentik;
    
    -- Create service-specific users
    CREATE USER n8n_user WITH PASSWORD 'n8n_password';
    CREATE USER grafana_user WITH PASSWORD 'grafana_password';
    CREATE USER nextcloud_user WITH PASSWORD 'nextcloud_password';
    CREATE USER wordpress_user WITH PASSWORD 'wordpress_password';
    CREATE USER authentik_user WITH PASSWORD 'authentik_password';
    
    -- Grant permissions
    GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n_user;
    GRANT ALL PRIVILEGES ON DATABASE grafana TO grafana_user;
    GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud_user;
    GRANT ALL PRIVILEGES ON DATABASE wordpress TO wordpress_user;
    GRANT ALL PRIVILEGES ON DATABASE authentik TO authentik_user;
    
    -- Create extensions commonly used by applications
    \c n8n;
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    
    \c grafana;
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    
    \c nextcloud;
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    
    \c wordpress;
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    
    \c authentik;
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
EOSQL

echo "Database initialization completed successfully!"