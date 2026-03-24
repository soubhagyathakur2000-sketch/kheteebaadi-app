# Kheteebaadi - Agricultural Marketplace Platform

## Phase 1: Complete Codebase

Kheteebaadi is an offline-first agricultural marketplace connecting farmers with mandis (markets) across rural India. Built for low-end Android devices on spotty 3G/4G connections with full multilingual support.

---

## Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| Mobile App | Flutter 3.24+ (Dart) | AOT-compiled, offline-first, single codebase Android + Web |
| Backend API | Python FastAPI | Async-native, Pydantic validation, native AI/ML ecosystem |
| Database | PostgreSQL 16+ | ACID transactions, PostGIS, JSONB, full-text search |
| Cache | Redis 7+ | Session management, API caching, sync queues |
| Cloud | AWS (ap-south-1) | Dual India regions, 13 CloudFront PoPs, ECS Fargate |
| CI/CD | GitHub Actions | Docker builds, ECR push, Terraform apply |

---

## Project Structure

```
kheteebaadi-app/
├── flutter_app/                 # Mobile + Web application
│   ├── lib/
│   │   ├── core/                # Constants, theme, network, DI
│   │   ├── database/            # Drift SQLite (offline storage)
│   │   ├── features/
│   │   │   ├── auth/            # OTP login (Clean Architecture)
│   │   │   ├── home/            # Dashboard
│   │   │   ├── mandi/           # Market prices
│   │   │   ├── orders/          # Order management
│   │   │   ├── profile/         # Farmer profile
│   │   │   └── sync/            # Offline sync engine
│   │   └── l10n/                # Translations (EN, HI, MR)
│   └── pubspec.yaml
│
├── backend/                     # FastAPI server
│   ├── app/
│   │   ├── api/v1/endpoints/    # REST endpoints
│   │   ├── core/                # Config, DB, Redis, Security
│   │   ├── models/              # SQLAlchemy models
│   │   ├── schemas/             # Pydantic schemas
│   │   ├── services/            # Business logic
│   │   ├── middleware/          # Rate limiter, logging
│   │   └── workers/             # Celery background tasks
│   ├── migrations/              # Alembic DB migrations
│   └── requirements.txt
│
├── infrastructure/
│   ├── docker/                  # Dockerfiles
│   ├── terraform/               # AWS IaC (VPC, ECS, RDS, Redis)
│   └── scripts/                 # DB init, seed data
│
├── docker-compose.yml           # Local development stack
└── docs/                        # Architecture document
```

---

## Quick Start (Local Development)

### Prerequisites
- Docker & Docker Compose
- Flutter SDK 3.24+
- Python 3.12+

### 1. Start Backend Services

```bash
# Start PostgreSQL, Redis, Backend, Celery
docker compose up -d

# Check all services are healthy
docker compose ps

# Backend API is at http://localhost:8000
# API docs at http://localhost:8000/docs
```

### 2. Run Flutter App

```bash
cd flutter_app

# Install dependencies
flutter pub get

# Generate Drift database code
dart run build_runner build --delete-conflicting-outputs

# Run on Android
flutter run

# Run on Chrome (web)
flutter run -d chrome

# Build release APK
flutter build apk --release
```

### 3. Run Backend Without Docker

```bash
cd backend

# Create virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Set environment variables (copy .env.example to .env)
cp .env.example .env

# Run migrations
alembic upgrade head

# Start server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/otp/request` | Request OTP for phone |
| POST | `/api/v1/auth/otp/verify` | Verify OTP, get tokens |
| POST | `/api/v1/auth/refresh` | Refresh access token |
| GET | `/api/v1/mandi/prices` | List mandi prices |
| GET | `/api/v1/mandi/nearby` | Nearby mandis by location |
| GET | `/api/v1/mandi/search` | Search crops |
| POST | `/api/v1/orders` | Create order |
| GET | `/api/v1/orders` | List user orders |
| PATCH | `/api/v1/orders/{id}/status` | Update order status |
| POST | `/api/v1/sync/batch` | Process offline sync batch |
| GET | `/api/v1/users/me` | Current user profile |
| GET | `/api/v1/villages` | List villages |

---

## Key Features

### Offline-First Sync Engine
The Flutter app queues all write operations locally when offline. On reconnection, the `SyncEngine` batches mutations (max 50) with UUID idempotency keys and sends to `/sync/batch`. The server checks each key against Redis (72-hour TTL) to prevent duplicates, processes within a PostgreSQL transaction, and returns per-item results.

### Multilingual Support
Three languages in Phase 1: English, Hindi, Marathi. Translations use Flutter's ARB format with `flutter_localizations`. Crop names are stored in both English and regional languages in the database. The i18n bundle is server-driven and cached locally.

### Cache Strategy
Redis caches mandi prices with 15-minute TTL. The Flutter app maintains a local Drift/Hive cache. Read path: Local cache -> Redis -> PostgreSQL. Write path: Local queue -> Batch sync -> PostgreSQL -> Redis invalidation.

---

## Deployment (AWS)

```bash
cd infrastructure/terraform

# Initialize
terraform init

# Plan
terraform plan -var="db_password=YOUR_SECURE_PASSWORD" -var="jwt_secret=YOUR_JWT_SECRET"

# Apply
terraform apply
```

This provisions: VPC (3 AZ), ECS Fargate cluster (min 2 tasks, auto-scale to 10), RDS PostgreSQL Multi-AZ, ElastiCache Redis, ALB with health checks, CloudWatch logging.

---

## Environment Variables

See `backend/.env.example` for all configuration options. Key variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | Async PostgreSQL connection | Required |
| `REDIS_URL` | Redis connection | Required |
| `JWT_SECRET_KEY` | Token signing secret | Required |
| `OTP_EXPIRE_SECONDS` | OTP validity window | 300 |
| `CACHE_TTL_MANDI_PRICES` | Price cache duration | 900 |
| `SYNC_BATCH_MAX_SIZE` | Max items per sync batch | 50 |
