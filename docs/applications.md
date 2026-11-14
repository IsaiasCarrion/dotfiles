# Aplicaciones

Ghostty, Zed, OpenCode y Obsidian están en `packages/apps.txt` y se instalan
desde los **repositorios oficiales** de Arch. No hay instaladores remotos,
AppImages administrados ni paquetes Flatpak obligatorios.

Omarchy ya trae **Obsidian**, **Ghostty** y **OpenCode**. Además, `gh`,
`opencode` y `uv` se instalan a través de mise
(`/etc/mise/conf.d/omarchy-tools.toml`). Por eso el instalador omite esos
paquetes cuando ya están presentes o los provee Omarchy; los manifiestos los
conservan para instalaciones de Arch puro. Zed no forma parte de la imagen base
y se instala con `packages/apps.txt`.

## Ghostty

- Paquete: `ghostty` (`extra`).
- La configuración y el tema son **de Omarchy**: `~/.config/ghostty/config` y
  `~/.local/state/omarchy/current/theme/ghostty.conf`.
- Este repo **no** versiona ni enlaza Ghostty. Las preferencias personales
  opcionales se aplican con `scripts/ghostty-personal.sh`; ver
  [ghostty.md](ghostty.md).

```bash
ghostty --version
ghostty +validate-config
```

## Zed

- Paquete: `zed` (`extra`).
- Datos personales: `~/.config/zed/` y `~/.local/share/zed/` **no se tocan**.
- El repositorio no versiona configuración de Zed; si más adelante querés
  administrarla, creá un paquete Stow aparte después de revisar que no tenga
  claves ni rutas privadas.

```bash
zeditor --version
```

En Arch el paquete `zed` instala `/usr/bin/zeditor`; `~/.bashrc` crea el alias
`zed` solo si ese nombre no existe. Omarchy define `EDITOR` con
`omarchy-launch-editor --inline`, que abre el editor configurado en Omarchy.

## OpenCode

- Paquete: `opencode` (`extra`, V2). En Omarchy se usa el binario 2.x que
  provee mise; el instalador no agrega el paquete pacman encima.
- Configuración del repo: `opencode/.config/opencode/*.jsonc` y `AGENTS.md`.
- Omarchy aporta `~/.config/opencode/opencode.json` y `cli.json`; el repo se
  fusiona sobre ellos sin reemplazarlos. Detalle: [opencode.md](opencode.md).

```bash
opencode --version
opencode plugin list
```

## Obsidian

- Paquete: `obsidian` (`extra`); ya viene en Omarchy.
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

## Contenedores

Omarchy instala Docker por defecto. Este repositorio **no** lo reinstala, no lo
habilita y no agrega al usuario al grupo `docker` (equivale a root). Si preferís
Podman rootless:

```bash
./scripts/install-packages.sh --with-optional   # incluye podman
podman info
```

No hay un script de instalación de Docker en el repo: sería redundante en
Omarchy.

## NetBird (opcional, AUR)

NetBird no está en los repositorios oficiales:

```bash
./scripts/install-netbird.sh --dry-run
./scripts/install-netbird.sh
```

Omarchy incluye `yay`; el script detecta `paru`/`yay` y no instala un helper.
Nunca ejecuta `netbird up` ni maneja setup keys.

## Resumen

| Aplicación | Integración | Instalación | Actualización |
|---|---|---|---|
| Ghostty | Omarchy (tema/config) | `apps.txt` solo si falta | `omarchy update` |
| Zed | Bootstrap | pacman (`apps.txt`) | `omarchy update` |
| OpenCode | Repo + base de Omarchy | pacman o mise (`apps.txt`) | `omarchy update` |
| Obsidian | Omarchy | `apps.txt` solo si falta | `omarchy update` |
| OBS Studio | Opcional | `--with-optional` | `omarchy update` |
| Podman | Opcional | `--with-optional` | `omarchy update` |
| NetBird | Opcional AUR | `install-netbird.sh` | `install-netbird.sh --update` |
