# Etapa 5 — Concurrencia y transacciones: documentación técnica

_Base de Datos I — UTN. Sistema de Gestión Hospitalaria._

---

## Simulación de deadlock

### Escenario

Se utilizaron dos sesiones de MySQL Workbench (Sesión A y Sesión B) actualizando
las mismas filas de la tabla `citas` en orden inverso, generando un bloqueo circular.

| Paso | Sesión A | Sesión B |
| ---- | -------- | -------- |
| 1 | `START TRANSACTION` | |
| 2 | `UPDATE citas ... WHERE cita_id = 1` → bloquea fila 1 | |
| 3 | | `START TRANSACTION` |
| 4 | | `UPDATE citas ... WHERE cita_id = 2` → bloquea fila 2 |
| 5 | | `UPDATE citas ... WHERE cita_id = 1` → **espera** (A tiene la fila) |
| 6 | `UPDATE citas ... WHERE cita_id = 2` → **deadlock** | |

### Resultado

MySQL detectó el ciclo de dependencia y eligió a **Sesión A como víctima**,
cancelando su transacción con el siguiente error:

```
Error Code: 1213. Deadlock found when trying to get lock; try restarting transaction
```

Sesión B, liberada del bloqueo, completó su UPDATE exitosamente tras **15.8 segundos**
de espera y hizo COMMIT.

---

## Transacciones con retry ante deadlock

Se implementó el procedimiento almacenado `actualizar_costo_cita` que encapsula
una operación de actualización dentro de una transacción explícita e incluye
manejo de Error 1213 con hasta 2 reintentos y backoff de 1 segundo entre intentos.

### Prueba de ejecución normal

```sql
CALL actualizar_costo_cita(1, 750.00);
```

**Resultado:** `[OK] Cita 1 actualizada a $750.00`

La transacción completó sin deadlock. El procedimiento hizo `START TRANSACTION`,
ejecutó el `UPDATE` y confirmó con `COMMIT`.

---

## Comparación de niveles de aislamiento

### Escenario

Sesión A abre una transacción y lee el `costo` de `cita_id = 1`.
Sesión B modifica ese valor y hace `COMMIT`.
Sesión A vuelve a leer la misma fila dentro de la misma transacción.

### Prueba A — READ COMMITTED

| Momento | Sesión A | Sesión B |
| ------- | -------- | -------- |
| Primera lectura | `costo = 750.00` | |
| | | `UPDATE citas SET costo = 9999.00` + `COMMIT` |
| Segunda lectura | `costo = 9999.00` | |

**Observación:** con `READ COMMITTED`, Sesión A vio el valor modificado por Sesión B
en la segunda lectura, aunque la transacción de A seguía abierta. Esto se conoce
como **lectura no repetible**.

### Prueba B — REPEATABLE READ

| Momento | Sesión A | Sesión B |
| ------- | -------- | -------- |
| Primera lectura | `costo = 750.00` | |
| | | `UPDATE citas SET costo = 9999.00` + `COMMIT` |
| Segunda lectura | `costo = 750.00` | |

**Observación:** con `REPEATABLE READ` (nivel por defecto de MySQL/InnoDB), Sesión A
obtuvo el mismo valor en ambas lecturas. MySQL mantiene una snapshot consistente
del inicio de la transacción, ignorando los commits posteriores de otras sesiones.

---

## Informe de observaciones

El deadlock se produjo de forma inmediata al generarse el bloqueo circular entre
las dos sesiones: MySQL no esperó el timeout sino que detectó el ciclo y eligió
una víctima en milisegundos. El mecanismo de retry implementado en el procedimiento
`actualizar_costo_cita` permite que la operación se reintente automáticamente ante
este error, evitando que el error llegue a la capa de aplicación.

La diferencia entre `READ COMMITTED` y `REPEATABLE READ` fue claramente observable:
con el primer nivel la segunda lectura devolvió el valor actualizado por otra sesión
(`9999.00`), mientras que con el segundo nivel la transacción mantuvo el valor
original (`750.00`) durante toda su duración. Para un sistema hospitalario, donde
la consistencia de datos dentro de una operación es crítica (por ejemplo, verificar
disponibilidad de una sala antes de confirmar una cita), `REPEATABLE READ` es el
nivel de aislamiento más adecuado.
