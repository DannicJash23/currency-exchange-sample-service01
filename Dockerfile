# Start with base image
FROM openjdk:17-jdk-slim
# Set working directory
WORKDIR /app
# Copy Maven build jar to container
COPY target/currency-exchange-sample-service01.jar myapp.jar
# Expose application port
EXPOSE 8080
# Run the jar file
ENTRYPOINT ["java", "-jar", "myapp.jar"]
