#!/usr/bin/env bash
# scripts/lib.sh — helpers shared by the bootstrap scripts.
# Sourced, never executed directly.

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_ROOT="${DOTFILES_BACKUP_ROOT:-$HOME/.dotfiles-backup}"
DRY_RUN="${DRY_RUN:-0}"
ASSUME_YES="${ASSUME_YES:-0}"

# The deploy step links into ~/.local/bin; make it usable during bootstrap too.
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH" ;;
esac
export PATH

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33mwarning:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

# Run a command, or print it when --dry-run is active.
run() {
    if (( DRY_RUN )); then
        printf '[dry-run]'
        printf ' %q' "$@"
        printf '\n'
        return 0
    fi
    "$@"
}

# Run a command with sudo when needed (and never as root-in-root).
sudo_run() {
    if (( DRY_RUN )); then
        printf '[dry-run]'
        printf ' %q' sudo "$@"
        printf '\n'
        return 0
    fi
    if (( EUID == 0 )); then
        "$@"
    else
        sudo "$@"
    fi
}

# Ask for confirmation unless --yes was passed.
confirm() {
    local prompt="$1" answer
    if (( ASSUME_YES )); then
        return 0
    fi
    [[ -t 0 ]] || die "Non-interactive shell; re-run with --yes to continue."
    read -r -p "$prompt [y/N]: " answer || return 1
    [[ "$answer" =~ ^([yY]|yes|YES|s|si|S)$ ]]
}

timestamp() { date +%Y%m%d-%H%M%S; }

require_fedora() {
    [[ -r /etc/fedora-release ]] ||
        die "This bootstrap targets Fedora; /etc/fedora-release was not found."
}

require_cmd() {
    have "$1" || die "Required command not found: $1"
}

# Read a manifest: strip comments, trim spaces, drop empty lines.
manifest_packages() {
    local file="$1"
    [[ -r "$file" ]] || die "Missing manifest: $file"
    sed -E 's/[[:space:]]*#.*$//' "$file" | tr -d '\r' | awk 'NF'
}

pkg_installed() { rpm -q "$1" >/dev/null 2>&1; }

# Locate the OpenCode V2 CLI, including the binary bundled with the desktop RPM.
opencode_cmd() {
    if have opencode; then
        printf 'opencode\n'
    elif [[ -x /opt/OpenCode/resources/opencode-cli ]]; then
        printf '%s\n' /opt/OpenCode/resources/opencode-cli
    else
        return 1
    fi
}
