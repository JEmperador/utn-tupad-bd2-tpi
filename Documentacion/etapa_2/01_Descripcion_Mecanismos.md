# Descripción de mecanismos de generación masiva

_Etapa 2 — Carga masiva con SQL puro. Base de Datos I — UTN._

---

## Objetivo

Poblar la base de datos con aproximadamente 10.000 registros distribuidos entre las
tablas principales del sistema, usando exclusivamente mecanismos nativos de SQL —
sin datos externos, sin scripts de aplicación y sin insertar filas manualmente.

---

## Mecanismos utilizados

### WITH RECURSIVE — generación de series numéricas

Se usa una CTE recursiva para generar una secuencia de números del 1 al 2.000,
que luego se materializa en una tabla temporal:

```sql
CREATE TEMPORARY TABLE serie (n INT);

INSERT INTO serie (n)
WITH RECURSIVE cte AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM cte WHERE n < 2000
)
SELECT n FROM cte;
```

Cada número de la serie sirve como base para construir los atributos de una persona
(nombre, apellido, DNI, fecha de nacimiento, tipo de sangre) mediante funciones
de cadena y aritmética modular.

**Por qué tabla temporal:** MySQL Workbench no acepta `WITH RECURSIVE` seguido
directamente de `INSERT INTO`. Materializar la serie en una tabla temporal separa
la generación de la carga y resuelve la limitación del cliente.

---

### CROSS JOIN — multiplicación de conjuntos

Se aplica para generar combinaciones entre hospitales y especialidades médicas,
produciendo un departamento por cada par posible:

```sql
INSERT INTO departamentos (nombre, hospital_id, especialidad_medica_id)
SELECT CONCAT(em.descripcion, ' — H', h.hospital_id), h.hospital_id, em.especialidad_medica_id
FROM hospitales h
CROSS JOIN especialidades_medicas em;
```

Con 6 hospitales y 12 especialidades se obtienen 72 departamentos en un único
`INSERT`. El mismo patrón genera 3 salas por departamento cruzando con una
subquery de tres filas (`SELECT 1 UNION SELECT 2 UNION SELECT 3`).

---

### INSERT ... SELECT — propagación encadenada

Una vez pobladas las tablas de base, cada tabla dependiente se carga seleccionando
de la anterior. Los atributos se derivan con expresiones calculadas:

```sql
INSERT INTO pacientes (persona_id, telefono, direccion, hospital_id)
SELECT sub.persona_id,
       CONCAT('351-', LPAD(sub.persona_id * 7, 7, '0')),
       CONCAT('Calle ', sub.persona_id, ' N° ', MOD(sub.persona_id, 999) + 1),
       h.hospital_id
FROM (...) sub
JOIN (...) h ON h.rn = MOD(sub.persona_id, h.total);
```

Este encadenamiento respeta el orden de dependencia de las claves foráneas:
`personas` → `medicos` / `pacientes` → `historias_clinicas` → `hc_diagnosticos` → `citas`.

---

### ROW_NUMBER() y aritmética modular — distribución de FKs

Para asignar claves foráneas de forma distribuida sin asumir que los IDs son
contiguos, se numera cada fila del conjunto destino con `ROW_NUMBER()` y se usa
`MOD` para elegir una fila real:

```sql
JOIN (
  SELECT departamento_id,
         ROW_NUMBER() OVER (ORDER BY departamento_id) - 1 AS rn,
         COUNT(*) OVER ()                                  AS total
  FROM departamentos
) d ON d.rn = MOD(sub.persona_id, d.total)
```

`ROW_NUMBER() - 1` produce índices 0, 1, 2, ..., N-1.
`MOD(persona_id, N)` produce valores en ese mismo rango.
El JOIN une cada persona con exactamente un departamento real, distribuyendo la
carga de forma cíclica y uniforme.

**Por qué no MOD + COUNT + 1:** ese patrón asume IDs contiguos desde 1. Si existe
cualquier gap (por ejemplo, la tabla fue parcialmente llenada en una etapa anterior),
el resultado puede apuntar a un ID que no existe, violando la FK.

**Por qué no LIMIT/OFFSET dinámico:** MySQL no permite subqueries dentro de `OFFSET`.
El valor debe ser una constante, no una expresión calculada por fila.

---

### LPAD, MOD, CONCAT, DATE_SUB — generación de valores realistas

| Función | Uso |
| --- | --- |
| `LPAD(n, 4, '0')` | DNIs y matrículas con ceros a la izquierda |
| `MOD(n, 8) + 1` | Distribuye tipo de sangre entre los 8 valores del catálogo |
| `MOD(n, 40) * 365` | Varía la fecha de nacimiento en un rango de 40 años |
| `MOD(n, 4) + 1` | Distribuye estados de cita entre los 4 valores del catálogo |
| `CONCAT(...)` | Construye nombres, direcciones y descripciones sintéticas |
| `DATE_SUB(...)` | Genera fechas de nacimiento y de creación de historias clínicas |
| `ROUND(500 + MOD(n * 17, 4500), 2)` | Costos entre $500 y $5.000 con variación distribuida |

---

## Distribución final de registros

| Tabla                | Mecanismo principal          | Registros aprox. |
| -------------------- | ---------------------------- | ---------------- |
| `hospitales`         | `INSERT VALUES`              | 6                |
| `departamentos`      | `CROSS JOIN`                 | 72               |
| `salas`              | `CROSS JOIN`                 | 216              |
| `personas`           | `WITH RECURSIVE` + tabla tmp | 2.001            |
| `medicos`            | `INSERT ... SELECT`          | 500              |
| `pacientes`          | `INSERT ... SELECT`          | 1.500            |
| `historias_clinicas` | `INSERT ... SELECT`          | 1.501            |
| `hc_diagnosticos`    | `CROSS JOIN` + SELECT        | 3.002            |
| `citas`              | `INSERT ... SELECT`          | 1.500            |
| **Total**            |                              | **~10.298**      |

---

## Idempotencia

El script incluye un bloque de limpieza al inicio que hace `TRUNCATE` de todas las
tablas de datos en orden inverso al de las dependencias, con `FOREIGN_KEY_CHECKS = 0`.
Esto permite re-ejecutar el script completo en cualquier momento sin tirar la base
ni volver a ejecutar el DDL.
