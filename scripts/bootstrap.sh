#!/usr/bin/env bash
# scripts/bootstrap.sh — CachyOS/Arch bootstrap orchestrator.
#
# Default flow (each step is idempotent):
#   1. install missing official packages (base, CLI tools, personal apps)
#   2. deploy the Stow packages (backing up conflicting files)
#   3. make Bash the login shell (only for the invoking user)
#   4. verify links, syntax, JSONC, applications and secrets
#
# The graphical environment (DMS, niri, display manager) is installed by
# CachyOS and is deliberately not touched by this repository.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: ./bootstrap.sh [options]

Options:
  --dry-run        Show every action without changing the system.
  --yes, -y        Assume yes for backups and the shell change.
  --with-optional  Install packages/optional.txt (toolchains, codecs, OBS).
  --no-packages    Skip package installation.
  --no-apps        Do not install packages/apps.txt (Ghostty, Zed, OpenCode, Obsidian).
  --no-deploy      Skip the Stow deployment.
  --no-shell       Do not change the login shell.
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
DO_APPS=1
DO_DEPLOY=1
DO_SHELL=1
DO_VERIFY=1

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --yes|-y) ASSUME_YES=1 ;;
        --with-optional) WITH_OPTIONAL=1 ;;
        --no-packages) DO_PACKAGES=0 ;;
        --no-apps) DO_APPS=0 ;;
        --no-deploy) DO_DEPLOY=0 ;;
        --no-shell) DO_SHELL=0 ;;
        --no-verify) DO_VERIFY=0 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

export DRY_RUN ASSUME_YES

print_plan() {
    log "CachyOS dotfiles bootstrap"
    info "repository: $REPO_ROOT"
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

step_shell() {
    local -a args=()
    if (( DRY_RUN )); then args+=(--dry-run); fi
    if (( ASSUME_YES )); then args+=(--yes); fi
    "$REPO_ROOT/scripts/set-shell.sh" "${args[@]}"
}

step_verify() {
    "$REPO_ROOT/scripts/verify.sh"
}

main() {
    require_arch
    require_cmd bash

    print_plan

    if (( DO_PACKAGES )); then
        log "Step 1/4: packages"
        step_packages
    fi

    if (( DO_DEPLOY )); then
        log "Step 2/4: Stow deployment"
        step_deploy
    fi

    if (( DO_SHELL )); then
        log "Step 3/4: login shell"
        step_shell
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
    if (( DO_SHELL == 0 )); then
        info "Shell change was skipped; run: ./scripts/set-shell.sh"
    fi
    if (( DO_VERIFY == 0 )); then
        info "Verification was skipped; run: ./scripts/verify.sh"
    fi

    if ! have gh; then
        info "GitHub CLI is not installed; the Git credential helper needs it."
    elif ! gh auth status >/dev/null 2>&1; then
        info "Next: gh auth login"
    fi
    info "Open a new session (or run: exec bash) to load the new shell configuration."
}

main "$@"
