# Matriz final de evidencias — eQuantum Relanzamiento

Fecha: 2026-10-08  
Candidato: `relanzamiento-2026` — `4674502`  
Alcance: evidencia local existente y gates pendientes. PostgreSQL local no certifica servicios administrados de Supabase.

| Gate | Estado | Evidencia disponible | Qué falta / impacto |
|---|---|---|---|
| Restore PostgreSQL y baseline | PASS | Restore limpio, reconciliación del baseline y exclusión explícita de Vault | No certifica Auth, Storage administrado ni Vault |
| Migraciones ordenadas | PASS | 22/22 migraciones aplicadas en ensayo local | Ensayo final en staging real y rollback |
| Regresión SQL | PASS | 28/28 tests versionados en `equantum_restore_clean` | No equivale a 361 ACC ni 40 IT/INT |
| Build y TypeScript | PASS | Build Next.js, TypeScript y 11/11 páginas estáticas | Build no es E2E |
| Tests Node financieros | PASS | 9/9 tests del resumen/circuito | No acredita sesión real ni recorrido visual |
| Seguridad financiera / IA | PASS | Boundary y permisos validados localmente; rechazo antes de contexto/proveedor | Probar servicios y sesiones reales en staging |
| Storage Portal A/B en PostgreSQL | PASS | Política instalada; A ve A/no B, B ve B/no A; rollback y cero residuos | Servicio remoto y recorrido Auth/Storage E2E |
| Acceso de usuario interno a Storage | PARTIAL | Política permite el acceso interno definido | Confirmar el flujo con identidad interna real en staging |
| Deployment Vercel del candidato | PARTIAL | Estado del commit indica deployment completado | Verificar rutas y flujos visuales en Preview |
| Matriz de aceptación: 361 ACC | PENDING | Matriz versionada localizada | Ejecución, evidencia y aprobación criterio por criterio; gate de release |
| Casos de integración: 40 IT/INT | PENDING | Matriz versionada localizada | Ejecución y aprobación de casos críticos; gate de release |
| E2E visual y Data API con sesión real | BLOCKED | Build/QA local disponibles | Requiere staging y usuarios de prueba autorizados |
| Supabase Auth/Storage administrados | BLOCKED | No se usan sustitutos locales para declarar PASS | Pruebas de sesión, upload/download y aislamiento en staging |
| Advisors y APIs legadas aplicables | BLOCKED | Sin evidencia final registrada | Revisión de seguridad en el entorno de staging |
| Rollback final del candidato | PENDING | Restores locales previos completados | Ensayar y registrar recuperación del candidato |
| Chat/eQ/DOTS y BI/ULi | PENDING | Estado de implementación los deja pendientes | Confirmar alcance; si son parte del release, bloquean su aprobación |
| Autorización de producción | BLOCKED | Producción permanece no autorizada | Aprobación explícita después de cerrar los gates |

## Decisión

El candidato está **listo para validación final**, pero **no está listo para producción**. Los PASS se limitan al alcance local descrito. Los estados BLOCKED requieren infraestructura real; PENDING refleja trabajo de validación o implementación aún no completado.
