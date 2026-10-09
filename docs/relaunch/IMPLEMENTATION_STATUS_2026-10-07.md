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

- PASS: implementación con evidencia suficiente dentro del alcance indicado.
- PARTIAL: implementación probada localmente; falta validación integral o externa.
- BLOCKED: depende de staging real, infraestructura administrada o aprobación externa.
- PENDING: implementación o validación requerida aún no realizada.

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
| Tratamiento fiscal | PASS | Backend local: políticas/versiones explícitas, aprobación Master y snapshot; UI/E2E y configuración operativa pendientes |
| Comisión excluye IVA | PASS | Backend PostgreSQL local: base 10M, IVA 1M, tasa 5%, comisión 500000; commission_policy_snapshot_v3 |
| Historial de política de comisión | PASS | Backend PostgreSQL local: snapshot de versión/tasa, cambio 5% a 7% conserva venta anterior; UI/E2E pendientes |
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
| Storage privado | PARTIAL | PostgreSQL local A/B PASS documentado; script de Auth/Storage real preparado, aún no ejecutado en staging |
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

## Checkpoint 08 — Comisión versionada y ensayo desde restore

Ejecución: 2026-10-07 America/Asuncion (2026-10-08 UTC).
Migración generada con Supabase CLI 2.81.3: 20261008021415_commission_policies_v3.sql.
Candidato ensayado: 05bfe2365c3e091c68a678b5758e15e7841a08b9.

Evidencia inicial: /home/equantumg/equantum-commission-validacion.txt; equantum_restore_clean, QA=25/25.
Evidencia de restore nuevo: /home/equantumg/equantum-commission-rehearsal.txt; equantum_commission_rehearsal, mismo contenedor equantum-staging.

- Restore del baseline con Vault explícitamente excluido, no-owner/no-privileges y transacción única: aprobado.
- Baseline 11 tablas reconciliado.
- Runner ordenado: ATTEMPTED=20 PASS=20 FAIL=0 TOTAL=20.
- SQL QA: 25/25 aprobado desde el restore nuevo.
- Master autenticado crea versiones explícitas; actor restringido no lee ni crea políticas.
- Base sin IVA 10000000, IVA 1000000: 5%=500000; versión 7%=700000.
- Retry y cambio posterior de Proposal conservan el snapshot histórico.
- Edición de política/snapshot/inputs históricos bloqueada.
- Sin política elegida, tasa/importe NULL, sin porcentaje global ni backfill ficticio.
- Fixtures y grants de prueba revertidos mediante ROLLBACK.
- Sintaxis Python del instalador y bash -n/diff --check inicial: sin errores.

Alcance: backend y RLS PostgreSQL local. No se aplicaron políticas de negocio productivas ni se modificó main/producción. UI para crear/elegir políticas, E2E, revisión final de seguridad/advisors y configuración operativa/fiscal permanecen pendientes. No certifica todos los criterios ni rollback final de release.

## Checkpoint 09 — Política fiscal gobernada

Ejecución: 2026-10-07 America/Asuncion (2026-10-08 UTC).
Candidato: 6500d81691e247072fe38bce3ab83ea5232ec5fc.
Migración generada por CLI: 20261008024203_fiscal_policy_governance_v3.sql.
Evidencia local: /home/equantumg/equantum-fiscal-governance-validacion.txt.

- Restore nuevo equantum_fiscal_rehearsal desde staging-baseline.dump, con lista validada y Vault excluido explícitamente; baseline 11 tablas reconciliado.
- Runner: ATTEMPTED=21 PASS=21 FAIL=0 TOTAL=21.
- SQL QA completo desde restore: 26/26 PASS.
- Después del ensayo aprobado, migración aplicada también a equantum_restore_clean y nuevo test fiscal aprobado allí.
- Master autenticado crea políticas/aprueba por Item con motivo y referencia de evidencia; cálculo backend actualiza Item y totales de Proposal.
- PYG/USD gravadas y USD export_zero/exempt verificadas con fixtures explícitos. La moneda no decide impuesto.
- Versión/tasa/aprobador/hora/evidencia guardados en Sale Items. Nuevas decisiones no recalculan ventas históricas.
- Política inválida, motivo vacío, cambio de base sin aprobación compatible y edición de histórico rechazados. Usuario restringido no lee/aprueba.
- Nuevas tablas RLS y funciones SECURITY INVOKER comprobadas por test.
- Fixtures y grants de prueba revertidos mediante ROLLBACK; cero residuos.
- Python/bash syntax y git diff --check del candidato: sin errores.

Alcance: backend y RLS PostgreSQL local, con fixtures de ingeniería. Las referencias almacenadas no certifican validez legal; no se precargaron tasas productivas, no se usó IA para clasificación y no se inventaron aprobaciones de datos legacy. UI/E2E, aprobación/configuración operativa real, revisión final de seguridad/advisors y rollback de release siguen pendientes.

Se integra únicamente a relanzamiento-2026. Main y producción sin cambios.

## Políticas financieras — interfaz y regresión local

Candidato validado: 931115b. Fecha UTC: 2026-10-08.

Se incorporó el panel de versiones fiscales, versiones de comisión y aprobación
fiscal de partidas existentes desde Finanzas para la cuenta maestra activa.
La aprobación usa approve_proposal_item_fiscal_v3 y el cálculo de PostgreSQL.
Este cambio no agrega migraciones ni permisos.

Evidencia local entregada: pruebas financieras 9/9; TypeScript y build PASS;
11/11 páginas estáticas; QA SQL PASS=26 FAIL=0 TOTAL=26 en
equantum_restore_clean. git diff --check sin errores.
Log: /home/equantumg/equantum-policies-ui-validacion.txt.

El recorrido visual y las operaciones Data API con sesión real no están
validados todavía. La asignación de comisión a propuestas, la configuración
fiscal operativa aprobada y los flujos comerciales completos siguen pendientes.
No se cierra automáticamente ningún criterio ACC/IT/INT con esta evidencia.
Main y producción no se modificaron.

## Circuito comercial-financiero — validacion local agrupada

Fecha UTC: 2026-10-08. Candidato validado: 620999c.
Migracion CLI: 20261008031852_commercial_flow_v3.sql.

Pantallas para propuesta con fiscalidad/comision, cierre a venta, factura y
cobro; resumen recargado despues de operar. Escrituras para Master activo
con financial_info; lector financiero conserva consulta sin escritura.

Restore baseline reconciliado; runner 22/22; regresion SQL 28/28 en
equantum_flow_rehearsal; circuito PYG/USD con el mismo rol authenticated Master;
reintentos sin duplicados; Golden PYG 14M/10M/7M/4M/3M; comision cerrada
protegida; fixtures revertidos. Tres pruebas de circuito/comision tambien
pasaron en equantum_restore_clean.

Node 9/9; TypeScript y build PASS (11/11 paginas estaticas); git diff --check
y bash -n sin errores.
Log: /home/equantumg/equantum-commercial-flow-validacion.txt.

Auth remoto, Data API con sesion real, recorrido visual, advisors y revision de
APIs legadas siguen pendientes, junto con configuracion fiscal operativa,
versiones posteriores, Quick Sale sin oportunidad y conversion multimoneda.
No se cierran automaticamente ACC/IT/INT. Main y produccion sin cambios.

---

## CHECKPOINT 04D — VALIDACIÓN INTEGRAL LOCAL

**Resultado:** PASS dentro del alcance técnico local automatizado.

### Estado validado

- Branch: `relanzamiento-2026`
- Base validada desde restore limpio: `equantum_restore_clean`
- Migraciones incluidas en runner: **22**
- Tests SQL versionados ejecutados: **28**
- Resultado QA SQL: **28 PASS / 0 FAIL**
- Build Next.js: **PASS**
- TypeScript: **PASS**
- Lint: **PASS**
- Generación de páginas: **11/11**
- Storage Portal isolation V3: **PASS**
- Working tree al inicio de la validación: limpio.

### Cobertura técnica incluida

La suite validó, entre otros:

- servicios, proyectos y tareas;
- catálogo y pipeline;
- flujo comercial-financiero;
- asignación y snapshot de comisiones;
- frontera financiera para IA;
- snapshot fiscal;
- idempotencia financiera;
- operaciones financieras;
- RLS financiero;
- gobernanza fiscal;
- golden commercial;
- golden financial;
- golden radar;
- golden triage;
- identidad comercial;
- reconciliación;
- seguridad/RLS;
- permiso financiero sensible;
- aislamiento Storage/Portal;
- permisos e historial de tareas;
- integración tareas/triage;
- múltiples tareas por ticket.

### Build

`npm run build` completó correctamente con Next.js 15.5.27:

- compilación: PASS;
- lint/typecheck: PASS;
- páginas estáticas: 11/11;
- `/api/ai/assistant`: compilada;
- `/dashboard`: compilada;
- `/portal`: compilada;
- `/portal/login`: compilada.

### Alcance de este PASS

Este checkpoint demuestra que el estado actual versionado supera la
suite técnica local automatizada sobre el restore utilizado y que la
aplicación compila correctamente.

NO equivale a:

- 361/361 criterios formales ejecutados;
- 40/40 casos de integración formal ejecutados;
- validación E2E completa con usuarios reales en staging remoto;
- certificación de producción;
- autorización para modificar `main`;
- autorización para desplegar a producción.

Producción y `main` permanecen fuera de este checkpoint.



## Cierre final del relanzamiento — 2026-10-08

**Candidato revisado:** `relanzamiento-2026` en `4674502`  
**Conclusión:** listo para entrar a validación final; **no autorizado para producción**.

Este cierre reutiliza la evidencia del CHECKPOINT 04D, registrada para el estado versionado actual: 22/22 migraciones, 28/28 pruebas SQL, TypeScript y build Next.js PASS, 11/11 páginas estáticas, además de Node 9/9 para el circuito financiero. No se repitió la regresión: las pruebas cubren el mismo candidato y el cambio de cierre es documental. El estado Vercel de este commit informa que la publicación terminó; eso no prueba los recorridos E2E ni los servicios Supabase administrados.

### Conclusión operativa

1. **Funciona hoy:** flujos comerciales y financieros implementados en el alcance V2/V3 probado; tareas, tickets, Radar y Triage; control financiero antes de IA; RLS PostgreSQL local, incluidos los adjuntos Portal A/B; snapshots fiscales y de comisión. Las funciones marcadas PASS conservan el alcance local descrito en sus evidencias.
2. **Probado:** restore y reconciliación del baseline; 22 migraciones ordenadas; suite SQL 28/28; tests Node 9/9; TypeScript/build; pruebas locales de RLS, seguridad financiera y flujos PYG/USD.
3. **Falta realmente:** ejecutar/revisar formalmente los 361 criterios ACC y los 40 casos IT/INT; completar los E2E visuales y de sesión real; hacer el ensayo final de rollback del candidato; resolver configuraciones operativas fiscales/multimoneda que requieran decisiones de negocio. Los módulos Chat/eQ/DOTS y BI/ULi siguen PENDING en el alcance documentado; si pertenecen a este release, deben implementarse y validarse antes de aprobarlo.
4. **No bloquea por sí solo:** la consulta histórica que devolvió cero políticas Storage. En el restore limpio actual la política existe y el test A/B local pasa. Tampoco bloquean repetir el build o la suite local ya aprobados para este mismo candidato.
5. **Sí bloquea producción:** falta de aprobación de ACC/IT/INT críticos, E2E final, rollback aprobado, configuración de negocio que afecte el alcance financiero, revisión de los controles administrados de Supabase y autorización explícita. La matriz formal sin ejecutar impide afirmar que el release satisface todos sus criterios.
6. **Debe probarse en staging real:** Auth y Data API con sesiones reales; upload/download de Storage para A/B y usuario interno según la política; flujos visuales de Portal y Comercial/Finanzas; advisors y APIs legadas aplicables; migración y rollback del candidato en staging. No se sustituye esta evidencia con PostgreSQL local.
7. **Listo para validación final:** sí. **Listo para producción:** no.

### Matriz formal de aceptación

- 361 criterios ACC: **PENDING** — la matriz de trabajo los registra sin ejecución formal. Esto no demuestra por sí solo que falte implementación en cada criterio.
- 40 casos IT/INT: **PENDING** — falta ejecución y aprobación formal.
- Los controles con dependencia de Supabase administrado quedan **BLOCKED** hasta disponer de staging real.
- Producción queda **BLOCKED** hasta cerrar los gates anteriores y obtener autorización explícita.

La matriz resumida por gate y evidencia está en `docs/relaunch/FINAL_EVIDENCE_MATRIX_2026-10-08.md`.  
`main` y producción permanecen intactos. No se agregaron funcionalidades ni se modificaron datos reales.


## Checkpoint 10 — Mapa definitivo de validación y bloqueantes

Fecha: 2026-10-08. Clasificación documental fila por fila; no se repitieron pruebas locales.

- Alcance inventariado: DOC12–DOC19 + 40 IT/INT; 401 filas. Sin exclusiones aprobadas, NO APLICA=0.
- ACC 361: 39 cubiertos/listos para ejecutar, 48 requieren staging, 274 dependen de función pendiente.
- IT/INT 40: 5 cubiertos/listos, 1 requiere staging, 34 dependen de función pendiente.
- Conteo combinado: 44 / 49 / 308 / 0, en ese orden. Las 401 filas conservan NO EJECUTADO; CUBIERTO no significa PASS.
- ACC con severidad BLOQUEANTE: 131; 23 listos aún sin ejecución formal, 22 requieren staging, 86 dependen de función pendiente.
- La matriz cruza los tests existentes por comportamiento probado; cada fila identifica el archivo y limita expresamente el alcance cuando el test no prueba el criterio completo.
- No se reasignó severidad a IT/INT porque la matriz fuente no tiene campo individual de criticidad.
- Conclusión: listo para organizar/ejecutar validación final; producción bloqueada hasta aprobar los ACC críticos, los IT/INT críticos y los gates externos.

Detalle: docs/relaunch/FINAL_EVIDENCE_MATRIX_2026-10-08.md y docs/relaunch/acceptance/FINAL_CLASIFICACION_ACC_IT_INT_2026-10-08.csv.


## Checkpoint 04E — Preparación de validación Supabase Storage real

La rama actual incluye una prueba reproducible para ejecutar el flujo con
sesiones existentes de Portal A, Portal B y personal interno autorizado:

`npm run test:storage:staging`

La prueba usa únicamente la clave pública/anon y contraseñas tomadas de
variables de entorno. No crea cuentas, no usa service_role, carga objetos
con prefijo QA bajo el UID autenticado y los elimina al finalizar. Nunca
imprime credenciales ni URLs firmadas.

### Criterios rectores asociados

- DOC12 / ACC-SEC-008: archivo de Cliente A solicitado por usuario de B;
  acceso denegado y URL privada no utilizable.
- DOC12 / ACC-DATA-001: Storage privado y RLS/autorización impiden acceso
  fuera del alcance.

La prueba remota cubre acceso autenticado por ruta, generación de URL firmada
por el solicitante, acceso anon, privacidad del bucket y cuenta interna
autorizada. No trata una URL firmada emitida para A como si quedara ligada a
la identidad de A: una URL firmada funciona como credencial bearer mientras
está vigente. Si ACC-SEC-008 exige que B no pueda usar una URL de A que le fue
entregada deliberadamente, ese requisito requiere validación/decisión de
arquitectura; no se declara probado por el test.

### Estado

- PostgreSQL local A/B: PASS según la evidencia existente del Checkpoint 04D;
  esta sesión no tuvo acceso al contenedor para repetir la prueba.
- Test Auth/Storage contra Supabase administrado: BLOCKED EXTERNAL VALIDATION;
  faltan staging Supabase y cuentas de prueba autorizadas en este entorno.
- Acceso interno: el script requiere una cuenta interna habilitada y valida
  que la política actual permita el acceso temporal previsto por el contrato.
  La autorización más granular por rol debe permanecer alineada con la matriz
  de permisos y no se infiere de una sesión exitosa aislada.
- Producción y main: sin cambios.


## Checkpoint M00 — Inventario inicial de visión y cobertura 00–19 — 2026-10-08

**Referencia remota verificada:** rama `relanzamiento-2026`, HEAD `2c0f3cd64e3b61b96a5e934c105d670474c90b7c`.  
**`main` observado sin cambios:** `c2b41570a5600a585c76ac77d798927e07549832`.  
**Fuentes:** ZIP rector adjunto con los 20 documentos 00–19; árbol GitHub de 112 archivos; este estado de implementación y la matriz de aceptación existente.

### Alcance de esta pasada

Se leyó completo el Documento 00 y, como fundamentos transversales, los Documentos 01, 02, 11 y 12. El ZIP contiene los 20 documentos. Los documentos de cada módulo restante se leerán en su checkpoint antes de implementar ese módulo; este inventario inicial usa el estado versionado y el árbol actual, y no equivale a una auditoría funcional completa de cada módulo.

### Resultado del módulo 00

El Documento 00 es el contrato transversal de producto, no una pantalla ni un servicio independiente. Define como principios: datos reales y fuente de verdad, seguridad y privacidad por alcance, decisión humana, trazabilidad, explicabilidad, continuidad, experiencia simple, adopción, intervención mínima y evolución incremental; IA no sustituye permisos ni decisiones humanas.

**Estado del documento rector: IMPLEMENTADO / DEFINITIVO.**  
**Conformidad del sistema completo: PARCIAL.** Hay evidencia local de varias capacidades operativas descritas por el 00, pero el estado del repositorio deja módulos como BI, Chat V2, DOTS, orquestación, memoria, gobernanza, evaluación y observabilidad pendientes; además, la ejecución formal de criterios y casos de integración sigue abierta.

No se agregó una función independiente para M00: hacerlo duplicaría responsabilidades de sus módulos propietarios. La acción correcta de este módulo es mantener sus principios como criterios de lectura para los módulos 01–19 y registrar brechas, sin declarar que el sistema completo ya los cumple.

### Matriz inicial de cobertura

La matriz por módulo está en `docs/relaunch/MODULE_COVERAGE_00_19_2026-10-08.md`. Sus estados son de inventario inicial. `PARCIAL` significa que hay una capacidad o evidencia relacionada y que quedan brechas; `FALTANTE` sigue el estado PENDING explícito del resumen vigente. Ninguna fila representa aceptación formal PASS. Las pruebas locales no sustituyen staging ni E2E.

### Pruebas y límites

- Verificación de fuentes: ZIP con 20 documentos DOCX; branch y HEAD consultados en GitHub; árbol remoto sin truncamiento (112 archivos).
- Se consultaron los registros de aceptación existentes para distinguir criterios definidos de criterios ejecutados; el registro actual conserva `NO EJECUTADO` en las filas formales.
- No hubo cambios de código, esquema, datos ni permisos. No aplica build ni regresión ejecutable a este checkpoint documental.
- Este entorno no ofrece un checkout local; por eso no se afirma `git status` local ni se repiten comandos de build/SQL.

### Clasificación del checkpoint M00

**PARCIAL — documento rector consolidado; conformidad global pendiente de la validación de módulos propietarios y de aceptación formal.** No se avanza automáticamente a otro módulo.


## Checkpoint M01 — Auditoría de Arquitectura y Seguridad — 2026-10-08

**HEAD remoto de entrada:** `deac6bb0149bb008a523e085ae36505b20379849`; **main observado:** `c2b41570a5600a585c76ac77d798927e07549832`, sin modificación.  
**M00:** permanece **PARCIAL**.

Se leyó completo el Documento 01 (v1.2; 89 secciones) del ZIP rector y se
cotejó con 00, 02, 11 y 12. También se revisaron la matriz de cobertura,
el estado oficial, la clasificación de aceptación, el árbol remoto, el
middleware, clientes Supabase, login/MFA, Portal, migraciones, tests y
workflow de backup.

### Resultado

- **Implementado:** stack Next.js 15/TypeScript, Supabase Auth/PostgreSQL,
  Vercel/GitHub; cliente SSR y navegador con clave publicable; middleware
  con perfil/estado/cambio de contraseña; MFA AAL2 exigida a Master;
  cabeceras de seguridad; RLS y pruebas locales.
- **Evidencia local histórica reutilizada:** 22/22 migraciones, 28/28 SQL,
  Node 9/9, TypeScript/build PASS y 11/11 páginas estáticas, según
  CHECKPOINT 04D. No se repitieron en esta sesión.
- **Brechas de implementación:** no se identificó flujo versionado de doble
  control Master, expiración de capacidad Master tras 15 minutos inactivo,
  audit log central e íntegro, step-up general, MFA obligatorio para otras
  cuentas sensibles ni lista/cierre remoto de sesiones. Historial de Tasks
  y Tickets no equivale al audit log central de DOC01.
- **Brechas de ambiente/operación:** restore probado sobre PostgreSQL local;
  no incluye Auth/Storage/Vault administrados. No se ejecutó Auth/Data API/
  Storage con sesiones reales de staging, rollback final ni operación RPO/RTO.
- **Otras capacidades transversales pendientes:** gobernanza/revocación de
  integraciones, salud/alertas técnicas y controles generales de jobs no
  están demostrados por los artefactos y pruebas revisados.
- No se cambió código ni RLS: esos cambios de autorización y privilegio
  requieren pruebas locales y staging que esta sesión no puede ejecutar.

### Criterios formales existentes relacionados

No se encontró un set separado de ACC propio de DOC01. Se conservaron IDs
del registro DOC12; todos los citados permanecen formalmente `NO EJECUTADO`.

| Criterio | Clasificación oficial | Evidencia relacionada y límite |
|---|---|---|
| ACC-SEC-001 | STAGING / bloqueante | Tests SQL de RLS existentes; falta matriz API/RPC con sesión real. |
| ACC-SEC-002 | STAGING / bloqueante | Tests de permisos/RLS; falta prueba completa de manipulación frontend/API en staging. |
| ACC-SEC-003 | STAGING / bloqueante | SQL y HTTP local del handler; no completa todas las APIs/sesiones reales. |
| ACC-SEC-004 | STAGING / no bloqueante | Evidencia local de acceso financiero por alcance; falta ejecución formal en staging. |
| ACC-SEC-005 | STAGING / bloqueante | Tests de permisos; falta comprobar todos los recursos y roles en staging. |
| ACC-SEC-006 | STAGING / bloqueante | Portal/RLS local; falta cambio de membresía con sesión real y no mezcla entre empresas. |
| ACC-SEC-007 | STAGING / bloqueante | Políticas de Tickets; falta E2E que demuestre ausencia de notas internas en API/payload. |
| ACC-SEC-008 | STAGING / bloqueante | Storage A/B PostgreSQL local; falta servicio Auth/Storage administrado y URL firmada. |
| ACC-SEC-009 | STAGING / bloqueante | No hay evidencia suficiente de audit log de acciones Master; función pendiente. |
| ACC-SEC-010 | STAGING / bloqueante | Boundary de IA local; no certifica todo el filtrado por permisos. |
| ACC-DATA-001 | STAGING / bloqueante | Storage privado A/B local; falta flujo Auth/Storage administrado. |
| ACC-DATA-003 | BLOQUEADO POR FUNCIÓN PENDIENTE / bloqueante | Falta audit log de cambios sensibles. |
| ACC-MIG-001, ACC-MIG-006 | STAGING / bloqueantes | Restore/reconciliación local no cierra ensayo ni rollback administrado. |

Las clasificaciones son las del archivo rector; relacionar un test por
comportamiento no cambia `NO EJECUTADO` a PASS.

### Pruebas de esta sesión y límites

- Inspección del documento rector y artefactos remotos: completada.
- GitHub status del HEAD de entrada: Vercel `success`; no es E2E ni aprobación.
- Regresión SQL: **NOT EXECUTED** en esta sesión.
- `npm run build`: **NOT EXECUTED** en esta sesión.
- Motivo: repositorio no está montado como checkout local; `git clone` no
  pudo conectarse al proxy de red; no hay acceso al contenedor local.
- Código, esquema, permisos, datos, producción y `main`: sin cambios.

### Estado final

**M01 = PARTIAL.** Arquitectura base y capas existentes están presentes,
con evidencia local previa. Doble control/expiración Master, auditoría
central, MFA por riesgo, sesiones remotas y aceptación en staging quedan
pendientes. **M00 = PARTIAL.** No se inicia M02.

## Auditoría funcional y plan de cierre de visión 00–19 — 2026-10-08

Se añadió una auditoría funcional trazable de los documentos rectores y un
plan de cierre por dependencias. El alcance fue documental y de inspección;
no se añadieron funciones ni se alteraron permisos, datos o servicios.

### Fuentes y trazabilidad

- Se cotejaron los SHA-256 de los 20 DOCX rectores contra el inventario
  versionado: 20/20 coinciden.
- El registro formal mantiene 401 IDs/casos únicos (361 ACC + 24 IT +
  16 INT), todos con ejecución formal `NO EJECUTADO` en el origen.
- La clasificación del registro: 44 CUBIERTO/LISTO PARA EJECUTAR, 49
  STAGING, 308 BLOQUEADO POR FUNCIÓN PENDIENTE, 0 NO APLICA aprobado.
- Los documentos 00–11 no aportan IDs de aceptación propios en el
  inventario; sus reglas deben enlazarse a criterios existentes o a
  criterios complementarios aprobados. No se inventaron IDs ACC ni se
  redujo alcance.

### Validación de esta sesión

- `node --test scripts/relaunch/finance-summary.test.cjs`: PASS, 1 suite.
- `npx --no-install tsc --noEmit`: PASS.
- `npm run build`: PASS, Next.js build y 11/11 páginas estáticas. Esta
  verificación es de compilación, sin conexión a Supabase.
- Regresión SQL: NO EJECUTADA en esta sesión; PostgreSQL local no respondía,
  Docker no estaba disponible y el dump de baseline no estaba presente en
  el runtime actual. Los 28/28 que constan en Checkpoint 04D son evidencia
  histórica registrada y no se reportan como ejecución actual.
- No se ejecutaron Auth/Storage administrados, navegador E2E, staging ni
  producción. No se tocaron `main`, producción, datos, esquema o permisos.

### Entregables documentales

- Auditoría funcional y límites por documento:
  `docs/relaunch/FUNCTIONAL_AUDIT_00_19_2026-10-08.md`.
- Plan de cierre, camino crítico, paralelismo, entregas, recursos y rangos:
  `docs/relaunch/RELEASE_CLOSURE_PLAN_00_19_2026-10-08.md`.
- Matriz de trazabilidad de 401 criterios/casos:
  `docs/relaunch/acceptance/REQUIREMENTS_TRACEABILITY_00_19_2026-10-08.csv`.
- Índice de 20 documentos, versión, hash y secciones principales:
  `docs/relaunch/acceptance/SOURCE_SECTION_COVERAGE_00_19_2026-10-08.csv`.

### Decisión

El núcleo operativo, comercial y financiero existente se conserva; la
visión integral aún no está completa. BI 07, Chat V2 10 y DOTS/IA 13–18
requieren implementación; M19 tiene una base financiera/comercial, pero el
Centro Ejecutivo/ULi sigue parcial. La fase 0 y una parte determinística de
la fase 1 de DOC19 pueden avanzar con contratos y fixtures sintéticos en
paralelo, con ratios, acciones y cifras reales deshabilitados hasta cerrar
sus fuentes, permisos y reconciliación.

El plan es una propuesta de secuencia, no autorización de implementación,
exclusión ni producción. M00 y los módulos incompletos permanecen parciales;
la ejecución formal de aceptación sigue pendiente.

## FASE 1 — M03 Tareas / M04 Triage / M05 Radar — avance funcional

Fecha: 2026-10-08. Rama: `relanzamiento-2026`.

### Cambios implementados en el checkout

- La creación de tareas se redujo a captura inicial breve; responsable,
  objetivo interno y compromiso externo se muestran por separado.
- La transición de estado se mueve a una operación SQL transaccional. Solo
  acepta los seis estados rectores, valida las transiciones, exige motivo al
  cancelar/reabrir, contexto y revisión/condición al esperar, y causa al
  bloquear. Conserva el cambio en `task_status_history`.
- Entrar en ESPERANDO crea o actualiza un único `followup` pendiente en la
  misma transacción; el trigger conserva la condición en Radar y reutiliza
  un asunto activo equivalente. No se convierte una espera en bloqueo por
  el paso del tiempo.
- La interfaz muestra causas registradas por Triage, espera/bloqueo, objetivo
  interno/compromiso externo, y filtros por estado. La reasignación queda
  condicionada a permisos existentes; la eliminación sigue reservada a
  quienes ya tienen `delete_tasks` y requiere confirmación.
- Radar diferencia revisión vencida, continuidad sin protección suficiente,
  seguimiento programado y cierre; confirmar el cierre requiere confirmación
  explícita. La prioridad permanece en Triage.

Archivos principales:
`app/dashboard/page.tsx`,
`lib/operations/task-triage-radar.ts`,
`supabase/migrations/20261008120000_tasks_radar_workflow_v3.sql`,
`supabase/tests/tasks_radar_workflow_v3.sql`,
`scripts/relaunch/task-triage-radar.test.cjs`,
`scripts/relaunch/migrate-v2-order.sh` y `package.json`.

### Verificación de esta ejecución

- Prueba Node de reglas de estado, presentación de categorías humanas,
  salud de Radar y contexto requerido: **4/4 PASS**.
- Suite Node `npm run test:operations`: **PASS**; reglas operativas 4/4 y
  suite financiera 1/1.
- TypeScript `npx --no-install tsc --noEmit`: **PASS** en el checkout final
  de esta ejecución.
- `npm run build`: compila y valida TypeScript, pero falla durante la
  generación estática con `Next.js build worker exited with code: 1` sin
  diagnóstico del worker. Se reprodujo el mismo fallo en un worktree limpio
  del commit base `5e07f36`; por tanto, el fallo no se atribuye a estos
  cambios y el build final queda **BLOCKED por el worker/runtime actual**.
- PostgreSQL/`psql` y el contenedor local no están disponibles en esta
  sesión. La migración, `tasks_radar_workflow_v3.sql` y la regresión SQL
  completa quedan **NO EJECUTADAS** aquí. Los 28/28 anteriores son evidencia
  histórica, no resultado de esta ejecución.
- La prueba SQL usa ahora `SET LOCAL ROLE authenticated` para ejercer el RPC
  y el RLS de la tarea fixture, conserva compatibilidad con el estado legado
  `waiting_client`, y revierte tanto grants mínimos de Auth como fixtures con
  `ROLLBACK`; su ejecución sigue pendiente por falta de PostgreSQL.
- No se ejecutó E2E autenticado en Supabase administrado ni Vercel.

### Estado de criterios y brechas

- `ACC-TASK-002`, `003` y `004`: hay implementación y prueba SQL
  versionada para ejecutar; aceptación formal **NO EJECUTADA** hasta aplicar
  y probar la migración en PostgreSQL local.
- `ACC-TASK-001`, `005`, `006` y `007`: conservan su evidencia anterior;
  no se reejecutaron en esta sesión. `ACC-TASK-008` sigue sin bloqueo de
  cierre de Proyecto en la interfaz/operación integral.
- Triage conserva el motor determinístico existente y ahora muestra sus
  razones en la vista. Agrupación de situaciones, conteo sin doble conteo,
  overrides auditables y señales amplias de Ticket/Proyecto permanecen
  pendientes; no se inventó una fórmula nueva.
- Radar mejora el ciclo temporal de tarea en espera. Notificaciones,
  escalamiento, revisión/eventos ejecutados sin navegador, cobertura de
  ausencias, zombies, capacidad y seguimiento de Tickets siguen pendientes.
- `ACC-TRI-001`, `002`, `004`, `006` y `ACC-RAD-003–006` no se declaran
  aceptados. `ACC-TRI-003`, `ACC-TRI-005` y `ACC-RAD-007` requieren volver a
  ejecutar sus pruebas pertinentes en un entorno con PostgreSQL; los
  controles existentes no se cambiaron intencionalmente.

### Resultado de fase

**FASE 1 = PARCIAL.** Se implementó un recorrido real y transaccional para
espera/bloqueo/reapertura y su enlace con Radar, además de mejoras de
explicabilidad y presentación. La migración aún necesita regresión SQL
ejecutada, y siguen abiertas capacidades rectoras de situaciones Triage,
Proyecto, notificación y seguimiento avanzado Radar. No se hizo commit,
push, merge ni despliegue en este avance.

### Revalidación del entorno y evidencia — 2026-10-08

Esta revalidación corresponde al checkout local `relanzamiento-2026`, HEAD
`5e07f36ea5e2b8c6218c64e59a4e74c4a76bccd4`. El árbol de trabajo ya contenía
cambios de Fase 1; se conservaron sin reset ni descarte.

- `npm run test:operations`: PASS (reglas Tareas/Triage/Radar 4/4 y resumen
  financiero Node 1/1).
- `npx --no-install tsc --noEmit`: PASS.
- `bash -n scripts/relaunch/migrate-v2-order.sh scripts/relaunch/qa-sql.sh`
  y `git diff --check`: PASS.
- `npm run build` sin variables públicas de Supabase falla durante la
  generación de páginas estáticas. La inicialización directa del cliente
  `@supabase/ssr` sin URL/clave reproduce el error explícito de configuración
  requerida. Con valores públicos ficticios, efímeros y pasados solo al
  proceso de build, `npm run build` terminó PASS y generó 11/11 páginas.
  Ese build verifica compilación/prerender, no conectividad ni E2E de Supabase.
- PostgreSQL 17.11 nativo responde por TCP local. No se encontró dump/backup
  baseline en las ubicaciones accesibles y la base `equantum_restore_clean`
  no existe. No se creó un esquema sustituto. Por ello no se aplicó la
  migración nueva ni se ejecutó su SQL de aceptación o la regresión SQL.
- Los 28/28 SQL de la evidencia anterior son históricos. La migración
  `20261008120000_tasks_radar_workflow_v3.sql` y el test
  `tasks_radar_workflow_v3.sql` están versionados en el árbol local, pero su
  validez funcional no está demostrada por PostgreSQL en esta ejecución.
- La rama remota consultada anteriormente apuntaba a
  `02eabdc195e60f8c2c6133af942d193c9c1cbb19`, con el mismo árbol Git que este
  checkout; el commit local `5e07f36` tiene metadatos de commit distintos.
  En esta revalidación no fue posible refrescar la referencia por Git CLI
  debido al proxy `browser-proxy:8889`; no se hizo push ni se alteró historia.

**Resultado actualizado: FASE 1 = PARCIAL.** Node, TypeScript y el build con
configuración pública no conectada pasan. La validación integrada de
PostgreSQL está **BLOQUEADA por falta del dump baseline aprobado**, no por una
falla observada de la migración. No se declara aceptación formal, E2E
administrado ni publicación de esta funcionalidad como validada.

### P1 — decisiones aprobadas D1/D2/D4/D6 — ejecución actual 2026-10-08

Se implementó el contrato acordado: salir de ESPERANDO conserva el seguimiento
si no se verificó la dependencia; con evidencia, cierra solo esa continuidad y
Radar promueve otro compromiso pendiente o cierra cuando no queda obligación.
COMPLETADA no pasa a CANCELADA; ambas pueden reabrirse a POR HACER con motivo e
historial. El RPC comprueba asignación/permisos explícitos en base de datos,
bloquea cambios directos de estado —incluido el intento de falsificar sus GUC—,
usa bloqueo de fila y estado esperado para rechazar escrituras obsoletas sin
efectos parciales. Se conserva la fórmula de Triage existente.

Ejecución comprobada en este checkout:

- `npm run test:operations`: PASS, 4/4 pruebas operativas y 1/1 prueba de
  resumen financiero Node.
- `npx --no-install tsc --noEmit`: PASS.
- `npm run build` con valores públicos ficticios y efímeros bajo
  `NEXT_PUBLIC_SUPABASE_URL` y `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`: PASS,
  11/11 páginas generadas; no valida conectividad ni Auth/Supabase.
- `bash -n` de ambos runners y `git diff --check`: PASS.
- Los 59 escenarios P1 permanecen `PREPARADO — NO EJECUTADO`. La prueba SQL
  versionada cubre sus casos transaccionales, pero no pudo ejecutarse: no hay
  servidor PostgreSQL respondiendo en esta sesión ni baseline autorizado
  disponible. No se creó un esquema sustituto ni se aplicaron migraciones.
- No se ejecutó concurrencia real de dos sesiones ni E2E administrado; el
  control de estado esperado tiene prueba SQL pendiente. No hubo commit/push,
  merge ni despliegue.

M03–M05 siguen **PARCIALES** hasta ejecutar la migración y regresión SQL sobre
el baseline aprobado y cerrar las brechas restantes de Triage/Radar descritas
arriba.

### Revisión independiente de permisos, Radar y eliminación — 2026-10-08

Checkout local: rama `codex/p1-validation-review-20261008`, base commit
`676ae38ef286b3375a80076ce422ba6e4aba786c`. Contraste disponible: la matriz
versionada `docs/relanzamiento/MATRIZ_PERMISOS_V2.md` separa visibilidad por
alcance de cambios; la copia íntegra del Documento 02 no estuvo disponible en
esta sesión.

Hallazgos confirmados en el código:

- La migración P1 permitía que `view_all_tasks` o `view_area_tasks` por sí
  solos autorizaran `UPDATE` y transiciones. Ambos son permisos de lectura en
  la matriz; `reassign_tasks` es el permiso explícito de mutación.
- Radar devolvía solo `requires_review` al vencer un seguimiento, ocultando
  simultáneamente una continuidad sin responsable, acción o condición útil.
- La interfaz ejecutaba `DELETE` definitivo y advertía que se perdería el
  historial, que tiene borrado en cascada. La política de borrado también
  habilitaba el rol administrador sin exigir `delete_tasks`, contrario al
  mínimo privilegio documentado.

Correcciones preparadas en código y pruebas, sin ejecución SQL aún:

- La migración P1 limita cambios al responsable o a usuarios con permiso de
  mutación y alcance explícitos; el permiso delegado no permite editar el
  contenido de tareas ajenas.
- El estado combinado `requires_review_unprotected` conserva ambas señales y
  se cuenta en las dos métricas de Radar.
- `delete_tasks` archiva con motivo y auditoría; conserva Task e historial,
  rechaza borrado físico y no permite archivar mientras haya continuidad
  activa. La UI ya no llama a `DELETE`.
- Se agregó prueba SQL de lectura/escritura para `view_all_tasks` y
  `view_area_tasks`, y pruebas de archivo, historial, reintento y continuidad.

Verificación ejecutada en esta sesión:

- `npm run test:operations`: PASS, reglas operativas 4/4 y finanzas Node 1/1.
- `npx --no-install tsc --noEmit`: PASS.
- `npm run build` con URL/clave pública ficticias y efímeras: PASS, 11/11
  páginas; no prueba conectividad ni Auth.
- `git diff --check`: PASS.
- **SQL NO EJECUTADO:** `pg_isready -h 127.0.0.1 -p 5433` no obtuvo respuesta.
  No se aplicó la migración correctiva ni la suite SQL. Su ejecución requiere
  PostgreSQL local con el baseline autorizado y sanitizado.
- Sin commit ni push; no se tocó `main`, Supabase administrado o producción.

Resultado: revisión de código corregida, pero los cambios SQL y el archivo
auditable aún necesitan validación en PostgreSQL. P1 y M03–M05 permanecen
**PARCIALES**; el respaldo remoto de esta rama sigue pendiente.

### Seguimiento de permisos y trazabilidad — 2026-10-09

Se contrastó el cambio con el Documento 02 v1.2 incluido en
`DOCUMENTOS_RECTORES(4).zip`, especialmente §30, reglas de autorización de
Tareas, y con Documento 03 §§98–100. La regla rectora establece que ser creador
no conserva visibilidad si la persona deja de ser responsable/colaborador y no
tiene otro permiso de alcance. La política P1 previa todavía incluía
`created_by = auth.uid()`; se eliminó ese acceso implícito en la migración
correctiva y se añadió un caso negativo de lectura de Tarea e historial.

También se ampliaron los casos de `view_all_tasks` y `view_area_tasks` para
rechazar reasignación directa, además de transición, archivo y edición de
contenido. Las funciones `SECURITY DEFINER` introducidas en la migración de
archivo fijan ahora `search_path` vacío y califican explícitamente sus objetos.
Radar conserva simultáneamente vencimiento y falta de protección en el estado
combinado, sus dos contadores y la presentación de la fila.

Verificación de esta sesión en la rama local derivada
`codex/p1-hardening-20261009`:

- `npm run test:operations`: PASS, 4/4 pruebas de Tareas/Triage/Radar y 1/1
  prueba financiera Node.
- `npx --no-install tsc --noEmit`: PASS, ejecutado después del build para no
  competir por los tipos generados de `.next`.
- `npm run build` con URL y clave pública ficticias, efímeras y limitadas al
  proceso: PASS, 11/11 páginas. No valida conexión, Auth ni RLS remotos.
- `bash -n` para los runners SQL y `git diff --check`: PASS.
- SQL: NO EJECUTADO. En este runtime no están disponibles `psql`,
  `pg_isready`, Docker ni `$HOME/staging-baseline.dump`; por tanto no se aplicó
  la migración correctiva ni se ejecutó la regresión. El rechazo SQL de acceso
  permanente del creador queda implementado y versionado, pero aún sin
  verificación PostgreSQL.

El árbol local coincide con el árbol del respaldo P1 remoto
`5257b445faa862ab3a9c33da5658e9e6b23e6472` (`02a413a4…`). La rama de trabajo
local nueva parte del commit P1 `676ae38`; no hubo push, merge ni despliegue en
este seguimiento. Esta confirmación posterior reemplaza el estado histórico
“respaldo pendiente” registrado en la nota del 2026-10-08. P1 y M03–M05
continúan **PARCIALES** hasta validar la migración y sus pruebas en PostgreSQL
aislado con baseline autorizado.

### Automatización de validación de aplicación P1 — 2026-10-09

- Se añade un workflow de GitHub Actions para Pull Requests dirigidas a `relanzamiento-2026` (apertura, actualización o reapertura), solo desde ramas del mismo repositorio.
- Usa `ubuntu-latest`, Node 24 y `npm run validate:p1:app-local`, con permiso `contents: read`. No incluye despliegues, secretos de Supabase, SQL ni conexión a bases remotas.
- El resultado del runner de GitHub queda pendiente de la primera ejecución en la PR. Las pruebas locales previas no sustituyen esa ejecución ni la aceptación formal de P1.
- `package-lock.json` no está presente; npm instala las versiones permitidas por `package.json`, por lo que puede haber variación de dependencias entre ejecuciones.
