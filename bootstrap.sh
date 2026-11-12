#!/usr/bin/env bash
# bootstrap.sh — one-command restore for this CachyOS desktop.
# The real work lives in scripts/; this wrapper only keeps the entry point tidy.

set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec "$ROOT/scripts/bootstrap.sh" "$@"
