# Etapa 4 — Seguridad e integridad

_Base de Datos I — UTN. Sistema de Gestión Hospitalaria._

---

## Checklist de entregables

- [x] Usuario MySQL con privilegios mínimos creado
- [x] Prueba de acceso restringido (acción denegada documentada)
- [x] 2 vistas que oculten información sensible
- [x] 2 pruebas de integridad (violación de constraints con error documentado)
- [x] Consulta segura contra SQL injection (Opción B: procedimiento almacenado SQL sin SQL dinámico)
- [x] Prueba anti-inyección documentada (intento malicioso + resultado + explicación)
- [x] Anexo IA — intercambios 16 a 19 documentados
- [x] 📷 Captura — creación del usuario y asignación de permisos
- [x] 📷 Captura — error al intentar acción no permitida con el usuario restringido
- [x] 📷 Captura — resultado de cada vista (2 capturas)
- [x] 📷 Captura — errores de las 2 pruebas de integridad
- [x] 📷 Captura — prueba anti-inyección bloqueada

---

## Entregables

### Script SQL de seguridad

Script con la creación del usuario, permisos y vistas:

- [`../../Codigo/05_Seguridad_Etapa4.sql`](../../Codigo/05_Seguridad_Etapa4.sql)

---

### Consulta segura

Código con la implementación de la consulta parametrizada y la prueba anti-inyección:

- Opción elegida: **B — procedimiento almacenado SQL sin SQL dinámico**

---

### Anexo IA

Evidencia de intercambios con IA durante el diseño de la seguridad:

- [`../Anexo_IA.md`](../Anexo_IA.md)
