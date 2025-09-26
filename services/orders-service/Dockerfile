# Orders Service Dockerfile
FROM eclipse-temurin:17-jre AS base
WORKDIR /app

ARG OTEL_JAVA_AGENT_VERSION=1.37.0
ARG DOWNLOAD_AGENT=true

# Install curl only if we might download the agent
RUN if [ "$DOWNLOAD_AGENT" = "true" ]; then \
      microdnf install -y curl ca-certificates || (apt-get update && apt-get install -y curl ca-certificates); \
    fi || true

# Attempt to download OpenTelemetry Java agent (non-fatal)
RUN if [ "$DOWNLOAD_AGENT" = "true" ]; then \
      mkdir -p /otel && \
      curl -fSL https://repo1.maven.org/maven2/io/opentelemetry/javaagent/opentelemetry-javaagent/${OTEL_JAVA_AGENT_VERSION}/opentelemetry-javaagent-${OTEL_JAVA_AGENT_VERSION}.jar -o /otel/opentelemetry-javaagent.jar || echo "(warn) Could not download otel javaagent version ${OTEL_JAVA_AGENT_VERSION}"; \
    fi

COPY target/orders-service-*.jar app.jar

# NOTE: Do not set JAVA_TOOL_OPTIONS to empty value here to avoid JVM parsing errors.
# To enable agent at runtime set: JAVA_TOOL_OPTIONS=-javaagent:/otel/opentelemetry-javaagent.jar

ENV OTEL_TRACES_EXPORTER=otlp \
    OTEL_METRICS_EXPORTER=none \
    OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4317 \
    OTEL_RESOURCE_ATTRIBUTES="service.name=orders-service" \
    OTEL_LOGS_EXPORTER=none

EXPOSE 8080
ENTRYPOINT ["sh","-c","java $JAVA_TOOL_OPTIONS -jar app.jar"]
