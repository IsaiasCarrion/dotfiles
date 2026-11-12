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
    note "$(pacman --version | grep -m1 . || true)"
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
        systemctl is-active fwupd >/dev/null 2>&1 && ok "fwupd service active." || note "fwupd service is not active."
        note "Check updates manually: sudo fwupdmgr refresh --force && sudo fwupdmgr get-updates"
    else
        note "fwupd is not installed (optional)."
    fi

    section "Secure Boot y NVIDIA"
    if have mokutil; then
        note "$(mokutil --sb-state 2>&1 | head -n1)"
    else
        note "mokutil not installed (optional); cannot read Secure Boot state."
    fi

    local nvidia_gpu="" nvidia_smi="" nvidia_pkgs="" nvidia_module=0 nvidia_lspci=0
    if have lspci; then
        nvidia_gpu="$(lspci 2>/dev/null | grep -iE 'vga|3d|display' | grep -i nvidia | head -n1 || true)"
        if lspci -k 2>/dev/null | grep -A3 -iE 'vga|3d|display' | grep -qi 'Kernel driver in use: nvidia'; then
            nvidia_lspci=1
        fi
    fi
    if have nvidia-smi; then
        nvidia_smi="$(timeout 5 nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null | head -n1 || true)"
    fi
    if [[ -d /sys/module/nvidia ]]; then
        nvidia_module=1
    fi
    nvidia_pkgs="$(pacman -Qq 2>/dev/null | grep -E '(^|-)nvidia(-|$)' | tr '\n' ' ' || true)"

    if [[ -n "$nvidia_gpu" || -n "$nvidia_smi" ]]; then
        if [[ -n "$nvidia_gpu" ]]; then
            note "NVIDIA GPU: $(cut -d: -f3 <<<"$nvidia_gpu" | sed 's/^ //')"
        else
            note "NVIDIA GPU: ${nvidia_smi%%,*}"
        fi

        # Active driver: nvidia-smi is the strongest signal; the sysfs module
        # and lspci are fallbacks when the userspace tool is unavailable.
        if [[ -n "$nvidia_smi" ]]; then
            ok "NVIDIA driver active: $nvidia_smi"
        elif (( nvidia_module )); then
            ok "nvidia kernel module active (/sys/module/nvidia)."
        elif (( nvidia_lspci )); then
            warnc "lspci reports 'Kernel driver in use: nvidia', but nvidia-smi did not respond."
        else
            warnc "NVIDIA GPU present but no active NVIDIA driver."
        fi

        if [[ -n "$nvidia_pkgs" ]]; then
            note "NVIDIA packages installed: $nvidia_pkgs"
        else
            note "No NVIDIA packages detected in pacman."
        fi
    else
        if ! have lspci; then
            note "lspci not available (optional pciutils); cannot detect an NVIDIA GPU."
        else
            note "No NVIDIA GPU detected."
        fi
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
    have mount.cifs && ok "mount.cifs available." || note "mount.cifs not available (optional cifs-utils)."
    have smbclient && ok "smbclient available." || note "smbclient not available (optional smbclient)."

    section "Bluetooth"
    if pkg_installed bluez; then
        systemctl is-active bluetooth >/dev/null 2>&1 && ok "bluetooth service active." || warnc "bluetooth service is not active."
        if have rfkill; then
            note "rfkill: $(rfkill list bluetooth 2>/dev/null | tr '\n' ' ' || echo 'no adapter reported')"
        fi
        if have bluetoothctl; then
            note "Controllers: $(bluetoothctl list 2>/dev/null | tr '\n' ' ' || echo 'none')"
        fi
    else
        note "bluez is not installed (optional)."
    fi

    section "Shell"
    local user login_shell ghostty_cmd ghostty_name
    user="$(id -un)"
    login_shell="$(getent passwd "$user" | cut -d: -f7)"
    note "SHELL env (may be stale): ${SHELL:-unset}"
    note "login shell of $user: ${login_shell:-unknown}"
    if [[ "$(basename -- "$login_shell")" == "bash" ]]; then
        ok "Bash is the login shell: $(bash --version | head -n1)"
    else
        warnc "Bash is not the login shell; run ./scripts/set-shell.sh."
    fi
    if shopt -oq posix; then
        note "POSIX mode in this diagnostic shell: enabled."
    else
        note "POSIX mode in this diagnostic shell: disabled."
    fi
    if [[ -n "${SHELL:-}" && "$(basename -- "$SHELL")" != "bash" ]]; then
        warnc "SHELL=$SHELL is not Bash; log out and back in to refresh the session environment."
    fi
    if have ghostty; then
        ghostty_cmd="$(ghostty +show-config --no-pager 2>/dev/null | sed -n 's/^command = //p' | head -n1 || true)"
        if [[ -n "$ghostty_cmd" ]]; then
            note "Ghostty effective command: $ghostty_cmd"
            ghostty_name="${ghostty_cmd%% *}"
            ghostty_name="${ghostty_name#direct:}"
            if [[ "$(basename -- "$ghostty_name")" != "bash" ]]; then
                warnc "Ghostty is configured to launch '$ghostty_cmd', not Bash."
            fi
        fi
    fi

    section "Aplicaciones administradas"
    for p in ghostty zed opencode obsidian; do
        pkg_installed "$p" && ok "$p installed." || warnc "$p is not installed."
    done
    if have opencode; then
        note "OpenCode: $(opencode --version 2>/dev/null | head -n1 || true)"
    fi

    printf '\nDiagnostics finished (read-only).\n'
}

main "$@"
