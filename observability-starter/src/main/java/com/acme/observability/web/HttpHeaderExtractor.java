package com.acme.observability.web;

import io.opentelemetry.context.propagation.TextMapGetter;
import jakarta.servlet.http.HttpServletRequest;

import java.util.Collections;

/**
 * Extracts trace context from HTTP request headers for distributed tracing.
 */
public class HttpHeaderExtractor implements TextMapGetter<HttpServletRequest> {
    
    @Override
    public String get(HttpServletRequest carrier, String key) {
        return carrier.getHeader(key);
    }
    
    @Override
    public Iterable<String> keys(HttpServletRequest carrier) {
        return Collections.list(carrier.getHeaderNames());
    }
}
