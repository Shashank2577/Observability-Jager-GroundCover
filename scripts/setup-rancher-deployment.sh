#!/bin/bash

# Setup and Deploy GroundCover Observability to Rancher
# This script helps configure kubectl and deploy the observability stack

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Rancher Deployment Setup${NC}"
echo "=================================="

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

# Function to check kubectl configuration
check_kubectl() {
    print_info "Checking kubectl configuration..."
    
    if kubectl cluster-info &> /dev/null; then
        print_status "kubectl is configured and cluster is accessible"
        kubectl cluster-info
        return 0
    else
        print_error "kubectl is not configured or cluster is not accessible"
        return 1
    fi
}

# Function to setup kubectl
setup_kubectl() {
    print_info "Setting up kubectl for Rancher cluster..."
    
    echo ""
    print_info "Please choose one of the following options:"
    echo ""
    echo "1. I have a kubeconfig file from Rancher UI"
    echo "2. I want to use Rancher CLI"
    echo "3. I want to manually configure kubectl"
    echo "4. Skip kubectl setup (already configured)"
    echo ""
    
    read -p "Enter your choice (1-4): " choice
    
    case $choice in
        1)
            read -p "Enter the path to your kubeconfig file: " kubeconfig_path
            if [ -f "$kubeconfig_path" ]; then
                export KUBECONFIG="$kubeconfig_path"
                print_status "Kubeconfig set to: $kubeconfig_path"
            else
                print_error "File not found: $kubeconfig_path"
                exit 1
            fi
            ;;
        2)
            read -p "Enter your Rancher server URL: " rancher_url
            read -p "Enter your Rancher API token: " rancher_token
            read -p "Enter your cluster name: " cluster_name
            
            print_info "Setting up Rancher CLI configuration..."
            # This would require rancher CLI to be installed
            print_warning "Please ensure rancher CLI is installed and configured"
            ;;
        3)
            print_info "Please configure kubectl manually and run this script again"
            print_info "You can:"
            print_info "  - Download kubeconfig from Rancher UI"
            print_info "  - Set KUBECONFIG environment variable"
            print_info "  - Copy kubeconfig to ~/.kube/config"
            exit 0
            ;;
        4)
            print_info "Skipping kubectl setup"
            ;;
        *)
            print_error "Invalid choice"
            exit 1
            ;;
    esac
}

# Function to verify cluster access
verify_cluster() {
    print_info "Verifying cluster access..."
    
    if kubectl cluster-info &> /dev/null; then
        print_status "Cluster is accessible"
        
        # Get cluster info
        print_info "Cluster Information:"
        kubectl cluster-info
        
        # Check nodes
        print_info "Available Nodes:"
        kubectl get nodes
        
        # Check permissions
        if kubectl auth can-i create namespaces &> /dev/null; then
            print_status "You have sufficient permissions to create resources"
        else
            print_warning "You may not have sufficient permissions to create resources"
            print_info "Please ensure your account has cluster-admin or appropriate permissions"
        fi
        
        return 0
    else
        print_error "Cannot access cluster"
        return 1
    fi
}

# Function to check required images
check_images() {
    print_info "Checking required images..."
    
    local images=("shashtaazaa/orders-service:1.0.0" "shashtaazaa/inventory-service:1.0.0")
    local missing_images=()
    
    for image in "${images[@]}"; do
        if ! docker pull "$image" &> /dev/null; then
            missing_images+=("$image")
        fi
    done
    
    if [ ${#missing_images[@]} -gt 0 ]; then
        print_warning "Some images are missing:"
        for image in "${missing_images[@]}"; do
            echo "  - $image"
        done
        print_info "Building and pushing images..."
        ./scripts/build-and-push.sh
    else
        print_status "All required images are available"
    fi
}

# Function to deploy the observability stack
deploy_observability() {
    print_info "Deploying GroundCover Observability with OTLP Logging..."
    
    # Run the deployment script
    if [ -f "./scripts/deploy-to-rancher-otlp-logs.sh" ]; then
        print_info "Running OTLP logging deployment script..."
        ./scripts/deploy-to-rancher-otlp-logs.sh
    else
        print_error "Deployment script not found"
        exit 1
    fi
}

# Function to show next steps
show_next_steps() {
    echo ""
    echo "=================================="
    print_status "Setup Complete!"
    echo "=================================="
    echo ""
    
    print_info "Next Steps:"
    echo "1. Verify deployment: kubectl get pods -n observability-demo"
    echo "2. Check services: kubectl get services -n observability-demo"
    echo "3. View logs: kubectl logs -n observability-demo -l app=orders-service"
    echo "4. Access services via port forwarding:"
    echo "   kubectl port-forward -n observability-demo service/orders-service 8080:8080"
    echo "   kubectl port-forward -n observability-demo service/inventory-service 8081:8080"
    echo ""
    
    print_info "Test Commands:"
    echo "curl http://localhost:8080/orders/health"
    echo "curl http://localhost:8081/inventory/health"
    echo "curl -X POST 'http://localhost:8080/orders?sku=ALPHA&qty=2'"
    echo ""
    
    print_info "GroundCover Verification:"
    echo "1. Check logs in GroundCover UI"
    echo "2. Filter by service.namespace: shash.demo"
    echo "3. Look for trace_id field in log entries"
    echo "4. Enable 'Correlation by Trace ID' toggle"
    echo ""
}

# Main function
main() {
    # Check if kubectl is already configured
    if ! check_kubectl; then
        print_info "kubectl is not configured. Let's set it up..."
        setup_kubectl
    fi
    
    # Verify cluster access
    if ! verify_cluster; then
        print_error "Cannot access cluster. Please check your configuration."
        exit 1
    fi
    
    # Check images
    check_images
    
    # Deploy observability stack
    deploy_observability
    
    # Show next steps
    show_next_steps
    
    print_status "🎉 Deployment completed successfully!"
}

# Run main function
main "$@"
