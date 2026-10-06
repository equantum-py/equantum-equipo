# Seguridad y Permisos V2 — diseño inicial

Estado: PREPARADO, NO APLICADO A PRODUCCIÓN.

## Principio rector

La autorización debe ocurrir antes de exponer datos a la interfaz, BI o eQ. Un usuario autenticado no equivale automáticamente a un colaborador interno: las cuentas del Portal también usan autenticación.

## Hallazgos confirmados

1. `clients authenticated read` permite SELECT con `USING (true)`.
2. Existe además `portal user reads own client`, pero al ser políticas permisivas se combinan y la regla amplia puede superar el aislamiento esperado.
3. `projects authenticated read` también usa `USING (true)`.
4. `improvement_suggestions` permite lectura a cualquier authenticated.
5. Tareas ya exigen `is_active_user()` para lectura y permisos adicionales para creación.
6. Tickets y mensajes ya distinguen reglas internas de reglas del Portal, aunque existen políticas históricas duplicadas que se revisarán en una segunda migración.
7. El Portal debe conservar la regla: Cliente A nunca puede acceder a datos de Cliente B.

## Cambio preparado

La migración `20261006_security_permissions_v2.sql` reemplaza las lecturas amplias de Clientes, Proyectos y Mejoras por `is_active_user()`, conservando las políticas específicas del Portal para su propio cliente.

## Lo que NO hace esta migración

- No modifica datos.
- No cambia contraseñas.
- No elimina usuarios.
- No cambia la cuenta maestra.
- No toca todavía Storage.
- No consolida todavía todas las políticas históricas de Tickets.
- No se aplica automáticamente a producción.

## Puerta de salida

Antes de aplicar en producción deben ejecutarse pruebas negativas con, como mínimo:
- colaborador interno activo;
- usuario Portal Cliente A;
- intento de acceso a Cliente B;
- usuario interno suspendido;
- usuario anónimo.

El resultado esperado es denegación por defecto fuera del alcance autorizado.
