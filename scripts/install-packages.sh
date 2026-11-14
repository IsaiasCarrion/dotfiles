#!/usr/bin/env bash
# scripts/install-packages.sh — install only missing Arch/Omarchy packages.
#
# Reads:
#   packages/base.txt     bootstrap/runtime dependencies
#   packages/common.txt   CLI tools used by the managed configurations
#   packages/apps.txt     personal applications installed by default
#   packages/optional.txt optional toolchains/runtimes (--with-optional)
#
# Omarchy already ships a large base system; this step only fills the gaps.
# Tools that Omarchy provides through mise (gh, opencode, uv, ...) are skipped
# so the pacman package does not duplicate or shadow them.
# Idempotent: installed packages are skipped. Nothing is upgraded implicitly;
# if the sync database is stale, run `sudo pacman -Syu` and retry.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: scripts/install-packages.sh [options]

Options:
  --dry-run        Print the commands without changing the system.
  --yes, -y        Do not ask for confirmation.
  --with-optional  Also install packages from packages/optional.txt.
  --no-apps        Skip packages/apps.txt (Ghostty, Zed, OpenCode, Obsidian).
  -h, --help       Show this help.
EOF
}

WITH_OPTIONAL=0
WITH_APPS=1

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --yes|-y) ASSUME_YES=1 ;;
        --with-optional) WITH_OPTIONAL=1 ;;
        --no-apps) WITH_APPS=0 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

# Read a manifest and append the packages that are not installed yet.
# Tools that Omarchy already provides through mise are skipped: a pacman
# package would duplicate or shadow the mise-installed command.
collect_missing() {
    local manifest="$1"
    local -n target="$2"
    local pkg
    while IFS= read -r pkg; do
        [[ -n "$pkg" ]] || continue
        if pkg_installed "$pkg"; then
            continue
        fi
        if omarchy_mise_tool "$pkg"; then
            info "skipping $pkg: provided by Omarchy through mise"
            continue
        fi
        target+=("$pkg")
    done < <(manifest_packages "$manifest")
}

main() {
    require_arch
    if is_omarchy; then
        info "Omarchy $(omarchy_version) detected; only missing packages will be installed."
    fi

    local -a required=() optional=()
    collect_missing "$REPO_ROOT/packages/base.txt" required
    collect_missing "$REPO_ROOT/packages/common.txt" required
    if (( WITH_APPS )); then
        collect_missing "$REPO_ROOT/packages/apps.txt" required
    fi

    if ((${#required[@]})); then
        local pkg
        for pkg in "${required[@]}"; do
            pkg_available "$pkg" || die "Package not available in the official repositories: $pkg"
        done

        log "Installing ${#required[@]} required package(s): ${required[*]}"
        if ! sudo_run pacman -S --needed --noconfirm -- "${required[@]}"; then
            die "pacman failed. If the package database is stale, run 'sudo pacman -Syu' and retry."
        fi
    else
        info "All required packages are already installed."
    fi

    if (( WITH_OPTIONAL )); then
        local pkg
        while IFS= read -r pkg; do
            [[ -n "$pkg" ]] || continue
            if pkg_installed "$pkg"; then
                continue
            fi
            if omarchy_mise_tool "$pkg"; then
                info "skipping $pkg: provided by Omarchy through mise"
                continue
            fi
            if pkg_available "$pkg"; then
                optional+=("$pkg")
            else
                warn "Skipping optional package not available in the official repositories: $pkg"
            fi
        done < <(manifest_packages "$REPO_ROOT/packages/optional.txt")

        if ((${#optional[@]})); then
            log "Installing ${#optional[@]} optional package(s): ${optional[*]}"
            if ! sudo_run pacman -S --needed --noconfirm -- "${optional[@]}"; then
                die "pacman failed while installing optional packages."
            fi
        else
            info "All optional packages are already installed."
        fi
    fi

    log "Package step finished."
}

main "$@"
