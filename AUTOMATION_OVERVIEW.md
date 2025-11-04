# Alchemist Homelab OS - Automation Overview

## 🤖 Automatic Container Updates with Watchtower

The system now includes **Watchtower** for automatic container updates with intelligent tunnel monitoring.

### Watchtower Configuration
- **Schedule**: Daily at 4:00 AM UTC (`0 0 4 * * *`)
- **Features**: 
  - Automatic cleanup of old images
  - Selective updates via labels
  - Health-aware restarts
  - Integration with existing services

### Service Management
```bash
# Start/stop Watchtower
./scripts/manage.sh start watchtower
./scripts/manage.sh stop watchtower

# View Watchtower logs  
./scripts/manage.sh logs watchtower

# Full stack with Watchtower
./scripts/stack.sh start
```

## 🔄 Intelligent Tunnel Monitoring

### Automatic URL Synchronization
When Cloudflare tunnel restarts and gets a new URL, the system automatically:

1. **Detects URL Changes**: Monitors cloudflared container restarts
2. **Updates Configuration**: Updates `.env` file with new tunnel URL
3. **Restarts n8n**: Applies new configuration seamlessly
4. **Validates Access**: Ensures n8n is accessible at the new URL

### Tunnel Monitor Usage
```bash
# Start background monitoring (60s interval)
./scripts/tunnel-monitor.sh monitor 60

# Check current status
./scripts/tunnel-monitor.sh status

# Force URL update
./scripts/tunnel-monitor.sh update

# Stop monitoring
./scripts/tunnel-monitor.sh stop
```

## 🚀 Complete Automation Workflow

### Daily Operations
1. **4:00 AM**: Watchtower checks for container updates
2. **On Updates**: Containers are updated with zero downtime
3. **If Tunnel Restarts**: New URL is automatically detected and propagated
4. **n8n Updates**: Service is restarted with new tunnel URL configuration

### Manual Operations
```bash
# Check all services status
./scripts/stack.sh status

# Get current tunnel URL
./scripts/stack.sh url

# View automation logs
tail -f tunnel-monitor.log
docker logs watchtower
```

## 📊 System Status

### Current Services
- ✅ **Traefik**: Reverse proxy with multi-port support
- ✅ **Cloudflared**: Secure tunnel to n8n
- ✅ **n8n**: Workflow automation platform  
- ✅ **Watchtower**: Automatic container updates
- ✅ **Tunnel Monitor**: URL change detection and sync

### Automation Features
- 🔄 **Auto-Updates**: Containers update automatically
- 🌐 **URL Sync**: Tunnel URL changes handled seamlessly  
- 📈 **Health Monitoring**: Service health awareness
- 🛠️ **Zero-Config**: No manual intervention required
- 📋 **Centralized Config**: All settings in `.env` file

## 🔧 Configuration Files

### Key Files
- `/.env`: Centralized configuration
- `/docker-compose.yml`: Master orchestration
- `/services/maintenance/watchtower/`: Watchtower service
- `/scripts/tunnel-monitor.sh`: URL monitoring automation
- `/scripts/stack.sh`: Intelligent service management

### Environment Variables
```bash
# Watchtower Configuration
WATCHTOWER_SCHEDULE=0 0 4 * * *
WATCHTOWER_CLEANUP=true
WATCHTOWER_ENABLE=true

# Tunnel Monitoring
N8N_WEBHOOK_URL=https://your-tunnel-url.trycloudflare.com
```

## 🎯 Next Steps

The system is now fully automated and requires minimal maintenance:

1. **Monitor Logs**: Occasionally check `tunnel-monitor.log` and `docker logs watchtower`
2. **Verify Updates**: Check service status after 4 AM to confirm updates
3. **Scale Services**: Add new services using the established patterns
4. **Backup Data**: Ensure important n8n workflows are backed up

Your homelab is now running a production-grade automation platform! 🚀