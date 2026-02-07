#!/bin/bash
set -e

if [ -f /opt/intel/oneapi/setvars.sh ]; then
    source /opt/intel/oneapi/setvars.sh --force > /dev/null 2>&1 || true
fi

export ZES_ENABLE_SYSMAN=1

if [ ! -d /dev/dri ]; then
    echo "ERROR: /dev/dri not found. Pass --device /dev/dri to docker run." >&2
    exit 1
fi

# Auto-detect render group GID and add llama user to it
RENDER_GID=$(stat -c '%g' /dev/dri/renderD128 2>/dev/null)
if [ -n "$RENDER_GID" ] && [ "$RENDER_GID" != "0" ]; then
    groupadd -g "$RENDER_GID" -o render 2>/dev/null || true
    usermod -aG render llama 2>/dev/null || true
fi

LLAMA_HOST="${LLAMA_HOST:-0.0.0.0}"
LLAMA_PORT="${LLAMA_PORT:-8080}"

case "${1:-}" in
    llama-cli)
        shift
        exec gosu llama llama-cli "$@"
        ;;
    llama-server)
        shift
        exec gosu llama llama-server --host "$LLAMA_HOST" --port "$LLAMA_PORT" "$@"
        ;;
    bash|sh)
        exec "$@"
        ;;
    *)
        exec gosu llama llama-server --host "$LLAMA_HOST" --port "$LLAMA_PORT" "$@"
        ;;
esac
