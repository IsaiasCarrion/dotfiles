#!/usr/bin/env bash
# scripts/install-obsidian.sh — install Obsidian from the official AppImage.
#
# Detection order (never installs a second copy):
#   1. an existing Flatpak (md.obsidian.Obsidian)
#   2. an existing RPM (obsidian)
#   3. an AppImage already managed in ~/Applications
#   4. an executable named obsidian in PATH
#
# The script never touches ~/.var/app/md.obsidian.Obsidian or any vault.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: scripts/install-obsidian.sh [options]

Options:
  --dry-run   Show what would be installed; change nothing.
  --update    Update the existing installation when it is managed by this
              script, a Flatpak or an RPM.
  -h, --help  Show this help.

The official AppImage is downloaded from
https://github.com/obsidianmd/obsidian-releases/releases (x86_64 and aarch64).
AppImages are stored in ~/Applications, linked from ~/.local/bin/obsidian and
launched through ~/.local/share/applications/obsidian.desktop.
EOF
}

FORCE_UPDATE=0

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --update) FORCE_UPDATE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

APPS_DIR="$HOME/Applications"
APPIMAGE_GLOB="Obsidian-*.AppImage"
LINK="$HOME/.local/bin/obsidian"
DESKTOP_FILE="$HOME/.local/share/applications/obsidian.desktop"
ICON_FILE="$HOME/.local/share/icons/hicolor/512x512/apps/obsidian.png"

flatpak_obsidian() {
    have flatpak || return 1
    flatpak info md.obsidian.Obsidian >/dev/null 2>&1
}

find_any_obsidian() {
    local file
    if have obsidian; then
        command -v obsidian
        return 0
    fi
    for file in "$APPS_DIR"/$APPIMAGE_GLOB; do
        if [[ -x "$file" ]]; then
            printf '%s\n' "$file"
            return 0
        fi
    done
    return 1
}

check_fuse() {
    if [[ ! -e /dev/fuse ]]; then
        die "/dev/fuse is missing; install fuse and fuse-libs before using AppImages."
    fi
    if ! pkg_installed fuse && ! pkg_installed fuse3; then
        warn "Neither fuse nor fuse3 is installed; the AppImage may not launch."
    fi
}

download_latest_appimage() {
    require_cmd curl
    require_cmd jq

    local arch="$1" api tmpdir asset url tag version
    case "$arch" in
        x86_64|amd64) arch="x86_64" ;;
        aarch64|arm64) arch="arm64" ;;
        *) die "Unsupported architecture: $arch (expected x86_64 or aarch64)." ;;
    esac

    api="https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest"
    tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/obsidian.XXXXXX")"

    if ! curl -fsSL --max-time 60 "$api" -o "$tmpdir/release.json"; then
        rm -rf -- "$tmpdir"
        die "Could not read the Obsidian release metadata."
    fi

    if [[ "$arch" == "x86_64" ]]; then
        asset="$(jq -r 'first(.assets[] | select(.name | test("^Obsidian-.*\\.AppImage$")) | select(.name | test("arm64") | not) | .name)' "$tmpdir/release.json")"
    else
        asset="$(jq -r 'first(.assets[] | select(.name | test("^Obsidian-.*-arm64\\.AppImage$")) | .name)' "$tmpdir/release.json")"
    fi

    [[ -n "$asset" ]] || {
        rm -rf -- "$tmpdir"
        die "No ${arch} AppImage found in the latest Obsidian release."
    }
    url="$(jq -r --arg n "$asset" '.assets[] | select(.name==$n) | .browser_download_url' "$tmpdir/release.json")"
    tag="$(jq -r '.tag_name' "$tmpdir/release.json")"
    version="${tag#v}"

    printf '\033[1;34m==>\033[0m Downloading Obsidian %s (%s).\n' "$version" "$arch" >&2
    if ! curl -fL --max-time 600 "$url" -o "$tmpdir/$asset" 2>/dev/null; then
        rm -rf -- "$tmpdir"
        die "Could not download $asset."
    fi
    chmod +x "$tmpdir/$asset"
    printf '%s\t%s\t%s\n' "$tmpdir/$asset" "$version" "$asset"
}

extract_icon() {
    local appimage="$1" tmpdir
    tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/obsidian-icon.XXXXXX")"
    if (cd "$tmpdir" && "$appimage" --appimage-extract 'usr/share/icons/hicolor/512x512/apps/obsidian.png' >/dev/null 2>&1); then
        if [[ -f "$tmpdir/squashfs-root/usr/share/icons/hicolor/512x512/apps/obsidian.png" ]]; then
            mkdir -p "$(dirname -- "$ICON_FILE")"
            cp -- "$tmpdir/squashfs-root/usr/share/icons/hicolor/512x512/apps/obsidian.png" "$ICON_FILE"
        fi
    fi
    rm -rf -- "$tmpdir"
}

write_launcher() {
    mkdir -p "$(dirname -- "$DESKTOP_FILE")"
    cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Obsidian
Exec=$LINK --no-sandbox %U
Terminal=false
Type=Application
Icon=obsidian
StartupWMClass=md.obsidian.Obsidian
Comment=Markdown knowledge base
MimeType=application/pdf;text/markdown;application/x-obsidian-canvas;application/x-obsidian-base;x-scheme-handler/obsidian;
Categories=Office;
EOF
}

install_appimage() {
    if (( DRY_RUN )); then
        info "Would download the latest official Obsidian AppImage for $(uname -m)."
        info "Would install it under ~/Applications/ and refresh the launcher."
        return 0
    fi

    local downloaded tmp_appimage version asset target
    downloaded="$(download_latest_appimage "$(uname -m)")"
    IFS=$'\t' read -r tmp_appimage version asset <<<"$downloaded"

    target="$APPS_DIR/Obsidian-$version.AppImage"

    mkdir -p "$APPS_DIR" "$(dirname -- "$LINK")"
    if [[ -e "$target" ]]; then
        rm -f -- "$target"
    fi
    mv -- "$tmp_appimage" "$target"
    chmod +x "$target"
    rm -rf -- "$(dirname -- "$tmp_appimage")"

    # Retire older AppImages managed by this script, after the new one works.
    local old
    for old in "$APPS_DIR"/$APPIMAGE_GLOB; do
        [[ "$old" == "$target" ]] && continue
        [[ -x "$old" ]] || continue
        info "Removing old managed AppImage: ${old/#$HOME/~}"
        rm -f -- "$old"
    done

    ln -sfn "$target" "$LINK"
    extract_icon "$target"
    write_launcher

    info "Installed: Obsidian $version (${target/#$HOME/~})"
    info "Launch with: ${LINK/#$HOME/~} (or the Obsidian desktop entry)"
    info "Update later with: ./scripts/install-obsidian.sh --update"
}

main() {
    local existing

    if flatpak_obsidian; then
        local version
        version="$(flatpak info md.obsidian.Obsidian 2>/dev/null | awk -F': *' '/^ *Version:/{print $2; exit}')"
        info "Obsidian is already installed as a Flatpak${version:+ ($version)}; skipping to avoid duplicates."
        info "Configuration and vaults in ~/.var/app/md.obsidian.Obsidian are left untouched."
        if (( FORCE_UPDATE )); then
            log "Updating the Flatpak."
            run flatpak update -y md.obsidian.Obsidian
        fi
        return 0
    fi

    if pkg_installed obsidian; then
        info "Obsidian is already installed as an RPM; skipping to avoid duplicates."
        if (( FORCE_UPDATE )); then
            log "Updating the RPM."
            sudo_run dnf upgrade -y obsidian
        fi
        return 0
    fi

    if existing="$(find_any_obsidian)"; then
        info "Obsidian is already available: $existing"
        if (( FORCE_UPDATE )); then
            if [[ "$existing" == "$APPS_DIR"/* ]]; then
                install_appimage
            else
                warn "Refusing to replace an installation not managed by this script: $existing"
            fi
        else
            info "Skipping; run with --update only for AppImages managed in ~/Applications."
        fi
        return 0
    fi

    if (( DRY_RUN )); then
        [[ -e /dev/fuse ]] || warn "/dev/fuse is missing; the AppImage would not launch."
        info "Would download the latest official Obsidian AppImage for $(uname -m)."
        info "Would install it under ~/Applications/ and create the launcher."
        return 0
    fi

    check_fuse
    install_appimage
}

main "$@"
