# Omarchy: post-instalación

Este documento cubre lo que ocurre **después** de instalar Omarchy y antes de
considerar el equipo listo. El bootstrap normal (`./bootstrap.sh`) resuelve las
dependencias personales; los módulos opcionales se ejecutan a mano y son
idempotentes.

Omarchy administra el escritorio, los temas, Bash, Starship y Ghostty. Este
repositorio no los reinstala ni los reconfigura.

## Actualizaciones

```bash
omarchy update        # o: sudo pacman -Syu
```

No se ejecutan actualizaciones automáticas ni se reinicia el sistema desde el
repositorio. Si `pacman` falla por una base de datos vieja durante el bootstrap:

```bash
omarchy update
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
  `/sys/module/nvidia` y `lspci -k` son respaldos válidos.
- Omarchy instala los drivers NVIDIA según el hardware; este repositorio no
  instala ni firma módulos.
- Si Secure Boot está deshabilitado, no se modifica: es una decisión de firmware.

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
./archivo.AppImage --extract-and-run
```

`fuse2` suele ser el paquete que necesitan los AppImages. Instalalo solo si usás
AppImages: `sudo pacman -S fuse2`.

## Contenedores

Omarchy instala Docker por defecto y **no** es tarea de este repo habilitarlo ni
agregar al usuario al grupo `docker` (equivale a root). Para trabajo rootless:

```bash
./scripts/install-packages.sh --with-optional   # incluye podman
podman info
```

## SSH y GitHub

```bash
systemctl is-active sshd
ssh -V
gh auth status
```

- `sshd` no se habilita automáticamente.
- Omarchy provee `gh` a través de mise; la única acción manual esperada es
  `gh auth login`.
- Las claves y `~/.ssh/config` son locales y no se versionan.

## NetBird, CIFS y SMB

NetBird (opcional, AUR):

```bash
./scripts/install-netbird.sh --dry-run
./scripts/install-netbird.sh
sudo netbird up          # unirse a una red es una acción manual
```

Omarchy incluye `yay`; el script detecta `paru`/`yay`, no instala el helper, no
maneja setup keys y no ejecuta `netbird up`.

Utilidades SMB (opcionales):

```bash
sudo pacman -S cifs-utils smbclient
command -v mount.cifs smbclient
```

## Bluetooth

```bash
rfkill list bluetooth
bluetoothctl list
```

Omarchy ya incluye `bluez`, `bluez-utils` y el servicio de Bluetooth.

## Diagnóstico integral (solo lectura)

```bash
./scripts/diagnose-system.sh
```

Revisa Omarchy, Hyprland, tema, actualizaciones/reinicio, firmware, Secure Boot,
NVIDIA, Flatpak, FUSE, contenedores, SSH/GitHub, NetBird/CIFS, Bluetooth, shell
y aplicaciones administradas. No instala, habilita ni edita nada.

## Resumen de módulos

| Módulo | Comando | ¿Bootstrap normal? |
|---|---|---|
| Paquetes base, CLI y apps | `install-packages.sh` | Sí |
| Stow | `deploy-dotfiles.sh` | Sí |
| Verificación | `verify.sh` | Sí |
| Pruebas seguras | `test.sh` | No (solo lectura/HOMEs temporales) |
| Diagnóstico | `diagnose-system.sh` | No (solo lectura) |
| Preferencias Ghostty | `ghostty-personal.sh` | No |
| Podman/Go/Rust/OBS | `--with-optional` | No |
| NetBird (AUR) | `install-netbird.sh` | No |
| Addy skills | `install-addy-skills.sh` | No |
| Graphify | `install-graphify.sh` | No |
