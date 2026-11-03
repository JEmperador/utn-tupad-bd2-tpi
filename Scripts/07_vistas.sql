-- =============================================================================
-- Sistema de Gestión Hospitalaria
-- Etapa 3 y 4 — Vistas del sistema
-- Base de Datos I — UTN
-- =============================================================================

USE hospital_db;

-- =============================================================================
-- V1 — Vista: detalle completo de citas
-- =============================================================================
-- Centraliza en una sola vista todos los datos relevantes de una cita:
-- paciente, médico, especialidad, sala, departamento, hospital y estado.
-- Simplifica las consultas del sistema evitando repetir los mismos JOINs.
-- =============================================================================

CREATE OR REPLACE VIEW vista_citas_detalle AS
SELECT
    c.cita_id,
    c.fecha_hora,
    CONCAT(pp.apellido, ', ', pp.nombre) AS paciente,
    pp.dni                               AS paciente_dni,
    CONCAT(pm.apellido, ', ', pm.nombre) AS medico,
    m.matricula,
    em.descripcion                       AS especialidad,
    h.nombre                             AS hospital,
    d.nombre                             AS departamento,
    s.numero                             AS sala,
    s.tipo                               AS tipo_sala,
    ec.descripcion                       AS estado,
    c.costo,
    c.observaciones
FROM citas c
JOIN pacientes pac             ON c.paciente_id           = pac.paciente_id
JOIN personas pp               ON pac.persona_id          = pp.persona_id
JOIN medicos m                 ON c.medico_id             = m.medico_id
JOIN personas pm               ON m.persona_id            = pm.persona_id
JOIN especialidades_medicas em ON m.especialidad_medica_id = em.especialidad_medica_id
JOIN salas s                   ON c.sala_id               = s.sala_id
JOIN departamentos d           ON s.departamento_id       = d.departamento_id
JOIN hospitales h              ON d.hospital_id           = h.hospital_id
JOIN estados_cita ec           ON c.estado_cita_id        = ec.estado_cita_id;

-- =============================================================================
-- V2 — Vista: pacientes sin datos sensibles
-- =============================================================================
-- Expone nombre, apellido, teléfono y dirección del paciente.
-- Oculta: DNI, fecha de nacimiento y tipo de sangre.
-- Útil para recepción: puede identificar y contactar al paciente sin acceder
-- a sus datos personales completos ni a su información médica.
-- =============================================================================

CREATE OR REPLACE VIEW vista_pacientes_recepcion AS
SELECT
    pac.paciente_id,
    p.nombre,
    p.apellido,
    pac.telefono,
    pac.direccion,
    h.nombre AS hospital
FROM pacientes pac
JOIN personas p    ON pac.persona_id = p.persona_id
LEFT JOIN hospitales h ON pac.hospital_id = h.hospital_id;

-- =============================================================================
-- V3 — Vista: agenda de citas sin información financiera
-- =============================================================================
-- Expone fecha, paciente, médico, especialidad, sala y estado de cada cita.
-- Oculta: costo y observaciones.
-- Útil para un médico o recepcionista que consulta la agenda sin ver datos
-- de facturación ni notas clínicas.
-- =============================================================================

CREATE OR REPLACE VIEW vista_agenda_citas AS
SELECT
    c.cita_id,
    c.fecha_hora,
    CONCAT(pp.apellido, ', ', pp.nombre) AS paciente,
    CONCAT(pm.apellido, ', ', pm.nombre) AS medico,
    em.descripcion                       AS especialidad,
    s.numero                             AS sala,
    s.tipo                               AS tipo_sala,
    ec.descripcion                       AS estado
FROM citas c
JOIN pacientes pac             ON c.paciente_id            = pac.paciente_id
JOIN personas pp               ON pac.persona_id           = pp.persona_id
JOIN medicos m                 ON c.medico_id              = m.medico_id
JOIN personas pm               ON m.persona_id             = pm.persona_id
JOIN especialidades_medicas em ON m.especialidad_medica_id = em.especialidad_medica_id
JOIN salas s                   ON c.sala_id                = s.sala_id
JOIN estados_cita ec           ON c.estado_cita_id         = ec.estado_cita_id;
