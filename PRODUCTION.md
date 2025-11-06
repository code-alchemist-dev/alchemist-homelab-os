# 🔒 Production Deployment Guide

> **Secure Your Alchemist Homelab OS for Production Use**

This guide provides comprehensive instructions for deploying Alchemist Homelab OS in a production environment with proper security configurations, monitoring, and maintenance procedures.

## 🎯 Production Checklist

### ✅ **Pre-Deployment Security**
- [ ] Change all default passwords
- [ ] Configure proper timezone
- [ ] Set up named Cloudflare tunnel
- [ ] Disable development features
- [ ] Configure resource limits
- [ ] Set up automated backups
- [ ] Review network security
- [ ] Configure monitoring alerts

## 🚀 Quick Production Setup

### 1. **Initial Configuration**

```bash
# Clone and prepare
git clone https://github.com/code-alchemist-dev/alchemist-homelab-os.git
cd alchemist-homelab-os

# Create production environment file
cp .env.example .env
nano .env  # Configure all settings below
```

### 2. **Security Configuration**

Edit your `.env` file with production values:

```bash
# === GLOBAL SETTINGS ===
COMPOSE_PROJECT_NAME=homelab-prod
TIMEZONE=Your/Timezone              # Set your timezone
PUID=1000                          # Your user ID
PGID=1000                          # Your group ID

# === SECURITY SETTINGS ===
TRAEFIK_API_INSECURE=false         # Disable insecure API
N8N_SECURE_COOKIE=true             # Enable secure cookies

# === DATABASE SECURITY ===
POSTGRES_PASSWORD=your_very_secure_database_password_here
N8N_DB_PASSWORD=secure_n8n_password_change_this
GRAFANA_DB_PASSWORD=secure_grafana_password_change_this
NEXTCLOUD_DB_PASSWORD=secure_nextcloud_password_change_this
WORDPRESS_DB_PASSWORD=secure_wordpress_password_change_this
AUTHENTIK_DB_PASSWORD=secure_authentik_password_change_this

# === APPLICATION PASSWORDS ===
GRAFANA_ADMIN_PASSWORD=your_secure_grafana_admin_password
```

### 3. **Named Cloudflare Tunnel (Recommended)**

For production, use a named tunnel instead of quick tunnels:

```bash
# 1. Create Cloudflare account and get tunnel token
# 2. Update cloudflared configuration
nano services/proxy/cloudflared/docker-compose.yml

# Replace the command with:
command: cloudflared tunnel run --token YOUR_TUNNEL_TOKEN_HERE

# 3. Update environment with your domain
sed -i 's/CLOUDFLARED_TUNNEL_URL=.*/CLOUDFLARED_TUNNEL_URL=https://yourdomain.com/' .env
```

### 4. **Start Production Stack**

```bash
# Start all services
./scripts/stack.sh start

# Verify all services are running
./scripts/stack.sh status
```

## 🔒 Security Hardening

### **Database Security**

```bash
# 1. Generate strong passwords (example using openssl)
openssl rand -base64 32  # Use for database passwords

# 2. Create database admin user (after stack is running)
docker exec postgres psql -U homelab -d homelab -c "
CREATE USER admin_user WITH PASSWORD 'very_secure_admin_password';
GRANT ALL PRIVILEGES ON ALL DATABASES TO admin_user;
"

# 3. Restrict database access (optional)
# Edit postgresql.conf to limit connections if needed
```

### **Application Security**

```bash
# 1. Secure n8n
# Add these to your .env:
N8N_DISABLE_PRODUCTION_MAIN_PROCESS=false
N8N_BLOCK_ENV_ACCESS_IN_NODE=true
N8N_SECURE_COOKIE=true

# 2. Secure Grafana
# Configure in .env:
GRAFANA_ADMIN_PASSWORD=your_very_secure_password
GRAFANA_SECURITY_ADMIN_USER=admin
GRAFANA_SECURITY_SECRET_KEY=$(openssl rand -base64 32)

# 3. Disable unnecessary services
# Comment out services you don't need in docker-compose.yml
```

### **Network Security**

```bash
# 1. Firewall configuration (Ubuntu/Debian)
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp   # Only if you need direct HTTP access
sudo ufw allow 443/tcp  # Only if you need direct HTTPS access
sudo ufw enable

# 2. Docker network isolation
# Services communicate only through the 'web' network
# No services expose ports directly to host (except PostgreSQL for admin)
```

## 📊 Production Monitoring

### **Health Monitoring Setup**

```bash
# 1. Access Grafana
# URL: http://localhost:3000
# Login: admin / [your_secure_password]

# 2. Import recommended dashboards:
# - Node Exporter Full (ID: 1860)
# - Docker Container & Host Metrics (ID: 10619) 
# - PostgreSQL Database (ID: 9628)

# 3. Set up alerts for:
# - High CPU usage (>80% for 5 minutes)
# - Low disk space (<10% remaining)
# - Container restarts
# - Database connection failures
```

### **Log Monitoring**

```bash
# Set up log rotation
sudo nano /etc/logrotate.d/docker-homelab
```

Add to logrotate config:
```
/var/lib/docker/containers/*/*.log {
    rotate 7
    daily
    compress
    size=10M
    missingok
    delaycompress
    copytruncate
}
```

## 💾 Backup Strategy

### **Automated Backup Script**

Create `/home/ubuntu/backup-homelab.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/home/ubuntu/homelab-backups"
DATE=$(date +%Y%m%d-%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup PostgreSQL databases
echo "Backing up databases..."
docker exec postgres pg_dumpall -U homelab > "$BACKUP_DIR/postgres-all-$DATE.sql"

# Backup n8n data
echo "Backing up n8n data..."
tar -czf "$BACKUP_DIR/n8n-data-$DATE.tar.gz" -C services/automation/n8n n8n_data

# Backup configuration
echo "Backing up configuration..."
cp .env "$BACKUP_DIR/env-$DATE.bak"
tar -czf "$BACKUP_DIR/config-$DATE.tar.gz" docker-compose.yml services/*/docker-compose.yml

# Cleanup old backups (keep 30 days)
find "$BACKUP_DIR" -name "*.sql" -mtime +30 -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete
find "$BACKUP_DIR" -name "*.bak" -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR"
```

Make executable and add to crontab:
```bash
chmod +x /home/ubuntu/backup-homelab.sh

# Add to crontab (daily at 2:00 AM)
crontab -e
# Add line: 0 2 * * * /home/ubuntu/backup-homelab.sh >> /var/log/homelab-backup.log 2>&1
```

### **Restore Procedures**

```bash
# Restore PostgreSQL database
docker exec -i postgres psql -U homelab < postgres-all-YYYYMMDD-HHMMSS.sql

# Restore n8n data
./scripts/stack.sh stop
tar -xzf n8n-data-YYYYMMDD-HHMMSS.tar.gz -C services/automation/n8n/
./scripts/stack.sh start

# Restore configuration
cp env-YYYYMMDD-HHMMSS.bak .env
tar -xzf config-YYYYMMDD-HHMMSS.tar.gz
```

## 🔧 Resource Management

### **Container Resource Limits**

Add to your docker-compose.yml services:

```yaml
services:
  postgres:
    # ... existing config
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '0.5'
        reservations:
          memory: 512M
          cpus: '0.25'
  
  n8n:
    # ... existing config  
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1'
        reservations:
          memory: 512M
          cpus: '0.5'
```

### **Storage Management**

```bash
# Monitor disk usage
df -h

# Clean up Docker resources regularly
docker system prune -a --volumes --force

# Set up automatic cleanup (weekly)
echo "0 2 * * 0 docker system prune -a --volumes --force" | crontab -
```

## 🚨 Troubleshooting Production Issues

### **Service Not Starting**

```bash
# 1. Check Docker daemon
sudo systemctl status docker

# 2. Check service logs
docker logs [container_name] --tail 50

# 3. Check resource usage
docker stats

# 4. Check disk space
df -h
```

### **Database Connection Issues**

```bash
# 1. Check PostgreSQL health
docker exec postgres pg_isready -U homelab

# 2. Check database connections
docker exec postgres psql -U homelab -c "SELECT * FROM pg_stat_activity;"

# 3. Restart database if needed
docker restart postgres
```

### **Tunnel Connection Problems**

```bash
# 1. Check tunnel status
docker logs cloudflared-tunnel --tail 20

# 2. Test connectivity
curl -I https://yourdomain.com

# 3. Restart tunnel if needed
docker restart cloudflared-tunnel
```

## 📈 Performance Optimization

### **Database Performance**

```bash
# Add to PostgreSQL configuration (optional)
echo "
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 16MB
maintenance_work_mem = 256MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
" > services/storage/postgres/postgresql.conf

# Mount in docker-compose.yml:
# volumes:
#   - ./postgresql.conf:/etc/postgresql/postgresql.conf
```

### **Monitoring Performance**

```bash
# Monitor resource usage
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

# Check container logs for errors
for container in $(docker ps --format "{{.Names}}"); do
    echo "=== $container ==="
    docker logs $container --tail 5 --since 1h | grep -i error
done
```

## 🔄 Maintenance Procedures

### **Weekly Maintenance**

```bash
#!/bin/bash
# weekly-maintenance.sh

echo "Starting weekly maintenance..."

# Update containers (Watchtower handles this automatically)
# But you can do manual updates if needed:
# docker compose pull && docker compose up -d

# Backup critical data
/home/ubuntu/backup-homelab.sh

# Clean up old logs
docker system prune -f

# Check disk space
df -h | grep -E "Filesystem|/$"

# Check service health
./scripts/stack.sh status

echo "Weekly maintenance completed."
```

### **Monthly Maintenance**

```bash
#!/bin/bash
# monthly-maintenance.sh

echo "Starting monthly maintenance..."

# Full system cleanup
docker system prune -a --volumes

# Update base system (Ubuntu/Debian)
sudo apt update && sudo apt upgrade -y

# Review backup retention
find /home/ubuntu/homelab-backups -type f -mtime +90 -delete

# Security audit
docker scan $(docker images --format "{{.Repository}}:{{.Tag}}")

echo "Monthly maintenance completed."
```

## 🎯 Production Best Practices

### **Security Best Practices**
1. **Regular Updates**: Enable automatic security updates
2. **Access Control**: Use SSH keys, disable password auth
3. **Monitoring**: Set up alerts for critical issues
4. **Backups**: Test restore procedures regularly
5. **Documentation**: Keep configuration documented
6. **Secrets Management**: Use environment files, never hardcode secrets

### **Operational Best Practices**
1. **Change Management**: Test changes in development first
2. **Monitoring**: Monitor resource usage and performance
3. **Capacity Planning**: Plan for growth and scaling
4. **Incident Response**: Have procedures for common issues
5. **Documentation**: Maintain operational runbooks

### **High Availability Considerations**
- Use named Cloudflare tunnels for consistent URLs
- Set up database replication if critical
- Consider container orchestration (Docker Swarm/Kubernetes) for larger deployments
- Implement health checks and automatic recovery

---

## 📞 Support

For production support:
- Check service logs: `docker logs [container]`
- Review monitoring dashboards
- Consult troubleshooting sections in service READMEs
- Community support via GitHub issues

**Your Alchemist Homelab OS is now production-ready! 🚀**