# Orders Service

Implements order placement and persistence with Postgres. Uses `observability-starter` for annotation-only tracing, structured logging, baggage, and HTTP context propagation.

## Endpoints
- `POST /orders?sku=SKU123&qty=2` – Create an order (reserves inventory remotely first)
- `GET /orders` – List orders
- `GET /orders/health` – Health check

## Observability
- Request span: `HTTP METHOD /orders` created by interceptor if no upstream span
- Method spans: `OrdersController.create`, `OrderService.place`, etc.
- Inter-service call to Inventory carries W3C trace headers via RestTemplate interceptor.

## Configuration (`application.yml`)
Highlights:
```
observability:
  service-name: orders-service
  exporter: otlp
  otlp-endpoint: http://otel-collector:4317
```

## Local Run
```bash
mvn -pl observability-starter,services/orders-service -am spring-boot:run
```

## Docker Build
```bash
mvn -pl services/orders-service -am package
docker build -t your-reg/orders-service:1.0.0 ./services/orders-service
```

## Example Order
```bash
curl -X POST "http://localhost:8080/orders?sku=ABC&qty=1"
```

Trace & logs will show `traceId` / `spanId` correlated.

