# Use an official Maven image to build the project
#
#FROM maven:3.5.2-jdk-17 AS build
FROM maven:3.8.7-eclipse-temurin-17 AS build
WORKDIR /app

# Copy the project files
COPY . .

# Build the application
RUN mvn clean package -DskipTests

# Use a lightweight Java runtime for the final image
FROM openjdk:17-jdk-slim
WORKDIR /app

# Copy the built jar from the build stage
COPY --from=build /app/target/*.jar app.jar

# Expose port 8000
EXPOSE 8000

# Command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
