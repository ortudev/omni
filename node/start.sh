#!/bin/bash
set -e

echo "[start] workspace-node ready"
echo "[start] Node: $(node -v)"
echo "[start] pnpm: $(pnpm -v)"
echo "[start] Available node versions:"
source /usr/local/nvm/nvm.sh && nvm list

exec tail -f /dev/null
