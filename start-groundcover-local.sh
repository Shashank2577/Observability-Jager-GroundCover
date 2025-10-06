#!/bin/bash

# Start services locally with GroundCover configuration
echo "🚀 Starting GroundCover Observability Demo locally..."

# Set GroundCover environment variables
export OTLP_ENDPOINT="https://api.groundcover.com/v1/otlp"
export GROUNDCOVER_TOKEN="${GROUNDCOVER_TOKEN:-your_groundcover_token_here}"
export GROUNDCOVER_PROJECT_ID="${GROUNDCOVER_PROJECT_ID:-your_project_id_here}"

# Kill any existing processes
echo "🧹 Cleaning up existing processes..."
pkill -f "inventory-service-1.0.0-SNAPSHOT.jar" 2>/dev/null || true
pkill -f "orders-service-1.0.0-SNAPSHOT.jar" 2>/dev/null || true

# Create log directories
mkdir -p /workspace/logs

# Start inventory service
echo "📦 Starting inventory service on port 8080..."
nohup java -jar /workspace/services/inventory-service/target/inventory-service-1.0.0-SNAPSHOT.jar \
  --spring.profiles.active=local \
  --server.port=8080 \
  --spring.datasource.url=jdbc:h2:mem:inventory \
  --spring.datasource.username=sa \
  --spring.datasource.password= \
  --spring.jpa.hibernate.ddl-auto=create-drop \
  --observability.otlp-endpoint="$OTLP_ENDPOINT" \
  --observability.service-name=inventory-service \
  --logging.file.name=/workspace/logs/inventory.log \
  > /workspace/logs/inventory-startup.log 2>&1 &

INVENTORY_PID=$!
echo "📦 Inventory service started with PID: $INVENTORY_PID"

# Wait for inventory service to start
echo "⏳ Waiting for inventory service to start..."
sleep 15

# Check if inventory service is running
if ! kill -0 $INVENTORY_PID 2>/dev/null; then
    echo "❌ Inventory service failed to start. Check logs:"
    cat /workspace/logs/inventory-startup.log
    exit 1
fi

# Start orders service
echo "🛒 Starting orders service on port 8081..."
nohup java -jar /workspace/services/orders-service/target/orders-service-1.0.0-SNAPSHOT.jar \
  --spring.profiles.active=local \
  --server.port=8081 \
  --spring.datasource.url=jdbc:h2:mem:orders \
  --spring.datasource.username=sa \
  --spring.datasource.password= \
  --spring.jpa.hibernate.ddl-auto=create-drop \
  --observability.otlp-endpoint="$OTLP_ENDPOINT" \
  --observability.service-name=orders-service \
  --inventory.base-url=http://localhost:8080 \
  --logging.file.name=/workspace/logs/orders.log \
  > /workspace/logs/orders-startup.log 2>&1 &

ORDERS_PID=$!
echo "🛒 Orders service started with PID: $ORDERS_PID"

# Wait for orders service to start
echo "⏳ Waiting for orders service to start..."
sleep 15

# Check if orders service is running
if ! kill -0 $ORDERS_PID 2>/dev/null; then
    echo "❌ Orders service failed to start. Check logs:"
    cat /workspace/logs/orders-startup.log
    exit 1
fi

echo ""
echo "✅ Services started successfully!"
echo "📦 Inventory service: http://localhost:8080"
echo "🛒 Orders service: http://localhost:8081"
echo "📊 GroundCover endpoint: $OTLP_ENDPOINT"
echo ""
echo "📋 Process IDs:"
echo "   Inventory: $INVENTORY_PID"
echo "   Orders: $ORDERS_PID"
echo ""
echo "📝 Logs location:"
echo "   Inventory: /workspace/logs/inventory.log"
echo "   Orders: /workspace/logs/orders.log"
echo ""
echo "🔍 To test the services:"
echo "   curl -X POST 'http://localhost:8081/orders?sku=ALPHA&qty=1'"
echo "   curl -X GET 'http://localhost:8080/inventory'"
echo ""
echo "🛑 To stop services:"
echo "   kill $INVENTORY_PID $ORDERS_PID"