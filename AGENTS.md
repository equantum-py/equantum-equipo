# EQ — guía operativa

Seguir docs/PROTOCOLO_MAESTRO.md y docs/PLAN_MAESTRO.md. Los documentos
rectores DOC00–19 y las decisiones aprobadas son la fuente funcional. Ante
contradicción, detener ese paquete y registrar la decisión pendiente.

- Antes de editar, confirmar checkout, rama, HEAD y estado Git; preservar todo
  cambio previo. Trabajar en rama aislada, nunca en main directamente.
- Daniel decide visión, alcance, prioridad y aceptación empresarial.
  Derlis decide arquitectura y asuntos técnicos críticos.
  Producción, acciones irreversibles y cambios sobre datos reales requieren
  autorización explícita de ambos.
- No desplegar, hacer push/merge, cambiar permisos críticos, gastar en servicios,
  usar producción como prueba ni modificar Supabase remoto sin la autorización
  que define el protocolo.
- No inventar requisitos, IDs, staging, aprobaciones ni resultados. Código y
  build no equivalen a aceptación. No exponer secretos o datos personales.
- Usar fixtures aislados, probar casos negativos y verificar limpieza. No
  debilitar RLS/aserciones, agregar grants permanentes para simulaciones ni usar
  reset destructivo o force push.
- Registrar por paquete HEAD, ambiente, comandos, resultados y límites en
  docs/codex/WORKLOG.md; mantener docs/ESTADO_DEL_PROYECTO.md vigente.
- Automatizar lo reversible y autorizado. Detenerse ante decisión funcional,
  acción irreversible, acceso externo, costo o autorización faltante.
- No iniciar automáticamente el paquete siguiente salvo que alcance, orden,
  dependencias, entorno y mecanismo estén aprobados y disponibles.
