package com.acme.observability.logging;

import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.AppenderBase;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.common.AttributesBuilder;
import io.opentelemetry.api.logs.LogRecordBuilder;
import io.opentelemetry.api.logs.Logger;
import io.opentelemetry.api.logs.LoggerProvider;
import io.opentelemetry.context.Context;
import org.slf4j.MDC;

import java.time.Instant;

public class OtlpLogbackAppender extends AppenderBase<ILoggingEvent> {
    
    private LoggerProvider loggerProvider;
    private String serviceName = "unknown-service";
    
    public void setLoggerProvider(LoggerProvider loggerProvider) {
        this.loggerProvider = loggerProvider;
    }
    
    public void setServiceName(String serviceName) {
        this.serviceName = serviceName;
    }

    @Override
    protected void append(ILoggingEvent event) {
        if (loggerProvider == null) {
            return;
        }
        
        try {
            Logger logger = loggerProvider.get("com.acme.observability");
            
            // Build all attributes
            AttributesBuilder attributesBuilder = Attributes.builder()
                    .put("service.name", serviceName)
                    .put("service.namespace", "shash.demo")
                    .put("deployment.environment", "groundcover-demo")
                    .put("service.version", "1.0.0")
                    .put("service.instance.id", System.getProperty("user.name", "unknown"))
                    .put("logger.name", event.getLoggerName())
                    .put("thread.name", event.getThreadName())
                    .put("log.level", event.getLevel().toString())
                    .put("log.message", event.getFormattedMessage());
            
            // Add trace correlation if available
            String traceId = MDC.get("trace_id");
            String spanId = MDC.get("span_id");
            
            if (traceId != null && !traceId.isEmpty()) {
                attributesBuilder.put("trace_id", traceId);
                if (spanId != null && !spanId.isEmpty()) {
                    attributesBuilder.put("span_id", spanId);
                }
            }
            
            // Add exception if present
            if (event.getThrowableProxy() != null) {
                attributesBuilder.put("exception.type", event.getThrowableProxy().getClassName());
                attributesBuilder.put("exception.message", event.getThrowableProxy().getMessage());
                attributesBuilder.put("exception.stacktrace", getStackTrace(event.getThrowableProxy()));
            }
            
            LogRecordBuilder logRecordBuilder = logger.logRecordBuilder()
                    .setTimestamp(Instant.ofEpochMilli(event.getTimeStamp()))
                    .setSeverityText(event.getLevel().toString())
                    .setSeverity(io.opentelemetry.api.logs.Severity.values()[mapSeverity(event.getLevel().toInt())])
                    .setBody(event.getFormattedMessage())
                    .setAllAttributes(attributesBuilder.build());
            
            logRecordBuilder.emit();
            
        } catch (Exception e) {
            // Fallback to console if OTLP fails
            System.err.println("Failed to send log via OTLP: " + e.getMessage());
        }
    }
    
    private int mapSeverity(int logbackLevel) {
        // Map logback levels to OpenTelemetry Severity enum index
        switch (logbackLevel) {
            case 50000: // ERROR
                return 21; // ERROR
            case 40000: // WARN
                return 17; // WARN
            case 30000: // INFO
                return 13; // INFO
            case 20000: // DEBUG
                return 5; // DEBUG
            case 10000: // TRACE
                return 1; // TRACE
            default:
                return 13; // INFO
        }
    }
    
    private String getStackTrace(ch.qos.logback.classic.spi.IThrowableProxy throwable) {
        if (throwable == null) return "";
        
        StringBuilder sb = new StringBuilder();
        sb.append(throwable.getClassName()).append(": ").append(throwable.getMessage()).append("\n");
        
        for (ch.qos.logback.classic.spi.StackTraceElementProxy element : throwable.getStackTraceElementProxyArray()) {
            sb.append("\tat ").append(element.toString()).append("\n");
        }
        
        return sb.toString();
    }
}
