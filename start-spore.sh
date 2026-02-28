#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="/zeroclaw-data"
CONFIG_DIR="$DATA_DIR/.zeroclaw"
CONFIG_FILE="$CONFIG_DIR/config.toml"

# ── 1. Ensure volume directories exist ──
mkdir -p "$CONFIG_DIR" "$DATA_DIR/workspace" "$DATA_DIR/chrome-storage"

# Config + secrets: `zeroclaw onboard` via `railway shell` after first deploy
# Persists in volume (/zeroclaw-data/.zeroclaw/)

# ── 3. Start Xvfb (virtual display for Chromium) ──
Xvfb :99 -screen 0 1920x1080x24 -nolisten tcp &
export DISPLAY=:99
sleep 1
echo "[spore] Xvfb started on :99"

# ── 4. Start x11vnc ──
x11vnc -display :99 -forever -nopw -shared -rfbport 5900 &
sleep 1
echo "[spore] x11vnc started on :5900"

# ── 5. Start noVNC (websocket → VNC bridge) ──
/opt/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080 &
sleep 1
echo "[spore] noVNC started on :6080"

# ── 6. Start nginx reverse proxy ──
nginx -c /etc/nginx/nginx-spore.conf &
echo "[spore] nginx started on :8080"

# ── 7. Start ZeroClaw daemon (gateway + channels) ──
echo "[spore] Starting zeroclaw daemon..."
exec zeroclaw daemon
