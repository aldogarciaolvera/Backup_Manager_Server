# Backup Manager

Backup Manager es una herramienta modular escrita en Bash para realizar respaldos y restauraciones de servidores Linux y bases de datos.

Actualmente soporta:

- Ubuntu Server
- PostgreSQL
- MySQL
- Docker
- Verificación SHA-256
- Compresión Zstandard
- Retención automática
- Restauración segura

## Versión actual

```text
1.0.1

---

# Características

- ✅ Backup completo del servidor
- ✅ Backup lógico de PostgreSQL (`pg_dumpall`)
- ✅ Backup lógico de MySQL (`mysqldump`)
- ✅ Compresión con Zstandard (`.tar.zst`)
- ✅ Verificación SHA-256
- ✅ Validación de integridad antes de restaurar
- ✅ Restauración segura del servidor
- ✅ Restauración temporal de PostgreSQL
- ✅ Restauración temporal de MySQL
- ✅ Política automática de retención
- ✅ Workspaces temporales administrados
- ✅ Bloqueo mediante `flock`
- ✅ Automatización mediante `systemd`
- ✅ Versionado y CHANGELOG

---

# Estructura

```text
backup-manager/
├── backup.sh
├── bootstrap.sh
├── config.sh
├── README.md
├── docs/
├── tests/
├── lib/
└── modules/
```

---

# Uso

Backup completo

```bash
sudo ./backup.sh all
```

Backup del servidor

```bash
sudo ./backup.sh server
```

Backup PostgreSQL

```bash
sudo ./backup.sh postgres
```

Backup MySQL

```bash
sudo ./backup.sh mysql
```

Restore MySQL

```bash
sudo ./backup.sh restore mysql
```

Restore PostgreSQL

```bash
sudo ./backup.sh restore postgres
```

Ejecutar retención

```bash
sudo ./backup.sh cleanup
```

Version

```bash
sudo ./backup.sh --version

---

# Requisitos

- Ubuntu Server
- Bash 5+
- Docker
- PostgreSQL
- MySQL
- zstd
- sha256sum

---

# Documentación

La documentación técnica se encuentra en:

```
docs/
```

---

# Estado del proyecto

Versión actual:

```
v1.0.1
```

Proyecto completamente funcional para:

- Backup
- Restore
- Validación
- Integridad
- Retención



---

# Flujo de ejecución

```text
                +----------------------+
                |  systemd timer       |
                | 03:00 AM diariamente |
                +----------+-----------+
                           |
                           v
                 backup.sh all
                           |
          +----------------+----------------+
          |                |                |
          v                v                v
      Server          PostgreSQL        MySQL
          |                |                |
          +----------------+----------------+
                           |
                           v
              Compresión + SHA-256
                           |
                           v
                Política de retención
                           |
                           v
                  Backup final listo
```

---

# Automatización con systemd

## Servicio

`/etc/systemd/system/backup-manager.service`

```ini
[Unit]
Description=Backup Manager - Respaldo completo del servidor
RequiresMountsFor=/mnt/storage
After=docker.service network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=root
Group=root
ExecStart=/opt/scripts/backup-manager/backup.sh all

Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7

PrivateTmp=no
ProtectSystem=full
ReadWritePaths=/mnt/storage/backups /tmp/backup-manager /opt/scripts/backup-manager/logs /run/lock

StandardOutput=journal
StandardError=journal
```

## Timer

`/etc/systemd/system/backup-manager.timer`

```ini
[Unit]
Description=Ejecuta Backup Manager diariamente

[Timer]
OnCalendar=*-*-* 03:00:00
Persistent=true
RandomizedDelaySec=10m
Unit=backup-manager.service

[Install]
WantedBy=timers.target
```

## Instalación

```bash
sudo systemctl daemon-reload
sudo systemctl enable backup-manager.timer
sudo systemctl start backup-manager.timer
```

## Verificación

```bash
systemctl status backup-manager.timer
systemctl list-timers backup-manager.timer
journalctl -u backup-manager.service
journalctl -u backup-manager.service --since "24 hours ago"
```

## Funcionamiento

El timer ejecuta diariamente:

```bash
backup.sh all
```

Incluye:

- Backup del servidor.
- Backup de PostgreSQL.
- Backup de MySQL.
- Limpieza automática mediante la política de retención.

Si el servidor estaba apagado durante la hora programada, `Persistent=true` ejecutará el respaldo pendiente al iniciar nuevamente el sistema.
