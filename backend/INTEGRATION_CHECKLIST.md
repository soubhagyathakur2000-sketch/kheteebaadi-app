# Kheteebaadi Backend - Integration Checklist

Complete checklist for integrating the backend with your Flutter app or deployment.

## Pre-Deployment Checklist

### Environment Setup
- [ ] Copy `.env.example` to `.env`
- [ ] Set `JWT_SECRET_KEY` to a secure random value (minimum 32 characters)
- [ ] Configure `DATABASE_URL` with production PostgreSQL credentials
- [ ] Configure `REDIS_URL` with production Redis instance
- [ ] Update `CORS_ORIGINS` with your app domain/URL
- [ ] Set `DEBUG=False` for production
- [ ] Review and update all configuration values in `.env`

### Database Setup
- [ ] PostgreSQL 13+ installed and running
- [ ] Database `kheteebaadi` created
- [ ] User with proper permissions created
- [ ] Run migrations: `alembic upgrade head`
- [ ] Verify all tables created: 7 tables total

### Redis Setup
- [ ] Redis 6+ installed and running
- [ ] Accessible from application
- [ ] Optional: Configure Redis persistence if needed

### Dependencies
- [ ] Python 3.11+ installed
- [ ] Install all dependencies: `pip install -r requirements.txt`
- [ ] Verify installations: `python -c "import fastapi; print(fastapi.__version__)"`

## Backend Development Checklist

### Application Start
- [ ] Start PostgreSQL service
- [ ] Start Redis service
- [ ] Create Python virtual environment
- [ ] Install dependencies
- [ ] Run migrations: `alembic upgrade head`
- [ ] Start API server: `uvicorn app.main:app --reload`
- [ ] Verify health check: `curl http://localhost:8000/health`
- [ ] Access API docs: `http://localhost:8000/docs`

### Background Jobs (Optional)
- [ ] Start Celery worker: `celery -A app.workers.celery_app worker --loglevel=info`
- [ ] Start Celery beat: `celery -A app.workers.celery_app beat --loglevel=info`
- [ ] Verify task queues initialized

## API Testing Checklist

### Authentication Flow
- [ ] Test OTP request: `POST /api/v1/auth/otp/request`
  - Input: Valid Indian phone number
  - Expected: OTP sent, 300 second expiry
  - Check: OTP stored in Redis

- [ ] Test OTP verification: `POST /api/v1/auth/otp/verify`
  - Input: Phone + valid OTP
  - Expected: Access token, refresh token, user object
  - Check: Tokens stored in Redis

- [ ] Test token refresh: `POST /api/v1/auth/refresh`
  - Input: Refresh token
  - Expected: New access token
  - Check: Old token still valid until expiry

- [ ] Test logout: `POST /api/v1/auth/logout`
  - Input: Valid access token
  - Expected: 200 OK, token blacklisted
  - Check: Token removed from Redis

- [ ] Test invalid token: Request with bad JWT
  - Expected: 401 Unauthorized

- [ ] Test expired token: Use token after expiry
  - Expected: 401 Unauthorized

### Mandi Prices
- [ ] Seed test data to mandi_prices table
- [ ] Test list prices: `GET /api/v1/mandi/prices`
  - Expected: Paginated list, cache metadata

- [ ] Test price search: `GET /api/v1/mandi/search?query=wheat`
  - Expected: Matching results

- [ ] Test regional filter: `GET /api/v1/mandi/prices?region_id=MP`
  - Expected: Filtered results

- [ ] Test nearby mandis: `GET /api/v1/mandi/nearby?latitude=22.7&longitude=75.8&radius_km=50`
  - Expected: Mandis within radius sorted by distance

- [ ] Test cache: Call same endpoint twice
  - Expected: Second call shows `cached=true`

### Orders
- [ ] Create test user via OTP flow
- [ ] Test create order: `POST /api/v1/orders`
  - Input: Order with 1+ items, delivery address
  - Expected: 201 Created, order_number generated

- [ ] Test list orders: `GET /api/v1/orders`
  - Expected: User's orders only

- [ ] Test order detail: `GET /api/v1/orders/{order_id}`
  - Expected: Full order with items

- [ ] Test status update: `PATCH /api/v1/orders/{order_id}/status`
  - Input: New status (confirmed, processing, etc.)
  - Expected: Updated status

- [ ] Test cancellation: `POST /api/v1/orders/{order_id}/cancel`
  - Expected: Order status changed to cancelled

- [ ] Test permission: Try accessing other user's order
  - Expected: 403 Forbidden

### Sync (Offline-First)
- [ ] Create test offline order payload
- [ ] Test sync batch: `POST /api/v1/sync/batch`
  - Input: 1-50 sync items with idempotency keys
  - Expected: Per-item results with status

- [ ] Test duplicate handling: Sync same item twice
  - First attempt: status=success
  - Second attempt: status=duplicate

- [ ] Test batch size limit: Send 51 items
  - Expected: 422 Validation error

- [ ] Test error handling: Invalid delivery address
  - Expected: status=failed with error message

- [ ] Test idempotency: Network retry (same key)
  - Expected: Returns same result, no duplication

### Users
- [ ] Test get profile: `GET /api/v1/users/me`
  - Expected: Current user data

- [ ] Test update profile: `PATCH /api/v1/users/me`
  - Input: name, language_pref
  - Expected: Updated profile

- [ ] Test stats: `GET /api/v1/users/me/stats`
  - Expected: order_count, total_spent, recent_orders

### Villages
- [ ] Seed test villages to database
- [ ] Test list: `GET /api/v1/villages`
  - Expected: Paginated list

- [ ] Test search: `GET /api/v1/villages?search=indore`
  - Expected: Matching villages

- [ ] Test detail: `GET /api/v1/villages/{village_id}`
  - Expected: Full village data

- [ ] Test nearby: `GET /api/v1/villages/nearby?latitude=22.7&longitude=75.8`
  - Expected: Villages within radius, sorted by distance

### Rate Limiting
- [ ] Send 100 requests in rapid succession
  - Expected: All succeed

- [ ] Send 101st request immediately
  - Expected: 429 Too Many Requests

- [ ] Wait 1 minute, send request
  - Expected: Success (window reset)

### Logging
- [ ] Check application logs (should be JSON formatted)
- [ ] Verify request ID in response headers: `X-Request-ID`
- [ ] Check logs for slow requests (>1000ms as warning)

## Integration with Flutter App

### API Endpoint Configuration
- [ ] Update Flutter app API base URL to backend
- [ ] Configure CORS origin in `.env` to match app domain/protocol
- [ ] Test API calls from mobile device/emulator

### Authentication Integration
- [ ] Implement OTP request screen
- [ ] Implement OTP verification screen
- [ ] Store access/refresh tokens securely (secure storage)
- [ ] Implement automatic token refresh
- [ ] Handle 401 errors (logout + redirect to login)

### Data Model Integration
- [ ] Map Flutter models to Pydantic schemas
- [ ] Handle nullable fields properly
- [ ] Test date/time serialization
- [ ] Test Decimal/numeric fields

### Error Handling
- [ ] Display user-friendly error messages
- [ ] Handle 422 validation errors
- [ ] Handle 429 rate limit errors
- [ ] Handle 5xx server errors gracefully

### Offline Support
- [ ] Implement sync batch in app
- [ ] Generate idempotency keys (timestamp-based recommended)
- [ ] Queue mutations when offline
- [ ] Trigger sync when online
- [ ] Handle duplicate detection

## Production Deployment Checklist

### Security
- [ ] Set strong JWT_SECRET_KEY (min 32 random chars)
- [ ] Use HTTPS only in production
- [ ] Configure CORS for specific origins
- [ ] Set DEBUG=False
- [ ] Use environment-specific .env files
- [ ] Rotate secrets periodically
- [ ] Review SQL injection prevention (ORM prevents this)
- [ ] Enable HTTPS on all endpoints

### Performance
- [ ] Configure database connection pool size (default: 20)
- [ ] Configure Redis connection limits
- [ ] Set appropriate cache TTLs
- [ ] Enable query logging to identify slow queries
- [ ] Use CDN for static assets if needed
- [ ] Monitor response times

### Monitoring & Logging
- [ ] Configure log aggregation (ELK, Datadog, etc.)
- [ ] Set up error tracking (Sentry, etc.)
- [ ] Configure health check monitoring
- [ ] Set up database monitoring
- [ ] Set up Redis monitoring
- [ ] Create dashboards for key metrics

### Database
- [ ] Regular backups configured
- [ ] Backup retention policy set
- [ ] Test backup restoration procedure
- [ ] Monitor disk space
- [ ] Monitor query performance
- [ ] Run ANALYZE/VACUUM periodically

### Infrastructure
- [ ] Use Docker for consistent deployment
- [ ] Configure auto-scaling if on cloud
- [ ] Set up load balancer if multiple instances
- [ ] Configure database replication if needed
- [ ] Set up Redis cluster/replication if needed

### Documentation
- [ ] API documentation accessible (Swagger UI)
- [ ] Database schema documented
- [ ] Deployment runbook created
- [ ] Rollback procedure documented
- [ ] On-call runbook for issues

## Testing Checklist

### Unit Tests
- [ ] Tests for each service layer
- [ ] Tests for schema validation
- [ ] Tests for exception handling
- [ ] Run: `pytest tests/ -v`

### Integration Tests
- [ ] Tests for full API flows
- [ ] Tests with real database
- [ ] Tests with Redis
- [ ] Run: `pytest tests/ -v -m integration`

### Load Testing
- [ ] Test with expected concurrent users
- [ ] Identify performance bottlenecks
- [ ] Test rate limiter under load
- [ ] Measure response times

### Security Testing
- [ ] Test JWT validation
- [ ] Test rate limiting
- [ ] Test CORS headers
- [ ] Test input validation
- [ ] Test SQL injection prevention

## Maintenance Checklist (Post-Deployment)

### Daily
- [ ] Monitor application logs for errors
- [ ] Check health check endpoint
- [ ] Review error tracking alerts

### Weekly
- [ ] Review performance metrics
- [ ] Check database size growth
- [ ] Review slow query logs
- [ ] Check backup integrity

### Monthly
- [ ] Update dependencies (security patches)
- [ ] Review security access logs
- [ ] Analyze usage patterns
- [ ] Plan capacity updates if needed

### Quarterly
- [ ] Load test with projected growth numbers
- [ ] Review and optimize slow queries
- [ ] Update documentation
- [ ] Review and update CORS origins
- [ ] Security audit

### Annually
- [ ] Full security assessment
- [ ] Disaster recovery drill
- [ ] Architecture review for scalability
- [ ] Update dependencies to latest stable versions

## Common Issues & Solutions

### Database Connection Issues
- [ ] Verify PostgreSQL running: `psql -U kheteebaadi -d kheteebaadi`
- [ ] Check DATABASE_URL in .env
- [ ] Verify network access to database

### Redis Connection Issues
- [ ] Verify Redis running: `redis-cli ping`
- [ ] Check REDIS_URL in .env
- [ ] Verify network access to Redis

### JWT Token Issues
- [ ] Verify JWT_SECRET_KEY is set
- [ ] Check token expiry times
- [ ] Verify Authorization header format: `Bearer {token}`

### OTP Issues
- [ ] Check OTP_EXPIRE_SECONDS setting
- [ ] Verify Redis is storing OTPs
- [ ] Check rate limiting counter

### Migration Issues
- [ ] Verify alembic.ini points to correct env.py
- [ ] Check DATABASE_URL format
- [ ] Run: `alembic current` to see current revision

## Rollback Procedures

### Database Rollback
```bash
alembic downgrade -1  # Rollback one migration
alembic downgrade [revision]  # Rollback to specific revision
```

### Docker Rollback
```bash
docker-compose down
git checkout [previous-version]
docker-compose up -d
```

### Manual Backup & Restore
```bash
# Backup
pg_dump -U kheteebaadi kheteebaadi > backup.sql

# Restore
psql -U kheteebaadi kheteebaadi < backup.sql
```

---

## Support Resources

- **Issues**: Create GitHub issue with:
  - Python version
  - PostgreSQL version
  - Error message
  - Relevant logs

- **Documentation**: See STARTUP.md and PROJECT_SUMMARY.md

- **Performance**: Monitor with structlog output, check slow queries

---

**Last Updated**: March 2026
**Backend Version**: 1.0.0
**Status**: Production Ready ✅
