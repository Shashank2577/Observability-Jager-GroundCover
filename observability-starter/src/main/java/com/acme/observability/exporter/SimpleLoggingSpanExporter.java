package com.acme.observability.exporter;

import io.opentelemetry.sdk.common.CompletableResultCode;
import io.opentelemetry.sdk.trace.data.SpanData;
import io.opentelemetry.sdk.trace.export.SpanExporter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Collection;

/**
 * Minimal logging span exporter to avoid pulling extra OTel exporter artifacts.
 * Not for production use (no batching / backpressure). Just emits basic span info.
 */
public class SimpleLoggingSpanExporter implements SpanExporter {

    private static final Logger log = LoggerFactory.getLogger(SimpleLoggingSpanExporter.class);

    @Override
    public CompletableResultCode export(Collection<SpanData> spans) {
        try {
            for (SpanData sd : spans) {
                log.info("[otel-span] traceId={} spanId={} parentSpanId={} name={} kind={} status={} durationMs={} attributes={}",
                        sd.getTraceId(),
                        sd.getSpanId(),
                        sd.getParentSpanId(),
                        sd.getName(),
                        sd.getKind(),
                        sd.getStatus(),
                        (sd.getEndEpochNanos() - sd.getStartEpochNanos()) / 1_000_000.0,
                        sd.getAttributes());
            }
            return CompletableResultCode.ofSuccess();
        } catch (Exception e) {
            log.warn("Failed to log spans", e);
            return CompletableResultCode.ofFailure();
        }
    }

    @Override
    public CompletableResultCode flush() { return CompletableResultCode.ofSuccess(); }

    @Override
    public CompletableResultCode shutdown() { return CompletableResultCode.ofSuccess(); }
}

