#!/usr/bin/env bash
# scripts/bootstrap.sh — Fedora bootstrap orchestrator.
#
# Default flow (each step is idempotent):
#   1. install missing RPM packages, COPR repositories and Flatpaks
#   2. make the OpenCode V2 CLI available
#   3. deploy the Stow packages (backing up conflicting files)
#   4. verify links, syntax, JSONC, Ghostty, niri and secrets
#
# Nothing is installed when it is already present. Existing real files are
# moved to ~/.dotfiles-backup/<timestamp>/ instead of being overwritten.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: ./bootstrap.sh [options]

Options:
  --dry-run        Show every action without changing the system.
  --yes, -y        Assume yes for the conflict backup (unattended runs).
  --with-optional  Install packages/optional.txt (toolchains, Starship, codecs).
  --no-packages    Skip RPM/COPR/Flatpak installation.
  --no-opencode    Skip making the OpenCode V2 CLI available.
  --no-deploy      Skip the Stow deployment.
  --no-verify      Skip the final verification.
  -h, --help       Show this help.

Examples:
  ./bootstrap.sh --dry-run
  ./bootstrap.sh
  ./bootstrap.sh --yes --with-optional
EOF
}

DRY_RUN=0
ASSUME_YES=0
WITH_OPTIONAL=0
DO_PACKAGES=1
DO_OPENCODE=1
DO_DEPLOY=1
DO_VERIFY=1

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --yes|-y) ASSUME_YES=1 ;;
        --with-optional) WITH_OPTIONAL=1 ;;
        --no-packages) DO_PACKAGES=0 ;;
        --no-opencode) DO_OPENCODE=0 ;;
        --no-deploy) DO_DEPLOY=0 ;;
        --no-verify) DO_VERIFY=0 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

# Export so the child scripts inherit the same safety mode.
export DRY_RUN ASSUME_YES

print_plan() {
    log "Fedora dotfiles bootstrap"
    info "repository: $REPO_ROOT"
    info "mode:       $([[ "$DRY_RUN" == 1 ]] && echo 'dry-run (no changes)' || echo 'apply')"
    if (( WITH_OPTIONAL )); then
        info "optional:   packages/optional.txt"
    fi
    return 0
}

step_packages() {
    local -a args=()
    if (( DRY_RUN )); then args+=(--dry-run); fi
    if (( ASSUME_YES )); then args+=(--yes); fi
    if (( WITH_OPTIONAL )); then args+=(--with-optional); fi
    "$REPO_ROOT/scripts/install-packages.sh" "${args[@]}"
}

step_opencode() {
    local -a args=()
    if (( DRY_RUN )); then args+=(--dry-run); fi
    "$REPO_ROOT/scripts/install-opencode.sh" "${args[@]}"
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
    require_fedora
    require_cmd bash
    require_cmd git

    print_plan

    if (( DO_PACKAGES )); then
        log "Step 1/4: packages"
        step_packages
    fi

    if (( DO_OPENCODE )); then
        log "Step 2/4: OpenCode CLI"
        step_opencode
    fi

    if (( DO_DEPLOY )); then
        log "Step 3/4: Stow deployment"
        step_deploy
    fi

    if (( DO_VERIFY )); then
        if (( DRY_RUN )); then
            info "Dry run: verification will run after a real deployment."
        else
            log "Step 4/4: verification"
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
}

main "$@"
