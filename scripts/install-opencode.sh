#!/usr/bin/env bash
# scripts/install-opencode.sh — make the OpenCode V2 CLI available.
#
# Preferred path on this desktop: the binary bundled with the OpenCode RPM
# (/opt/OpenCode/resources/opencode-cli) is linked into ~/.local/bin. On a
# machine without that bundle, the official V2 installer is used.
#
# The Terra repository ships OpenCode V1 and is intentionally not used.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: scripts/install-opencode.sh [options]

Options:
  --dry-run   Print what would be done without changing anything.
  -h, --help  Show this help.
EOF
}

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

link_bundled_cli() {
    local bundled=/opt/OpenCode/resources/opencode-cli
    local target="$HOME/.local/bin/opencode"

    if [[ -e "$target" || -L "$target" ]]; then
        warn "$target already exists; leaving it untouched."
        return 0
    fi

    log "Linking the bundled OpenCode V2 CLI to $target"
    run mkdir -p "$HOME/.local/bin"
    run ln -s "$bundled" "$target"
}

install_official() {
    log "Installing OpenCode V2 with the official installer."
    if (( DRY_RUN )); then
        printf '[dry-run] curl -fsSL https://opencode.ai/v2/install -o <tmp>/install.sh\n'
        printf '[dry-run] bash <tmp>/install.sh\n'
        return 0
    fi

    local tmp
    tmp="$(mktemp -d)"
    curl -fsSL https://opencode.ai/v2/install -o "$tmp/install.sh"
    bash "$tmp/install.sh"
    rm -rf -- "$tmp"
}

main() {
    if have opencode; then
        local version
        version="$(opencode --version 2>/dev/null || true)"
        log "OpenCode is already on PATH: ${version:-unknown version}"
        return 0
    fi

    if [[ -x /opt/OpenCode/resources/opencode-cli ]]; then
        link_bundled_cli
    else
        install_official
    fi

    if (( DRY_RUN )); then
        return 0
    fi

    local cli version
    cli="$(opencode_cmd)" || die "OpenCode CLI not found after installation."
    version="$("$cli" --version 2>/dev/null || true)"
    case "$version" in
        "opencode v2."*) info "OpenCode V2 ready: $version" ;;
        "") warn "Could not determine the OpenCode version from $cli." ;;
        *) die "Expected OpenCode V2, found: $version" ;;
    esac
}

main "$@"
