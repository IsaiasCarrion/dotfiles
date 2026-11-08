# Fedora 45: post-instalación

Este documento cubre lo que ocurre **después** de instalar Fedora 45 y antes de
considerar el equipo listo: DNF5, actualizaciones, firmware, multimedia, Flatpak,
AppImage, contenedores, SSH/GitHub, NetBird/SMB y Bluetooth.

El bootstrap normal (`./bootstrap.sh`) ya resuelve lo mínimo. Los módulos marcados
como **opcionales** se ejecutan a mano y son idempotentes.

## DNF5

Fedora 45 usa DNF5 (`dnf5 5.4.7.0` en el equipo auditado). Configuración aplicada
en `/etc/dnf/dnf.conf`:

```ini
[main]
max_parallel_downloads=10
defaultyes=True
keepcache=True
```

- `max_parallel_downloads=10` acelera descargas sin cambiar repositorios.
- `defaultyes=True` evita preguntas repetidas en scripts interactivos.
- `keepcache=True` conserva paquetes descargados; limpiar con `sudo dnf clean packages`.

Comprobación:

```bash
dnf --version
dnf repolist --enabled
```

Para reproducir los ajustes en un equipo nuevo (sin sobrescribir valores existentes):

```bash
./scripts/configure-dnf.sh --dry-run
./scripts/configure-dnf.sh --yes
```

## Actualizaciones y reinicio pendiente

```bash
sudo dnf upgrade --refresh
sudo dnf check-upgrade          # ver qué falta
```

Detección de reinicio:

```bash
[[ -e /run/reboot-required ]] && echo "reinicio requerido"
# alternativa si está instalado needs-restarting:
needs-restarting -r; echo "exit=$?"
```

Fedora no instala `needs-restarting` por defecto en DNF5. `scripts/diagnose-system.sh`
compara el kernel en ejecución (`uname -r`) con el kernel instalado más nuevo y avisa
si difieren. **Nunca se reinicia automáticamente.**

Actualizaciones automáticas: `dnf-automatic` no está instalado. Es una decisión
deliberada; ver [security-hardening.md](security-hardening.md) (PAT-003).

## RPM Fusion y multimedia (opcional)

```bash
./scripts/install-multimedia.sh --dry-run
./scripts/install-multimedia.sh
```

El módulo:

1. Instala `rpmfusion-free-release` y `rpmfusion-nonfree-release` si faltan.
2. Instala códecs GStreamer (`good`, `bad-free`, `bad-freeworld`, `ugly`,
   `openh264`) y `ffmpeg`.
3. Usa `--allowerasing` porque el `ffmpeg` de RPM Fusion reemplaza a `ffmpeg-free`.

RPM Fusion es un repositorio de terceros: habilitalo solo si confiás en él.

## Firmware (fwupd)

`fwupd`, `mokutil` y `pciutils` están en `packages/fedora.txt`.

```bash
fwupdmgr --version
systemctl is-active fwupd
sudo fwupdmgr refresh --force
sudo fwupdmgr get-updates
sudo fwupdmgr update        # aplica firmware; puede requerir reinicio
```

No se aplican actualizaciones de firmware automáticamente.

## Secure Boot y NVIDIA

Diagnóstico de solo lectura:

```bash
mokutil --sb-state
lspci -k | grep -iA3 -E 'vga|3d|display'
lsmod | grep '^nvidia'
rpm -qa | grep -E 'nvidia|kmod'
```

- Si Secure Boot está deshabilitado, no se modifica: es una decisión de firmware.
- Si hay GPU NVIDIA sin driver, la vía soportada en Fedora es RPM Fusion
  (`akmod-nvidia` / `kmod-nvidia`), no un instalador propietario suelto.
- El equipo auditado usa Intel i915 y solo tiene `nvidia-gpu-firmware`; no hay
  driver NVIDIA instalado.

## Flatpak y Flathub

```bash
flatpak remotes --columns=name,url
flatpak list --app
sudo flatpak update
```

El bootstrap agrega Flathub si falta e instala las aplicaciones de
`packages/flatpak.txt` (Extension Manager y Gearlever). Obsidian **no** se instala
por Flatpak en equipos nuevos: se usa el AppImage oficial
(ver [applications.md](applications.md)).

## AppImage y FUSE

```bash
ls -l /dev/fuse
rpm -q fuse fuse3 fuse-libs
~/Applications/Obsidian-*.AppImage --appimage-version
```

`fuse` y `fuse-libs` están en `packages/fedora.txt`. Si un AppImage no arranca:

```bash
chmod +x archivo.AppImage
./archivo.AppImage --appimage-extract-and-run
```

## Docker CE (opcional)

Fedora prefiere **Podman rootless**. Docker solo se instala si un flujo de trabajo
lo exige:

```bash
./scripts/install-docker.sh --dry-run
./scripts/install-docker.sh --yes
sudo systemctl enable --now docker
```

El script no elimina Podman y **no** agrega al usuario al grupo `docker` (ese grupo
equivale a root). Usá `sudo docker` o configurá Docker rootless.

## SSH y GitHub

```bash
systemctl is-active sshd
ssh -V
gh auth status
```

- `sshd` está inactivo en el equipo auditado. No se habilita automáticamente.
- `gh` ya está autenticado; el bootstrap no genera ni sube claves SSH.
- Las claves y `~/.ssh/config` son locales y no se versionan.

## NetBird, CIFS y SMB

Utilidades base (incluidas en `packages/fedora.txt`):

```bash
command -v mount.cifs smbclient
```

NetBird (opcional):

```bash
./scripts/install-netbird.sh --dry-run
./scripts/install-netbird.sh
sudo netbird up          # unirse a una red es una acción manual
```

El script escribe `/etc/yum.repos.d/netbird.repo` con `gpgcheck=1` y
`repo_gpgcheck=1`, porque NetBird ya no publica un `.repo` listo para descargar.
Nunca maneja setup keys ni ejecuta `netbird up`.

## OBS Studio (opcional)

```bash
./bootstrap.sh --with-optional
```

## Bluetooth

```bash
systemctl is-active bluetooth
rfkill list bluetooth
bluetoothctl list
bluetoothctl show
```

`bluez` está en `packages/fedora.txt`. Si el servicio está inactivo, abrilo desde
la configuración del escritorio o con `sudo systemctl enable --now bluetooth`.

## Diagnóstico integral (solo lectura)

```bash
./scripts/diagnose-system.sh
```

Revisa DNF5, actualizaciones/reinicio, RPM Fusion, firmware, Secure Boot, NVIDIA,
Flatpak, FUSE/AppImage, Podman/Docker, SSH/GitHub, NetBird/CIFS/SMB, Bluetooth,
Zed y Obsidian. No instala, habilita ni edita nada.

## Resumen de módulos

| Módulo | Comando | ¿Bootstrap normal? |
|---|---|---|
| Paquetes base | `install-packages.sh` | Sí |
| Zed | `install-zed.sh` | Sí |
| Obsidian | `install-obsidian.sh` | Sí |
| Diagnóstico | `diagnose-system.sh` | No (solo lectura) |
| DNF5 | `configure-dnf.sh` | No |
| Multimedia | `install-multimedia.sh` | No |
| Docker CE | `install-docker.sh` | No |
| NetBird | `install-netbird.sh` | No |
| OBS Studio | `--with-optional` | No |
