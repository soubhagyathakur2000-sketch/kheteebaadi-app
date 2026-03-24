# Kheteebaadi Backend Testing Guide

Comprehensive testing guide for the FastAPI backend with pytest unit/integration tests and k6 load tests.

## Directory Structure

```
backend/
├── tests/
│   ├── __init__.py
│   ├── conftest.py                 # Shared pytest fixtures
│   ├── pytest.ini                  # Pytest configuration
│   ├── unit/
│   │   ├── __init__.py
│   │   ├── test_schemas.py         # Pydantic schema validation tests
│   │   ├── test_security.py        # JWT, OTP, password hashing tests
│   │   ├── test_otp_service.py     # OTP service unit tests
│   │   ├── test_order_service.py   # Order service unit tests
│   │   └── test_sync_service.py    # Sync service unit tests
│   ├── integration/
│   │   ├── __init__.py
│   │   ├── test_auth_flow.py       # OTP request/verify/refresh endpoints
│   │   ├── test_sync_batch.py      # Sync batch endpoint integration tests
│   │   └── test_webhook_idempotency.py # Webhook handling and idempotency
│   └── load/
│       ├── __init__.py
│       ├── k6_harvest_spike.js     # Harvest season traffic simulation
│       ├── k6_payment_stress.js    # Payment endpoint stress test
│       └── k6_sync_stress.js       # Sync endpoint stress test
├── docker-compose.test.yml         # Test infrastructure (PostgreSQL, Redis)
└── requirements-test.txt           # Test dependencies
```

## Setup

### 1. Install Test Dependencies

```bash
pip install pytest pytest-asyncio httpx sqlalchemy aiosqlite fakeredis phonenumbers
```

Or install all requirements including test dependencies:

```bash
pip install -r requirements.txt
pip install -r requirements-test.txt
```

### 2. Set Up Test Database and Cache

Start test infrastructure with Docker Compose:

```bash
cd backend
docker-compose -f docker-compose.test.yml up -d
```

This starts:
- PostgreSQL on port 5433 (test_user/test_password)
- Redis on port 6380

### 3. Configure Environment for Tests

Create `.env.test`:

```env
DATABASE_URL=postgresql+asyncpg://test_user:test_password@localhost:5433/kheteebaadi_test
REDIS_URL=redis://localhost:6380/0
JWT_SECRET_KEY=test_secret_key_for_testing_only_not_production
DEBUG=true
```

## Running Tests

### Unit Tests Only (No Dependencies)

```bash
pytest tests/unit -v
```

### Integration Tests (Requires Infrastructure)

```bash
pytest tests/integration -v
```

### Specific Test File

```bash
pytest tests/unit/test_schemas.py -v
pytest tests/integration/test_auth_flow.py -v
```

### Specific Test Class

```bash
pytest tests/unit/test_schemas.py::TestOtpRequestSchema -v
```

### Specific Test

```bash
pytest tests/unit/test_schemas.py::TestOtpRequestSchema::test_valid_indian_phone_number -v
```

### Run All Tests

```bash
pytest tests/ -v
```

### Run with Coverage

```bash
pip install pytest-cov
pytest tests/ --cov=app --cov-report=html
```

### Run in Parallel (Faster Execution)

```bash
pip install pytest-xdist
pytest tests/ -n auto
```

## Test Suite Overview

### Unit Tests (tests/unit/)

#### test_schemas.py
- OtpRequest validation (valid/invalid phone formats)
- OtpVerify validation (valid/invalid OTP formats)
- OrderCreate validation (items list, delivery address)
- OrderStatusUpdate validation (valid status transitions)
- SyncBatchRequest validation (batch size limits)
- **Total: 20 tests**

#### test_security.py
- JWT token generation and expiration
- Token verification with invalid signatures
- OTP generation (6-digit format, uniqueness)
- Password hashing and verification
- Token claims preservation
- **Total: 18 tests**

#### test_otp_service.py
- OTP generation and Redis storage
- Rate limiting (max 3/hour)
- OTP verification (correct/incorrect/expired)
- Rate limit independence per phone
- **Total: 10 tests**

#### test_order_service.py
- Order creation with items
- Total amount calculation
- Order number generation
- Cancel order validation
- Status transition validation
- **Total: 12 tests**

#### test_sync_service.py
- Sync batch processing
- Idempotency key handling
- Duplicate detection
- Mixed success/failure handling
- **Total: 14 tests**

### Integration Tests (tests/integration/)

#### test_auth_flow.py
- POST /api/v1/auth/otp/request (valid/invalid phone)
- Rate limiting (4th request returns 429)
- POST /api/v1/auth/otp/verify (correct/incorrect/expired OTP)
- New user creation on first verify
- POST /api/v1/auth/refresh-token
- Complete auth flow: request → verify → authenticated request
- **Total: 10 tests**

#### test_sync_batch.py
- POST /api/v1/sync/batch with 5 items all succeeding
- Duplicate idempotency key handling
- Mixed success/failure responses
- Empty items rejection
- Batch size limit (50 max)
- Authentication requirement
- **Total: 8 tests**

#### test_webhook_idempotency.py
- Webhook signature validation
- Duplicate webhook handling (idempotency)
- Concurrent identical requests
- Payment event types (captured, authorized, failed)
- Invalid signature rejection
- **Total: 8 tests**

### Load Tests (tests/load/)

#### k6_harvest_spike.js
**Simulates harvest season traffic with realistic patterns**

Stages:
- Ramp: 0→5000 VUs (2 min)
- Steady: 5000 VUs (10 min)
- Spike: 5000→7500 VUs (5 min) - buyer surge
- Storm: 7500→2500 VUs (5 min) - payment processing
- Ramp down: 2500→0 VUs (2 min)

Scenarios:
- Farmer listing uploads
- Buyer mandi price searches
- Order creation
- Payment processing

Thresholds:
- p95 response time < 500ms
- Failure rate < 1%
- > 100,000 iterations

**Run:**
```bash
k6 run tests/load/k6_harvest_spike.js
```

#### k6_payment_stress.js
**Stress test payment endpoints with concurrent requests**

Configuration:
- 500 VUs for 5 minutes
- Multiple concurrent payment initiations
- Webhook handler with 200 VUs hitting same payment_id
- Payment status verification

Thresholds:
- p95 response time < 1500ms
- Failure rate < 1%
- Zero duplicate payments

Metrics:
- `duplicate_payments` counter
- `payment_latency` trend
- `concurrent_payments` gauge

**Run:**
```bash
k6 run tests/load/k6_payment_stress.js
```

#### k6_sync_stress.js
**Stress test sync endpoint with 50-item batches**

Configuration:
- 1000 VUs for 5 minutes
- Each VU posts batch of 50 items = 50,000 items total
- Idempotency verification (30% resend same batch)

Thresholds:
- p95 response time < 1500ms
- Failure rate < 0.5%
- > 40,000 items processed
- < 100 duplicates detected

**Run:**
```bash
k6 run tests/load/k6_sync_stress.js
```

## Fixture Overview (conftest.py)

### Database Fixtures
- `test_db`: SQLite in-memory database with AsyncSession
- Automatic table creation/cleanup

### Redis Fixtures
- `test_redis`: MockRedis with async methods (get_cached, set_cached, delete_cached, exists, increment)

### Application Fixtures
- `test_app`: AsyncClient connected to test app with mocked dependencies

### Data Factories
- `sample_user`: Creates test user with phone, village association
- `sample_village`: Creates test village
- `sample_order`: Creates test order with items
- `sample_sync_item`: Creates single sync item
- `sample_sync_batch`: Creates batch of 5 sync items

### Auth Fixtures
- `auth_headers`: JWT Bearer token for authenticated requests

## Running All Tests

### Quick Smoke Test (10 seconds)
```bash
pytest tests/unit -v --tb=short
```

### Full Test Suite (2-5 minutes)
```bash
pytest tests/ -v --cov=app
```

### With Detailed Reports
```bash
pytest tests/ -v --cov=app --cov-report=html --html=report.html
```

### Load Tests (Run One at a Time)
```bash
# Each test takes 10-20 minutes
k6 run tests/load/k6_harvest_spike.js --vus=1000 --duration=10m
k6 run tests/load/k6_payment_stress.js --vus=500 --duration=5m
k6 run tests/load/k6_sync_stress.js --vus=1000 --duration=5m
```

## Test Data

### Shared Test Data
Tests use `SharedArray` for pre-generated data:
- 1000 auth tokens (load tests)
- 10000 payment records (payment stress test)
- Various crop types with realistic pricing

### In-Memory Storage
Load tests use in-memory tracking for:
- Processed payment IDs
- Idempotency keys
- Duplicate detection

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Backend Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: kheteebaadi_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      redis:
        image: redis:7
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-test.txt

      - name: Run unit tests
        run: pytest tests/unit -v --cov=app

      - name: Run integration tests
        run: pytest tests/integration -v

      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

## Troubleshooting

### Test Database Connection Issues
```bash
# Check PostgreSQL is running
docker ps | grep postgres_test

# Check Redis is running
docker ps | grep redis_test

# View logs
docker logs kheteebaadi_postgres_test
docker logs kheteebaadi_redis_test
```

### AsyncIO Event Loop Errors
Ensure `pytest.ini` has:
```ini
asyncio_mode = auto
```

### Import Errors
Make sure you're running tests from the backend directory:
```bash
cd backend
pytest tests/
```

### k6 Installation
```bash
# macOS
brew install k6

# Ubuntu/Debian
sudo apt-get install k6

# Or download from https://k6.io/docs/getting-started/installation/
```

## Performance Benchmarks

Expected test execution times:

| Test Suite | Time | Notes |
|-----------|------|-------|
| Unit tests (68 tests) | 10-15s | No dependencies |
| Integration tests (26 tests) | 20-30s | Requires DB/Redis |
| All tests combined | 30-45s | Full coverage |
| k6 harvest spike | 25 min | 5000 VUs |
| k6 payment stress | 7 min | 500 VUs |
| k6 sync stress | 8 min | 1000 VUs |

## Test Metrics

### Coverage Target
- Statements: >80%
- Branches: >70%
- Functions: >80%
- Lines: >80%

### Load Test Targets
- p95 latency: <500ms (normal), <1500ms (stress)
- Error rate: <1% (harvest), <0.5% (sync)
- Concurrency: 5000+ simultaneous connections
- Throughput: 10k+ requests/minute

## Best Practices

1. **Run unit tests during development**: Fast feedback
2. **Run integration tests before commit**: Catches integration issues
3. **Run load tests before deployment**: Verify performance targets
4. **Monitor test coverage**: Maintain >80% coverage
5. **Keep tests isolated**: No shared state between tests
6. **Use fixtures**: Reduce test duplication
7. **Test edge cases**: Invalid input, boundary conditions
8. **Mark slow tests**: Use `@pytest.mark.slow` decorator

## Additional Resources

- [pytest documentation](https://docs.pytest.org/)
- [pytest-asyncio](https://pytest-asyncio.readthedocs.io/)
- [httpx AsyncClient](https://www.python-httpx.org/)
- [k6 documentation](https://k6.io/docs/)
- [SQLAlchemy async](https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html)
