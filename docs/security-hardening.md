# Seguridad: auditoría Linaudit y endurecimiento

Fecha de la auditoría: 2026-11-08. Equipo: Fedora 45 Workstation, DNF5 5.4.7.0,
kernel 6.17.x, escritorio niri + DMS.

Este documento registra la evidencia de los 19 hallazgos de Linaudit, su
interpretación y las acciones propuestas. **No se aplicó ninguna remediación de
alto riesgo.** PAM, repositorios, sysctl y políticas de contraseñas quedan bajo
aprobación explícita.

## Método

```bash
linaudit --no-interactive --profile desktop --plain --json \
  --output /tmp/opencode/linaudit-before.json
```

- Linaudit es de solo lectura.
- La corrida fue **sin root**, por eso 19 controles quedaron en `ERROR` y 7 en `NA`
  (no se pudieron leer archivos o rutas privilegiadas).
- Resultado: **6/10**, cobertura 73,7 %, 54 PASS, **7 FAIL + 12 WARN**.
- El JSON de evidencia no se versiona: contiene rutas y estado del equipo.

Los 19 hallazgos son los 7 `FAIL` y 12 `WARN` siguientes. Las severidades son las
que reporta la herramienta.

Clasificación usada:

- **Confirmado**: la configuración existe y el riesgo es real en este equipo.
- **Falso positivo**: la herramienta marca un estado esperado, transitorio o
  propio del paquete; no hay acción útil.
- **Informativo**: dato correcto pero de bajo impacto o dependiente de un uso
  concreto (por ejemplo, solo si se usa Apache).
- **Requiere aprobación**: un cambio reduciría el riesgo, pero puede afectar
  red, login, permisos o aplicaciones; no se aplica sin decisión explícita.

## Tabla de hallazgos

| ID | Sev. | Estado | Clasificación | Evidencia | Acción propuesta | ¿Cambio requiere aprobación? |
|---|---|---|---|---|---|---|
| PER-009 | CRITICAL | FAIL | Confirmado (alcance limitado) | `/etc/pam.d/anaconda:2`: `auth sufficient pam_permit.so` | Revisar si el stack `anaconda` se usa en el equipo; no editar aún | **Sí** |
| PAT-006 | HIGH | FAIL | Falso positivo práctico | `repo_gpgcheck=0` en COPR dms, dux-repo y niri; `gpgcheck=1` | Dejar como está: los paquetes sí se firman y COPR no firma metadatos | No |
| FS-011 | HIGH | WARN | Informativo | `cap_setuid/setgid` en `suexec` y `sssd`; `cap_dac_read_search` en `sssd_pam` | Son defaults de paquetes; no quitar sin probar Apache/SSSD | **Sí** |
| NET-011 | MEDIUM | FAIL | Confirmado | `net.ipv4.conf.all.rp_filter = 0` | Probar `1` en caliente; persistir solo si VPN/red siguen bien | **Sí** |
| NET-014 | LOW | FAIL | Confirmado | `net.ipv4.conf.all.log_martians = 0` | Activar `=1`; solo genera logs | **Sí** |
| PAT-003 | MEDIUM | WARN | Informativo | `dnf-automatic` no instalado ni habilitado | Documentar excepción o instalar `dnf-automatic` + timer | **Sí** |
| FS-017 | MEDIUM | FAIL | Falso positivo | 4 directorios world-writable sin sticky: caché `swcatalog` y `gdm/seat0` | Estado transitorio de caché; no aplicar `chmod +t` a ciegas | No |
| FS-018 | MEDIUM | WARN | Falso positivo | 7 archivos sin dueño/grupo en caché `swcatalog` y `gdm` | Caché regenerable; no forzar dueño sin validar | No |
| ACC-006 | MEDIUM | WARN | Falso positivo | Cuenta `greeter` con `/bin/bash` | Default de GDM; cambiarla puede romper el login gráfico | No |
| ACC-010 | MEDIUM | WARN | Informativo | `pwquality` sin `minlen` explícito (default 8) | Fijar `minlen = 12` en `/etc/security/pwquality.conf` | **Sí** |
| FS-006 | MEDIUM | WARN | Informativo | `/tmp` sin `noexec` | No aplicar sin probar: rompe instaladores y algunos AppImage | **Sí** |
| FS-007 | MEDIUM | WARN | Informativo | `/var/tmp` no es filesystem separado | No reparticionar por este hallazgo; documentar excepción | No |
| FS-008 | MEDIUM | WARN | Informativo | `/dev/shm` sin `noexec` | Probar: puede romper sandboxes Electron/Chromium | **Sí** |
| HRD-008 | LOW | FAIL | Confirmado | `kernel.kptr_restrict = 0` | Poner `=1`; bajo riesgo | **Sí** |
| HRD-010 | MEDIUM | FAIL | Confirmado | `fs.suid_dumpable = 2` | Poner `=0`; evita core dumps de setuid | **Sí** |
| HRD-016 | LOW | WARN | Informativo | `UMASK 022` en `/etc/login.defs` | Evaluar `027`; afecta permisos de archivos nuevos | **Sí** |
| HRD-017 | LOW | WARN | Informativo | `/etc/issue` y `/etc/issue.net` muestran kernel/versión | Reemplazar por banner estático sin `\r \m \s \v` | **Sí** |
| APP-050 | LOW | WARN | Informativo (solo si se usa httpd) | Apache `ServerTokens`/`ServerSignature` por defecto | Si `httpd` se usa: `ServerTokens Prod`, `ServerSignature Off` | **Sí** |
| APP-051 | MEDIUM | WARN | Informativo (solo si se usa httpd) | Apache con `Options Indexes` en `httpd.conf:149` y `userdir.conf:33` | Quitar `Indexes` o desinstalar `httpd` si no se usa | **Sí** |

## PER-009 — PAM acepta cualquier autenticación

Evidencia exacta:

```text
/etc/pam.d/anaconda:2:auth       sufficient  pam_permit.so
/etc/pam.d/anaconda:3:account    sufficient  pam_permit.so
/etc/pam.d/anaconda:4:password   sufficient  pam_permit.so
```

Verificaciones realizadas:

```bash
grep -rIn 'pam_permit' /etc/pam.d
grep -nE 'pam_permit|pam_exec' /etc/pam.d/sshd /etc/pam.d/system-auth /etc/pam.d/password-auth
```

- Solo `/etc/pam.d/anaconda` contiene `auth sufficient pam_permit.so`.
- `sshd`, `system-auth` y `password-auth` **no** están afectados.
- `anaconda` pertenece al instalador; no es el stack de login del escritorio.
- El riesgo real depende de si algún servicio invoca el stack `anaconda`. No se
  encontró evidencia de eso en esta auditoría.

Propuesta (requiere aprobación):

1. Confirmar el paquete dueño: `rpm -qf /etc/pam.d/anaconda`.
2. Respaldar el archivo fuera del sistema.
3. Evaluar si el equipo usa Anaconda en modo rescate/instalación.
4. Si no se usa, quitar solo la línea `auth sufficient pam_permit.so` y validar
   `sudo -v`, login gráfico y `su`.
5. Si el archivo lo administra un paquete, documentar la excepción en lugar de
   pelear con futuras actualizaciones.

**No se modificó PAM.**

## PAT-006 — Repositorios sin verificación de firma

Evidencia:

```text
/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:duxlabs:dms.repo:8:repo_gpgcheck=0
/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:duxlabs:dux-repo.repo:8:repo_gpgcheck=0
/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:yalter:niri.repo:8:repo_gpgcheck=0
```

Interpretación:

- Los tres repos tienen `gpgcheck=1`: los **paquetes** se verifican.
- `repo_gpgcheck=0` significa que los **metadatos** (`repomd.xml`) no se firman.
- Fedora, RPM Fusion y Terra también usan `repo_gpgcheck=0`; COPR no suele firmar
  metadatos. Es un hallazgo mayormente estructural, no una configuración rota.
- Cambiar `repo_gpgcheck=1` sin una clave de metadatos válida rompería `dnf`.

Propuesta (requiere aprobación):

1. Confirmar con `dnf repoinfo` qué clave usa cada repo.
2. No habilitar `repo_gpgcheck=1` en COPR salvo que el proyecto publique firma de
   metadatos.
3. Si se quiere reducir superficie, evaluar reemplazar el COPR de niri/DMS por
   paquetes oficiales cuando estén disponibles.

**No se modificó ningún repositorio.**

## Hallazgos de bajo riesgo para una fase posterior

Con aprobación, el orden seguro sería:

```bash
# 1. Respaldar sysctl y login.defs
sudo cp -a /etc/sysctl.d /root/sysctl.d.bak
sudo cp -a /etc/login.defs /root/login.defs.bak

# 2. Cambios de kernel/red, uno por vez
sudo sysctl -w kernel.kptr_restrict=1
sudo sysctl -w fs.suid_dumpable=0
sudo sysctl -w net.ipv4.conf.all.log_martians=1

# 3. Persistir en /etc/sysctl.d/99-hardening.conf y reiniciar
```

`net.ipv4.conf.all.rp_filter=1` requiere probar VPN, NetBird y múltiples rutas
antes de persistirlo.

Para Apache, si `httpd` no se usa:

```bash
sudo systemctl status httpd
sudo dnf remove httpd          # solo con aprobación
```

Si se usa, editar `ServerTokens Prod`, `ServerSignature Off` y quitar `Indexes`.

## Lo que no se hizo

- No se tocó PAM.
- No se deshabilitó GPG.
- No se cambiaron repositorios ni claves.
- No se aplicaron sysctl, umask, banners ni políticas de contraseña.
- No se desinstaló `httpd`.
- No se reinició el equipo.
- No se ejecutaron remediaciones de alto riesgo.

## Cobertura pendiente

**Sí hace falta una corrida como root para completar la cobertura.** La corrida
actual, sin privilegios, dejó 19 controles en `ERROR` y 7 en `NA`; esos controles
no pudieron evaluarse y por eso el resultado de 6/10 no cubre todo el sistema.

Para completar los controles que requieren privilegios:

```bash
sudo linaudit --no-interactive --profile desktop --plain --json \
  --output /tmp/opencode/linaudit-root.json
```

Es opcional y de solo lectura. No es requisito para el bootstrap.
