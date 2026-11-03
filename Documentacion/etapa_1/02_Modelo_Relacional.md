# Modelo Relacional — Sistema de Gestión Hospitalaria

_Etapa 1 — Modelado y Constraints. Base de Datos I — UTN._

---

## Notación

- **atributo** → Clave Primaria (PK)
- `*atributo*` → Clave Foránea (FK) — indicado con asteriscos en el texto
- `NN` → NOT NULL
- `UQ` → UNIQUE

---

## Tablas de catálogo

**tipos_sangre** (**tipo_sangre_id**, descripcion `NN UQ`)

**especialidades_medicas** (**especialidad_medica_id**, descripcion `NN UQ`)

**estados_cita** (**estado_cita_id**, descripcion `NN UQ`)

---

## Estructura del hospital

**hospitales** (**hospital_id**, nombre `NN`, direccion `NN`, telefono `NN`)

**departamentos** (**departamento_id**, nombre `NN`, `*hospital_id*` `NN FK`, `*especialidad_medica_id*` `NN FK`)

**salas** (**sala_id**, numero `NN`, tipo `NN`, `*departamento_id*` `NN FK`)

---

## Personas

**personas** (**persona_id**, nombre `NN`, apellido `NN`, dni `NN UQ`, fecha_nacimiento `NN`, `*tipo_sangre_id*` `NN FK`)

> `dni`: VARCHAR(8), solo dígitos, longitud 7 u 8. CHECK: `dni REGEXP '^[0-9]{7,8}$'`
> `fecha_nacimiento`: debe ser una fecha pasada. Validación a nivel de aplicación — MySQL no permite `CURDATE()` en CHECK constraints.

**pacientes** (**paciente_id**, `*persona_id*` `NN UQ FK`, telefono `NN`, direccion `NN`, `*hospital_id*` `FK`)

**medicos** (**medico_id**, `*persona_id*` `NN UQ FK`, matricula `NN UQ`, `*especialidad_medica_id*` `NN FK`, `*departamento_id*` `FK`)

---

## Citas

**citas** (**cita_id**, `*paciente_id*` `NN FK`, `*medico_id*` `NN FK`, `*sala_id*` `NN FK`, fecha_hora `NN`, costo `NN`, observaciones, `*estado_cita_id*` `NN FK`)

> `costo`: DECIMAL(10,2). CHECK: `costo >= 0`

---

## Historia clínica

**historias_clinicas** (**historia_clinica_id**, `*paciente_id*` `NN UQ FK`, fecha_creacion `NN`)

**hc_diagnosticos** (**hc_diagnostico_id**, `*historia_clinica_id*` `NN FK`, descripcion `NN`)

**hc_tratamientos** (**hc_tratamiento_id**, `*historia_clinica_id*` `NN FK`, descripcion `NN`)

**hc_alergias** (**hc_alergia_id**, `*historia_clinica_id*` `NN FK`, descripcion `NN`)

---

## Relaciones

| Tabla origen         | FK                       | Tabla destino            | Cardinalidad |
| -------------------- | ------------------------ | ------------------------ | ------------ |
| `personas`           | `tipo_sangre_id`         | `tipos_sangre`           | N:1          |
| `departamentos`      | `hospital_id`            | `hospitales`             | N:1          |
| `departamentos`      | `especialidad_medica_id` | `especialidades_medicas` | N:1          |
| `salas`              | `departamento_id`        | `departamentos`          | N:1          |
| `pacientes`          | `persona_id`             | `personas`               | 1:1          |
| `pacientes`          | `hospital_id`            | `hospitales`             | N:1          |
| `medicos`            | `persona_id`             | `personas`               | 1:1          |
| `medicos`            | `especialidad_medica_id` | `especialidades_medicas` | N:1          |
| `medicos`            | `departamento_id`        | `departamentos`          | N:1          |
| `citas`              | `paciente_id`            | `pacientes`              | N:1          |
| `citas`              | `medico_id`              | `medicos`                | N:1          |
| `citas`              | `sala_id`                | `salas`                  | N:1          |
| `citas`              | `estado_cita_id`         | `estados_cita`           | N:1          |
| `historias_clinicas` | `paciente_id`            | `pacientes`              | 1:1          |
| `hc_diagnosticos`    | `historia_clinica_id`    | `historias_clinicas`     | N:1          |
| `hc_tratamientos`    | `historia_clinica_id`    | `historias_clinicas`     | N:1          |
| `hc_alergias`        | `historia_clinica_id`    | `historias_clinicas`     | N:1          |
