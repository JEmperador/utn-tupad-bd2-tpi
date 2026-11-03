-- =============================================================================
-- Sistema de Gestión Hospitalaria
-- Etapa 3 — Medición de rendimiento con EXPLAIN
-- Base de Datos I — UTN
-- =============================================================================
-- Requiere: 04_indices.sql ejecutado previamente.
-- Al finalizar este script se elimina el índice de medición.
--
-- Se miden 3 consultas representativas:
--   M1 — Igualdad:  filtro exacto por fecha_hora
--   M2 — Rango:     filtro por fecha_hora BETWEEN
--   M3 — JOIN:      join citas ↔ medicos usando medico_id
--
-- Instrucciones:
--   1. Ejecutar cada bloque por separado en Workbench.
--   2. Activar "Query > Show Execution Time" o usar SHOW PROFILES.
--   3. Correr cada variante 3 veces y anotar los tiempos.
-- =============================================================================

USE hospital_db;

-- =============================================================================
-- M1 — Igualdad: buscar citas en una fecha/hora exacta
-- =============================================================================

-- CON índice (idx_citas_fecha_hora activo):
EXPLAIN
SELECT c.cita_id, c.fecha_hora, c.costo, ec.descripcion AS estado
FROM citas c
JOIN estados_cita ec ON c.estado_cita_id = ec.estado_cita_id
WHERE c.fecha_hora = '2025-06-15 10:00:00';

SELECT c.cita_id, c.fecha_hora, c.costo, ec.descripcion AS estado
FROM citas c
JOIN estados_cita ec ON c.estado_cita_id = ec.estado_cita_id
WHERE c.fecha_hora = '2025-06-15 10:00:00';

-- SIN índice (se fuerza ignorarlo):
EXPLAIN
SELECT c.cita_id, c.fecha_hora, c.costo, ec.descripcion AS estado
FROM citas c IGNORE INDEX (idx_citas_fecha_hora)
JOIN estados_cita ec ON c.estado_cita_id = ec.estado_cita_id
WHERE c.fecha_hora = '2025-06-15 10:00:00';

SELECT c.cita_id, c.fecha_hora, c.costo, ec.descripcion AS estado
FROM citas c IGNORE INDEX (idx_citas_fecha_hora)
JOIN estados_cita ec ON c.estado_cita_id = ec.estado_cita_id
WHERE c.fecha_hora = '2025-06-15 10:00:00';

-- =============================================================================
-- M2 — Rango: citas en un trimestre
-- =============================================================================

-- CON índice:
EXPLAIN
SELECT c.cita_id, c.fecha_hora, c.costo, ec.descripcion AS estado
FROM citas c
JOIN estados_cita ec ON c.estado_cita_id = ec.estado_cita_id
WHERE c.fecha_hora BETWEEN '2025-01-01 00:00:00' AND '2025-03-31 23:59:59';

SELECT c.cita_id, c.fecha_hora, c.costo, ec.descripcion AS estado
FROM citas c
JOIN estados_cita ec ON c.estado_cita_id = ec.estado_cita_id
WHERE c.fecha_hora BETWEEN '2025-01-01 00:00:00' AND '2025-03-31 23:59:59';

-- SIN índice:
EXPLAIN
SELECT c.cita_id, c.fecha_hora, c.costo, ec.descripcion AS estado
FROM citas c IGNORE INDEX (idx_citas_fecha_hora)
JOIN estados_cita ec ON c.estado_cita_id = ec.estado_cita_id
WHERE c.fecha_hora BETWEEN '2025-01-01 00:00:00' AND '2025-03-31 23:59:59';

SELECT c.cita_id, c.fecha_hora, c.costo, ec.descripcion AS estado
FROM citas c IGNORE INDEX (idx_citas_fecha_hora)
JOIN estados_cita ec ON c.estado_cita_id = ec.estado_cita_id
WHERE c.fecha_hora BETWEEN '2025-01-01 00:00:00' AND '2025-03-31 23:59:59';

-- =============================================================================
-- M3 — JOIN: citas con médico
-- (el índice FK fk_citas_medico ya existe; se compara normal vs IGNORE INDEX)
-- =============================================================================

-- CON índice de FK (comportamiento normal):
EXPLAIN
SELECT c.cita_id, c.fecha_hora, m.matricula,
       CONCAT(p.apellido, ', ', p.nombre) AS medico
FROM citas c
JOIN medicos m  ON c.medico_id  = m.medico_id
JOIN personas p ON m.persona_id = p.persona_id;

SELECT c.cita_id, c.fecha_hora, m.matricula,
       CONCAT(p.apellido, ', ', p.nombre) AS medico
FROM citas c
JOIN medicos m  ON c.medico_id  = m.medico_id
JOIN personas p ON m.persona_id = p.persona_id;

-- SIN índice de FK (se fuerza tabla completa en citas):
EXPLAIN
SELECT c.cita_id, c.fecha_hora, m.matricula,
       CONCAT(p.apellido, ', ', p.nombre) AS medico
FROM citas c IGNORE INDEX (fk_citas_medico)
JOIN medicos m  ON c.medico_id  = m.medico_id
JOIN personas p ON m.persona_id = p.persona_id;

SELECT c.cita_id, c.fecha_hora, m.matricula,
       CONCAT(p.apellido, ', ', p.nombre) AS medico
FROM citas c IGNORE INDEX (fk_citas_medico)
JOIN medicos m  ON c.medico_id  = m.medico_id
JOIN personas p ON m.persona_id = p.persona_id;

-- =============================================================================
-- Limpieza: eliminar el índice creado en 04_indices.sql
-- (ejecutar al finalizar todas las mediciones)
-- =============================================================================

DROP INDEX idx_citas_fecha_hora ON citas;
