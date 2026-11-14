#!/usr/bin/env bash
# scripts/install-addy-skills.sh — optional, pinned Addy agent skills.
# Arch/Omarchy: requires git (packages/base.txt).
#
# Installs a curated subset (default) or all skills from
# https://github.com/addyosmani/agent-skills into the global OpenCode skill
# directory. Skills are only advertised by name and description, so the full
# pack still costs little context; the curated set keeps the list smaller.
#
# Pinned commit: keep it in sync with docs/opencode.md.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

ADDY_REPO="https://github.com/addyosmani/agent-skills.git"
ADDY_COMMIT="301b02b12bff98e4688e6984af6556802322bbde"
SKILLS_DIR="$HOME/.config/opencode/skills"
REFS_DIR="$HOME/.config/opencode/references"
MANIFEST="$SKILLS_DIR/.addy-skills"

CURATED=(
    spec-driven-development
    planning-and-task-breakdown
    incremental-implementation
    test-driven-development
    debugging-and-error-recovery
    code-review-and-quality
    code-simplification
    frontend-ui-engineering
    git-workflow-and-versioning
    security-and-hardening
)

usage() {
    cat <<'EOF'
Usage: scripts/install-addy-skills.sh [options]

Options:
  --dry-run          Show what would be copied; change nothing.
  --yes, -y          Do not ask before replacing skills installed by this script.
  --all              Install every skill in the pinned repository.
  --skill <id>       Install one extra skill (repeatable).
  --list             Clone the pinned commit and list available skills.
  -h, --help         Show this help.

The pin is updated manually after reviewing the upstream changes. This script
never touches ~/.config/opencode/AGENTS.md.
EOF
}

DRY_RUN=0
ASSUME_YES=0
INSTALL_ALL=0
LIST_ONLY=0
EXTRA=()

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --yes|-y) ASSUME_YES=1 ;;
        --all) INSTALL_ALL=1 ;;
        --skill)
            [[ -n "${2:-}" ]] || die "--skill needs an ID."
            EXTRA+=("$2")
            shift
            ;;
        --list) LIST_ONLY=1 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

tmp=""
cleanup() { if [[ -n "$tmp" ]]; then rm -rf -- "$tmp"; fi; }
trap cleanup EXIT

clone_pin() {
    tmp="$(mktemp -d)"
    log "Cloning Addy skills at $ADDY_COMMIT"
    run git clone --filter=blob:none --no-checkout "$ADDY_REPO" "$tmp/repo"
    if (( DRY_RUN )); then
        return 0
    fi
    git -C "$tmp/repo" fetch --depth 1 origin "$ADDY_COMMIT"
    git -C "$tmp/repo" checkout --detach FETCH_HEAD
}

main() {
    require_cmd git
    clone_pin

    if (( DRY_RUN )); then
        info "Dry run: would install from $ADDY_REPO at $ADDY_COMMIT."
        info "Curated: ${CURATED[*]}"
        if (( INSTALL_ALL )); then
            info "All skills requested."
        fi
        return 0
    fi

    local repo="$tmp/repo"
    local -a available=()
    mapfile -t available < <(find "$repo/skills" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

    if (( LIST_ONLY )); then
        printf '%s\n' "${available[@]}"
        return 0
    fi

    local -a selected=("${CURATED[@]}" "${EXTRA[@]}")
    if (( INSTALL_ALL )); then
        selected=("${available[@]}")
    fi

    # De-duplicate while keeping order.
    local -a unique=()
    local skill
    for skill in "${selected[@]}"; do
        [[ " ${unique[*]} " == *" $skill "* ]] || unique+=("$skill")
    done

    if ((${#unique[@]} == 0)); then
        die "No skills selected."
    fi

    for skill in "${unique[@]}"; do
        [[ -f "$repo/skills/$skill/SKILL.md" ]] || die "Skill not found in pinned commit: $skill"
    done

    mkdir -p -- "$SKILLS_DIR" "$REFS_DIR"

    # Remove only directories this script installed previously.
    if [[ -f "$MANIFEST" ]]; then
        local old
        while IFS= read -r old; do
            [[ -n "$old" ]] || continue
            if [[ " ${unique[*]} " == *" $old "* ]]; then
                continue
            fi
            local stale="$SKILLS_DIR/$old"
            if [[ -d "$stale" ]]; then
                rm -rf -- "$stale"
            fi
        done <"$MANIFEST"
    fi

    if ! (( ASSUME_YES )); then
        log "Installing ${#unique[@]} skill(s) into ${SKILLS_DIR/#$HOME/~}:"
        info "${unique[*]}"
        confirm "Continue?" || die "Aborted; nothing was changed."
    fi

    for skill in "${unique[@]}"; do
        rm -rf -- "${SKILLS_DIR:?}/$skill"
        cp -a -- "$repo/skills/$skill" "$SKILLS_DIR/$skill"
    done

    # Skills reference ../../references, so keep the shared files beside them.
    cp -a -- "$repo/references/." "$REFS_DIR/"

    printf '%s\n' "${unique[@]}" >"$MANIFEST"
    log "Installed ${#unique[@]} Addy skill(s)."
    info "Update the pin in scripts/install-addy-skills.sh after reviewing upstream."
}

main "$@"
