# Observability Helper: Distributed Tracing & Logging Solution

## Executive Summary

Custom Spring Boot starter providing distributed tracing and structured logging for microservices. Seamlessly integrates with GroundCover's observability platform for end-to-end request tracing and log-trace correlation.

## Key Capabilities

- **Automatic HTTP Request Tracing**: Zero-config tracing for all incoming/outgoing HTTP calls
- **Log-Trace Correlation**: Automatic enrichment of logs with trace IDs for GroundCover compatibility
- **Cross-Service Propagation**: W3C Trace Context propagation across service boundaries
- **Enterprise Configuration**: OTLP export, configurable sampling, service metadata

## Core Implementation

### 1. ObservabilityHelper - Main Utility Class

```java
public final class ObservabilityHelper {
    public static <T> T withSpan(String name, Supplier<T> supplier) {
        Span span = tracer.spanBuilder(name).startSpan();
        try (Scope scope = span.makeCurrent()) {
            MdcLogContextEnricher.populateMdc(span);  // Enrich logs with trace context
            return supplier.get();
        } catch (Throwable t) {
            span.recordException(t);
            span.setAttribute("error", true);
            throw t;
        } finally {
            span.end();
            MdcLogContextEnricher.clear();
        }
    }
    
    public static void logWithAttributes(String message, Map<String, Object> attributes) {
        Span currentSpan = Span.current();
        if (currentSpan != null && currentSpan.getSpanContext().isValid()) {
            // Add GroundCover-specific attributes
            currentSpan.setAttribute("service.namespace", "shash.demo");
            currentSpan.setAttribute("trace.trace_id", spanContext.getTraceId());
            currentSpan.setAttribute("trace.span_id", spanContext.getSpanId());
            attributes.forEach((k,v) -> currentSpan.setAttribute(k, String.valueOf(v)));
        }
        logger.info(message + " | attrs={}", attributes);
    }
}
```

### 2. RequestTracingInterceptor - HTTP Request Instrumentation

```java
@Override
public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
    // Extract trace context from incoming headers
    var propagator = GlobalOpenTelemetry.getPropagators().getTextMapPropagator();
    Context extractedContext = propagator.extract(Context.current(), request, new HttpHeaderExtractor());
    
    // Create span as child of extracted context
    Span span = tracer().spanBuilder(spanName)
            .setParent(extractedContext)
            .setSpanKind(SpanKind.SERVER)
            .startSpan();
            
    // Add GroundCover-specific attributes
    span.setAttribute("service.namespace", "shash.demo");
    span.setAttribute("trace.trace_id", spanContext.getTraceId());
    span.setAttribute("trace.span_id", spanContext.getSpanId());
    
    MdcLogContextEnricher.populateMdc(span);  // Enable log correlation
    return true;
}
```

### 3. MdcLogContextEnricher - Log-Trace Correlation

```java
public static void populateMdc(Span span) {
    if (span == null) return;
    SpanContext ctx = span.getSpanContext();
    if (ctx != null && ctx.isValid()) {
        // Use trace_id field name that GroundCover recognizes
        MDC.put("trace_id", ctx.getTraceId());
        MDC.put("span_id", ctx.getSpanId());
        // Keep legacy fields for backward compatibility
        MDC.put("traceId", ctx.getTraceId());
        MDC.put("spanId", ctx.getSpanId());
    }
}
```

## GroundCover-Specific Optimizations

### 1. **Log-Trace Correlation Fields**
- Uses `trace_id` and `span_id` field names that GroundCover recognizes
- Maintains backward compatibility with legacy `traceId`/`spanId` fields
- Automatic MDC population for seamless correlation

### 2. **Service Metadata Enrichment**
```java
// GroundCover-specific attributes added to all spans
span.setAttribute("service.namespace", "shash.demo");
span.setAttribute("deployment.environment", "groundcover-demo");
span.setAttribute("service.version", "1.0.0");
span.setAttribute("service.instance.id", System.getProperty("user.name", "unknown"));

// Trace correlation attributes for GroundCover
span.setAttribute("trace.trace_id", spanContext.getTraceId());
span.setAttribute("trace.span_id", spanContext.getSpanId());
```

### 3. **OTLP Integration**
- Native OTLP protocol support for GroundCover ingestion
- Automatic RestTemplate instrumentation for outbound calls
- Configurable sampling and error handling

### 4. **Auto-Configuration**
```java
@Bean
public OpenTelemetry openTelemetry(ObservabilityProperties props) {
    if ("otlp".equalsIgnoreCase(props.getExporter())) {
        OtlpGrpcSpanExporter exporter = OtlpGrpcSpanExporter.builder()
                .setEndpoint(props.getOtlpEndpoint())
                .build();
        tpBuilder.addSpanProcessor(BatchSpanProcessor.builder(exporter).build());
    }
    // GroundCover resource attributes
    Resource resource = Resource.getDefault().merge(Resource.create(Attributes.builder()
            .put("service.namespace", "shash.demo")
            .put("deployment.environment", "groundcover-demo")
            .build()));
}
```

## Usage Examples

### Zero-Config HTTP Tracing
```java
// Automatic tracing - no code required
@RestController
public class OrderController {
    @GetMapping("/orders/{id}")
    public Order getOrder(@PathVariable String id) {
        // Request automatically traced with GroundCover attributes
        return orderService.findById(id);
    }
}
```

### Manual Span Creation
```java
// Manual span with GroundCover correlation
ObservabilityHelper.withSpan("process-payment", () -> {
    ObservabilityHelper.logInfo("Processing payment for order {}", orderId);
    // Business logic here
});
```

### Structured Logging
```java
Map<String, Object> attributes = Map.of("orderId", orderId, "amount", amount);
ObservabilityHelper.logWithAttributes("Order processed", attributes);
// Logs automatically enriched with trace_id, span_id for GroundCover correlation
```

## Configuration

```yaml
observability:
  enabled: true
  service-name: inventory-service
  sampling-probability: 1.0
  exporter: otlp
  otlp-endpoint: http://otel-collector:4317
```

## Business Value

- **Zero Configuration**: Automatic instrumentation with minimal code changes
- **GroundCover Native**: Optimized for GroundCover's log-trace correlation
- **Production Ready**: Configurable sampling, error handling, OTLP export
- **Developer Productivity**: Consistent observability patterns across all services
- **Operational Excellence**: End-to-end visibility, faster issue resolution
