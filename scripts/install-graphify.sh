#!/usr/bin/env bash
# scripts/install-graphify.sh — optional Graphify skill/CLI.
#
# Installs the pinned PyPI package with uv (preferred) or pipx, and optionally
# wires it into one project. It never edits the global AGENTS.md: Graphify's
# OpenCode integration writes project instructions, so it is opt-in per project.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

GRAPHIFY_VERSION="0.9.103"
CONFIGURE_DIR=""

usage() {
    cat <<'EOF'
Usage: scripts/install-graphify.sh [options]

Options:
  --dry-run             Show what would be installed; change nothing.
  --version <version>   Override the pinned graphifyy version (default: 0.9.103).
  --configure <dir>     Run `graphify install --platform opencode` in <dir>.
  -h, --help            Show this help.

Install the tool globally, then configure it only in projects where a knowledge
graph is actually useful.
EOF
}

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --version)
            [[ -n "${2:-}" ]] || die "--version needs a value."
            GRAPHIFY_VERSION="$2"
            shift
            ;;
        --configure)
            [[ -n "${2:-}" ]] || die "--configure needs a directory."
            CONFIGURE_DIR="$2"
            shift
            ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

main() {
    if (( DRY_RUN )); then
        if have uv; then
            info "[dry-run] uv tool install graphifyy==$GRAPHIFY_VERSION"
        elif have pipx; then
            info "[dry-run] pipx install graphifyy==$GRAPHIFY_VERSION"
        else
            info "Dry run: uv/pipx is missing; the package step installs uv first."
        fi
        if [[ -n "$CONFIGURE_DIR" ]]; then
            info "[dry-run] (cd $CONFIGURE_DIR && graphify install --platform opencode)"
        else
            info "After installing: cd /path/to/project && graphify install --platform opencode"
        fi
        return 0
    fi

    if have uv; then
        log "Installing graphifyy==$GRAPHIFY_VERSION with uv."
        run uv tool install "graphifyy==$GRAPHIFY_VERSION"
    elif have pipx; then
        log "Installing graphifyy==$GRAPHIFY_VERSION with pipx."
        run pipx install "graphifyy==$GRAPHIFY_VERSION"
    else
        die "uv or pipx is required. Install it first: sudo dnf install uv"
    fi

    if [[ -n "$CONFIGURE_DIR" ]]; then
        [[ -d "$CONFIGURE_DIR" ]] || die "Not a directory: $CONFIGURE_DIR"
        log "Configuring Graphify for OpenCode in $CONFIGURE_DIR"
        ( cd -- "$CONFIGURE_DIR" && run graphify install --platform opencode )
    else
        info "Graphify installed. To enable it in a project:"
        info "  cd /path/to/project && graphify install --platform opencode"
    fi
}

main "$@"
