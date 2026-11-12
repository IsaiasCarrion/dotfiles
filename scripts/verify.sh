#!/usr/bin/env bash
# scripts/verify.sh — read-only checks for the deployed configuration.
#
# Checks Stow links, shell syntax, JSONC validity, Starship, Ghostty, the
# login shell, required applications, and accidental secrets.
# It never modifies files.

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

stow_packages() {
    local -a packages=(bash bash-arch git ghostty opencode starship)
    if have delta; then
        packages+=(git-delta)
    fi
    printf '%s\n' "${packages[@]}"
}

check_stow() {
    if ! have stow; then
        fail "stow is not installed; cannot verify links."
        return
    fi

    local -a packages=()
    mapfile -t packages < <(stow_packages)

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

check_syntax() {
    local file
    for file in \
        "$REPO_ROOT/bootstrap.sh" \
        "$REPO_ROOT"/scripts/*.sh \
        "$REPO_ROOT/bash/.bashrc" \
        "$REPO_ROOT/bash/.bash_profile" \
        "$REPO_ROOT/bash-arch/.config/bash/pacman.sh"; do
        if bash -n "$file"; then
            info "syntax OK: ${file#"$REPO_ROOT"/}"
        else
            fail "Bash syntax error: ${file#"$REPO_ROOT"/}"
        fi
    done
}

check_initializers() {
    local file="$REPO_ROOT/bash/.bashrc" count

    count="$(grep -cF 'eval "$(starship init bash)"' "$file" || true)"
    if [[ "$count" == 1 ]]; then
        info "Starship initialization is present exactly once."
    else
        fail "Starship initialization found $count time(s) in bash/.bashrc (expected 1)."
    fi

    count="$(grep -cF 'eval "$(zoxide init bash)"' "$file" || true)"
    if [[ "$count" == 1 ]]; then
        info "zoxide initialization is present exactly once."
    else
        fail "zoxide initialization found $count time(s) in bash/.bashrc (expected 1)."
    fi
}

check_starship() {
    local config="$HOME/.config/starship.toml"

    if have starship; then
        info "starship executable: $(starship --version | head -n1)"
        if starship prompt --status 0 >/dev/null 2>&1; then
            info "Starship renders the prompt."
        else
            fail "starship is installed but failed to render the prompt."
        fi
    else
        fail "starship is not installed."
    fi

    if [[ ! -f "$config" ]]; then
        fail "Missing Starship config: ${config/#$HOME/~}"
    elif python3 - "$config" <<'PY'
import sys
import tomllib

with open(sys.argv[1], "rb") as handle:
    tomllib.load(handle)
PY
    then
        info "Starship config is valid TOML: ${config/#$HOME/~}"
    else
        fail "Invalid Starship TOML: ${config/#$HOME/~}"
    fi
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
        info "niri config is valid (managed by the desktop, not this repo)."
    else
        fail "niri reported an invalid config (run: niri validate -c ~/.config/niri/config.kdl)."
    fi
}

check_apps() {
    local pkg
    local -a apps=()
    mapfile -t apps < <(manifest_packages "$REPO_ROOT/packages/apps.txt")

    for pkg in "${apps[@]}"; do
        if pkg_installed "$pkg"; then
            info "application installed: $pkg"
        else
            fail "Required application is not installed: $pkg"
        fi
    done

    have opencode && info "OpenCode: $(opencode --version 2>/dev/null | head -n1)"
    have zed && info "Zed: $(zed --version 2>/dev/null | head -n1)"
}

check_system() {
    local pretty pacman_version user login_shell bash_path shell_real login_real

    pretty="$(os_release_field PRETTY_NAME || true)"
    if [[ -n "$pretty" ]]; then
        info "system: $pretty"
    else
        fail "Could not read /etc/os-release."
    fi

    if have pacman; then
        pacman_version="$(pacman --version 2>/dev/null | head -n1)"
        info "$pacman_version"
    else
        fail "pacman is not available."
    fi

    user="$(id -un)"
    login_shell="$(getent passwd "$user" | cut -d: -f7)"
    if [[ "$(basename -- "$login_shell")" == "bash" ]]; then
        info "login shell of $user is Bash ($login_shell)."
    else
        fail "login shell of $user is $login_shell; run ./scripts/set-shell.sh."
    fi

    if [[ -n "${SHELL:-}" ]]; then
        shell_real="$(readlink -f -- "$SHELL" 2>/dev/null || true)"
        login_real="$(readlink -f -- "$login_shell" 2>/dev/null || true)"
        if [[ -n "$shell_real" && -n "$login_real" && "$shell_real" != "$login_real" ]]; then
            warn "This session uses SHELL=$SHELL; log out and back in to load the login shell."
        fi
    fi

    bash_path="$(readlink -f -- "$(command -v bash)")"
    local entry listed=0
    while IFS= read -r entry; do
        [[ -n "$entry" && "$entry" != \#* ]] || continue
        if [[ "$(readlink -f -- "$entry" 2>/dev/null || true)" == "$bash_path" ]]; then
            listed=1
            break
        fi
    done </etc/shells 2>/dev/null || true

    if (( listed )); then
        info "Bash is listed in /etc/shells."
    else
        fail "Bash is not listed in /etc/shells; run ./scripts/set-shell.sh."
    fi

    if have gh; then
        if gh auth status >/dev/null 2>&1; then
            info "GitHub CLI is authenticated."
        else
            warn "GitHub CLI is installed but not authenticated; run: gh auth login"
        fi
    else
        fail "GitHub CLI (gh) is not installed."
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
    if ! have opencode; then
        warn "OpenCode CLI not found; skipping the plugin check."
        return
    fi

    info "OpenCode CLI: $(opencode --version 2>/dev/null | head -n1)"

    local output
    if ! output="$(opencode plugin list 2>&1)"; then
        warn "Could not list OpenCode plugins (it may need network/first start):"
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

check_shell_config() {
    if [[ -d "$HOME/.config/fish" ]]; then
        warn "$HOME/.config/fish exists and is preserved (not managed); Bash is the supported shell."
    fi

    if [[ ! -f "$HOME/.bash_profile" ]]; then
        fail "Missing $HOME/.bash_profile (login shells would not load ~/.bashrc)."
    elif ! grep -qE '\.bashrc' "$HOME/.bash_profile"; then
        fail "$HOME/.bash_profile does not source ~/.bashrc."
    else
        info "$HOME/.bash_profile loads ~/.bashrc."
    fi
}

main() {
    log "Verifying deployed dotfiles."

    check_system
    check_syntax
    check_stow
    check_initializers
    check_starship
    check_ghostty
    check_niri
    check_apps
    check_shell_config
    check_jsonc "$HOME/.config/opencode/opencode.jsonc"
    check_jsonc "$HOME/.config/opencode/dcp.jsonc"
    check_jsonc "$HOME/.config/opencode/opencode.omniroute.example.jsonc"
    check_secrets
    check_opencode

    check_link "$HOME/.bashrc" "$REPO_ROOT/bash/.bashrc"
    check_link "$HOME/.bash_profile" "$REPO_ROOT/bash/.bash_profile"
    check_link "$HOME/.gitconfig" "$REPO_ROOT/git/.gitconfig"
    check_link "$HOME/.gitignore_global" "$REPO_ROOT/git/.gitignore_global"
    check_link "$HOME/.config/bash/pacman.sh" "$REPO_ROOT/bash-arch/.config/bash/pacman.sh"
    check_link "$HOME/.config/ghostty/config" "$REPO_ROOT/ghostty/.config/ghostty/config"
    check_link "$HOME/.config/starship.toml" "$REPO_ROOT/starship/.config/starship.toml"
    check_link "$HOME/.config/opencode/opencode.jsonc" "$REPO_ROOT/opencode/.config/opencode/opencode.jsonc"
    check_link "$HOME/.config/opencode/AGENTS.md" "$REPO_ROOT/opencode/.config/opencode/AGENTS.md"
    check_link "$HOME/.config/opencode/dcp.jsonc" "$REPO_ROOT/opencode/.config/opencode/dcp.jsonc"
    check_link "$HOME/.config/opencode/opencode.omniroute.example.jsonc" "$REPO_ROOT/opencode/.config/opencode/opencode.omniroute.example.jsonc"

    if have delta; then
        check_link "$HOME/.config/git/delta.gitconfig" "$REPO_ROOT/git-delta/.config/git/delta.gitconfig"
    fi

    if (( failures > 0 )); then
        die "Verification finished with $failures problem(s)."
    fi
    log "All checks passed."
}

main "$@"
