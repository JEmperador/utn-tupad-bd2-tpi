-- =============================================================================
-- Sistema de Gestión Hospitalaria
-- Etapa 4 — Seguridad e integridad
-- Base de Datos I — UTN
-- =============================================================================

USE hospital_db;

-- =============================================================================
-- USUARIO CON PRIVILEGIOS MÍNIMOS — recepcion
-- =============================================================================
-- El usuario recepcion representa al personal de front-desk del hospital.
-- Solo necesita consultar pacientes, citas, médicos y salas para su trabajo.
-- No tiene acceso a historias clínicas, diagnósticos, tratamientos ni alergias
-- (datos médicos sensibles), ni puede modificar ningún dato.
-- =============================================================================

-- Nota: MySQL diferencia 'localhost' (socket) de '127.0.0.1' (TCP).
-- Workbench se conecta por TCP, por lo que se usa '127.0.0.1'.
CREATE USER IF NOT EXISTS 'recepcion'@'127.0.0.1' IDENTIFIED BY 'Recepcion2024!';

-- Permisos mínimos: solo SELECT en tablas operativas
GRANT SELECT ON hospital_db.pacientes              TO 'recepcion'@'127.0.0.1';
GRANT SELECT ON hospital_db.personas               TO 'recepcion'@'127.0.0.1';
GRANT SELECT ON hospital_db.citas                  TO 'recepcion'@'127.0.0.1';
GRANT SELECT ON hospital_db.medicos                TO 'recepcion'@'127.0.0.1';
GRANT SELECT ON hospital_db.especialidades_medicas TO 'recepcion'@'127.0.0.1';
GRANT SELECT ON hospital_db.estados_cita           TO 'recepcion'@'127.0.0.1';
GRANT SELECT ON hospital_db.hospitales             TO 'recepcion'@'127.0.0.1';
GRANT SELECT ON hospital_db.departamentos          TO 'recepcion'@'127.0.0.1';
GRANT SELECT ON hospital_db.salas                  TO 'recepcion'@'127.0.0.1';

-- Sin acceso a: historias_clinicas, hc_diagnosticos, hc_tratamientos,
--              hc_alergias, tipos_sangre

FLUSH PRIVILEGES;

-- =============================================================================
-- PRUEBAS DE INTEGRIDAD
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Prueba 1 — Violación de UNIQUE: DNI duplicado
-- Intenta insertar una persona con un DNI que ya existe en la base.
-- Viola la constraint uq_personas_dni.
-- Error esperado: Duplicate entry '...' for key 'personas.uq_personas_dni'
-- -----------------------------------------------------------------------------

INSERT INTO personas (nombre, apellido, dni, fecha_nacimiento, tipo_sangre_id)
SELECT 'Test', 'Duplicado', dni, '1990-01-01', 1
FROM personas
LIMIT 1;

-- -----------------------------------------------------------------------------
-- Prueba 2 — Violación de FK: estado de cita inexistente
-- Intenta insertar una cita con un estado_cita_id que no existe en estados_cita.
-- Viola la constraint fk_citas_estado.
-- Error esperado: Cannot add or update a child row: a foreign key constraint fails
-- -----------------------------------------------------------------------------

INSERT INTO citas (paciente_id, medico_id, sala_id, fecha_hora, costo, estado_cita_id)
VALUES (1, 1, 1, '2025-01-01 10:00:00', 500.00, 999);

-- =============================================================================
-- PROCEDIMIENTO ALMACENADO — Consulta segura contra SQL injection
-- =============================================================================
-- Busca pacientes por apellido usando un parámetro tipado.
-- Al usar parámetros en lugar de concatenación de strings, el valor ingresado
-- siempre se trata como dato, nunca como código SQL.
-- =============================================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS buscar_paciente_por_apellido$$

CREATE PROCEDURE buscar_paciente_por_apellido(
    IN p_apellido VARCHAR(100)
)
BEGIN
    SELECT
        pac.paciente_id,
        CONCAT(p.apellido, ', ', p.nombre) AS paciente,
        pac.telefono,
        pac.direccion
    FROM pacientes pac
    JOIN personas p ON pac.persona_id = p.persona_id
    WHERE p.apellido COLLATE utf8mb4_0900_ai_ci = p_apellido;
END$$

DELIMITER ;

-- =============================================================================
-- PRUEBA A — Acceso restringido
-- Usuario: recepcion@127.0.0.1
-- Crear una conexión separada en Workbench con ese usuario antes de ejecutar.
-- =============================================================================

-- Intento de SELECT sobre tabla médica sensible — debe dar ERROR 1142:
SELECT * FROM historias_clinicas;

-- Intento de INSERT sobre tabla operativa — debe dar ERROR 1142:
INSERT INTO citas (paciente_id, medico_id, sala_id, fecha_hora, costo, estado_cita_id)
VALUES (1, 1, 1, NOW(), 500.00, 1);

-- =============================================================================
-- PRUEBA B — Consulta segura y anti-inyección
-- Usuario: root (o cualquier usuario con permisos de EXECUTE)
-- =============================================================================

-- Llamada normal — devuelve los pacientes que coincidan con el apellido:
CALL buscar_paciente_por_apellido('Emperador');

-- Intento de inyección — la cadena maliciosa se trata como dato, no como SQL.
-- Resultado esperado: 0 filas. Ningún paciente tiene ese "apellido".
CALL buscar_paciente_por_apellido("' OR '1'='1");
