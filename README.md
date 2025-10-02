# 🚀 GroundCover Observability Demo

A comprehensive microservices observability demo showcasing distributed tracing, logging, and monitoring with OpenTelemetry and GroundCover integration.

## 📋 Overview

This project demonstrates end-to-end observability in a microservices architecture with:
- **Orders Service**: Places orders and manages order lifecycle
- **Inventory Service**: Manages stock and reservations
- **Distributed Tracing**: Full request flow visibility across services
- **Structured Logging**: Trace-correlated logs with context propagation
- **Multiple Deployment Options**: Local development, Docker Compose, and Kubernetes

## 🏗️ Architecture

```
┌─────────────────┐    HTTP + TraceContext    ┌──────────────────┐
│   Orders Svc    │ ────────────────────────► │  Inventory Svc   │
│   (Spring Boot) │                           │   (Spring Boot)  │
│   @OtelSpan     │ ◄────── (reserve) ─────── │   @OtelSpan      │
└─────────┬───────┘                           └─────────┬────────┘
          │ PostgreSQL (orders)                        │ PostgreSQL (inventory)
          ▼                                            ▼
    orders-postgres                            inventory-postgres

                    ┌─────────────────┐
                    │ Otel Collector  │ ──► GroundCover / Jaeger
                    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Java 17+
- Maven 3.9+
- Docker Desktop
- kubectl (for Kubernetes deployment)

### 1. Local Development (Recommended for Testing)

```bash
# Clone and build
git clone <repository-url>
cd GroundCoverObservability
mvn clean install

# Start infrastructure
docker-compose up -d

# Start services locally
./scripts/start-local.sh

# Test the services
curl -X POST "http://localhost:8081/orders?sku=OMEGA&qty=1"
```

### 2. Docker Compose (Full Containerized)

```bash
# Start all services including applications
docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d

# Test services
curl -X POST "http://localhost:8081/orders?sku=OMEGA&qty=1"
```

### 3. Kubernetes Deployment

```bash
# Build and push images
./scripts/build-and-push.sh

# Deploy to Kubernetes
kubectl apply -f k8s/

# Port forward for local access
kubectl port-forward service/orders-service 8081:8080
kubectl port-forward service/jaeger 16686:16686
```

## 🔧 Configuration

### Environment-Specific Settings

The project supports multiple deployment environments through Spring profiles:

| Environment | Profile | Database | Service URLs |
|-------------|---------|----------|--------------|
| **Local** | `local` | `localhost:5433/5434` | `localhost:8080/8081` |
| **Docker** | `cloud` | `service-name:5432` | `service-name:8080` |
| **Kubernetes** | `cloud` | `service-name:5432` | `service-name:8080` |

### Key Configuration Files

```
services/
├── orders-service/
│   └── src/main/resources/
│       ├── application.yml          # Base configuration
│       ├── application-local.yml    # Local development
│       └── application-cloud.yml    # Cloud deployment
└── inventory-service/
    └── src/main/resources/
        ├── application.yml          # Base configuration
        ├── application-local.yml    # Local development
        └── application-cloud.yml    # Cloud deployment
```

## 📊 Observability Features

### Distributed Tracing
- **W3C TraceContext** propagation across HTTP calls
- **Server spans** for incoming requests
- **Client spans** for outbound HTTP calls
- **Custom spans** via `@OtelSpan` annotation

### Structured Logging
- **Trace correlation** with `traceId` and `spanId`
- **Baggage propagation** for user context
- **Structured attributes** for better searchability

### Monitoring Integration
- **OpenTelemetry Collector** for trace aggregation
- **Jaeger UI** for trace visualization
- **GroundCover** integration ready

## 🛠️ Development

### Project Structure

```
├── observability-starter/          # Custom observability library
│   ├── src/main/java/
│   │   └── com/acme/observability/
│   │       ├── annotation/         # @OtelSpan annotation
│   │       ├── aop/               # AspectJ aspects
│   │       ├── autoconfig/        # Spring Boot auto-configuration
│   │       ├── logging/           # Structured logging helpers
│   │       └── web/               # HTTP tracing interceptors
│   └── pom.xml
├── services/
│   ├── orders-service/            # Orders microservice
│   └── inventory-service/         # Inventory microservice
├── k8s/                          # Kubernetes manifests
├── helm/                         # Helm charts
├── scripts/                      # Deployment scripts
└── docker-compose.yml           # Local development
```

### Building the Project

```bash
# Build all modules
mvn clean install

# Build specific service
cd services/orders-service
mvn clean package

# Build Docker images
docker build -t your-registry/orders-service:latest services/orders-service/
docker build -t your-registry/inventory-service:latest services/inventory-service/
```

## 🧪 Testing

### Manual Testing

```bash
# Health checks
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health

# Create orders
curl -X POST "http://localhost:8081/orders?sku=ALPHA&qty=2"
curl -X POST "http://localhost:8081/orders?sku=BETA&qty=1"

# List orders
curl http://localhost:8081/orders

# Check inventory
curl http://localhost:8080/inventory
```

### Load Testing

```bash
# Generate traffic
./scripts/load-generator.sh

# Or use the included load generator
kubectl apply -f k8s/load-generator.yaml
```

## 📈 Observability Data

### Jaeger UI
- **URL**: `http://localhost:16686`
- **Services**: `orders-service`, `inventory-service`
- **Traces**: Full request flows with timing and dependencies

### Logs with Trace Correlation
```bash
# View correlated logs
kubectl logs -l app=orders-service
kubectl logs -l app=inventory-service

# Example log output:
# 2025-09-26 15:23:21 INFO [http-nio-8081-exec-2] creating order | attrs={sku=OMEGA, qty=1} traceId=837faada3eab589261ad018b25d7cc45 spanId=e8841a8e872bb305
```

## 🚀 Deployment Options

### 1. Local Development
```bash
# Start infrastructure
docker-compose up -d

# Start services
./scripts/start-local.sh
```

### 2. Docker Compose
```bash
# Full containerized deployment
docker-compose -f docker-compose.yml -f docker-compose.override.yml up -d
```

### 3. Kubernetes
```bash
# Deploy to Kubernetes
kubectl apply -f k8s/

# Or use Helm
helm install observability-demo ./helm/groundcover-observability-demo
```

### 4. Rancher Cloud
```bash
# Deploy to Rancher cluster
rancher kubectl apply -f k8s/ -n personal-workspace
```

## 🔧 Customization

### Adding Custom Spans
```java
@Service
public class OrderService {
    
    @OtelSpan("order.creation")
    public Order createOrder(String sku, int quantity) {
        // Your business logic
        return order;
    }
}
```

### Custom Baggage Headers
```java
// Add custom headers to baggage
BaggageFilter.HEADER_KEYS.add("x-custom-header");
```

### Sampling Configuration
```yaml
observability:
  sampling-probability: 0.1  # 10% sampling
```

## 🧹 Cleanup

### Local Development
```bash
# Stop services
killall java

# Stop infrastructure
docker-compose down
```

### Kubernetes
```bash
# Remove deployment
kubectl delete -f k8s/

# Or remove namespace
kubectl delete namespace observability-demo
```

### Docker Compose
```bash
# Stop and remove containers
docker-compose down
```

## 🔍 Troubleshooting

### Common Issues

1. **Services can't connect**
   - Check service URLs in configuration
   - Verify network connectivity
   - Check firewall settings

2. **Traces not appearing**
   - Verify OTLP endpoint configuration
   - Check collector logs
   - Ensure sampling is enabled

3. **Database connection issues**
   - Check database URLs
   - Verify database is running
   - Check credentials

### Debug Commands

```bash
# Check service health
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health

# Check Jaeger services
curl http://localhost:16686/api/services

# View logs
kubectl logs -l app=orders-service
kubectl logs -l app=inventory-service
```

## 📚 Documentation

- [Configuration Guide](CONFIGURATION_GUIDE.md) - Environment-specific configuration
- [Deployment Guide](DEPLOYMENT_GUIDE.md) - Complete deployment instructions
- [Rancher Connection Guide](RANCHER_CONNECTION_GUIDE.md) - Rancher cloud deployment

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is for educational and demonstration purposes. Feel free to adapt and use in your own projects.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review the logs for error messages
3. Verify your environment configuration
4. Check the documentation links above

---

**Happy Observing! 🔍✨**