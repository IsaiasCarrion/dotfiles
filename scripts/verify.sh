#!/usr/bin/env bash
# scripts/verify.sh — read-only checks for this repository and its deployment.
#
# Default: verifies the deployed links and the live Omarchy environment.
# --repo:  verifies only the repository (no HOME links, no installed apps).
# It never modifies files.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: scripts/verify.sh [options]

Options:
  --repo      Check the repository only (safe before deploying anything).
  -h, --help  Show this help.
EOF
}

REPO_ONLY=0

while (($#)); do
    case "$1" in
        --repo) REPO_ONLY=1 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

failures=0
skips=0

fail() {
    warn "$*"
    failures=$((failures + 1))
}

skip() {
    info "skip: $*"
    skips=$((skips + 1))
}

repo_packages() {
    printf '%s\n' bash bash-arch git git-delta opencode
}

deployed_packages() {
    local -a packages=(bash bash-arch git opencode)
    if have delta; then
        packages+=(git-delta)
    fi
    printf '%s\n' "${packages[@]}"
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

check_stow_structure() {
    local pkg file
    while IFS= read -r pkg; do
        if [[ ! -d "$REPO_ROOT/$pkg" ]]; then
            fail "Missing Stow package directory: $pkg"
            continue
        fi
        while IFS= read -r -d '' file; do
            case "$file" in
                *.pre-stow|*.orig|*.bak|*.local|*.pem|*.key|*service.json|*auth.json|*.env|*/.env)
                    fail "File that must not be committed: ${file#"$REPO_ROOT"/}"
                    ;;
            esac
        done < <(find "$REPO_ROOT/$pkg" \( -type f -o -type l \) -print0)
    done < <(repo_packages)
    info "Stow package structure checked."
}

check_stow_simulation() {
    if ! have stow; then
        skip "stow is not installed; cannot run 'stow --simulate'."
        return
    fi

    local -a packages=()
    local target output temp=""

    if (( REPO_ONLY )); then
        mapfile -t packages < <(repo_packages)
        temp="$(mktemp -d)"
        target="$temp"
    else
        mapfile -t packages < <(deployed_packages)
        target="$HOME"
    fi

    if ! output="$(cd -- "$REPO_ROOT" && stow -n -v -t "$target" "${packages[@]}" 2>&1)"; then
        [[ -n "$temp" ]] && rm -rf -- "$temp"
        fail "Stow simulation failed:"
        printf '%s\n' "$output" >&2
        return
    fi
    [[ -n "$temp" ]] && rm -rf -- "$temp"

    output="$(printf '%s\n' "$output" | sed '/^WARNING: in simulation mode so not modifying filesystem\.$/d')"

    if (( REPO_ONLY )); then
        if ! grep -q '^LINK:' <<<"$output"; then
            fail "Stow simulation created no links; check .stowrc and the package layout."
        elif grep -Eq 'existing target|cannot stow|conflict' <<<"$output"; then
            fail "Stow simulation reports an internal conflict:"
            printf '%s\n' "$output" >&2
        else
            info "Stow simulation is clean in an empty HOME."
        fi
    elif [[ -n "$output" ]]; then
        fail "Stow simulation shows pending changes:"
        printf '%s\n' "$output" >&2
    else
        info "Stow deployment is complete and clean."
    fi
}

check_omarchy() {
    if ! is_omarchy; then
        skip "this is not an Omarchy system."
        return
    fi

    info "Omarchy $(omarchy_version)"

    if [[ -n "${OMARCHY_PATH:-}" && -d "$OMARCHY_PATH" ]]; then
        info "OMARCHY_PATH=$OMARCHY_PATH"
    else
        fail "OMARCHY_PATH is not set or does not exist."
    fi

    local config="$HOME/.config/ghostty/config"
    if [[ -L "$config" ]] && [[ "$(readlink -f -- "$config")" == "$REPO_ROOT"/* ]]; then
        fail "~/.config/ghostty/config is a Stow link into this repo; Omarchy must own it."
    else
        info "~/.config/ghostty/config is not managed by Stow."
    fi

    if grep -qE '^[[:space:]]*theme[[:space:]]*=' "$config" 2>/dev/null; then
        fail "~/.config/ghostty/config sets a static theme; Omarchy must provide it."
    fi

    if grep -q 'omarchy/current/theme/ghostty.conf' "$config" 2>/dev/null; then
        info "Ghostty uses Omarchy's dynamic theme file."
    else
        fail "Ghostty config does not reference Omarchy's dynamic theme."
    fi

    local theme_file="$HOME/.local/state/omarchy/current/theme/ghostty.conf"
    if [[ -r "$theme_file" ]]; then
        info "Current Omarchy theme file: ${theme_file/#$HOME/~}"
    else
        fail "Missing Omarchy theme file: ${theme_file/#$HOME/~}"
    fi

    if have ghostty; then
        if ghostty +validate-config >/dev/null 2>&1; then
            info "Ghostty config is valid."
        else
            fail "Ghostty rejected its config (run: ghostty +validate-config)."
        fi

        local effective theme
        if effective="$(ghostty +show-config --no-pager 2>/dev/null)"; then
            theme="$(printf '%s\n' "$effective" | sed -n 's/^theme = //p' | head -n1 || true)"
            if [[ -z "$theme" ]]; then
                info "Ghostty has no static theme; colors come from Omarchy."
            else
                fail "Ghostty effective theme is '$theme'; expected Omarchy's dynamic theme."
            fi
        else
            skip "could not read the effective Ghostty configuration."
        fi
    else
        skip "ghostty is not installed."
    fi

    # The repository must not ship a Ghostty config or palette.
    if [[ -e "$REPO_ROOT/ghostty" ]]; then
        fail "The repository still contains a ghostty/ package."
    fi
    local hits
    hits="$(grep -RInE '^[[:space:]]*(background|foreground|palette|cursor-color|selection-background|selection-foreground|theme|window-theme)[[:space:]]*=' \
        "$REPO_ROOT/assets/ghostty" 2>/dev/null || true)"
    if [[ -n "$hits" ]]; then
        fail "assets/ghostty contains theme/color keys; only personal preferences are allowed."
        printf '%s\n' "$hits" >&2
    else
        info "Repository contains no Ghostty theme or color definitions."
    fi
}

check_shell_config() {
    local file="$REPO_ROOT/bash/.bashrc" count

    count="$(grep -cE '^[[:space:]]*(source|\.)[[:space:]]+"?\$OMARCHY_PATH/default/bash/rc' "$file" || true)"
    if [[ "$count" == 1 ]]; then
        info "Personal .bashrc loads Omarchy's rc exactly once."
    else
        fail "Personal .bashrc loads Omarchy's rc $count time(s) (expected 1)."
    fi

    for init in 'starship init bash' 'zoxide init bash' 'fzf --bash'; do
        if grep -qF "$init" "$file"; then
            fail "Personal .bashrc duplicates Omarchy initialization: $init"
        fi
    done

    if grep -qF 'default/bash/env-bootstrap' "$file"; then
        info "Personal .bashrc loads Omarchy's environment bootstrap."
    else
        fail "Personal .bashrc does not load Omarchy's env-bootstrap."
    fi

    if grep -qE '\.bashrc' "$REPO_ROOT/bash/.bash_profile"; then
        info ".bash_profile loads .bashrc."
    else
        fail ".bash_profile does not load .bashrc."
    fi
}

check_mise_tools() {
    if ! is_omarchy; then
        skip "not an Omarchy system; mise-provided tools not checked."
        return
    fi

    local tool pkg
    for tool in gh opencode uv; do
        omarchy_mise_tool "$tool" || continue

        case "$tool" in
            gh) pkg="github-cli" ;;
            *)  pkg="$tool" ;;
        esac
        if pkg_installed "$pkg"; then
            warn "both pacman ($pkg) and mise provide '$tool'; remove one to avoid shadowing."
        fi

        if have "$tool"; then
            info "Omarchy mise tool available: $tool ($(command -v "$tool"))"
        else
            fail "Omarchy declares '$tool' through mise, but its command is not on PATH."
        fi
    done
}

check_starship() {
    if ! have starship; then
        skip "starship is not installed."
        return
    fi
    info "Starship is provided by Omarchy; no repository config is deployed."
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        info "~/.config/starship.toml exists (Omarchy-managed or local)."
    else
        skip "~/.config/starship.toml is missing; Omarchy usually provides it."
    fi
}

check_git() {
    local file="$REPO_ROOT/git/.gitconfig"
    if git config -f "$file" --list >/dev/null 2>&1; then
        info "Git config is syntactically valid."
    else
        fail "Invalid Git config: ${file#"$REPO_ROOT"/}"
    fi

    if git config -f "$file" --get user.email >/dev/null 2>&1; then
        fail "git/.gitconfig hardcodes user identity; keep it in Omarchy's config or ~/.gitconfig.local."
    else
        info "Git identity is not hardcoded in the repository."
    fi
}

check_apps() {
    local pkg
    local -a apps=()
    mapfile -t apps < <(manifest_packages "$REPO_ROOT/packages/apps.txt")

    for pkg in "${apps[@]}"; do
        if pkg_installed "$pkg"; then
            if omarchy_mise_tool "$pkg"; then
                warn "both pacman and mise provide '$pkg'; consider removing the pacman package to avoid shadowing."
            fi
            info "application installed: $pkg (pacman)"
        elif omarchy_mise_tool "$pkg" && have "$pkg"; then
            info "application provided by Omarchy via mise: $pkg"
        elif have "$pkg"; then
            info "application available on PATH: $pkg"
        else
            fail "Required application is not installed: $pkg"
        fi
    done

    local version
    if have opencode; then
        version="$(opencode --version 2>/dev/null | head -n1 || true)"
        info "OpenCode: ${version:-unknown}"
    fi
    if have zeditor; then
        version="$(zeditor --version 2>/dev/null | head -n1 || true)"
        info "Zed: ${version:-unknown}"
    elif have zed; then
        version="$(zed --version 2>/dev/null | head -n1 || true)"
        info "Zed: ${version:-unknown}"
    fi
}

check_system() {
    local pretty pacman_version user login_shell

    pretty="$(os_release_field PRETTY_NAME || true)"
    if [[ -n "$pretty" ]]; then
        info "system: $pretty"
    else
        fail "Could not read /etc/os-release."
    fi

    if have pacman; then
        pacman_version="$(pacman --version 2>/dev/null | grep -m1 . || true)"
        info "$pacman_version"
    else
        fail "pacman is not available."
    fi

    user="$(id -un)"
    login_shell="$(getent passwd "$user" | cut -d: -f7)"
    if [[ "$(basename -- "$login_shell")" == "bash" ]]; then
        info "login shell of $user is Bash ($login_shell)."
    else
        fail "login shell of $user is $login_shell; Omarchy expects Bash."
    fi

    if have gh; then
        if gh auth status >/dev/null 2>&1; then
            info "GitHub CLI is authenticated."
        else
            warn "GitHub CLI is installed but not authenticated; run: gh auth login"
        fi
    else
        skip "GitHub CLI (gh) is not on PATH."
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
    check_jsonc "$REPO_ROOT/opencode/.config/opencode/opencode.jsonc"
    check_jsonc "$REPO_ROOT/opencode/.config/opencode/dcp.jsonc"
    check_jsonc "$REPO_ROOT/opencode/.config/opencode/opencode.omniroute.example.jsonc"

    # Omarchy ships a minimal opencode.json (update disabled). OpenCode merges
    # global config.json -> opencode.json -> opencode.jsonc, so the repo's jsonc
    # layers on top without replacing Omarchy's file.
    local omarchy_config="$HOME/.config/opencode/opencode.json"
    if [[ -f "$omarchy_config" ]]; then
        if grep -q '"update"[[:space:]]*:[[:space:]]*"disable"' "$omarchy_config"; then
            info "Omarchy's opencode.json disables self-updates."
        else
            warn "Omarchy's opencode.json exists but does not disable updates."
        fi
    else
        skip "Omarchy's ~/.config/opencode/opencode.json is not present."
    fi

    if ! have opencode; then
        skip "OpenCode CLI not found; skipping the plugin check."
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

check_links() {
    check_link "$HOME/.bashrc" "$REPO_ROOT/bash/.bashrc"
    check_link "$HOME/.bash_profile" "$REPO_ROOT/bash/.bash_profile"
    check_link "$HOME/.gitconfig" "$REPO_ROOT/git/.gitconfig"
    check_link "$HOME/.gitignore_global" "$REPO_ROOT/git/.gitignore_global"
    check_link "$HOME/.config/bash/pacman.sh" "$REPO_ROOT/bash-arch/.config/bash/pacman.sh"
    check_link "$HOME/.config/opencode/opencode.jsonc" "$REPO_ROOT/opencode/.config/opencode/opencode.jsonc"
    check_link "$HOME/.config/opencode/AGENTS.md" "$REPO_ROOT/opencode/.config/opencode/AGENTS.md"
    check_link "$HOME/.config/opencode/dcp.jsonc" "$REPO_ROOT/opencode/.config/opencode/dcp.jsonc"
    check_link "$HOME/.config/opencode/opencode.omniroute.example.jsonc" "$REPO_ROOT/opencode/.config/opencode/opencode.omniroute.example.jsonc"

    if have delta; then
        check_link "$HOME/.config/git/delta.gitconfig" "$REPO_ROOT/git-delta/.config/git/delta.gitconfig"
    fi
}

main() {
    log "Verifying dotfiles ($([[ "$REPO_ONLY" == 1 ]] && echo 'repository only' || echo 'deployed'))."

    check_syntax
    check_stow_structure
    check_stow_simulation
    check_shell_config
    check_git
    check_secrets
    check_opencode
    check_mise_tools

    if (( REPO_ONLY )); then
        check_omarchy
        log "Repository checks finished."
    else
        check_system
        check_omarchy
        check_starship
        check_apps
        check_links
        log "Deployment checks finished."
    fi

    if (( failures > 0 )); then
        die "Verification finished with $failures problem(s) and $skips skipped check(s)."
    fi
    log "All executed checks passed ($skips skipped)."
}

main "$@"
