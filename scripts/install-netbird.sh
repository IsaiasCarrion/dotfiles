#!/usr/bin/env bash
# scripts/install-netbird.sh — optional NetBird client module.
#
# NetBird is not in the official Arch repositories; it comes from the AUR.
# The script checks for paru or yay and never installs an AUR helper on its own.
# No login or setup key is handled: joining a network is left to the user.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: scripts/install-netbird.sh [options]

Options:
  --dry-run   Show what would be installed; change nothing.
  --update    Upgrade an existing NetBird installation.
  -h, --help  Show this help.

Requires paru or yay (AUR). It never runs "netbird up" and never handles
setup keys.
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

main() {
    require_arch

    local helper
    helper="$(aur_helper)" || {
        die "NetBird is only available from the AUR. Install paru or yay first, or install NetBird manually."
    }

    if have netbird; then
        info "NetBird is already installed: $(netbird version 2>/dev/null | head -n1)"
        if (( FORCE_UPDATE )); then
            log "Upgrading NetBird with $helper."
            run "$helper" -S --noconfirm netbird
        else
            info "Run with --update to upgrade."
        fi
        info "Join a network manually with: sudo netbird up"
        return 0
    fi

    log "Installing NetBird from the AUR with $helper."
    if ! run "$helper" -S --needed --noconfirm netbird; then
        die "The AUR helper failed while installing NetBird."
    fi

    info "NetBird does not join a network automatically."
    info "Join manually with: sudo netbird up (or --setup-key, handled by you)."
}

main "$@"
