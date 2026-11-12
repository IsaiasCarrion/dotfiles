#!/usr/bin/env bash
# scripts/deploy-dotfiles.sh — deploy the Stow packages into $HOME.
#
# Safety rules:
#   * Never uses `stow --adopt`.
#   * Existing real files are moved to ~/.dotfiles-backup/<timestamp>/ (not deleted).
#   * Symlinks that point somewhere other than this repository are treated as
#     conflicts and are backed up instead of overwritten.
#   * DMS-managed files are never stowed or edited.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: scripts/deploy-dotfiles.sh [options]

Options:
  --dry-run   Show the conflicts and the Stow simulation; change nothing.
  --yes, -y   Do not ask before moving conflicting files to the backup folder.
  -h, --help  Show this help.
EOF
}

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --yes|-y) ASSUME_YES=1 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

main() {
    if ! have stow; then
        if (( DRY_RUN )); then
            warn "stow is not installed; skipping the Stow simulation (the package step would install it)."
        else
            die "stow is not installed; run: sudo pacman -S stow"
        fi
    fi

    local -a packages=(bash bash-arch git ghostty opencode starship)
    local pkg

    for pkg in "${packages[@]}"; do
        [[ -d "$REPO_ROOT/$pkg" ]] || die "Missing Stow package directory: $pkg"
    done

    if have delta; then
        packages+=(git-delta)
    else
        warn "delta is not installed; skipping the git-delta package."
    fi

    local -a conflicts=()
    local file rel target resolved expected

    for pkg in "${packages[@]}"; do
        while IFS= read -r -d '' file; do
            rel="${file#"$REPO_ROOT/$pkg"/}"
            target="$HOME/$rel"

            if [[ -L "$target" ]]; then
                resolved="$(readlink -f -- "$target" || true)"
                expected="$(readlink -f -- "$file" || true)"
                if [[ "$resolved" == "$expected" ]]; then
                    continue
                fi
                conflicts+=("$target")
            elif [[ -e "$target" ]]; then
                resolved="$(readlink -f -- "$target" || true)"
                expected="$(readlink -f -- "$file" || true)"
                if [[ "$resolved" == "$expected" ]]; then
                    warn "Skipping ${target/#$HOME/~}: it reaches the repo through a symlinked directory; run 'stow -D' for the old package first."
                    continue
                fi
                conflicts+=("$target")
            fi
        done < <(find "$REPO_ROOT/$pkg" -type f -print0)
    done

    if ((${#conflicts[@]})); then
        log "Existing files/symlinks that Stow would conflict with:"
        local item
        for item in "${conflicts[@]}"; do
            info "${item/#$HOME/~}"
        done

        if (( DRY_RUN )); then
            info "Dry run: these files would be moved to $BACKUP_ROOT/<timestamp>/."
        else
            confirm "Move ${#conflicts[@]} conflicting file(s) to the backup folder and continue?" ||
                die "Aborted; nothing was changed."
        fi

        local stamp backup_dir dest
        stamp="$(timestamp)"
        backup_dir="$BACKUP_ROOT/$stamp"
        # Two runs in the same second must not share (and truncate) a backup.
        if [[ -e "$backup_dir" ]]; then
            backup_dir="$BACKUP_ROOT/$stamp-$$"
        fi

        if (( DRY_RUN )); then
            info "Dry run: would create $backup_dir."
        else
            mkdir -p -- "$backup_dir"
            : >"$backup_dir/manifest.txt"
            for item in "${conflicts[@]}"; do
                rel="${item#"$HOME"/}"
                dest="$backup_dir/$rel"
                mkdir -p -- "$(dirname -- "$dest")"
                mv -- "$item" "$dest"
                printf '%s -> %s\n' "$item" "$dest" >>"$backup_dir/manifest.txt"
                info "Moved ${item/#$HOME/~} to ${dest/#$HOME/~}"
            done
            ln -sfn -- "$backup_dir" "$BACKUP_ROOT/LATEST"
            info "Backup: $backup_dir"
        fi
    else
        info "No conflicting files found."
    fi

    log "Deploying Stow packages: ${packages[*]}"
    cd -- "$REPO_ROOT" || die "Could not enter the repository: $REPO_ROOT"

    if ! have stow; then
        info "Dry run: would run stow -v -t \"$HOME\" ${packages[*]}"
        log "Deployment step finished (simulation only)."
        return 0
    fi

    if (( DRY_RUN )); then
        if ! stow -n -v -t "$HOME" "${packages[@]}"; then
            if ((${#conflicts[@]})); then
                info "Dry run: Stow stopped at the conflicts listed above; a real run backs them up first."
            else
                die "Stow simulation failed; review the output above."
            fi
        fi
    else
        stow -v -t "$HOME" "${packages[@]}" || die "Stow failed; review the output above."
    fi

    # DMS owns ~/.config/ghostty/themes/dankcolors. Provide a fallback only when
    # DMS has not generated it yet; never overwrite the managed file.
    local theme="$HOME/.config/ghostty/themes/dankcolors"
    if [[ -e "$theme" || -L "$theme" ]]; then
        info "DMS Ghostty theme present; leaving it untouched."
    else
        log "Installing the Ghostty fallback theme (DMS will replace it later)."
        run install -Dm644 "$REPO_ROOT/assets/ghostty/dankcolors" "$theme"
    fi

    log "Deployment step finished."
}

main "$@"
