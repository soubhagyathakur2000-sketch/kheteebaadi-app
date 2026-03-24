# Kheteebaadi Production Deployment Guide

This document provides instructions for deploying the Kheteebaadi AgTech platform using Docker and Docker Compose in a production environment.

## Overview

The production setup includes:
- **FastAPI Backend** - REST API for the agricultural marketplace
- **PostgreSQL 15** - Primary relational database with Alpine optimization
- **Redis 7** - In-memory cache and Celery message broker
- **Celery Workers** - Background task processing for async operations
- **Celery Beat** - Scheduled task scheduler for recurring jobs

## Files Created

### Docker Configuration
- **`backend/Dockerfile`** - Multi-stage production Dockerfile for the FastAPI API
  - Stage 1 (Builder): Installs build dependencies and Python packages
  - Stage 2 (Runtime): Minimal image with only runtime requirements
  - Security: Non-root user, health checks, optimized image size

- **`backend/Dockerfile.worker`** - Multi-stage Dockerfile for Celery workers
  - Same builder pattern as the main API
  - Optimized for background task processing
  - Can be scaled independently for high task volume

- **`backend/.dockerignore`** - Excludes unnecessary files from Docker builds
  - Reduces image size and build time
  - Prevents accidental inclusion of secrets or test files

- **`backend/scripts/entrypoint.sh`** - Production entrypoint script
  - Waits for PostgreSQL to be ready using `pg_isready`
  - Runs database migrations with Alembic
  - Ensures proper application startup sequence

### Compose Configuration
- **`docker-compose.prod.yml`** - Production-ready Docker Compose configuration
  - Services: api, celery-worker, celery-beat, db, redis
  - Named volumes for persistent data
  - Health checks for all services
  - Custom bridge network for inter-service communication
  - Environment variable template loading from `.env` file

### Environment Configuration
- **`.env.example.prod`** - Example environment variables for production
  - Complete template with all configurable options
  - Security checklist and recommendations
  - Comments explaining each setting

## Quick Start

### 1. Prepare Environment Variables

```bash
# Copy the example environment file
cp .env.example.prod .env

# Edit the file with your production values
# CRITICAL: Set these values:
# - JWT_SECRET_KEY (generate with: openssl rand -hex 32)
# - DB_PASSWORD (use strong password)
# - CORS_ORIGINS (your actual frontend domain)
# - AWS credentials (if using S3)
nano .env
```

### 2. Build Docker Images

```bash
# Build the API image
docker build -t kheteebaadi-api:latest ./backend

# Build the worker image
docker build -t kheteebaadi-worker:latest -f ./backend/Dockerfile.worker ./backend

# Or build both with compose
docker compose -f docker-compose.prod.yml build
```

### 3. Start Services

```bash
# Start all services in detached mode
docker compose -f docker-compose.prod.yml up -d

# View logs
docker compose -f docker-compose.prod.yml logs -f

# View specific service logs
docker compose -f docker-compose.prod.yml logs -f api
docker compose -f docker-compose.prod.yml logs -f celery-worker
```

### 4. Verify Health

```bash
# Check service status
docker compose -f docker-compose.prod.yml ps

# Test API health
curl http://localhost:8000/health

# Test database connection
docker compose -f docker-compose.prod.yml exec db psql -U kheteebaadi_prod -d kheteebaadi_prod -c "SELECT version();"

# Test Redis connection
docker compose -f docker-compose.prod.yml exec redis redis-cli ping
```

## Configuration Details

### Database Configuration

**PostgreSQL 15-Alpine** provides a minimal base image with:
- Size: ~150MB vs 500MB+ for non-Alpine
- Security: Reduced attack surface
- Health checks ensure readiness before API starts
- Volume persistence ensures data survives container restarts

```yaml
db:
  image: postgres:15-alpine
  environment:
    POSTGRES_DB: ${DB_NAME}
    POSTGRES_USER: ${DB_USER}
    POSTGRES_PASSWORD: ${DB_PASSWORD}
```

### Redis Configuration

**Redis 7-Alpine** optimized for production use:
- LRU eviction policy prevents out-of-memory errors
- AOF persistence for data durability
- Authentication support via `REDIS_PASSWORD` variable
- Health checks verify connectivity

```yaml
redis:
  image: redis:7-alpine
  command: >
    redis-server
    --maxmemory ${REDIS_MAX_MEMORY:-256mb}
    --maxmemory-policy ${REDIS_EVICTION_POLICY:-allkeys-lru}
    --appendonly yes
    --appendfsync everysec
```

### API Configuration

**FastAPI Backend** runs with:
- Uvicorn ASGI server (2 workers for balanced concurrency)
- Health check endpoint at `/health`
- Non-root user for security (UID 1000)
- Automatic database migration before startup
- Graceful handling of dependencies

Key configuration in Dockerfile:
```dockerfile
# Multi-worker setup balances concurrency vs memory usage
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
```

### Celery Worker Configuration

**Celery Workers** handle:
- Background task processing (mandi price refresh, notifications, etc.)
- Task queues for different priorities
- Concurrency level: 2 (adjustable via environment)
- Integration with Redis message broker

```yaml
celery-worker:
  build:
    context: ./backend
    dockerfile: Dockerfile.worker
  command: celery -A app.workers.celery_app worker --loglevel=info --concurrency=2
```

### Celery Beat Configuration

**Celery Beat** manages scheduled tasks:
- Hourly mandi price refresh
- Daily sync log cleanup (2 AM UTC)
- Daily report generation (11:59 PM UTC)
- Configurable via `backend/app/workers/celery_app.py`

## Scaling for Production

### Horizontal Scaling

Scale worker instances for high task volume:

```bash
# Scale to 3 worker instances
docker compose -f docker-compose.prod.yml up -d --scale celery-worker=3
```

### Resource Limits

Enable resource constraints in `docker-compose.prod.yml`:

```yaml
api:
  deploy:
    resources:
      limits:
        cpus: '1'
        memory: 512M
      reservations:
        cpus: '0.5'
        memory: 256M
```

### Performance Tuning

**For High Throughput:**
- Increase API workers: `--workers 4` or `--workers 8`
- Increase Celery concurrency: `--concurrency=4`
- Scale multiple worker containers
- Use load balancer (nginx, HAProxy)

**For High Memory Usage:**
- Reduce worker count
- Enable swap monitoring
- Monitor database connection pool
- Use connection pooling with pgBouncer

## Security Best Practices

### 1. Environment Variables
- Never commit `.env` file to git
- Use strong, randomly generated secrets
- Rotate secrets regularly
- Use secrets manager in production (AWS Secrets Manager, HashiCorp Vault)

### 2. Database Security
- Use strong passwords (32+ characters)
- Run PostgreSQL with minimal privileges
- Enable SSL/TLS for connections
- Use managed database service in cloud (RDS, Cloud SQL)
- Regular backups to separate storage

### 3. Redis Security
- Enable `requirepass` authentication
- Use managed Redis service if available
- Restrict network access
- Monitor for unauthorized access

### 4. API Security
- CORS origins must match actual frontend domains
- Enable HTTPS at reverse proxy (nginx, ALB)
- Rate limiting enabled and configured
- JWT secret rotated regularly
- Monitor logs for suspicious activity

### 5. Container Security
- Images run as non-root user
- Use specific version tags (not `latest`)
- Scan images for vulnerabilities
- Keep base images updated
- Use private container registry

## Monitoring and Logging

### Application Logs

```bash
# Follow API logs
docker compose -f docker-compose.prod.yml logs -f api

# Follow worker logs
docker compose -f docker-compose.prod.yml logs -f celery-worker

# View all logs with timestamps
docker compose -f docker-compose.prod.yml logs --timestamps
```

### Database Monitoring

```bash
# Connect to PostgreSQL
docker compose -f docker-compose.prod.yml exec db psql -U kheteebaadi_prod -d kheteebaadi_prod

# Check active connections
SELECT count(*) FROM pg_stat_activity;

# Check database size
SELECT pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname))
FROM pg_database ORDER BY pg_database_size(pg_database.datname) DESC;
```

### Redis Monitoring

```bash
# Monitor Redis info
docker compose -f docker-compose.prod.yml exec redis redis-cli INFO

# Check memory usage
docker compose -f docker-compose.prod.yml exec redis redis-cli INFO memory

# Monitor real-time commands
docker compose -f docker-compose.prod.yml exec redis redis-cli MONITOR
```

## Troubleshooting

### API Failed to Start

1. Check logs:
```bash
docker compose -f docker-compose.prod.yml logs api
```

2. Verify database is ready:
```bash
docker compose -f docker-compose.prod.yml logs db
```

3. Check PostgreSQL connection:
```bash
docker compose -f docker-compose.prod.yml exec db pg_isready -U kheteebaadi_prod
```

### Worker Not Processing Tasks

1. Check worker logs:
```bash
docker compose -f docker-compose.prod.yml logs celery-worker
```

2. Verify Redis is running:
```bash
docker compose -f docker-compose.prod.yml logs redis
docker compose -f docker-compose.prod.yml exec redis redis-cli ping
```

3. Check Celery tasks in Redis:
```bash
docker compose -f docker-compose.prod.yml exec redis redis-cli
> KEYS celery*
> LLEN celery
```

### Database Migration Failed

1. Check migration logs:
```bash
docker compose -f docker-compose.prod.yml logs api | grep -i alembic
```

2. Manually run migrations:
```bash
docker compose -f docker-compose.prod.yml exec api alembic upgrade head
```

3. Check migration status:
```bash
docker compose -f docker-compose.prod.yml exec api alembic current
docker compose -f docker-compose.prod.yml exec api alembic history
```

## Cleanup and Maintenance

### Stop Services
```bash
# Stop all services but keep volumes
docker compose -f docker-compose.prod.yml down

# Stop and remove volumes (caution: data loss)
docker compose -f docker-compose.prod.yml down -v
```

### Database Backup
```bash
# Backup PostgreSQL database
docker compose -f docker-compose.prod.yml exec db pg_dump -U kheteebaadi_prod kheteebaadi_prod > backup.sql

# Restore from backup
docker compose -f docker-compose.prod.yml exec -T db psql -U kheteebaadi_prod kheteebaadi_prod < backup.sql
```

### Redis Backup
```bash
# Redis already configured with AOF persistence (appendonly yes)
# Backup the Redis data volume
docker run --rm -v kheteebaadi_redis_data:/data -v $(pwd):/backup alpine tar czf /backup/redis_backup.tar.gz /data
```

## Production Checklist

Before going live, verify:

- [ ] `.env` file configured with all required variables
- [ ] JWT_SECRET_KEY generated securely
- [ ] Database password is strong (32+ chars)
- [ ] CORS_ORIGINS updated to actual frontend domain(s)
- [ ] DEBUG set to `false`
- [ ] AWS S3 credentials configured (if using file uploads)
- [ ] SSL/TLS certificates configured at reverse proxy
- [ ] Database backups automated and tested
- [ ] Redis persistence (AOF) enabled
- [ ] Monitoring and alerting configured
- [ ] Log aggregation set up
- [ ] Regular security updates planned
- [ ] Disaster recovery plan documented

## Deployment Strategies

### Blue-Green Deployment

```bash
# Start new "green" stack
docker compose -f docker-compose.prod.yml -p kheteebaadi-green up -d

# Test green stack, then switch traffic

# Stop old "blue" stack
docker compose -f docker-compose.prod.yml -p kheteebaadi-blue down
```

### Rolling Deployment

Update and restart services one at a time to maintain availability:

```bash
# Update database (if needed)
# Update API image and restart
docker compose -f docker-compose.prod.yml up -d api

# Update workers one by one
docker compose -f docker-compose.prod.yml up -d celery-worker
```

## Support and Documentation

- API Documentation: http://localhost:8000/docs
- Celery Flower (task monitoring): Configure separate service if needed
- Database Docs: https://www.postgresql.org/docs/15/
- Redis Docs: https://redis.io/documentation
- FastAPI Docs: https://fastapi.tiangolo.com/
- Celery Docs: https://docs.celeryproject.io/

## Next Steps

1. **Set up monitoring** - ELK Stack, Prometheus, DataDog, New Relic
2. **Configure backups** - Automated database and Redis snapshots
3. **Set up load balancing** - nginx, HAProxy, or cloud load balancer
4. **Enable CI/CD** - GitHub Actions, GitLab CI for automated deployments
5. **Implement auto-scaling** - Kubernetes, AWS ECS, or Docker Swarm
6. **Security hardening** - WAF, DDoS protection, intrusion detection
