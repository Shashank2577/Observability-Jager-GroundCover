# 🚀 Rancher Deployment Guide - GroundCover Observability with OTLP Logging

This guide provides multiple deployment options for deploying the GroundCover Observability Demo with complete OTLP logging to your Rancher cluster.

## 📋 Prerequisites

### 1. Rancher Cluster Access
- Ensure you have access to your Rancher cluster
- Download kubeconfig from Rancher UI or configure kubectl
- Verify cluster connectivity: `kubectl cluster-info`

### 2. Required Tools
- `kubectl` configured for your Rancher cluster
- `docker` for building images (if needed)
- `helm` (for Helm deployment option)

### 3. GroundCover Endpoints
- GroundCover GRPC endpoint: `http://10.1.1.202:31519`
- GroundCover HTTP endpoint: `http://10.1.1.202:30907`

## 🚀 Deployment Options

### Option 1: Quick Kubernetes Deployment (Recommended)

**Use the enhanced deployment script with OTLP logging:**

```bash
# Make script executable
chmod +x scripts/deploy-to-rancher-otlp-logs.sh

# Deploy with OTLP logging
./scripts/deploy-to-rancher-otlp-logs.sh
```

**What this script does:**
- ✅ Checks cluster connectivity
- ✅ Verifies required images
- ✅ Updates OTLP collector configuration for GroundCover
- ✅ Deploys services with OTLP logging environment variables
- ✅ Sets up port forwarding
- ✅ Tests services
- ✅ Shows deployment summary

### Option 2: Helm Deployment

**Deploy using Helm charts:**

```bash
# Add Helm repository (if needed)
helm repo add stable https://charts.helm.sh/stable

# Deploy using Helm
helm install observability-demo ./helm/groundcover-observability-demo \
  --namespace observability-demo \
  --create-namespace \
  --set global.namespace=observability-demo
```

### Option 3: Manual Kubernetes Deployment

**Step-by-step manual deployment:**

```bash
# 1. Create namespace
kubectl apply -f k8s/namespace.yaml

# 2. Deploy databases
kubectl apply -f k8s/postgres-orders.yaml
kubectl apply -f k8s/postgres-inventory.yaml

# 3. Wait for databases
kubectl wait --for=condition=ready pod -l app=orders-postgres -n observability-demo --timeout=60s
kubectl wait --for=condition=ready pod -l app=inventory-postgres -n observability-demo --timeout=60s

# 4. Deploy OTLP collector with GroundCover logging
kubectl apply -f k8s/otel-collector-groundcover.yaml

# 5. Wait for collector
kubectl wait --for=condition=ready pod -l app=otel-collector -n observability-demo --timeout=60s

# 6. Deploy application services
kubectl apply -f k8s/orders-service.yaml
kubectl apply -f k8s/inventory-service.yaml

# 7. Wait for services
kubectl wait --for=condition=ready pod -l app=orders-service -n observability-demo --timeout=120s
kubectl wait --for=condition=ready pod -l app=inventory-service -n observability-demo --timeout=120s

# 8. Deploy load generator
kubectl apply -f k8s/load-generator.yaml
```

## 🔧 Configuration Details

### OTLP Collector Configuration

The OTLP collector is configured with:

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  filelog:
    include: [ "/var/log/app/*.log" ]
    start_at: beginning
  syslog:
    listen_address: "0.0.0.0:514"
    protocol: tcp

exporters:
  otlp/groundcover-grpc:
    endpoint: http://10.1.1.202:31519
    tls:
      insecure: true
  otlp/groundcover-logs-grpc:
    endpoint: http://10.1.1.202:31519
    tls:
      insecure: true

processors:
  resource:
    attributes:
      - key: deployment.environment
        value: groundcover-demo
        action: upsert
      - key: service.namespace
        value: shash.demo
        action: upsert

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [resource, batch]
      exporters: [logging, otlp/groundcover-grpc]
    logs:
      receivers: [otlp, filelog, syslog]
      processors: [resource, batch]
      exporters: [logging, otlp/groundcover-logs-grpc]
```

### Service Environment Variables

Each service is configured with:

```yaml
env:
  - name: OTLP_ENDPOINT
    value: "http://otel-collector:4317"
  - name: OTLP_LOGS_ENDPOINT
    value: "http://otel-collector:4317"
  - name: OBSERVABILITY_SERVICE_NAME
    value: "shash.demo-orders-service"  # or shash.demo-inventory-service
```

## 🌐 Accessing Services

### Port Forwarding Setup

```bash
# Set up port forwarding
kubectl port-forward -n observability-demo service/orders-service 8080:8080 &
kubectl port-forward -n observability-demo service/inventory-service 8081:8080 &
kubectl port-forward -n observability-demo service/jaeger 16686:16686 &
```

### Service URLs

- **Orders Service**: http://localhost:8080
- **Inventory Service**: http://localhost:8081
- **Jaeger UI**: http://localhost:16686

## 🧪 Testing the Deployment

### Health Checks

```bash
# Test service health
curl http://localhost:8080/orders/health
curl http://localhost:8081/inventory/health
```

### Create Test Orders

```bash
# Create an order
curl -X POST "http://localhost:8080/orders?sku=ALPHA&qty=2"

# List orders
curl http://localhost:8080/orders

# Check inventory
curl http://localhost:8081/inventory
```

### Generate Load

```bash
# The load generator will automatically start generating traffic
# You can also manually create orders to generate traces and logs
```

## 📊 GroundCover Verification

### 1. Check Logs in GroundCover
- Navigate to GroundCover UI
- Go to Logs section
- Filter by `service.namespace: shash.demo`
- Look for `trace_id` field in log entries

### 2. Verify Trace Correlation
- Enable "Correlation by Trace ID" toggle in GroundCover
- Verify logs are linked to traces
- Check that services appear under `shash.demo` namespace

### 3. Expected Log Format

Logs should appear in GroundCover with:

```json
{
  "service.name": "shash.demo-orders-service",
  "service.namespace": "shash.demo",
  "deployment.environment": "groundcover-demo",
  "trace_id": "1234567890abcdef1234567890abcdef",
  "span_id": "1234567890abcdef",
  "logger.name": "com.acme.orders.service.OrdersService",
  "log.level": "INFO",
  "log.message": "Processing order request"
}
```

## 🔍 Troubleshooting

### Common Issues

#### 1. Pods Not Starting
```bash
# Check pod status
kubectl get pods -n observability-demo

# Check pod logs
kubectl logs -n observability-demo -l app=orders-service
kubectl logs -n observability-demo -l app=inventory-service
```

#### 2. OTLP Connection Issues
```bash
# Check OTLP collector logs
kubectl logs -n observability-demo -l app=otel-collector

# Verify collector configuration
kubectl get configmap otel-collector-config -n observability-demo -o yaml
```

#### 3. GroundCover Not Receiving Logs
- Verify GroundCover endpoints are accessible from the cluster
- Check OTLP collector logs for export errors
- Ensure service names include `shash.demo` namespace

### Useful Commands

```bash
# View all resources
kubectl get all -n observability-demo

# View services
kubectl get services -n observability-demo

# View logs
kubectl logs -n observability-demo -l app=orders-service
kubectl logs -n observability-demo -l app=inventory-service

# Describe resources
kubectl describe pods -n observability-demo
kubectl describe services -n observability-demo

# Clean up
kubectl delete namespace observability-demo
```

## 🧹 Cleanup

To remove the deployment:

```bash
# Delete namespace (removes all resources)
kubectl delete namespace observability-demo

# Or delete individual resources
kubectl delete -f k8s/otel-collector-groundcover.yaml
kubectl delete -f k8s/orders-service.yaml
kubectl delete -f k8s/inventory-service.yaml
kubectl delete -f k8s/postgres-orders.yaml
kubectl delete -f k8s/postgres-inventory.yaml
kubectl delete -f k8s/namespace.yaml
```

## 📈 Monitoring and Observability

### Logs in GroundCover
- **Service Namespace**: `shash.demo`
- **Trace Correlation**: Enabled via `trace_id` field
- **Log Format**: Structured JSON with OpenTelemetry attributes
- **Export Method**: OTLP to GroundCover endpoints

### Traces in GroundCover
- **Service Names**: `shash.demo-orders-service`, `shash.demo-inventory-service`
- **Trace Correlation**: Linked to logs via `trace_id`
- **Span Attributes**: Include GroundCover-specific metadata

### Metrics
- Service health endpoints
- Database connection metrics
- OTLP export metrics

## 🎉 Success Criteria

Your deployment is successful when:

1. ✅ All pods are running in `observability-demo` namespace
2. ✅ Services are accessible via port forwarding
3. ✅ Health checks pass
4. ✅ Logs appear in GroundCover under `shash.demo` namespace
5. ✅ Trace correlation works in GroundCover UI
6. ✅ Logs contain `trace_id` field for correlation

## 📞 Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review pod logs for errors
3. Verify GroundCover endpoint accessibility
4. Ensure all environment variables are set correctly

The deployment is now ready with complete OTLP logging to GroundCover! 🚀
