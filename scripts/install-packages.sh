#!/usr/bin/env bash
# scripts/install-packages.sh — install only the missing Fedora packages.
#
# Reads:
#   packages/fedora.txt   base Fedora packages
#   packages/common.txt   portable CLI baseline
#   packages/dms.txt      DMS desktop stack (COPR)
#   packages/copr.txt     COPR repositories required by the desktop stack
#   packages/flatpak.txt  Flathub applications
#   packages/optional.txt optional toolchains/codecs (--with-optional)
#
# Idempotent: already-installed packages are skipped and repositories are only
# enabled when a package that needs them is actually missing.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: scripts/install-packages.sh [options]

Options:
  --dry-run        Print the commands without changing the system.
  --yes, -y        Do not ask for confirmation.
  --with-optional  Also install packages from packages/optional.txt.
  --no-flatpak     Skip Flatpak applications.
  --no-copr        Never enable COPR repositories (fails if DMS is missing).
  -h, --help       Show this help.
EOF
}

WITH_OPTIONAL=0
WITH_FLATPAK=1
WITH_COPR=1

while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --yes|-y) ASSUME_YES=1 ;;
        --with-optional) WITH_OPTIONAL=1 ;;
        --no-flatpak) WITH_FLATPAK=0 ;;
        --no-copr) WITH_COPR=0 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
    shift
done

repo_enabled() {
    dnf repolist --enabled 2>/dev/null | awk '{print $1}'
}

ensure_coprs() {
    (( WITH_COPR )) || die "COPR repositories are disabled but DMS packages are missing."

    if ! pkg_installed dnf-plugins-core; then
        log "Installing dnf-plugins-core (needed for COPR)."
        sudo_run dnf install -y dnf-plugins-core
    fi

    local spec owner project repo_id
    local -a enabled
    mapfile -t enabled < <(repo_enabled)

    while IFS= read -r spec; do
        [[ -n "$spec" ]] || continue
        [[ "$spec" == */* ]] || die "Invalid COPR entry (expected owner/project): $spec"
        owner="${spec%%/*}"
        project="${spec#*/}"
        repo_id="copr:copr.fedorainfracloud.org:${owner}:${project}"

        if printf '%s\n' "${enabled[@]}" | grep -qx "$repo_id"; then
            info "COPR already enabled: $spec"
        else
            log "Enabling COPR: $spec"
            sudo_run dnf -y copr enable "$spec"
        fi
    done < <(manifest_packages "$REPO_ROOT/packages/copr.txt")
}

starship_in_fedora() {
    dnf -q repoquery --available --repo=fedora --repo=updates starship 2>/dev/null | grep -q .
}

ensure_starship_repo() {
    pkg_installed starship && return 0
    if starship_in_fedora; then
        return 0
    fi
    if repo_enabled | grep -qx terra; then
        info "Terra repository already enabled (needed by starship)."
        return 0
    fi

    # Terra's key ships in Fedora's distribution-gpg-keys package. Installing
    # that Fedora-signed package first lets DNF verify terra-release instead of
    # disabling GPG checks.
    local rel key
    rel="$(rpm -E %fedora)"
    key="/usr/share/distribution-gpg-keys/terra/RPM-GPG-KEY-terra${rel}"

    log "Installing distribution-gpg-keys (Fedora-provided Terra key)."
    sudo_run dnf install -y distribution-gpg-keys

    if (( ! DRY_RUN )) && [[ ! -r "$key" ]]; then
        die "Terra GPG key not found at $key."
    fi

    log "Importing the Terra GPG key."
    sudo_run rpm --import "$key"

    log "Enabling the Terra repository (GPG verification enabled)."
    sudo_run dnf install -y \
        --repofrompath "terra,https://repos.fyralabs.com/terra${rel}" \
        terra-release
}

install_flatpaks() {
    (( WITH_FLATPAK )) || return 0

    have flatpak || {
        warn "flatpak is not installed; skipping Flatpak applications."
        return 0
    }

    local -a apps=()
    mapfile -t apps < <(manifest_packages "$REPO_ROOT/packages/flatpak.txt")
    ((${#apps[@]})) || return 0

    local app
    local -a missing=()
    for app in "${apps[@]}"; do
        flatpak info --system "$app" >/dev/null 2>&1 || missing+=("$app")
    done

    if ((${#missing[@]} == 0)); then
        info "All Flatpak applications are already installed."
        return 0
    fi

    if ! flatpak remotes --system --columns=name 2>/dev/null | grep -qx flathub; then
        log "Adding the Flathub remote (system-wide)."
        sudo_run flatpak remote-add --if-not-exists --system flathub \
            https://flathub.org/repo/flathub.flatpakrepo
    fi

    log "Installing ${#missing[@]} Flatpak application(s): ${missing[*]}"
    sudo_run flatpak install -y --system flathub "${missing[@]}"
}

main() {
    require_fedora
    require_cmd dnf

    local -a fedora_pkgs=() common_pkgs=() dms_pkgs=() optional_pkgs=()
    mapfile -t fedora_pkgs < <(manifest_packages "$REPO_ROOT/packages/fedora.txt")
    mapfile -t common_pkgs < <(manifest_packages "$REPO_ROOT/packages/common.txt")
    mapfile -t dms_pkgs < <(manifest_packages "$REPO_ROOT/packages/dms.txt")
    mapfile -t optional_pkgs < <(manifest_packages "$REPO_ROOT/packages/optional.txt")

    # starship lives in Terra, which is not a Fedora/COPR repository.
    ensure_starship_repo

    local -a wanted=("${fedora_pkgs[@]}" "${common_pkgs[@]}" "${dms_pkgs[@]}")
    local -a missing=()
    local pkg

    for pkg in "${wanted[@]}"; do
        pkg_installed "$pkg" || missing+=("$pkg")
    done

    if ((${#missing[@]})); then
        # COPR is only needed when a DMS package itself is missing.
        local need_copr=0
        for pkg in "${dms_pkgs[@]}"; do
            if ! pkg_installed "$pkg"; then
                need_copr=1
                break
            fi
        done

        if (( need_copr )); then
            ensure_coprs
        fi

        log "Installing ${#missing[@]} missing package(s): ${missing[*]}"
        sudo_run dnf install -y -- "${missing[@]}"
    else
        info "All base packages are already installed."
    fi

    if (( WITH_OPTIONAL )); then
        local -a opt_missing=()
        for pkg in "${optional_pkgs[@]}"; do
            pkg_installed "$pkg" || opt_missing+=("$pkg")
        done

        if ((${#opt_missing[@]})); then
            local enabled
            enabled="$(repo_enabled)"
            local -a opt_install=()
            for pkg in "${opt_missing[@]}"; do
                case "$pkg" in
                    ffmpeg|gstreamer1-plugins-*)
                        if grep -qx rpmfusion-free <<<"$enabled"; then
                            opt_install+=("$pkg")
                        else
                            warn "Skipping $pkg: RPM Fusion Free is not enabled (https://rpmfusion.org)."
                        fi
                        ;;
                    *) opt_install+=("$pkg") ;;
                esac
            done

            if ((${#opt_install[@]})); then
                log "Installing optional package(s): ${opt_install[*]}"
                sudo_run dnf install -y -- "${opt_install[@]}"
            fi
        else
            info "All optional packages are already installed."
        fi
    fi

    install_flatpaks

    log "Package step finished."
}

main "$@"
