package com.acme.observability.web;

import com.acme.observability.logging.MdcLogContextEnricher;
import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.api.trace.StatusCode;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Context;
import io.opentelemetry.context.Scope;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.lang.NonNull;
import org.springframework.lang.Nullable;
import org.springframework.web.servlet.HandlerInterceptor;

/**
 * Creates a SERVER span per incoming HTTP request when no existing span is current.
 */
public class RequestTracingInterceptor implements HandlerInterceptor {

    // Do not initialize a Tracer at class-load time (avoids calling GlobalOpenTelemetry.get during static init)
    private static final String SPAN_KEY = RequestTracingInterceptor.class.getName() + ".span";
    private static final String SCOPE_KEY = RequestTracingInterceptor.class.getName() + ".scope";

    private Tracer tracer() {
        return GlobalOpenTelemetry.getTracer("com.acme.observability");
    }

    @Override
    public boolean preHandle(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response, @NonNull Object handler) {
        // If an upstream agent already created one, don't duplicate.
        Span parent = Span.current();
        if (parent != null && parent.getSpanContext().isValid()) {
            return true;
        }
        
        String spanName = request.getMethod() + " " + request.getRequestURI();
        
        // Extract trace context from incoming headers
        var propagator = GlobalOpenTelemetry.getPropagators().getTextMapPropagator();
        Context extractedContext = propagator.extract(Context.current(), request, new HttpHeaderExtractor());
        
        // Create span as child of extracted context (or root if no context found)
        Span span = tracer().spanBuilder(spanName)
                .setParent(extractedContext)
                .setSpanKind(SpanKind.SERVER)
                .startSpan();
                
        Scope scope = span.makeCurrent();
        request.setAttribute(SPAN_KEY, span);
        request.setAttribute(SCOPE_KEY, scope);
        MdcLogContextEnricher.populateMdc(span);
        
        // Standard HTTP attributes
        span.setAttribute("http.method", request.getMethod());
        span.setAttribute("http.route", request.getRequestURI());
        span.setAttribute("http.url", request.getRequestURL().toString());
        span.setAttribute("http.user_agent", request.getHeader("User-Agent"));
        span.setAttribute("http.scheme", request.getScheme());
        span.setAttribute("http.host", request.getServerName());
        span.setAttribute("http.target", request.getRequestURI());
        
        // GroundCover-specific attributes
        span.setAttribute("service.namespace", "shash.demo");
        span.setAttribute("deployment.environment", "groundcover-demo");
        span.setAttribute("service.version", "1.0.0");
        span.setAttribute("service.instance.id", System.getProperty("user.name", "unknown"));
        
        return true;
    }

    @Override
    public void afterCompletion(@NonNull HttpServletRequest request, @NonNull HttpServletResponse response, @NonNull Object handler, @Nullable Exception ex) {
        Object spanObj = request.getAttribute(SPAN_KEY);
        Object scopeObj = request.getAttribute(SCOPE_KEY);
        if (spanObj instanceof Span span && scopeObj instanceof Scope scope) {
            try {
                span.setAttribute("http.status_code", response.getStatus());
                if (ex != null) {
                    span.recordException(ex);
                    span.setStatus(StatusCode.ERROR);
                } else if (response.getStatus() >= 500) {
                    span.setStatus(StatusCode.ERROR);
                }
            } finally {
                span.end();
                scope.close();
                MdcLogContextEnricher.clear();
            }
        }
    }
}
