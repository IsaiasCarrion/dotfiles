#!/usr/bin/env bash
# scripts/install-zed.sh — install the stable Zed editor with the official installer.
#
# Detects RPM, Flatpak and the official tarball layout before doing anything.
# It never touches ~/.config/zed or ~/.local/share/zed.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: scripts/install-zed.sh [options]

Options:
  --dry-run   Show what would be installed; change nothing.
  --update    Re-run the official installer even if Zed is already present.
  -h, --help  Show this help.

The official installer is https://zed.dev/install.sh (stable channel). It
supports x86_64 and aarch64 and installs under ~/.local/.
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

find_zed() {
    local candidate
    if have zed; then
        command -v zed
        return 0
    fi
    for candidate in \
        "$HOME/.local/zed.app/bin/zed" \
        "$HOME/.local/zed-preview.app/bin/zed"; do
        if [[ -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

main() {
    local bin

    if bin="$(find_zed)"; then
        if (( ! FORCE_UPDATE )); then
            info "Zed is already installed: $("$bin" --version 2>/dev/null | head -n1)"
            info "Configuration in ~/.config/zed and ~/.local/share/zed is left untouched."
            info "Run with --update to refresh the installation."
            return 0
        fi
        info "Updating Zed with the official installer (configuration is preserved)."
    elif have flatpak && flatpak info dev.zed.Zed >/dev/null 2>&1; then
        if (( FORCE_UPDATE )); then
            log "Updating the Zed Flatpak."
            run flatpak update -y dev.zed.Zed
        else
            info "Zed is already installed as a Flatpak; skipping to avoid duplicates."
        fi
        return 0
    elif pkg_installed zed; then
        if (( FORCE_UPDATE )); then
            log "Updating the Zed RPM."
            sudo_run dnf upgrade -y zed
        else
            info "Zed is already installed as an RPM; skipping."
        fi
        return 0
    fi

    if (( DRY_RUN )); then
        info "Would run the official installer https://zed.dev/install.sh (stable, $(uname -m))."
        return 0
    fi

    require_cmd curl
    local installer
    installer="$(mktemp "${TMPDIR:-/tmp}/zed-install.XXXXXX")"

    if ! curl -fsSL https://zed.dev/install.sh -o "$installer"; then
        rm -f -- "$installer"
        die "Could not download the Zed installer."
    fi
    if ! sh "$installer"; then
        rm -f -- "$installer"
        die "The Zed installer failed."
    fi
    rm -f -- "$installer"

    bin="$(find_zed)" || die "Zed was installed but the executable was not found."
    info "Installed: $("$bin" --version 2>/dev/null | head -n1)"
    info "Update later with: ./scripts/install-zed.sh --update"
}

main "$@"
