#!/bin/bash

# Build and Push Images to Docker Hub
# This script builds and pushes the application images to your Docker Hub registry
#
#set -e
#
#echo "🐳 Building and pushing images to Docker Hub..."
#
## Build orders service
#echo "📦 Building orders-service..."
#docker build -t shashtaazaa/orders-service:1.11.6-groundcover -f services/orders-service/Dockerfile services/orders-service/
#
## Build inventory service
#echo "📦 Building inventory-service..."
#docker build -t shashtaazaa/inventory-service:1.11.6-groundcover -f services/inventory-service/Dockerfile services/inventory-service/
#
## Login to Docker Hub (if not already logged in)
#echo "🔐 Logging in to Docker Hub..."
#docker login
#
## Push orders service
#echo "⬆️ Pushing orders-service..."
#docker push shashtaazaa/orders-service:1.11.6-groundcover
#
## Push inventory service
#echo "⬆️ Pushing inventory-service..."
#docker push shashtaazaa/inventory-service:1.11.6-groundcover
#
#echo "✅ Images successfully built and pushed to Docker Hub!"
echo ""
echo "📋 Your images are now available:"
echo "  - shashtaazaa/orders-service:1.11.6-groundcover"
echo "  - shashtaazaa/inventory-service:1.11.6-groundcover"
echo ""
echo "🚀 You can now deploy to your Rancher cluster using:"
echo "  ./scripts/deploy-to-rancher.sh"
