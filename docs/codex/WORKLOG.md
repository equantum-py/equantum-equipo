# Bitácora técnica — Codex / EQ 2026

Entradas cronológicas. Registrar hechos, no secretos ni datos personales. No
borrar historia; agregar una entrada correctiva si un hecho cambia.

## 2026-10-09 UTC — Protocolo Maestro 2.0 preparado localmente

- Checkout: /workspace/scratch/b96fa0074e66/equantum-relaunch.
- Rama: codex/p1-hardening-20261009. Commits de trabajo local; no push/merge.
- Se creó la normativa 2.0, el plan P1–P7 según prioridades expresas, estado
  ejecutivo y esta bitácora. No se desarrollaron módulos ni se cambiaron datos,
  permisos, producción o Supabase remoto.
- El único AGENTS.md localizado fue el del checkout, que ya era provisional.
  No apareció una copia independiente en los adjuntos de esta sesión. Se
  enriqueció esa guía; Daniel/Derlis deben revisar el protocolo preparado.
- Documentos fuente inspeccionados: RELEASE_CLOSURE_PLAN E0–E8 y matriz de
  cobertura 00–19. P1–P7 aquí organizan prioridad, no alteran DOC00–19. P3
  DOTS queda limitado por DOC14–18; P4–P6 dependen de fuentes y gates del plan.
- Node operations, TypeScript y build con valores públicos ficticios constaban
  aprobados en esta sesión; no se repitieron por cambio documental. No equivalen
  a aceptación de módulo. SQL y 59 escenarios P1 siguen NO EJECUTADOS en este
  entorno.
- Automatizaciones comprobadas en checkout: scripts de pruebas locales y
  workflow de backup existente, no ejecutado. No hay CI de pruebas ni mecanismo
  de continuidad automática comprobado. Staging/base y branch rules requieren
  configuración externa. No se afirmará instalación por estar documentada.
- Decisiones: Daniel conserva autoridad empresarial; Derlis, la técnica crítica;
  ambos autorizan producción e irreversibles, conforme al encargo.
- Próximo gate: revisión de Daniel y Derlis. Después, validar P1 con baseline
  autorizado antes de iniciar P2.

## 2026-10-09 UTC — revisión de coherencia DOC08/DOC12 y DOTS/BI

- Fuentes comprobadas: DOC08 §§46–50; DOC12 §0/§3, Tabla 11 (ACC-FIN-001–008),
  Tabla 14 (ACC-DOTS) y Tabla 16 (ACC-BI); DOC13 §§0/3/5/16/27–35/43–47;
  DOC07 §§8/43/46/48/50/52; plan de cierre E0–E8 y registro oficial CSV.
- DOC08 figura correctamente en P2 como dueño del ciclo Clientes/Ventas y en
  P5 como fuente de los hechos económicos comerciales; DOC08 §50 dice que
  Ventas aporta hechos y Finanzas Gerencial consolida el impacto. DOC19 posee
  la consolidación financiera. DOC12 prueba los contratos —no crea reglas— y
  Tabla 11 contiene ACC-FIN-001–008; no es dueño del módulo financiero.
- La matriz oficial confirma localizadores ACC-FIN-001–008 en DOC12 Tabla 11.
  También conserva DOC12 Tabla 14 ACC-DOTS y Tabla 16 ACC-BI; no se alteraron
  IDs ni estados de aceptación.
- Dependencia DOTS corregida conceptualmente: DOC13 experiencia/contratos y
  pruebas con sintéticos pueden avanzar antes de P4. E1/DOC02/DOC11 es gate
  para contexto real; E4/P4 para métricas oficiales e integración BI; E5/DOC14–18
  y E1/E2 son gates de activación de acciones autónomas integradas (plan E6).
  DOTS no duplica NBA, Radar, Triage ni BI; ACC-DOTS-002/003/005 y ACC-BI-003
  respaldan estos límites.
- Archivos corregidos: docs/PROTOCOLO_MAESTRO.md, docs/PLAN_MAESTRO.md y
  docs/ESTADO_DEL_PROYECTO.md; esta entrada registra la revisión.
- Solo revisión documental: no se desarrolló código ni se ejecutaron tests.
  Pendiente: revisión/aprobación de Daniel y Derlis; P1 permanece PARTIAL.
