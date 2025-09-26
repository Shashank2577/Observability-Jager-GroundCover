package com.acme.observability.aop;

import com.acme.observability.annotation.OtelSpan;
import com.acme.observability.logging.MdcLogContextEnricher;
import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.Tracer;
import io.opentelemetry.context.Scope;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.lang.reflect.Method;

@Aspect
@Component
public class OtelSpanAspect {
    private static final Logger log = LoggerFactory.getLogger(OtelSpanAspect.class);

    @Around("@annotation(com.acme.observability.annotation.OtelSpan)")
    public Object aroundAnnotated(ProceedingJoinPoint pjp) throws Throwable {
        MethodSignature sig = (MethodSignature) pjp.getSignature();
        Method method = sig.getMethod();
        OtelSpan ann = method.getAnnotation(OtelSpan.class);
        String defaultName = pjp.getTarget().getClass().getSimpleName() + "." + method.getName();
        String spanName = (ann != null && !ann.value().isEmpty()) ? ann.value() : defaultName;

        // Obtain the tracer at the time the advice is executed (lazy), so the
        // OpenTelemetry SDK has been initialized and registered globally.
        Tracer tracer = GlobalOpenTelemetry.getTracer("com.acme.observability");
        Span span = tracer.spanBuilder(spanName).startSpan();
        try (Scope scope = span.makeCurrent()) {
            MdcLogContextEnricher.populateMdc(span);
            return pjp.proceed();
        } catch (Throwable t) {
            span.recordException(t);
            span.setAttribute("error", true);
            log.error("Exception in span {}", spanName, t);
            throw t;
        } finally {
            span.end();
            MdcLogContextEnricher.clear();
        }
    }
}
