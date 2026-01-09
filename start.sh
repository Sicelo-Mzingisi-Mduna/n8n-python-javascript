#!/bin/bash
# ===================================================
# n8n startup script for Render (External Mode)
# ===================================================

set -e

# Ensure global npm binaries are in PATH
export PATH=$PATH:/usr/local/bin

echo "--- 1. Starting n8n Main Server ---"
# Start the main process
n8n start &

# Wait for the main server to actually start listening on 5678
# This helps Render detect the service is live
echo "Waiting for n8n to start listening on port 5678..."
for i in {1..30}; do
    if ss -lnt | grep -q :5678; then
        echo "n8n is up!"
        break
    fi
    sleep 2
done

echo "--- 2. Starting External Python Runner ---"
# In newer n8n versions, the python runner is launched via the 'worker' command
# with the --concurrency and --task-runner flags
n8n worker --task-runner:type=python &

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?