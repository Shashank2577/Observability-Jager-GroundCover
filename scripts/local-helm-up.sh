#!/usr/bin/env bash
set -euo pipefail

# Local deployment script for Docker Desktop (Kubernetes enabled) using Helm chart values-local.yaml
# Prerequisites: docker, kubectl (pointing to docker-desktop), helm

CHART_DIR="$(dirname "$0")/../helm/groundcover-observability-demo"
CHART_DIR="$(cd "$CHART_DIR" && pwd)"
VALUES_LOCAL="$CHART_DIR/values-local.yaml"
NAMESPACE="observability-demo"
RELEASE_NAME="gc-demo-local"
IMAGE_TAG="1.0.0-SNAPSHOT"
DOWNLOAD_AGENT=${DOWNLOAD_AGENT:-false}

log(){ echo "[local-helm-up] $*"; }

if ! command -v helm >/dev/null 2>&1; then
  log "Helm not found in PATH. Install Helm (https://helm.sh) and re-run." >&2
  exit 1
fi
if ! command -v kubectl >/dev/null 2>&1; then
  log "kubectl not found in PATH." >&2
  exit 1
fi

CTX=$(kubectl config current-context || true)
log "Current kube context: ${CTX}"

log "Building application jars (skip tests)"
mvn -q -DskipTests package

log "Building local Docker images (no registry push) with DOWNLOAD_AGENT=${DOWNLOAD_AGENT}"
# Orders
DOCKER_BUILDKIT=1 docker build \
  --build-arg DOWNLOAD_AGENT=${DOWNLOAD_AGENT} \
  --build-arg OTEL_JAVA_AGENT_VERSION=1.37.0 \
  -t orders-service:${IMAGE_TAG} services/orders-service
# Inventory
DOCKER_BUILDKIT=1 docker build \
  --build-arg DOWNLOAD_AGENT=${DOWNLOAD_AGENT} \
  --build-arg OTEL_JAVA_AGENT_VERSION=1.37.0 \
  -t inventory-service:${IMAGE_TAG} services/inventory-service

echo ""; log "Images built:"; docker images | grep -E 'orders-service|inventory-service' || true

log "Ensuring namespace ${NAMESPACE} exists"
if ! kubectl get namespace ${NAMESPACE} >/dev/null 2>&1; then
  kubectl create namespace ${NAMESPACE} || true
fi

log "Helm install/upgrade release ${RELEASE_NAME}"
if helm status ${RELEASE_NAME} -n ${NAMESPACE} >/dev/null 2>&1; then
  helm upgrade ${RELEASE_NAME} ${CHART_DIR} -n ${NAMESPACE} -f ${VALUES_LOCAL}
else
  helm install ${RELEASE_NAME} ${CHART_DIR} -n ${NAMESPACE} -f ${VALUES_LOCAL}
fi

log "Waiting for deployments (orders-service, inventory-service) to become Ready"
for d in orders-service inventory-service; do
  for i in {1..30}; do
    ready=$(kubectl -n ${NAMESPACE} get deploy $d -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo 0)
    if [ "$ready" = "1" ]; then
      log "$d Ready"
      break
    fi
    sleep 4
    if [ $i -eq 30 ]; then
      log "Timeout waiting for $d; showing describe and recent logs"
      kubectl -n ${NAMESPACE} describe deploy $d || true
      pod=$(kubectl -n ${NAMESPACE} get pods -l app=$d -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo '')
      [ -n "$pod" ] && kubectl -n ${NAMESPACE} logs $pod --tail=120 || true
    fi
  done
done

log "Listing services (NodePorts)"
kubectl -n ${NAMESPACE} get svc orders-service inventory-service -o wide || true

ORDERS_NODEPORT=$(kubectl -n ${NAMESPACE} get svc orders-service -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo '')
INVENTORY_NODEPORT=$(kubectl -n ${NAMESPACE} get svc inventory-service -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo '')

if [ -n "$ORDERS_NODEPORT" ]; then
  log "Test an order creation (NodePort $ORDERS_NODEPORT)"
  set +e
  curl -sf -X POST "http://localhost:${ORDERS_NODEPORT}/orders?sku=ALPHA&qty=1" || log "Initial curl may fail until pod ready"
  set -e
fi

cat <<EOF

Local deployment complete.
Orders Service:    http://localhost:${ORDERS_NODEPORT}
Inventory Service: http://localhost:${INVENTORY_NODEPORT}
Try: curl http://localhost:${ORDERS_NODEPORT}/orders
Logs: kubectl -n ${NAMESPACE} logs deploy/orders-service | head
To remove: ./scripts/local-helm-down.sh
Disable agent download (default false): DOWNLOAD_AGENT=false ./scripts/local-helm-up.sh
Enable agent download: DOWNLOAD_AGENT=true ./scripts/local-helm-up.sh
EOF
