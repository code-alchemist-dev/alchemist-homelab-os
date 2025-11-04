#!/bin/bash

# Service Template Generator for Alchemist Homelab OS
# Usage: ./scripts/new-service.sh <category> <service-name>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SERVICES_DIR="$PROJECT_ROOT/services"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_color() {
    printf "${1}${2}${NC}\n"
}

show_usage() {
    echo "Usage: $(basename "$0") <category> <service-name>"
    echo ""
    echo "Categories:"
    echo "  automation  - Workflow and automation tools"
    echo "  proxy       - Reverse proxies and load balancers"
    echo "  monitoring  - Monitoring and observability"
    echo "  storage     - Storage and database services"
    echo "  media       - Media servers and streaming"
    echo "  security    - Security and authentication"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") monitoring grafana"
    echo "  $(basename "$0") media plex"
    echo "  $(basename "$0") storage postgresql"
}

create_service_template() {
    local category=$1
    local service_name=$2
    local service_path="$SERVICES_DIR/$category/$service_name"
    
    # Create service directory
    mkdir -p "$service_path"
    
    # Create docker-compose.yml template
    cat > "$service_path/docker-compose.yml" << EOF
version: '3.8'

services:
  $service_name:
    image: # TODO: Add your image here
    container_name: $service_name
    restart: unless-stopped
    environment:
      # TODO: Add environment variables
      - PUID=1000
      - PGID=1000
      - TZ=UTC
    volumes:
      # TODO: Add volume mounts
      - ./${service_name}_data:/data
    networks:
      - web
    # Uncomment and configure Traefik labels for web access
    # labels:
    #   - "traefik.enable=true"
    #   - "traefik.http.routers.${service_name}.rule=Host(\`${service_name}.localhost\`)"
    #   - "traefik.http.routers.${service_name}.entrypoints=web"
    #   - "traefik.http.services.${service_name}.loadbalancer.server.port=80"

networks:
  web:
    external: true
EOF
    
    # Create .env template
    cat > "$service_path/.env" << EOF
# Environment variables for $service_name
# Copy this to .env.local and customize

# Service Configuration
SERVICE_NAME=$service_name
SERVICE_PORT=80

# Security
# Generate secure passwords: openssl rand -base64 32
# ADMIN_PASSWORD=

# Database (if applicable)
# DB_HOST=
# DB_NAME=
# DB_USER=
# DB_PASSWORD=

# Timezone
TZ=UTC

# User/Group IDs
PUID=1000
PGID=1000
EOF
    
    # Create README for the service
    cat > "$service_path/README.md" << EOF
# $service_name

## Description
TODO: Add service description

## Configuration

1. Copy environment file:
   \`\`\`bash
   cp .env .env.local
   \`\`\`

2. Edit \`.env.local\` with your configuration

3. Start the service:
   \`\`\`bash
   # From project root
   ./scripts/manage.sh start $service_name
   
   # Or from service directory
   docker compose up -d
   \`\`\`

## Access

- **Local**: http://localhost:PORT
- **Traefik**: http://$service_name.localhost (if Traefik labels enabled)

## Volumes

- \`${service_name}_data\`: Service data directory

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| SERVICE_PORT | Service port | 80 |
| TZ | Timezone | UTC |
| PUID | User ID | 1000 |
| PGID | Group ID | 1000 |

## Troubleshooting

### Common Issues

1. **Service won't start**
   - Check logs: \`docker logs $service_name\`
   - Verify configuration in \`.env.local\`

2. **Can't access via Traefik**
   - Ensure Traefik labels are uncommented in docker-compose.yml
   - Verify service is in \`web\` network
   - Check Traefik dashboard: http://localhost:8080

## Links

- TODO: Add relevant documentation links
EOF
    
    print_color $GREEN "✅ Service template created: $service_path"
    print_color $BLUE "Next steps:"
    echo "1. Edit $service_path/docker-compose.yml"
    echo "2. Configure $service_path/.env.local"
    echo "3. Update $service_path/README.md"
    echo "4. Start with: ./scripts/manage.sh start $service_name"
}

# Validation
if [ $# -ne 2 ]; then
    print_color $RED "Error: Wrong number of arguments"
    show_usage
    exit 1
fi

category=$1
service_name=$2

# Validate category
if [ ! -d "$SERVICES_DIR/$category" ]; then
    print_color $RED "Error: Category '$category' does not exist"
    echo "Available categories:"
    ls -1 "$SERVICES_DIR" | sed 's/^/  /'
    exit 1
fi

# Validate service name
if [[ ! "$service_name" =~ ^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$ ]]; then
    print_color $RED "Error: Service name must be lowercase alphanumeric with hyphens"
    exit 1
fi

# Check if service already exists
if [ -d "$SERVICES_DIR/$category/$service_name" ]; then
    print_color $RED "Error: Service '$service_name' already exists in category '$category'"
    exit 1
fi

print_color $BLUE "Creating new service: $category/$service_name"
create_service_template "$category" "$service_name"