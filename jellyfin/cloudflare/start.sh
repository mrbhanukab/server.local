#!/bin/bash

# Start the WARP service in the background
echo "Starting warp-svc..."
warp-svc &
WARP_PID=$!

# Give the daemon a moment to initialize
sleep 5

# Check if WARP_TOKEN is provided
if [ -z "$WARP_TOKEN" ]; then
    echo "ERROR: WARP_TOKEN environment variable is not set!"
    echo "Please set it in your .env file."
    exit 1
fi

echo "Registering WARP connector with token..."
# Using the exact command for connector mode
warp-cli connector new "$WARP_TOKEN"

echo "Connecting WARP..."
warp-cli connect

# Keep the container alive by waiting on the warp-svc process
wait $WARP_PID
