#!/usr/bin/env bash
# scripts/configure-dnf.sh — optional DNF5 performance settings.
#
# Adds the missing keys to /etc/dnf/dnf.conf without overwriting values that
# already exist. This is a system configuration change, so it is opt-in.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage() {
    cat <<'EOF'
Usage: scripts/configure-dnf.sh [options]

Options:
  --dry-run   Show what would change; change nothing.
  --yes, -y   Do not ask for confirmation.
  -h, --help  Show this help.

Ensures these keys exist in /etc/dnf/dnf.conf:
  max_parallel_downloads=10
  defaultyes=True
  keepcache=True

Existing values are never overwritten.
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

CONF="/etc/dnf/dnf.conf"
KEYS=(
    "max_parallel_downloads=10"
    "defaultyes=True"
    "keepcache=True"
)

main() {
    require_fedora
    require_cmd dnf
    [[ -r "$CONF" ]] || die "Missing $CONF."

    if ! grep -q '^\[main\]' "$CONF"; then
        die "$CONF has no [main] section; refusing to edit it."
    fi

    local entry key existing
    local -a additions=()

    for entry in "${KEYS[@]}"; do
        key="${entry%%=*}"
        if grep -qE "^[[:space:]]*${key}[[:space:]]*=" "$CONF"; then
            existing="$(grep -E "^[[:space:]]*${key}[[:space:]]*=" "$CONF" | head -n1)"
            info "Keeping existing setting: $existing"
        else
            additions+=("$entry")
        fi
    done

    if ((${#additions[@]} == 0)); then
        info "DNF5 performance settings are already present."
        return 0
    fi

    if ! confirm "Append ${#additions[@]} setting(s) to $CONF?"; then
        info "Cancelled."
        return 0
    fi

    if (( DRY_RUN )); then
        printf '[dry-run] append to %s:\n' "$CONF"
        printf '    %s\n' "${additions[@]}"
        return 0
    fi

    printf '%s\n' "${additions[@]}" | sudo_run tee -a "$CONF" >/dev/null
    info "Updated $CONF: ${additions[*]}"
}

main "$@"
