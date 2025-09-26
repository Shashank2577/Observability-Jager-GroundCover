package com.acme.observability.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "observability")
public class ObservabilityProperties {
    /** Enable/disable custom observability starter */
    private boolean enabled = true;
    private String serviceName = "demo-service";
    private double samplingProbability = 1.0d;
    /** exporter: otlp | logging */
    private String exporter = "otlp";
    private String otlpEndpoint = "http://otel-collector:4317";

    public boolean isEnabled() { return enabled; }
    public void setEnabled(boolean enabled) { this.enabled = enabled; }
    public String getServiceName() { return serviceName; }
    public void setServiceName(String serviceName) { this.serviceName = serviceName; }
    public double getSamplingProbability() { return samplingProbability; }
    public void setSamplingProbability(double samplingProbability) { this.samplingProbability = samplingProbability; }
    public String getExporter() { return exporter; }
    public void setExporter(String exporter) { this.exporter = exporter; }
    public String getOtlpEndpoint() { return otlpEndpoint; }
    public void setOtlpEndpoint(String otlpEndpoint) { this.otlpEndpoint = otlpEndpoint; }
}

