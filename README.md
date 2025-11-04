# 🧪 Alchemist Homelab OS

A comprehensive Docker-based homelab operating system for self-hosted services. Built with modularity and scalability in mind.

## 🌟 Philosophy

Transform your home server into a powerful, self-hosted cloud platform. Alchemist Homelab OS provides a curated collection of Docker services that work seamlessly together.

## 🏗️ Architecture

```
Internet → Cloudflare Tunnel → Traefik → n8n
```

- **Cloudflare Tunnel**: Provides secure HTTPS access without port forwarding
- **Traefik**: Acts as reverse proxy and load balancer
- **n8n**: Workflow automation platform

## 📁 Directory Structure

```
alchemist-homelab-os/
├── services/
│   ├── proxy/
│   │   ├── traefik/           # Reverse proxy & SSL termination
│   │   └── cloudflared/       # Cloudflare tunnel for secure access
│   ├── automation/
│   │   └── n8n/               # Workflow automation platform
│   ├── monitoring/            # System monitoring services
│   ├── storage/               # File storage and backup solutions
│   ├── media/                 # Media servers and downloaders
│   └── security/              # Security and authentication services
├── scripts/
├── docs/
└── README.md
```

## 🚀 Available Services

### 🔄 Proxy & Access
- **Traefik**: Reverse proxy with automatic SSL
- **Cloudflared**: Secure tunnel without port forwarding

### 🤖 Automation
- **n8n**: Visual workflow automation

### 📊 Monitoring (Coming Soon)
- **Prometheus**: Metrics collection
- **Grafana**: Dashboards and visualization
- **Uptime Kuma**: Service monitoring

### 💾 Storage (Coming Soon)
- **Nextcloud**: Personal cloud storage
- **Minio**: S3-compatible object storage

### 🎬 Media (Coming Soon)
- **Plex/Jellyfin**: Media server
- **Sonarr/Radarr**: Media management

### 🔒 Security (Coming Soon)
- **Authelia**: Authentication and authorization
- **Vaultwarden**: Password manager

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- External Docker network named `web`

### 1. Create the Docker Network

```bash
docker network create web
```

### 2. Start Services (in order)

```bash
# Start Traefik first
cd services/proxy/traefik
docker compose up -d

# Start n8n
cd ../../automation/n8n
docker compose up -d

# Start Cloudflare tunnel
cd ../../proxy/cloudflared
docker compose up -d
```

### 3. Get Your Public URL

```bash
docker logs cloudflared-tunnel | grep "Visit it at"
```

You'll see output like:
```
Your quick Tunnel has been created! Visit it at:
https://your-unique-url.trycloudflare.com
```

## 🔧 Management Commands

### Start All Services
```bash
# Option 1: Start individually (recommended order)
cd stack/traefik && docker compose up -d
cd ../n8n && docker compose up -d
cd ../cloudflared && docker compose up -d

# Option 2: Start all from root
docker compose -f stack/traefik/docker-compose.yml up -d
docker compose -f stack/n8n/docker-compose.yml up -d
docker compose -f stack/cloudflared/docker-compose.yml up -d
```

### Stop All Services
```bash
# Stop in reverse order
cd stack/cloudflared && docker compose down
cd ../n8n && docker compose down
cd ../traefik && docker compose down
```

### Restart Services
```bash
# Restart individual service
cd stack/n8n
docker compose restart

# Or restart all
cd stack/cloudflared && docker compose restart
cd ../n8n && docker compose restart
cd ../traefik && docker compose restart
```

### View Logs
```bash
# View n8n logs
docker logs n8n

# View Traefik logs
docker logs traefik

# View tunnel logs (to get URL)
docker logs cloudflared-tunnel

# Follow logs in real-time
docker logs -f n8n
```

### Check Service Status
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

## 🌐 Access Points

### Public Access (via Cloudflare Tunnel)
- **n8n Interface**: `https://your-unique-url.trycloudflare.com`
- **Webhooks**: `https://your-unique-url.trycloudflare.com/webhook/...`

### Local Access
- **Traefik Dashboard**: `http://localhost:8080`
- **Direct n8n**: `http://localhost` (via Traefik)

## ⚙️ Configuration

### n8n Environment Variables

Located in `stack/n8n/docker-compose.yml`:

```yaml
environment:
  - N8N_LOG_LEVEL=info
  - GENERIC_TIMEZONE=Africa/Johannesburg
  - TZ=Africa/Johannesburg
  - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
  - N8N_RUNNERS_ENABLED=true
  - N8N_SECURE_COOKIE=false
  - N8N_EDITOR_BASE_URL=https://your-tunnel-url.trycloudflare.com/
  - WEBHOOK_URL=https://your-tunnel-url.trycloudflare.com/
```

### Update Tunnel URL

When the tunnel URL changes, update n8n configuration:

1. Get new URL: `docker logs cloudflared-tunnel | grep "Visit it at"`
2. Edit `stack/n8n/docker-compose.yml`
3. Update `N8N_EDITOR_BASE_URL` and `WEBHOOK_URL`
4. Restart n8n: `cd stack/n8n && docker compose restart`

### Traefik Configuration

Traefik is configured via command line arguments in `stack/traefik/docker-compose.yml`:

- **API Dashboard**: Enabled on port 8080
- **Docker Provider**: Automatically discovers containers
- **Entry Points**: HTTP (80) and HTTPS (443)

## 🔒 Security Features

- **HTTPS Encryption**: Automatic via Cloudflare
- **No Port Forwarding**: Cloudflare tunnel eliminates need for router configuration
- **DDoS Protection**: Built-in via Cloudflare
- **Access Control**: Can be configured via Traefik middleware

## 🔄 Troubleshooting

### Services Won't Start
```bash
# Check network exists
docker network ls | grep web

# Check for port conflicts
docker ps --format "table {{.Names}}\t{{.Ports}}"

# View service logs
docker logs traefik
docker logs n8n
docker logs cloudflared-tunnel
```

### Tunnel URL Changed
```bash
# Get new URL
docker logs cloudflared-tunnel | grep "Visit it at"

# Update n8n config and restart
cd stack/n8n
# Edit docker-compose.yml with new URL
docker compose restart
```

### n8n Permission Issues
```bash
cd stack/n8n
sudo chown -R 1000:1000 n8n_data
docker compose restart
```

### Can't Access n8n
1. Check all containers are running: `docker ps`
2. Check tunnel URL: `docker logs cloudflared-tunnel | grep "Visit it at"`
3. Test local access: `curl -I http://localhost`
4. Check Traefik dashboard: `http://localhost:8080`

## 🔧 Maintenance

### Update Services
```bash
# Pull latest images
cd stack/traefik && docker compose pull
cd ../n8n && docker compose pull
cd ../cloudflared && docker compose pull

# Restart with new images
cd ../traefik && docker compose up -d
cd ../n8n && docker compose up -d
cd ../cloudflared && docker compose up -d
```

### Backup n8n Data
```bash
# Create backup
tar -czf n8n-backup-$(date +%Y%m%d).tar.gz -C stack/n8n n8n_data

# Restore backup
cd stack/n8n
docker compose down
tar -xzf n8n-backup-YYYYMMDD.tar.gz
docker compose up -d
```

### Clean Up
```bash
# Stop all services
cd stack/cloudflared && docker compose down
cd ../n8n && docker compose down
cd ../traefik && docker compose down

# Remove unused images
docker image prune

# Remove unused volumes
docker volume prune
```

## 📝 Notes

- **Tunnel URLs**: Quick tunnel URLs change on restart. For permanent URLs, upgrade to Cloudflare Teams
- **Data Persistence**: n8n data is stored in `stack/n8n/n8n_data/`
- **Network**: All services use the external `web` network for communication
- **Timezone**: Set to `Africa/Johannesburg`, adjust as needed

## 🆘 Support

For issues:
1. Check container logs: `docker logs <container-name>`
2. Verify network connectivity: `docker network inspect web`
3. Test local access before troubleshooting tunnel
4. Ensure proper startup order: Traefik → n8n → Cloudflared

## 📚 Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)