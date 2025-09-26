# groundcover-observability-demo Helm Chart

Helm chart packaging the Orders + Inventory microservices, optional Postgres instances, optional OpenTelemetry Collector, and a load generator. Designed for rapid deployment to Rancher-managed clusters and integration with Groundcover.

## Features
- Two Spring Boot microservices (orders, inventory) with independent Postgres DBs.
- Optional in-chart OpenTelemetry Collector (forwarding to Groundcover).
- Configurable direct OTLP export mode (bypass collector).
- Optional Java agent toggle per all services (adds more automatic instrumentation if needed).
- Lightweight load generator (curl loop) to produce traffic.
- Resource requests/limits configurable.

## Values Overview
Key values (see `values.yaml` for full list):

| Path | Description | Default |
|------|-------------|---------|
| global.namespace | Target namespace | observability-demo |
| global.image.registry | Image registry | your-reg |
| global.image.tag | Image tag for both services | 1.0.0 |
| global.otlp.mode | `collector` or `direct` | collector |
| global.otlp.endpoint | Explicit OTLP endpoint (overrides mode) | "" |
| global.javaAgent.enabled | Enable OpenTelemetry Java agent | false |
| ordersService.replicaCount | Orders replicas | 2 |
| inventoryService.replicaCount | Inventory replicas | 2 |
| collector.enabled | Deploy in-chart collector (ignored if mode=direct) | true |
| loadGenerator.enabled | Deploy traffic generator | true |

## Deploy
```bash
helm install demo ./helm/groundcover-observability-demo \
  --set global.image.registry=myrepo \
  --set global.image.tag=1.0.0
```

## Direct Export to Groundcover
Skip the collector:
```bash
helm install demo ./helm/groundcover-observability-demo \
  --set global.image.registry=myrepo \
  --set global.image.tag=1.0.0 \
  --set global.otlp.mode=direct
```
Or specify a custom endpoint:
```bash
--set global.otlp.endpoint=http://groundcover-opentelemetry-collector:4317
```

## Enable Java Agent
```bash
helm upgrade demo ./helm/groundcover-observability-demo \
  --set global.javaAgent.enabled=true
```

## Disable Load Generator
```bash
helm install demo ./helm/groundcover-observability-demo \
  --set loadGenerator.enabled=false
```

## Customize Resources
Example overriding Orders limits:
```bash
helm upgrade demo ./helm/groundcover-observability-demo \
  --set ordersService.resources.requests.cpu=200m \
  --set ordersService.resources.limits.cpu=1
```

## Uninstall
```bash
helm uninstall demo
# (Optionally) kubectl delete namespace observability-demo
```

## Notes
- If using Rancher UI, you can package this chart (`helm package`) and upload to a catalog or use a Git repo as a catalog source.
- Ensure images exist in the specified registry; chart does not build or push them.
- Set `global.otlp.resourceAttributes` to attach additional OTEL resource attributes.

