TFI - Bases de Datos I
Alumno: Emperador, Javier
Comisión: 2
Motor: MySQL 8.0

# ORDEN DE EJECUCIÓN

01_esquema.sql - Creación del esquema: tablas, PK, FK, UNIQUE, CHECK
02_catalogos.sql - Tablas catálogo / maestras (datos de referencia)
03_carga_masiva.sql - Generación y carga masiva de datos (mínimo 10.000 registros)
04_indices.sql - Creación de índices para optimización de consultas
05_consultas.sql - Consultas avanzadas (JOIN, GROUP BY/HAVING, subconsultas)
06_explain.sql - Medición comparativa con/sin índice (EXPLAIN / EXPLAIN ANALYZE)
07_vistas.sql - Creación de vistas útiles y de seguridad
08_seguridad.sql - Usuario con privilegios mínimos, permisos y prueba anti-inyección
09_transacciones.sql - Transacciones con START TRANSACTION / COMMIT / ROLLBACK
10_concurrencia_guiada.sql - Simulación de deadlock, niveles de aislamiento y retry

# NOTAS

- Todos los scripts son idempotentes (usan DROP IF EXISTS / CREATE OR REPLACE).
- Ejecutar en el orden indicado; cada script depende del anterior.
- Probado en MySQL 8.0 sobre Windows 11.
