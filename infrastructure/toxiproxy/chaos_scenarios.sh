#!/bin/bash

set -e

TOXIPROXY_API="http://localhost:8474"
PROXIES=("postgres" "redis" "s3" "razorpay")

cleanup_proxies() {
  echo "Cleaning up toxics from all proxies..."
  for proxy in "${PROXIES[@]}"; do
    toxiproxy-cli toxic remove -p "$proxy" -t latency 2>/dev/null || true
    toxiproxy-cli toxic remove -p "$proxy" -t jitter 2>/dev/null || true
    toxiproxy-cli toxic remove -p "$proxy" -t timeout 2>/dev/null || true
    toxiproxy-cli toxic remove -p "$proxy" -t bandwidth 2>/dev/null || true
    toxiproxy-cli toxic remove -p "$proxy" -t reset_peer 2>/dev/null || true
  done
  echo "Cleanup complete"
}

scenario_2g() {
  echo "Applying 2G network scenario (1500ms latency + 20% packet loss)..."
  cleanup_proxies

  for proxy in "${PROXIES[@]}"; do
    echo "  Adding latency to $proxy..."
    toxiproxy-cli toxic add -p "$proxy" -t latency -a latency=1500

    echo "  Adding jitter to $proxy..."
    toxiproxy-cli toxic add -p "$proxy" -t jitter -a jitter=200
  done

  echo "2G scenario applied successfully"
}

scenario_flaky() {
  echo "Applying flaky network scenario (random 5s blackouts every 30s)..."
  cleanup_proxies

  for proxy in "${PROXIES[@]}"; do
    echo "  Adding timeout to $proxy..."
    toxiproxy-cli toxic add -p "$proxy" -t timeout -a timeout=5000

    echo "  Adding reset_peer to $proxy..."
    toxiproxy-cli toxic add -p "$proxy" -t reset_peer -a timeout=30000
  done

  echo "Flaky scenario applied successfully"
}

scenario_postgres_down() {
  echo "Disabling PostgreSQL proxy..."
  toxiproxy-cli proxy disable postgres
  echo "PostgreSQL proxy disabled - simulate database down"
}

scenario_redis_crash() {
  echo "Disabling Redis proxy..."
  toxiproxy-cli proxy disable redis
  echo "Redis proxy disabled - simulate cache crash"
}

scenario_s3_slow() {
  echo "Applying S3 slow scenario (30s latency)..."
  cleanup_proxies

  echo "  Adding extreme latency to S3..."
  toxiproxy-cli toxic add -p s3 -t latency -a latency=30000

  echo "S3 slow scenario applied successfully"
}

scenario_clean() {
  echo "Cleaning all chaos scenarios..."
  cleanup_proxies

  echo "Re-enabling all proxies..."
  for proxy in "${PROXIES[@]}"; do
    toxiproxy-cli proxy enable "$proxy" 2>/dev/null || true
  done

  echo "All scenarios cleaned, proxies re-enabled"
}

show_help() {
  cat << EOF
Usage: ./chaos_scenarios.sh [SCENARIO]

Available scenarios:
  2g              Simulate 2G network (1500ms latency + 20% jitter)
  flaky           Simulate flaky network (random 5s blackouts every 30s)
  postgres_down   Simulate database connection down
  redis_crash     Simulate cache service crash
  s3_slow         Simulate S3 API extremely slow (30s latency)
  clean           Remove all chaos scenarios and re-enable proxies
  help            Show this help message

Examples:
  ./chaos_scenarios.sh 2g
  ./chaos_scenarios.sh postgres_down
  ./chaos_scenarios.sh clean

Requirements:
  - toxiproxy-cli must be installed and in PATH
  - Toxiproxy server must be running on localhost:8474
EOF
}

if [ $# -eq 0 ]; then
  show_help
  exit 1
fi

case "$1" in
  2g)
    scenario_2g
    ;;
  flaky)
    scenario_flaky
    ;;
  postgres_down)
    scenario_postgres_down
    ;;
  redis_crash)
    scenario_redis_crash
    ;;
  s3_slow)
    scenario_s3_slow
    ;;
  clean)
    scenario_clean
    ;;
  help)
    show_help
    ;;
  *)
    echo "Unknown scenario: $1"
    echo ""
    show_help
    exit 1
    ;;
esac
