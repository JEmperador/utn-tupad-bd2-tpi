-- =============================================================================
-- Sistema de Gestión Hospitalaria
-- Etapa 3 — Índices para medición de rendimiento
-- Base de Datos I — UTN
-- =============================================================================
-- Ejecutar ANTES de 05_explain.sql.
-- El índice creado aquí es eliminado al final de 05_explain.sql.
-- =============================================================================

USE hospital_db;

-- Índice sobre citas.fecha_hora para comparar rendimiento con/sin índice (M1, M2)
DROP INDEX IF EXISTS idx_citas_fecha_hora ON citas;
CREATE INDEX idx_citas_fecha_hora ON citas (fecha_hora);
