#!/bin/sh
set -eu

SECRET_FILE="/app/data/session-secret"
mkdir -p /app/data

if [ -z "${SESSION_SECRET:-}" ]; then
  if [ -s "${SECRET_FILE}" ]; then
    SESSION_SECRET="$(cat "${SECRET_FILE}")"
  else
    SESSION_SECRET="$(node -e "process.stdout.write(require('crypto').randomBytes(32).toString('hex'))")"
    printf '%s\n' "${SESSION_SECRET}" >"${SECRET_FILE}"
    chmod 600 "${SECRET_FILE}"
  fi
  export SESSION_SECRET
fi

exec "$@"
