# Matriz final de evidencias — eQuantum Relanzamiento

Fecha: 2026-10-08  
Candidato revisado en GitHub: `relanzamiento-2026` — `8b38489`  
Alcance: evidencia local existente y gates pendientes. PostgreSQL local no certifica servicios administrados de Supabase.

| Gate | Estado | Evidencia disponible | Qué falta / impacto |
|---|---|---|---|
| Restore PostgreSQL y baseline | PASS | Restore limpio, reconciliación del baseline y exclusión explícita de Vault | No certifica Auth, Storage administrado ni Vault |
| Migraciones ordenadas | PASS | 22/22 migraciones aplicadas en ensayo local | Ensayo final en staging real y rollback |
| Regresión SQL | PASS | 28/28 tests versionados en `equantum_restore_clean` | No equivale a 361 ACC ni 40 IT/INT |
| Build y TypeScript | PASS | Build Next.js, TypeScript y 11/11 páginas estáticas | Build no es E2E |
| Tests Node financieros | PASS | 9/9 tests del resumen/circuito | No acredita sesión real ni recorrido visual |
| Seguridad financiera / IA | PASS | Boundary y permisos validados localmente; rechazo antes de contexto/proveedor | Probar servicios y sesiones reales en staging |
| Storage Portal A/B en PostgreSQL | PASS | Política instalada; A ve A/no B, B ve B/no A; rollback y cero residuos, según evidencia del checkpoint local | Script de Auth/Storage real preparado; falta ejecutarlo en staging y confirmar URL privada/internal |
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


## Mapa definitivo de validación y bloqueantes — 2026-10-08

**Alcance:** los registros rectores versionados incluyen DOC12–DOC19 y 40 casos IT/INT. No encontramos una exclusión aprobada; los 401 registros permanecen en el alcance de salida. No se asignó NO APLICA.

“CUBIERTO / LISTO PARA EJECUTAR” indica que hay implementación y evidencia técnica relacionada para ejecutar el criterio formal. No significa PASS. La columna de ejecución permanece **NO EJECUTADO** en las 401 filas. Los tests se relacionaron por el comportamiento que efectivamente prueban; cuando cubren solo una parte o requieren servicio/sesión real, la justificación lo dice.

### Conteo por inventario

| Alcance | Total | Cubierto / listo | Requiere staging | Función pendiente | No aplica |
|---|---:|---:|---:|---:|---:|
| ACC | 361 | 39 | 48 | 274 | 0 |
| IT/INT | 40 | 5 | 1 | 34 | 0 |
| **Total** | **401** | **44** | **49** | **308** | **0** |

### Conteo por documento / paquete

| Paquete | Total | Cubierto / listo | Requiere staging | Función pendiente |
|---|---:|---:|---:|---:|
| DOC12 | 139 | 33 | 40 | 66 |
| DOC13 | 13 | 0 | 0 | 13 |
| DOC14 | 15 | 0 | 2 | 13 |
| DOC15 | 15 | 0 | 0 | 15 |
| DOC16 | 30 | 0 | 1 | 29 |
| DOC17 | 42 | 2 | 0 | 40 |
| DOC18 | 40 | 0 | 0 | 40 |
| DOC19 | 67 | 4 | 5 | 58 |
| P01 | 24 | 1 | 0 | 23 |
| P02 | 16 | 4 | 1 | 11 |

### Bloqueantes explícitos

La fuente marca **131 ACC como BLOQUEANTE**:

| Situación del bloqueante | Cantidad |
|---|---:|
| CUBIERTO / listo para ejecutar, aún no ejecutado formalmente | 23 |
| Requiere staging real | 22 |
| Depende de función pendiente | 86 |
| **Total** | **131** |

Los 131 se distribuyen por fuente así: DOC12 = 61; DOC15 = 6; DOC16 = 22; DOC17 = 19; DOC18 = 23. No hay severidad BLOQUEANTE en DOC13, DOC14 ni DOC19 en la matriz fuente. Los 86 bloqueantes dependientes de función pendiente comprenden 16 de DOC12 y 70 de DOC15–DOC18.

Los IT/INT no tienen una columna de severidad individual. Por eso no se inventa una cantidad adicional de bloqueantes IT/INT. El gate rector sí exige aprobar los casos de integración críticos; los 34 que dependen de funciones ausentes todavía no pueden ejecutarse.

### Bloqueantes reales para producción

1. **Los 131 ACC marcados BLOQUEANTE siguen abiertos.** Ninguno tiene ejecución/aprobación formal en esta matriz; incluso los 23 listos para ejecutar deben aprobarse antes de cerrar el gate.
2. **Hay 86 bloqueantes que requieren funciones aún pendientes.** Principalmente privacidad/memoria, gobernanza y evaluación de IA, observabilidad, junto con gaps concretos de DOC12.
3. **Hay 22 bloqueantes que requieren staging real**, incluida seguridad por sesiones/RLS, Storage administrado, flujo de usuarios, configuración fiscal real y ensayo de migración/rollback.
4. **Los IT/INT críticos siguen sin aprobación formal.** Cinco están listos para ejecutar, uno necesita staging y 34 esperan funciones pendientes; la fuente no declara cuáles son críticos caso por caso.
5. **Los gates externos siguen abiertos:** sesión real Supabase Auth/Data API/Storage, E2E de Preview, Advisors/APIs legadas aplicables, rollback final y autorización explícita. Esto no se demuestra con QA PostgreSQL local ni con el build.

### Decisión de salida

El candidato está **listo para organizar y ejecutar la validación final**, pero **no está listo para producción**. No se repitieron regresiones ni build en esta clasificación documental. main, producción y datos reales no se modificaron.

Matriz detallada, una fila por criterio/caso: docs/relaunch/acceptance/FINAL_CLASIFICACION_ACC_IT_INT_2026-10-08.csv.
