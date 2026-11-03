-- =============================================================================
-- Sistema de Gestión Hospitalaria
-- Etapa 5 — Procedimiento con transacción y retry ante deadlock
-- Base de Datos I — UTN
-- =============================================================================

USE hospital_db;

-- =============================================================================
-- PROCEDIMIENTO CON TRANSACCIÓN Y RETRY ANTE DEADLOCK
-- =============================================================================
-- El procedimiento actualiza el costo de una cita dentro de una transacción.
-- Si MySQL devuelve Error 1213 (deadlock), reintenta hasta 2 veces con un
-- backoff de 1 segundo entre intentos.
-- =============================================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS actualizar_costo_cita$$

CREATE PROCEDURE actualizar_costo_cita(
    IN p_cita_id  INT,
    IN p_nuevo_costo DECIMAL(10,2)
)
BEGIN
    DECLARE intentos     INT     DEFAULT 0;
    DECLARE max_intentos INT     DEFAULT 2;
    DECLARE exito        BOOLEAN DEFAULT FALSE;
    DECLARE codigo_error INT;
    DECLARE mensaje_error VARCHAR(255);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            codigo_error  = MYSQL_ERRNO,
            mensaje_error = MESSAGE_TEXT;

        ROLLBACK;

        IF codigo_error = 1213 AND intentos < max_intentos THEN
            SET intentos = intentos + 1;
            SELECT CONCAT(
                '[RETRY] Deadlock detectado. Intento ', intentos, ' de ', max_intentos,
                '. Error: ', mensaje_error
            ) AS log_retry;
            DO SLEEP(1);
            CALL actualizar_costo_cita(p_cita_id, p_nuevo_costo);
        ELSE
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = mensaje_error;
        END IF;
    END;

    START TRANSACTION;
    UPDATE citas SET costo = p_nuevo_costo WHERE cita_id = p_cita_id;
    COMMIT;
    SET exito = TRUE;

    IF exito THEN
        SELECT CONCAT('[OK] Cita ', p_cita_id, ' actualizada a $', p_nuevo_costo) AS resultado;
    END IF;
END$$

DELIMITER ;

-- -----------------------------------------------------------------------------
-- Prueba del procedimiento — ejecución normal (sin deadlock)
-- -----------------------------------------------------------------------------

CALL actualizar_costo_cita(1, 750.00);
-- Resultado esperado: [OK] Cita 1 actualizada a $750.00
