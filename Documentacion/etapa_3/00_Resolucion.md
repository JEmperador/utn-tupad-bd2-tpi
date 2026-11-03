# Etapa 3 — Consultas avanzadas y reportes

_Base de Datos I — UTN. Sistema de Gestión Hospitalaria._

---

## Checklist de entregables

- [x] 4 consultas SQL (2 JOIN, 1 GROUP BY + HAVING, 1 subconsulta)
- [x] 1 vista útil en el contexto del sistema
- [x] Medición comparativa con/sin índice en 3 consultas (igualdad, rango, JOIN)
- [x] Tabla de tiempos (3 corridas → mediana) + EXPLAIN por consulta medida
- [x] Documentación de utilidad práctica de cada consulta (3–5 líneas c/u)
- [x] Conclusión sobre el impacto de índices (5–10 líneas)
- [x] Anexo IA — intercambios 12 a 15 documentados
- [x] 📷 Captura — resultado de Q1 (resumen de citas por hospital y departamento)
- [x] 📷 Captura — resultado de Q2 (plantel médico por hospital)
- [x] 📷 Captura — resultado de Q3 (citas completadas por mes y especialidad)
- [x] 📷 Captura — resultado de Q4 (pacientes con historia clínica sin citas)
- [x] 📷 Captura — resultado de V1 (`SELECT * FROM vista_citas_detalle LIMIT 20`)
- [x] 📷 Captura — EXPLAIN de M1 con índice y sin índice
- [x] 📷 Captura — EXPLAIN de M2 con índice y sin índice
- [x] 📷 Captura — EXPLAIN de M3 con índice FK y sin índice FK

---

## Entregables

### Script SQL de consultas

Script con las 4 consultas, la vista y los índices usados para medición:

- [`../../Codigo/04_Consultas_Etapa3.sql`](../../Codigo/04_Consultas_Etapa3.sql)

---

### Consultas y análisis de rendimiento

Descripción de cada consulta, su utilidad práctica y la tabla de tiempos con/sin índice:

- [`01_Consultas.md`](./01_Consultas.md)

---

### Anexo IA

Evidencia de intercambios con IA durante el diseño y optimización de consultas:

- [`../Anexo_IA.md`](../Anexo_IA.md)
