# Arquitectura

## Visión General

Backup Manager está diseñado con una arquitectura modular donde cada componente tiene una única responsabilidad.

El objetivo es que agregar un nuevo tipo de respaldo o restauración requiera únicamente crear un nuevo módulo, sin modificar el resto del sistema.

---

# Arquitectura General

```text
                    backup.sh
                        │
                        ▼
                 bootstrap.sh
                        │
        ┌───────────────┼────────────────┐
        │               │                │
        ▼               ▼                ▼
    config.sh       lib/*.sh       modules/*
                            │
            ┌───────────────┴───────────────┐
            ▼                               ▼
      backup modules                 restore modules
```

---

# Componentes

## backup.sh

Punto de entrada del sistema.

Responsable de:

- interpretar comandos
- validar parámetros
- ejecutar módulos
- iniciar retención

No contiene lógica de respaldo.

---

## bootstrap.sh

Carga todo el proyecto.

Responsabilidades:

- configuración
- librerías
- módulos

De esta forma cualquier script tiene acceso a todas las funciones comunes.

---

## config.sh

Contiene toda la configuración global.

Ejemplos:

- rutas
- directorios
- retención
- nombres
- exclusiones

---

# Librerías

## logger.sh

Sistema de logs.

Niveles:

- INFO
- SUCCESS
- WARNING
- ERROR

---

## workspace.sh

Administra los directorios temporales.

Funciones principales:

- start_managed_workspace
- get_active_workspace
- finish_managed_workspace

---

## archive.sh

Responsable de:

- compresión
- extracción
- checksum
- validación

---

## pipeline.sh

Centraliza la generación del respaldo.

Se encarga de:

1. manifest
2. compresión
3. checksum
4. validación
5. mover al destino final

---

## restore.sh

Funciones reutilizables para restauraciones.

Ejemplos:

- validar backup
- localizar respaldo más reciente
- preparar dumps

---

## retention.sh

Implementa la política de retención.

---

# Módulos

Cada módulo únicamente conoce su propio servicio.

Ejemplo:

backup/postgres.sh

solamente sabe cómo respaldar PostgreSQL.

No conoce:

- checksum
- compresión
- retención
- workspaces

Eso queda delegado a las librerías.

---

# Flujo de Backup

```text
backup.sh
      │
      ▼
módulo
      │
      ▼
workspace
      │
      ▼
generar datos
      │
      ▼
pipeline
      │
      ▼
manifest
      │
      ▼
compresión
      │
      ▼
checksum
      │
      ▼
validación
      │
      ▼
destino final
```

---

# Flujo de Restore

```text
backup.sh restore
        │
        ▼
módulo restore
        │
        ▼
resolver respaldo
        │
        ▼
validar checksum
        │
        ▼
workspace
        │
        ▼
extraer dump
        │
        ▼
preparar dump
        │
        ▼
restaurar
        │
        ▼
validar
        │
        ▼
limpieza
```

---

# Principios del proyecto

- Responsabilidad única
- Reutilización de código
- Modularidad
- Restauraciones seguras
- Validación antes de restaurar
- Limpieza automática
- Bajo acoplamiento
- Alta cohesión

---

# Estado actual

Versión:

```
1.0.0
```

Componentes implementados:

- Backup Server
- Backup PostgreSQL
- Backup MySQL
- Restore PostgreSQL
- Restore MySQL
- Pipeline
- Workspaces
- Retención
- Manifest
- SHA-256
