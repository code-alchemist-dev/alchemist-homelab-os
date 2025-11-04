#!/bin/bash

# Alchemist Homelab OS - Service Management Script
# Usage: ./scripts/manage.sh [start|stop|restart|status] [service]

set -e

SERVICES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../services" && pwd)"
SCRIPT_NAME=$(basename "$0")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_color() {
    printf "${1}${2}${NC}\n"
}

# Show usage
show_usage() {
    echo "Usage: $SCRIPT_NAME [command] [service]"
    echo ""
    echo "Commands:"
    echo "  start     - Start services"
    echo "  stop      - Stop services"
    echo "  restart   - Restart services"
    echo "  status    - Show service status"
    echo "  logs      - Show service logs"
    echo "  update    - Update service images"
    echo ""
    echo "Services:"
    echo "  all       - All services (default)"
    echo "  proxy     - Traefik and Cloudflared"
    echo "  traefik   - Traefik reverse proxy"
    echo "  cloudflared - Cloudflare tunnel"
    echo "  n8n       - n8n automation"
    echo ""
    echo "Examples:"
    echo "  $SCRIPT_NAME start all"
    echo "  $SCRIPT_NAME stop n8n"
    echo "  $SCRIPT_NAME logs traefik"
}

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_color $RED "Error: Docker is not running"
        exit 1
    fi
}

# Ensure web network exists
ensure_network() {
    if ! docker network ls | grep -q "web"; then
        print_color $YELLOW "Creating web network..."
        docker network create web
    fi
}

# Start services
start_services() {
    local service=$1
    ensure_network
    
    case $service in
        "all")
            print_color $BLUE "Starting all services..."
            start_service "traefik"
            sleep 2
            start_service "n8n"
            sleep 2
            start_service "cloudflared"
            show_tunnel_url
            ;;
        "proxy")
            start_service "traefik"
            start_service "cloudflared"
            show_tunnel_url
            ;;
        "traefik"|"n8n"|"cloudflared")
            start_service "$service"
            if [ "$service" = "cloudflared" ]; then
                show_tunnel_url
            fi
            ;;
        *)
            print_color $RED "Unknown service: $service"
            show_usage
            exit 1
            ;;
    esac
}

# Start individual service
start_service() {
    local service=$1
    local service_path=""
    
    case $service in
        "traefik")
            service_path="$SERVICES_DIR/proxy/traefik"
            ;;
        "n8n")
            service_path="$SERVICES_DIR/automation/n8n"
            ;;
        "cloudflared")
            service_path="$SERVICES_DIR/proxy/cloudflared"
            ;;
    esac
    
    if [ -d "$service_path" ]; then
        print_color $GREEN "Starting $service..."
        cd "$service_path"
        docker compose up -d
    else
        print_color $RED "Service directory not found: $service_path"
        exit 1
    fi
}

# Stop services
stop_services() {
    local service=$1
    
    case $service in
        "all")
            print_color $BLUE "Stopping all services..."
            stop_service "cloudflared"
            stop_service "n8n"
            stop_service "traefik"
            ;;
        "proxy")
            stop_service "cloudflared"
            stop_service "traefik"
            ;;
        "traefik"|"n8n"|"cloudflared")
            stop_service "$service"
            ;;
        *)
            print_color $RED "Unknown service: $service"
            show_usage
            exit 1
            ;;
    esac
}

# Stop individual service
stop_service() {
    local service=$1
    local service_path=""
    
    case $service in
        "traefik")
            service_path="$SERVICES_DIR/proxy/traefik"
            ;;
        "n8n")
            service_path="$SERVICES_DIR/automation/n8n"
            ;;
        "cloudflared")
            service_path="$SERVICES_DIR/proxy/cloudflared"
            ;;
    esac
    
    if [ -d "$service_path" ]; then
        print_color $YELLOW "Stopping $service..."
        cd "$service_path"
        docker compose down
    else
        print_color $RED "Service directory not found: $service_path"
        exit 1
    fi
}

# Show service status
show_status() {
    print_color $BLUE "Service Status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(traefik|n8n|cloudflared)" || print_color $YELLOW "No services running"
}

# Show logs
show_logs() {
    local service=$1
    local container_name=""
    
    case $service in
        "traefik")
            container_name="traefik"
            ;;
        "n8n")
            container_name="n8n"
            ;;
        "cloudflared")
            container_name="cloudflared-tunnel"
            ;;
        *)
            print_color $RED "Unknown service: $service"
            show_usage
            exit 1
            ;;
    esac
    
    print_color $BLUE "Showing logs for $service..."
    docker logs -f "$container_name"
}

# Show tunnel URL
show_tunnel_url() {
    print_color $BLUE "Getting Cloudflare tunnel URL..."
    sleep 3
    local url=$(docker logs cloudflared-tunnel 2>/dev/null | grep "Visit it at" | tail -1 | sed 's/.*https:/https:/' | tr -d ' \r\n')
    if [ -n "$url" ]; then
        print_color $GREEN "🌐 Your n8n is accessible at: $url"
    else
        print_color $YELLOW "Tunnel URL not ready yet. Check logs: docker logs cloudflared-tunnel"
    fi
}

# Update services
update_services() {
    local service=$1
    
    case $service in
        "all")
            update_service "traefik"
            update_service "n8n"
            update_service "cloudflared"
            ;;
        "traefik"|"n8n"|"cloudflared")
            update_service "$service"
            ;;
        *)
            print_color $RED "Unknown service: $service"
            show_usage
            exit 1
            ;;
    esac
}

# Update individual service
update_service() {
    local service=$1
    local service_path=""
    
    case $service in
        "traefik")
            service_path="$SERVICES_DIR/proxy/traefik"
            ;;
        "n8n")
            service_path="$SERVICES_DIR/automation/n8n"
            ;;
        "cloudflared")
            service_path="$SERVICES_DIR/proxy/cloudflared"
            ;;
    esac
    
    if [ -d "$service_path" ]; then
        print_color $BLUE "Updating $service..."
        cd "$service_path"
        docker compose pull
        docker compose up -d
    else
        print_color $RED "Service directory not found: $service_path"
        exit 1
    fi
}

# Main script logic
main() {
    check_docker
    
    local command=${1:-"help"}
    local service=${2:-"all"}
    
    case $command in
        "start")
            start_services "$service"
            ;;
        "stop")
            stop_services "$service"
            ;;
        "restart")
            stop_services "$service"
            sleep 2
            start_services "$service"
            ;;
        "status")
            show_status
            ;;
        "logs")
            if [ "$service" = "all" ]; then
                print_color $RED "Please specify a service for logs"
                show_usage
                exit 1
            fi
            show_logs "$service"
            ;;
        "update")
            update_services "$service"
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            print_color $RED "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"