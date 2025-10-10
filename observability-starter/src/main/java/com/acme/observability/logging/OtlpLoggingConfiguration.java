package com.acme.observability.logging;

import com.acme.observability.config.ObservabilityProperties;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.exporter.otlp.logs.OtlpGrpcLogRecordExporter;
import io.opentelemetry.sdk.OpenTelemetrySdk;
import io.opentelemetry.sdk.logs.LogRecordProcessor;
import io.opentelemetry.sdk.logs.SdkLoggerProvider;
import io.opentelemetry.sdk.logs.export.BatchLogRecordProcessor;
import io.opentelemetry.sdk.resources.Resource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConditionalOnProperty(prefix = "observability", name = "enabled", havingValue = "true", matchIfMissing = true)
public class OtlpLoggingConfiguration {
    
    private static final Logger log = LoggerFactory.getLogger(OtlpLoggingConfiguration.class);

    @Bean
    public SdkLoggerProvider sdkLoggerProvider(ObservabilityProperties props) {
        Resource resource = Resource.getDefault().merge(Resource.create(Attributes.builder()
                .put("service.name", props.getServiceName())
                .put("service.namespace", props.getServiceNamespace())
                .put("deployment.environment", "groundcover-demo")
                .put("service.version", "1.4.0-groundcover")
                .put("service.instance.id", System.getProperty("user.name", "unknown"))
                .build()));

        var builder = SdkLoggerProvider.builder()
                .setResource(resource);

        if ("otlp".equalsIgnoreCase(props.getExporter())) {
            log.info("Configuring OTLP logs exporter at {}", props.getOtlpLogsEndpoint());
            OtlpGrpcLogRecordExporter logsExporter = OtlpGrpcLogRecordExporter.builder()
                    .setEndpoint(props.getOtlpLogsEndpoint())
                    .build();
            
            LogRecordProcessor processor = BatchLogRecordProcessor.builder(logsExporter).build();
            builder.addLogRecordProcessor(processor);
        }

        return builder.build();
    }
}

