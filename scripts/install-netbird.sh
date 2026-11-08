#!/usr/bin/env bash
# scripts/install-netbird.sh — optional NetBird client module.
#
# NetBird no longer publishes a ready-made .repo file, so the repository is
# written from the official documentation values. No login or token is used:
# joining a network is left to the user.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: scripts/install-netbird.sh [options]

Options:
  --dry-run   Show what would be installed; change nothing.
  --update    Upgrade an existing NetBird installation.
  -h, --help  Show this help.

Writes /etc/yum.repos.d/netbird.repo (GPG verification enabled) and installs
the netbird client. It never runs "netbird up" and never handles setup keys.
EOF
}

FORCE_UPDATE=0

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --update) FORCE_UPDATE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

REPO_FILE="/etc/yum.repos.d/netbird.repo"
BASEURL="https://pkgs.netbird.io/yum/"
GPGBASE="https://pkgs.netbird.io/yum/repodata/repomd.xml.key"

write_repo_file() {
    local content
    content="[netbird]
name=NetBird
baseurl=$BASEURL
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=$GPGBASE"

    if (( DRY_RUN )); then
        printf '[dry-run] write %s:\n%s\n' "$REPO_FILE" "$content"
        return 0
    fi

    printf '%s\n' "$content" | sudo_run tee "$REPO_FILE" >/dev/null
}

main() {
    require_fedora
    require_cmd dnf

    if have netbird; then
        info "NetBird is already installed: $(netbird version 2>/dev/null | head -n1)"
        if (( FORCE_UPDATE )); then
            log "Upgrading NetBird."
            sudo_run dnf upgrade -y netbird
        else
            info "Run with --update to upgrade."
        fi
        info "Join a network manually with: sudo netbird up"
        return 0
    fi

    if (( ! DRY_RUN )); then
        require_cmd curl
        if ! curl -fsI --max-time 30 "${BASEURL}repodata/repomd.xml" >/dev/null 2>&1; then
            die "NetBird repository is unreachable: ${BASEURL}"
        fi
    fi

    if [[ -f "$REPO_FILE" ]]; then
        info "NetBird repository already configured: $REPO_FILE"
    else
        log "Writing the NetBird repository definition."
        write_repo_file
    fi

    log "Installing NetBird."
    sudo_run dnf install -y netbird

    info "NetBird does not join a network automatically."
    info "Join manually with: sudo netbird up (or --setup-key, handled by you)."
}

main "$@"
