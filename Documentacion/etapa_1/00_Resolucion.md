# Etapa 1 — Modelado y Constraints

_Base de Datos I — UTN. Sistema de Gestión Hospitalaria._

---

## Checklist de entregables

- [x] DER — diagrama generado en dbdiagram.io
- [x] Modelo relacional formal
- [x] Script SQL con PK, FK, UNIQUE, CHECK y restricciones de dominio
- [x] Inserciones de prueba — 2 correctas y 2 erróneas
- [x] Anexo IA — intercambios documentados
- [x] 📷 Captura — resultado de las 2 inserciones correctas (sin error)
- [x] 📷 Captura — resultado de las 2 inserciones erróneas (mensajes de error distintos)

---

## Entregables

### DER

Generado en [dbdiagram.io](https://dbdiagram.io/d/Sistema-de-Gestion-Hospitalaria-6adf7906aac3301410252873).

Archivos exportados:

- [`Sistema de Gestión Hospitalaria.png`](./Sistema%20de%20Gestión%20Hospitalaria.png)
- [`Sistema de Gestión Hospitalaria.svg`](./Sistema%20de%20Gestión%20Hospitalaria.svg)

Pseudocódigo fuente (DBML):

- [`01_Modelo_DBML.md`](./01_Modelo_DBML.md)

---

### Modelo relacional

Descripción formal de tablas, atributos, PKs, FKs y constraints:

- [`02_Modelo_Relacional.md`](./02_Modelo_Relacional.md)

---

### Script SQL

Script DDL completo con todas las restricciones de integridad:

- [`../../Codigo/01_Script_DDL_Etapa1.sql`](../../Codigo/01_Script_DDL_Etapa1.sql)

Incluye:

- `PRIMARY KEY` con `AUTO_INCREMENT` en todas las tablas
- `FOREIGN KEY` con nombre explícito (`fk_`)
- `UNIQUE` con nombre explícito (`uq_`)
- `CHECK` con nombre explícito (`chk_`):
  - `dni REGEXP '^[0-9]{7,8}$'`
  - `fecha_nacimiento < CURDATE()`
  - `costo >= 0`
  - Valores válidos en `tipos_sangre` y `estados_cita`
- `ENGINE=InnoDB`, `CHARSET=utf8mb4`

---

### Inserciones de prueba

Script con 2 inserciones correctas y 2 erróneas, verificando errores distintos:

- [`../../Codigo/02_Inserciones_Prueba_Etapa1.sql`](../../Codigo/02_Inserciones_Prueba_Etapa1.sql)

| #   | Tipo     | Qué se prueba                                       | Error esperado                                     |
| --- | -------- | --------------------------------------------------- | -------------------------------------------------- |
| 1   | Correcta | Carga completa: catálogos, hospital, personas, cita | Sin error                                          |
| 2   | Correcta | Segundo paciente con datos válidos distintos        | Sin error                                          |
| 3   | Errónea  | DNI duplicado (`30123456`)                          | `Duplicate entry` — viola `uq_personas_dni`        |
| 4   | Errónea  | Tipo de sangre inválido (`'XX'`)                    | `Check constraint` — viola `chk_tipos_sangre_desc` |

---

### Anexo IA

Evidencia de intercambios con IA durante el diseño:

- [`../Anexo_IA.md`](../Anexo_IA.md)
