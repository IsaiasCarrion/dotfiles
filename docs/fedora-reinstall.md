# Reinstalación limpia de Fedora 45

Objetivo: recuperar el entorno de trabajo desde una instalación limpia de Fedora 45
usando este repositorio, sin perder configuraciones personales y sin repetir
instalaciones que ya existan.

## 0. Antes de borrar el sistema

Guardá fuera del equipo o en una partición aparte:

- El repositorio `~/dotfiles` (o al menos `git push` de los cambios que quieras conservar).
- `~/.gitconfig.local` y `~/.bashrc.local`.
- `~/.ssh/` (claves y `config`), sin subirlas a ningún repositorio.
- `~/.config/opencode/service.json` (secreto local, nunca versionado).
- Vaults de Obsidian y `~/.var/app/md.obsidian.Obsidian/`.
- Cualquier archivo de `~/.dotfiles-backup/` que quieras conservar.

No es necesario respaldar configuraciones administradas por DMS o niri: cada
aplicación las regenera.

## 1. Instalar Fedora 45 y actualizar

1. Instalación normal de Fedora 45 Workstation.
2. Primer arranque y actualización completa:

```bash
sudo dnf upgrade --refresh
sudo reboot            # solo si el kernel o el firmware lo requieren
```

3. Verificá la versión:

```bash
cat /etc/fedora-release
dnf --version          # debe ser dnf5
```

## 2. Recuperar el repositorio

```bash
sudo dnf install -y git curl
git clone https://github.com/IsaiasCarrion/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

Si traés un backup local, copiá el contenido a `~/dotfiles` en lugar de clonar.
Revisá `git status` antes de seguir y no descartes cambios sin revisarlos.

## 3. Bootstrap

Primero simulá; después aplicá:

```bash
./bootstrap.sh --dry-run
./bootstrap.sh
```

Pasos que ejecuta:

1. RPM/COPR/Flatpak que falten (`install-packages.sh`).
2. CLI de OpenCode V2 (`install-opencode.sh`).
3. Aplicaciones obligatorias: Zed y Obsidian (`install-zed.sh`, `install-obsidian.sh`).
4. Despliegue Stow con respaldo de conflictos (`deploy-dotfiles.sh`).
5. Verificación (`verify.sh`).

Opciones útiles:

```bash
./bootstrap.sh --yes              # sin preguntas de respaldo
./bootstrap.sh --with-optional    # toolchains y códecs
./bootstrap.sh --no-apps          # no instala Zed/Obsidian
./bootstrap.sh --no-deploy        # solo paquetes y apps
```

## 4. Restaurar configuración local

Estos archivos no están en el repositorio:

```bash
cp /ruta/backup/gitconfig.local   ~/.gitconfig.local
cp /ruta/backup/bashrc.local      ~/.bashrc.local
cp -a /ruta/backup/ssh            ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config ~/.ssh/id_* 2>/dev/null || true
```

Identidad de Git:

```bash
git config --file ~/.gitconfig.local user.name  "Tu Nombre"
git config --file ~/.gitconfig.local user.email "tu@correo"
```

Obsidian (si usabas Flatpak):

```bash
cp -a /ruta/backup/md.obsidian.Obsidian ~/.var/app/
```

Los vaults se abren desde Obsidian; el repositorio no los crea ni los modifica.

## 5. Aplicaciones

```bash
zed --version
~/.local/bin/obsidian --version     # o: flatpak run md.obsidian.Obsidian
```

- Zed se instala con el instalador oficial y conserva `~/.config/zed/`.
- Obsidian usa el AppImage oficial en equipos nuevos; si restauraste el Flatpak,
  el script lo detecta y no instala una copia extra.
- OBS Studio es opcional: `./bootstrap.sh --with-optional`.

Detalle: [applications.md](applications.md).

## 6. Módulos opcionales

```bash
./scripts/configure-dnf.sh           # ajustes de rendimiento DNF5
./scripts/install-multimedia.sh      # RPM Fusion + códecs
./scripts/install-docker.sh          # solo si necesitás Docker CE
./scripts/install-netbird.sh         # cliente NetBird
```

Ninguno se ejecuta solo. Revisá cada `--dry-run` antes de aplicar.

## 7. Verificación final

```bash
./scripts/verify.sh
./scripts/diagnose-system.sh
```

Comprobá además:

```bash
niri validate -c ~/.config/niri/config.kdl
ghostty +validate-config
starship --version
opencode --version
```

## 8. Seguridad

El repositorio **no aplica** endurecimiento automático. Si querés revisar el
estado del equipo:

```bash
linaudit --no-interactive --profile desktop --plain
```

Los hallazgos, su evidencia y las acciones que requieren aprobación están en
[security-hardening.md](security-hardening.md). No modifiques PAM ni repositorios
sin revisar ese documento.

## Checklist final

- [ ] Fedora 45 actualizado y DNF5 funcionando.
- [ ] Repositorio clonado en `~/dotfiles`.
- [ ] `./bootstrap.sh` terminó sin errores.
- [ ] Zed y Obsidian abren y conservan su configuración.
- [ ] `./scripts/verify.sh` pasa.
- [ ] `niri`, DMS, Ghostty, Bash y Starship funcionan.
- [ ] Configuración local y claves restauradas.
- [ ] Vaults de Obsidian intactos.
- [ ] Módulos opcionales instalados solo si hacen falta.
