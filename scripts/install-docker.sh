#!/usr/bin/env bash
# scripts/install-docker.sh — optional Docker CE module.
#
# Fedora already provides rootless Podman. Install Docker only when a workflow
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

Adds the official Docker CE repository and installs docker-ce, the CLI,
containerd, Buildx and Compose. The service is not started automatically.
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

REPO_URL="https://download.docker.com/linux/fedora/docker-ce.repo"
REPO_FILE="/etc/yum.repos.d/docker-ce.repo"
PACKAGES=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)

main() {
    require_fedora
    require_cmd dnf

    if pkg_installed docker-ce; then
        info "Docker CE is already installed."
        info "Enable it with: sudo systemctl enable --now docker"
        return 0
    fi

    warn "Podman (rootless) is the preferred container runtime on Fedora."
    info "This module is optional and keeps Podman installed."

    if (( ! DRY_RUN )) && ! confirm "Install Docker CE from the official repository?"; then
        info "Cancelled."
        return 0
    fi

    if [[ ! -f "$REPO_FILE" ]]; then
        log "Adding the Docker CE repository."
        sudo_run dnf config-manager addrepo --from-repofile="$REPO_URL"
    else
        info "Docker CE repository already configured."
    fi

    log "Installing Docker CE."
    sudo_run dnf install -y -- "${PACKAGES[@]}"

    info "Start Docker with: sudo systemctl enable --now docker"
    info "Run containers with sudo, or configure rootless Docker; this script does not add you to the docker group."
}

main "$@"
