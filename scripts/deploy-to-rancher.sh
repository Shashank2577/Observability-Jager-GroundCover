#!/bin/bash

# Deploy GroundCover Observability Demo to Rancher Cluster
# This script deploys all services to your Rancher cluster

set -e

echo "🚀 Deploying GroundCover Observability Demo to Rancher Cluster..."

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ kubectl is not configured or cluster is not accessible"
    echo "Please configure your kubeconfig to point to your Rancher cluster"
    exit 1
fi

# Get cluster info
echo "📊 Cluster Information:"
kubectl cluster-info

# Create namespace first
echo "📦 Creating namespace..."
kubectl apply -f k8s/namespace.yaml

# Deploy infrastructure services
echo "🗄️ Deploying PostgreSQL databases..."
kubectl apply -f k8s/postgres-orders.yaml
kubectl apply -f k8s/postgres-inventory.yaml

# Wait for databases to be ready
echo "⏳ Waiting for databases to be ready..."
kubectl wait --for=condition=ready pod -l app=orders-postgres -n observability-demo --timeout=60s
kubectl wait --for=condition=ready pod -l app=inventory-postgres -n observability-demo --timeout=60s

# Deploy observability stack
echo "📊 Deploying observability stack..."
kubectl apply -f k8s/otel-collector.yaml

# Wait for collector
echo "⏳ Waiting for OpenTelemetry collector..."
kubectl wait --for=condition=ready pod -l app=otel-collector -n observability-demo --timeout=60s

# Deploy application services
echo "🔧 Deploying application services..."
kubectl apply -f k8s/orders-service.yaml
kubectl apply -f k8s/inventory-service.yaml

# Wait for services to be ready
echo "⏳ Waiting for application services..."
kubectl wait --for=condition=ready pod -l app=orders-service -n observability-demo --timeout=120s
kubectl wait --for=condition=ready pod -l app=inventory-service -n observability-demo --timeout=120s

# Deploy load generator
echo "🎯 Deploying load generator..."
kubectl apply -f k8s/load-generator.yaml

# Check deployment status
echo "📋 Deployment Status:"
kubectl get pods -n observability-demo

echo "🌐 Services:"
kubectl get services -n observability-demo

echo "✅ Deployment completed successfully!"
echo ""
echo "🔍 To access the services:"
echo "1. Port forward to access services locally:"
echo "   kubectl port-forward -n observability-demo service/orders-service 8080:8080"
echo "   kubectl port-forward -n observability-demo service/inventory-service 8081:8080"
echo ""
echo "2. Test the services:"
echo "   curl http://localhost:8080/orders/health"
echo "   curl http://localhost:8081/inventory/health"
echo ""
echo "3. Create some orders:"
echo "   curl -X POST 'http://localhost:8080/orders?sku=ALPHA&qty=2'"
echo ""
echo "4. Check logs with trace correlation:"
echo "   kubectl logs -n observability-demo -l app=orders-service"
echo "   kubectl logs -n observability-demo -l app=inventory-service"



