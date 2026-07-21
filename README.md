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
1.0.0

---

# Características

- Backup completo del servidor
- Backup lógico de PostgreSQL
- Backup lógico de MySQL
- Restore de PostgreSQL
- Restore de MySQL
- Manifiestos JSON
- Checksums SHA-256
- Verificación de integridad
- Política de retención
- Workspaces temporales administrados

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
v1.0.0
```

Proyecto completamente funcional para:

- Backup
- Restore
- Validación
- Integridad
- Retención
