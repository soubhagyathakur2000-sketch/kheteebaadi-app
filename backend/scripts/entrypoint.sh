#!/bin/bash
# ═════════════════════════════════════════════════════════════════════════════
# Kheteebaadi Backend Entrypoint Script
#
# This script handles production startup tasks:
# 1. Waits for PostgreSQL to be ready
# 2. Runs database migrations (alembic upgrade)
# 3. Starts the FastAPI application
#
# Exit codes:
#   0 - Successful startup
#   1 - Failed to connect to PostgreSQL
#   2 - Database migration failed
#   3 - Application startup failed
# ═════════════════════════════════════════════════════════════════════════════

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
MAX_ATTEMPTS=30
ATTEMPT_INTERVAL=2
POSTGRES_READY_TIMEOUT=5

# Extract PostgreSQL connection details from DATABASE_URL
# Format: postgresql+asyncpg://user:password@host:port/database
if [ -z "$DATABASE_URL" ]; then
    echo -e "${RED}[ERROR] DATABASE_URL environment variable is not set${NC}"
    exit 1
fi

# Parse database connection parameters
# Remove the asyncpg+ prefix if present
DB_CONNECTION_STRING="${DATABASE_URL#postgresql+asyncpg://}"

# Extract user and password
DB_USER_PASS="${DB_CONNECTION_STRING%@*}"
DB_USER="${DB_USER_PASS%:*}"
DB_PASSWORD="${DB_USER_PASS#*:}"

# Extract host and database
DB_HOST_PORT_DB="${DB_CONNECTION_STRING#*@}"
DB_HOST="${DB_HOST_PORT_DB%:*}"
DB_PORT="${DB_HOST_PORT_DB#*:}"
DB_PORT="${DB_PORT%/*}"
DB_NAME="${DB_CONNECTION_STRING##*/}"

echo -e "${YELLOW}[INFO] Starting Kheteebaadi Backend${NC}"
echo -e "${YELLOW}[INFO] Database Host: ${DB_HOST}${NC}"
echo -e "${YELLOW}[INFO] Database Port: ${DB_PORT}${NC}"
echo -e "${YELLOW}[INFO] Database Name: ${DB_NAME}${NC}"

# ═════════════════════════════════════════════════════════════════════════════
# Step 1: Wait for PostgreSQL to be ready
# ═════════════════════════════════════════════════════════════════════════════

echo -e "${YELLOW}[INFO] Waiting for PostgreSQL to be ready...${NC}"

ATTEMPT=0
POSTGRES_READY=false

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    echo -e "${YELLOW}[INFO] PostgreSQL connection attempt ${ATTEMPT}/${MAX_ATTEMPTS}...${NC}"

    # Use pg_isready to check if PostgreSQL is accepting connections
    if pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -t "$POSTGRES_READY_TIMEOUT" > /dev/null 2>&1; then
        echo -e "${GREEN}[SUCCESS] PostgreSQL is ready${NC}"
        POSTGRES_READY=true
        break
    fi

    if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
        echo -e "${YELLOW}[INFO] PostgreSQL not ready, waiting ${ATTEMPT_INTERVAL} seconds...${NC}"
        sleep "$ATTEMPT_INTERVAL"
    fi
done

if [ "$POSTGRES_READY" = false ]; then
    echo -e "${RED}[ERROR] PostgreSQL failed to become ready after ${MAX_ATTEMPTS} attempts${NC}"
    exit 1
fi

# ═════════════════════════════════════════════════════════════════════════════
# Step 2: Run database migrations
# ═════════════════════════════════════════════════════════════════════════════

echo -e "${YELLOW}[INFO] Running database migrations...${NC}"

if alembic upgrade head; then
    echo -e "${GREEN}[SUCCESS] Database migrations completed${NC}"
else
    echo -e "${RED}[ERROR] Database migrations failed${NC}"
    exit 2
fi

# ═════════════════════════════════════════════════════════════════════════════
# Step 3: Start the FastAPI application
# ═════════════════════════════════════════════════════════════════════════════

echo -e "${GREEN}[INFO] Starting FastAPI application${NC}"

# Execute the CMD from Dockerfile
# This replaces the current shell process with the application
exec "$@"
