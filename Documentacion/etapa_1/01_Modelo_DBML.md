# Modelo DBML — Sistema de Gestión Hospitalaria

_Etapa 1 — Modelado y Constraints. Para usar en [dbdiagram.io](https://dbdiagram.io)._

**Diagrama publicado:** <https://dbdiagram.io/d/Sistema-de-Gestion-Hospitalaria-6adf7906aac3301410252873>

---

```dbml
// ── Tablas de catálogo (enums) ──────────────────────────────────────────────

Table tipos_sangre {
  tipo_sangre_id TINYINT     [pk, increment]
  descripcion    VARCHAR(3)  [not null, unique, note: 'A+, A-, B+, B-, AB+, AB-, O+, O-']
}

Table especialidades_medicas {
  especialidad_medica_id TINYINT     [pk, increment]
  descripcion            VARCHAR(50) [not null, unique]
}

Table estados_cita {
  estado_cita_id TINYINT     [pk, increment]
  descripcion    VARCHAR(20) [not null, unique, note: 'PROGRAMADA, CONFIRMADA, CANCELADA, COMPLETADA']
}

// ── Estructura del hospital ─────────────────────────────────────────────────

Table hospitales {
  hospital_id INT          [pk, increment]
  nombre      VARCHAR(100) [not null]
  direccion   VARCHAR(200) [not null]
  telefono    VARCHAR(20)  [not null]
}

Table departamentos {
  departamento_id        INT          [pk, increment]
  nombre                 VARCHAR(100) [not null]
  hospital_id            INT          [not null, ref: > hospitales.hospital_id]
  especialidad_medica_id TINYINT      [not null, ref: > especialidades_medicas.especialidad_medica_id]
}

Table salas {
  sala_id         INT         [pk, increment]
  numero          VARCHAR(10) [not null]
  tipo            VARCHAR(50) [not null]
  departamento_id INT         [not null, ref: > departamentos.departamento_id]
}

// ── Personas ────────────────────────────────────────────────────────────────

Table personas {
  persona_id       INT          [pk, increment]
  nombre           VARCHAR(100) [not null]
  apellido         VARCHAR(100) [not null]
  dni              VARCHAR(8)   [not null, unique, note: '7 u 8 digitos numericos']
  fecha_nacimiento DATE         [not null, note: 'fecha pasada']
  tipo_sangre_id   TINYINT      [not null, ref: > tipos_sangre.tipo_sangre_id]
}

Table pacientes {
  paciente_id INT          [pk, increment]
  persona_id  INT          [not null, unique, ref: - personas.persona_id]
  telefono    VARCHAR(20)  [not null]
  direccion   VARCHAR(200) [not null]
  hospital_id INT          [ref: > hospitales.hospital_id]
}

Table medicos {
  medico_id              INT         [pk, increment]
  persona_id             INT         [not null, unique, ref: - personas.persona_id]
  matricula              VARCHAR(20) [not null, unique]
  especialidad_medica_id TINYINT     [not null, ref: > especialidades_medicas.especialidad_medica_id]
  departamento_id        INT         [ref: > departamentos.departamento_id]
}

// ── Citas ───────────────────────────────────────────────────────────────────

Table citas {
  cita_id        INT           [pk, increment]
  paciente_id    INT           [not null, ref: > pacientes.paciente_id]
  medico_id      INT           [not null, ref: > medicos.medico_id]
  sala_id        INT           [not null, ref: > salas.sala_id]
  fecha_hora     DATETIME      [not null]
  costo          DECIMAL(10,2) [not null, note: 'CHECK costo >= 0']
  observaciones  TEXT
  estado_cita_id TINYINT       [not null, ref: > estados_cita.estado_cita_id]
}

// ── Historia clínica ────────────────────────────────────────────────────────

Table historias_clinicas {
  historia_clinica_id INT      [pk, increment]
  paciente_id         INT      [not null, unique, ref: - pacientes.paciente_id]
  fecha_creacion      DATETIME [not null]
}

Table hc_diagnosticos {
  hc_diagnostico_id   INT  [pk, increment]
  historia_clinica_id INT  [not null, ref: > historias_clinicas.historia_clinica_id]
  descripcion         TEXT [not null]
}

Table hc_tratamientos {
  hc_tratamiento_id   INT  [pk, increment]
  historia_clinica_id INT  [not null, ref: > historias_clinicas.historia_clinica_id]
  descripcion         TEXT [not null]
}

Table hc_alergias {
  hc_alergia_id       INT          [pk, increment]
  historia_clinica_id INT          [not null, ref: > historias_clinicas.historia_clinica_id]
  descripcion         VARCHAR(200) [not null]
}
```

---

## Referencias de relaciones

| Símbolo  | Significado              |
| -------- | ------------------------ |
| `ref: >` | Muchos a uno (FK → PK)   |
| `ref: -` | Uno a uno                |
