#!/bin/bash
set -e

# 1. Cleanup & Path Security
N8N_BIN=$(which n8n || echo "/usr/local/bin/n8n")

# Only run fuser if it exists to avoid "command not found" errors
if command -v fuser >/dev/null 2>&1; then
  fuser -k 5678/tcp || true
  fuser -k 5679/tcp || true
fi

echo "--- 1. Starting n8n Main Server ---"
$N8N_BIN start &

# 2. Wait for Port Binding
echo "Waiting for n8n Broker to initialize on port 5679..."
# Increased to 60 retries (120 seconds) because Render boot can be slow
MAX_RETRIES=60
COUNT=0
until ss -lnt | grep -q :5679; do
  if [ $COUNT -eq $MAX_RETRIES ]; then
    echo "Error: n8n Main Server failed to start within 2 minutes."
    echo "Please check your database environment variables."
    exit 1
  fi
  sleep 2
  ((COUNT++))
done

echo "--- 2. Starting External Python Runner ---"
$N8N_BIN worker --task-runner:type=python &

echo "n8n and Python Runner are now active."

# 3. Process Monitoring
# This ensures Render restarts the container if any part of n8n crashes
wait -n
exit $?