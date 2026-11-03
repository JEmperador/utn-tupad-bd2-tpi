# Usuario recepcion — Referencia de conexión

_Base de Datos I — UTN. Sistema de Gestión Hospitalaria._

---

## Credenciales

| Campo    | Valor            |
| -------- | ---------------- |
| Usuario  | `recepcion`      |
| Password | `Recepcion2024!` |
| Host     | `127.0.0.1`      |
| Puerto   | `3306`           |
| Base     | `hospital_db`    |

> **Nota:** el usuario fue creado como `'recepcion'@'127.0.0.1'` (no `localhost`)
> porque Workbench se conecta por TCP y MySQL los trata como hosts distintos.

---

## Cómo crear la conexión en MySQL Workbench

1. En la pantalla de inicio, clic en el **"+"** junto a "MySQL Connections".
2. **Connection Name:** `recepcion_test`
3. **Username:** `recepcion`
4. **Password** → clic en "Store in Vault…" → ingresar `Recepcion2024!`
5. Host y puerto quedan igual: `127.0.0.1`, `3306`
6. Clic en **"Test Connection"** para verificar → si dice OK, clic en "OK".

---

## Pruebas de acceso restringido

Conectado como `recepcion`, ejecutar estas sentencias por separado y capturar el error de cada una:

```sql
-- Debe dar error: SELECT command denied
SELECT * FROM historias_clinicas;

-- Debe dar error: INSERT command denied
INSERT INTO citas (paciente_id, medico_id, sala_id, fecha_hora, costo, estado_cita_id)
VALUES (1, 1, 1, NOW(), 500.00, 1);
```

---

## Tablas a las que recepcion SÍ tiene acceso (solo SELECT)

- `pacientes`
- `personas`
- `citas`
- `medicos`
- `especialidades_medicas`
- `estados_cita`
- `hospitales`
- `departamentos`
- `salas`

## Tablas a las que recepcion NO tiene acceso

- `historias_clinicas`
- `hc_diagnosticos`
- `hc_tratamientos`
- `hc_alergias`
- `tipos_sangre`
