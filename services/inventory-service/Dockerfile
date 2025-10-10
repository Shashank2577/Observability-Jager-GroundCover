# Inventory Service Dockerfile
FROM eclipse-temurin:17-jre AS base
WORKDIR /app

ARG OTEL_JAVA_AGENT_VERSION=2.20.1
ARG DOWNLOAD_AGENT=true

# Install curl only if we might download the agent
RUN if [ "$DOWNLOAD_AGENT" = "true" ]; then \
      microdnf install -y curl ca-certificates wget || (apt-get update && apt-get install -y curl ca-certificates wget); \
    fi || true

# Attempt to download OpenTelemetry Java agent
RUN if [ "$DOWNLOAD_AGENT" = "true" ]; then \
      mkdir -p /otel && \
      curl -fL https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_JAVA_AGENT_VERSION}/opentelemetry-javaagent.jar -o /otel/opentelemetry-javaagent.jar; \
    fi

COPY target/inventory-service-*.jar app.jar

# NOTE: Do not set JAVA_TOOL_OPTIONS to an empty value to avoid JVM startup errors.
# Enable agent at runtime with: JAVA_TOOL_OPTIONS=-javaagent:/otel/opentelemetry-javaagent.jar

ENV OTEL_TRACES_EXPORTER=otlp \
    OTEL_METRICS_EXPORTER=none \
    OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317 \
    OTEL_RESOURCE_ATTRIBUTES="service.name=inventory-service,service.namespace=shash.demo,deployment.environment=groundcover-demo,service.version=1.11.6-groundcover" \
    OTEL_LOGS_EXPORTER=otlp \
    OTEL_EXPORTER_OTLP_LOGS_ENDPOINT=http://otel-collector:4318 \
    OTEL_INSTRUMENTATION_LOGGING_EXPERIMENTAL_ENABLED=true
ENV JAVA_TOOL_OPTIONS="-javaagent:/otel/opentelemetry-javaagent.jar"

EXPOSE 8080
ENTRYPOINT ["sh","-c","java $JAVA_TOOL_OPTIONS -jar app.jar"]
