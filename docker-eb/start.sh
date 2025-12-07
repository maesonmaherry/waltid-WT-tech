#!/bin/bash
set -e

start_service() {
  local port="$1"
  local jar="$2"
  if [ -n "$jar" ]; then
    echo "Starting $jar on $port"
    nohup java $JAVA_OPTS -jar "$jar" > "/app/log-$(basename $jar).log" 2>&1 &
    echo $! > "/app/pid-$(basename $jar).pid"
  fi
}

stop_all() {
  echo "Stopping all child processes..."
  pkill -f 'java .*\.jar' || true
  nginx -s quit || true
}

trap 'stop_all; exit 0' TERM INT

# try to find suitable jars
WALLET_JAR=$(ls /app/jars/*wallet*/*.jar /app/jars/*wallet*.jar 2>/dev/null | head -n1 || true)
if [ -z "$WALLET_JAR" ]; then
  WALLET_JAR=$(ls /app/jars/*waltid-wallet-api*.jar /app/jars/*wallet-api*.jar 2>/dev/null | head -n1 || true)
fi
ISSUER_JAR=$(ls /app/jars/*issuer*/*.jar /app/jars/*issuer*.jar 2>/dev/null | head -n1 || true)
VERIFIER_JAR=$(ls /app/jars/*verifier*/*.jar /app/jars/*verifier*.jar 2>/dev/null | head -n1 || true)

echo "Detected jars:"
echo "  WALLET: $WALLET_JAR"
echo "  ISSUER: $ISSUER_JAR"
echo "  VERIFIER: $VERIFIER_JAR"

# start services
start_service 8080 "$WALLET_JAR"
start_service 8081 "$ISSUER_JAR"
start_service 8082 "$VERIFIER_JAR"

# start nginx
echo "Starting nginx..."
rm -f /run/nginx.pid || true
nginx

# keep container alive and respond to signals
while true; do
  sleep 5
done
