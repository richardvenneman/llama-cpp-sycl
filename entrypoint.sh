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

LLAMA_HOST="${LLAMA_HOST:-0.0.0.0}"
LLAMA_PORT="${LLAMA_PORT:-8080}"

case "${1:-}" in
    llama-cli)
        shift
        exec llama-cli "$@"
        ;;
    llama-server)
        shift
        exec llama-server --host "$LLAMA_HOST" --port "$LLAMA_PORT" "$@"
        ;;
    bash|sh)
        exec "$@"
        ;;
    *)
        exec llama-server --host "$LLAMA_HOST" --port "$LLAMA_PORT" "$@"
        ;;
esac
