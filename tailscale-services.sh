#!/bin/bash

# --- Kaneo ---
tailscale serve --service=svc:kaneo --https=443 http://127.0.0.1:5173

# --- Monitoring ---
tailscale serve --service=svc:dozzle --https=443 http://127.0.0.1:8084

echo "Tailscale services have been started in the background."
echo "Use 'tailscale serve status' to check the current configuration."
