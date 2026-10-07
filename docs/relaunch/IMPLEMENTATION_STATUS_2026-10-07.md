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
| ACC-MIG-001 | PARTIAL |
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
| Restore de ensayo | PARTIAL | Datos de negocio restaurados; 3 errores supabase_vault |
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
| Sale separada de Invoice | PENDING | Documento 19 vigente |
| Invoice separada de Payment | PENDING | Documento 19 vigente |
| Caja / movimientos | PENDING | Documento 19 vigente |
| Multimoneda gobernada | PENDING | No sumar monedas sin conversión |
| Tratamiento fiscal | PENDING | Falta implementación |
| Comisión excluye IVA | PENDING | Falta implementación |
| Historial de política de comisión | PENDING | Falta implementación |
| Golden financiero exacto | PENDING | Falta ejecución |

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
| financial_info API | PENDING | Falta negative test |
| financial_info IA | PENDING | Falta negative test |
| Storage privado | PARTIAL | Endurecido; falta cobertura final |
| Master protegido | PASS | Cuenta master preservada |

---

## 8. Triage

| Control | Estado | Evidencia |
|---|---|---|
| UI Triage existente | PASS | Dashboard actual |
| Regla de prioridad backend | PENDING | Actualmente parte del cálculo está en React |
| Score reproducible backend | PENDING | Falta implementación |
| Razones de priorización backend | PENDING | Falta implementación |
| Golden Triage | PENDING | Falta test |

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
| Vercel Preview commit 5d6661f | PENDING |
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

