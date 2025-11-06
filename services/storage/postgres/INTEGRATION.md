# PostgreSQL Integration Examples

This document shows how to configure your homelab applications to use the PostgreSQL database service.

## 🔗 Connection Information

- **Host**: `postgres` (internal Docker network) or `localhost:5432` (external)
- **Port**: `5432`
- **Available Databases**: `homelab`, `n8n`, `grafana`, `nextcloud`, `wordpress`, `authentik`

## 🤖 n8n Configuration

To configure n8n to use PostgreSQL instead of SQLite:

### Environment Variables

Add these to your n8n environment configuration:

```bash
# Database Configuration
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n_user
DB_POSTGRESDB_PASSWORD=n8n_password
DB_POSTGRESDB_SCHEMA=public
```

### Connection String Format

```
postgresql://n8n_user:n8n_password@postgres:5432/n8n
```

### n8n Postgres Node

When using the Postgres node in n8n workflows:

- **Host**: `postgres`
- **Port**: `5432`  
- **Database**: `n8n` (or any other database you created)
- **User**: `n8n_user`
- **Password**: `n8n_password`

## 📊 Grafana Configuration

To use PostgreSQL as Grafana's backend database:

```bash
# Grafana Database Configuration
GF_DATABASE_TYPE=postgres
GF_DATABASE_HOST=postgres:5432
GF_DATABASE_NAME=grafana
GF_DATABASE_USER=grafana_user
GF_DATABASE_PASSWORD=grafana_password
GF_DATABASE_SSL_MODE=disable
```

## ☁️ Nextcloud Configuration

For Nextcloud database setup:

```bash
# Nextcloud Database Configuration
POSTGRES_HOST=postgres
POSTGRES_DB=nextcloud
POSTGRES_USER=nextcloud_user
POSTGRES_PASSWORD=nextcloud_password
```

## 📝 WordPress Configuration

WordPress database configuration:

```bash
# WordPress Database Configuration
WORDPRESS_DB_HOST=postgres:5432
WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=wordpress_user
WORDPRESS_DB_PASSWORD=wordpress_password
```

## 🔐 Authentik Configuration

For Authentik authentication service:

```bash
# Authentik Database Configuration
AUTHENTIK_POSTGRESQL__HOST=postgres
AUTHENTIK_POSTGRESQL__NAME=authentik
AUTHENTIK_POSTGRESQL__USER=authentik_user
AUTHENTIK_POSTGRESQL__PASSWORD=authentik_password
AUTHENTIK_POSTGRESQL__PORT=5432
```

## 🧪 Testing Connections

Use the provided test script:

```bash
cd services/storage/postgres
./test-connection.sh
```

## 📊 Database Management

### Via Command Line

```bash
# Connect to main database
docker exec -it postgres psql -U homelab -d homelab

# Connect to n8n database
docker exec -it postgres psql -U n8n_user -d n8n

# Create a new database
docker exec -it postgres createdb -U homelab my_new_db

# Backup a database
docker exec postgres pg_dump -U homelab -d n8n > n8n_backup.sql

# Restore a database
docker exec -i postgres psql -U homelab -d n8n < n8n_backup.sql
```

### Via GUI Tools

You can connect using tools like pgAdmin, DBeaver, or any PostgreSQL client:

- **Host**: `localhost`
- **Port**: `5432`
- **Username**: `homelab` (admin) or specific app users
- **Password**: `changeme` (admin) or app-specific passwords

## 🔒 Security Notes

1. **Change Default Passwords**: Update passwords in `.env` file before production use
2. **Network Security**: PostgreSQL is only accessible from Docker network by default  
3. **User Permissions**: Each application has its own database user with limited permissions
4. **Backup Strategy**: Implement regular database backups for production use

## 🛠️ Customization

To add a new database and user:

```sql
-- Connect as admin user
docker exec -it postgres psql -U homelab -d homelab

-- Create new database and user
CREATE DATABASE my_app;
CREATE USER my_app_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE my_app TO my_app_user;
```

Then add the credentials to your `.env` file:

```bash
MY_APP_DB_PASSWORD=secure_password
```