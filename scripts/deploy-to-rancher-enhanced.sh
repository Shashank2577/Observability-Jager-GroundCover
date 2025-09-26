#!/bin/bash

# Enhanced Deploy GroundCover Observability Demo to Rancher Cluster
# This script provides comprehensive deployment with error handling and verification

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

echo -e "${BLUE}🚀 Enhanced Deployment to Rancher Cluster${NC}"
echo "================================================"

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

# Function to check cluster resources
check_cluster_resources() {
    print_info "Checking cluster resources..."
    
    # Check if we can create resources
    if ! kubectl auth can-i create namespaces &> /dev/null; then
        print_error "Insufficient permissions to create namespaces"
        print_info "Please ensure your account has cluster-admin or appropriate permissions"
        exit 1
    fi
    
    # Check node resources
    local node_count=$(kubectl get nodes --no-headers | wc -l)
    if [ "$node_count" -lt 1 ]; then
        print_error "No nodes found in cluster"
        exit 1
    fi
    
    print_status "Cluster resources verified ($node_count nodes available)"
}

# Function to check if images exist
check_images() {
    print_info "Checking if required images exist..."
    
    local images=("shashtaazaa/orders-service:1.0.0" "shashtaazaa/inventory-service:1.0.0")
    
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

# Function to verify deployment
verify_deployment() {
    print_info "Verifying deployment..."
    
    # Check all pods are running
    local failed_pods=$(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase!=Running --no-headers | wc -l)
    if [ "$failed_pods" -gt 0 ]; then
        print_warning "Some pods are not running. Checking details..."
        kubectl get pods -n "$NAMESPACE"
        kubectl describe pods -n "$NAMESPACE" --field-selector=status.phase!=Running
    fi
    
    # Check services
    local service_count=$(kubectl get services -n "$NAMESPACE" --no-headers | wc -l)
    print_status "Deployment verification complete ($service_count services running)"
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
    echo "================================================"
    print_status "Deployment Summary"
    echo "================================================"
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
}

# Main deployment process
main() {
    # Pre-deployment checks
    check_cluster_connectivity
    check_cluster_resources
    check_images
    
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
    
    # Deploy observability stack
    print_info "Deploying observability stack..."
    deploy_with_retry "k8s/otel-collector.yaml"
    
    # Wait for collector
    wait_for_pods "app=otel-collector" 60
    
    # Deploy application services
    print_info "Deploying application services..."
    deploy_with_retry "k8s/orders-service.yaml"
    deploy_with_retry "k8s/inventory-service.yaml"
    
    # Wait for services
    wait_for_pods "app=orders-service" 120
    wait_for_pods "app=inventory-service" 120
    
    # Deploy load generator
    print_info "Deploying load generator..."
    deploy_with_retry "k8s/load-generator.yaml"
    
    # Verify deployment
    verify_deployment
    
    # Setup port forwarding
    setup_port_forwarding
    
    # Test services
    test_services
    
    # Show summary
    show_summary
    
    print_status "🎉 Deployment completed successfully!"
}

# Run main function
main "$@"
