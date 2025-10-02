#!/bin/bash

# Deploy GroundCover Observability Demo with OTLP Logging to Rancher Cluster
# This script deploys all services with complete OTLP logging configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="observability-demo"
TIMEOUT=120
MAX_RETRIES=3

echo -e "${BLUE}🚀 Deploying GroundCover Observability Demo with OTLP Logging to Rancher${NC}"
echo "=================================================================="

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check cluster connectivity
check_cluster_connectivity() {
    print_info "Checking cluster connectivity..."
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "kubectl is not configured or cluster is not accessible"
        print_info "Please ensure your kubeconfig is properly configured for your Rancher cluster"
        print_info "You can download kubeconfig from Rancher UI or use: export KUBECONFIG=/path/to/rancher-kubeconfig.yaml"
        exit 1
    fi
    
    print_status "Cluster connectivity verified"
}

# Function to check if images exist
check_images() {
    print_info "Checking if required images exist..."
    
    local images=("shashtaazaa/orders-service:1.4.0-groundcover" "shashtaazaa/inventory-service:1.4.0-groundcover")
    
    for image in "${images[@]}"; do
        if ! docker pull "$image" &> /dev/null; then
            print_warning "Image $image not found locally or in registry"
            print_info "Building and pushing images..."
            ./scripts/build-and-push.sh
            break
        fi
    done
    
    print_status "Required images verified"
}

# Function to deploy with retry logic
deploy_with_retry() {
    local manifest=$1
    local retries=0
    
    while [ $retries -lt $MAX_RETRIES ]; do
        if kubectl apply -f "$manifest" &> /dev/null; then
            print_status "Successfully applied $manifest"
            return 0
        else
            retries=$((retries + 1))
            print_warning "Failed to apply $manifest (attempt $retries/$MAX_RETRIES)"
            sleep 5
        fi
    done
    
    print_error "Failed to apply $manifest after $MAX_RETRIES attempts"
    return 1
}

# Function to wait for pods to be ready
wait_for_pods() {
    local selector=$1
    local timeout=${2:-60}
    local retries=0
    
    print_info "Waiting for pods with selector: $selector"
    
    while [ $retries -lt $MAX_RETRIES ]; do
        if kubectl wait --for=condition=ready pod -l "$selector" -n "$NAMESPACE" --timeout="${timeout}s" 2>/dev/null; then
            print_status "Pods with selector '$selector' are ready"
            return 0
        else
            retries=$((retries + 1))
            print_warning "Attempt $retries failed. Retrying in 10 seconds..."
            sleep 10
        fi
    done
    
    print_error "Failed to get pods ready after $MAX_RETRIES attempts"
    return 1
}

# Function to update OTLP collector config
update_otel_collector_config() {
    print_info "Updating OTLP collector configuration for GroundCover logging..."
    
    # Create the updated OTLP collector config
    cat > k8s/otel-collector-groundcover.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-config
  namespace: observability-demo
  labels:
    app: otel-collector
data:
  otel-collector-config.yaml: |
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318
      # File log receiver for application logs
      filelog:
        include: [ "/var/log/app/*.log" ]
        start_at: beginning
        operators:
          - type: json_parser
            parse_from: body
          - type: move
            from: attributes.trace_id
            to: trace_id
          - type: move
            from: attributes.span_id
            to: span_id
      # Syslog receiver for container logs
      syslog:
        listen_address: "0.0.0.0:514"
        protocol: tcp

    exporters:
      logging:
        loglevel: debug
      otlp/groundcover-grpc:
        endpoint: http://10.1.1.202:31519
        tls:
          insecure: true
      otlp/groundcover-http:
        endpoint: http://10.1.1.202:30907
        tls:
          insecure: true
      # Log exporters to GroundCover
      otlp/groundcover-logs-grpc:
        endpoint: http://10.1.1.202:31519
        tls:
          insecure: true
      otlp/groundcover-logs-http:
        endpoint: http://10.1.1.202:30907
        tls:
          insecure: true

    processors:
      batch:
        timeout: 1s
        send_batch_size: 1024
      resource:
        attributes:
          - key: deployment.environment
            value: groundcover-demo
            action: upsert
          - key: service.namespace
            value: shash.demo
            action: upsert
          - key: service.version
            value: "1.4.0-groundcover"
            action: upsert

    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [resource, batch]
          exporters: [logging, otlp/groundcover-grpc, otlp/groundcover-http]
        logs:
          receivers: [otlp, filelog, syslog]
          processors: [resource, batch]
          exporters: [logging, otlp/groundcover-logs-grpc, otlp/groundcover-logs-http]
---
apiVersion: v1
kind: Service
metadata:
  name: otel-collector
  namespace: observability-demo
  labels:
    app: otel-collector
spec:
  type: ClusterIP
  selector:
    app: otel-collector
  ports:
    - name: otlp-grpc
      port: 4317
      targetPort: 4317
    - name: otlp-http
      port: 4318
      targetPort: 4318
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: otel-collector
  namespace: observability-demo
  labels:
    app: otel-collector
spec:
  replicas: 1
  selector:
    matchLabels:
      app: otel-collector
  template:
    metadata:
      labels:
        app: otel-collector
    spec:
      containers:
        - name: otel-collector
          image: otel/opentelemetry-collector-contrib:0.95.0
          args: ["--config=/conf/otel-collector-config.yaml"]
          ports:
            - containerPort: 4317
            - containerPort: 4318
          volumeMounts:
            - name: config
              mountPath: /conf
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
      volumes:
        - name: config
          configMap:
            name: otel-collector-config
            items:
              - key: otel-collector-config.yaml
                path: otel-collector-config.yaml
EOF

    print_status "OTLP collector configuration updated for GroundCover logging"
}

# Function to update service configurations
update_service_configs() {
    print_info "Updating service configurations for OTLP logging..."
    
    # Update orders service
    cat > k8s/orders-service-otlp.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: orders-service
  namespace: observability-demo
  labels:
    app: orders-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: orders-service
  template:
    metadata:
      labels:
        app: orders-service
    spec:
      containers:
        - name: orders-service
          image: shashtaazaa/orders-service:1.4.0-groundcover
          ports:
            - containerPort: 8080
          env:
            - name: SPRING_DATASOURCE_URL
              value: "jdbc:postgresql://orders-postgres:5432/orders"
            - name: SPRING_DATASOURCE_USERNAME
              value: "orders"
            - name: SPRING_DATASOURCE_PASSWORD
              value: "orders"
            - name: OTLP_ENDPOINT
              value: "http://otel-collector:4317"
            - name: OTLP_LOGS_ENDPOINT
              value: "http://otel-collector:4317"
            - name: OBSERVABILITY_SERVICE_NAME
              value: "shash.demo-orders-service"
            - name: INVENTORY_BASE_URL
              value: "http://inventory-service:8080"
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
---
apiVersion: v1
kind: Service
metadata:
  name: orders-service
  namespace: observability-demo
  labels:
    app: orders-service
spec:
  type: ClusterIP
  selector:
    app: orders-service
  ports:
    - port: 8080
      targetPort: 8080
EOF

    # Update inventory service
    cat > k8s/inventory-service-otlp.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inventory-service
  namespace: observability-demo
  labels:
    app: inventory-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: inventory-service
  template:
    metadata:
      labels:
        app: inventory-service
    spec:
      containers:
        - name: inventory-service
          image: shashtaazaa/inventory-service:1.4.0-groundcover
          ports:
            - containerPort: 8080
          env:
            - name: SPRING_DATASOURCE_URL
              value: "jdbc:postgresql://inventory-postgres:5432/inventory"
            - name: SPRING_DATASOURCE_USERNAME
              value: "inventory"
            - name: SPRING_DATASOURCE_PASSWORD
              value: "inventory"
            - name: OTLP_ENDPOINT
              value: "http://otel-collector:4317"
            - name: OTLP_LOGS_ENDPOINT
              value: "http://otel-collector:4317"
            - name: OBSERVABILITY_SERVICE_NAME
              value: "shash.demo-inventory-service"
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
---
apiVersion: v1
kind: Service
metadata:
  name: inventory-service
  namespace: observability-demo
  labels:
    app: inventory-service
spec:
  type: ClusterIP
  selector:
    app: inventory-service
  ports:
    - port: 8080
      targetPort: 8080
EOF

    print_status "Service configurations updated for OTLP logging"
}

# Function to setup port forwarding
setup_port_forwarding() {
    print_info "Setting up port forwarding..."
    
    # Kill existing port forwards
    pkill -f "kubectl port-forward.*observability-demo" 2>/dev/null || true
    
    # Start port forwarding in background
    kubectl port-forward -n "$NAMESPACE" service/orders-service 8080:8080 &
    kubectl port-forward -n "$NAMESPACE" service/inventory-service 8081:8080 &
    kubectl port-forward -n "$NAMESPACE" service/jaeger 16686:16686 &
    
    # Wait a moment for port forwards to establish
    sleep 5
    
    print_status "Port forwarding setup complete"
    print_info "Services accessible at:"
    print_info "  - Orders Service: http://localhost:8080"
    print_info "  - Inventory Service: http://localhost:8081"
    print_info "  - Jaeger UI: http://localhost:16686"
}

# Function to test services
test_services() {
    print_info "Testing services..."
    
    # Wait for services to be ready
    sleep 10
    
    # Test health endpoints
    if curl -s http://localhost:8080/orders/health > /dev/null; then
        print_status "Orders service health check passed"
    else
        print_warning "Orders service health check failed"
    fi
    
    if curl -s http://localhost:8081/inventory/health > /dev/null; then
        print_status "Inventory service health check passed"
    else
        print_warning "Inventory service health check failed"
    fi
    
    # Create a test order
    if curl -s -X POST "http://localhost:8080/orders?sku=TEST&qty=1" > /dev/null; then
        print_status "Test order creation successful"
    else
        print_warning "Test order creation failed"
    fi
}

# Function to show deployment summary
show_summary() {
    echo ""
    echo "=================================================================="
    print_status "OTLP Logging Deployment Summary"
    echo "=================================================================="
    echo ""
    
    print_info "Cluster Information:"
    kubectl cluster-info
    echo ""
    
    print_info "Deployed Resources:"
    kubectl get all -n "$NAMESPACE"
    echo ""
    
    print_info "Access Information:"
    echo "  🌐 Orders Service: http://localhost:8080"
    echo "  🌐 Inventory Service: http://localhost:8081"
    echo "  📊 Jaeger UI: http://localhost:16686"
    echo ""
    
    print_info "OTLP Logging Features:"
    echo "  📝 Logs sent to GroundCover via OTLP"
    echo "  🔗 Trace correlation with trace_id field"
    echo "  🏷️  Service namespace: shash.demo"
    echo "  📊 Structured JSON logging"
    echo ""
    
    print_info "Useful Commands:"
    echo "  📋 View pods: kubectl get pods -n $NAMESPACE"
    echo "  📋 View services: kubectl get services -n $NAMESPACE"
    echo "  📋 View logs: kubectl logs -n $NAMESPACE -l app=orders-service"
    echo "  🧹 Cleanup: kubectl delete namespace $NAMESPACE"
    echo ""
    
    print_info "Test Commands:"
    echo "  🧪 Health check: curl http://localhost:8080/orders/health"
    echo "  🧪 Create order: curl -X POST 'http://localhost:8080/orders?sku=ALPHA&qty=2'"
    echo "  🧪 List orders: curl http://localhost:8080/orders"
    echo "  🧪 Check inventory: curl http://localhost:8081/inventory"
    echo ""
    
    print_info "GroundCover Verification:"
    echo "  🔍 Check logs in GroundCover UI"
    echo "  🔍 Filter by service.namespace: shash.demo"
    echo "  🔍 Look for trace_id field in log entries"
    echo "  🔍 Enable 'Correlation by Trace ID' toggle"
    echo ""
}

# Main deployment process
main() {
    # Pre-deployment checks
    check_cluster_connectivity
    check_images
    
    # Update configurations
    update_otel_collector_config
    update_service_configs
    
    # Create namespace
    print_info "Creating namespace..."
    deploy_with_retry "k8s/namespace.yaml"
    
    # Deploy databases
    print_info "Deploying PostgreSQL databases..."
    deploy_with_retry "k8s/postgres-orders.yaml"
    deploy_with_retry "k8s/postgres-inventory.yaml"
    
    # Wait for databases
    wait_for_pods "app=orders-postgres" 60
    wait_for_pods "app=inventory-postgres" 60
    
    # Deploy observability stack with OTLP logging
    print_info "Deploying OTLP collector with GroundCover logging..."
    deploy_with_retry "k8s/otel-collector-groundcover.yaml"
    
    # Wait for collector
    wait_for_pods "app=otel-collector" 60
    
    # Deploy application services with OTLP logging
    print_info "Deploying application services with OTLP logging..."
    deploy_with_retry "k8s/orders-service-otlp.yaml"
    deploy_with_retry "k8s/inventory-service-otlp.yaml"
    
    # Wait for services
    wait_for_pods "app=orders-service" 120
    wait_for_pods "app=inventory-service" 120
    
    # Deploy load generator
    print_info "Deploying load generator..."
    deploy_with_retry "k8s/load-generator.yaml"
    
    # Setup port forwarding
    setup_port_forwarding
    
    # Test services
    test_services
    
    # Show summary
    show_summary
    
    print_status "🎉 OTLP Logging Deployment completed successfully!"
    print_info "Your logs are now being sent to GroundCover with trace correlation!"
}

# Run main function
main "$@"
