#!/bin/bash

# ===================================================================
# ALCHEMIST HOMELAB OS - CLOUDFLARE TUNNEL MONITOR
# ===================================================================
# This script monitors Cloudflare tunnel for URL changes and updates n8n

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_ROOT/.env"
LOCK_FILE="/tmp/tunnel-monitor.lock"
LOG_FILE="/tmp/tunnel-monitor.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_color() {
    printf "${1}${2}${NC}\n"
}

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if already running
check_lock() {
    if [ -f "$LOCK_FILE" ]; then
        local pid=$(cat "$LOCK_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            log_message "Monitor already running with PID $pid"
            exit 1
        else
            log_message "Removing stale lock file"
            rm -f "$LOCK_FILE"
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

# Cleanup on exit
cleanup() {
    rm -f "$LOCK_FILE"
    log_message "Tunnel monitor stopped"
}

trap cleanup EXIT

# Get current tunnel URL from logs
get_current_tunnel_url() {
    local url=$(docker logs cloudflared-tunnel 2>&1 | grep "https://.*\.trycloudflare\.com" | tail -1 | grep -o "https://[^[:space:]]*" 2>/dev/null || echo "")
    echo "$url"
}

# Get stored tunnel URL from environment
get_stored_tunnel_url() {
    if [ -f "$ENV_FILE" ]; then
        grep "^CLOUDFLARED_TUNNEL_URL=" "$ENV_FILE" | cut -d'=' -f2 || echo ""
    else
        echo ""
    fi
}

# Update environment file with new URL
update_environment_urls() {
    local new_url=$1
    
    if [ -f "$ENV_FILE" ]; then
        # Update all URL references
        sed -i "s|CLOUDFLARED_TUNNEL_URL=.*|CLOUDFLARED_TUNNEL_URL=$new_url|g" "$ENV_FILE"
        sed -i "s|N8N_EDITOR_BASE_URL=.*|N8N_EDITOR_BASE_URL=$new_url|g" "$ENV_FILE"
        sed -i "s|N8N_WEBHOOK_URL=.*|N8N_WEBHOOK_URL=$new_url|g" "$ENV_FILE"
        
        log_message "Updated environment file with new URL: $new_url"
        return 0
    else
        log_message "ERROR: Environment file not found: $ENV_FILE"
        return 1
    fi
}

# Restart n8n with new configuration
restart_n8n() {
    log_message "Restarting n8n with updated configuration..."
    
    # Restart n8n using docker compose
    cd "$PROJECT_ROOT/services/automation/n8n"
    docker compose --env-file "$ENV_FILE" down
    sleep 2
    docker compose --env-file "$ENV_FILE" up -d
    
    if [ $? -eq 0 ]; then
        log_message "n8n restarted successfully"
        return 0
    else
        log_message "ERROR: Failed to restart n8n"
        return 1
    fi
}

# Check if Cloudflared container restarted
check_container_restart() {
    local container_name="cloudflared-tunnel"
    local last_restart_file="/tmp/cloudflared_last_restart"
    
    # Get container start time
    local start_time=$(docker inspect "$container_name" --format='{{.State.StartedAt}}' 2>/dev/null || echo "")
    
    if [ -z "$start_time" ]; then
        log_message "WARNING: Could not get container start time for $container_name"
        return 1
    fi
    
    # Check if this is a new start time
    if [ -f "$last_restart_file" ]; then
        local last_start_time=$(cat "$last_restart_file")
        if [ "$start_time" != "$last_start_time" ]; then
            echo "$start_time" > "$last_restart_file"
            log_message "Detected container restart: $container_name"
            return 0
        fi
    else
        echo "$start_time" > "$last_restart_file"
        log_message "Initialized restart tracking for $container_name"
        return 1
    fi
    
    return 1
}

# Monitor tunnel URL changes
monitor_tunnel_changes() {
    local check_interval=${1:-30}  # Check every 30 seconds by default
    
    log_message "Starting tunnel URL monitor (interval: ${check_interval}s)"
    
    while true; do
        # Check if cloudflared container restarted
        if check_container_restart; then
            log_message "Container restart detected, waiting for new tunnel URL..."
            sleep 10  # Wait for tunnel to establish
        fi
        
        # Get current URLs
        local current_url=$(get_current_tunnel_url)
        local stored_url=$(get_stored_tunnel_url)
        
        # Check if we have a valid current URL
        if [ -n "$current_url" ] && [[ "$current_url" =~ ^https://.*\.trycloudflare\.com$ ]]; then
            # Compare with stored URL
            if [ "$current_url" != "$stored_url" ]; then
                log_message "Tunnel URL changed!"
                log_message "  Old URL: $stored_url"
                log_message "  New URL: $current_url"
                
                # Update environment and restart n8n
                if update_environment_urls "$current_url"; then
                    if restart_n8n; then
                        log_message "Successfully updated n8n with new tunnel URL"
                    else
                        log_message "ERROR: Failed to restart n8n"
                    fi
                else
                    log_message "ERROR: Failed to update environment file"
                fi
            fi
        else
            if [ -n "$stored_url" ]; then
                log_message "WARNING: Could not detect valid tunnel URL, keeping stored URL: $stored_url"
            fi
        fi
        
        sleep "$check_interval"
    done
}

# Show current status
show_status() {
    log_message "=== TUNNEL MONITOR STATUS ==="
    log_message "Current tunnel URL: $(get_current_tunnel_url)"
    log_message "Stored tunnel URL:  $(get_stored_tunnel_url)"
    log_message "Cloudflared status: $(docker ps --filter name=cloudflared-tunnel --format '{{.Status}}' || echo 'Not running')"
    log_message "n8n status:         $(docker ps --filter name=n8n --format '{{.Status}}' || echo 'Not running')"
    log_message "=========================="
}

# Main function
main() {
    local command=${1:-"monitor"}
    local interval=${2:-30}
    
    case $command in
        "monitor")
            check_lock
            log_message "Starting Cloudflare tunnel monitor..."
            show_status
            monitor_tunnel_changes "$interval"
            ;;
        "status")
            show_status
            ;;
        "update")
            log_message "Manual tunnel URL update requested"
            local current_url=$(get_current_tunnel_url)
            if [ -n "$current_url" ]; then
                update_environment_urls "$current_url"
                restart_n8n
            else
                log_message "ERROR: Could not detect tunnel URL"
                exit 1
            fi
            ;;
        "stop")
            if [ -f "$LOCK_FILE" ]; then
                local pid=$(cat "$LOCK_FILE")
                if ps -p "$pid" > /dev/null 2>&1; then
                    kill "$pid"
                    log_message "Stopped tunnel monitor (PID: $pid)"
                else
                    log_message "Monitor not running"
                fi
                rm -f "$LOCK_FILE"
            else
                log_message "Monitor not running"
            fi
            ;;
        *)
            echo "Usage: $0 {monitor|status|update|stop} [interval]"
            echo ""
            echo "Commands:"
            echo "  monitor [interval]  - Start monitoring (default interval: 30s)"
            echo "  status             - Show current status"
            echo "  update             - Force URL update"
            echo "  stop               - Stop monitoring"
            echo ""
            echo "Examples:"
            echo "  $0 monitor 60      # Monitor with 60s interval"
            echo "  $0 status          # Show current status"
            exit 1
            ;;
    esac
}

main "$@"