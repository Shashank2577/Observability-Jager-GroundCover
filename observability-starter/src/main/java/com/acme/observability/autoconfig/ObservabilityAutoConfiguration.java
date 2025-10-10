package com.acme.observability.autoconfig;

import com.acme.observability.config.ObservabilityProperties;
import com.acme.observability.exporter.SimpleLoggingSpanExporter;
// import com.acme.observability.logging.OtlpLogbackAppender; // Disabled - using official appender
import com.acme.observability.logging.OtlpLoggingConfiguration;
import com.acme.observability.web.BaggageFilter;
import com.acme.observability.web.RequestTracingInterceptor;
import io.opentelemetry.api.OpenTelemetry;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.logs.LoggerProvider;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator;
import io.opentelemetry.context.Context;
import io.opentelemetry.context.Scope;
import io.opentelemetry.context.propagation.ContextPropagators;
import io.opentelemetry.exporter.otlp.trace.OtlpGrpcSpanExporter;
import io.opentelemetry.exporter.otlp.logs.OtlpGrpcLogRecordExporter;
import io.opentelemetry.sdk.logs.SdkLoggerProvider;
import io.opentelemetry.sdk.logs.export.BatchLogRecordProcessor;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.resources.Resource;
import io.opentelemetry.sdk.trace.SdkTracerProvider;
import io.opentelemetry.sdk.trace.SdkTracerProviderBuilder;
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor;
import io.opentelemetry.sdk.trace.samplers.Sampler;
import jakarta.servlet.Filter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.lang.NonNull;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@AutoConfiguration
@EnableConfigurationProperties(ObservabilityProperties.class)
@ConditionalOnProperty(prefix = "observability", name = "enabled", havingValue = "true", matchIfMissing = true)
public class ObservabilityAutoConfiguration {

    private static final Logger log = LoggerFactory.getLogger(ObservabilityAutoConfiguration.class);

    @Bean
    @ConditionalOnMissingBean
    public OpenTelemetry openTelemetry(ObservabilityProperties props) {
        Resource resource = Resource.getDefault().merge(Resource.create(Attributes.builder()
                .put("service.name", props.getServiceName())
                .put("service.namespace", props.getServiceNamespace())
                .put("deployment.environment", "groundcover-demo")
                .put("service.version", "1.11.0-groundcover")
                .put("service.instance.id", System.getProperty("user.name", "unknown"))
                .build()));
        SdkTracerProviderBuilder tpBuilder = SdkTracerProvider.builder()
                .setResource(resource)
                .setSampler(Sampler.traceIdRatioBased(props.getSamplingProbability()));

        if ("otlp".equalsIgnoreCase(props.getExporter())) {
            log.info("Configuring OTLP exporter at {}", props.getOtlpEndpoint());
            OtlpGrpcSpanExporter exporter = OtlpGrpcSpanExporter.builder()
                    .setEndpoint(props.getOtlpEndpoint())
                    .build();
            tpBuilder.addSpanProcessor(BatchSpanProcessor.builder(exporter).build());
        } else {
            log.info("Configuring simple logging span exporter (fallback mode)");
            tpBuilder.addSpanProcessor(BatchSpanProcessor.builder(new SimpleLoggingSpanExporter()).build());
        }

        SdkTracerProvider provider = tpBuilder.build();
        OpenTelemetrySdk sdk = OpenTelemetrySdk.builder()
                .setTracerProvider(provider)
                .setPropagators(ContextPropagators.create(W3CTraceContextPropagator.getInstance()))
                .buildAndRegisterGlobal();
        return sdk;
    }

    @Bean
    @Order(Ordered.HIGHEST_PRECEDENCE + 10)
    public Filter baggageFilter() {
        return new BaggageFilter();
    }

    @Bean
    public RequestTracingInterceptor requestTracingInterceptor() { return new RequestTracingInterceptor(); }

    @Bean
    public WebMvcConfigurer tracingWebMvcConfigurer(RequestTracingInterceptor interceptor) {
        return new WebMvcConfigurer() {
            @Override
            public void addInterceptors(@NonNull InterceptorRegistry registry) {
                registry.addInterceptor(interceptor);
            }
        };
    }

    @Bean
    @ConditionalOnProperty(name = "observability.enabled", havingValue = "true", matchIfMissing = true)
    public LoggerProvider loggerProvider(ObservabilityProperties props) {
        if ("otlp".equalsIgnoreCase(props.getExporter())) {
            // Create OTLP log exporter using the dedicated logs endpoint
            String logsEndpoint = props.getOtlpLogsEndpoint() != null ? props.getOtlpLogsEndpoint() : props.getOtlpEndpoint();
            OtlpGrpcLogRecordExporter logExporter = OtlpGrpcLogRecordExporter.builder()
                    .setEndpoint(logsEndpoint)
                    .build();
            
            // Create resource with service information
            Resource resource = Resource.getDefault()
                    .merge(Resource.builder()
                            .put("service.name", props.getServiceName())
                            .put("service.namespace", props.getServiceNamespace())
                            .put("deployment.environment", "groundcover-demo")
                            .put("service.version", "1.11.0-groundcover")
                            .build());
            
            // Create logger provider with OTLP exporter
            return SdkLoggerProvider.builder()
                    .setResource(resource)
                    .addLogRecordProcessor(BatchLogRecordProcessor.builder(logExporter).build())
                    .build();
        }
        return null;
    }

    @Bean
    @ConditionalOnMissingBean
    public RestTemplate restTemplate(ObjectProvider<OpenTelemetry> otelProvider) {
        RestTemplate rt = new RestTemplate();
        rt.getInterceptors().add((request, body, execution) -> {
            var otel = otelProvider.getIfAvailable();
            if (otel != null) {
                var tracer = otel.getTracer("com.acme.observability");
                var propagator = otel.getPropagators().getTextMapPropagator();
                
                // Create client span for outbound HTTP call
                String spanName = "HTTP " + request.getMethod() + " " + request.getURI().getHost();
                Span clientSpan = tracer.spanBuilder(spanName)
                        .setSpanKind(io.opentelemetry.api.trace.SpanKind.CLIENT)
                        .startSpan();
                
                try (Scope scope = clientSpan.makeCurrent()) {
                    // Inject trace context into headers
                    propagator.inject(Context.current(), request.getHeaders(), (headers, key, value) -> headers.add(key, value));
                    
                    // Add HTTP attributes
                    clientSpan.setAttribute("http.method", request.getMethod().toString());
                    clientSpan.setAttribute("http.url", request.getURI().toString());
                    clientSpan.setAttribute("http.scheme", request.getURI().getScheme());
                    clientSpan.setAttribute("http.host", request.getURI().getHost());
                    clientSpan.setAttribute("http.target", request.getURI().getPath());
                    
                    // GroundCover-specific attributes
                    clientSpan.setAttribute("service.namespace", "shash.demo");
                    clientSpan.setAttribute("deployment.environment", "groundcover-demo");
                    clientSpan.setAttribute("service.version", "1.11.0-groundcover");
                    clientSpan.setAttribute("service.instance.id", System.getProperty("user.name", "unknown"));
                    
                    // Add trace correlation attributes for GroundCover
                    io.opentelemetry.api.trace.SpanContext spanContext = clientSpan.getSpanContext();
                    clientSpan.setAttribute("trace.trace_id", spanContext.getTraceId());
                    clientSpan.setAttribute("trace.span_id", spanContext.getSpanId());
                    
                    return execution.execute(request, body);
                } catch (Exception e) {
                    clientSpan.recordException(e);
                    clientSpan.setStatus(io.opentelemetry.api.trace.StatusCode.ERROR);
                    throw e;
                } finally {
                    clientSpan.end();
                }
            }
            return execution.execute(request, body);
        });
        return rt;
    }
}
