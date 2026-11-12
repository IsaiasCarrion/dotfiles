#!/usr/bin/env bash
# scripts/diagnose-system.sh — read-only CachyOS/Arch diagnostics.
#
# Reports packages, updates, kernel/reboot, firmware, Secure Boot, NVIDIA,
# Flatpak, FUSE/AppImage, containers, SSH/GitHub, NetBird/CIFS, Bluetooth,
# the login shell and the managed applications.
# It never installs, enables or edits anything.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: scripts/diagnose-system.sh [options]

Options:
  -h, --help  Show this help.

The script only reads the system. It may query package metadata over the
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

ok()    { printf '  [ok]   %s\n' "$*"; }
warnc() { printf '  [warn] %s\n' "$*"; }
note()  { printf '  [info] %s\n' "$*"; }
section() { printf '\n== %s ==\n' "$*"; }

main() {
    require_arch

    section "Sistema"
    note "$(os_release_field PRETTY_NAME || echo 'unknown')"
    note "kernel: $(uname -r) ($(uname -m))"
    note "$(pacman --version | head -n1)"
    note "installed packages: $(pacman -Qq | wc -l)"

    section "Actualizaciones y reinicio"
    local updates
    if have checkupdates; then
        updates="$( { checkupdates 2>/dev/null || true; } | wc -l )"
    else
        updates="$( { pacman -Qu 2>/dev/null || true; } | wc -l )"
    fi
    if (( updates > 0 )); then
        warnc "$updates package update(s) available (run: sudo pacman -Syu)"
    else
        ok "No package updates reported."
    fi

    local running newest
    running="$(uname -r)"
    newest="$(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -V | tail -n1)"
    if [[ -n "$newest" && "$running" != "$newest" ]]; then
        warnc "Running kernel $running differs from the newest installed kernel $newest."
    else
        ok "No pending kernel reboot detected."
    fi

    section "Firmware (fwupd)"
    if pkg_installed fwupd; then
        ok "fwupd: $(fwupdmgr --version 2>/dev/null | awk '/org.freedesktop.fwupd/{print $NF; exit}')"
        systemctl is-active fwupd >/dev/null 2>&1 && ok "fwupd service active." || warnc "fwupd service is not active."
        note "Check updates manually: sudo fwupdmgr refresh --force && sudo fwupdmgr get-updates"
    else
        warnc "fwupd is not installed (optional)."
    fi

    section "Secure Boot y NVIDIA"
    if have mokutil; then
        note "$(mokutil --sb-state 2>&1 | head -n1)"
    else
        warnc "mokutil not installed; cannot read Secure Boot state."
    fi
    local nvidia_gpu nvidia_driver
    nvidia_gpu="$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | grep -i nvidia || true)"
    nvidia_driver="$(pacman -Qq 2>/dev/null | grep -E '^(nvidia|nvidia-open|nvidia-dkms|nvidia-open-dkms)$' || true)"
    if [[ -n "$nvidia_gpu" ]]; then
        note "NVIDIA GPU: $(cut -d: -f3 <<<"$nvidia_gpu" | sed 's/^ //' | head -n1)"
        [[ -n "$nvidia_driver" ]] && ok "NVIDIA driver: $(tr '\n' ' ' <<<"$nvidia_driver")" || warnc "NVIDIA GPU present but no NVIDIA driver installed."
        lsmod 2>/dev/null | grep -q '^nvidia' && ok "nvidia kernel module loaded." || note "nvidia module not loaded."
    else
        note "No NVIDIA GPU detected."
    fi

    section "Flatpak y AppImage"
    if have flatpak; then
        ok "Flatpak: $(flatpak --version 2>/dev/null)"
        note "$(flatpak list --app --columns=application 2>/dev/null | wc -l) Flatpak application(s) installed."
    else
        note "Flatpak is not installed (optional)."
    fi
    [[ -e /dev/fuse ]] && ok "/dev/fuse present." || warnc "/dev/fuse is missing; AppImages will not launch."
    for p in fuse2 fuse3; do
        pkg_installed "$p" && ok "$p installed." || note "$p not installed."
    done
    local appimages
    appimages="$( { find "$HOME/Applications" -maxdepth 1 -name '*.AppImage' -type f 2>/dev/null || true; } | wc -l )"
    note "$appimages AppImage(s) in ~/Applications."

    section "Contenedores"
    if pkg_installed podman; then
        ok "Podman: $(podman --version 2>/dev/null)"
    else
        note "Podman is not installed."
    fi
    if pkg_installed docker; then
        note "Docker: $(docker --version 2>/dev/null)"
        systemctl is-active docker >/dev/null 2>&1 && ok "docker service active." || note "docker service not active."
    else
        note "Docker is not installed (optional)."
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
        netbird status >/dev/null 2>&1 && note "NetBird daemon reachable." || note "NetBird installed but not connected."
    else
        note "NetBird is not installed (optional)."
    fi
    have mount.cifs && ok "mount.cifs available." || warnc "mount.cifs missing (install cifs-utils)."
    have smbclient && ok "smbclient available." || warnc "smbclient missing (install smbclient)."

    section "Bluetooth"
    if pkg_installed bluez; then
        systemctl is-active bluetooth >/dev/null 2>&1 && ok "bluetooth service active." || warnc "bluetooth service is not active."
        have rfkill && note "rfkill: $(rfkill list bluetooth 2>/dev/null | tr '\n' ' ' || echo 'no adapter reported')"
        have bluetoothctl && note "Controllers: $(bluetoothctl list 2>/dev/null | tr '\n' ' ' || echo 'none')"
    else
        warnc "bluez is not installed."
    fi

    section "Shell"
    local user login_shell
    user="$(id -un)"
    login_shell="$(getent passwd "$user" | cut -d: -f7)"
    note "login shell of $user: ${login_shell:-unknown}"
    if [[ "$(basename -- "$login_shell")" == "bash" ]]; then
        ok "Bash is the login shell: $(bash --version | head -n1)"
    else
        warnc "Bash is not the login shell; run ./scripts/set-shell.sh."
    fi

    section "Aplicaciones administradas"
    for p in ghostty zed opencode obsidian; do
        pkg_installed "$p" && ok "$p installed." || warnc "$p is not installed."
    done
    have opencode && note "OpenCode: $(opencode --version 2>/dev/null | head -n1)"

    printf '\nDiagnostics finished (read-only).\n'
}

main "$@"
