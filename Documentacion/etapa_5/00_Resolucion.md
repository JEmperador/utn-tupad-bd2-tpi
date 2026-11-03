# Etapa 5 — Concurrencia y transacciones

_Base de Datos I — UTN. Sistema de Gestión Hospitalaria._

---

## Checklist de entregables

- [x] Simulación de al menos 1 deadlock en dos sesiones documentado
- [x] Transacciones con START TRANSACTION / COMMIT / ROLLBACK implementadas
- [x] Manejo de error 1213 (deadlock) con retry (hasta 2 reintentos con backoff)
- [x] Comparación práctica de READ COMMITTED vs REPEATABLE READ
- [x] Informe breve (5–10 líneas) con observaciones sobre concurrencia
- [x] Anexo IA — intercambios 20 a 23 documentados
- [x] 📷 Captura — las dos sesiones en el momento del bloqueo cruzado
- [x] 📷 Captura — error 1213 en la sesión que pierde el deadlock
- [x] 📷 Captura — retry exitoso ante deadlock
- [x] 📷 Captura — ejemplo con READ COMMITTED (comportamiento observable)
- [x] 📷 Captura — mismo ejemplo con REPEATABLE READ (diferencia observable)

---

## Entregables

### Script SQL de concurrencia y transacciones

Guion de pruebas con simulación de deadlock, transacciones y niveles de aislamiento:

- [`../../Codigo/06_Concurrencia_Etapa5.sql`](../../Codigo/06_Concurrencia_Etapa5.sql)

---

### Documentación técnica

Descripción de pruebas, resultados y observaciones:

- [`01_Concurrencia.md`](01_Concurrencia.md)

---

### Anexo IA

Evidencia de intercambios con IA durante la etapa:

- [`../Anexo_IA.md`](../Anexo_IA.md)
