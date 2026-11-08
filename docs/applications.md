# Aplicaciones obligatorias y opcionales

Zed y Obsidian forman parte del bootstrap (`./bootstrap.sh`, paso 3/5). El resto de
las aplicaciones de este documento son módulos opcionales y nunca se instalan solos.

## Zed

- **Origen:** instalador oficial estable <https://zed.dev/install.sh>.
- **Arquitecturas:** x86_64 y aarch64 (el instalador oficial las soporta).
- **Destino:** `~/.local/zed.app/` con el ejecutable enlazado desde `~/.local/bin/zed`
  (el instalador también crea `~/.local/share/applications/dev.zed.Zed.desktop`).
- **Datos personales:** `~/.config/zed/` y `~/.local/share/zed/` **no se tocan**.

Instalar o comprobar:

```bash
./scripts/install-zed.sh --dry-run   # muestra qué haría
./scripts/install-zed.sh             # instala solo si falta
zed --version
```

Detección previa, en este orden: ejecutable en `PATH`, `~/.local/zed.app/bin/zed`,
Flatpak `dev.zed.Zed` y RPM `zed`. Si ya existe cualquiera de ellos, el script no
instala una segunda copia.

Actualizar:

```bash
./scripts/install-zed.sh --update
```

El instalador oficial descarga la versión estable más reciente y reemplaza el
directorio `~/.local/zed.app`; la configuración y los datos de usuario quedan
intactos. Zed también puede actualizarse desde su propia interfaz. Si Zed se
había instalado por Flatpak o RPM, `--update` actualiza ese canal y no crea una
copia extra.

## Obsidian

- **Preferencia:** AppImage oficial de <https://obsidian.md/download>.
- **Origen real:** releases de <https://github.com/obsidianmd/obsidian-releases>.
- **Arquitecturas:** x86_64 y arm64.
- **Destino:** `~/Applications/Obsidian-<versión>.AppImage`.
- **Acceso:** enlace `~/.local/bin/obsidian` y lanzador
  `~/.local/share/applications/obsidian.desktop`.
- **Icono:** `~/.local/share/icons/hicolor/512x512/apps/obsidian.png`, extraído del
  propio AppImage durante la instalación.

Detección previa, en este orden:

1. Flatpak `md.obsidian.Obsidian`.
2. RPM `obsidian`.
3. AppImage administrado en `~/Applications/Obsidian-*.AppImage`.
4. Ejecutable `obsidian` en `PATH`.

Si ya existe una instalación, el script **no instala otra**. En particular, un
Obsidian Flatpak existente se conserva y nunca se reemplaza por el AppImage.

```bash
./scripts/install-obsidian.sh --dry-run   # muestra qué haría
./scripts/install-obsidian.sh             # instala solo si no hay ninguna copia
./scripts/install-obsidian.sh --update    # actualiza la copia detectada
```

Actualizar:

- AppImage administrado: descarga la última release, mueve el archivo nuevo a
  `~/Applications/` y elimina solo los AppImage antiguos administrados por el script.
- Flatpak: `flatpak update -y md.obsidian.Obsidian`.
- RPM: `sudo dnf upgrade -y obsidian`.

Requisitos y datos personales:

- **FUSE:** requiere `/dev/fuse` y `fuse`/`fuse-libs` (están en `packages/fedora.txt`).
- **Configuración y vaults:** viven en `~/.var/app/md.obsidian.Obsidian/` para Flatpak
  o en la ruta elegida por el usuario para AppImage. El script **nunca** crea, mueve ni
  modifica vaults ni `obsidian.json`.
- El archivo `~/Downloads/Obsidian-1.15.0.AppImage` no es una instalación administrada;
  queda intacto.

## OBS Studio (opcional)

`obs-studio` está en `packages/optional.txt` y solo se instala con:

```bash
./bootstrap.sh --with-optional
# o
./scripts/install-packages.sh --with-optional
```

No se instala durante el bootstrap normal para no arrastrar dependencias de video
en equipos que no graban o transmiten.

## Resumen

| Aplicación | Integración | Instalación | Actualización |
|---|---|---|---|
| Zed | Bootstrap, paso 3/5 | `install-zed.sh` (oficial) | `install-zed.sh --update` |
| Obsidian | Bootstrap, paso 3/5 | `install-obsidian.sh` (AppImage) | `install-obsidian.sh --update` |
| OBS Studio | Opcional | `--with-optional` | `sudo dnf upgrade` |
| Docker CE | Opcional | `install-docker.sh` | `sudo dnf upgrade` |
| NetBird | Opcional | `install-netbird.sh` | `install-netbird.sh --update` |
