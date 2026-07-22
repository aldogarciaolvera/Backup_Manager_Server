## [1.0.3] - 2026-07-22

### Changed

- Preparación de la versión 1.0.3.

## [1.0.2] - 2026-07-22

### Changed

- Preparación de la versión 1.0.2.

# Changelog

Todos los cambios importantes del proyecto se documentarán en este archivo.

El formato está basado en Keep a Changelog y el proyecto usa Semantic Versioning.

## 1.0.1 - 2026-07-22

### Added

- Safe server restore to an isolated destination
- PostgreSQL restore to a protected temporary database
- MySQL restore to a protected temporary database
- CLI restore commands for server, PostgreSQL and MySQL

### Fixed

- PostgreSQL restore no longer includes `CREATE DATABASE` statements from subsequent databases in the `pg_dumpall` output
- PostgreSQL restore CLI support is now documented in `--help`
- Restore modules now validate archive integrity and SHA-256 checksums before importing
- Temporary restore workspaces are cleaned after successful execution

### Validated

- Server restore: 1,795 files and 666 directories
- PostgreSQL restore: 64 tables
- MySQL restore: 5 tables

## [1.0.0] - 2026-07-21

### Added

- Respaldo del servidor.
- Respaldo completo de PostgreSQL mediante `pg_dumpall`.
- Respaldo de bases de datos MySQL mediante `mysqldump`.
- Restauración de bases PostgreSQL.
- Restauración de bases MySQL.
- Resolución automática del respaldo más reciente.
- Validación de archivos antes de restaurar.
- Verificación de integridad mediante SHA-256.
- Compresión de respaldos con Zstandard.
- Generación de manifiestos.
- Pipeline reutilizable para finalizar respaldos.
- Administración centralizada de workspaces temporales.
- Limpieza automática de workspaces.
- Política de retención configurable.
- Sistema de logging.
- Manejo centralizado de errores.
- Configuración centralizada en `config.sh`.
- Arquitectura modular para backup y restore.
- Documentación inicial del proyecto.
