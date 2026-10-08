<!-- CHECKPOINT-01 -->
# CHECKPOINT 01 — ESTADO ACTUAL DEL RELANZAMIENTO

**Fecha:** 2026-10-07  
**Rama de integración:** `relanzamiento-2026`  
**HEAD local:** `2c56f22` — `fix: close task permissions and rls qa`  
**HEAD remoto relanzamiento:** `5d6661f`  
**Commits locales pendientes de push:** 8  
**Commits sobre `origin/main`:** 41  
**Producción:** BLOQUEADA / NO AUTORIZADA

> Este checkpoint representa el estado actual. Las secciones históricas
> posteriores deben interpretarse junto con este bloque.

## Estado técnico actual

| Control | Estado |
|---|---|
| PostgreSQL staging local | PASS |
| Rama de integración aislada de main | PASS |
| Build Next.js final en `2c56f22` | PASS |
| Suite SQL actual | PASS — 20/20 |
| Triage V2 | IMPLEMENTADO + PROBADO |
| Radar V2 | IMPLEMENTADO + PROBADO |
| Tasks permisos/historial/RLS | IMPLEMENTADO + PROBADO |
| Ticket multi-task | IMPLEMENTADO + PROBADO |
| Núcleo comercial V2 | IMPLEMENTADO + PROBADO |
| Financial Core V2 | IMPLEMENTADO + PROBADO |
| Financial Dashboard V2 | IMPLEMENTADO + BUILD PASS |
| Financial Operations V2 | IMPLEMENTADO + PROBADO |
| Permiso `financial_info` Master-only | IMPLEMENTADO + PROBADO |
| Boundary financiero antes de IA | IMPLEMENTADO + PRUEBAS PARCIALES |
| ACC-SEC-003 HTTP sin autenticación | PASS — 401 |
| ACC-SEC-003 HTTP autenticado | PENDIENTE |
| ACC-SEC-003 global | PARTIAL |
| 361 criterios de aceptación | VALIDACIÓN FORMAL PENDIENTE |
| 40 casos de integración | PENDIENTE |
| ACC-MIG-001 | PASS |
| Release producción | BLOQUEADO |

## Evidencia QA actual

Suite SQL ejecutada en staging:

**20 PASS / 0 FAIL / 20 TOTAL**

Este resultado valida la suite técnica actual, pero **no equivale a 361/361
criterios de aceptación ni autoriza producción**.

## Respaldo

- Commit local: SÍ.
- Push de los últimos 8 commits: PENDIENTE.
- GitHub permanece en `5d6661f`.
- Motivo registrado: error interno de GitHub durante intentos anteriores.
- Los cambios posteriores a `5d6661f` todavía no deben considerarse
  respaldados remotamente.

## Próxima porción

**ACC-MIG-001 — ensayo reproducible de migración, backup y restore.**

Criterio para cerrar esa porción:

1. backup verificable;
2. restore reproducible en staging;
3. migraciones aplicables;
4. reconciliación de datos;
5. errores de restore resueltos o formalmente justificados;
6. evidencia registrada;
7. commit;
8. push o registro explícito de bloqueo remoto.

---

# Relanzamiento eQuantum — Estado de Implementación

Fecha de corte: 2026-10-07
Rama: relanzamiento-2026
Producción: NO AUTORIZADA
Main: NO MODIFICAR

## Estados

- PASS: implementado y demostrado
- PARTIAL: implementado parcialmente o falta evidencia final
- PENDING: pendiente
- BLOCKED: bloqueado por dependencia
- N/A: no aplica, con justificación

---

## 1. Infraestructura y seguridad de trabajo

| Control | Estado | Evidencia |
|---|---|---|
| Rama aislada relanzamiento-2026 | PASS | Rama activa separada de main |
| Main protegido durante relanzamiento | PASS | Sin merge a main |
| Backup producción | PASS | pg_dump PostgreSQL 17 + copia cifrada |
| Restore de ensayo | PASS | Restore PostgreSQL reproducible; Vault excluido explícitamente por no estar disponible en PostgreSQL local |
| Staging sin costo | PASS | PostgreSQL 17 en Docker |
| Variables sensibles fuera de Git | PASS | .env* incluido en .gitignore |
| APIs IA pagas | PASS | No utilizadas |

---

## 2. Modelo de datos V2

| Control | Estado | Evidencia |
|---|---|---|
| Inventario Supabase | PASS | Auditoría realizada |
| Baseline staging | PASS | staging-baseline.dump |
| Entidad comercial canónica | PASS | Migraciones V2 |
| Catálogo maestro | PASS | Migraciones y pruebas |
| IDs estables | PASS | Modelo V2 |
| Estado actual + historial | PASS/PARTIAL | Implementado en módulos ya migrados |
| Relaciones ambiguas no inventadas | PASS | Tasks sin client_id conservadas sin auto-link |

---

## 3. Comercial

| Control | Estado | Evidencia |
|---|---|---|
| Prospecto -> Oportunidad | PASS | RPC + Golden comercial |
| Conversión idempotente | PASS | Golden comercial |
| WON -> exactamente una Sale | PASS | Golden comercial |
| LOST -> no crea Sale | PASS | Golden comercial |
| Quick Sale reutiliza oportunidad equivalente | PASS | Golden comercial |
| Quick Sale sin oportunidad equivalente | PARTIAL | Camino pendiente de prueba/cierre |
| Propuestas versionadas | PARTIAL | Modelo disponible; falta cobertura final |
| Snapshot de cierre en Sale | PASS/PARTIAL | Implementación V2; falta matriz ACC completa |

---

## 4. Finanzas

| Control | Estado | Evidencia |
|---|---|---|
| Sale separada de Invoice | PASS | PostgreSQL local: golden_financial_v2 y financial_functions_e2e_v2 |
| Invoice separada de Payment | PASS | PostgreSQL local: golden_financial_v2 y financial_functions_e2e_v2 |
| Caja / movimientos | PARTIAL | Movimientos y conciliacion sin duplicar cobro probados localmente; falta validar alcance integral |
| Multimoneda gobernada | PARTIAL | Separacion de monedas y rechazo de Payment incompatible probados; conversion y gobierno pendientes de evidencia |
| Tratamiento fiscal | PENDING | Falta implementación |
| Comisión excluye IVA | PENDING | Falta implementación |
| Historial de política de comisión | PENDING | Falta implementación |
| Golden financiero exacto | PASS | golden_financial_v2 ejecutado dentro del QA 21/21; alcance SQL local, no certifica todo Documento 19 |

---

## 5. Tasks / Tickets

| Control | Estado | Evidencia |
|---|---|---|
| Historial automático Task | PASS | 73cdd95 + tasks_history_v2 |
| view_area_tasks | PASS | tests permisos |
| reassign_tasks | PASS | tests positivos/negativos |
| delete_tasks | PASS | tests positivos/negativos |
| Ticket permite múltiples Tasks | PASS | eb7bc8a + ticket_multi_tasks_v2 |
| Task completada no cierra Ticket | PASS | test realizado |
| Ticket 0/1/N Tasks | PASS | ACC-TICKET-004 |

---

## 6. Radar

| Control | Estado | Evidencia |
|---|---|---|
| Radar backend | PASS | 6b1624d |
| Followup -> Radar automático | PASS | trigger sync_followup_to_radar |
| Radar idempotente | PASS | índice + upsert |
| Overdue sin navegador | PASS | radar_operational_v2 |
| Cierre Radar backend | PASS | close_radar_item |
| Golden Radar | PASS | 7/7 |
| Dashboard consume Radar V2 | PASS | 5d6661f |
| Acceso vista autenticada | PASS | radar_operational_access_v2 |
| E2E visual Radar | PENDING | Falta Preview/E2E final |

---

## 7. RLS / Portal

| Control | Estado | Evidencia |
|---|---|---|
| RLS interno | PASS | V2/V3/V3.1/V3.2 |
| Portal aislado por empresa | PASS | pruebas positivas/negativas |
| Portal sin notas internas | PASS | pruebas de aislamiento |
| financial_info DB | PASS | negative tests DB |
| financial_info API | PARTIAL | Asistente HTTP local validado en checkpoint 03; falta cobertura del resto de APIs aplicables |
| financial_info IA | PASS | Checkpoint 03: bloqueo previo a contexto/proveedor, dentro del alcance local probado |
| Storage privado | PARTIAL | Checkpoint 04B: A/B PostgreSQL local PASS; servicio remoto y flujos E2E pendientes |
| Master protegido | PASS | Cuenta master preservada |

---

## 8. Triage

| Control | Estado | Evidencia |
|---|---|---|
| UI Triage existente | PASS | Dashboard actual |
| Regla de prioridad backend | PASS | Trigger INSERT/UPDATE probado en PostgreSQL local: tasks_triage_integration_v2 |
| Score reproducible backend | PASS | calculate_task_triage: siete casos Golden locales; dashboard consume score persistido |
| Razones de priorización backend | PASS | Razones exactas y limpieza probadas mediante trigger local; E2E visual pendiente |
| Golden Triage | PASS | golden_triage_v2: siete casos de calculo local, sin certificar E2E |

---

## 9. Chat / eQ / DOTS / IA

| Módulo | Estado |
|---|---|
| Chat V2 | PENDING |
| eQ | PENDING |
| DOTS | PENDING |
| Orquestación IA | PENDING |
| Memoria/Conocimiento | PENDING |
| Gobernanza IA | PENDING |
| Evaluación IA | PENDING |
| Observabilidad IA | PENDING |

---

## 10. BI / Centro Ejecutivo

| Módulo | Estado |
|---|---|
| BI V2 | PENDING |
| Centro Ejecutivo | PENDING |
| ULi | PENDING |
| Indicadores financieros reales | PENDING |

---

## 11. QA y Release

| Control | Estado |
|---|---|
| Golden comercial funcional | PASS |
| Golden Radar | PASS |
| Tests RLS | PASS |
| Tests Tasks | PASS |
| Tests Ticket multi-task | PASS |
| 361 ACC matriz completa | PENDING |
| 40 IT/INT | PENDING |
| Playwright E2E | PENDING |
| Vercel Preview del candidato de release | PENDING | Validar el commit final seleccionado para release |
| Ensayo rollback final | PENDING |
| Merge main | BLOCKED |
| Producción | BLOCKED |

---

## Gates para producción

Producción permanece BLOQUEADA hasta:

1. Migraciones completas y reversibles.
2. RLS y permisos finales aprobados.
3. Finanzas/Documento 19 implementado y probado.
4. Golden Dataset completo aprobado.
5. ACC críticos aprobados.
6. IT/INT críticos aprobados.
7. E2E aprobado.
8. Preview/Staging aprobado.
9. Rollback ensayado.
10. Autorización explícita de release.


## CHECKPOINT 02 — ACC-MIG-001 CERRADO

**Resultado:** PASS para backup/restore PostgreSQL y cadena de migraciones V2.

### Evidencia

- Backup utilizado: `staging-baseline.dump`.
- PostgreSQL de ensayo: 17.
- Restore limpio ejecutado en base temporal independiente.
- `supabase_vault` aislado explícitamente:
  - schema `vault`;
  - extensión `supabase_vault`;
  - comentario de extensión;
  - datos `vault.secrets`.
- Primer restore filtrado: exit code `0`, stderr `0`.
- Segundo restore desde cero: exit code `0`, stderr `0`.
- Migraciones V2: `18/18 PASS`, `0 FAIL`.
- Runner oficial: `scripts/relaunch/migrate-v2-order.sh`.
- QA sobre base reconstruida: `20/20 PASS`, `0 FAIL`.
- Baseline final:
  - clients: 3
  - profiles: 3
  - tasks: 3
  - tickets: 2
  - user_permissions: 3
  - opportunities: 0
  - sales: 0
  - invoices: 0
  - payments: 0
  - bank_movements: 0
- RLS: `30/30` tablas públicas.
- Policies: `53`.
- `is_internal_user()` presente.
- `has_financial_info()` presente.
- `authenticated` sin SELECT directo sobre `user_permissions`.
- `authenticated` sin SELECT directo sobre `profiles`.
- Base `equantum_staging` original permaneció intacta.

### Límite de la evidencia

Este PASS demuestra recuperación PostgreSQL, datos de negocio, migraciones,
RLS y pruebas SQL del relanzamiento.

**No certifica un restore completo de servicios administrados de Supabase
Auth/Storage/Vault.** `supabase_vault` no está disponible en el contenedor
PostgreSQL local y fue excluido de manera explícita, no ignorado silenciosamente.

### Próximo checkpoint

Checkpoint 03: cierre de bloqueantes de seguridad y aceptación restantes.

---

---

## CHECKPOINT 03 — Seguridad financiera del asistente

**Fecha:** 2026-10-07  
**Criterio trabajado:** ACC-SEC-003  
**Estado técnico del control probado:** PASS  
**Producción:** NO DESPLEGADA / NO AUTORIZADA

### Objetivo

Validar que una consulta financiera sensible sea rechazada antes de:

1. cargar contexto operativo;
2. consultar información de tareas/clientes/seguimientos;
3. invocar un proveedor externo de IA.

### Implementación

La lógica de `POST /api/ai/assistant` fue separada en un handler reutilizable:

- `app/api/ai/assistant/route.ts`
- `lib/ai/assistant-handler.ts`

La ruta pública continúa utilizando el cliente Supabase real de servidor.

No se agregó bypass de autenticación ni endpoint de pruebas al código final.

### Orden de seguridad validado

1. autenticación;
2. `has_financial_info`;
3. clasificación de consulta financiera;
4. respuesta 403 si no está autorizada;
5. recién después carga de contexto;
6. recién después, si corresponde, proveedor externo de IA.

### Evidencia HTTP local aislada

Prueba ejecutada mediante Next.js local contra el mismo
`handleAssistantPost` utilizado por `/api/ai/assistant`.

Casos:

- PASS — sin autenticación → HTTP 401, queries=0, fetch=0.
- PASS — autenticado sin `financial_info` → HTTP 403, queries=0, fetch=0.
- PASS — error en RPC de permiso → HTTP 403, queries=0, fetch=0.
- PASS — intento de prompt injection financiero → HTTP 403, queries=0, fetch=0.
- PASS — consulta operativa autenticada → HTTP 200, queries=3, fetch=0.

**Resultado:** 5/5 casos PASS.

### Fail-closed

Si la verificación `has_financial_info` falla y la consulta solicita
información financiera restringida, la solicitud se rechaza con 403.

No se cargan `tasks`, `clients` ni `followups` antes del rechazo.

No se realiza llamada al proveedor externo de IA antes del rechazo.

### Validación de compilación

- TypeScript `npx tsc --noEmit`: PASS.
- Next.js production build: PASS.
- Compilación: PASS.
- Lint/type validation: PASS.
- Static pages: 11/11.
- `/api/ai/assistant`: ruta dinámica válida.

### Limpieza

El endpoint temporal utilizado para la prueba HTTP fue eliminado antes
del cierre.

Código final no contiene `/api/test/acc-sec-003`.

### Alcance y límite de evidencia

Esta evidencia valida la integración HTTP local del handler,
autenticación simulada, autorización financiera simulada, fail-closed,
orden de controles y ausencia de acceso a contexto/IA antes del rechazo.

**No constituye una prueba E2E contra Supabase Auth remoto.**

No se utilizó producción como ambiente de prueba.

No se realizaron llamadas pagas de IA.

### Resultado Checkpoint 03

**ACC-SEC-003 — PASS dentro del alcance técnico probado.**

La validación integral de release continúa sujeta a los criterios
formales restantes, staging/evidencias aplicables y autorización de
despliegue.

## Checkpoint 04 — Storage Portal RLS A/B

Fecha de ejecución: 2026-10-07

### Alcance probado

Se validó localmente el aislamiento horizontal del bucket
`ticket-attachments` mediante RLS sobre `storage.objects`.

La prueba reproduce temporalmente la capa mínima de permisos
administrados por Supabase dentro de una transacción y finaliza
con `ROLLBACK`.

### Resultado

- Usuario Portal A puede leer su propio objeto: PASS.
- Usuario Portal A no puede leer objeto de B: PASS.
- Usuario Portal B puede leer su propio objeto: PASS.
- Usuario Portal B no puede leer objeto de A: PASS.
- Objetos residuales después de la prueba: 0.
- Grants temporales sobre Storage después del rollback: no persistieron.

Prueba reproducible:

`supabase/tests/storage_portal_isolation_v3.sql`

### Límite de la evidencia

PASS dentro del alcance PostgreSQL/RLS local probado.

La prueba no constituye por sí sola validación E2E del servicio
Supabase Storage remoto ni certificación global de seguridad.

## Checkpoint 04B — Integracion Storage en QA SQL

Fecha: 2026-10-07.

### Evidencia

- Base local probada: equantum_restore_clean.
- Contenedor: equantum-staging.
- Politica ticket attachments read authorized presente en ambas
  bases locales: equantum_staging y equantum_restore_clean.
- Storage A/B: A propio=1, otro=0; B propio=1, otro=0.
- Prueba A/B finalizada con ROLLBACK.
- Objetos QA antes/despues: 0/0.
- Permisos temporales auth/storage/SELECT: no persistieron.
- Runner: scripts/relaunch/qa-sql.sh.
- Regresion SQL: PASS=21 FAIL=0 TOTAL=21; codigo de resultado 0.
- bash -n y git diff --check: sin errores.

### Cambios

security_rls_v3.sql exige RLS habilitado y presencia de la politica
autorizada de lectura para authenticated, ademas de rechazar la
politica amplia anterior.

storage_portal_isolation_v3.sql comprueba esos requisitos y rechaza
un rol authenticated con superusuario, BYPASSRLS o propiedad de objects.

El runner incluye todos los tests SQL y solo admite la base local
equantum_restore_clean dentro del contenedor equantum-staging.

### Limites

PASS dentro del alcance PostgreSQL/RLS local probado.
No valida el servicio remoto Supabase Storage ni sus flujos E2E.
21/21 tests SQL no equivale a 361/361 criterios formales.

La causa historica de la consulta que devolvio cero politicas no
quedo demostrada. No se reinstalaron ni modificaron politicas:
la politica autorizada ya estaba presente al verificar ambas bases.

## Checkpoint 05 — Reconciliacion de estado y evidencia

Fecha: 2026-10-07.

Se actualizaron las filas generales con evidencia de los checkpoints
03/04B y del QA SQL 21/21 ejecutado en equantum_restore_clean.

No se rehizo implementacion ni se repitieron pruebas ya aprobadas.
PASS en estas filas conserva el alcance local indicado.

Pendientes identificados:
- Triage: prueba integrada del trigger y razones esperadas.
- Finanzas: reconciliacion completa contra Documento 19,
  tratamiento fiscal, comisiones y gobierno multimoneda.
- Auth/Storage remoto, recorridos E2E y Preview del candidato.
- Ensayo final de rollback.
- Matriz de criterios y casos de integracion: no localizada en
  el repo ni en la busqueda limitada realizada en Cloud Shell.

No se certifican 361/361 criterios ni 40/40 casos.
Main y produccion permanecen fuera de este checkpoint.

## Checkpoint 06 — Triage integrado

Fecha: 2026-10-07.
Base: equantum_restore_clean; contenedor: equantum-staging.

Prueba: supabase/tests/tasks_triage_integration_v2.sql.

Resultados:
- INSERT calcula score, prioridad y razones, reemplazando valores enviados.
- UPDATE individual de cada uno de los cinco factores recalcula Triage.
- Score, prioridad y razones coinciden con los resultados esperados.
- Restablecer factores elimina razones anteriores.
- Editar descripcion conserva Triage.
- ROLLBACK deja cero Tasks QA residuales.
- Test integrado: codigo 0.
- Regresion SQL: PASS=22 FAIL=0 TOTAL=22; codigo 0.

Alcance: comportamiento del backend PostgreSQL local como postgres.
No certifica permisos de usuarios, E2E visual ni resistencia a
modificaciones directas de columnas derivadas mediante UPDATE.
No equivale a 361/361 criterios ni 40/40 casos de integracion.

## Checkpoint 07 — Correcciones agrupadas de release

Base: equantum_restore_clean; contenedor: equantum-staging.
No se aplicaron cambios a produccion ni a equantum_staging.

- Migracion nueva: supabase/migrations/20261008013538_release_guards_v3.sql.
- Triage: UPDATE directo de columnas derivadas vuelve a calcular desde factores.
- Idempotencia Payment: rechaza reutilizar referencia con factura/importe/metodo distintos.
- Panel: solo cobros confirmados; pendientes por factura; excluye borradores/anuladas del facturado.
- RLS financiero: fixtures no vacios y SET LOCAL ROLE authenticated; permitido/restringido/restringido.
- Tests del resumen financiero: cuatro casos PASS.
- Suite SQL: 23/23 PASS, FAIL=0.
- TypeScript y build de Next.js: codigo 0.
- Runner de migraciones: detiene la secuencia ante el primer fallo.
- Registros originales recuperados: 361 criterios y 40 casos; matrices de trabajo separadas.

Esta evidencia no certifica todas las APIs, funciones Edge, Auth/Storage remoto,
Preview, E2E, impuestos/comisiones ni los modulos 13-19 completos.
El test financiero anterior consultaba como postgres sin fixtures y no certificaba
RLS positivo/negativo. Fue reemplazado por prueba con rol real y datos presentes.
Los criterios formales no se marcaron PASS automaticamente.
Produccion permanece BLOQUEADA.

## Checkpoint 06 — Resumen financiero por moneda

Ejecución local: 2026-10-07, America/Asuncion (2026-10-08 UTC).
Candidato probado: 1891cf7c586a754081985e38948194d72c196fd2.
Carpeta de prueba: /home/equantumg/equantum-finance-review.
Evidencia local: /home/equantumg/equantum-finance-validacion.txt.

- Tests del helper financiero: 9/9 PASS.
- TypeScript completo: npx --no-install tsc --noEmit, PASS.
- Build Next.js 15.5.27: PASS; 11/11 páginas estáticas.
- QA SQL en equantum_restore_clean, contenedor equantum-staging: PASS=23 FAIL=0 TOTAL=23.
- git diff --check: PASS.

La vista presenta vendido, facturado, cobrado, pendiente de facturar y pendiente de cobro por moneda. Consultas paginadas; pendiente de facturar por Sale, sin compensar saldos entre ventas. Los tests del helper reproducen DOC12 FIN001 y cifras PYG FIN008, con separación de moneda FIN003.

Alcance: cálculo de presentación y regresión SQL local. No demuestra todavía el recorrido E2E DB→API→UI del Golden ni cierra los ACC completos. Tratamiento fiscal, comisiones/versionado, default y cambio de moneda autorizado, servicio Auth/Storage remoto y gates restantes conservan sus pendientes.

Integración limitada a relanzamiento-2026. Main y producción no se modifican. Sin servicios pagos.

## Checkpoint 07 — Contrato fiscal del cierre y base de comisión

Ejecución: 2026-10-07 America/Asuncion (2026-10-08 UTC).
Candidato: 4dac30007e59d2885ea7208ff618ed3aaef4b839.
Evidencia local: /home/equantumg/equantum-fiscal-validacion.txt.

- git diff --check: PASS.
- Regresión SQL en equantum_restore_clean / equantum-staging: PASS=24 FAIL=0 TOTAL=24.
- financial_fiscal_snapshot_v3.sql: PASS. Prueba el cierre real para PYG gravada, USD gravada y USD sin impuesto explícito; la moneda no decide el impuesto.
- Base de comisión sin IVA: 10000000 para venta con impuesto 1000000, dentro del fixture probado.
- Cambio posterior de Proposal/Items y retry WON no alteran el snapshot fiscal de Sale/Items.
- La prueba termina con ROLLBACK y verifica ausencia de fixtures residuales.

Límite: PostgreSQL local como postgres; no certifica permisos administrativos ni clasificación fiscal legal. FIN005 sigue pendiente de políticas y clasificación gobernada. FIN006 conserva la base probada pero falta calcular/persistir la comisión. FIN007 sigue pendiente de porcentaje y versión histórica de política. No se aplica tasa global del 5% ni se configura fiscalidad productiva.

Integración solamente a relanzamiento-2026; main y producción no se modifican.
