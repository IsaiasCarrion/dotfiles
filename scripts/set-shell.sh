#!/usr/bin/env bash
# scripts/set-shell.sh — make Bash the login shell of the invoking user.
#
# Safety rules:
#   * Only the user running the bootstrap (or SUDO_USER) is modified.
#   * Bash must exist and be listed in /etc/shells; it is added there if missing.
#   * Nothing changes when Bash is already the login shell.
#   * The user is told to log out; no session is restarted automatically.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: scripts/set-shell.sh [options]

Options:
  --dry-run   Show what would change; change nothing.
  --yes, -y   Do not ask before changing the login shell.
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

# Print the literal /etc/shells entry that resolves to the given canonical path.
# chsh validates the exact string, so we must reuse the entry as written there
# (Arch lists /bin/bash while `command -v bash` may return /usr/bin/bash).
# /bin/sh may also resolve to bash, so only paths named "bash" are acceptable.
listed_shell() {
    local expected="$1" entry candidate
    [[ -r /etc/shells ]] || return 1

    for candidate in "$expected" /bin/bash /usr/bin/bash; do
        [[ -x "$candidate" ]] || continue
        [[ "$(readlink -f -- "$candidate" 2>/dev/null || true)" == "$expected" ]] || continue
        while IFS= read -r entry; do
            [[ -n "$entry" && "$entry" != \#* ]] || continue
            if [[ "$entry" == "$candidate" ]]; then
                printf '%s\n' "$entry"
                return 0
            fi
        done </etc/shells
    done

    # Fallback: another listed path whose basename is bash (e.g. a custom prefix).
    while IFS= read -r entry; do
        [[ -n "$entry" && "$entry" != \#* ]] || continue
        [[ "$(basename -- "$entry")" == bash ]] || continue
        if [[ "$(readlink -f -- "$entry" 2>/dev/null || true)" == "$expected" ]]; then
            printf '%s\n' "$entry"
            return 0
        fi
    done </etc/shells

    return 1
}

main() {
    require_arch
    require_cmd getent
    require_cmd readlink

    local bash_path bash_real login_shell_path target current_shell
    bash_path="$(readlink -f -- "$(command -v bash)")" || die "Bash was not found."
    bash_real="$bash_path"
    [[ -x "$bash_path" ]] || die "Bash is not executable: $bash_path"

    if (( EUID == 0 )); then
        target="${SUDO_USER:-}"
        if [[ -z "$target" ]]; then
            warn "Running as root without SUDO_USER; skipping the login-shell change."
            return 0
        fi
    else
        target="$(id -un)"
    fi

    current_shell="$(getent passwd "$target" | cut -d: -f7)"
    [[ -n "$current_shell" ]] || die "Could not read the login shell of $target."

    if [[ "$(basename -- "$current_shell")" == "bash" ]]; then
        info "Login shell of $target is already Bash ($current_shell)."
        return 0
    fi

    if login_shell_path="$(listed_shell "$bash_real")"; then
        info "Bash is listed in /etc/shells as $login_shell_path."
    else
        login_shell_path="$bash_real"
        log "Adding $login_shell_path to /etc/shells."
        confirm "Append $login_shell_path to /etc/shells?" ||
            die "Aborted; Bash is not a valid login shell."
        if (( DRY_RUN )); then
            printf '[dry-run] printf %%s\\n %q | sudo tee -a /etc/shells\n' "$login_shell_path"
        else
            printf '%s\n' "$login_shell_path" | sudo_run tee -a /etc/shells >/dev/null
        fi
    fi

    log "Changing the login shell of $target: $current_shell -> $login_shell_path"
    confirm "Change the login shell of $target to Bash?" ||
        die "Aborted; the login shell was not changed."

    if ! sudo_run chsh -s "$login_shell_path" "$target"; then
        die "chsh failed. Change it manually with: chsh -s $login_shell_path $target"
    fi

    info "Login shell updated. Log out and back in (or reboot) to apply it."
}

main "$@"
