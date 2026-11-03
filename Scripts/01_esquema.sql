-- =============================================================================
-- Sistema de Gestión Hospitalaria
-- Etapa 1 — Script DDL con constraints
-- Base de Datos I — UTN
-- =============================================================================

CREATE DATABASE IF NOT EXISTS hospital_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE hospital_db;

-- =============================================================================
-- TABLAS DE CATÁLOGO
-- =============================================================================

CREATE TABLE tipos_sangre (
  tipo_sangre_id TINYINT      NOT NULL AUTO_INCREMENT,
  descripcion    VARCHAR(3)   NOT NULL,
  CONSTRAINT pk_tipos_sangre     PRIMARY KEY (tipo_sangre_id),
  CONSTRAINT uq_tipos_sangre_desc UNIQUE (descripcion),
  CONSTRAINT chk_tipos_sangre_desc CHECK (descripcion IN ('A+','A-','B+','B-','AB+','AB-','O+','O-'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE especialidades_medicas (
  especialidad_medica_id TINYINT      NOT NULL AUTO_INCREMENT,
  descripcion            VARCHAR(50)  NOT NULL,
  CONSTRAINT pk_especialidades_medicas      PRIMARY KEY (especialidad_medica_id),
  CONSTRAINT uq_especialidades_medicas_desc UNIQUE (descripcion)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE estados_cita (
  estado_cita_id TINYINT      NOT NULL AUTO_INCREMENT,
  descripcion    VARCHAR(20)  NOT NULL,
  CONSTRAINT pk_estados_cita      PRIMARY KEY (estado_cita_id),
  CONSTRAINT uq_estados_cita_desc UNIQUE (descripcion),
  CONSTRAINT chk_estados_cita_desc CHECK (descripcion IN ('PROGRAMADA','CONFIRMADA','CANCELADA','COMPLETADA'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================================================
-- ESTRUCTURA DEL HOSPITAL
-- =============================================================================

CREATE TABLE hospitales (
  hospital_id INT          NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(100) NOT NULL,
  direccion   VARCHAR(200) NOT NULL,
  telefono    VARCHAR(20)  NOT NULL,
  CONSTRAINT pk_hospitales PRIMARY KEY (hospital_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE departamentos (
  departamento_id        INT          NOT NULL AUTO_INCREMENT,
  nombre                 VARCHAR(100) NOT NULL,
  hospital_id            INT          NOT NULL,
  especialidad_medica_id TINYINT      NOT NULL,
  CONSTRAINT pk_departamentos PRIMARY KEY (departamento_id),
  CONSTRAINT fk_departamentos_hospital
    FOREIGN KEY (hospital_id) REFERENCES hospitales (hospital_id),
  CONSTRAINT fk_departamentos_especialidad
    FOREIGN KEY (especialidad_medica_id) REFERENCES especialidades_medicas (especialidad_medica_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE salas (
  sala_id         INT         NOT NULL AUTO_INCREMENT,
  numero          VARCHAR(10) NOT NULL,
  tipo            VARCHAR(50) NOT NULL,
  departamento_id INT         NOT NULL,
  CONSTRAINT pk_salas PRIMARY KEY (sala_id),
  CONSTRAINT fk_salas_departamento
    FOREIGN KEY (departamento_id) REFERENCES departamentos (departamento_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================================================
-- PERSONAS
-- =============================================================================

CREATE TABLE personas (
  persona_id       INT          NOT NULL AUTO_INCREMENT,
  nombre           VARCHAR(100) NOT NULL,
  apellido         VARCHAR(100) NOT NULL,
  dni              VARCHAR(8)   NOT NULL,
  fecha_nacimiento DATE         NOT NULL,
  tipo_sangre_id   TINYINT      NOT NULL,
  CONSTRAINT pk_personas          PRIMARY KEY (persona_id),
  CONSTRAINT uq_personas_dni      UNIQUE (dni),
  CONSTRAINT chk_personas_dni     CHECK (dni REGEXP '^[0-9]{7,8}$'),
  CONSTRAINT fk_personas_tipo_sangre
    FOREIGN KEY (tipo_sangre_id) REFERENCES tipos_sangre (tipo_sangre_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE pacientes (
  paciente_id INT          NOT NULL AUTO_INCREMENT,
  persona_id  INT          NOT NULL,
  telefono    VARCHAR(20)  NOT NULL,
  direccion   VARCHAR(200) NOT NULL,
  hospital_id INT,
  CONSTRAINT pk_pacientes        PRIMARY KEY (paciente_id),
  CONSTRAINT uq_pacientes_persona UNIQUE (persona_id),
  CONSTRAINT fk_pacientes_persona
    FOREIGN KEY (persona_id) REFERENCES personas (persona_id),
  CONSTRAINT fk_pacientes_hospital
    FOREIGN KEY (hospital_id) REFERENCES hospitales (hospital_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE medicos (
  medico_id              INT         NOT NULL AUTO_INCREMENT,
  persona_id             INT         NOT NULL,
  matricula              VARCHAR(20) NOT NULL,
  especialidad_medica_id TINYINT     NOT NULL,
  departamento_id        INT,
  CONSTRAINT pk_medicos           PRIMARY KEY (medico_id),
  CONSTRAINT uq_medicos_persona   UNIQUE (persona_id),
  CONSTRAINT uq_medicos_matricula UNIQUE (matricula),
  CONSTRAINT fk_medicos_persona
    FOREIGN KEY (persona_id) REFERENCES personas (persona_id),
  CONSTRAINT fk_medicos_especialidad
    FOREIGN KEY (especialidad_medica_id) REFERENCES especialidades_medicas (especialidad_medica_id),
  CONSTRAINT fk_medicos_departamento
    FOREIGN KEY (departamento_id) REFERENCES departamentos (departamento_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================================================
-- CITAS
-- =============================================================================

CREATE TABLE citas (
  cita_id        INT           NOT NULL AUTO_INCREMENT,
  paciente_id    INT           NOT NULL,
  medico_id      INT           NOT NULL,
  sala_id        INT           NOT NULL,
  fecha_hora     DATETIME      NOT NULL,
  costo          DECIMAL(10,2) NOT NULL,
  observaciones  TEXT,
  estado_cita_id TINYINT       NOT NULL,
  CONSTRAINT pk_citas        PRIMARY KEY (cita_id),
  CONSTRAINT chk_citas_costo CHECK (costo >= 0),
  CONSTRAINT fk_citas_paciente
    FOREIGN KEY (paciente_id) REFERENCES pacientes (paciente_id),
  CONSTRAINT fk_citas_medico
    FOREIGN KEY (medico_id) REFERENCES medicos (medico_id),
  CONSTRAINT fk_citas_sala
    FOREIGN KEY (sala_id) REFERENCES salas (sala_id),
  CONSTRAINT fk_citas_estado
    FOREIGN KEY (estado_cita_id) REFERENCES estados_cita (estado_cita_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================================================
-- HISTORIA CLÍNICA
-- =============================================================================

CREATE TABLE historias_clinicas (
  historia_clinica_id INT      NOT NULL AUTO_INCREMENT,
  paciente_id         INT      NOT NULL,
  fecha_creacion      DATETIME NOT NULL,
  CONSTRAINT pk_historias_clinicas        PRIMARY KEY (historia_clinica_id),
  CONSTRAINT uq_historias_clinicas_paciente UNIQUE (paciente_id),
  CONSTRAINT fk_historias_clinicas_paciente
    FOREIGN KEY (paciente_id) REFERENCES pacientes (paciente_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE hc_diagnosticos (
  hc_diagnostico_id   INT  NOT NULL AUTO_INCREMENT,
  historia_clinica_id INT  NOT NULL,
  descripcion         TEXT NOT NULL,
  CONSTRAINT pk_hc_diagnosticos PRIMARY KEY (hc_diagnostico_id),
  CONSTRAINT fk_hc_diagnosticos_historia
    FOREIGN KEY (historia_clinica_id) REFERENCES historias_clinicas (historia_clinica_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE hc_tratamientos (
  hc_tratamiento_id   INT  NOT NULL AUTO_INCREMENT,
  historia_clinica_id INT  NOT NULL,
  descripcion         TEXT NOT NULL,
  CONSTRAINT pk_hc_tratamientos PRIMARY KEY (hc_tratamiento_id),
  CONSTRAINT fk_hc_tratamientos_historia
    FOREIGN KEY (historia_clinica_id) REFERENCES historias_clinicas (historia_clinica_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE hc_alergias (
  hc_alergia_id       INT          NOT NULL AUTO_INCREMENT,
  historia_clinica_id INT          NOT NULL,
  descripcion         VARCHAR(200) NOT NULL,
  CONSTRAINT pk_hc_alergias PRIMARY KEY (hc_alergia_id),
  CONSTRAINT fk_hc_alergias_historia
    FOREIGN KEY (historia_clinica_id) REFERENCES historias_clinicas (historia_clinica_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
