#!/usr/bin/env bash
# scripts/bootstrap.sh — Arch/Omarchy bootstrap orchestrator.
#
# Default flow (each step is idempotent):
#   1. install missing official packages (base, CLI tools, personal apps)
#   2. deploy the Stow packages (backing up conflicting files)
#   3. verify links, syntax, JSONC, applications and secrets
#
# Omarchy owns the desktop (Hyprland, shell, terminals, theme, Starship, Bash
# defaults) and this repository deliberately does not touch it.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: ./bootstrap.sh [options]

Options:
  --dry-run        Show every action without changing the system.
  --yes, -y        Assume yes for backups.
  --with-optional  Install packages/optional.txt (Go, Rust, Podman, OBS).
  --no-packages    Skip package installation.
  --no-apps        Do not install packages/apps.txt (Ghostty, Zed, OpenCode, Obsidian).
  --no-deploy      Skip the Stow deployment.
  --no-verify      Skip the final verification.
  -h, --help       Show this help.

Examples:
  ./bootstrap.sh --dry-run
  ./bootstrap.sh
  ./bootstrap.sh --yes --with-optional

This script never changes the login shell: Omarchy already uses Bash.
EOF
}

DRY_RUN=0
ASSUME_YES=0
WITH_OPTIONAL=0
DO_PACKAGES=1
DO_APPS=1
DO_DEPLOY=1
DO_VERIFY=1

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --yes|-y) ASSUME_YES=1 ;;
        --with-optional) WITH_OPTIONAL=1 ;;
        --no-packages) DO_PACKAGES=0 ;;
        --no-apps) DO_APPS=0 ;;
        --no-deploy) DO_DEPLOY=0 ;;
        --no-verify) DO_VERIFY=0 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

export DRY_RUN ASSUME_YES

print_plan() {
    log "Omarchy/Arch dotfiles bootstrap"
    info "repository: $REPO_ROOT"
    if is_omarchy; then
        info "system:     Omarchy $(omarchy_version)"
    else
        info "system:     Arch-compatible ($(os_release_field PRETTY_NAME || echo unknown))"
    fi
    info "mode:       $([[ "$DRY_RUN" == 1 ]] && echo 'dry-run (no changes)' || echo 'apply')"
    if (( WITH_OPTIONAL )); then
        info "optional:   packages/optional.txt"
    fi
}

step_packages() {
    local -a args=()
    if (( DRY_RUN )); then args+=(--dry-run); fi
    if (( ASSUME_YES )); then args+=(--yes); fi
    if (( WITH_OPTIONAL )); then args+=(--with-optional); fi
    if (( ! DO_APPS )); then args+=(--no-apps); fi
    "$REPO_ROOT/scripts/install-packages.sh" "${args[@]}"
}

step_deploy() {
    local -a args=()
    if (( DRY_RUN )); then args+=(--dry-run); fi
    if (( ASSUME_YES )); then args+=(--yes); fi
    "$REPO_ROOT/scripts/deploy-dotfiles.sh" "${args[@]}"
}

step_verify() {
    "$REPO_ROOT/scripts/verify.sh"
}

main() {
    require_arch
    require_cmd bash

    print_plan

    if (( DO_PACKAGES )); then
        log "Step 1/3: packages"
        step_packages
    fi

    if (( DO_DEPLOY )); then
        log "Step 2/3: Stow deployment"
        step_deploy
    fi

    if (( DO_VERIFY )); then
        if (( DRY_RUN )); then
            info "Dry run: verification will run after a real deployment."
        else
            log "Step 3/3: verification"
            step_verify
        fi
    fi

    log "Bootstrap finished."
    if (( DO_DEPLOY == 0 )); then
        info "Deployment was skipped; run: ./bootstrap.sh --no-packages"
    fi
    if (( DO_VERIFY == 0 )); then
        info "Verification was skipped; run: ./scripts/verify.sh"
    fi

    if ! have gh; then
        info "GitHub CLI (gh) is not on PATH; Omarchy provides it through mise."
    elif ! gh auth status >/dev/null 2>&1; then
        info "Next: gh auth login"
    fi

    info "Ghostty keeps Omarchy's theme. Personal preferences (optional): ./scripts/ghostty-personal.sh"
    info "Log out and back in only if you changed something in your session environment."
}

main "$@"
