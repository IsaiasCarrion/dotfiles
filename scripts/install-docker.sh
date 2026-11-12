#!/usr/bin/env bash
# scripts/install-docker.sh — optional Docker module for CachyOS/Arch.
#
# Arch/CachyOS provides rootless Podman. Install Docker only when a workflow
# explicitly needs it. The script never removes Podman and never adds the user
# to the docker group (that group is effectively root-equivalent).

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: scripts/install-docker.sh [options]

Options:
  --dry-run   Show what would be installed; change nothing.
  --yes, -y   Do not ask for confirmation.
  -h, --help  Show this help.

Installs docker, docker-compose and docker-buildx from the official
repositories. The service is not enabled or started automatically.
EOF
}

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --yes|-y) ASSUME_YES=1 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

PACKAGES=(docker docker-compose docker-buildx)

main() {
    require_arch

    if pkg_installed docker; then
        info "Docker is already installed."
        info "Enable it with: sudo systemctl enable --now docker"
        return 0
    fi

    local pkg
    for pkg in "${PACKAGES[@]}"; do
        pkg_available "$pkg" || die "Package not available in the official repositories: $pkg"
    done

    warn "Podman (rootless) is the preferred container runtime on Arch/CachyOS."
    info "This module is optional and keeps Podman installed."

    if (( ! DRY_RUN )) && ! confirm "Install Docker from the official repositories?"; then
        info "Cancelled."
        return 0
    fi

    log "Installing Docker."
    if ! sudo_run pacman -S --needed --noconfirm -- "${PACKAGES[@]}"; then
        die "pacman failed. If the package database is stale, run 'sudo pacman -Syu' and retry."
    fi

    info "Start Docker with: sudo systemctl enable --now docker"
    info "Run containers with sudo, or configure rootless Docker; this script does not add you to the docker group."
}

main "$@"
