# Inventory Service

Maintains and reserves stock quantities. Provides reservation endpoint consumed by Orders Service. Uses `observability-starter` for explicit, annotation-driven spans and structured logging.

## Endpoints
- `GET /inventory` – List known inventory items
- `POST /inventory/reserve?sku=SKU123&qty=5` – Reserve quantity (creates item with default stock=100 if missing)
- `GET /inventory/health` – Health check

## Observability
- Request SERVER spans created by interceptor
- Method spans for annotated controller & service methods (`InventoryController.reserve`, `InventoryService.reserve`)
- Structured logs include `traceId` / `spanId`

## Configuration (`application.yml`)
Highlights:
```
observability:
  service-name: inventory-service
  exporter: otlp
  otlp-endpoint: http://otel-collector:4317
```

## Local Run
```bash
mvn -pl observability-starter,services/inventory-service -am spring-boot:run
```

## Docker Build
```bash
mvn -pl services/inventory-service -am package
docker build -t your-reg/inventory-service:1.0.0 ./services/inventory-service
```

## Example Reserve
```bash
curl -X POST "http://localhost:8080/inventory/reserve?sku=ABC&qty=3"
```

