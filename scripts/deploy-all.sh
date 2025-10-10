#!/usr/bin/env bash
set -euo pipefail

# Deploy all components to a Kubernetes/Rancher cluster.
# Prereqs: kubectl context set to target cluster, docker login to registry.

REGISTRY=${REGISTRY:-"your-reg"}
VERSION=${VERSION:-"1.0.0"}
NAMESPACE=personal-workspace

log() { echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*"; }
#
#log "Building Maven artifacts"
#mvn -q clean package -DskipTests
#
#log "Building container images (REGISTRY=$REGISTRY VERSION=$VERSION)"
#docker build -t $REGISTRY/orders-service:$VERSION services/orders-service
#docker build -t $REGISTRY/inventory-service:$VERSION services/inventory-service
#
#log "Pushing images"
#docker push $REGISTRY/orders-service:$VERSION
#docker push $REGISTRY/inventory-service:$VERSION
#
#log "Adjusting k8s manifests with image registry (dry run). Use yq/kustomize in prod."
## Simple inline substitution example (not modifying files permanently):
## kubectl apply -f <(sed "s|your-reg/orders-service:1.0.0|$REGISTRY/orders-service:$VERSION|" k8s/orders-service.yaml)
## For clarity we just print instructions.

log "Applying base manifests"
rancher kubectl --insecure-skip-tls-verify=true apply -f k8s/namespace.yaml
rancher kubectl --insecure-skip-tls-verify=true apply -f k8s/postgres-orders.yaml
rancher kubectl --insecure-skip-tls-verify=true apply -f k8s/postgres-inventory.yaml

log "Applying services (ensure images reference your registry)"
rancher kubectl --insecure-skip-tls-verify=true apply -n $NAMESPACE -f k8s/orders-service.yaml
rancher kubectl --insecure-skip-tls-verify=true apply -n $NAMESPACE -f k8s/inventory-service.yaml

log "Waiting for deployments to become ready"
for deploy in orders-service inventory-service; do
  rancher kubectl --insecure-skip-tls-verify=true -n $NAMESPACE rollout status deploy/$deploy --timeout=120s || true
done

log "Listing pods"
rancher kubectl --insecure-skip-tls-verify=true -n $NAMESPACE get pods -o wide

log "Done. Verify traces in Groundcover UI (filter by service.name)."
