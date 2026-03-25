# Multi-stage Dockerfile for Kheteebaadi FastAPI Backend
# Production-optimized with security best practices and minimal attack surface

# ============================================================================
# Stage 1: Builder
# Purpose: Install build dependencies and compile Python packages
# ============================================================================
FROM python:3.11-slim AS builder

# Set environment variables for Python
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install build-time system dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    libffi-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Create isolated virtual environment in builder stage
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip setuptools wheel && \
    pip install -r requirements.txt

# ============================================================================
# Stage 2: Runtime
# Purpose: Lean production image with only runtime dependencies
# ============================================================================
FROM python:3.11-slim

# Set environment variables for Python and application
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/opt/venv/bin:$PATH" \
    PYTHONPATH="/app"

# Install only runtime dependencies (no gcc or build tools)
# postgresql-client provides pg_isready for entrypoint health checks
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    postgresql-client \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for improved security
# Using numeric UID for better compatibility across systems
RUN groupadd -r appuser && useradd -r -g appuser -u 1000 appuser

# Set working directory
WORKDIR /app

# Copy virtual environment from builder stage (avoids reinstalling packages)
COPY --from=builder /opt/venv /opt/venv

# Copy application code
COPY . .

# Change ownership of application directory to appuser
RUN chown -R appuser:appuser /app

# Switch to non-root user for container execution
USER appuser

# Expose application port
EXPOSE 8000

# Health check - validates that the API is responding correctly
# Interval: check every 30 seconds
# Timeout: consider unhealthy if response takes >10 seconds
# Start period: allow 40 seconds for application startup
# Retries: mark unhealthy after 3 consecutive failures
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import httpx; httpx.get('http://localhost:8000/health', timeout=5.0)" || exit 1

# Default command: start FastAPI app with uvicorn
# Using 2 workers for balanced concurrency and memory usage
# Bind to 0.0.0.0 to ensure accessibility from all interfaces in container
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
