-- =============================================================================
-- Sistema de Gestión Hospitalaria
-- Etapa 2 — Carga masiva de datos con SQL puro
-- Base de Datos I — UTN
-- Total aproximado: 10.000 registros distribuidos
-- =============================================================================

USE hospital_db;

-- =============================================================================
-- LIMPIEZA PREVIA — permite re-ejecutar el script sin tirar la base
-- =============================================================================

SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE hc_diagnosticos;
TRUNCATE TABLE hc_tratamientos;
TRUNCATE TABLE hc_alergias;
TRUNCATE TABLE historias_clinicas;
TRUNCATE TABLE citas;
TRUNCATE TABLE pacientes;
TRUNCATE TABLE medicos;
TRUNCATE TABLE personas;
TRUNCATE TABLE salas;
TRUNCATE TABLE departamentos;
TRUNCATE TABLE hospitales;
SET FOREIGN_KEY_CHECKS = 1;

-- Aumentar límite de recursión para WITH RECURSIVE
SET SESSION cte_max_recursion_depth = 5000;

-- =============================================================================
-- HOSPITALES (5 hospitales adicionales)
-- =============================================================================

INSERT INTO hospitales (nombre, direccion, telefono) VALUES
  ('Hospital San Martín',    'Av. San Martín 1200',  '0351-4100000'),
  ('Hospital Italiano',      'Av. Italia 890',        '0351-4200000'),
  ('Hospital Privado',       'Calle 9 de Julio 500',  '0351-4300000'),
  ('Hospital Municipal',     'Av. Colón 1500',        '0351-4400000'),
  ('Clínica del Sol',        'Av. Vélez Sársfield 33','0351-4500000');

-- =============================================================================
-- DEPARTAMENTOS (1 por especialidad por hospital = 72 departamentos)
-- =============================================================================

INSERT INTO departamentos (nombre, hospital_id, especialidad_medica_id)
SELECT
  CONCAT(em.descripcion, ' — H', h.hospital_id),
  h.hospital_id,
  em.especialidad_medica_id
FROM hospitales h
CROSS JOIN especialidades_medicas em;

-- =============================================================================
-- SALAS (3 salas por departamento)
-- =============================================================================

INSERT INTO salas (numero, tipo, departamento_id)
SELECT
  CONCAT('S-', LPAD(d.departamento_id, 3, '0'), '-', n.n),
  CASE MOD(n.n, 3)
    WHEN 0 THEN 'Consultorio'
    WHEN 1 THEN 'Quirófano'
    ELSE 'Internación'
  END,
  d.departamento_id
FROM departamentos d
CROSS JOIN (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3) n;

-- =============================================================================
-- PERSONAS — 2.000 registros (base para pacientes y médicos)
-- =============================================================================

DROP TEMPORARY TABLE IF EXISTS serie;

CREATE TEMPORARY TABLE serie (n INT);

INSERT INTO serie (n)
WITH RECURSIVE cte AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM cte WHERE n < 2000
)
SELECT n FROM cte;

INSERT INTO personas (nombre, apellido, dni, fecha_nacimiento, tipo_sangre_id)
SELECT
  CONCAT('Nombre', LPAD(n, 4, '0')),
  CONCAT('Apellido', LPAD(n, 4, '0')),
  LPAD(n + 20000000, 8, '0'),
  DATE_SUB('1990-01-01', INTERVAL (MOD(n, 40) * 365) DAY),
  MOD(n, 8) + 1
FROM serie;

DROP TEMPORARY TABLE IF EXISTS serie;

-- =============================================================================
-- MÉDICOS — 500 (personas 2 a 501, ya que persona 1 es de Etapa 1)
-- =============================================================================

INSERT INTO medicos (persona_id, matricula, especialidad_medica_id, departamento_id)
SELECT
  sub.persona_id,
  CONCAT('MP-', LPAD(sub.persona_id, 5, '0')),
  MOD(sub.persona_id, 12) + 1,
  d.departamento_id
FROM (
  SELECT p.persona_id
  FROM personas p
  WHERE p.persona_id BETWEEN 2 AND 501
    AND p.persona_id NOT IN (SELECT persona_id FROM medicos)
    AND p.persona_id NOT IN (SELECT persona_id FROM pacientes)
) sub
JOIN (
  SELECT departamento_id,
         ROW_NUMBER() OVER (ORDER BY departamento_id) - 1 AS rn,
         COUNT(*) OVER ()                                  AS total
  FROM departamentos
) d ON d.rn = MOD(sub.persona_id, d.total);

-- =============================================================================
-- PACIENTES — 1.500 (personas 502 a 2001)
-- =============================================================================

INSERT INTO pacientes (persona_id, telefono, direccion, hospital_id)
SELECT
  sub.persona_id,
  CONCAT('351-', LPAD(sub.persona_id * 7, 7, '0')),
  CONCAT('Calle ', sub.persona_id, ' N° ', MOD(sub.persona_id, 999) + 1),
  h.hospital_id
FROM (
  SELECT p.persona_id
  FROM personas p
  WHERE p.persona_id BETWEEN 502 AND 2001
    AND p.persona_id NOT IN (SELECT persona_id FROM pacientes)
    AND p.persona_id NOT IN (SELECT persona_id FROM medicos)
) sub
JOIN (
  SELECT hospital_id,
         ROW_NUMBER() OVER (ORDER BY hospital_id) - 1 AS rn,
         COUNT(*) OVER ()                              AS total
  FROM hospitales
) h ON h.rn = MOD(sub.persona_id, h.total);

-- =============================================================================
-- HISTORIAS CLÍNICAS — 1 por paciente (1.500 registros)
-- =============================================================================

INSERT INTO historias_clinicas (paciente_id, fecha_creacion)
SELECT
  paciente_id,
  DATE_SUB(NOW(), INTERVAL MOD(paciente_id, 1000) DAY)
FROM pacientes
WHERE paciente_id NOT IN (SELECT paciente_id FROM historias_clinicas);

-- =============================================================================
-- HC_DIAGNOSTICOS — 2 por historia clínica (3.000 registros)
-- =============================================================================

INSERT INTO hc_diagnosticos (historia_clinica_id, descripcion)
SELECT
  hc.historia_clinica_id,
  CONCAT('Diagnóstico ', n.n, ' — historia ', hc.historia_clinica_id)
FROM historias_clinicas hc
CROSS JOIN (SELECT 1 AS n UNION SELECT 2) n;

-- =============================================================================
-- CITAS — 1.500 registros
-- =============================================================================

INSERT INTO citas (paciente_id, medico_id, sala_id, fecha_hora, costo, estado_cita_id)
SELECT
  pa.paciente_id,
  m.medico_id,
  s.sala_id,
  DATE_ADD('2025-01-01', INTERVAL MOD(pa.paciente_id * 3, 365) DAY),
  ROUND(500 + MOD(pa.paciente_id * 17, 4500), 2),
  MOD(pa.paciente_id, 4) + 1
FROM (SELECT paciente_id FROM pacientes LIMIT 1500) pa
JOIN (
  SELECT medico_id,
         ROW_NUMBER() OVER (ORDER BY medico_id) - 1 AS rn,
         COUNT(*) OVER ()                            AS total
  FROM medicos
) m ON m.rn = MOD(pa.paciente_id, m.total)
JOIN (
  SELECT sala_id,
         ROW_NUMBER() OVER (ORDER BY sala_id) - 1 AS rn,
         COUNT(*) OVER ()                          AS total
  FROM salas
) s ON s.rn = MOD(pa.paciente_id, s.total);

-- =============================================================================
-- VERIFICACIONES DE CONSISTENCIA
-- =============================================================================

SELECT 'hospitales'          AS tabla, COUNT(*) AS total FROM hospitales
UNION ALL
SELECT 'departamentos',                COUNT(*)           FROM departamentos
UNION ALL
SELECT 'salas',                        COUNT(*)           FROM salas
UNION ALL
SELECT 'personas',                     COUNT(*)           FROM personas
UNION ALL
SELECT 'medicos',                      COUNT(*)           FROM medicos
UNION ALL
SELECT 'pacientes',                    COUNT(*)           FROM pacientes
UNION ALL
SELECT 'historias_clinicas',           COUNT(*)           FROM historias_clinicas
UNION ALL
SELECT 'hc_diagnosticos',              COUNT(*)           FROM hc_diagnosticos
UNION ALL
SELECT 'citas',                        COUNT(*)           FROM citas;

-- FK huérfanas — deben retornar 0 en todos los casos
SELECT 'pacientes sin persona'       AS verificacion, COUNT(*) AS resultado
FROM pacientes p LEFT JOIN personas pe ON p.persona_id = pe.persona_id
WHERE pe.persona_id IS NULL
UNION ALL
SELECT 'medicos sin persona',          COUNT(*)
FROM medicos m LEFT JOIN personas pe ON m.persona_id = pe.persona_id
WHERE pe.persona_id IS NULL
UNION ALL
SELECT 'citas sin paciente',           COUNT(*)
FROM citas c LEFT JOIN pacientes pa ON c.paciente_id = pa.paciente_id
WHERE pa.paciente_id IS NULL
UNION ALL
SELECT 'citas sin medico',             COUNT(*)
FROM citas c LEFT JOIN medicos m ON c.medico_id = m.medico_id
WHERE m.medico_id IS NULL
UNION ALL
SELECT 'historias sin paciente',       COUNT(*)
FROM historias_clinicas hc LEFT JOIN pacientes pa ON hc.paciente_id = pa.paciente_id
WHERE pa.paciente_id IS NULL;
