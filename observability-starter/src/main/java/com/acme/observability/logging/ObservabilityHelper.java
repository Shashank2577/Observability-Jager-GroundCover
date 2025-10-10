package com.acme.observability.logging;

import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanContext;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Scope;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Map;
import java.util.function.Supplier;

public final class ObservabilityHelper {
    private static final Tracer tracer = GlobalOpenTelemetry.getTracer("com.acme.observability");
    private static final Logger logger = LoggerFactory.getLogger(ObservabilityHelper.class);

    private ObservabilityHelper() {}

    public static <T> T withSpan(String name, Supplier<T> supplier) {
        Span span = tracer.spanBuilder(name).startSpan();
        try (Scope scope = span.makeCurrent()) {
            MdcLogContextEnricher.populateMdc(span);
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

    public static void withSpan(String name, Runnable runnable) {
        withSpan(name, () -> { runnable.run(); return null; });
    }

    public static void logInfo(String msg, Object... args) {
        MdcLogContextEnricher.populateFromCurrent();
        logger.info(msg, args);
    }

    public static void logError(String msg, Throwable t, Object... args) {
        MdcLogContextEnricher.populateFromCurrent();
        logger.error(msg, t, args);
    }

    public static void logWithAttributes(String message, Map<String, Object> attributes) {
        Span currentSpan = Span.current();
        if (currentSpan != null && currentSpan.getSpanContext().isValid()) {
            // Add GroundCover-specific attributes
            currentSpan.setAttribute("service.namespace", "shash.demo");
            currentSpan.setAttribute("deployment.environment", "groundcover-demo");
            currentSpan.setAttribute("service.version", "1.4.0-groundcover");
            currentSpan.setAttribute("service.instance.id", System.getProperty("user.name", "unknown"));
            
            // Add trace correlation attributes for GroundCover
            SpanContext spanContext = currentSpan.getSpanContext();
            currentSpan.setAttribute("trace.trace_id", spanContext.getTraceId());
            currentSpan.setAttribute("trace.span_id", spanContext.getSpanId());
            
            // Add custom attributes
            attributes.forEach((k,v) -> currentSpan.setAttribute(k, String.valueOf(v)));
        }
        MdcLogContextEnricher.populateFromCurrent();
        logger.info(message + " | attrs={}", attributes);
    }
}

