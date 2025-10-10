# 🚀 GroundCover Observability Project Helper

This document provides context and guidance for GitHub Copilot when contributing to the GroundCoverObservability repository.

## Project Overview

A demonstration of microservices observability using Spring Boot, OpenTelemetry, and integration with GroundCover and Jaeger. Includes:
- **orders-service**: Handles order placement and lifecycle
- **inventory-service**: Manages inventory stock and reservations
- **observability-starter**: Shared library for tracing and logging instrumentation
- Deployment manifests: Docker Compose, Kubernetes (Helm, raw manifests, Rancher)
- Scripts: Build, deploy, and local testing utilities

## Important Paths

```
/.github/            # GitHub-related helper and instruction files
/observability-starter/      # Custom OTEL starter library
/services/           # Spring Boot microservices
/helm/               # Helm charts for K8s
/k8s/                # Raw Kubernetes manifests
/scripts/            # Shell scripts for automation
docker-compose*.yml  # Local Docker Compose setup
``` 

## Common Commands

```bash
# Build all modules
mvn clean install

# Start local infrastructure and services
docker-compose up -d && ./scripts/start-local.sh

# Deploy to Kubernetes
kubectl apply -f k8s/ && helm upgrade --install demo helm/groundcover-observability-demo
```

