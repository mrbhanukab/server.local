#!/bin/bash

# Dynamically get the primary LAN IP address of this machine
LOCAL_IP=$(ip route get 1.1.1.1 | awk '{print $7}')

echo "Binding Tailscale proxy to Local IP: $LOCAL_IP"

# --- Kaneo ---
tailscale serve --service=svc:kaneo --https=443 http://$LOCAL_IP:5173

# --- Monitoring ---
tailscale serve --service=svc:dozzle --https=443 http://$LOCAL_IP:8084
tailscale serve --service=svc:dockge --https=443 http://$LOCAL_IP:5001

# --- Metube ---
tailscale serve --service=svc:metube --https=443 http://$LOCAL_IP:8081

echo "Tailscale services have been started in the background."
echo "Use 'tailscale serve status' to check the current configuration."
