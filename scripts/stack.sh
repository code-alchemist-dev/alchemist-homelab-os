#!/bin/bash

# ===================================================================
# ALCHEMIST HOMELAB OS - INTELLIGENT STARTUP SCRIPT
# ===================================================================
# This script handles service dependencies and dynamic URL assignment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SERVICES_DIR="$PROJECT_ROOT/services"
ENV_FILE="$PROJECT_ROOT/.env"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_color() {
    printf "${1}${2}${NC}\n"
}

print_banner() {
    echo ""
    print_color $CYAN "🏠⚡ ALCHEMIST HOMELAB OS - INTELLIGENT STARTUP"
    print_color $CYAN "================================================="
    echo ""
}

# Load environment variables
load_env() {
    if [ -f "$ENV_FILE" ]; then
        print_color $BLUE "📋 Loading environment configuration..."
        export $(grep -v '^#' "$ENV_FILE" | xargs)
    else
        print_color $RED "❌ Environment file not found: $ENV_FILE"
        if [ -f "$PROJECT_ROOT/.env.example" ]; then
            print_color $YELLOW "💡 Creating .env from .env.example..."
            cp "$PROJECT_ROOT/.env.example" "$ENV_FILE"
            print_color $GREEN "✅ Environment file created. You can customize it if needed."
            export $(grep -v '^#' "$ENV_FILE" | xargs)
        else
            print_color $RED "❌ No .env.example found either"
            exit 1
        fi
    fi
}

# Ensure Docker network exists
ensure_network() {
    local network_name=${EXTERNAL_NETWORK:-web}
    if ! docker network ls | grep -q "$network_name"; then
        print_color $YELLOW "🌐 Creating Docker network: $network_name"
        docker network create "$network_name"
    else
        print_color $GREEN "✅ Docker network exists: $network_name"
    fi
}

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_color $RED "❌ Docker is not running"
        exit 1
    fi
    print_color $GREEN "✅ Docker is running"
}

# Start a service
start_service() {
    local service_name=$1
    local service_path=""
    
    case $service_name in
        "traefik")
            service_path="$SERVICES_DIR/proxy/traefik"
            ;;
        "cloudflared")
            service_path="$SERVICES_DIR/proxy/cloudflared"
            ;;
        "n8n")
            service_path="$SERVICES_DIR/automation/n8n"
            ;;
        "watchtower")
            service_path="$SERVICES_DIR/maintenance/watchtower"
            ;;
        "monitoring")
            service_path="$SERVICES_DIR/monitoring/grafana-stack"
            ;;
        *)
            print_color $RED "❌ Unknown service: $service_name"
            return 1
            ;;
    esac
    
    if [ -d "$service_path" ]; then
        print_color $BLUE "🚀 Starting $service_name..."
        cd "$service_path"
        docker compose --env-file "$ENV_FILE" up -d
        print_color $GREEN "✅ $service_name started successfully"
    else
        print_color $RED "❌ Service directory not found: $service_path"
        return 1
    fi
}

# Wait for service to be healthy
wait_for_service() {
    local container_name=$1
    local max_attempts=${2:-30}
    local attempt=0
    
    print_color $YELLOW "⏳ Waiting for $container_name to be ready..."
    
    while [ $attempt -lt $max_attempts ]; do
        # Check if container is running
        if docker ps | grep -q "$container_name.*Up"; then
            # For cloudflared, also check if tunnel is established
            if [[ "$container_name" == "cloudflared"* ]]; then
                if docker logs "$container_name" 2>&1 | grep -q "Registered tunnel connection"; then
                    print_color $GREEN "✅ $container_name is ready"
                    return 0
                fi
            else
                print_color $GREEN "✅ $container_name is ready"
                return 0
            fi
        fi
        
        sleep 2
        attempt=$((attempt + 1))
        printf "."
    done
    
    echo ""
    print_color $RED "❌ Timeout waiting for $container_name"
    return 1
}

# Get Cloudflare tunnel URL
get_tunnel_url() {
    local max_attempts=15
    local attempt=0
    
    print_color $YELLOW "🔍 Detecting Cloudflare tunnel URL..."
    
    while [ $attempt -lt $max_attempts ]; do
        local tunnel_url=$(docker logs cloudflared-tunnel 2>&1 | grep "https://.*\.trycloudflare\.com" | tail -1 | grep -o "https://[^[:space:]]*")
        
        if [ -n "$tunnel_url" ]; then
            print_color $GREEN "🌐 Tunnel URL detected: $tunnel_url"
            echo "$tunnel_url"
            return 0
        fi
        
        sleep 2
        attempt=$((attempt + 1))
        printf "."
    done
    
    echo ""
    print_color $YELLOW "⚠️  Could not detect tunnel URL, using fallback"
    echo "https://localhost"
}

# Update environment file with dynamic URL
update_tunnel_url() {
    local tunnel_url=$1
    
    print_color $BLUE "📝 Updating environment file with tunnel URL..."
    
    # Update the main .env file
    sed -i "s|CLOUDFLARED_TUNNEL_URL=.*|CLOUDFLARED_TUNNEL_URL=$tunnel_url|g" "$ENV_FILE"
    sed -i "s|N8N_EDITOR_BASE_URL=.*|N8N_EDITOR_BASE_URL=$tunnel_url|g" "$ENV_FILE"
    sed -i "s|N8N_WEBHOOK_URL=.*|N8N_WEBHOOK_URL=$tunnel_url|g" "$ENV_FILE"
    
    # Update n8n specific .env file if it exists
    local n8n_env="$SERVICES_DIR/automation/n8n/.env"
    if [ -f "$n8n_env" ]; then
        sed -i "s|N8N_EDITOR_BASE_URL=.*|N8N_EDITOR_BASE_URL=$tunnel_url|g" "$n8n_env"
        sed -i "s|WEBHOOK_URL=.*|WEBHOOK_URL=$tunnel_url|g" "$n8n_env"
    fi
    
    print_color $GREEN "✅ Environment files updated with tunnel URL"
}

# Restart service with new configuration
restart_service_with_new_env() {
    local service_name=$1
    
    print_color $BLUE "🔄 Restarting $service_name with updated configuration..."
    
    # Stop the service
    local service_path=""
    case $service_name in
        "n8n")
            service_path="$SERVICES_DIR/automation/n8n"
            ;;
    esac
    
    if [ -d "$service_path" ]; then
        cd "$service_path"
        docker compose --env-file "$ENV_FILE" down
        sleep 2
        docker compose --env-file "$ENV_FILE" up -d
        print_color $GREEN "✅ $service_name restarted with new configuration"
    fi
}

# Display access information
show_access_info() {
    local tunnel_url=$1
    
    echo ""
    print_color $PURPLE "🎉 HOMELAB STARTUP COMPLETE!"
    print_color $PURPLE "=============================="
    echo ""
    print_color $GREEN "🌐 Access Points:"
    print_color $CYAN "   • n8n (Local):      http://localhost"
    print_color $CYAN "   • n8n (External):   $tunnel_url"
    print_color $CYAN "   • Traefik Dashboard: http://localhost:8080"
    print_color $CYAN "   • Grafana Dashboard: http://localhost:3000"
    print_color $CYAN "   • Prometheus:       http://localhost:9090"
    echo ""
    print_color $YELLOW "📊 Service Status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(traefik|cloudflared|n8n)" || echo "   No services running"
    echo ""
}

# Main startup sequence
main() {
    print_banner
    
    # Pre-flight checks
    check_docker
    load_env
    ensure_network
    
    print_color $PURPLE "🚀 Starting services in dependency order..."
    echo ""
    
    # Step 1: Start Traefik (reverse proxy foundation)
    start_service "traefik"
    wait_for_service "traefik" 20
    
    # Step 2: Start Cloudflare tunnel (external access)
    start_service "cloudflared"
    wait_for_service "cloudflared-tunnel" 15
    
    # Step 3: Get tunnel URL and update configuration
    tunnel_url=$(get_tunnel_url)
    update_tunnel_url "$tunnel_url"
    
    # Step 4: Start n8n with updated URL
    start_service "n8n"
    wait_for_service "n8n" 30
    
    # Step 5: Start Watchtower for auto-updates
    start_service "watchtower"
    wait_for_service "watchtower" 15
    
    # Step 6: Start monitoring stack (optional but recommended)
    print_color $BLUE "🚀 Starting monitoring stack (Grafana + Prometheus)..."
    start_service "monitoring" || print_color $YELLOW "⚠️  Monitoring stack failed to start (optional)"
    
    # Final status
    show_access_info "$tunnel_url"
    
    print_color $GREEN "🎊 All services are running with proper dependencies!"
    
    # Offer to start tunnel monitoring
    echo ""
    print_color $YELLOW "💡 Pro Tip: Start tunnel monitoring to auto-update n8n when Cloudflare URL changes:"
    print_color $CYAN "   ./scripts/tunnel-monitor.sh monitor &"
    print_color $CYAN "   # Or run in background: nohup ./scripts/tunnel-monitor.sh monitor > /dev/null 2>&1 &"
}

# Handle command line arguments
case "${1:-start}" in
    "start"|"up")
        main
        ;;
    "stop"|"down")
        print_color $YELLOW "🛑 Stopping all services..."
        cd "$SERVICES_DIR/automation/n8n" && docker compose down || true
        cd "$SERVICES_DIR/proxy/cloudflared" && docker compose down || true
        cd "$SERVICES_DIR/proxy/traefik" && docker compose down || true
        print_color $GREEN "✅ All services stopped"
        ;;
    "restart")
        $0 stop
        sleep 3
        $0 start
        ;;
    "status")
        print_color $BLUE "📊 Service Status:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(traefik|cloudflared|n8n|watchtower|grafana|prometheus)" || echo "No services running"
        ;;
    "url")
        tunnel_url=$(get_tunnel_url)
        print_color $GREEN "🌐 Current tunnel URL: $tunnel_url"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|url}"
        echo ""
        echo "Commands:"
        echo "  start   - Start all services with dependency management"
        echo "  stop    - Stop all services"
        echo "  restart - Restart all services"
        echo "  status  - Show service status"
        echo "  url     - Get current tunnel URL"
        ;;
esac