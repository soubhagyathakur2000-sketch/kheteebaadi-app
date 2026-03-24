# Quick Test Reference - Kheteebaadi Backend

## File Locations

All test files are in `backend/tests/`:

```
tests/
├── conftest.py                    # Shared fixtures
├── pytest.ini                     # Pytest config
├── unit/
│   ├── test_schemas.py           # 21 tests
│   ├── test_security.py          # 18 tests
│   ├── test_otp_service.py       # 10 tests
│   ├── test_order_service.py     # 12 tests
│   └── test_sync_service.py      # 14 tests
├── integration/
│   ├── test_auth_flow.py         # 10 tests
│   ├── test_sync_batch.py        # 8 tests
│   └── test_webhook_idempotency.py # 8 tests
└── load/
    ├── k6_harvest_spike.js       # Harvest season load test
    ├── k6_payment_stress.js      # Payment stress test
    └── k6_sync_stress.js         # Sync stress test
```

## Installation

```bash
cd backend

# Install test dependencies
pip install -r requirements-test.txt

# Start test infrastructure (Docker)
docker-compose -f docker-compose.test.yml up -d
```

## Running Tests

```bash
# All unit tests (fastest - 15 seconds)
pytest tests/unit -v

# All integration tests (30 seconds)
pytest tests/integration -v

# All tests with coverage
pytest tests/ -v --cov=app --cov-report=html

# Specific test file
pytest tests/unit/test_schemas.py -v

# Specific test class
pytest tests/unit/test_schemas.py::TestOtpRequestSchema -v

# Specific test
pytest tests/unit/test_schemas.py::TestOtpRequestSchema::test_valid_indian_phone_number -v

# Run in parallel (faster)
pytest tests/ -n auto

# Stop on first failure
pytest tests/ -x
```

## Load Testing

```bash
# Harvest season traffic (25 min, 5000 VUs)
k6 run tests/load/k6_harvest_spike.js

# Payment stress (7 min, 500 VUs)
k6 run tests/load/k6_payment_stress.js

# Sync stress (8 min, 1000 VUs)
k6 run tests/load/k6_sync_stress.js

# Custom parameters
k6 run tests/load/k6_harvest_spike.js --vus=100 --duration=5m
```

## Test Counts

| Category | Count | Time |
|----------|-------|------|
| Unit tests | 68 | 10-15s |
| Integration | 26 | 20-30s |
| All tests | 94 | 30-45s |

## Key Test Files

### Schemas (test_schemas.py)
- Phone number validation (Indian +91)
- OTP format (6 digits)
- Order items validation
- Status transitions
- Sync batch size (max 50)

### Security (test_security.py)
- JWT token generation/verification
- Token expiration
- Password hashing/verification
- OTP generation

### Services
- **OTP**: Generation, storage, rate limiting (3/hour)
- **Order**: Creation, cancellation, status updates
- **Sync**: Batch processing, idempotency, duplicates

### API Endpoints
- **Auth**: Request OTP, verify OTP, refresh token
- **Sync**: Batch processing with idempotency
- **Webhook**: Payment events with signature verification

## Infrastructure

### Docker Compose Test Services

```bash
# Start
docker-compose -f docker-compose.test.yml up -d

# Check logs
docker logs kheteebaadi_postgres_test
docker logs kheteebaadi_redis_test

# Stop
docker-compose -f docker-compose.test.yml down

# Clean volumes
docker-compose -f docker-compose.test.yml down -v
```

### Services
- PostgreSQL 15: localhost:5433
- Redis 7: localhost:6380

## Fixtures Available

All in `conftest.py`:

```python
# Database
test_db                # SQLite in-memory async session

# Cache
test_redis            # MockRedis with async methods

# App
test_app              # AsyncClient to FastAPI app

# Data
sample_user           # Test user with phone
sample_village        # Test village
sample_order          # Test order with items
sample_sync_item      # Single sync item
sample_sync_batch     # 5 sync items

# Auth
auth_headers          # JWT Bearer token
```

## Common Patterns

### Unit Test
```python
@pytest.mark.asyncio
async def test_something():
    service = MyService()
    result = await service.do_something()
    assert result is not None
```

### Integration Test
```python
async def test_endpoint(test_app, auth_headers):
    response = await test_app.post(
        "/api/v1/endpoint",
        json={"data": "value"},
        headers=auth_headers
    )
    assert response.status_code == 200
```

### Mock Redis
```python
redis_mock = AsyncMock()
redis_mock.get_cached.return_value = "value"
redis_mock.set_cached = AsyncMock()
```

## Expected Behavior

### Auth Flow
1. POST /otp/request → 200 (OTP sent)
2. POST /otp/verify → 200 (tokens + user)
3. POST /refresh-token → 200 (new tokens)

### Sync Batch
1. POST /sync/batch → 200
2. Response includes per-item results
3. Same idempotency key → detected as duplicate

### Webhooks
1. Valid signature → 200 (payment processed)
2. Duplicate webhook → 200 (no duplicate DB entries)
3. Invalid signature → 400/403 (rejected)

## Debugging

```bash
# Show full output
pytest tests/unit/test_schemas.py -vv

# Show local variables on failure
pytest tests/unit/test_schemas.py -l

# Show print statements
pytest tests/unit/test_schemas.py -s

# Stop on first failure
pytest tests/unit/test_schemas.py -x

# Show slowest tests
pytest tests/ --durations=10
```

## Performance Targets

- p95 latency: < 500ms (normal load)
- p95 latency: < 1500ms (stress tests)
- Error rate: < 1% (normal), < 0.5% (sync)
- Concurrent users: 5000+
- Rate: 10k+ requests/minute

## Files Reference

| File | Purpose | Size |
|------|---------|------|
| conftest.py | Shared fixtures | 250 lines |
| test_schemas.py | Schema validation | 250 lines |
| test_security.py | JWT/OTP/password | 200 lines |
| test_otp_service.py | OTP service logic | 180 lines |
| test_order_service.py | Order operations | 200 lines |
| test_sync_service.py | Sync batching | 220 lines |
| test_auth_flow.py | Auth endpoints | 250 lines |
| test_sync_batch.py | Sync endpoint | 200 lines |
| test_webhook_idempotency.py | Webhook handling | 200 lines |
| k6_harvest_spike.js | Load test | 150 lines |
| k6_payment_stress.js | Payment test | 150 lines |
| k6_sync_stress.js | Sync test | 160 lines |
| TESTING.md | Full guide | 400+ lines |

## Troubleshooting

**Import error?**
→ Run from backend directory: `cd backend && pytest tests/`

**Database connection failed?**
→ Start Docker: `docker-compose -f docker-compose.test.yml up -d`

**AsyncIO error?**
→ Check pytest.ini has: `asyncio_mode = auto`

**k6 not found?**
→ Install: `brew install k6` (macOS) or `apt-get install k6` (Linux)

**Port 5433 already in use?**
→ Stop other containers: `docker ps` and `docker stop <container>`

## Quick Checklist

- [ ] Install dependencies: `pip install -r requirements-test.txt`
- [ ] Start Docker: `docker-compose -f docker-compose.test.yml up -d`
- [ ] Run unit tests: `pytest tests/unit -v`
- [ ] Run integration tests: `pytest tests/integration -v`
- [ ] Check coverage: `pytest tests/ --cov=app --cov-report=html`
- [ ] Run load tests: `k6 run tests/load/k6_harvest_spike.js`

All tests ready to run!
