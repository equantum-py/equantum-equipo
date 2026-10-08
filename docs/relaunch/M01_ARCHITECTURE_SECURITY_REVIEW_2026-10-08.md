# M01 — Arquitectura y Seguridad: auditoría de cobertura

Fecha: 2026-10-08  
Documento rector: `01_ARQUITECTURA_Y_SEGURIDAD_FINAL.docx`, versión 1.2  
Rama y HEAD de entrada: `relanzamiento-2026` / `deac6bb0149bb008a523e085ae36505b20379849`  
`main` observado: `c2b41570a5600a585c76ac77d798927e07549832`  
Estado M01: **PARTIAL** · Estado M00: **PARTIAL**

## Fuentes examinadas

Documento 01 completo (89 secciones) extraído de
`DOCUMENTOS_RECTORES(4).zip`, fundamentos transversales 00, 02, 11 y 12,
estado oficial, matriz 00–19, matriz final de aceptación, árbol remoto y
fuentes actuales de middleware, Auth/MFA, Portal, Supabase, migraciones,
tests y workflow de backup.

No hay una lista separada de aceptación de DOC01. Se enlazan IDs oficiales
de DOC12; no se inventaron IDs.

## Matriz de cobertura de M01

| Requisito DOC01 | Estado | Evidencia / brecha |
|---|---|---|
| Stack vigente y modularidad | PARTIAL | Next.js 15/TS, Supabase/Postgres, Vercel y GitHub; no se propone reemplazo. |
| Defensa en capas y autorización server-side | PARTIAL | Auth/middleware/RLS presentes; falta prueba formal API/DB con sesiones administradas. |
| Identidad Portal separada | PARTIAL | `client_portal_users`, `is_internal_user()`, RLS de Portal/Storage y A/B local; E2E Auth/Data API/Storage pendiente. |
| MFA por riesgo | PARTIAL | AAL2 exigida a Master; no se exige a las demás cuentas sensibles de DOC01. |
| Dos personas para elevación Master | PENDING | No se identificó solicitud, segundo aprobador, aprobación/rechazo ni elevación temporal versionados. |
| Expiración Master tras 15 min inactivo | PENDING | No se identificó expiración de capacidad privilegiada por inactividad. MFA de login no la sustituye. |
| Step-up y cierre remoto de sesión | PENDING | No se encontró flujo general de reautenticación, inventario o revocación remota. |
| Audit log central, íntegro | PENDING | Hay historial operativo; no evidencia del registro central e inmutable de eventos sensibles requerido. |
| Development/staging/production | PARTIAL | Rama aislada y Docker local documentados; no se verificó proyecto Supabase de staging separado. |
| Backup/restore y continuidad | PARTIAL | Restore/reconciliación PostgreSQL local; Auth/Storage/Vault, RPO/RTO y rollback final externos pendientes. |
| Secretos y credenciales | PARTIAL | `.env.example` usa URL y publishable key pública; no se pudo hacer escaneo local completo del repositorio/historial. |
| Integraciones con mínimo privilegio/revocación | PENDING | No hay evidencia de catálogo, consentimiento y ciclo de revocación para integraciones. |
| Jobs, salud y alertas | PENDING | No se demostró un control transversal de salud/alertas y operación de jobs. |
| No agregar servicios pagos sin autorización | PASS en el alcance revisado | No se añadieron dependencias ni servicios en este checkpoint. |

## Criterios DOC12 relacionados

La clasificación fuente conserva `NO EJECUTADO`:

| ID | Clasificación fuente | Prueba relacionada (alcance limitado) |
|---|---|---|
| ACC-SEC-001 | STAGING / BLOQUEANTE | `security_rls_v3.sql`, `financial_rls_v2.sql`; no prueba toda la matriz API/RPC. |
| ACC-SEC-002 | STAGING / BLOQUEANTE | Tests RLS de tareas/finanzas; no prueba toda manipulación UI/API. |
| ACC-SEC-003 | STAGING / BLOQUEANTE | `financial_ai_boundary_v2.sql` y handler HTTP local; faltan sesiones/API completas. |
| ACC-SEC-004 | STAGING / no bloqueante | RLS/finanzas local; falta aceptación de alcance en staging. |
| ACC-SEC-005 | STAGING / BLOQUEANTE | Tests de permisos; falta alcance completo de recursos/roles. |
| ACC-SEC-006 | STAGING / BLOQUEANTE | RLS Portal local; falta cambio real de membresía y no mezcla E2E. |
| ACC-SEC-007 | STAGING / BLOQUEANTE | Políticas Tickets; falta comprobar payload/API sin notas internas. |
| ACC-SEC-008 | STAGING / BLOQUEANTE | `storage_portal_isolation_v3.sql`; no prueba Storage administrado/signed URLs. |
| ACC-SEC-009 | STAGING / BLOQUEANTE | No hay test suficiente de audit log de acciones Master. |
| ACC-SEC-010 | STAGING / BLOQUEANTE | Boundary de IA local; no certifica todos los consumidores. |
| ACC-DATA-001 | STAGING / BLOQUEANTE | Storage A/B local; Auth/Storage administrado pendiente. |
| ACC-DATA-003 | BLOQUEADO POR FUNCIÓN PENDIENTE / BLOQUEANTE | Audit log sensible aún no implementado/demostrado. |
| ACC-MIG-001, ACC-MIG-006 | STAGING / BLOQUEANTE | Restore local existe; ensayo administrado, fallo parcial y rollback final pendientes. |

La asociación indica evidencia relacionada, no cierre del criterio. No se
alteró la matriz formal de ejecución.

## Evidencia de regresión y ejecución

El estado oficial registra para CHECKPOINT 04D evidencia histórica del
candidato: 22/22 migraciones, 28/28 SQL, Node 9/9, TypeScript/build PASS,
11/11 páginas estáticas. Se reutiliza como evidencia local ya registrada;
no se afirma que estas pruebas se ejecutaron en esta sesión.

El HEAD de entrada tiene estado Vercel `success`, que no acredita prueba
E2E ni staging de Supabase.

En esta sesión:
- revisión documental/código remoto: completada;
- regresión SQL y build: **NOT EXECUTED**;
- motivo: no hay checkout local ni acceso al contenedor PostgreSQL; el
  intento de clone fue bloqueado por el proxy de red;
- ningún cambio de código, esquema, permisos o datos.

## Decisión

M01 permanece **PARTIAL**. No se escribieron controles sensibles sin
entorno para validarlos. Los bloqueantes de implementación son: doble
control y expiración Master, audit log central, MFA por permisos sensibles
y cierre remoto de sesiones. Los bloqueantes externos son Auth/Data API/
Storage en staging, rollback final y aceptación formal ACC. M00 permanece
**PARTIAL**; no se inicia M02.
