#!/bin/bash

# Start services locally with proper configuration
echo "Starting services locally..."

# Kill any existing processes
pkill -f "inventory-service-1.0.0-SNAPSHOT.jar" 2>/dev/null || true
pkill -f "orders-service-1.0.0-SNAPSHOT.jar" 2>/dev/null || true

# Start inventory service
echo "Starting inventory service on port 8080..."
java -jar services/inventory-service/target/inventory-service-1.0.0-SNAPSHOT.jar \
  --spring.profiles.active=local \
  --server.port=8080 \
  --spring.datasource.url=jdbc:postgresql://localhost:5434/inventory \
  --spring.datasource.username=inventory \
  --spring.datasource.password=inventory \
  --observability.otlp-endpoint=http://localhost:4317 \
  --observability.service-name=inventory-service &

# Wait for inventory service to start
sleep 10

# Start orders service
echo "Starting orders service on port 8081..."
java -jar services/orders-service/target/orders-service-1.0.0-SNAPSHOT.jar \
  --spring.profiles.active=local \
  --server.port=8081 \
  --spring.datasource.url=jdbc:postgresql://localhost:5433/orders \
  --spring.datasource.username=orders \
  --spring.datasource.password=orders \
  --observability.otlp-endpoint=http://localhost:4317 \
  --observability.service-name=orders-service \
  --inventory.base-url=http://localhost:8080 &

echo "Services started!"
echo "Inventory service: http://localhost:8080"
echo "Orders service: http://localhost:8081"
echo "Jaeger UI: http://localhost:16686"
