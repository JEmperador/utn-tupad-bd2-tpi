# Anexo IA — TPI Base de Datos I

_Tecnicatura Universitaria en Programación — UTN. Base de Datos I._
_Equipo: JEmperador_

---

## Etapa 1 — Modelado y Constraints

**Fecha:** 2026-10-26

---

### Intercambio 1 — Estrategia de modelado de enums

```text
Estudiante: Los enums del sistema Java (TipoSangre, EspecialidadMedica, EstadoCita)
— ¿los modelamos como columna con CHECK en la tabla o como tabla de referencia
separada con FK?

Claude: Hay dos opciones:

  Opción A: Columna con CHECK en la tabla
  (ej. CHECK (tipo_sangre IN ('A+', 'A-', ...))). Más simple y suficiente para este TPI.

  Opción B: Tabla de referencia separada
  (ej. tabla tipos_sangre con FK). Más ordenado, extensible como sistema y genera
  un modelo más rico.

  La opción A es más simple. La B es más "enterprise" pero agrega más tablas al DER
  y enriquece las consultas de etapas posteriores.

Estudiante: Me gusta la B por cuestión de escalado de sistema.
```

**Decisión tomada:** se eligió la **Opción B** (tablas de referencia separadas) porque
permite un diseño más ordenado, con posibilidades de crecimiento, y enriquece el modelo
relacional con más entidades.

Las tablas de catálogo resultantes son:

- `tipos_sangre` — valores: A+, A-, B+, B-, AB+, AB-, O+, O-
- `especialidades_medicas` — valores: Cardiología, Neurología, Pediatría, Traumatología,
  Ginecología, Urología, Oftalmología, Dermatología, Psiquiatría, Medicina General,
  Cirugía General, Anestesiología
- `estados_cita` — valores: PROGRAMADA, CONFIRMADA, CANCELADA, COMPLETADA

---

### Intercambio 2 — Modelado de herencia y subtablas

```text
Claude: En Java Paciente y Medico heredan de Persona (clase abstracta). En una base de
datos relacional no existe herencia, hay dos formas de modelarlo:

  Opción A: Tabla por clase concreta — los campos comunes (nombre, apellido, dni, etc.)
  se repiten en pacientes y medicos. Simple pero con redundancia.

  Opción B: Tabla base personas con FK en pacientes y medicos — sin repetición,
  escalable si se agregan más tipos de personas (enfermeros, administrativos, etc.).

  Para las listas de HistoriaClinica (diagnósticos, tratamientos, alergias) propuse
  una tabla unificada con discriminador (tipo = 'DIAGNOSTICO'/'TRATAMIENTO'/'ALERGIA').

Estudiante: Me gusta la Opción B para la herencia por cuestión de escalado.
Para la historia clínica prefiero tablas separadas por tipo, ya que cada una puede
tener columnas específicas en el futuro (ej. severidad en alergias).
```

**Decisión tomada:**

1. **Herencia → Opción B:** se crea tabla `personas` como base, y `pacientes` y `medicos`
   tienen un campo `persona_id` (FK a `personas`). Criterio: escalabilidad del sistema.
2. **Subtablas de historia clínica → tablas separadas:** `hc_diagnosticos`,
   `hc_tratamientos` y `hc_alergias` son tablas independientes con `historia_clinica_id`
   (FK a `historias_clinicas`). Criterio: cada tipo puede tener columnas específicas
   en el futuro sin afectar a los demás.

---

### Intercambio 3 — Convenciones de nomenclatura

```text
Claude: ¿Qué convenciones usamos para nombrar tablas, PKs, FKs, booleanos e idioma?

  Propuesta:
  - Tablas: snake_case plural (personas, historias_clinicas)
  - PK: {tabla_singular}_id dentro de su propia tabla (persona_id en personas)
  - FK: mismo nombre que la PK de la tabla origen para facilitar JOINs
  - Booleanos: ¿con prefijo es_ o sin prefijo?
  - Idioma: ¿español o inglés?

Estudiante: Plural para tablas. persona_id como PK. FKs igual a la PK de origen.
Booleanos sin prefijo (activo, visible). Todo en español.
```

**Decisión tomada:**

| Elemento            | Convención              | Ejemplo                           |
| ------------------- | ----------------------- | --------------------------------- |
| Tablas              | snake_case plural       | `personas`, `historias_clinicas`  |
| PK                  | `{tabla_singular}_id`   | `persona_id` en tabla `personas`  |
| FK                  | igual a la PK de origen | `persona_id` en tabla `pacientes` |
| Booleanos           | sin prefijo             | `activo`, `visible`               |
| Estados multi-valor | sin prefijo + `_id`     | `estado_cita_id`                  |
| Idioma              | español                 | `fecha_nacimiento`, `descripcion` |

> MySQL guarda nombres en lowercase — no usar PascalCase ni camelCase.

---

### Intercambio 4 — Limitación de CURDATE() en CHECK constraints

```text
Estudiante: Al ejecutar el script DDL en MySQL aparece este error:
Error Code: 3814. An expression of a check constraint 'chk_personas_fecha'
contains disallowed function: curdate.

Claude: MySQL no permite funciones no deterministas como CURDATE() dentro de
un CHECK constraint, porque el valor cambia con el tiempo y MySQL no puede
garantizarlo estáticamente. La validación de fecha pasada debe hacerse a nivel
de aplicación (Java) o mediante un trigger, no con CHECK.

Estudiante: ¿El diagrama hay que cambiarlo?

Claude: No, el diagrama no representa CHECK constraints, solo la estructura
de tablas y relaciones. El diagrama queda igual.
```

**Decisión tomada:** se eliminó `CONSTRAINT chk_personas_fecha CHECK (fecha_nacimiento < CURDATE())`
del script DDL. La validación de que la fecha de nacimiento sea pasada queda
documentada como responsabilidad de la capa de aplicación (Java).

---

### Intercambio 5 — Claves compuestas

```text
Claude: ¿Usamos claves compuestas en alguna tabla?

Estudiante: No quiero claves compuestas. Todas las tablas tienen PK simple
con AUTO_INCREMENT.
```

**Decisión tomada:** todas las tablas usan PK simple (`{tabla_singular}_id` con
`AUTO_INCREMENT`). Las restricciones de unicidad sobre múltiples columnas se
implementan como índices `UNIQUE` separados, no como claves primarias compuestas.

---

### Intercambio 5 — Tipo de dato del campo dni

```text
Claude: Al exportar el SQL desde dbdiagram, el campo dni quedó como CHAR(8).
Sin embargo el código Java valida que el DNI tenga 7 u 8 dígitos. CHAR(8) fuerza
exactamente 8 caracteres, lo que rechazaría DNIs de 7 dígitos.

Estudiante: Correcto, hay que arreglarlo.
```

**Decisión tomada:** `dni` pasa de `CHAR(8)` a `VARCHAR(8)` con un `CHECK` que
valida formato numérico y longitud: `CHECK (dni REGEXP '^[0-9]{7,8}$')`.
Esto respeta la validación original del sistema Java.

---

## Etapa 2 — Carga masiva con SQL puro

**Fecha:** 2026-10-26

---

### Intercambio 7 — Sintaxis de WITH RECURSIVE + INSERT en MySQL Workbench

```text
Estudiante: Al ejecutar el script de carga masiva, MySQL Workbench lanzó este error:
Error Code: 1064. You have an error in your SQL syntax; check the manual that
corresponds to your MySQL server version for the right syntax to use near
'INSERT INTO personas ...' at line 6

El código era:
  WITH RECURSIVE serie AS (...)
  INSERT INTO personas (...) SELECT ... FROM serie;

Claude: MySQL Workbench no acepta WITH RECURSIVE seguido directamente de INSERT INTO.
La solución es materializar la serie en una tabla temporal primero:
  CREATE TEMPORARY TABLE serie (n INT);
  INSERT INTO serie (n) WITH RECURSIVE cte AS (...) SELECT n FROM cte;
  INSERT INTO personas (...) SELECT ... FROM serie;
  DROP TEMPORARY TABLE IF EXISTS serie;
```

**Decisión tomada:** se usa una tabla temporal `serie` para materializar la secuencia
generada por `WITH RECURSIVE` antes de hacer el `INSERT` principal.
El `DROP TEMPORARY TABLE IF EXISTS` previo al `CREATE` evita errores si la tabla ya existe
de una ejecución anterior interrumpida.

---

### Intercambio 8 — FK constraint con MOD sobre COUNT asumiendo IDs contiguos

```text
Estudiante: Al insertar médicos aparece:
Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails
(`hospital_db`.`medicos`, CONSTRAINT `fk_medicos_departamento` FOREIGN KEY
(`departamento_id`) REFERENCES `departamentos` (`departamento_id`))

El código usaba:
  MOD(p.persona_id, (SELECT COUNT(*) FROM departamentos)) + 1

Claude: El problema es que MOD(id, COUNT(*)) + 1 asume que los IDs de departamentos
son contiguos desde 1 hasta N. Si hay cualquier gap (por ejemplo, el primer departamento
fue insertado en Etapa 1 con id=1 y los siguientes en Etapa 2), el resultado puede
apuntar a un ID inexistente. La solución es usar un JOIN con ROW_NUMBER():

  JOIN (
    SELECT departamento_id,
           ROW_NUMBER() OVER (ORDER BY departamento_id) - 1 AS rn,
           COUNT(*) OVER () AS total
    FROM departamentos
  ) d ON d.rn = MOD(sub.persona_id, d.total)

Así siempre se elige un ID real, independientemente de los gaps.
```

**Decisión tomada:** se reemplazó el patrón `MOD + COUNT + 1` por un JOIN con
`ROW_NUMBER() OVER (ORDER BY ...)` en todas las tablas donde se asigna una FK
mediante distribución modular: `departamentos`, `hospitales`, `medicos`, `salas`.

---

### Intercambio 9 — Subquery no permitida dentro de OFFSET

```text
Estudiante: Al intentar corregir el error anterior con LIMIT/OFFSET apareció:
Error Code: 1064. You have an error in your SQL syntax ... near
'MOD(sub.persona_id, (SELECT COUNT(*) FROM departamentos)))'

El código era:
  LIMIT 1 OFFSET MOD(sub.persona_id, (SELECT COUNT(*) FROM departamentos))

Claude: MySQL no permite subqueries dentro de LIMIT ni OFFSET — el valor debe ser
una constante o una variable de sesión, no una expresión calculada en línea.
La misma solución con ROW_NUMBER() resuelve ambos problemas a la vez: evita OFFSET
completamente y garantiza IDs válidos sin importar gaps.
```

**Decisión tomada:** se descartó el enfoque LIMIT/OFFSET y se adoptó definitivamente
el patrón con `ROW_NUMBER()` como única estrategia de distribución modular en el script.

---

### Intercambio 10 — Idempotencia del script de carga masiva

```text
Estudiante: Si el script falla a mitad, ¿hay que tirar toda la base y volver a empezar?

Claude: No necesariamente. Se puede agregar un bloque de limpieza al inicio del script
que haga TRUNCATE de todas las tablas de datos en orden inverso (respetando FKs),
deshabilitando temporalmente las verificaciones de FK:

  SET FOREIGN_KEY_CHECKS = 0;
  TRUNCATE TABLE hc_diagnosticos;
  ...
  TRUNCATE TABLE hospitales;
  SET FOREIGN_KEY_CHECKS = 1;

Así el script se puede re-ejecutar cuantas veces sea necesario sin tirar la base.
Los catálogos (tipos_sangre, especialidades_medicas, estados_cita) se recargan
desde 02_Inserciones_Prueba.sql antes de ejecutar la carga masiva.
```

**Decisión tomada:** se agregó el bloque de limpieza al inicio de `03_Carga_Masiva.sql`.
El orden de ejecución quedó establecido como:

1. `01_Script_DDL.sql` — estructura (solo la primera vez)
2. `02_Inserciones_Prueba.sql` — catálogos y datos de Etapa 1
3. `03_Carga_Masiva.sql` — limpia y recarga los datos masivos

---

### Intercambio 11 — Por qué el script de verificación usa UNION ALL y no UNION

```text
Estudiante: El script de conteo de registros usa UNION ALL. ¿Por qué UNION ALL
y no simplemente varias consultas separadas o UNION?

Claude: Hay dos partes en la respuesta:

  1. ¿Por qué UNION ALL y no consultas separadas?
  Porque el objetivo es obtener un único resultado con todos los conteos en
  una sola tabla. Consultas separadas devuelven 9 resultados distintos.
  UNION ALL los apila verticalmente en una tabla de dos columnas (tabla, total).

  2. ¿Por qué UNION ALL y no UNION?
  UNION elimina filas duplicadas (hace un DISTINCT implícito). Si dos tablas
  tienen el mismo conteo — por ejemplo, medicos y pacientes ambas con 500 —,
  UNION eliminaría una de las dos filas porque las considera idénticas.
  UNION ALL mantiene todas las filas siempre, sin importar si los valores
  coinciden. Como acá cada fila es un conteo de una tabla distinta, queremos
  conservarlas todas.

  Regla general: usar UNION ALL cuando no querés perder filas; UNION solo
  cuando necesitás eliminar duplicados explícitamente.
```

**Decisión tomada:** el script de verificación usa `UNION ALL` para garantizar
que se muestren los conteos de las 9 tablas sin importar si alguna tiene el
mismo número de registros que otra.

---

## Etapa 3 — Consultas avanzadas y reportes

**Fecha:** 2026-10-27

---

### Intercambio 12 — Diseño del rol del administrador y alcance de las consultas JOIN

```text
Claude: Pensando en el sistema hospitalario, ¿qué información necesitaría ver
un administrativo en su pantalla principal? ¿Le interesa más ver el detalle de
una cita completa (quién, con quién, cuándo, en qué sala), o preferiría ver el
plantel de médicos organizado por hospital/departamento?

Estudiante: El administrador se suele abstraer más, así que debe mirar más a
gran escala. Debería mirar por hospital, luego por departamento e ir de mucha
información a información más filtrada. No sé si el administrador es solo uno
y administra todos los hospitales o hay uno por hospital.

Claude: En sistemas hospitalarios reales suele haber un administrador general
(ve todos los hospitales) y administradores por hospital. Para la consulta
conviene diseñarla para el administrador general, así usamos más tablas en el
JOIN y es más representativa. La jerarquía del sistema es:
hospital → departamento → sala → cita.

Propuesta aceptada:
- Q1: resumen de citas por hospital y departamento (cantidades, estados,
  facturación).
- Q2: detalle del plantel médico (médico, especialidad, departamento, hospital).
```

**Decisión tomada:** Q1 y Q2 siguen la jerarquía del sistema de mayor a menor
granularidad. Q1 es el reporte de actividad general; Q2 es el reporte del
plantel médico.

---

### Intercambio 13 — Criterio del umbral mínimo para GROUP BY + HAVING

```text
Claude: Para Q3 (GROUP BY + HAVING), ¿qué umbral mínimo de citas te parece
razonable para filtrar especialidades con poca actividad?

Estudiante: Me parecen bien 5 citas como mínimo. Así de paso colocamos un
límite para no sobre analizar. Para los casos con menos de 5 citas quizás
corresponde otro criterio, o son situaciones demasiado límite y casos muy
particulares.

Claude: Perfecto. HAVING COUNT(*) > 5 deja afuera los meses y especialidades
con actividad marginal que podrían distorsionar un análisis estadístico.
Los casos con menos de 5 citas merecen otro tipo de seguimiento (por ejemplo,
revisión manual o alerta específica), no un reporte agregado.
```

**Decisión tomada:** `HAVING COUNT(c.cita_id) > 5` como umbral mínimo en Q3.
El reporte mensual filtra especialidades con actividad marginal.

---

### Intercambio 14 — Elección de la consulta con subconsulta (NOT IN)

```text
Claude: Para Q4 (subconsulta), hay tres opciones posibles:
  1. Pacientes que nunca cancelaron una cita.
  2. Médicos que nunca tuvieron una cita en estado PROGRAMADA.
  3. Pacientes con historia clínica pero sin ninguna cita registrada.
¿Cuál te parece más interesante?

Estudiante: Me gusta la opción 3. De esa forma podemos saber qué pacientes no
fueron en el último tiempo al hospital y analizar si esto sucedió porque
cambiaron de hospital o si simplemente solucionaron su problema.

Claude: Exacto. La subconsulta queda como NOT IN sobre citas, filtrando
pacientes que tienen historia clínica (están en el sistema) pero nunca
agendaron una cita. Es útil para analizar retención y seguimiento de pacientes.
```

**Decisión tomada:** Q4 usa `WHERE pac.paciente_id NOT IN (SELECT DISTINCT
paciente_id FROM citas)`, cruzado con `historias_clinicas` para asegurar que
el paciente está registrado en el sistema.

---

### Intercambio 15 — Índice más lento que full scan en M2

```text
Estudiante: Los tiempos de M2 con índice (15 ms y 16 ms en las primeras dos
corridas) fueron mayores que sin índice (< 1 ms en las tres corridas).
¿Por qué el índice es más lento?

Claude: Con volúmenes pequeños (~1.500 registros), usar un índice B-tree puede
tener más overhead que un full scan directo. El motor debe primero recorrer el
árbol del índice para encontrar las entradas del rango, y luego acceder a las
filas reales en el heap (random I/O). Con tan pocos registros, ese proceso de
dos pasos es más costoso que simplemente leer la tabla entera de corrido.
MySQL lo sabe internamente y en muchos casos elige ignorar el índice cuando
estima que el full scan es más eficiente. La diferencia real se vería con
200.000 a 500.000 registros: ahí el índice permite saltar directamente al
inicio del rango sin recorrer toda la tabla, reduciendo el tiempo de forma
significativa.
```

**Observación documentada:** con el volumen actual de la base (~1.500 registros
en `citas`), las mediciones de rendimiento no muestran diferencias significativas
entre consultas con y sin índice. El resultado más llamativo fue M2, donde el
índice resultó más lento que el full scan en las primeras corridas por el overhead
del acceso en dos pasos (índice → heap).

---

## Etapa 4 — Seguridad e integridad

**Fecha:** 2026-10-27

---

### Intercambio 16 — Elección del perfil de usuario con privilegios mínimos

```text
Claude: Para el usuario con privilegios mínimos, ¿qué rol tiene sentido en el
sistema? Por ejemplo: un usuario recepcion que solo puede consultar pacientes y
citas (solo SELECT), o un usuario medico_app que puede ver y registrar citas
pero no tocar tablas administrativas.

Estudiante: El usuario de recepcion es lo que elijo, principalmente porque es
la opción más sencilla y directa. Comprendo que buscamos usuarios con
privilegios mínimos.

Claude: Exacto. Mínimos privilegios significa darle al usuario solo lo que
necesita para su trabajo y nada más. recepcion con solo SELECT sobre las
tablas que necesita ver es perfecto para demostrarlo. Sin acceso a
historias_clinicas, hc_diagnosticos, hc_tratamientos ni hc_alergias, que son
datos médicos sensibles.
```

**Decisión tomada:** usuario `recepcion`@`localhost` con SELECT únicamente
sobre tablas operativas (pacientes, personas, citas, medicos, especialidades,
estados_cita, hospitales, departamentos, salas). Sin acceso a historias
clínicas ni tablas de catálogo médico sensible.

---

### Intercambio 17 — Elección de datos sensibles para las vistas

```text
Claude: Para las 2 vistas que ocultan información sensible, ¿qué datos
considerás sensibles en el sistema hospitalario? ¿Qué datos no debería ver
cualquier empleado?

Estudiante: Tengo una duda, porque a día de hoy en Argentina están todos los
datos filtrados del sistema de salud. ¿Qué considerás que sería mejor?

Claude: En el contexto del TPI lo que importa es demostrar el concepto técnico,
no resolver el problema real. Propuesta:

  Vista 1 — Pacientes sin datos personales completos: muestra nombre, apellido
  y teléfono, pero oculta DNI, fecha de nacimiento y tipo de sangre. Útil para
  recepción: puede buscar al paciente sin ver sus datos sensibles.

  Vista 2 — Citas sin información financiera: muestra fecha, médico,
  especialidad y estado, pero oculta el costo y las observaciones. Útil para
  quien consulta la agenda sin necesitar ver facturación.

Estudiante: Me parece bien ese par.
```

**Decisión tomada:**

- `vista_pacientes_recepcion` — oculta DNI, fecha de nacimiento y tipo de sangre.
- `vista_agenda_citas` — oculta costo y observaciones.

---

### Intercambio 18 — Cómo cambiar de usuario en MySQL Workbench

```text
Estudiante: No sé cómo cambiar entre usuarios en Workbench ni cómo crear
conexiones con otro usuario. ¿Cómo se hace?

Claude: En Workbench cada conexión es independiente. Para conectarse como
recepcion hay que crear una nueva conexión:

  1. En la pantalla de inicio de Workbench, clic en el "+" junto a
     "MySQL Connections".
  2. En "Connection Name" poné algo como "recepcion_test".
  3. En "Username" escribí recepcion.
  4. En "Password" → Store in Vault → ingresá Recepcion2024!
  5. El host y puerto quedan igual (127.0.0.1, 3306).
  6. Clic en "Test Connection" para verificar, luego "OK".

Una vez conectado como recepcion, intentás ejecutar SELECT * FROM
historias_clinicas o un INSERT INTO citas y Workbench mostrará el error
de permisos denegados que hay que capturar.
```

**Decisión tomada:** la prueba de acceso restringido se realiza creando una
conexión separada en Workbench con el usuario `recepcion`, ejecutando acciones
no permitidas y capturando los mensajes de error.

---

### Intercambio 19 — Error de collation en el procedimiento almacenado

```text
Estudiante: Al ejecutar CALL buscar_paciente_por_apellido('Garcia') da este error:
Error Code: 1267. Illegal mix of collations (utf8mb4_0900_ai_ci,IMPLICIT)
and (utf8mb4_unicode_ci,IMPLICIT) for operation '='

Claude: El conflicto ocurre porque la base fue creada con utf8mb4_unicode_ci
pero el servidor usa utf8mb4_0900_ai_ci como collation por defecto. El parámetro
del procedimiento toma la collation del servidor, que no coincide con la de la
columna apellido.

Primer intento: agregar COLLATE utf8mb4_unicode_ci al parámetro.
→ Error 1235: MySQL requiere especificar CHARACTER SET junto con COLLATE.

Segundo intento: agregar CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci.
→ Sigue fallando porque la columna en realidad tiene utf8mb4_0900_ai_ci.

Solución final: dejar el parámetro sin collation explícita (toma la del servidor,
utf8mb4_0900_ai_ci) y forzar la conversión en el WHERE:
  WHERE p.apellido COLLATE utf8mb4_0900_ai_ci = p_apellido

Estudiante: Ahora funciona correctamente.
```

**Decisión tomada:** el procedimiento usa `COLLATE utf8mb4_0900_ai_ci` en la
cláusula WHERE para alinear la collation de la columna con la del parámetro
y evitar el conflicto entre la collation de la base y la del servidor.

---

## Etapa 5 — Concurrencia y transacciones

**Fecha:** 2026-10-28

---

### Intercambio 20 — Por qué se necesitan dos pestañas para simular un deadlock

```text
Estudiante: ¿Hace falta dos pestañas separadas o puedo ejecutar todo desde
la misma pestaña de query que tengo abierta?

Claude: La necesidad es que un deadlock requiere dos transacciones abiertas
al mismo tiempo, en paralelo. Si ejecutás todo desde una sola pestaña, los
comandos se ejecutan en secuencia: primero termina uno, después arranca el otro.
Nunca van a estar los dos bloqueados al mismo tiempo, así que el deadlock
nunca ocurre.

Con dos pestañas podés dejar la Sesión A con su transacción abierta mientras
ejecutás los comandos de Sesión B. Cuando B intenta bloquear una fila que A
ya tiene, queda esperando. Recién ahí, cuando volvés a A y ésta intenta
bloquear la fila que B tiene, MySQL detecta el ciclo y emite Error 1213.
```

**Decisión tomada:** se usaron dos pestañas de query en MySQL Workbench,
cada una con su propia conexión independiente al servidor, para ejecutar
las transacciones en paralelo.

---

### Intercambio 21 — Variables de sesión no compartidas entre conexiones

```text
Estudiante: Ejecuté el SET @cita_a = 1 en una pestaña pero el UPDATE
sigue devolviendo Rows matched: 0.

Claude: Las variables de sesión (@nombre) son locales a cada conexión.
Si seteás @cita_a en la Pestaña A, la Pestaña B no la ve — cada pestaña
de Workbench abre una conexión independiente al servidor. Tenés que ejecutar
el SET en cada pestaña por separado antes de arrancar.

Estudiante: Ahora funciona, los UPDATE matchean correctamente.
```

**Decisión tomada:** el bloque `SET @cita_a` y `SET @cita_b` se ejecutó
en cada sesión por separado antes de iniciar las transacciones.

---

### Intercambio 22 — Diferencia entre Error 1213 (deadlock) y Error 2013 (timeout)

```text
Estudiante: Ocurrió Error Code: 2013. Lost connection to MySQL server during
query después de 30 segundos. ¿Es el deadlock que buscábamos?

Claude: No. Error 2013 es un lock wait timeout: una sesión esperó demasiado
tiempo por un bloqueo y MySQL la desconectó. No es un deadlock.

Un deadlock (Error 1213) ocurre cuando hay un ciclo circular de dependencias:
A espera a B y B espera a A al mismo tiempo. MySQL lo detecta en milisegundos
y mata una de las dos sesiones casi de inmediato.

En tu caso, Sesión B no tenía START TRANSACTION antes de sus UPDATEs, así que
cada UPDATE corría en autocommit y liberaba el bloqueo inmediatamente. B esperó
30 segundos por la fila que A tenía, pero A no estaba esperando nada de B,
por lo que no había ciclo.

Estudiante: Con START TRANSACTION en ambas sesiones ocurrió el Error 1213
casi de inmediato.
```

**Decisión tomada:** ambas sesiones deben abrir explícitamente una transacción
con `START TRANSACTION` antes de los UPDATEs para que los bloqueos persistan
y MySQL pueda detectar el ciclo.

---

### Intercambio 23 — Elección del nivel de aislamiento para el sistema hospitalario

```text
Estudiante: ¿Qué nivel de aislamiento es más adecuado para un sistema
hospitalario, READ COMMITTED o REPEATABLE READ?

Claude: Para un sistema hospitalario, REPEATABLE READ es más adecuado.
El motivo es que las operaciones críticas (como verificar disponibilidad
de una sala antes de confirmar una cita) requieren que los datos leídos
al inicio de una transacción no cambien durante su ejecución. Con READ
COMMITTED, una segunda lectura dentro de la misma transacción podría
devolver un valor distinto si otra sesión hizo COMMIT en el medio —
lo que se conoce como lectura no repetible.

REPEATABLE READ garantiza una snapshot consistente desde el inicio de la
transacción, lo que evita inconsistencias en operaciones multi-paso.
Es además el nivel por defecto de MySQL/InnoDB, lo que confirma que
es la elección correcta para este dominio.

Estudiante: Lo comprobamos en la práctica: con READ COMMITTED la segunda
lectura devolvió 9999.00 (el valor modificado por la otra sesión), mientras
que con REPEATABLE READ devolvió 750.00 (el valor original al inicio).
```

**Decisión tomada:** el sistema hospitalario debería operar con `REPEATABLE READ`
(nivel por defecto de InnoDB) para garantizar consistencia dentro de cada
transacción operativa.

---
