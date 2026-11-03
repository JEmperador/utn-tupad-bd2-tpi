# Etapa 2 — Generación y carga de datos masivos con SQL puro

_Base de Datos I — UTN. Sistema de Gestión Hospitalaria._

---

## Checklist de entregables

- [x] Script SQL de carga masiva — mínimo 10.000 registros distribuidos
- [x] Descripción conceptual del mecanismo usado (1 página)
- [x] Verificaciones de consistencia — incluidas al final del script
- [x] Anexo IA — intercambios 7 a 11 documentados
- [x] 📷 Captura — resultado del conteo de registros por tabla
- [x] 📷 Captura — resultado de FK huérfanas (todos 0)

---

## Entregables

### Script SQL de carga masiva

Script que genera ~10.000 registros usando exclusivamente mecanismos SQL
(`WITH RECURSIVE`, `INSERT ... SELECT`, `CROSS JOIN`, `MOD`, `LPAD`, etc.):

- [`../../Codigo/03_Carga_Masiva_Etapa2.sql`](../../Codigo/03_Carga_Masiva_Etapa2.sql)

Distribución de registros:

| Tabla                | Registros aprox. |
| -------------------- | ---------------- |
| `hospitales`         | 6                |
| `departamentos`      | 72               |
| `salas`              | 216              |
| `personas`           | 2.001            |
| `medicos`            | 500              |
| `pacientes`          | 1.500            |
| `historias_clinicas` | 1.500            |
| `hc_diagnosticos`    | 3.000            |
| `citas`              | 1.500            |
| **Total**            | **~10.295**      |

---

### Descripción conceptual

Explica los mecanismos SQL usados y la estrategia de distribución:

- [`01_Descripcion_Mecanismos.md`](./01_Descripcion_Mecanismos.md)

---

### Verificaciones de consistencia

Las verificaciones están incluidas al final de `03_Carga_Masiva.sql`:

- Conteo de registros por tabla
- FK huérfanas = 0 en todas las relaciones principales

Resultados verificados: todos los conteos de FK huérfanas retornaron 0.

---

### Anexo IA

Evidencia de intercambios con IA durante el diseño de la estrategia:

- [`../Anexo_IA.md`](../Anexo_IA.md)
