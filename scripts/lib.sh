#!/usr/bin/env bash
# scripts/lib.sh — helpers shared by the bootstrap scripts (Arch/Omarchy).
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
        have sudo || die "sudo is required for this step: $*"
        sudo "$@"
    fi
}

# Ask for confirmation unless --yes was passed.
confirm() {
    local prompt="$1" answer
    # A dry run must never block on input, because nothing will change.
    if (( ASSUME_YES || DRY_RUN )); then
        return 0
    fi
    [[ -t 0 ]] || die "Non-interactive shell; re-run with --yes to continue."
    read -r -p "$prompt [y/N]: " answer || return 1
    [[ "$answer" =~ ^([yY]|yes|YES|s|si|S)$ ]]
}

timestamp() { date +%Y%m%d-%H%M%S; }

os_release_field() {
    local field="$1"
    [[ -r /etc/os-release ]] || return 1
    ( set +u; . /etc/os-release; printf '%s' "${!field:-}" )
}

# Accept Omarchy and any Arch-compatible distribution.
require_arch() {
    local id id_like
    id="$(os_release_field ID || true)"
    id_like="$(os_release_field ID_LIKE || true)"

    case "$id" in
        omarchy|cachyos|arch|endeavouros|manjaro|garuda) ;;
        *)
            case " $id_like " in
                *" arch "*) ;;
                *) die "This bootstrap targets Omarchy/Arch (detected ID='${id:-unknown}')." ;;
            esac
            ;;
    esac

    have pacman || die "pacman was not found; this is not an Arch-compatible system."
}

is_omarchy() {
    [[ "$(os_release_field ID || true)" == "omarchy" ]]
}

omarchy_version() {
    if have omarchy-version; then
        omarchy-version 2>/dev/null | head -n1
    elif [[ -r /usr/share/omarchy/version ]]; then
        head -n1 /usr/share/omarchy/version
    else
        printf 'unknown\n'
    fi
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

pkg_installed() { pacman -Qq -- "$1" >/dev/null 2>&1; }
pkg_available() { pacman -Si -- "$1" >/dev/null 2>&1; }

# Omarchy manages a set of CLI tools through mise (gh, opencode, uv, node, ...).
# See /etc/mise/conf.d/omarchy-tools.toml. Installing the pacman package on top
# would duplicate or shadow the mise version, so the installer leaves them alone.
OMARCHY_MISE_CONFIG="${OMARCHY_MISE_CONFIG:-/etc/mise/conf.d/omarchy-tools.toml}"

omarchy_mise_tool() {
    is_omarchy || return 1
    [[ -r "$OMARCHY_MISE_CONFIG" ]] || return 1
    grep -qE "^[[:space:]]*(\"?${1//./\\.}\"?)[[:space:]]*=" "$OMARCHY_MISE_CONFIG"
}

# A tool is satisfied when its command runs, whether it came from pacman,
# mise or ~/.local/bin.
tool_available() { have "$1"; }

# Return the available AUR helper, if any. Never installs one implicitly.
aur_helper() {
    local helper
    for helper in paru yay; do
        if have "$helper"; then
            printf '%s\n' "$helper"
            return 0
        fi
    done
    return 1
}
