#!/usr/bin/env bash
# scripts/install-multimedia.sh — enable RPM Fusion and install the full codecs.
#
# Optional module. Fedora ships free codecs by default; the packages installed
# here come from RPM Fusion and replace some Fedora builds (ffmpeg-free).

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: scripts/install-multimedia.sh [options]

Options:
  --dry-run   Show what would be installed; change nothing.
  --yes, -y   Do not ask for confirmation.
  -h, --help  Show this help.

Enables RPM Fusion Free/Nonfree when missing and installs the GStreamer
codecs plus FFmpeg (replacing ffmpeg-free with --allowerasing).
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

releasever() { rpm -E %fedora; }

ensure_rpmfusion() {
    local rel="$1"
    if pkg_installed rpmfusion-free-release; then
        info "RPM Fusion Free is already enabled."
    else
        log "Installing RPM Fusion Free for Fedora $rel."
        sudo_run dnf install -y \
            "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${rel}.noarch.rpm"
    fi

    if pkg_installed rpmfusion-nonfree-release; then
        info "RPM Fusion Nonfree is already enabled."
    else
        log "Installing RPM Fusion Nonfree for Fedora $rel."
        sudo_run dnf install -y \
            "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${rel}.noarch.rpm"
    fi
}

main() {
    require_fedora
    require_cmd dnf
    require_cmd rpm

    local rel packages=(
        gstreamer1-plugins-good
        gstreamer1-plugins-bad-free
        gstreamer1-plugins-bad-freeworld
        gstreamer1-plugins-ugly
        gstreamer1-plugin-openh264
        mozilla-openh264
    )

    ensure_rpmfusion "$(releasever)"

    local pkg
    local -a missing=()
    for pkg in "${packages[@]}"; do
        pkg_installed "$pkg" || missing+=("$pkg")
    done

    if ((${#missing[@]} == 0)) && pkg_installed ffmpeg; then
        info "All multimedia packages are already installed."
        return 0
    fi

    log "Installing multimedia packages (FFmpeg replaces ffmpeg-free)."
    sudo_run dnf install -y --allowerasing -- "${missing[@]}" ffmpeg
    info "Verify with: ffmpeg -version && gst-inspect-1.0 | head"
}

main "$@"
