#!/bin/bash

# --- Kaneo ---
tailscale serve --bg --service=svc:kaneo --https=443 / http://127.0.0.1:5173
tailscale serve --bg --service=svc:kaneo-api --https=443 / http://127.0.0.1:1337

# --- Monitoring ---
tailscale serve --bg --service=svc:uptime --https=443 / http://127.0.0.1:3001
tailscale serve --bg --service=svc:dozzle --https=443 / http://127.0.0.1:8084

# --- Tools ---
tailscale serve --bg --service=svc:pdf --https=443 / http://127.0.0.1:8082
tailscale serve --bg --service=svc:it-tools --https=443 / http://127.0.0.1:8083

echo "Tailscale services have been started in the background."
echo "Use 'tailscale serve status' to check the current configuration."
