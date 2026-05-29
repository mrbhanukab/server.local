# =============================================================================
# common.env — Consolidated environment variables for all stacks
# =============================================================================
# IMPORTANT: This file lives at the repository root.
# Each docker-compose.yml references it via:
#   env_file:
#     - ../common.env
# =============================================================================

# --- System / User ---
PUID=1000
PGID=1000
TZ=Asia/Colombo

# --- Network Bindings (LAN + Tailscale) ---
# Bind service ports to LAN and Tailscale interfaces only
LAN_IP=
TAILSCALE_IP=

# --- Media Storage ---
# Point this to your host's media directory (e.g., /mnt/data/media)
MEDIA_DIR=/mnt/data/media

# --- Cloudflare DNS / TLS (DDNS via ddclient) ---
# API token with Zone:DNS:Edit for mrbhanuka.dev
CLOUDFLARE_API_TOKEN=

# --- CrowdSec ---
# Generate with: docker compose -f opennet/docker-compose.yml exec crowdsec cscli bouncers add traefik-bouncer
CROWDSEC_LAPI_KEY=

# --- WireGuard / VPN (Gluetun) ---
# Obtain from AirVPN Config Generator
WIREGUARD_PRIVATE_KEY=
WIREGUARD_PRESHARED_KEY=
WIREGUARD_ADDRESSES=
WIREGUARD_MTU=1280
# Obtained from AirVPN account (optional but recommended)
FIREWALL_VPN_INPUT_PORTS=
SERVER_COUNTRIES=

# --- MeTube ---
# Path to your separate disk for downloads
METUBE_DOWNLOADS_DIR=/mnt/data/metube-downloads

# --- Kaneo ---
POSTGRES_DB=kaneo
POSTGRES_USER=kaneo
POSTGRES_PASSWORD=
PGDATA=/var/lib/postgresql/data/pgdata
# Built from POSTGRES_* vars; do not set manually
# DATABASE_URL=

# Authentication secret (min 32 chars) — generate with:
# openssl rand -hex 32
AUTH_SECRET=

# --- GitHub Integration (Kaneo) ---
# Setup: https://kaneo.app/docs/core/integrations/github/setup
GITHUB_APP_ID=
GITHUB_WEBHOOK_SECRET=
GITHUB_PRIVATE_KEY=
GITHUB_APP_NAME=app-name

# Disable guest access and self-registration (Kaneo)
DISABLE_GUEST_ACCESS=true
DISABLE_REGISTRATION=true
# Optional: custom device auth clients (comma-separated)
# DEVICE_AUTH_CLIENT_IDS=kaneo-cli,kaneo-mcp