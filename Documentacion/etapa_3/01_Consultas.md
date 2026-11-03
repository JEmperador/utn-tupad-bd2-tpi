# Etapa 3 — Consultas avanzadas: descripción y análisis de rendimiento

_Base de Datos I — UTN. Sistema de Gestión Hospitalaria._

---

## Vista

### V1 — `vista_citas_detalle`

**Utilidad:** Centraliza en una sola vista todos los datos relevantes de una cita:
paciente, médico, especialidad, sala, departamento, hospital y estado. Evita
repetir los mismos JOINs en cada consulta del sistema y simplifica el acceso
a la información desde la capa de aplicación.

---

## Consultas SQL

### Q1 — Resumen de citas por hospital y departamento (JOIN múltiple)

**Tablas involucradas:** `citas` → `salas` → `departamentos` → `hospitales` + `estados_cita`

**Utilidad:** Permite al administrador general ver, de un vistazo, la actividad
de cada hospital: cuántas citas tiene cada departamento, en qué estado están
y cuánto se facturó. Es el punto de entrada para detectar hospitales o
departamentos con baja actividad, alta carga o problemas de facturación.

---

### Q2 — Plantel médico por hospital y departamento (JOIN con auxiliares)

**Tablas involucradas:** `medicos` → `personas` + `especialidades_medicas` + `departamentos` → `hospitales`

**Utilidad:** Muestra el listado completo del plantel médico organizado por
hospital y departamento. Permite verificar la distribución de especialidades
en cada sede y detectar si algún departamento carece de médicos asignados o
si alguna especialidad está sobredimensionada en una sede particular.

---

### Q3 — Citas completadas por mes y especialidad (GROUP BY + HAVING)

**Tablas involucradas:** `citas` → `medicos` → `especialidades_medicas` + `estados_cita`

**Utilidad:** Reporte mensual de actividad por especialidad. Solo muestra las
especialidades que superaron 5 citas completadas en el mes, dejando afuera
los casos con muy poca actividad que podrían distorsionar el análisis. Permite
detectar tendencias temporales y tomar decisiones sobre asignación de recursos
por área médica. El umbral de 5 citas filtra situaciones límite que requieren
un análisis diferente al estadístico estándar.

---

### Q4 — Pacientes con historia clínica pero sin citas registradas (subconsulta)

**Tablas involucradas:** `pacientes` → `personas` + `historias_clinicas` / subconsulta sobre `citas`

**Utilidad:** Identifica pacientes que tienen historia clínica abierta en el
sistema pero nunca agendaron ni una sola cita. Puede indicar pacientes que se
atendieron originalmente y luego dejaron de concurrir, cambiaron de hospital,
o resolvieron su problema de salud. Es útil para analizar la retención y el
seguimiento de pacientes a lo largo del tiempo.

---

## Medición de rendimiento con y sin índice

### Metodología

- Se midieron 3 consultas representativas: igualdad, rango y JOIN.
- Cada variante (con y sin índice) se ejecutó **3 veces**; se reporta la **mediana**.
- Se usó `EXPLAIN` antes de cada consulta para analizar el plan de ejecución.
- Para M1 y M2 se creó el índice `idx_citas_fecha_hora` sobre `citas.fecha_hora`
  (columna sin índice por defecto) y se usó `IGNORE INDEX` para simular su ausencia.
- Para M3 se usó `IGNORE INDEX (fk_citas_medico)` para comparar el JOIN con y sin
  el índice de FK que MySQL crea automáticamente.

---

### M1 — Igualdad: `WHERE fecha_hora = '2025-06-15 10:00:00'`

| Corrida | Con índice (ms) | Sin índice (ms) |
| ------- | --------------- | --------------- |
| 1       | < 1             | < 1             |
| 2       | < 1             | < 1             |
| 3       | < 1             | < 1             |
| Mediana | < 1             | < 1             |

**EXPLAIN con índice:**

| id | table | type   | key                  | rows | Extra |
| -- | ----- | ------ | -------------------- | ---- | ----- |
| 1  | c     | ref    | idx_citas_fecha_hora | 1    | NULL  |
| 1  | ec    | eq_ref | PRIMARY              | 1    | NULL  |

**EXPLAIN sin índice:**

| id | table | type  | key                  | rows | Extra       |
| -- | ----- | ----- | -------------------- | ---- | ----------- |
| 1  | ec    | index | uq_estados_cita_desc | 4    | Using index |
| 1  | c     | ref   | fk_citas_estado      | 374  | Using where |

---

### M2 — Rango: `WHERE fecha_hora BETWEEN '2025-01-01' AND '2025-03-31'`

| Corrida | Con índice (ms) | Sin índice (ms) |
| ------- | --------------- | --------------- |
| 1       | 15              | < 1             |
| 2       | 16              | < 1             |
| 3       | < 1             | < 1             |
| Mediana | 15              | < 1             |

**EXPLAIN con índice:**

| id | table | type  | key                  | rows | Extra       |
| -- | ----- | ----- | -------------------- | ---- | ----------- |
| 1  | ec    | index | uq_estados_cita_desc | 4    | Using index |
| 1  | c     | ref   | fk_citas_estado      | 374  | Using where |

**EXPLAIN sin índice:**

| id | table | type  | key                  | rows | Extra       |
| -- | ----- | ----- | -------------------- | ---- | ----------- |
| 1  | ec    | index | uq_estados_cita_desc | 4    | Using index |
| 1  | c     | ref   | fk_citas_estado      | 374  | Using where |

---

### M3 — JOIN: `citas` ↔ `medicos` ↔ `personas`

| Corrida | Con índice FK (ms) | Sin índice FK (ms) |
| ------- | ------------------ | ------------------ |
| 1       | < 1                | < 1                |
| 2       | < 1                | < 1                |
| 3       | < 1                | < 1                |
| Mediana | < 1                | < 1                |

**EXPLAIN con índice FK:**

| id | table | type   | key             | rows | Extra |
| -- | ----- | ------ | --------------- | ---- | ----- |
| 1  | m     | ALL    | NULL            | 500  | NULL  |
| 1  | p     | eq_ref | PRIMARY         | 1    | NULL  |
| 1  | c     | ref    | fk_citas_medico | 2    | NULL  |

**EXPLAIN sin índice FK:**

| id | table | type   | key     | rows | Extra |
| -- | ----- | ------ | ------- | ---- | ----- |
| 1  | c     | ALL    | NULL    | 1499 | NULL  |
| 1  | m     | eq_ref | PRIMARY | 1    | NULL  |
| 1  | p     | eq_ref | PRIMARY | 1    | NULL  |

---

## Conclusión

Las tres mediciones arrojaron tiempos menores a 1 ms tanto con índice como sin índice,
con excepción de las primeras dos corridas de M2 con índice (15 ms y 16 ms). Este
comportamiento es esperable con un volumen de ~1.500 registros en la tabla `citas`:
la tabla es suficientemente pequeña como para que MySQL realice un full scan en
microsegundos, sin que el uso de un índice represente una ventaja observable.

El caso de M2 es el más interesante: las dos primeras corridas con índice fueron más
lentas que sin índice. Esto ocurre porque en tablas pequeñas el overhead de recorrer
el índice B-tree y luego acceder a las filas puede superar al costo de un escaneo
directo. MySQL lo sabe y en muchos casos elige ignorar el índice por su cuenta cuando
estima que el full scan es más eficiente.

Donde el impacto de los índices sí sería visible es con volúmenes de 200.000 a
500.000 registros, rango recomendado por el enunciado para mediciones de performance
representativas. A ese volumen, el índice sobre `fecha_hora` permitiría saltar
directamente a los registros del rango buscado en lugar de recorrer toda la tabla,
y el índice de FK en el JOIN evitaría comparaciones fila a fila entre tablas grandes.
