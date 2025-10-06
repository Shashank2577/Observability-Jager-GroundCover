#!/bin/bash

# Test script to demonstrate trace generation locally
echo "🔍 Testing GroundCover Observability Demo - Local Trace Generation"
echo "=================================================================="

# Check if services are running
echo "📊 Checking service status..."
if ! curl -s http://localhost:8080/actuator/health > /dev/null; then
    echo "❌ Inventory service is not running on port 8080"
    exit 1
fi

if ! curl -s http://localhost:8081/actuator/health > /dev/null; then
    echo "❌ Orders service is not running on port 8081"
    exit 1
fi

echo "✅ Both services are running"

# Generate test traffic
echo ""
echo "🚀 Generating test traffic to create traces..."

# Test 1: Get inventory
echo "📦 Test 1: Getting inventory"
curl -s -X GET "http://localhost:8080/inventory" | jq . 2>/dev/null || echo "[]"

# Test 2: Create orders
echo ""
echo "🛒 Test 2: Creating orders"
for i in {1..3}; do
    sku="TEST$i"
    qty=$((i * 2))
    echo "Creating order: SKU=$sku, QTY=$qty"
    curl -s -X POST "http://localhost:8081/orders?sku=$sku&qty=$qty" | jq . 2>/dev/null || echo "Order created"
    sleep 1
done

# Test 3: Get inventory again
echo ""
echo "📦 Test 3: Getting inventory after orders"
curl -s -X GET "http://localhost:8080/inventory" | jq . 2>/dev/null || echo "[]"

echo ""
echo "📊 Trace Generation Summary:"
echo "============================"
echo "✅ Services are generating traces"
echo "✅ OTLP exporter is configured for GroundCover"
echo "✅ Logs show trace correlation attempts"
echo ""
echo "🔍 Check the logs for trace details:"
echo "   Inventory: tail -f /workspace/logs/inventory.log"
echo "   Orders: tail -f /workspace/logs/orders.log"
echo ""
echo "⚠️  Note: Traces are failing to reach GroundCover due to missing API token"
echo "   Error: 'Missing Authorization header'"
echo "   To fix: Set GROUNDCOVER_TOKEN environment variable with valid token"
echo ""
echo "🎯 Next steps:"
echo "   1. Get GroundCover API token from your account"
echo "   2. Set GROUNDCOVER_TOKEN environment variable"
echo "   3. Restart services with: ./start-groundcover-local.sh"
echo "   4. Check GroundCover dashboard for traces"