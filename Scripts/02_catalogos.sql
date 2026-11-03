-- =============================================================================
-- Sistema de Gestión Hospitalaria
-- Etapa 1 — Inserciones de prueba (correctas e inválidas)
-- Base de Datos I — UTN
-- =============================================================================

USE hospital_db;

-- =============================================================================
-- INSERCIONES CORRECTAS
-- =============================================================================

-- Correcta 1: carga completa de catálogos, hospital, departamento, sala,
--             persona, paciente y médico con datos válidos.

INSERT INTO tipos_sangre (descripcion) VALUES
  ('A+'), ('A-'), ('B+'), ('B-'), ('AB+'), ('AB-'), ('O+'), ('O-');

INSERT INTO especialidades_medicas (descripcion) VALUES
  ('Cardiología'), ('Neurología'), ('Pediatría'), ('Traumatología'),
  ('Ginecología'), ('Urología'), ('Oftalmología'), ('Dermatología'),
  ('Psiquiatría'), ('Medicina General'), ('Cirugía General'), ('Anestesiología');

INSERT INTO estados_cita (descripcion) VALUES
  ('PROGRAMADA'), ('CONFIRMADA'), ('CANCELADA'), ('COMPLETADA');

INSERT INTO hospitales (nombre, direccion, telefono) VALUES
  ('Hospital Central', 'Av. Siempreviva 742', '0351-4000000');

INSERT INTO departamentos (nombre, hospital_id, especialidad_medica_id) VALUES
  ('Cardiología Adultos', 1, 1);

INSERT INTO salas (numero, tipo, departamento_id) VALUES
  ('C-01', 'Consultorio', 1);

INSERT INTO personas (nombre, apellido, dni, fecha_nacimiento, tipo_sangre_id) VALUES
  ('Ana', 'García', '30123456', '1990-05-15', 1);

INSERT INTO pacientes (persona_id, telefono, direccion, hospital_id) VALUES
  (1, '351-1234567', 'Calle Falsa 123', 1);

INSERT INTO personas (nombre, apellido, dni, fecha_nacimiento, tipo_sangre_id) VALUES
  ('Carlos', 'López', '25987654', '1978-11-20', 3);

INSERT INTO medicos (persona_id, matricula, especialidad_medica_id, departamento_id) VALUES
  (2, 'MP-00123', 1, 1);

INSERT INTO historias_clinicas (paciente_id, fecha_creacion) VALUES
  (1, NOW());

INSERT INTO citas (paciente_id, medico_id, sala_id, fecha_hora, costo, estado_cita_id) VALUES
  (1, 1, 1, '2026-11-10 09:00:00', 1500.00, 1);

-- Correcta 2: segundo paciente con datos válidos distintos.

INSERT INTO personas (nombre, apellido, dni, fecha_nacimiento, tipo_sangre_id) VALUES
  ('María', 'Fernández', '3567890', '2000-03-08', 5);

INSERT INTO pacientes (persona_id, telefono, direccion, hospital_id) VALUES
  (3, '351-9876543', 'Av. Colón 400', 1);

-- =============================================================================
-- INSERCIONES ERRÓNEAS
-- =============================================================================

-- Errónea 1: violación de UNIQUE en dni
-- Se intenta insertar una persona con un DNI ya registrado (30123456).
-- Error esperado: Duplicate entry '30123456' for key 'uq_personas_dni'

INSERT INTO personas (nombre, apellido, dni, fecha_nacimiento, tipo_sangre_id) VALUES
  ('Pedro', 'Ramírez', '30123456', '1985-07-22', 2);

-- Errónea 2: violación de CHECK en tipos_sangre
-- Se intenta insertar un tipo de sangre con un valor fuera del dominio permitido.
-- Error esperado: Check constraint 'chk_tipos_sangre_desc' is violated.

INSERT INTO tipos_sangre (descripcion) VALUES ('XX');
