#!/usr/bin/env bash
set -euo pipefail
NAMESPACE=${NAMESPACE:-observability-demo}
RELEASE_NAME=${RELEASE_NAME:-gc-demo-local}

log(){ echo "[local-helm-down] $*"; }

if ! command -v helm >/dev/null 2>&1; then
  log "Helm not found; nothing to remove via Helm." >&2
  exit 0
fi

if helm status ${RELEASE_NAME} -n ${NAMESPACE} >/dev/null 2>&1; then
  log "Uninstalling Helm release ${RELEASE_NAME} in namespace ${NAMESPACE}";
  helm uninstall ${RELEASE_NAME} -n ${NAMESPACE};
else
  log "Helm release ${RELEASE_NAME} not found (skipping uninstall).";
fi

if kubectl get namespace ${NAMESPACE} >/dev/null 2>&1; then
  log "Deleting namespace ${NAMESPACE}";
  kubectl delete namespace ${NAMESPACE};
fi

log "Done."

