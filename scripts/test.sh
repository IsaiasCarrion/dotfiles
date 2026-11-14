#!/usr/bin/env bash
# scripts/test.sh — offline repository tests.
#
# Safe by design: it never deploys into the real $HOME. Every deployment test
# uses a throwaway HOME under mktemp. It may download GNU Stow into that temp
# directory when stow is not installed, so the real system is left untouched.
#
# Checks: Bash syntax, ShellCheck (if present), JSONC, package manifests,
# Stow structure and simulation, real/backup/dry-run deployment in temp HOMEs,
# idempotence, and the Ghostty personal-preferences script.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

TMPROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")"
cleanup() { rm -rf -- "$TMPROOT"; }
trap cleanup EXIT

PASS=0
FAIL=0
SKIP=0

ok()   { PASS=$((PASS + 1)); printf '  [ok]   %s\n' "$*"; }
bad()  { FAIL=$((FAIL + 1)); printf '  [fail] %s\n' "$*"; }
skipped() { SKIP=$((SKIP + 1)); printf '  [skip] %s\n' "$*"; }

assert_file() {
    if [[ -f "$1" ]]; then ok "$2"; else bad "$2"; fi
}

assert_no_path() {
    if [[ ! -e "$1" && ! -L "$1" ]]; then ok "$2"; else bad "$2"; fi
}

assert_link_to() {
    if [[ -L "$1" && "$(readlink -f -- "$1")" == "$2" ]]; then
        ok "$3"
    else
        bad "$3"
    fi
}

section() { printf '\n== %s ==\n' "$*"; }

jsonc_valid() {
    python3 - "$1" <<'PY'
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
}

ensure_stow() {
    if have stow; then
        ok "stow is available: $(stow --version | head -n1)"
        return 0
    fi

    local archive="$TMPROOT/stow.tar.gz" dir prefix
    if ! curl -fsSL --max-time 60 https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz -o "$archive"; then
        skipped "stow is not installed and could not be downloaded."
        return 1
    fi
    if ! tar -xzf "$archive" -C "$TMPROOT"; then
        skipped "could not extract GNU Stow."
        return 1
    fi
    dir="$(find "$TMPROOT" -mindepth 1 -maxdepth 1 -type d -name 'stow-*' | head -n1)"
    prefix="$TMPROOT/stow-prefix"
    if [[ -z "$dir" || ! -x "$dir/configure" ]] || ! have make || ! have perl; then
        skipped "GNU Stow needs configure, make and perl to run from a temporary prefix."
        return 1
    fi
    if ! (cd -- "$dir" && ./configure --prefix="$prefix" >/dev/null 2>&1 && make install >/dev/null 2>&1); then
        skipped "could not build GNU Stow in the temporary directory."
        return 1
    fi
    export PATH="$prefix/bin:$PATH"
    ok "using temporary GNU Stow: $(stow --version | head -n1)"
}

section "Bash syntax"
while IFS= read -r file; do
    if bash -n "$file"; then
        ok "syntax: ${file#"$REPO_ROOT"/}"
    else
        bad "syntax: ${file#"$REPO_ROOT"/}"
    fi
done < <(
    printf '%s\n' "$REPO_ROOT/bootstrap.sh"
    find "$REPO_ROOT/scripts" -maxdepth 1 -name '*.sh' -type f | sort
    printf '%s\n' "$REPO_ROOT/bash/.bashrc" "$REPO_ROOT/bash/.bash_profile" \
        "$REPO_ROOT/bash-arch/.config/bash/pacman.sh"
)

section "ShellCheck"
if have shellcheck; then
    if shellcheck -x "$REPO_ROOT/bootstrap.sh" "$REPO_ROOT"/scripts/*.sh; then
        ok "shellcheck passed."
    else
        bad "shellcheck reported problems."
    fi
else
    skipped "shellcheck is not installed (not added as a dependency)."
fi

section "JSONC"
for file in "$REPO_ROOT"/opencode/.config/opencode/*.jsonc; do
    if jsonc_valid "$file"; then
        ok "JSONC: ${file#"$REPO_ROOT"/}"
    else
        bad "JSONC: ${file#"$REPO_ROOT"/}"
    fi
done

section "Package manifests"
declare -A seen=()
duplicates=0
for manifest in "$REPO_ROOT"/packages/*.txt; do
    while IFS= read -r pkg; do
        [[ -n "$pkg" ]] || continue
        if [[ -n "${seen[$pkg]:-}" ]]; then
            bad "duplicate package '$pkg' in ${manifest##*/} and ${seen[$pkg]}"
            duplicates=$((duplicates + 1))
        else
            seen[$pkg]="$manifest"
        fi
        [[ "$pkg" =~ ^[a-z0-9@._+-]+$ ]] || bad "suspicious package name: $pkg"
    done < <(manifest_packages "$manifest")
done
(( duplicates == 0 )) && ok "no duplicate package names across manifests."

if have pacman; then
    missing=0
    for pkg in "${!seen[@]}"; do
        if ! pkg_available "$pkg"; then
            bad "package not available in official repositories: $pkg"
            missing=$((missing + 1))
        fi
    done
    (( missing == 0 )) && ok "all manifest packages exist in the official repositories."
else
    skipped "pacman is not available; package availability not checked."
fi

section "Omarchy mise-provided tools"
if is_omarchy && [[ -r "$OMARCHY_MISE_CONFIG" ]]; then
    for tool in gh opencode uv; do
        if omarchy_mise_tool "$tool"; then
            ok "Omarchy declares '$tool' through mise."
        else
            bad "expected Omarchy to declare '$tool' through mise."
        fi
    done
    if plan="$("$REPO_ROOT/scripts/install-packages.sh" --dry-run 2>&1)"; then
        if grep -Eq 'Installing [0-9]+ required package\(s\):.*\b(opencode|uv|gh|node)\b' <<<"$plan"; then
            bad "the installer would duplicate a mise-provided tool via pacman."
            printf '%s\n' "$plan" | sed 's/^/    /' >&2
        else
            ok "the installer does not duplicate mise-provided tools."
        fi
    else
        bad "install-packages.sh --dry-run failed."
        printf '%s\n' "$plan" | sed 's/^/    /' >&2
    fi
else
    skipped "Omarchy/mise configuration not found; mise checks not executed."
fi

section "Repository invariants"
if grep -q '^--no-folding$' "$REPO_ROOT/.stowrc"; then
    ok ".stowrc uses --no-folding."
else
    bad ".stowrc does not use --no-folding."
fi

if grep -RInE --exclude=test.sh '^[^#]*stow[[:space:]].*--adopt' \
    "$REPO_ROOT/scripts" "$REPO_ROOT/bootstrap.sh" >/dev/null 2>&1; then
    bad "a script uses stow --adopt."
else
    ok "no script uses stow --adopt."
fi

assert_no_path "$REPO_ROOT/ghostty" "no ghostty Stow package."
assert_file "$REPO_ROOT/assets/ghostty/personal.conf" "personal Ghostty fragment exists."

if grep -Eq '^[[:space:]]*(background|foreground|palette|cursor-color|selection-background|selection-foreground|theme|window-theme)[[:space:]]*=' \
    "$REPO_ROOT/assets/ghostty/personal.conf"; then
    bad "the personal Ghostty fragment defines theme/color keys."
else
    ok "the personal Ghostty fragment has no theme/color keys."
fi

if grep -RInE --exclude=test.sh 'dnf|COPR|Fedora|CachyOS|DMS|niri' \
    "$REPO_ROOT/scripts" "$REPO_ROOT/packages" "$REPO_ROOT/bootstrap.sh" >/dev/null 2>&1; then
    bad "obsolete Fedora/CachyOS/DMS reference in executable content."
else
    ok "no obsolete distribution/desktop references in scripts or packages."
fi

section "Git and secrets"
if git -C "$REPO_ROOT" config -f "$REPO_ROOT/git/.gitconfig" --list >/dev/null 2>&1; then
    ok "git/.gitconfig is valid."
else
    bad "git/.gitconfig is invalid."
fi
if git -C "$REPO_ROOT" config -f "$REPO_ROOT/git/.gitconfig" --get user.email >/dev/null 2>&1; then
    bad "git/.gitconfig hardcodes user.email."
else
    ok "git/.gitconfig does not hardcode identity."
fi

section "Stow simulation"
if ensure_stow; then
    sim_home="$TMPROOT/sim-home"
    mkdir -p "$sim_home"
    if sim_out="$(cd -- "$REPO_ROOT" && stow -n -v -t "$sim_home" bash bash-arch git git-delta opencode 2>&1)"; then
        if grep -q '^LINK:' <<<"$sim_out" && ! grep -Eq 'existing target|cannot stow|conflict' <<<"$sim_out"; then
            ok "stow --simulate links the packages in an empty HOME."
        else
            bad "stow --simulate output was unexpected."
            printf '%s\n' "$sim_out" >&2
        fi
    else
        bad "stow --simulate failed."
        printf '%s\n' "$sim_out" >&2
    fi
else
    skipped "stow simulation not executed."
fi

section "Deployment in a temporary HOME"
if have stow; then
    dep_home="$TMPROOT/deploy-home"
    mkdir -p "$dep_home"
    if HOME="$dep_home" DOTFILES_BACKUP_ROOT="$TMPROOT/backups" \
        "$REPO_ROOT/scripts/deploy-dotfiles.sh" --yes >"$TMPROOT/deploy.log" 2>&1; then
        ok "deploy-dotfiles.sh completed in a temporary HOME."
    else
        bad "deploy-dotfiles.sh failed in a temporary HOME."
        sed 's/^/    /' "$TMPROOT/deploy.log" >&2
    fi

    assert_link_to "$dep_home/.bashrc" "$REPO_ROOT/bash/.bashrc" "temporary ~/.bashrc links to the repo."
    assert_link_to "$dep_home/.gitconfig" "$REPO_ROOT/git/.gitconfig" "temporary ~/.gitconfig links to the repo."
    assert_link_to "$dep_home/.config/opencode/opencode.jsonc" \
        "$REPO_ROOT/opencode/.config/opencode/opencode.jsonc" "temporary OpenCode config is linked."
    assert_no_path "$dep_home/.config/ghostty/config" "Ghostty config is not deployed."
    assert_no_path "$dep_home/.config/starship.toml" "Starship config is not deployed."

    if HOME="$dep_home" DOTFILES_BACKUP_ROOT="$TMPROOT/backups" \
        "$REPO_ROOT/scripts/deploy-dotfiles.sh" --yes >"$TMPROOT/deploy2.log" 2>&1 &&
        ! grep -q '^LINK:' "$TMPROOT/deploy2.log"; then
        ok "second deployment is idempotent (no new links)."
    else
        bad "second deployment was not idempotent."
        sed 's/^/    /' "$TMPROOT/deploy2.log" >&2
    fi
else
    skipped "deployment test not executed."
fi

section "Conflict backup in a temporary HOME"
if have stow; then
    conf_home="$TMPROOT/conflict-home"
    mkdir -p "$conf_home"
    printf 'sentinel-bashrc\n' >"$conf_home/.bashrc"
    if HOME="$conf_home" DOTFILES_BACKUP_ROOT="$TMPROOT/backups-conflict" \
        "$REPO_ROOT/scripts/deploy-dotfiles.sh" --yes >"$TMPROOT/conflict.log" 2>&1; then
        ok "deployment with a conflict completed."
    else
        bad "deployment with a conflict failed."
        sed 's/^/    /' "$TMPROOT/conflict.log" >&2
    fi
    assert_link_to "$conf_home/.bashrc" "$REPO_ROOT/bash/.bashrc" "conflicting ~/.bashrc was replaced by a link."
    backup_file="$(find "$TMPROOT/backups-conflict" -type f -name .bashrc | head -n1)"
    if [[ -n "$backup_file" && "$(cat -- "$backup_file")" == "sentinel-bashrc" ]]; then
        ok "conflicting file was backed up intact."
    else
        bad "conflicting file was not backed up correctly."
    fi
else
    skipped "conflict test not executed."
fi

section "Dry-run safety"
if have stow; then
    dry_home="$TMPROOT/dry-home"
    mkdir -p "$dry_home"
    printf 'sentinel-dry\n' >"$dry_home/.bashrc"
    if HOME="$dry_home" DOTFILES_BACKUP_ROOT="$TMPROOT/backups-dry" \
        "$REPO_ROOT/scripts/deploy-dotfiles.sh" --dry-run >"$TMPROOT/dry.log" 2>&1; then
        ok "dry-run completed with exit 0."
    else
        bad "dry-run failed."
    fi
    if [[ "$(cat -- "$dry_home/.bashrc")" == "sentinel-dry" && ! -L "$dry_home/.bashrc" ]]; then
        ok "dry-run did not touch the existing file."
    else
        bad "dry-run modified the existing file."
    fi
    assert_no_path "$TMPROOT/backups-dry" "dry-run created no backup directory."
else
    skipped "dry-run test not executed."
fi

section "Ghostty personal preferences"
if have ghostty; then
    ghost_home="$TMPROOT/ghostty-home"
    mkdir -p "$ghost_home/.config/ghostty"
    cp /usr/share/omarchy/config/ghostty/config "$ghost_home/.config/ghostty/config"
    before_theme="$(grep '^config-file = .*current/theme/ghostty.conf' "$ghost_home/.config/ghostty/config")"

    if HOME="$ghost_home" DOTFILES_BACKUP_ROOT="$TMPROOT/backups-ghostty" \
        "$REPO_ROOT/scripts/ghostty-personal.sh" --yes >"$TMPROOT/ghostty.log" 2>&1; then
        ok "ghostty-personal.sh applied preferences in a temporary HOME."
    else
        bad "ghostty-personal.sh failed."
        sed 's/^/    /' "$TMPROOT/ghostty.log" >&2
    fi

    if grep -q 'dotfiles: preferencias personales' "$ghost_home/.config/ghostty/config"; then
        ok "personal block was added."
    else
        bad "personal block was not added."
    fi
    if [[ "$(grep '^config-file = .*current/theme/ghostty.conf' "$ghost_home/.config/ghostty/config")" == "$before_theme" ]]; then
        ok "Omarchy's dynamic theme line was preserved."
    else
        bad "Omarchy's dynamic theme line changed."
    fi

    hash1="$(sha256sum "$ghost_home/.config/ghostty/config" | awk '{print $1}')"
    HOME="$ghost_home" DOTFILES_BACKUP_ROOT="$TMPROOT/backups-ghostty" \
        "$REPO_ROOT/scripts/ghostty-personal.sh" --yes >"$TMPROOT/ghostty2.log" 2>&1 || true
    hash2="$(sha256sum "$ghost_home/.config/ghostty/config" | awk '{print $1}')"
    if [[ "$hash1" == "$hash2" ]]; then
        ok "ghostty-personal.sh is idempotent."
    else
        bad "ghostty-personal.sh changed the file on the second run."
    fi

    if HOME="$ghost_home" DOTFILES_BACKUP_ROOT="$TMPROOT/backups-ghostty" \
        "$REPO_ROOT/scripts/ghostty-personal.sh" --yes --remove >"$TMPROOT/ghostty3.log" 2>&1; then
        if ! grep -q 'dotfiles: preferencias personales' "$ghost_home/.config/ghostty/config"; then
            ok "--remove cleaned the personal block."
        else
            bad "--remove left the personal block behind."
        fi
    else
        bad "--remove failed."
    fi
else
    skipped "ghostty is not installed; personal-preferences test not executed."
fi

section "Repository-only verification"
if "$REPO_ROOT/scripts/verify.sh" --repo >"$TMPROOT/verify.log" 2>&1; then
    ok "verify.sh --repo passed."
else
    bad "verify.sh --repo failed."
    sed 's/^/    /' "$TMPROOT/verify.log" >&2
fi

printf '\n== Summary ==\n'
printf 'passed: %d, failed: %d, skipped: %d\n' "$PASS" "$FAIL" "$SKIP"
if (( FAIL > 0 )); then
    exit 1
fi
