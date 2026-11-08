#!/usr/bin/env bash
# scripts/diagnose-system.sh — read-only Fedora desktop diagnostics.
#
# Reports the state of DNF5, updates, firmware, Secure Boot, NVIDIA, Flatpak,
# FUSE/AppImage, containers, SSH/GitHub, NetBird/CIFS, Bluetooth, Zed and
# Obsidian. It never installs, enables or edits anything.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: scripts/diagnose-system.sh [options]

Options:
  -h, --help  Show this help.

The script only reads the system. It may query DNF and fwupd metadata over the
network, but it does not change packages, services or configuration.
EOF
}

while (($#)); do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

ok()   { printf '  [ok]   %s\n' "$*"; }
warnc(){ printf '  [warn] %s\n' "$*"; }
note() { printf '  [info] %s\n' "$*"; }
section() { printf '\n== %s ==\n' "$*"; }

has_pkg() { pkg_installed "$1"; }

main() {
    require_fedora

    section "Sistema"
    note "$(cat /etc/fedora-release)"
    note "kernel: $(uname -r) ($(uname -m))"
    local dnf_version
    dnf_version="$(dnf --version 2>/dev/null || true)"
    if grep -q '^dnf5' <<<"$dnf_version"; then
        ok "DNF5: $(head -n1 <<<"$dnf_version")"
    else
        warnc "DNF5 not detected (Fedora 45 expects dnf5)."
    fi

    section "DNF5 y rendimiento"
    note "max_parallel_downloads: $(grep -E '^max_parallel_downloads' /etc/dnf/dnf.conf 2>/dev/null | cut -d= -f2 || echo 'default')"
    note "keepcache: $(grep -E '^keepcache' /etc/dnf/dnf.conf 2>/dev/null | cut -d= -f2 || echo 'default')"

    section "Actualizaciones y reinicio"
    local updates
    updates="$( { timeout 120 dnf -q check-upgrade 2>/dev/null || true; } | wc -l )"
    if (( updates > 0 )); then
        warnc "$updates package update(s) available (run: sudo dnf upgrade --refresh)"
    else
        ok "No package updates reported."
    fi

    if [[ -e /run/reboot-required ]]; then
        warnc "Reboot required (/run/reboot-required exists)."
    elif have needs-restarting && ! needs-restarting -r >/dev/null 2>&1; then
        warnc "Reboot required (needs-restarting -r)."
    else
        local running newest
        running="$(uname -r)"
        newest="$(rpm -q kernel --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' 2>/dev/null | sort -V | tail -n1)"
        if [[ -n "$newest" && "$running" != "$newest" ]]; then
            warnc "Running kernel $running differs from the newest installed kernel $newest."
        else
            ok "No pending reboot detected."
        fi
    fi

    section "RPM Fusion y multimedia"
    local enabled
    enabled="$( { dnf repolist --enabled 2>/dev/null || true; } | awk '{print $1}' )"
    if grep -qx rpmfusion-free <<<"$enabled"; then
        ok "RPM Fusion Free enabled."
    else
        warnc "RPM Fusion Free is not enabled."
    fi
    if grep -qx rpmfusion-nonfree <<<"$enabled"; then
        ok "RPM Fusion Nonfree enabled."
    else
        warnc "RPM Fusion Nonfree is not enabled."
    fi
    if has_pkg ffmpeg && ! has_pkg ffmpeg-free; then
        ok "Full FFmpeg (RPM Fusion) installed."
    elif has_pkg ffmpeg; then
        warnc "ffmpeg is installed alongside ffmpeg-free; check the provider."
    else
        warnc "ffmpeg is not installed."
    fi
    for p in gstreamer1-plugins-bad-freeworld gstreamer1-plugins-ugly; do
        has_pkg "$p" && ok "$p installed." || warnc "$p is missing."
    done

    section "Firmware (fwupd)"
    if has_pkg fwupd; then
        ok "fwupd: $(fwupdmgr --version 2>/dev/null | awk '/org.freedesktop.fwupd/{print $NF; exit}')"
        systemctl is-active fwupd >/dev/null 2>&1 && ok "fwupd service active." || warnc "fwupd service is not active."
        note "Check updates manually: sudo fwupdmgr refresh --force && sudo fwupdmgr get-updates"
    else
        warnc "fwupd is not installed."
    fi

    section "Secure Boot y NVIDIA"
    if have mokutil; then
        note "$(mokutil --sb-state 2>&1 | head -n1)"
    else
        warnc "mokutil not installed; cannot read Secure Boot state."
    fi
    local nvidia_gpu nvidia_driver
    nvidia_gpu="$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | grep -i nvidia || true)"
    nvidia_driver="$(rpm -qa 2>/dev/null | grep -E '^(kmod-nvidia|nvidia-driver|akmod-nvidia)' || true)"
    if [[ -n "$nvidia_gpu" ]]; then
        note "NVIDIA GPU: $(cut -d: -f3 <<<"$nvidia_gpu" | sed 's/^ //' | head -n1)"
        [[ -n "$nvidia_driver" ]] && ok "NVIDIA driver: $(tr '\n' ' ' <<<"$nvidia_driver")" || warnc "NVIDIA GPU present but no RPM Fusion driver installed."
        lsmod 2>/dev/null | grep -q '^nvidia' && ok "nvidia kernel module loaded." || note "nvidia module not loaded (normal without the driver)."
    else
        note "No NVIDIA GPU detected."
    fi

    section "Flatpak"
    if have flatpak; then
        ok "Flatpak: $(flatpak --version 2>/dev/null)"
        flatpak remotes --columns=name,url 2>/dev/null | sed 's/^/    /'
        note "$(flatpak list --app --columns=application 2>/dev/null | wc -l) Flatpak application(s) installed."
    else
        warnc "Flatpak is not installed."
    fi

    section "FUSE y AppImage"
    [[ -e /dev/fuse ]] && ok "/dev/fuse present." || warnc "/dev/fuse is missing."
    for p in fuse fuse3 fuse-libs; do
        has_pkg "$p" && ok "$p installed." || note "$p not installed."
    done
    local appimages
    appimages="$( { find "$HOME/Applications" -maxdepth 1 -name '*.AppImage' -type f 2>/dev/null || true; } | wc -l )"
    note "$appimages AppImage(s) in ~/Applications."

    section "Contenedores"
    if has_pkg podman; then
        ok "Podman (rootless preferred): $(podman --version 2>/dev/null)"
    else
        note "Podman is not installed."
    fi
    if has_pkg docker-ce; then
        note "Docker CE: $(docker --version 2>/dev/null)"
        systemctl is-active docker >/dev/null 2>&1 && ok "docker service active." || note "docker service not active."
    else
        note "Docker CE is not installed (optional)."
    fi

    section "SSH y GitHub"
    if systemctl is-active sshd >/dev/null 2>&1; then
        warnc "sshd is active; confirm that remote access is intended."
    else
        ok "sshd is inactive."
    fi
    [[ -f /etc/ssh/ssh_host_ed25519_key ]] && note "SSH host keys exist." || note "No SSH host keys generated (normal if sshd never ran)."
    if have gh; then
        gh auth status 2>&1 | sed 's/^/    /' || true
    else
        note "GitHub CLI (gh) is not installed."
    fi

    section "NetBird, CIFS y SMB"
    if have netbird; then
        ok "NetBird: $(netbird version 2>/dev/null | head -n1)"
        netbird status >/dev/null 2>&1 && note "NetBird daemon reachable (not joining automatically)." || note "NetBird installed but not connected."
    else
        note "NetBird is not installed (optional module)."
    fi
    have mount.cifs && ok "mount.cifs available." || warnc "mount.cifs missing (install cifs-utils)."
    have smbclient && ok "smbclient available." || warnc "smbclient missing (install samba-client)."

    section "Bluetooth"
    if has_pkg bluez; then
        systemctl is-active bluetooth >/dev/null 2>&1 && ok "bluetooth service active." || warnc "bluetooth service is not active."
        if have rfkill; then
            note "rfkill: $(rfkill list bluetooth 2>/dev/null | tr '\n' ' ' || echo 'no adapter reported')"
        fi
        if have bluetoothctl; then
            note "Controllers: $(bluetoothctl list 2>/dev/null | tr '\n' ' ' || echo 'none')"
        fi
    else
        warnc "bluez is not installed."
    fi

    section "Zed y Obsidian"
    if have zed; then
        ok "Zed: $(zed --version 2>/dev/null | head -n1)"
    else
        warnc "Zed not found in PATH."
    fi
    if have flatpak && flatpak info md.obsidian.Obsidian >/dev/null 2>&1; then
        ok "Obsidian (Flatpak): $(flatpak info md.obsidian.Obsidian 2>/dev/null | awk -F': *' '/Version:/{print $2; exit}')"
    elif have obsidian; then
        ok "Obsidian: $(command -v obsidian)"
    else
        warnc "Obsidian not found (Flatpak or AppImage)."
    fi

    printf '\nDiagnostics finished (read-only).\n'
}

main "$@"
