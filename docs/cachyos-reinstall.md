# Reinstalación limpia de CachyOS

Objetivo: recuperar el entorno de trabajo desde una instalación limpia de
CachyOS usando este repositorio, sin perder configuraciones personales y sin
repetir instalaciones que ya existan.

## 0. Antes de borrar el sistema

Guardá fuera del equipo o en una partición aparte:

- El repositorio `~/dotfiles` (o `git push` de los cambios que quieras conservar).
- `~/.gitconfig.local` y `~/.bashrc.local`.
- `~/.config/fish/` si existía (se conserva hasta validar Bash; no se migra a ciegas).
- `~/.ssh/` (claves y `config`), sin subirlas a ningún repositorio.
- `~/.config/opencode/service.json` (secreto local, nunca versionado).
- Vaults de Obsidian y cualquier archivo de `~/.dotfiles-backup/` que quieras
  conservar.

No es necesario respaldar configuraciones de DMS o niri: cada aplicación las
regenera.

## 1. Instalar CachyOS

1. Instalación normal de CachyOS con el escritorio que ya uses (DMS/niri).
2. Primer arranque y actualización completa:

```bash
sudo pacman -Syu
sudo reboot            # solo si el kernel o el firmware lo requieren
```

3. Verificá la versión y que pacman funcione:

```bash
cat /etc/os-release
pacman --version
```

## 2. Recuperar el repositorio

```bash
sudo pacman -S --needed git curl
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

1. Paquetes oficiales que falten (`install-packages.sh`).
2. Despliegue Stow con respaldo de conflictos (`deploy-dotfiles.sh`).
3. Bash como shell de login (`set-shell.sh`).
4. Verificación (`verify.sh`).

Opciones útiles:

```bash
./bootstrap.sh --yes              # sin preguntas de respaldo/shell
./bootstrap.sh --with-optional    # toolchains y códecs
./bootstrap.sh --no-apps          # no instala Ghostty/Zed/OpenCode/Obsidian
./bootstrap.sh --no-deploy        # solo paquetes
./bootstrap.sh --no-shell         # no cambia la shell de login
```

## 4. Autenticación de GitHub

La única acción manual esperada:

```bash
gh auth login
```

El helper de credenciales de `~/.gitconfig` usa `gh auth git-credential`.

## 5. Restaurar configuración local

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

Obsidian: abrí los vaults desde la aplicación; el repositorio no los crea ni los
modifica.

## 6. Aplicaciones

```bash
ghostty --version
zeditor --version
opencode --version
obsidian --version
```

Todas se instalan con pacman desde `packages/apps.txt`. No hay AppImage
administrado ni Flatpak obligatorio.

## 7. Módulos opcionales

```bash
./scripts/install-docker.sh          # solo si necesitás Docker
./scripts/install-netbird.sh         # NetBird desde AUR (paru/yay)
./scripts/install-addy-skills.sh     # skills de OpenCode
./scripts/install-graphify.sh        # Graphify
```

Ninguno se ejecuta solo. Revisá cada `--dry-run` antes de aplicar.

## 8. Verificación final

```bash
./scripts/verify.sh
./scripts/diagnose-system.sh

niri validate -c ~/.config/niri/config.kdl
ghostty +validate-config
starship --version
opencode --version
```

Cerrá sesión y volvé a entrar para confirmar que Bash es la shell de login:

```bash
echo "$SHELL"
ps -p $$ -o comm=
getent passwd "$USER" | cut -d: -f7
```

## Checklist final

- [ ] CachyOS actualizado y pacman funcionando.
- [ ] Repositorio clonado en `~/dotfiles`.
- [ ] `./bootstrap.sh` terminó sin errores.
- [ ] `gh auth login` completado.
- [ ] Bash es la shell de login.
- [ ] `./scripts/verify.sh` pasa.
- [ ] DMS, niri, Ghostty, Zed y OpenCode funcionan.
- [ ] Configuración local y claves restauradas.
- [ ] Vaults de Obsidian intactos.
- [ ] Módulos opcionales instalados solo si hacen falta.
