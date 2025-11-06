# PostgreSQL - Database Server

PostgreSQL is a powerful, open source object-relational database system with over 35 years of active development that has earned it a strong reputation for reliability, feature robustness, and performance.

## 🚀 Quick Start

### Start PostgreSQL

```bash
# Start PostgreSQL
./scripts/manage.sh start postgres

# Or start directly
cd services/storage/postgres
docker compose up -d
```

### Access PostgreSQL

Once running, you can connect to PostgreSQL at:

- **Host**: localhost
- **Port**: 5432
- **Database**: homelab
- **Username**: homelab
- **Password**: changeme (change this in .env)

## 🔧 Configuration

### Environment Variables

Key environment variables (defined in `.env`):

```bash
# PostgreSQL Configuration
POSTGRES_IMAGE=postgres:15
POSTGRES_CONTAINER_NAME=postgres
POSTGRES_DB=homelab
POSTGRES_USER=homelab
POSTGRES_PASSWORD=changeme
POSTGRES_PORT=5432
```

### Pre-configured Databases

The service automatically creates databases for common homelab applications:

- **n8n**: For workflow automation
- **grafana**: For monitoring dashboards
- **nextcloud**: For file storage
- **wordpress**: For websites/blogs
- **authentik**: For authentication

### Pre-configured Users

Each service has its own database user:

- `n8n_user` / `n8n_password`
- `grafana_user` / `grafana_password`
- `nextcloud_user` / `nextcloud_password`
- `wordpress_user` / `wordpress_password`
- `authentik_user` / `authentik_password`

## 🗄️ Database Management

### Connect via Command Line

```bash
# Connect to PostgreSQL container
docker exec -it postgres psql -U homelab -d homelab

# Connect to specific database
docker exec -it postgres psql -U n8n_user -d n8n
```

### Connect via GUI Tools

Use tools like pgAdmin, DBeaver, or any PostgreSQL client:

- **Connection String**: `postgresql://homelab:changeme@localhost:5432/homelab`
- **For n8n**: `postgresql://n8n_user:n8n_password@localhost:5432/n8n`

## 📊 Database Operations

### Create New Database

```sql
-- Connect as main user
CREATE DATABASE my_new_app;
CREATE USER my_app_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE my_new_app TO my_app_user;
```

### Backup Database

```bash
# Backup specific database
docker exec postgres pg_dump -U homelab -d homelab > homelab_backup.sql

# Backup all databases
docker exec postgres pg_dumpall -U homelab > all_databases_backup.sql
```

### Restore Database

```bash
# Restore database
docker exec -i postgres psql -U homelab -d homelab < homelab_backup.sql
```

## 🔗 Integration with Applications

### n8n Configuration

```env
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n_user
DB_POSTGRESDB_PASSWORD=n8n_password
```

### Grafana Configuration

```env
GF_DATABASE_TYPE=postgres
GF_DATABASE_HOST=postgres:5432
GF_DATABASE_NAME=grafana
GF_DATABASE_USER=grafana_user
GF_DATABASE_PASSWORD=grafana_password
```

### Nextcloud Configuration

```env
POSTGRES_HOST=postgres
POSTGRES_DB=nextcloud
POSTGRES_USER=nextcloud_user
POSTGRES_PASSWORD=nextcloud_password
```

## 🔧 Maintenance

### Performance Tuning

The PostgreSQL instance is configured with sensible defaults, but you can tune it by mounting a custom `postgresql.conf`:

```yaml
volumes:
  - ./config/postgresql.conf:/etc/postgresql/postgresql.conf
```

### Monitoring

```bash
# View active connections
docker exec postgres psql -U homelab -c "SELECT * FROM pg_stat_activity;"

# Check database sizes
docker exec postgres psql -U homelab -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database;"
```

### Logs

```bash
# View PostgreSQL logs
docker logs postgres

# Follow logs
docker logs -f postgres
```

## 🔒 Security

### Production Checklist

- [ ] Change default passwords
- [ ] Use strong passwords for all users
- [ ] Limit network access if not needed externally
- [ ] Enable SSL/TLS for connections
- [ ] Configure firewall rules
- [ ] Set up regular backups
- [ ] Monitor for suspicious activity

### Network Security

The service is configured to work with the homelab's Docker network but doesn't expose any web interfaces directly.

## 🚨 Troubleshooting

### Common Issues

1. **Connection refused**
   ```bash
   # Check if container is running
   docker ps | grep postgres
   
   # Check logs
   docker logs postgres
   ```

2. **Authentication failed**
   ```bash
   # Verify credentials in .env file
   # Reset password if needed
   docker exec postgres psql -U postgres -c "ALTER USER homelab PASSWORD 'new_password';"
   ```

3. **Database doesn't exist**
   ```bash
   # Create database manually
   docker exec postgres createdb -U homelab my_database
   ```

### Reset Everything

```bash
# Stop service and remove data (WARNING: This deletes all data!)
docker compose down -v

# Start fresh
docker compose up -d
```

## 📚 Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker PostgreSQL Image](https://hub.docker.com/_/postgres)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)