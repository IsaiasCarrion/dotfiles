# CachyOS: post-instalación

Este documento cubre lo que ocurre **después** de instalar CachyOS y antes de
considerar el equipo listo. El bootstrap normal (`./bootstrap.sh`) ya resuelve
las dependencias personales; los módulos marcados como **opcionales** se ejecutan
a mano y son idempotentes.

El escritorio (DMS, niri, display manager) ya viene con CachyOS y **no se toca**.

## Actualizaciones

```bash
sudo pacman -Syu
```

No se ejecutan actualizaciones automáticas ni se reinicia el sistema desde el
repositorio. Si `pacman` falla por una base de datos vieja durante el bootstrap:

```bash
sudo pacman -Syu
./bootstrap.sh
```

## Firmware (fwupd, opcional)

`fwupd` no está en el manifiesto por defecto. Si lo usás:

```bash
sudo pacman -S fwupd
fwupdmgr --version
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
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
pacman -Qq | grep -E '(^|-)nvidia(-|$)'
```

- `nvidia-smi` respondiendo es la evidencia principal de un driver **activo**.
  `/sys/module/nvidia` y `lspci -k` (`Kernel driver in use: nvidia`) son
  respaldos válidos si `nvidia-smi` no está disponible.
- Los paquetes `nvidia-utils` y `linux-*-nvidia-open` indican driver
  **instalado**, no necesariamente cargado. No confundas ambos estados.
- Si Secure Boot está deshabilitado, no se modifica: es una decisión de firmware.
- Si hay GPU NVIDIA sin driver activo, usá la vía que provee CachyOS (por
  ejemplo `nvidia-utils`/`linux-cachyos-nvidia-open` según el kernel). Este
  repositorio no instala drivers ni firma módulos.

## Flatpak (opcional)

El bootstrap no instala Flatpak ni Flathub. Si lo querés para aplicaciones que no
están en los repositorios oficiales:

```bash
sudo pacman -S flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub <app>
```

Ninguna configuración del repositorio depende de Flatpak.

## AppImage y FUSE

```bash
ls -l /dev/fuse
pacman -Q fuse2 fuse3 2>/dev/null
```

Si un AppImage no arranca:

```bash
chmod +x archivo.AppImage
./archivo.AppImage --appimage-extract-and-run
```

`fuse2` suele ser el paquete que necesitan los AppImages. Instalalo solo si usás
AppImages: `sudo pacman -S fuse2`.

## Docker CE (opcional)

Arch/CachyOS prefiere **Podman rootless**. Docker solo se instala si un flujo de
trabajo lo exige:

```bash
./scripts/install-docker.sh --dry-run
./scripts/install-docker.sh --yes
sudo systemctl enable --now docker
```

El script no elimina Podman y **no** agrega al usuario al grupo `docker` (ese
grupo equivale a root). Usá `sudo docker` o configurá Docker rootless.

## SSH y GitHub

```bash
systemctl is-active sshd
ssh -V
gh auth status
```

- `sshd` no se habilita automáticamente.
- `gh` se instala con `packages/common.txt`; la única acción manual esperada es
  `gh auth login`.
- Las claves y `~/.ssh/config` son locales y no se versionan.

## NetBird, CIFS y SMB

NetBird (opcional, AUR):

```bash
./scripts/install-netbird.sh --dry-run
./scripts/install-netbird.sh
sudo netbird up          # unirse a una red es una acción manual
```

Requiere `paru` o `yay`; el script no instala el helper, no maneja setup keys y
no ejecuta `netbird up`.

Utilidades SMB (opcionales):

```bash
sudo pacman -S cifs-utils smbclient
command -v mount.cifs smbclient
```

## Bluetooth

```bash
sudo pacman -S bluez bluez-utils
sudo systemctl enable --now bluetooth
rfkill list bluetooth
bluetoothctl list
```

## Diagnóstico integral (solo lectura)

```bash
./scripts/diagnose-system.sh
```

Revisa actualizaciones/reinicio, firmware, Secure Boot, NVIDIA, Flatpak, FUSE,
contenedores, SSH/GitHub, NetBird/CIFS/SMB, Bluetooth, shell y aplicaciones
administradas. No instala, habilita ni edita nada.

## Resumen de módulos

| Módulo | Comando | ¿Bootstrap normal? |
|---|---|---|
| Paquetes base, CLI y apps | `install-packages.sh` | Sí |
| Stow | `deploy-dotfiles.sh` | Sí |
| Shell Bash | `set-shell.sh` | Sí |
| Verificación | `verify.sh` | Sí |
| Diagnóstico | `diagnose-system.sh` | No (solo lectura) |
| Docker | `install-docker.sh` | No |
| NetBird (AUR) | `install-netbird.sh` | No |
| OBS Studio | `--with-optional` | No |
| Addy skills | `install-addy-skills.sh` | No |
| Graphify | `install-graphify.sh` | No |
