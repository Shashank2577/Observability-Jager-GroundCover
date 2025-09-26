# 🔧 Fixing Groundcover Trace Correlation

## Problem Statement
While Jaeger shows properly linked distributed traces, Groundcover is not correlating spans to traces. This document outlines the detailed steps needed to fix trace correlation in Groundcover.

## Root Cause Analysis

### Current State
- ✅ **Jaeger**: Shows complete distributed traces with 7 spans per request
- ✅ **Trace Context Propagation**: Working between services
- ❌ **Groundcover**: Spans are not linked to traces

### Why Groundcover Fails
1. **Missing Trace Context in Spans**: Groundcover needs explicit trace context attributes
2. **Incomplete Span Metadata**: Missing parent-child relationships
3. **Service Name Attribution**: Spans may not have proper service names
4. **OTLP Export Configuration**: May need specific OTLP settings for Groundcover

## Required Fixes

### 1. Enhanced Span Attributes for Groundcover

#### A. Add Groundcover-Specific Attributes
```java
// In RequestTracingInterceptor.java
span.setAttribute("trace.parent_id", parentSpanId);
span.setAttribute("trace.trace_id", traceId);
span.setAttribute("service.name", serviceName);
span.setAttribute("service.version", serviceVersion);
span.setAttribute("deployment.environment", environment);
```

#### B. Ensure Proper Parent-Child Relationships
```java
// In RequestTracingInterceptor.java
if (parentSpan != null && parentSpan.getSpanContext().isValid()) {
    span.setAttribute("trace.parent_id", parentSpan.getSpanContext().getSpanId());
    span.setAttribute("trace.trace_id", parentSpan.getSpanContext().getTraceId());
}
```

### 2. Service Name Attribution

#### A. Update Resource Attributes
```java
// In ObservabilityAutoConfiguration.java
Resource resource = Resource.getDefault().merge(Resource.create(Attributes.builder()
    .put("service.name", props.getServiceName())
    .put("service.version", props.getServiceVersion())
    .put("deployment.environment", props.getEnvironment())
    .put("service.instance.id", InetAddress.getLocalHost().getHostName())
    .build()));
```

#### B. Add Service Name to Each Span
```java
// In RequestTracingInterceptor.java
span.setAttribute("service.name", props.getServiceName());
span.setAttribute("service.version", props.getServiceVersion());
```

### 3. OTLP Export Configuration for Groundcover

#### A. Update OpenTelemetry Collector Config
```yaml
# otel-collector-config.yaml
exporters:
  otlp/groundcover:
    endpoint: "https://api.groundcover.com/v1/otlp"
    headers:
      authorization: "Bearer YOUR_GROUNDCOVER_TOKEN"
    tls:
      insecure: false
    retry_on_failure:
      enabled: true
      initial_interval: 1s
      max_interval: 5s
      max_elapsed_time: 30s

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging, jaeger, otlp/groundcover]
```

#### B. Add Groundcover-Specific Headers
```java
// In ObservabilityAutoConfiguration.java
OtlpGrpcSpanExporter groundcoverExporter = OtlpGrpcSpanExporter.builder()
    .setEndpoint("https://api.groundcover.com/v1/otlp")
    .addHeader("Authorization", "Bearer " + props.getGroundcoverToken())
    .addHeader("Content-Type", "application/x-protobuf")
    .build();
```

### 4. Enhanced Trace Context Propagation

#### A. Add Baggage Support
```java
// In RequestTracingInterceptor.java
// Extract baggage from headers
var baggage = GlobalOpenTelemetry.getBaggageManager().baggageBuilder()
    .put("user.id", request.getHeader("X-User-ID"))
    .put("request.id", request.getHeader("X-Request-ID"))
    .build();
```

#### B. Add Custom Attributes
```java
// In RequestTracingInterceptor.java
span.setAttribute("http.user_agent", request.getHeader("User-Agent"));
span.setAttribute("http.client_ip", getClientIP(request));
span.setAttribute("http.request_id", request.getHeader("X-Request-ID"));
span.setAttribute("http.user_id", request.getHeader("X-User-ID"));
```

### 5. Groundcover-Specific Configuration

#### A. Add Groundcover Properties
```yaml
# application.yml
observability:
  enabled: true
  service-name: ${SERVICE_NAME:inventory-service}
  service-version: ${SERVICE_VERSION:1.1.0}
  environment: ${ENVIRONMENT:production}
  groundcover:
    enabled: true
    endpoint: ${GROUNDCOVER_ENDPOINT:https://api.groundcover.com/v1/otlp}
    token: ${GROUNDCOVER_TOKEN:}
    project-id: ${GROUNDCOVER_PROJECT_ID:}
```

#### B. Update ObservabilityProperties
```java
// In ObservabilityProperties.java
@ConfigurationProperties(prefix = "observability")
public class ObservabilityProperties {
    private String serviceName = "unknown-service";
    private String serviceVersion = "1.0.0";
    private String environment = "development";
    private GroundcoverProperties groundcover = new GroundcoverProperties();
    
    // Getters and setters...
    
    public static class GroundcoverProperties {
        private boolean enabled = false;
        private String endpoint;
        private String token;
        private String projectId;
        
        // Getters and setters...
    }
}
```

### 6. Client Span Enhancement

#### A. Add Parent Context to Client Spans
```java
// In ObservabilityAutoConfiguration.java (RestTemplate interceptor)
Span clientSpan = tracer.spanBuilder(spanName)
    .setParent(Context.current()) // Ensure parent context
    .setSpanKind(SpanKind.CLIENT)
    .startSpan();

// Add parent span ID
if (Span.current().getSpanContext().isValid()) {
    clientSpan.setAttribute("trace.parent_id", Span.current().getSpanContext().getSpanId());
}
```

#### B. Add Service-to-Service Attributes
```java
// In RestTemplate interceptor
clientSpan.setAttribute("rpc.service", targetService);
clientSpan.setAttribute("rpc.method", request.getMethod().toString());
clientSpan.setAttribute("rpc.system", "http");
```

## Implementation Steps

### Step 1: Update Observability Starter
1. Add Groundcover-specific attributes to `RequestTracingInterceptor`
2. Enhance `ObservabilityAutoConfiguration` with Groundcover exporter
3. Add service name attribution to all spans
4. Update `ObservabilityProperties` with Groundcover configuration

### Step 2: Update Application Configuration
1. Add Groundcover environment variables to deployments
2. Update `application.yml` with Groundcover settings
3. Configure OTLP endpoint for Groundcover

### Step 3: Update OpenTelemetry Collector
1. Add Groundcover OTLP exporter to collector config
2. Configure authentication headers
3. Update service pipeline to include Groundcover

### Step 4: Deploy and Test
1. Build new Docker images with Groundcover support
2. Deploy to Rancher cluster
3. Generate test traffic
4. Verify traces appear in Groundcover with proper correlation

## Environment Variables Needed

```bash
# For each service deployment
SERVICE_NAME=inventory-service
SERVICE_VERSION=1.1.0
ENVIRONMENT=production
GROUNDCOVER_ENDPOINT=https://api.groundcover.com/v1/otlp
GROUNDCOVER_TOKEN=your_groundcover_token
GROUNDCOVER_PROJECT_ID=your_project_id
```

## Testing Strategy

### 1. Local Testing
```bash
# Test with local Groundcover endpoint
curl -X POST "http://localhost:8081/orders?sku=BETA&qty=1"
# Check Groundcover UI for trace correlation
```

### 2. Cloud Testing
```bash
# Generate traffic on Rancher cluster
curl -X POST "http://localhost:8081/orders?sku=BETA&qty=1"
# Verify in Groundcover dashboard
```

## Rollback Plan

If Groundcover integration causes issues:

1. **Revert Images**: Use previous Docker images without Groundcover
2. **Update Collector**: Remove Groundcover exporter from OTLP collector
3. **Environment Variables**: Remove Groundcover-specific env vars

## Expected Results

After implementation:
- ✅ Groundcover shows complete distributed traces
- ✅ Spans are properly linked with parent-child relationships
- ✅ Service names are correctly attributed
- ✅ Trace context flows through all services
- ✅ Both Jaeger and Groundcover show identical trace structures

## Monitoring and Validation

### Key Metrics to Check
1. **Trace Correlation Rate**: % of spans properly linked
2. **Service Attribution**: All spans have correct service names
3. **Parent-Child Relationships**: Proper span hierarchy
4. **Error Rate**: No increase in application errors

### Groundcover Dashboard Checks
1. **Service Map**: Shows connections between services
2. **Trace Timeline**: Complete request flow visualization
3. **Span Details**: Proper attributes and metadata
4. **Error Tracking**: Failed requests properly attributed

This comprehensive approach should resolve the Groundcover trace correlation issues while maintaining compatibility with Jaeger.

