# Fase 0 — Backup, Restore y Ensayo Gratuito

## Objetivo

Cerrar el gate que impide probar las migraciones V2 sin tocar producción y sin contratar infraestructura adicional.

## Restricciones

- Producción no es entorno de prueba.
- No crear Supabase Branch ni proyecto adicional con costo.
- No ejecutar las migraciones V2 en producción.
- Un backup no se considera verificado hasta demostrar restore + reconciliación.
- Auth, Storage y secretos requieren tratamiento separado del dump de tablas.

## Baseline productivo — 2026-10-06

Lectura realizada antes del ensayo:

| Tabla | Filas |
|---|---:|
| clients | 3 |
| projects | 0 |
| tasks | 3 |
| followups | 0 |
| tickets | 2 |
| ticket_messages | 3 |
| ticket_events | 10 |
| profiles | 3 |
| user_permissions | 3 |
| chat_messages | 2 |
| client_portal_users | 1 |

Estos conteos son controles de reconciliación, no sustituyen un backup.

## Entorno de ensayo Gs. 0

La estrategia aprobada para costo cero es una base PostgreSQL/Supabase local o efímera en un entorno de desarrollo, nunca una branch administrada paga.

El repositorio debe contener scripts/checklists reproducibles, pero **no** dumps con datos sensibles ni secretos.

## Gate A — Backup

Antes de una migración real:
1. obtener snapshot/dump compatible de esquema y datos permitidos;
2. registrar fecha/hora y origen;
3. mantener el backup fuera de Git;
4. verificar que el artefacto no esté vacío/corrupto;
5. registrar qué queda fuera: Auth/Storage/secretos si no están incluidos por el mecanismo usado.

Estado: **PENDIENTE DE EJECUCIÓN**.

## Gate B — Restore

Restaurar el backup en el entorno gratuito/efímero.

Después del restore:
- ejecutar `supabase/tests/phase0_baseline_reconcile.sql`;
- comparar conteos con baseline;
- comprobar FKs/huérfanos;
- comprobar relaciones Ticket/Task/Portal;
- registrar diferencias, sin inventar relaciones.

Estado: **PENDIENTE DE EJECUCIÓN**.

## Gate C — Ensayo de migraciones V2

Solo después de un restore válido:
1. aplicar migraciones V2 en orden;
2. ejecutar tests de reconciliación;
3. ejecutar tests de identidad comercial;
4. ejecutar tests de catálogo/pipeline;
5. ejecutar tests de propuestas/ventas;
6. ejecutar tests de servicios/proyectos/tareas;
7. ejecutar pruebas RLS negativas;
8. reconciliar nuevamente los datos.

Cualquier fallo bloquea producción.

## Gate D — Restore limpio / rollback

Descartar la base de ensayo y repetir el restore desde el backup original. El resultado debe volver al baseline previo a V2.

Esto demuestra recuperación real; tener solamente un archivo de backup no alcanza.

## Auth y Storage

El ensayo de PostgreSQL no debe interpretarse como prueba completa de Supabase Auth/Storage. Para el gate final:
- preservar/reconciliar vínculos `profiles.id ↔ auth.users.id`;
- verificar `client_portal_users.user_id`;
- verificar bucket privado `ticket-attachments`;
- probar que Portal A no accede a datos/adjuntos de B;
- no copiar tokens ni secretos a Git.

## Criterio de salida Fase 0

Fase 0 queda verde únicamente cuando exista evidencia de:
- backup creado;
- restore exitoso;
- baseline reconciliado;
- migraciones V2 ensayadas;
- RLS negativo aprobado;
- restore limpio repetible;
- costo adicional = Gs. 0.

Hasta entonces: **NO MERGE A MAIN / NO MIGRACIÓN EN PRODUCCIÓN**.
