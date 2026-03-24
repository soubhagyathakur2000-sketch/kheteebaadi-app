# Kheteebaadi Backend - Startup Guide

## Overview

Complete production-grade FastAPI backend for the Kheteebaadi agricultural marketplace app. Includes:

- **Authentication**: OTP-based login with JWT tokens
- **Mandi Prices**: Real-time agricultural market prices with caching
- **Orders**: Complete order management system
- **Sync**: Offline-first synchronization with idempotency
- **Users**: User profiles and statistics
- **Villages**: Location-based village search

## Quick Start with Docker

### 1. Prerequisites
- Docker and Docker Compose installed
- 8GB RAM minimum
- Ports 5432, 6379, 8000 available

### 2. Start Services
```bash
docker-compose up -d
```

This starts:
- PostgreSQL (port 5432)
- Redis (port 6379)
- FastAPI (port 8000)
- Celery Worker
- Celery Beat (for scheduled tasks)

### 3. Run Migrations
```bash
docker-compose exec api alembic upgrade head
```

### 4. Access API
- API: http://localhost:8000
- Docs: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Local Development Setup

### 1. Create Python Virtual Environment
```bash
python3.11 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
pip install pytest pytest-asyncio pytest-cov  # For testing
```

### 3. Environment Variables
```bash
cp .env.example .env
# Edit .env with your configuration
```

### 4. Database Setup
```bash
# Using PostgreSQL locally
createdb kheteebaadi
createuser -P kheteebaadi  # Password: kheteebaadi

# Run migrations
alembic upgrade head
```

### 5. Redis Setup
```bash
# Start Redis (if not using Docker)
redis-server
```

### 6. Run API
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 7. Run Celery (in separate terminal)
```bash
# Worker
celery -A app.workers.celery_app worker --loglevel=info

# Beat (in another terminal)
celery -A app.workers.celery_app beat --loglevel=info
```

## Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI app factory
│   ├── core/
│   │   ├── config.py          # Settings management
│   │   ├── database.py        # Database setup
│   │   ├── redis.py           # Redis client
│   │   ├── security.py        # JWT & OTP utilities
│   │   └── exceptions.py      # Custom exceptions
│   ├── models/
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── village.py
│   │   ├── mandi.py
│   │   ├── order.py
│   │   └── sync_log.py
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── auth.py
│   │   ├── mandi.py
│   │   ├── order.py
│   │   └── sync.py
│   ├── api/
│   │   └── v1/
│   │       ├── endpoints/
│   │       │   ├── auth.py
│   │       │   ├── mandi.py
│   │       │   ├── orders.py
│   │       │   ├── sync.py
│   │       │   ├── users.py
│   │       │   └── villages.py
│   │       └── router.py
│   ├── services/
│   │   ├── otp_service.py
│   │   ├── mandi_service.py
│   │   ├── order_service.py
│   │   ├── sync_service.py
│   │   ├── user_service.py
│   │   └── village_service.py
│   ├── middleware/
│   │   ├── logging_middleware.py
│   │   └── rate_limiter.py
│   └── workers/
│       ├── celery_app.py
│       └── tasks.py
├── migrations/              # Alembic migrations
├── tests/                  # Test files
├── requirements.txt
├── .env.example
├── docker-compose.yml
├── Dockerfile
├── pyproject.toml
└── alembic.ini
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/otp/request` - Request OTP
- `POST /api/v1/auth/otp/verify` - Verify OTP & login
- `POST /api/v1/auth/refresh` - Refresh access token
- `POST /api/v1/auth/logout` - Logout

### Mandi Prices
- `GET /api/v1/mandi/prices` - List prices with caching
- `GET /api/v1/mandi/prices/{mandi_id}` - Prices for specific mandi
- `GET /api/v1/mandi/search` - Search crops
- `GET /api/v1/mandi/nearby` - Nearby mandis by coordinates

### Orders
- `POST /api/v1/orders` - Create order
- `GET /api/v1/orders` - List user's orders
- `GET /api/v1/orders/{order_id}` - Get order detail
- `PATCH /api/v1/orders/{order_id}/status` - Update status
- `POST /api/v1/orders/{order_id}/cancel` - Cancel order

### Sync (Offline-First)
- `POST /api/v1/sync/batch` - Sync batch of offline mutations (max 50 items)

### Users
- `GET /api/v1/users/me` - Get profile
- `PATCH /api/v1/users/me` - Update profile
- `GET /api/v1/users/me/stats` - Get user statistics

### Villages
- `GET /api/v1/villages` - List villages
- `GET /api/v1/villages/{village_id}` - Get village detail
- `GET /api/v1/villages/nearby` - Nearby villages by coordinates

## Database Schema

### Users
- UUID primary key
- Phone (unique, indexed)
- Village reference
- Language preference (hi, en, mr, gu)
- Created/updated timestamps

### Villages
- UUID primary key
- Name (English and local language)
- District, state
- GPS coordinates
- Pin code

### Mandis
- UUID primary key
- Name (English and local language)
- District, state
- GPS coordinates

### Mandi Prices
- UUID primary key
- Mandi reference
- Crop name (English and local language)
- Price per quintal with min/max
- Price date
- Indexed for fast queries

### Orders
- UUID primary key
- User reference
- Order number (unique, auto-generated)
- Status (pending, confirmed, processing, shipped, delivered, cancelled)
- Items (one-to-many)
- Total amount
- Delivery address

### Sync Logs
- UUID primary key
- User reference
- Idempotency key (unique)
- Entity type and ID
- Action (create, update, delete)
- Payload (JSON)
- Status (processed, failed, duplicate)

## Key Features

### 1. OTP-Based Authentication
- Phone number validation (Indian format)
- Redis-based OTP storage with 5-minute TTL
- Rate limiting: max 3 OTP requests per hour per phone
- JWT tokens with 30-minute access, 30-day refresh

### 2. Offline-First Sync
- Batch sync endpoint supports up to 50 items per request
- Idempotency checking with 72-hour TTL
- Duplicate detection prevents re-processing
- Database transaction ensures atomic operations
- Per-item error reporting

### 3. Mandi Prices Caching
- Redis cache with 15-minute TTL
- Cache-first strategy for read performance
- Configurable cache refresh
- Full-text search on crop names
- Regional filtering

### 4. Rate Limiting
- Per-user sliding window (100 requests/minute default)
- Redis-backed for distributed deployments
- Configurable limits per endpoint
- Automatic 429 responses with Retry-After header

### 5. Structured Logging
- JSON-formatted logs with timestamps
- Request ID correlation
- Performance metrics (response time, status codes)
- Automatic error tracking

### 6. Background Tasks
- Celery for async job processing
- Scheduled tasks: mandi price refresh, cleanup, reporting
- Task routing to different queues
- Result caching in Redis

## Configuration

### Environment Variables
```env
# App
DEBUG=False
APP_NAME=Kheteebaadi API
VERSION=1.0.0

# Database (async PostgreSQL)
DATABASE_URL=postgresql+asyncpg://user:pass@localhost/kheteebaadi

# Redis
REDIS_URL=redis://localhost:6379/0

# JWT
JWT_SECRET_KEY=your-secret-key-min-32-chars
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=30

# OTP
OTP_EXPIRE_SECONDS=300
OTP_LENGTH=6
OTP_MAX_ATTEMPTS_PER_HOUR=3

# AWS S3 (for future file uploads)
AWS_REGION=ap-south-1
S3_BUCKET=kheteebaadi
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx

# CORS
CORS_ORIGINS=["http://localhost:3000", "capacitor://localhost"]

# Caching
CACHE_TTL_MANDI_PRICES=900
CACHE_TTL_VILLAGES=3600
CACHE_TTL_MANDIS=3600
```

## Testing

### Run All Tests
```bash
pytest
```

### Run Specific Test Suite
```bash
pytest tests/test_auth.py -v
```

### With Coverage
```bash
pytest --cov=app --cov-report=html
```

## Deployment

### Docker Production Build
```bash
docker build -t kheteebaadi-api:1.0.0 .
docker run -p 8000:8000 \
  -e DATABASE_URL=postgresql+asyncpg://... \
  -e REDIS_URL=redis://... \
  -e JWT_SECRET_KEY=... \
  kheteebaadi-api:1.0.0
```

### Kubernetes Deployment
Use the provided Dockerfile with Kubernetes manifests (CPU/memory requests, health checks configured).

### Environment-Specific Configuration
- Development: Debug mode enabled, in-memory caching
- Staging: Production-like, verbose logging
- Production: Debug off, optimized pool sizes, structured logging

## Monitoring & Logging

### Structured Logs
All logs are JSON-formatted with:
- Timestamp (ISO format)
- Log level
- Message
- Context (user_id, request_id, etc.)
- Exception info (if applicable)

### Health Check
```bash
curl http://localhost:8000/health
```

### API Documentation
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Performance Tuning

### Database
- Connection pool: size=20, max_overflow=10
- Proper indexing on frequently queried columns
- Async operations throughout

### Redis
- Connection pooling with 20 max connections
- JSON serialization for complex data types
- Automatic TTL expiration

### Caching Strategy
- Mandi prices: 15-minute cache
- Villages: 1-hour cache
- User profiles: On-demand (no cache)

## Security Considerations

- All passwords hashed with bcrypt
- JWT tokens with expiration
- CORS configured for Flutter app domains
- Rate limiting on all endpoints
- Phone number validation
- SQL injection prevention (SQLAlchemy ORM)
- HTTPS recommended in production
- API key rotation (JWT refresh tokens)

## Future Enhancements

1. SMS/Email notifications (Twilio, SendGrid)
2. Push notifications (Firebase Cloud Messaging)
3. Admin dashboard
4. Analytics and reporting
5. Multi-language support expansion
6. Payment integration
7. Crop recommendation engine
8. Weather integration
9. Farmer community features
10. Price prediction ML model

## Support & Documentation

- API Docs: http://localhost:8000/docs
- Code Comments: Comprehensive docstrings
- Type Hints: Full Python type annotations
- Error Messages: User-friendly, actionable

## License

Kheteebaadi - Agricultural Marketplace
