#!/usr/bin/env bash
# scripts/verify.sh — read-only checks for the deployed configuration.
#
# Checks Stow links, shell syntax, JSONC validity, Ghostty/niri configuration,
# OpenCode's plugin view, and accidental secrets. It never modifies files.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: scripts/verify.sh [options]

Options:
  -h, --help  Show this help.
EOF
}

while (($#)); do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

failures=0

fail() {
    warn "$*"
    failures=$((failures + 1))
}

check_link() {
    local target="$1" expected="$2" resolved
    if [[ ! -L "$target" ]]; then
        fail "Not a symlink: ${target/#$HOME/~}"
        return
    fi
    resolved="$(readlink -f -- "$target" || true)"
    if [[ "$resolved" != "$expected" ]]; then
        fail "Wrong link target: ${target/#$HOME/~} -> ${resolved:-<broken>}"
        return
    fi
    info "link OK: ${target/#$HOME/~}"
}

check_jsonc() {
    local file="$1"
    [[ -f "$file" ]] || {
        fail "Missing JSONC file: ${file/#$HOME/~}"
        return
    }

    if python3 - "$file" <<'PY'
import json
import re
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    source = handle.read()

out = []
i = 0
n = len(source)
in_string = False
escaped = False

while i < n:
    char = source[i]
    if in_string:
        out.append(char)
        if escaped:
            escaped = False
        elif char == "\\":
            escaped = True
        elif char == '"':
            in_string = False
        i += 1
        continue

    if char == '"':
        in_string = True
        out.append(char)
        i += 1
        continue

    if char == "/" and i + 1 < n and source[i + 1] == "/":
        while i < n and source[i] != "\n":
            i += 1
        continue

    if char == "/" and i + 1 < n and source[i + 1] == "*":
        i += 2
        while i + 1 < n and not (source[i] == "*" and source[i + 1] == "/"):
            i += 1
        i += 2
        continue

    out.append(char)
    i += 1

text = "".join(out)
text = re.sub(r",(\s*[}\]])", r"\1", text)
json.loads(text)
PY
    then
        info "JSONC OK: ${file/#$HOME/~}"
    else
        fail "Invalid JSONC: ${file/#$HOME/~}"
    fi
}

check_stow() {
    if ! have stow; then
        fail "stow is not installed; cannot verify links."
        return
    fi

    local -a packages=(bash bash-dnf git ghostty opencode)
    if have delta; then
        packages+=(git-delta)
    fi

    local output
    if ! output="$(cd -- "$REPO_ROOT" && stow -n -v -t "$HOME" "${packages[@]}" 2>&1)"; then
        fail "Stow simulation failed:"
        printf '%s\n' "$output" >&2
        return
    fi

    # Stow always prints this notice on stderr in simulation mode.
    output="$(printf '%s\n' "$output" | sed '/^WARNING: in simulation mode so not modifying filesystem\.$/d')"

    if [[ -n "$output" ]]; then
        fail "Stow simulation shows pending changes:"
        printf '%s\n' "$output" >&2
    else
        info "Stow simulation is clean."
    fi
}

check_shell() {
    local file
    for file in \
        "$REPO_ROOT/bash/.bashrc" \
        "$REPO_ROOT/bash-dnf/.config/bash/dnf.sh"; do
        if bash -n "$file"; then
            info "syntax OK: ${file#"$REPO_ROOT"/}"
        else
            fail "Bash syntax error: ${file#"$REPO_ROOT"/}"
        fi
    done
}

check_ghostty() {
    if ! have ghostty; then
        info "ghostty not installed; skipping config validation."
        return
    fi
    if ghostty +validate-config >/dev/null 2>&1; then
        info "Ghostty config is valid."
    else
        fail "Ghostty reported an invalid config (run: ghostty +validate-config)."
    fi
}

check_niri() {
    if ! have niri; then
        info "niri not installed; skipping config validation."
        return
    fi
    if [[ ! -f "$HOME/.config/niri/config.kdl" ]]; then
        info "No niri config found; skipping."
        return
    fi
    if niri validate -c "$HOME/.config/niri/config.kdl" >/dev/null 2>&1; then
        info "niri config is valid."
    else
        fail "niri reported an invalid config (run: niri validate -c ~/.config/niri/config.kdl)."
    fi
}

check_secrets() {
    local files hits
    files="$(find "$REPO_ROOT" -path "$REPO_ROOT/.git" -prune -o -type f \
        \( -name service.json -o -name auth.json -o -name .env -o -name id_rsa -o -name '*.pem' \) -print)"
    if [[ -n "$files" ]]; then
        fail "Sensitive file(s) inside the repository:"
        printf '%s\n' "$files" >&2
    else
        info "No service.json/auth.json/.env/private keys inside the repository."
    fi

    if git -C "$REPO_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        # --untracked also scans files that are new but not committed yet; ignored
        # files (service.json, .env, keys) stay out of the scan by design.
        hits="$(git -C "$REPO_ROOT" grep --untracked -nEI \
            '(sk-[A-Za-z0-9]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|"password"[[:space:]]*:[[:space:]]*"[^"]+")' \
            -- . 2>/dev/null || true)"
        if [[ -n "$hits" ]]; then
            fail "Possible secret in versioned files:"
            printf '%s\n' "$hits" >&2
        else
            info "No obvious secrets in versioned files."
        fi
    fi
}

check_opencode() {
    local cli output
    cli="$(opencode_cmd)" || {
        warn "OpenCode CLI not found; skipping plugin check."
        return
    }

    if ! output="$("$cli" plugin list 2>&1)"; then
        warn "Could not list OpenCode plugins:"
        printf '%s\n' "$output" | sed -n '1,6p' | sed 's/^/    /' >&2
        return
    fi

    printf '%s\n' "$output" | sed 's/^/    /'
    if grep -q 'opencode-dcp' <<<"$output"; then
        info "DCP plugin is visible to OpenCode."
    else
        warn "opencode-dcp is not listed yet; it will be fetched on first start."
    fi
}

main() {
    log "Verifying deployed dotfiles."

    check_stow
    check_shell
    check_ghostty
    check_niri
    check_jsonc "$HOME/.config/opencode/opencode.jsonc"
    check_jsonc "$HOME/.config/opencode/dcp.jsonc"
    check_jsonc "$HOME/.config/opencode/opencode.omniroute.example.jsonc"

    check_link "$HOME/.bashrc" "$REPO_ROOT/bash/.bashrc"
    check_link "$HOME/.gitconfig" "$REPO_ROOT/git/.gitconfig"
    check_link "$HOME/.gitignore_global" "$REPO_ROOT/git/.gitignore_global"
    check_link "$HOME/.config/bash/dnf.sh" "$REPO_ROOT/bash-dnf/.config/bash/dnf.sh"
    check_link "$HOME/.config/ghostty/config" "$REPO_ROOT/ghostty/.config/ghostty/config"
    check_link "$HOME/.config/opencode/opencode.jsonc" "$REPO_ROOT/opencode/.config/opencode/opencode.jsonc"
    check_link "$HOME/.config/opencode/AGENTS.md" "$REPO_ROOT/opencode/.config/opencode/AGENTS.md"
    check_link "$HOME/.config/opencode/dcp.jsonc" "$REPO_ROOT/opencode/.config/opencode/dcp.jsonc"
    check_link "$HOME/.config/opencode/opencode.omniroute.example.jsonc" "$REPO_ROOT/opencode/.config/opencode/opencode.omniroute.example.jsonc"

    check_secrets
    check_opencode

    if (( failures > 0 )); then
        die "Verification finished with $failures problem(s)."
    fi
    log "All checks passed."
}

main "$@"
