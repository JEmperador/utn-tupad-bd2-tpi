-- =============================================================================
-- Sistema de Gestión Hospitalaria
-- Etapa 5 — Concurrencia: deadlock y niveles de aislamiento
-- Base de Datos I — UTN
-- =============================================================================
-- Instrucciones generales:
--   Para simular concurrencia se necesitan DOS conexiones abiertas en paralelo:
--     Sesión A: pestaña 1 de Workbench
--     Sesión B: pestaña 2 de Workbench
--   Ejecutar los pasos en el orden indicado, alternando entre sesiones.
-- =============================================================================

USE hospital_db;

-- =============================================================================
-- PARTE 1 — SIMULACIÓN DE DEADLOCK
-- =============================================================================
-- Escenario: dos sesiones actualizan las mismas filas en orden inverso,
-- generando un bloqueo circular. MySQL detecta el deadlock y mata
-- automáticamente la transacción que causó menor costo de rollback (víctima),
-- devolviendo Error 1213.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Paso 1 — Identificar dos citas existentes para usar en las pruebas
-- Ejecutar en cualquier sesión antes de comenzar.
-- Anotar los IDs que devuelve (se usan como @cita_a y @cita_b).
-- -----------------------------------------------------------------------------

SELECT cita_id, estado_cita_id, costo
FROM citas
ORDER BY cita_id
LIMIT 2;

-- -----------------------------------------------------------------------------
-- Reemplazar los valores de @cita_a y @cita_b con los IDs obtenidos arriba.
-- IMPORTANTE: ejecutar este SET en CADA pestaña por separado.
-- Las variables de sesión (@nombre) son locales a cada conexión.
-- -----------------------------------------------------------------------------

SET @cita_a = 1;   -- reemplazar con el primer cita_id real
SET @cita_b = 2;   -- reemplazar con el segundo cita_id real

-- -----------------------------------------------------------------------------
-- Paso 2 — SESIÓN A: bloquear cita_a y esperar
-- -----------------------------------------------------------------------------

-- [SESIÓN A] Ejecutar este bloque completo y NO hacer COMMIT todavía:
START TRANSACTION;
UPDATE citas SET costo = costo + 1 WHERE cita_id = @cita_a;
-- Dejar la transacción abierta y pasar a Sesión B.

-- -----------------------------------------------------------------------------
-- Paso 3 — SESIÓN B: bloquear cita_b y luego intentar bloquear cita_a
-- -----------------------------------------------------------------------------

-- [SESIÓN B] Ejecutar este bloque completo:
START TRANSACTION;
UPDATE citas SET costo = costo + 1 WHERE cita_id = @cita_b;
-- Ahora intentar bloquear cita_a (ya bloqueada por Sesión A) → espera:
UPDATE citas SET costo = costo + 1 WHERE cita_id = @cita_a;
-- Sesión B queda bloqueada esperando a Sesión A.

-- -----------------------------------------------------------------------------
-- Paso 4 — SESIÓN A: intentar bloquear cita_b → deadlock
-- -----------------------------------------------------------------------------

-- [SESIÓN A] Ejecutar mientras Sesión B sigue esperando:
UPDATE citas SET costo = costo + 1 WHERE cita_id = @cita_b;
-- MySQL detecta el ciclo y mata una de las dos sesiones con Error 1213.
-- Captura aquí: la sesión con el error es la víctima del deadlock.

-- -----------------------------------------------------------------------------
-- Paso 5 — Limpiar: hacer ROLLBACK en la sesión que sobrevivió
-- -----------------------------------------------------------------------------

-- [SESIÓN que NO recibió Error 1213] Ejecutar:
ROLLBACK;

-- =============================================================================
-- PARTE 2 — COMPARACIÓN DE NIVELES DE AISLAMIENTO
-- =============================================================================
-- Escenario: Sesión A lee una fila, Sesión B la modifica, Sesión A vuelve a leer.
--   READ COMMITTED  → Sesión A ve el valor actualizado en la segunda lectura
--                     (lectura no repetible).
--   REPEATABLE READ → Sesión A sigue viendo el valor original durante toda la
--                     transacción (MySQL garantiza una snapshot al inicio).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Paso 1 — Registrar el costo original de la cita de prueba
-- Ejecutar en cualquier sesión.
-- -----------------------------------------------------------------------------

SELECT cita_id, costo FROM citas WHERE cita_id = 1;

-- ---- PRUEBA A: READ COMMITTED -----------------------------------------------

-- [SESIÓN A] Abrir transacción con READ COMMITTED y hacer primera lectura:
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
SELECT cita_id, costo FROM citas WHERE cita_id = 1;
-- Anotar el valor de costo. Dejar la transacción abierta.

-- [SESIÓN B] Modificar y confirmar el cambio:
UPDATE citas SET costo = 9999.00 WHERE cita_id = 1;
COMMIT;

-- [SESIÓN A] Segunda lectura dentro de la misma transacción:
SELECT cita_id, costo FROM citas WHERE cita_id = 1;
-- READ COMMITTED: devuelve 9999.00 (ve el commit de Sesión B).
-- Captura aquí: segunda lectura muestra el valor actualizado.
ROLLBACK;

-- ---- PRUEBA B: REPEATABLE READ -----------------------------------------------

-- [SESIÓN B] Restaurar el costo original para repetir la prueba:
UPDATE citas SET costo = 750.00 WHERE cita_id = 1;
COMMIT;

-- [SESIÓN A] Abrir transacción con REPEATABLE READ y hacer primera lectura:
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;
SELECT cita_id, costo FROM citas WHERE cita_id = 1;
-- Anotar el valor de costo. Dejar la transacción abierta.

-- [SESIÓN B] Modificar y confirmar el cambio:
UPDATE citas SET costo = 9999.00 WHERE cita_id = 1;
COMMIT;

-- [SESIÓN A] Segunda lectura dentro de la misma transacción:
SELECT cita_id, costo FROM citas WHERE cita_id = 1;
-- REPEATABLE READ: devuelve 750.00 (snapshot del inicio de la transacción).
-- Captura aquí: segunda lectura muestra el valor original, no el de Sesión B.
ROLLBACK;

-- ---- Restaurar nivel de aislamiento por defecto de MySQL ---------------------

SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
