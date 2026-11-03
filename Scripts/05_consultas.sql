-- =============================================================================
-- Sistema de Gestión Hospitalaria
-- Etapa 3 — Consultas avanzadas y reportes
-- Base de Datos I — UTN
-- =============================================================================

USE hospital_db;

-- =============================================================================
-- Q1 — Resumen de citas por hospital y departamento (JOIN múltiple)
-- =============================================================================
-- Permite al administrador general ver la actividad de cada hospital:
-- cuántas citas tiene cada departamento, en qué estado están y cuánto
-- se facturó. Útil para detectar hospitales o departamentos con baja
-- actividad o alta carga.
-- =============================================================================

SELECT
    h.nombre                  AS hospital,
    d.nombre                  AS departamento,
    ec.descripcion            AS estado,
    COUNT(c.cita_id)          AS cantidad_citas,
    ROUND(SUM(c.costo), 2)    AS facturacion_total,
    ROUND(AVG(c.costo), 2)    AS costo_promedio
FROM citas c
JOIN salas s            ON c.sala_id         = s.sala_id
JOIN departamentos d    ON s.departamento_id = d.departamento_id
JOIN hospitales h       ON d.hospital_id     = h.hospital_id
JOIN estados_cita ec    ON c.estado_cita_id  = ec.estado_cita_id
GROUP BY
    h.hospital_id, h.nombre,
    d.departamento_id, d.nombre,
    ec.estado_cita_id, ec.descripcion
ORDER BY h.nombre, d.nombre, ec.descripcion;

-- =============================================================================
-- Q2 — Plantel médico por hospital y departamento (JOIN con auxiliares)
-- =============================================================================
-- Muestra el listado completo del plantel médico organizado por hospital y
-- departamento. Permite verificar la distribución de especialidades en cada
-- sede y detectar si algún departamento carece de médicos asignados.
-- =============================================================================

SELECT
    h.nombre                             AS hospital,
    d.nombre                             AS departamento,
    em.descripcion                       AS especialidad,
    CONCAT(p.apellido, ', ', p.nombre)   AS medico,
    m.matricula
FROM medicos m
JOIN personas p                ON m.persona_id             = p.persona_id
JOIN especialidades_medicas em ON m.especialidad_medica_id = em.especialidad_medica_id
JOIN departamentos d           ON m.departamento_id        = d.departamento_id
JOIN hospitales h              ON d.hospital_id            = h.hospital_id
ORDER BY h.nombre, d.nombre, p.apellido, p.nombre;

-- =============================================================================
-- Q3 — Citas completadas por mes y especialidad — GROUP BY + HAVING
-- =============================================================================
-- Reporte mensual de actividad por especialidad. Solo muestra las
-- especialidades que superaron 5 citas completadas en el mes, dejando
-- afuera casos con muy poca actividad que podrían distorsionar el análisis.
-- =============================================================================

SELECT
    DATE_FORMAT(c.fecha_hora, '%Y-%m') AS periodo,
    em.descripcion                     AS especialidad,
    COUNT(c.cita_id)                   AS citas_completadas,
    COUNT(DISTINCT c.paciente_id)      AS pacientes_distintos,
    ROUND(SUM(c.costo), 2)             AS facturacion_total
FROM citas c
JOIN medicos m                 ON c.medico_id              = m.medico_id
JOIN especialidades_medicas em ON m.especialidad_medica_id = em.especialidad_medica_id
JOIN estados_cita ec           ON c.estado_cita_id         = ec.estado_cita_id
WHERE ec.descripcion = 'COMPLETADA'
GROUP BY
    DATE_FORMAT(c.fecha_hora, '%Y-%m'),
    em.especialidad_medica_id,
    em.descripcion
HAVING COUNT(c.cita_id) > 5
ORDER BY periodo, citas_completadas DESC;

-- =============================================================================
-- Q4 — Pacientes con historia clínica pero sin citas registradas (subconsulta)
-- =============================================================================
-- Identifica pacientes que tienen historia clínica abierta en el sistema
-- pero nunca agendaron ni una sola cita. Útil para analizar retención
-- y seguimiento de pacientes.
-- =============================================================================

SELECT
    CONCAT(p.apellido, ', ', p.nombre) AS paciente,
    p.dni,
    hc.fecha_creacion                  AS historia_abierta_desde
FROM pacientes pac
JOIN personas p            ON pac.persona_id  = p.persona_id
JOIN historias_clinicas hc ON pac.paciente_id = hc.paciente_id
WHERE pac.paciente_id NOT IN (
    SELECT DISTINCT paciente_id
    FROM citas
)
ORDER BY p.apellido, p.nombre;
