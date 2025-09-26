#!/usr/bin/env bash
set -euo pipefail

ORDERS_URL="${ORDERS_URL:-http://localhost:8080/orders}"
SKUS=(ALPHA BETA GAMMA DELTA OMEGA)

concurrency="${CONCURRENCY:-5}"
iterations="${ITERATIONS:-100}"
sleep_ms="${SLEEP_MS:-200}"

log() { echo "[$(date -Is)] $*"; }

run_once() {
  local sku=${SKUS[$RANDOM % ${#SKUS[@]}]}
  local qty=$(( (RANDOM % 5) + 1 ))
  curl -sf -X POST "${ORDERS_URL}?sku=${sku}&qty=${qty}" >/dev/null && \
    log "Created order sku=${sku} qty=${qty}" || \
    log "Failed order sku=${sku} qty=${qty}" >&2
}

export -f run_once log
export ORDERS_URL SKUS

log "Starting load: concurrency=${concurrency} iterations=${iterations} target=${ORDERS_URL}"
for ((i=1;i<=iterations;i++)); do
  p=()
  for ((c=1;c<=concurrency;c++)); do
    bash -c run_once &
    p+=("$!")
    sleep 0.01
  done
  for pid in "${p[@]}"; do wait "$pid" || true; done
  sleep $(awk -v ms=${sleep_ms} 'BEGIN{print ms/1000}')
 done
log "Load generation complete"

