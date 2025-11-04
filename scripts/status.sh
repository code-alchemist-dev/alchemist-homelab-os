#!/bin/bash

# Alchemist Homelab OS - Repository Summary & Status

echo "🏠⚡ ALCHEMIST HOMELAB OS - REPOSITORY STATUS"
echo "=============================================="
echo ""

echo "📊 REPOSITORY STATISTICS:"
echo "├── Commits: $(git rev-list --count HEAD)"
echo "├── Files: $(find . -type f | grep -v '.git' | grep -v 'n8n_data' | wc -l)"
echo "├── Services: $(find services -name 'docker-compose.yml' | wc -l)"
echo "└── Scripts: $(find scripts -name '*.sh' | wc -l)"
echo ""

echo "📁 PROJECT STRUCTURE:"
tree -I '.git|n8n_data' || find . -type d | grep -v '.git' | head -20

echo ""
echo "🚀 AVAILABLE COMMANDS:"
echo "├── ./scripts/stack.sh start     # Intelligent startup with dependencies"
echo "├── ./scripts/stack.sh stop      # Graceful shutdown"
echo "├── ./scripts/stack.sh status    # Service status check"
echo "├── ./scripts/manage.sh start    # Individual service management"
echo "└── ./scripts/new-service.sh     # Add new services"
echo ""

echo "🌐 CURRENT ACCESS POINTS:"
if docker ps | grep -q "traefik.*Up"; then
    echo "├── ✅ Traefik Dashboard: http://localhost:8080"
else
    echo "├── ❌ Traefik: Not running"
fi

if docker ps | grep -q "n8n.*Up"; then
    echo "├── ✅ n8n (Local): http://localhost"
else
    echo "├── ❌ n8n: Not running"
fi

if docker ps | grep -q "cloudflared.*Up"; then
    TUNNEL_URL=$(docker logs cloudflared-tunnel 2>&1 | grep "https://.*\.trycloudflare\.com" | tail -1 | grep -o "https://[^[:space:]]*" || echo "Not detected")
    echo "└── ✅ n8n (External): $TUNNEL_URL"
else
    echo "└── ❌ Cloudflare Tunnel: Not running"
fi

echo ""
echo "📋 GIT STATUS:"
git status --short || git status

echo ""
echo "🎉 READY FOR HOMELAB ADVENTURES!"
echo "Start with: ./scripts/stack.sh start"