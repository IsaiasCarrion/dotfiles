# Aplicaciones

Ghostty, Zed, OpenCode y Obsidian están en `packages/apps.txt` y se instalan con
el bootstrap normal desde los **repositorios oficiales** de Arch/CachyOS. No hay
instaladores remotos, AppImages administrados ni paquetes Flatpak obligatorios.

## Ghostty

- Paquete: `ghostty` (`extra`).
- Configuración administrada: `ghostty/.config/ghostty/config` → `~/.config/ghostty/config`.
- El tema `dankcolors` lo genera DMS; el repo solo guarda un fallback en
  `assets/ghostty/dankcolors`.

```bash
ghostty --version
ghostty +validate-config
```

## Zed

- Paquete: `zed` (`extra`).
- Datos personales: `~/.config/zed/` y `~/.local/share/zed/` **no se tocan**.
- Este repositorio no versiona configuración de Zed; si más adelante querés
  administrarla, creá un paquete Stow aparte después de revisar que no tenga
  claves ni rutas privadas.

```bash
zeditor --version
```

En Arch el paquete `zed` instala `/usr/bin/zeditor`; `~/.bashrc` crea el alias
`zed` solo si ese nombre no existe.

## OpenCode

- Paquete: `opencode` (`extra`, V2).
- Configuración administrada: `opencode/.config/opencode/` → `~/.config/opencode/`.
- No se usa el RPM de Fedora, Terra ni un script de instalación remoto.

```bash
opencode --version
opencode plugin list
```

Detalle: [opencode.md](opencode.md).

## Obsidian

- Paquete: `obsidian` (`extra`).
- Datos personales y vaults: no los crea, mueve ni modifica este repositorio.

```bash
obsidian --version
```

## OBS Studio (opcional)

`obs-studio` está en `packages/optional.txt` y solo se instala con:

```bash
./bootstrap.sh --with-optional
# o
./scripts/install-packages.sh --with-optional
```

## Docker (opcional)

No está en los manifiestos para evitar dos vías de instalación:

```bash
./scripts/install-docker.sh --dry-run
./scripts/install-docker.sh --yes
```

Instala `docker`, `docker-compose` y `docker-buildx`, pero **no** habilita el
servicio ni agrega al usuario al grupo `docker` (equivale a root).

## NetBird (opcional, AUR)

NetBird no está en los repositorios oficiales:

```bash
./scripts/install-netbird.sh --dry-run
./scripts/install-netbird.sh
```

Requiere `paru` o `yay`; el script no instala el helper. Nunca ejecuta
`netbird up` ni maneja setup keys.

## Resumen

| Aplicación | Integración | Instalación | Actualización |
|---|---|---|---|
| Ghostty | Bootstrap | pacman (`apps.txt`) | `sudo pacman -Syu` |
| Zed | Bootstrap | pacman (`apps.txt`) | `sudo pacman -Syu` |
| OpenCode | Bootstrap | pacman (`apps.txt`) | `sudo pacman -Syu` |
| Obsidian | Bootstrap | pacman (`apps.txt`) | `sudo pacman -Syu` |
| OBS Studio | Opcional | `--with-optional` | `sudo pacman -Syu` |
| Docker | Opcional | `install-docker.sh` | `sudo pacman -Syu` |
| NetBird | Opcional AUR | `install-netbird.sh` | `install-netbird.sh --update` |
