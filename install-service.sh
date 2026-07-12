#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVICE_NAME="${SERVICE_NAME:-live-scheduler}"
USER_NAME="${USER_NAME:-$(id -un)}"
ENV_FILE="${APP_DIR}/.env"

CURRENT_HOSTNAME="0.0.0.0"
CURRENT_PORT="3500"
CURRENT_SECRET=""
if [ -f "${ENV_FILE}" ]; then
  ENV_HOSTNAME="$(sed -n 's/^HOSTNAME=//p' "${ENV_FILE}" | tail -n 1)"
  ENV_PORT="$(sed -n 's/^PORT=//p' "${ENV_FILE}" | tail -n 1)"
  ENV_SECRET="$(sed -n 's/^SESSION_SECRET=//p' "${ENV_FILE}" | tail -n 1)"
  CURRENT_HOSTNAME="${ENV_HOSTNAME:-0.0.0.0}"
  CURRENT_PORT="${ENV_PORT:-3500}"
  if [ -n "${ENV_SECRET}" ] && [ "${ENV_SECRET}" != "replace-with-a-long-random-secret" ]; then
    CURRENT_SECRET="${ENV_SECRET}"
  fi
fi

LISTEN_HOST="${CURRENT_HOSTNAME}"
LISTEN_PORT="${CURRENT_PORT}"
if [ -t 0 ]; then
  read -r -p "Listen IP [${CURRENT_HOSTNAME}]: " INPUT_HOST
  read -r -p "Listen port [${CURRENT_PORT}]: " INPUT_PORT
  LISTEN_HOST="${INPUT_HOST:-${CURRENT_HOSTNAME}}"
  LISTEN_PORT="${INPUT_PORT:-${CURRENT_PORT}}"
fi

if ! [[ "${LISTEN_HOST}" =~ ^[A-Za-z0-9.:-]+$ ]]; then
  echo "Invalid listen IP or hostname: ${LISTEN_HOST}" >&2
  exit 1
fi
if ! [[ "${LISTEN_PORT}" =~ ^[0-9]+$ ]] || [ "${LISTEN_PORT}" -lt 1 ] || [ "${LISTEN_PORT}" -gt 65535 ]; then
  echo "Port must be an integer between 1 and 65535." >&2
  exit 1
fi

NODE_BIN="$(command -v node || true)"
if [ -z "${NODE_BIN}" ]; then
  echo "Node.js 24 or newer is required." >&2
  exit 1
fi

if [ -z "${CURRENT_SECRET}" ]; then
  if command -v openssl >/dev/null 2>&1; then
    CURRENT_SECRET="$(openssl rand -hex 32)"
  else
    CURRENT_SECRET="$(${NODE_BIN} -e "console.log(require('crypto').randomBytes(32).toString('hex'))")"
  fi
fi

cat >"${ENV_FILE}" <<ENV
NODE_ENV=production
HOSTNAME=${LISTEN_HOST}
PORT=${LISTEN_PORT}
SESSION_SECRET=${CURRENT_SECRET}
ENV
chmod 600 "${ENV_FILE}"
mkdir -p "${APP_DIR}/data"

sudo tee "/etc/systemd/system/${SERVICE_NAME}.service" >/dev/null <<SERVICE
[Unit]
Description=Live Scheduler
After=network.target

[Service]
Type=simple
WorkingDirectory=${APP_DIR}
EnvironmentFile=${APP_DIR}/.env
ExecStart=${NODE_BIN} ${APP_DIR}/server.js
Restart=always
RestartSec=3
User=${USER_NAME}

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable "${SERVICE_NAME}"
sudo systemctl restart "${SERVICE_NAME}"
sudo systemctl status "${SERVICE_NAME}" --no-pager

echo
echo "Installation page: http://${LISTEN_HOST}:${LISTEN_PORT}/install"
