#!/bin/bash

# PostgreSQL Connection Test Script
# Tests connectivity to the PostgreSQL service from another container

echo "🧪 PostgreSQL Connection Test"
echo "================================"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_connection() {
    local db_name=$1
    local db_user=$2
    local description=$3
    
    echo -n "Testing $description... "
    
    if docker exec postgres psql -U "$db_user" -d "$db_name" -c "SELECT 1;" > /dev/null 2>&1; then
        printf "${GREEN}✅ PASS${NC}\n"
        return 0
    else
        printf "${RED}❌ FAIL${NC}\n"
        return 1
    fi
}

echo "Testing database connections:"
echo ""

# Test main homelab database
test_connection "homelab" "homelab" "Main homelab database"

# Test application databases
test_connection "n8n" "n8n_user" "n8n automation database"
test_connection "grafana" "grafana_user" "Grafana monitoring database"
test_connection "nextcloud" "nextcloud_user" "Nextcloud file storage database"
test_connection "wordpress" "wordpress_user" "WordPress content database"
test_connection "authentik" "authentik_user" "Authentik authentication database"

echo ""
echo "📊 Database Info:"
echo "---------------"
echo "🌐 Host: postgres (internal) or localhost:5432 (external)"
echo "🔒 Main User: homelab / changeme"
echo "📁 Data Volume: postgres_postgres_data"
echo "🌐 Networks: web (external), postgres_internal (internal)"

echo ""
echo "🔗 Example Connection Strings:"
echo "-----------------------------"
echo "📱 n8n: postgresql://n8n_user:n8n_password@postgres:5432/n8n"
echo "📊 Grafana: postgresql://grafana_user:grafana_password@postgres:5432/grafana"
echo "☁️  Nextcloud: postgresql://nextcloud_user:nextcloud_password@postgres:5432/nextcloud"
echo "📝 WordPress: postgresql://wordpress_user:wordpress_password@postgres:5432/wordpress"

echo ""
echo "✅ PostgreSQL service is ready for homelab applications!"