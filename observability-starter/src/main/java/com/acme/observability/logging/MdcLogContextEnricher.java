package com.acme.observability.logging;

import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanContext;
import org.slf4j.MDC;

public final class MdcLogContextEnricher {
    private MdcLogContextEnricher() {}

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

    public static void populateFromCurrent() {
        populateMdc(Span.current());
    }

    public static void clear() {
        MDC.remove("trace_id");
        MDC.remove("span_id");
        MDC.remove("traceId");
        MDC.remove("spanId");
    }
}

