#!/usr/bin/env bash
# scripts/ghostty-personal.sh — apply personal Ghostty preferences on Omarchy.
#
# Omarchy owns ~/.config/ghostty/config and generates the theme from
# ~/.local/state/omarchy/current/theme/ghostty.conf. This script never replaces
# that file: it appends (or refreshes) one marked block with personal,
# non-theme preferences. Colors and theme keys are rejected.
#
# It is NOT run by bootstrap.sh. Run it later, after the Stow deployment.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

START_MARK='# >>> dotfiles: preferencias personales (no tocar el tema de Omarchy) >>>'
END_MARK='# <<< dotfiles: preferencias personales <<<'

usage() {
    cat <<'EOF'
Usage: scripts/ghostty-personal.sh [options]

Options:
  --dry-run   Show the resulting diff; change nothing.
  --yes, -y   Do not ask before editing ~/.config/ghostty/config.
  --remove    Remove the personal block and restore the Omarchy config.
  -h, --help  Show this help.

The theme is always Omarchy's: ~/.local/state/omarchy/current/theme/ghostty.conf
EOF
}

REMOVE=0

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --yes|-y) ASSUME_YES=1 ;;
        --remove) REMOVE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

FRAGMENT="$REPO_ROOT/assets/ghostty/personal.conf"
CONFIG="${GHOSTTY_CONFIG:-$HOME/.config/ghostty/config}"
TMPFILE=""

# Keys that belong to the theme. Refuse to manage them here.
FORBIDDEN_RE='^[[:space:]]*(background|foreground|palette|cursor-color|selection-background|selection-foreground|theme|window-theme|background-opacity|background-blur-radius|unfocused-split-fill|unfocused-split-opacity)[[:space:]]*='

main() {
    [[ -f "$CONFIG" ]] || die "Missing $CONFIG. Omarchy should provide it; run: omarchy refresh config ghostty/config"

    if (( ! REMOVE )); then
        [[ -r "$FRAGMENT" ]] || die "Missing preferences fragment: $FRAGMENT"
        if grep -Eq "$FORBIDDEN_RE" "$FRAGMENT"; then
            die "The personal fragment contains theme/color keys. Fix it before applying."
        fi
    fi

    local current filtered desired
    current="$(cat -- "$CONFIG")"

    filtered="$(
        printf '%s\n' "$current" | awk -v s="$START_MARK" -v e="$END_MARK" '
            $0 == s { skip = 1; next }
            $0 == e { skip = 0; next }
            !skip { print }
        '
    )"

    if (( REMOVE )); then
        desired="$filtered"
    else
        desired="${filtered%$'\n'}"$'\n\n'"$START_MARK"$'\n'"$(cat -- "$FRAGMENT")"$'\n'"$END_MARK"
    fi

    if [[ "$desired" == "$current" ]]; then
        info "Ghostty already has the current personal preferences; nothing to do."
        return 0
    fi

    TMPFILE="$(mktemp "${TMPDIR:-/tmp}/ghostty-config.XXXXXX")"
    trap 'rm -f -- "${TMPFILE:-}"' EXIT
    printf '%s\n' "$desired" >"$TMPFILE"

    if (( DRY_RUN )); then
        printf '[dry-run] diff -u %q %q\n' "$CONFIG" "$TMPFILE"
        diff -u --label "$CONFIG" --label "$CONFIG (propuesto)" "$CONFIG" "$TMPFILE" || true
        return 0
    fi

    confirm "Update $CONFIG with the personal Ghostty preferences?" || die "Aborted; nothing was changed."

    local stamp backup_dir
    stamp="$(timestamp)"
    backup_dir="$BACKUP_ROOT/ghostty-${stamp}"
    [[ -e "$backup_dir" ]] && backup_dir="$BACKUP_ROOT/ghostty-${stamp}-$$"

    mkdir -p -- "$backup_dir"
    cp -a -- "$CONFIG" "$backup_dir/config"
    printf '%s -> %s\n' "$CONFIG" "$backup_dir/config" >"$backup_dir/manifest.txt"
    ln -sfn -- "$backup_dir" "$BACKUP_ROOT/ghostty-LATEST"

    cat -- "$TMPFILE" >"$CONFIG"

    if have ghostty; then
        if ghostty +validate-config >/dev/null 2>&1; then
            info "Ghostty config is valid."
        else
            warn "Ghostty rejected the result; restoring the backup."
            cp -a -- "$backup_dir/config" "$CONFIG"
            die "Restored $CONFIG from $backup_dir/config."
        fi
    fi

    info "Applied personal preferences; theme is still Omarchy's."
    info "Backup: $backup_dir"
}

main "$@"
