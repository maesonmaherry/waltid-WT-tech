FROM gradle:latest AS build
WORKDIR /src
COPY . /src
RUN chmod +x ./gradlew && ./gradlew -x test build \
  && mkdir -p /output \
  && find . -type f -path "*/build/libs/*.jar" -exec cp {} /output/ \;

FROM eclipse-temurin:17-jre
WORKDIR /app

# install nginx and minimal tools for the container
RUN apt-get update && apt-get install -y --no-install-recommends nginx procps curl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Copy compiled jars from build stage
COPY --from=build /output /app/jars

# Copy nginx config and start script
COPY docker-eb/nginx.conf /etc/nginx/nginx.conf
COPY docker-eb/start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 80 8080 8081 8082
ENV JAVA_OPTS=""

CMD [ "/app/start.sh" ]
