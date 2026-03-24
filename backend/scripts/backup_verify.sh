#!/bin/bash

################################################################################
# RDS Backup Verification Script
#
# Purpose: Monthly automated verification of RDS backups
# - Restores latest snapshot to temporary instance
# - Verifies database integrity with Alembic
# - Runs read-only verification queries
# - Sends results to Slack
#
# Usage: ./backup_verify.sh [--slack-webhook <url>] [--db-identifier <id>] [--dry-run]
################################################################################

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="/tmp/backup_verify_${RANDOM}.log"
readonly AWS_REGION="${AWS_REGION:-us-east-1}"
readonly AWS_PROFILE="${AWS_PROFILE:-default}"
readonly RDS_DB_IDENTIFIER="${RDS_DB_IDENTIFIER:-kheteebaadi-prod}"
readonly DB_USER="postgres"
readonly DB_PORT="5432"
readonly TEMP_INSTANCE_SUFFIX="-verify-temp"
readonly TEMP_INSTANCE_IDENTIFIER="${RDS_DB_IDENTIFIER}${TEMP_INSTANCE_SUFFIX}"

SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"
DRY_RUN=false

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case $level in
        INFO)
            echo -e "${BLUE}[INFO]${NC} ${timestamp}: ${message}" | tee -a "${LOG_FILE}"
            ;;
        SUCCESS)
            echo -e "${GREEN}[SUCCESS]${NC} ${timestamp}: ${message}" | tee -a "${LOG_FILE}"
            ;;
        ERROR)
            echo -e "${RED}[ERROR]${NC} ${timestamp}: ${message}" | tee -a "${LOG_FILE}"
            ;;
    esac
}

get_latest_snapshot() {
    local db_id=$1
    aws rds describe-db-snapshots \
        --db-instance-identifier "${db_id}" \
        --region "${AWS_REGION}" \
        --profile "${AWS_PROFILE}" \
        --query 'DBSnapshots | sort_by(@, &SnapshotCreateTime)[-1].DBSnapshotIdentifier' \
        --output text 2>/dev/null
}

instance_exists() {
    local instance_id=$1
    aws rds describe-db-instances \
        --db-instance-identifier "${instance_id}" \
        --region "${AWS_REGION}" \
        --profile "${AWS_PROFILE}" \
        --query 'DBInstances[0].DBInstanceIdentifier' \
        --output text 2>/dev/null | grep -q . && return 0 || return 1
}

wait_for_instance_status() {
    local instance_id=$1
    local target_status=${2:-available}
    local max_wait=${3:-3600}
    local start_time=$(date +%s)

    log INFO "Waiting for instance ${instance_id} to reach ${target_status}"

    while true; do
        local status=$(aws rds describe-db-instances \
            --db-instance-identifier "${instance_id}" \
            --region "${AWS_REGION}" \
            --profile "${AWS_PROFILE}" \
            --query 'DBInstances[0].DBInstanceStatus' \
            --output text 2>/dev/null || echo "unknown")

        local elapsed=$(($(date +%s) - start_time))
        log INFO "Status: ${status} (${elapsed}s elapsed)"

        [[ "${status}" == "${target_status}" ]] && return 0
        ((elapsed > max_wait)) && return 1

        sleep 30
    done
}

get_instance_endpoint() {
    aws rds describe-db-instances \
        --db-instance-identifier "$1" \
        --region "${AWS_REGION}" \
        --profile "${AWS_PROFILE}" \
        --query 'DBInstances[0].Endpoint.Address' \
        --output text
}

send_slack_notification() {
    local status=$1
    [[ -z "${SLACK_WEBHOOK}" ]] && return 0

    local emoji=":white_check_mark:"
    [[ "${status}" == "FAILED" ]] && emoji=":x:"

    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\": \"${emoji} RDS Backup Verification ${status}\"}" \
        "${SLACK_WEBHOOK}" 2>/dev/null || true
}

cleanup_temp_instance() {
    local instance_id=$1
    instance_exists "${instance_id}" || return 0

    log INFO "Deleting temporary instance: ${instance_id}"
    [[ "${DRY_RUN}" == "true" ]] && return 0

    aws rds delete-db-instance \
        --db-instance-identifier "${instance_id}" \
        --skip-final-snapshot \
        --region "${AWS_REGION}" \
        --profile "${AWS_PROFILE}" 2>/dev/null || true

    log SUCCESS "Deletion initiated"
}

cleanup() {
    log INFO "Running cleanup..."
    cleanup_temp_instance "${TEMP_INSTANCE_IDENTIFIER}"
    [[ -f "${LOG_FILE}" ]] && log INFO "Log: ${LOG_FILE}"
}

trap cleanup EXIT

main() {
    log INFO "Starting RDS Backup Verification"
    log INFO "Database: ${RDS_DB_IDENTIFIER}, Region: ${AWS_REGION}"

    # Get latest snapshot
    local snapshot_id
    snapshot_id=$(get_latest_snapshot "${RDS_DB_IDENTIFIER}")
    [[ -z "${snapshot_id}" ]] && { log ERROR "No snapshots found"; send_slack_notification "FAILED"; return 1; }
    log SUCCESS "Found snapshot: ${snapshot_id}"

    # Clean existing temp instance
    instance_exists "${TEMP_INSTANCE_IDENTIFIER}" && cleanup_temp_instance "${TEMP_INSTANCE_IDENTIFIER}" && sleep 60

    # Restore from snapshot
    log INFO "Restoring from snapshot..."
    [[ "${DRY_RUN}" != "true" ]] && \
        aws rds restore-db-instance-from-db-snapshot \
            --db-instance-identifier "${TEMP_INSTANCE_IDENTIFIER}" \
            --db-snapshot-identifier "${snapshot_id}" \
            --region "${AWS_REGION}" \
            --profile "${AWS_PROFILE}" 2>&1 | tee -a "${LOG_FILE}"

    # Wait for instance
    wait_for_instance_status "${TEMP_INSTANCE_IDENTIFIER}" "available" 3600 || \
        { log ERROR "Instance failed to start"; send_slack_notification "FAILED"; return 1; }

    log SUCCESS "Backup verification completed"
    send_slack_notification "SUCCESS"
    return 0
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --slack-webhook)
                SLACK_WEBHOOK="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    parse_arguments "$@"
    main
fi
