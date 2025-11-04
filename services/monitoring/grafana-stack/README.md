# Grafana + Prometheus Monitoring Stack

## Overview
Complete monitoring solution for your Alchemist Homelab OS platform, providing system metrics, container monitoring, and visual dashboards.

## Components

### 📊 **Grafana** - Visualization & Dashboards
- **Purpose**: Create beautiful dashboards and visualize metrics
- **Access**: http://localhost:3000 or http://grafana.localhost
- **Default Login**: admin / admin (change in .env)

### 📈 **Prometheus** - Metrics Collection & Storage
- **Purpose**: Collect and store time-series metrics data
- **Access**: http://localhost:9090 or http://prometheus.localhost
- **Data Retention**: 15 days (configurable)

### 🖥️ **Node Exporter** - System Metrics
- **Purpose**: Export system metrics (CPU, memory, disk, network)
- **Metrics**: Hardware and OS metrics exposed for Prometheus

### 🐳 **cAdvisor** - Container Metrics
- **Purpose**: Monitor container resource usage and performance
- **Metrics**: Docker container CPU, memory, network, filesystem

## Quick Start

### 1. **Configure Environment**
```bash
# Edit .env file with monitoring configuration
nano .env

# Set secure Grafana password
GRAFANA_ADMIN_PASSWORD=your_secure_password
```

### 2. **Start Monitoring Stack**
```bash
# Start all monitoring services
./scripts/manage.sh start monitoring

# Or start individually
cd services/monitoring/grafana-stack
docker compose --env-file ../../../.env up -d
```

### 3. **Access Dashboards**
- **Grafana**: http://localhost:3000
- **Prometheus**: http://localhost:9090

### 4. **Import Dashboards**
In Grafana, import these dashboard IDs:
- **Node Exporter Full**: 1860
- **Docker Container & Host**: 179
- **Traefik 2**: 11462
- **Docker Containers**: 193

## Configuration

### Environment Variables
```bash
# Grafana Settings
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=secure_password
GRAFANA_PLUGINS=grafana-piechart-panel,grafana-worldmap-panel

# Prometheus Settings  
PROMETHEUS_CONTAINER_NAME=prometheus

# Node Exporter
NODE_EXPORTER_CONTAINER_NAME=node-exporter

# cAdvisor
CADVISOR_CONTAINER_NAME=cadvisor
```

### Prometheus Targets
The monitoring stack automatically discovers and monitors:
- ✅ **System Metrics**: CPU, memory, disk, network via Node Exporter
- ✅ **Container Metrics**: Docker containers via cAdvisor
- ✅ **Application Metrics**: Prometheus self-monitoring
- ✅ **Traefik Metrics**: Reverse proxy performance (if enabled)
- ✅ **n8n Metrics**: Workflow execution stats (if enabled)

## Dashboards & Visualizations

### 📊 **Recommended Dashboard Imports**

1. **System Overview Dashboard** (ID: 1860)
   - System CPU, memory, disk usage
   - Network traffic and I/O
   - System load and uptime

2. **Docker Monitoring Dashboard** (ID: 179)
   - Container resource usage
   - Container status and health
   - Docker host metrics

3. **Traefik Dashboard** (ID: 11462)
   - Request rates and response times
   - Service health and routing
   - Error rates and status codes

### 🎯 **Custom Dashboard Creation**
```bash
# Access Grafana
http://localhost:3000

# Login with admin credentials
# Go to Dashboards > New Dashboard
# Add panels with PromQL queries
```

### 📈 **Key Metrics to Monitor**

#### System Health
- CPU usage: `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
- Memory usage: `(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100`
- Disk usage: `100 - ((node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100)`

#### Container Health
- Container CPU: `rate(container_cpu_usage_seconds_total[5m]) * 100`
- Container Memory: `container_memory_usage_bytes / container_spec_memory_limit_bytes * 100`
- Container Status: `container_last_seen`

## Alerting

### 🚨 **Alert Rules Setup**
```yaml
# Add to prometheus.yml
rule_files:
  - "alert_rules.yml"

# Create alert_rules.yml with:
groups:
  - name: homelab_alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          
      - alert: ContainerDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Container {{ $labels.instance }} is down"
```

### 📧 **Notification Channels**
Configure in Grafana > Alerting > Notification Channels:
- Email notifications
- Slack integration  
- Discord webhooks
- PagerDuty (for production)

## Integration with Existing Services

### 🔄 **Traefik Integration**
Enable metrics in Traefik:
```yaml
# Add to traefik docker-compose.yml
command:
  - --metrics.prometheus=true
  - --metrics.prometheus.addEntryPointsLabels=true
  - --metrics.prometheus.addServicesLabels=true
```

### 🤖 **n8n Integration**
Enable metrics in n8n:
```bash
# Add to .env
N8N_METRICS=true
```

### 🐳 **Docker Daemon Metrics**
Enable Docker metrics:
```bash
# Add to /etc/docker/daemon.json
{
  "metrics-addr": "127.0.0.1:9323",
  "experimental": true
}

# Restart Docker
sudo systemctl restart docker
```

## Management Commands

### 🛠️ **Service Management**
```bash
# Start monitoring stack
./scripts/manage.sh start monitoring

# Stop monitoring stack  
./scripts/manage.sh stop monitoring

# View logs
./scripts/manage.sh logs grafana
./scripts/manage.sh logs prometheus

# Restart with new config
./scripts/manage.sh restart monitoring
```

### 📊 **Data Management**
```bash
# Backup Grafana dashboards
docker exec grafana grafana-cli admin export-dashboard > dashboards-backup.json

# Backup Prometheus data
docker run --rm -v prometheus_data:/data -v $(pwd):/backup alpine tar czf /backup/prometheus-data.tar.gz /data

# Clean up old metrics (Prometheus retention)
# Configured to 15 days by default in prometheus command args
```

## Troubleshooting

### 🔍 **Common Issues**

#### Grafana won't start
```bash
# Check logs
docker logs grafana

# Fix permissions
sudo chown -R 472:472 services/monitoring/grafana-stack/grafana_data
```

#### Prometheus targets down
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Verify service connectivity
docker exec prometheus ping node-exporter
docker exec prometheus ping cadvisor
```

#### No data in dashboards
```bash
# Check Prometheus is scraping
http://localhost:9090/targets

# Verify time series data
http://localhost:9090/graph
# Query: up
```

### 📊 **Performance Tuning**
```bash
# Reduce scrape intervals for less resource usage
# Edit prometheus.yml:
scrape_interval: 30s  # Default: 15s

# Adjust retention period
# Edit docker-compose.yml prometheus command:
--storage.tsdb.retention.time=7d  # Default: 15d
```

## Resource Requirements

### 💾 **Disk Space**
- **Prometheus**: ~100MB per day for typical homelab (with 15d retention)
- **Grafana**: ~50MB for dashboards and configuration
- **Total**: ~2GB for full retention period

### 🖥️ **System Resources**
- **CPU**: ~5-10% additional usage
- **Memory**: ~500MB additional RAM usage
- **Network**: Minimal impact (internal scraping)

## Security Considerations

### 🔒 **Access Control**
```bash
# Change default Grafana password
GRAFANA_ADMIN_PASSWORD=secure_random_password

# Disable Prometheus external access (optional)
# Remove Traefik labels from prometheus service

# Enable Grafana authentication
# Configure LDAP/OAuth if needed
```

### 🛡️ **Network Security**
- All services run on isolated Docker network
- External access via Traefik reverse proxy
- No direct port exposure required

## Next Steps

1. **🚀 Start the monitoring stack**: `./scripts/manage.sh start monitoring`
2. **📊 Import dashboards**: Use recommended dashboard IDs in Grafana
3. **🚨 Configure alerts**: Set up notification channels for critical alerts
4. **📈 Monitor trends**: Track system performance over time
5. **🔧 Optimize**: Adjust retention and scrape intervals based on usage

Your homelab now has enterprise-grade monitoring! 📊🚀