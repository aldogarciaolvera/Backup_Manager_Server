# Changelog

Todos los cambios importantes del proyecto se documentarán en este archivo.

El formato está basado en Keep a Changelog y el proyecto usa Semantic Versioning.

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
