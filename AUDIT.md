# Auditoría y migración a CachyOS

Fecha: 2026-11-12. Objetivo: dejar este repositorio autosuficiente para una
instalación limpia de **CachyOS (Arch Linux)** con Bash, GNU Stow, Ghostty, Zed,
OpenCode y el escritorio DMS/niri ya provisto por el sistema.

> **Actualización 2026-11-12:** la auditoría final se ejecutó en el equipo real
> CachyOS. No se instalaron paquetes ni se cambió la shell (ya era Bash), pero
> se ejecutaron `--dry-run`, `verify.sh`, `diagnose-system.sh`, simulación Stow y
> pruebas de idempotencia. Los resultados reales están en la sección 8; la
> sección 7 conserva el plan original de validación.

## 1. Estado inicial encontrado

- El repositorio estaba íntegramente orientado a **Fedora/DNF/COPR**:
  `packages/fedora.txt`, `packages/dms.txt`, `packages/copr.txt`,
  `packages/flatpak.txt`, `scripts/configure-dnf.sh`, `install-multimedia.sh`,
  `install-zed.sh`, `install-obsidian.sh`, `install-opencode.sh`.
- `scripts/lib.sh` y `scripts/install-packages.sh` usaban `dnf`, `rpm`, COPR,
  Terra, RPM Fusion y Flatpak.
- El bootstrap instalaba el **stack del escritorio** (`niri`, `dms`, `ghostty`,
  `quickshell`, `matugen`, `dux-*`) desde COPR, en contradicción con la regla de
  no instalar DMS/niri/entorno gráfico.
- Zed y Obsidian se instalaban con instaladores propios/AppImage, aunque ambos
  están en los repositorios oficiales de Arch/CachyOS. OpenCode se enlazaba desde
  un RPM de Fedora o se instalaba con un script remoto.
- La configuración de Bash cargaba `/etc/bashrc` (Fedora) y el paquete
  `bash-dnf`. No existía `.bash_profile`.
- La documentación describía Fedora 45, DNF5, COPR y RPM Fusion.
- **No existía ningún archivo Fish** (`config.fish`, `conf.d/`, `functions/`,
  variables universales), ni en el árbol actual ni en el historial Git. Tampoco
  había referencias a Fish en scripts o documentación.

## 2. Problemas encontrados

| # | Problema | Riesgo | Corrección |
|---|---|---|---|
| 1 | Manifiestos y scripts exclusivos de Fedora (`dnf`, `rpm`, COPR) | El bootstrap falla en CachyOS | Reemplazados por manifiestos Arch y pacman |
| 2 | Instalación del escritorio (niri/DMS/dux) | Viola el alcance y puede pisar CachyOS | Eliminados `dms.txt` y `copr.txt`; el repo no toca el escritorio |
| 3 | Dos mecanismos para Zed/Obsidian/OpenCode | Duplicados y actualizaciones divergentes | Una sola vía: `packages/apps.txt` + pacman |
| 4 | Script remoto de OpenCode y binario de RPM | Origen no reproducible en Arch | Paquete oficial `opencode` de `extra` |
| 5 | `pacman`/AUR sin política ni detección | Instalaciones incompletas | `install-packages.sh` usa pacman; AUR solo en NetBird opcional |
| 6 | `.bashrc` cargaba `/etc/bashrc` de Fedora | Configuración global incorrecta | Carga `/etc/bash.bashrc` si existe |
| 7 | Faltaba `.bash_profile` | Un shell de login no cargaba `.bashrc` | Agregado al paquete `bash` |
| 8 | Shell de login no se configuraba | Bash no quedaba como shell principal | Nuevo `scripts/set-shell.sh`, seguro e idempotente |
| 9 | `common.txt` usaba nombres Fedora (`fd-find` por `fd`, `p7zip` por `7zip`) | Paquetes inexistentes o incorrectos | Nombres Arch verificados contra archlinux.org |
| 10 | `cargo` listado aparte de `rust` | Duplicado: Arch lo incluye en `rust` | Eliminado de `optional.txt` |
| 11 | Docker podía instalarse por dos vías | Duplicación | Solo `scripts/install-docker.sh` |
| 12 | `verify.sh` comprobaba DNF/Flatpak/COPR y enlaces viejos | Falsos negativos en CachyOS | Reescrito para Arch, shell, apps y enlaces actuales |
| 13 | `diagnose-system.sh` era de Fedora | Diagnóstico inútil | Reescrito para pacman/systemd/Arch |
| 14 | Documentación desactualizada | El README prometía Fedora | README, AUDIT y docs reescritos |
| 15 | Sin verificación de shell por defecto | El criterio de éxito no se comprobaba | `verify.sh` valida shell, `/etc/shells` y `.bash_profile` |

## 3. Correcciones realizadas

### Paquetes

Manifiestos definitivos:

- `packages/base.txt`: bash, git, stow, sudo, curl, ca-certificates, jq,
  util-linux, tar, gzip, bzip2, xz, zstd, unzip, 7zip, findutils.
- `packages/common.txt`: bash-completion, ripgrep, fzf, fd, bat, eza, zoxide,
  starship, tree, tmux, neovim, python, uv, github-cli, git-delta.
- `packages/apps.txt`: ghostty, zed, opencode, obsidian.
- `packages/optional.txt`: gcc, make, go, rust, ffmpeg, gst-plugins-good/bad/ugly,
  gst-libav, obs-studio.

Todos los paquetes fueron consultados en la API de archlinux.org y están en
`core`/`extra`. **No se requiere AUR** para la instalación normal.

### Instalación

- `install-packages.sh` detecta CachyOS/Arch, comprueba disponibilidad, instala
  solo lo ausente con `pacman -S --needed --noconfirm`, y no actualiza el sistema
  implícitamente. Si la base está vieja, indica `sudo pacman -Syu`.
- No usa `--noconfirm` para operaciones destructivas; solo para instalar.
- El único uso de AUR es `install-netbird.sh` (opcional). Detecta `paru`/`yay`,
  no instala un helper y no ejecuta `netbird up`.

### Stow

- Paquete `bash-dnf` renombrado a `bash-arch`; `dnf.sh` reemplazado por
  `pacman.sh`.
- `deploy-dotfiles.sh` usa `bash bash-arch git ghostty opencode starship` y
  agrega `git-delta` solo si `delta` existe.
- Sigue sin usar `stow --adopt`; los conflictos se mueven a
  `~/.dotfiles-backup/<timestamp>/`.
- `.stowrc` conserva `--no-folding`.

### Shell / Fish

- **No había archivos Fish**, así que no hubo migración de funciones ni
  variables. Las capacidades equivalentes ya estaban en Bash.
- `bash/.bashrc` ahora carga `/etc/bash.bashrc`, agrega `~/.cargo/bin` al PATH,
  inicializa bash-completion, mantiene una sola inicialización de fzf, zoxide y
  Starship, y carga `~/.config/bash/pacman.sh`.
- `bash/.bash_profile` carga `~/.bashrc` una sola vez.
- `scripts/set-shell.sh`: verifica Bash y `/etc/shells`, lee la shell actual,
  modifica solo al usuario que ejecuta el bootstrap (o `SUDO_USER`), pide
  confirmación y avisa que hay que cerrar sesión.

### OpenCode

- La configuración V2 (`opencode.jsonc`, `AGENTS.md`, `dcp.jsonc`, plantilla
  OmniRoute) se conservó sin cambios funcionales: modelo, plugins, permisos y
  protecciones de secretos siguen igual.
- Solo cambió la **instalación**: ahora es el paquete oficial `opencode` de
  `extra` (V2), no el RPM/bundle de Fedora ni un script remoto.
- No se agregaron plugins, proveedores ni credenciales.

### Documentación

- `README.md` reescrito para CachyOS.
- Nuevos `docs/cachyos-post-install.md` y `docs/cachyos-reinstall.md`.
- `docs/applications.md`, `docs/opencode.md` y `docs/dms.md` actualizados.
- Eliminado `docs/security-hardening.md` (auditoría Fedora 45, fuera del alcance
  y sin relación con este bootstrap). El README ya no promete endurecimiento.

## 4. Archivos nuevos, modificados y eliminados

### Nuevos

- `bash/.bash_profile`
- `bash-arch/.config/bash/pacman.sh`
- `packages/base.txt`
- `packages/apps.txt`
- `scripts/set-shell.sh`
- `docs/cachyos-post-install.md`
- `docs/cachyos-reinstall.md`

### Modificados

- `bootstrap.sh`
- `scripts/bootstrap.sh`
- `scripts/lib.sh`
- `scripts/install-packages.sh`
- `scripts/deploy-dotfiles.sh`
- `scripts/verify.sh`
- `scripts/diagnose-system.sh`
- `scripts/install-docker.sh`
- `scripts/install-netbird.sh`
- `scripts/install-graphify.sh`
- `scripts/install-addy-skills.sh` (comentario)
- `bash/.bashrc`
- `packages/common.txt`
- `packages/optional.txt`
- `README.md`
- `AUDIT.md`
- `docs/applications.md`
- `docs/opencode.md`
- `docs/dms.md`

### Eliminados

- `bash-dnf/.config/bash/dnf.sh` (renombrado a `bash-arch/.../pacman.sh`)
- `packages/fedora.txt`
- `packages/copr.txt`
- `packages/dms.txt`
- `packages/flatpak.txt`
- `scripts/configure-dnf.sh`
- `scripts/install-multimedia.sh`
- `scripts/install-zed.sh`
- `scripts/install-obsidian.sh`
- `scripts/install-opencode.sh`
- `docs/fedora-post-install.md`
- `docs/fedora-reinstall.md`
- `docs/security-hardening.md`

## 5. Manifiesto definitivo de paquetes

```
base:    bash git stow sudo curl ca-certificates jq util-linux tar gzip bzip2
         xz zstd unzip 7zip findutils
common:  bash-completion ripgrep fzf fd bat eza zoxide starship tree tmux
         neovim python uv github-cli git-delta
apps:    ghostty zed opencode obsidian
optional: gcc make go rust ffmpeg gst-plugins-good gst-plugins-bad
          gst-plugins-ugly gst-libav obs-studio
```

## 6. Validaciones realizadas

| Comprobación | Resultado |
|---|---|
| `bash -n` en bootstrap, scripts, `.bashrc`, `.bash_profile`, `pacman.sh` | **Verificado**: sin errores |
| `shellcheck -x` en bootstrap y scripts | **Verificado parcialmente**: sin errores; quedan avisos informativos (SC1091/SC2015 y variables usadas por archivos sourceados) |
| Existencia de paquetes en Arch `core`/`extra` | **Verificado** contra archlinux.org |
| Ausencia de referencias Fedora/DNF en scripts y paquetes | **Verificado** (solo quedan menciones opcionales a Flatpak en diagnóstico y post-instalación) |
| Ausencia de archivos/referencias Fish | **Verificado** en árbol e historial |
| Estructura de paquetes Stow y destinos únicos | **Verificado** estáticamente (sin destinos duplicados) |
| Despliegue Stow y re-simulación en un `$HOME` temporal | **Verificado**: enlaces correctos y simulación posterior limpia |
| `deploy-dotfiles.sh --dry-run` con archivos reales en `$HOME` | **Verificado**: lista conflictos, no crea respaldos ni escribe enlaces, termina con código 0 |
| Idempotencia de instalación/despliegue | **Verificado por diseño** y por simulación Stow; falta ejecución real con pacman/chsh |
| Sintaxis JSONC de OpenCode | **Verificado** con el parser de `verify.sh` en modo lectura |
| `gh auth status`, plugins y versiones de apps | `gh` sin autenticar; plugins no verificados por el aborto de `verify.sh`, corregido en la sección 8 |
| `pacman -S --needed`, `chsh`, enlaces Stow reales | **Verificado en CachyOS**: paquetes ya instalados; enlaces reales correctos; `chsh` no fue necesario (la shell ya era Bash) |

No se afirma que el bootstrap completo funcione en CachyOS hasta ejecutar la
prueba de la sección 7.

## 7. Plan de validación en CachyOS

### 7.1 Instalación y paquetes

1. Clonar el repo en `~/dotfiles`.
2. Ejecutar `./bootstrap.sh --dry-run` y revisar que no haya errores de pacman,
   conflictos ni rutas.
3. Ejecutar `./bootstrap.sh` (con `sudo` disponible).
4. Confirmar que `pacman -S --needed` resolvió la base de datos y que no hubo
   conflictos de paquetes.
5. Verificar que DMS, niri y el display manager sigan intactos.
6. Ejecutar `gh auth login`.

### 7.2 Shell: Fish → Bash

Estado actual: **Bash es la shell objetivo**. Este repositorio no contiene
archivos Fish ni instala Fish. Si el equipo CachyOS tiene `~/.config/fish`, se
conserva intacto hasta validar la migración. **Zsh queda fuera de esta etapa**:
no se instala ni se configura.

1. Comprobar la shell inicial:

   ```bash
   getent passwd "$USER" | cut -d: -f7
   echo "$SHELL"
   ps -p $$ -o comm=
   ```

2. Verificar que Bash exista y figure en `/etc/shells`:

   ```bash
   command -v bash
   readlink -f "$(command -v bash)"
   cat /etc/shells
   ```

3. Si existe configuración local de Fish, inventariarla antes de migrar:

   ```bash
   ls -la ~/.config/fish
   grep -RInE 'alias|function|set -gx|fish_add_path|starship init|zoxide init|fzf' ~/.config/fish
   ```

   Comparar aliases, funciones, variables de entorno, PATH e inicializaciones
   con `~/.bashrc` y `~/.bash_profile`. No borrar `~/.config/fish` durante la
   validación.

4. Ejecutar `./scripts/set-shell.sh` (o `./bootstrap.sh`) y confirmar el `chsh`.
5. Cerrar sesión y volver a entrar.
6. Verificar la shell efectiva:

   ```bash
   echo "$SHELL"
   ps -p $$ -o comm=
   getent passwd "$USER"
   ```

7. Confirmar que `~/.bash_profile` carga `~/.bashrc` y que Starship, zoxide y fzf
   se inicializan una sola vez (`./scripts/verify.sh`).

### 7.3 Verificación, aplicaciones y rollback

8. Ejecutar `./scripts/verify.sh` y `./scripts/diagnose-system.sh`.
9. Probar `starship`, `zoxide`, `fzf`, `eza`, `bat`, `gh`, `opencode`, `zed`,
   `ghostty` y `obsidian`.
10. Reejecutar `./bootstrap.sh` para confirmar idempotencia (sin instalaciones
    ni enlaces nuevos).
11. Probar la vuelta atrás de Stow en un usuario de prueba.

## 8. Fuera de alcance

- No se instala ni configura DMS, niri, display manager, GNOME, KDE, Waybar ni
  componentes del escritorio.
- No se versionan `~/.ssh`, historiales, `~/.cache`, `~/.config/gh`, `~/venvs`,
  `~/.var` ni secretos de OpenCode.
- No se modifican PAM, sysctl, repositorios del sistema ni políticas de contraseñas.
- No se instala ni configura Zsh en esta etapa; la migración Bash → Zsh se
  auditará por separado.
- No se hacen commits ni pushes.

## 8. Auditoría final en CachyOS (2026-11-12)

### 8.1 Hallazgos corregidos

| # | Problema | Severidad | Corrección |
|---|---|---|---|
| 1 | `verify.sh` abortaba con `set -e` en `have zed && info` (`zed` no existe; el binario es `zeditor`) | Crítico | `if have zeditor/zed`, variables locales y resumen final |
| 2 | NVIDIA falso negativo: solo buscaba paquetes `nvidia*` exactos y `lsmod` | Crítico | `nvidia-smi` como señal principal, `/sys/module/nvidia` y `lspci -k` como respaldos; paquetes aparte |
| 3 | `install-packages.sh --with-optional` abortaba en `pkg_installed && continue` | Crítico | `if pkg_installed; then continue; fi` |
| 4 | `ghostty +show-config` mostraba `/bin/fish` por `$SHELL` obsoleto | Importante | `command = /usr/bin/bash` en la config; documentado el refresco de sesión |
| 5 | `--posix` en `ps` parecía un error | Importante | Es la integración de Ghostty; `ghostty.bash` ejecuta `set +o posix` |
| 6 | `verify.sh` no comprobaba la config efectiva de Ghostty | Importante | Verifica `command` Bash y `theme = dankcolors` |
| 7 | `cursor` y `no-cursor` contradictorios | Menor | Se dejó `no-cursor,sudo,title` |
| 8 | Opcionales ausentes reportados como warning | Menor | `fwupd`, `mokutil`, `cifs`, `smbclient` y `bluez` pasan a informativos |
| 9 | `pacman --version \| head -n1` mostraba una línea vacía | Menor | `grep -m1 .` |
| 10 | Docs decían `zed --version` | Menor | `zeditor --version` |

### 8.2 Estado verificado (no modificado)

- `getent passwd xizzy` → `/usr/bin/bash`; Bash 5.3; login shell correcto.
- Ghostty: `command = /usr/bin/bash`, `theme = dankcolors`; el proceso real es
  `/usr/bin/bash --posix` (integración) y POSIX queda desactivado.
- NVIDIA: RTX 3070 Ti, driver 620.70.06 activo (`nvidia-smi`), `/sys/module/nvidia`
  presente, `lspci` reporta `Kernel driver in use: nvidia`.
- Stow: enlaces correctos y simulación limpia.
- `~/.config/ghostty/themes/dankcolors` existe como archivo real; el fallback no
  lo tocó.
- Niri y DMS no fueron modificados.

### 8.3 Pruebas ejecutadas

| Prueba | Resultado |
|---|---|
| `bash -n` en todos los scripts y configs Bash | OK |
| ShellCheck | No instalado; no se agregó como dependencia |
| `./bootstrap.sh --dry-run` | OK, sin cambios |
| `./bootstrap.sh --with-optional --dry-run` | OK, ejercita el camino corregido |
| `./scripts/verify.sh` | OK con advertencias esperadas (`gh` sin auth, `$SHELL` viejo) |
| `./scripts/diagnose-system.sh` | OK; NVIDIA detectado como activo |
| Simulación Stow (`stow -n -v`) | Limpia |
| Enlaces `~/.bashrc`, `.bash_profile`, `.gitconfig`, Ghostty, Starship, OpenCode | Correctos |
| Inicialización única de Starship/zoxide | Verificada |
| Despliegue en `$HOME` temporal con conflicto y backup | Verificado (sin tocar el usuario real) |
| Segunda ejecución de `--dry-run`/verify | Idempotente |

### 8.4 Pendientes/manual

- Cerrar sesión por completo y volver a entrar para refrescar `SHELL` en
  systemd/Ghostty (no alcanza `exec bash`).
- `gh auth login` (no automatizado).
- ShellCheck no está instalado; ejecutarlo cuando esté disponible.
- No se hizo commit ni push.
