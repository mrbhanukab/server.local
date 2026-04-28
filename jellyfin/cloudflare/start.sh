#!/bin/bash

# Start the WARP service in the background
echo "Starting warp-svc..."
warp-svc &
WARP_PID=$!

# Give the daemon a moment to initialize
sleep 5

# Check if we are already registered
if [ ! -f /var/lib/cloudflare-warp/settings.json ]; then
    echo "No existing registration found. Registering as a new connector..."

    # Check if WARP_TOKEN is provided
    if [ -z "$WARP_TOKEN" ]; then
        echo "ERROR: WARP_TOKEN environment variable is not set!"
        echo "Please set it in your .env file."
        exit 1
    fi

    # Register the connector
    warp-cli --accept-tos connector new "$WARP_TOKEN"
else
    echo "Existing registration found. Skipping registration..."
fi

echo "Connecting WARP..."
# Always include --accept-tos for non-interactive environments
warp-cli --accept-tos connect

# Keep the container alive by waiting on the warp-svc process
wait $WARP_PID
