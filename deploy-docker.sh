#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# Kheteebaadi - Quick Deploy with Docker Compose
# Use this to deploy on any server with Docker installed
#
# Run: chmod +x deploy-docker.sh && ./deploy-docker.sh
#
# This starts: PostgreSQL + Redis + FastAPI API + Celery Worker + Celery Beat
# ═══════════════════════════════════════════════════════════════════════════

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${CYAN}"
echo "═══════════════════════════════════════════════════════════"
echo "   KHETEEBAADI - Docker Compose Deployment"
echo "═══════════════════════════════════════════════════════════"
echo -e "${NC}"

# Check Docker
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Docker not found!${NC}"; exit 1; }
command -v docker compose >/dev/null 2>&1 || { echo -e "${RED}Docker Compose not found!${NC}"; exit 1; }

# Generate .env if missing
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${YELLOW}Generating production secrets...${NC}"
    JWT_SECRET=$(openssl rand -hex 32)
    DB_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=' | head -c 40)

    cat > "$SCRIPT_DIR/.env" <<ENVEOF
DB_USER=kheteebaadi_admin
DB_PASSWORD=$DB_PASSWORD
DB_NAME=kheteebaadi
DB_PORT=5432
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_MAX_MEMORY=256mb
REDIS_EVICTION_POLICY=allkeys-lru
JWT_SECRET_KEY=$JWT_SECRET
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
CORS_ORIGINS=["*"]
AWS_REGION=ap-south-1
S3_BUCKET=kheteebaadi-prod
API_PORT=8000
APP_NAME=Kheteebaadi API
APP_VERSION=1.0.0
DEBUG=false
ENVEOF
    echo -e "${GREEN}  Created .env${NC}"
fi

# Also create backend .env
if [ ! -f "$SCRIPT_DIR/backend/.env" ]; then
    source "$SCRIPT_DIR/.env"
    cat > "$SCRIPT_DIR/backend/.env" <<BENVEOF
APP_NAME=Kheteebaadi API
VERSION=1.0.0
DEBUG=false
DATABASE_URL=postgresql+asyncpg://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}
REDIS_URL=redis://redis:6379/0
JWT_SECRET_KEY=${JWT_SECRET_KEY}
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=30
OTP_EXPIRE_SECONDS=300
OTP_LENGTH=6
OTP_MAX_ATTEMPTS_PER_HOUR=5
CORS_ORIGINS=["*"]
AWS_REGION=ap-south-1
S3_BUCKET=kheteebaadi-prod
SYNC_BATCH_MAX_SIZE=50
SYNC_IDEMPOTENCY_TTL_HOURS=72
CACHE_TTL_MANDI_PRICES=900
CACHE_TTL_VILLAGES=3600
CACHE_TTL_MANDIS=3600
RATE_LIMIT_PER_MINUTE=100
BENVEOF
    echo -e "${GREEN}  Created backend/.env${NC}"
fi

# Build and start
echo -e "${YELLOW}Building Docker images...${NC}"
cd "$SCRIPT_DIR"
docker compose -f docker-compose.prod.yml build

echo -e "${YELLOW}Starting services...${NC}"
docker compose -f docker-compose.prod.yml up -d

echo -e "${YELLOW}Waiting for services to become healthy...${NC}"
sleep 10

# Check health
echo ""
echo -e "${CYAN}Service Status:${NC}"
docker compose -f docker-compose.prod.yml ps

echo ""

# Get the server IP
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "localhost")

# Test API
echo -e "${YELLOW}Testing API health...${NC}"
if curl -sf http://localhost:8000/health >/dev/null 2>&1; then
    echo -e "${GREEN}  API is healthy!${NC}"
else
    echo -e "${YELLOW}  API still starting up. Check logs: docker compose -f docker-compose.prod.yml logs -f api${NC}"
fi

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   DEPLOYMENT COMPLETE!${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  API:          http://${SERVER_IP}:8000"
echo -e "  API Docs:     http://${SERVER_IP}:8000/docs"
echo -e "  Health:       http://${SERVER_IP}:8000/health"
echo ""
echo -e "  Useful commands:"
echo -e "    View logs:    docker compose -f docker-compose.prod.yml logs -f"
echo -e "    Stop:         docker compose -f docker-compose.prod.yml down"
echo -e "    Restart:      docker compose -f docker-compose.prod.yml restart"
echo -e "    Rebuild:      docker compose -f docker-compose.prod.yml up -d --build"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
