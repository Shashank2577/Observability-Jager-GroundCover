package com.acme.observability.web;

import io.opentelemetry.api.baggage.Baggage;
import io.opentelemetry.api.baggage.BaggageBuilder;
import io.opentelemetry.context.Scope;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

/**
 * Reads select headers once per request and makes them baggage.
 */
public class BaggageFilter extends HttpFilter {

    private static final List<String> HEADER_KEYS = List.of("x-user", "x-tenant", "x-request-id");

    @Override
    protected void doFilter(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        BaggageBuilder builder = Baggage.current().toBuilder();
        HEADER_KEYS.forEach(h -> {
            String v = request.getHeader(h);
            if (v != null && !v.isBlank()) {
                String key = h.replace('-', '.'); // normalize
                builder.put(key, v);
            }
        });
        Baggage baggage = builder.build();
        try (Scope ignored = baggage.makeCurrent()) {
            chain.doFilter(request, response);
        }
    }
}

