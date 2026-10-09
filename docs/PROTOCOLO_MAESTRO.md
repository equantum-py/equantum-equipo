# Protocolo Maestro Codex 2.0 — eQuantum Equipo 2026

Estado: normativa operativa preparada localmente; aprobación de Daniel y Derlis
pendiente. No modifica los requisitos DOC00–19 ni autoriza producción.

## 1. Autoridad de decisión y fuentes

Fuentes funcionales, en orden: documentos rectores DOC00–19 y anexos aprobados;
decisiones empresariales registradas; este protocolo y el paquete autorizado;
código y pruebas. El código no redefine requisitos. Ante contradicción entre
fuentes, documentar ambas y pedir decisión; no escoger en silencio.

- Daniel: visión, alcance, prioridad, reglas de negocio, excepciones y aceptación
  empresarial.
- Derlis: arquitectura, seguridad, contratos técnicos, migraciones y decisiones
  técnicas críticas.
- Daniel y Derlis: producción, cambios irreversibles, datos reales, permisos
  críticos y publicación con impacto operativo.
- Codex: pasos rutinarios, reversibles y dentro de un paquete aprobado; debe
  dejar evidencia y respetar gates.

Una autorización cubre únicamente acción, alcance, rama y ambiente indicados.
El silencio, una aprobación anterior o la aprobación de otra tarea no autorizan
un cambio nuevo.

## 2. Gestión de paquetes y dependencias

Cada paquete lleva ID, objetivo, fuentes DOC y IDs ACC/IT/INT existentes, alcance
incluido/excluido, dependencias, cambios previstos, riesgos, pruebas, responsable
y condición de cierre. El registro se mantiene en docs/PLAN_MAESTRO.md; la
ejecución, en docs/codex/WORKLOG.md.

Estados: PROPUESTO, LISTO, EN CURSO, BLOQUEADO, VERIFICADO LOCAL, VALIDADO EN
STAGING, ACEPTADO y PUBLICADO. No saltar estados. Una dependencia bloquea solo
lo que depende de ella; se continúa trabajo independiente sin ampliar alcance.

Solo continuar automáticamente al siguiente paquete si orden y alcance ya
están aprobados, el paquete está listo, las dependencias y el entorno existen,
el paquete anterior cerró con evidencia y no hay una nueva decisión o permiso
requerido. Si la plataforma no ofrece ejecución continua compatible, informar
que la continuidad automática no está activa.

Separar el desarrollo de una capacidad de su habilitación integrada. Una tarea
independiente puede avanzar con contratos y datos sintéticos aunque otro
paquete prioritario sea una dependencia de activación; registrar el límite y no
marcar LISTO/ACEPTADO el flujo integrado hasta cumplir todos sus gates. El orden
empresarial no elimina dependencias técnicas ni obliga a dejar ocioso trabajo
seguro que no las necesita.

## 3. Ejecución autónoma supervisada

Dentro del paquete aprobado, Codex diagnostica, desarrolla, prueba, corrige fallos
reproducibles, revisa el diff y actualiza la evidencia sin pedir aprobación para
cada paso ordinario. No sustituye implementación por auditorías repetidas.

Detener solo la acción afectada cuando haya ambigüedad de negocio, cambio de
alcance, seguridad crítica, datos reales, servicio externo, costo, acción
irreversible o falta de permiso. Explicar operación, riesgo y requisito concreto;
seguir tareas independientes permitidas.

## 4. Revisión independiente

Cambios de Auth/RLS, permisos, finanzas, migraciones destructivas, automatización,
privacidad, secretos y release requieren revisión independiente. El revisor
compara fuente, diff y pruebas. Si no existe segundo revisor humano/técnico,
registrar REVISIÓN INDEPENDIENTE NO DISPONIBLE; el autor no se atribuye esa
revisión.

## 5. Memoria persistente

AGENTS.md resume reglas de entrada. Este protocolo define el método.
PLAN_MAESTRO.md mantiene paquetes y dependencias. ESTADO_DEL_PROYECTO.md es la
fotografía vigente. codex/WORKLOG.md conserva entradas cronológicas.

Cada entrada registra fecha y zona, repo/branch/HEAD antes y después, cambios,
comandos, resultados, ambiente, límites, decisiones con autor/alcance, estado de
publicación y siguiente gate. No guardar secretos, datos personales ni logs
sensibles. Corregir una entrada con otra; no borrar la historia.

## 6. Seguridad, permisos y datos

Aplicar mínimo privilegio y validar permisos en servidor/base, no solo en UI.
Usar staging identificado, separado y autorizado. No asumir que nombre, URL,
dump legible o build verde prueban aislamiento o sanitización.

No abrir ni imprimir secretos; no incluirlos en Git, chat o evidencia. Los tests
usan datos sintéticos, fixtures aislados y rollback cuando corresponde. Verificar
limpieza. No agregar grants permanentes para compensar infraestructura local
incompleta. Incluir rechazos de acceso ajeno e intentos inválidos.

## 7. Pruebas y regresiones

Elegir pruebas por comportamiento: unitarias, SQL/RLS, integración, UI/E2E,
build y regresión afectada. No repetir suites aprobadas salvo que cambie código,
dependencia o riesgo. Registrar fecha, HEAD y comando para diferenciar evidencia
actual e histórica.

Estados de prueba: PASS, FAIL, NO EJECUTADO y BLOQUEADO. El estado de módulo es
PARTIAL mientras queden requisitos o aceptación pendiente. Todo PASS declara
entorno y límites. PostgreSQL local no prueba Auth, Storage, MFA o sesiones de
Supabase administrado; build no prueba conectividad ni flujo de usuario. La
aceptación formal requiere el criterio oficial ejecutado, no una prueba similar.

No desactivar tipos, seguridad, aserciones ni checks para obtener verde. Ante
fallo, diagnosticar causa, separar defecto de limitación ambiental y repetir las
pruebas afectadas más la regresión necesaria.

## 8. Paralelismo controlado

Dividir tareas solo cuando sean independientes, con contrato, archivos y dueño
claros. Un integrador revisa conflictos, seguridad y regresión. No permitir
edición concurrente de una misma migración, política, estado canónico o regla.
Usar agentes paralelos únicamente si la plataforma e instrucciones vigentes lo
permiten; esta norma no instala esa capacidad.

## 9. Recuperación segura

Antes de editar, registrar Git y preservar cambios previos. Preferir cambios
pequeños y commits locales revisables en ramas aisladas. Ante error, conservar
diff y evidencia; corregir de forma compensatoria o revertir explícitamente.
Nunca resetear/destruir trabajo automáticamente ni force-pushear. Una migración
irreversible necesita plan y autorización dual; no ejecutarla sobre datos reales
en esta preparación.

## 10. Recursos y costos

Costo adicional por defecto: cero. No crear servicios, subir planes, activar
proveedores pagos ni ampliar cuota. Si un paso puede generar costo, medir o
estimar y detenerse hasta autorización. Registrar duración, bloqueos y consumo
cuando las herramientas lo expongan. Nunca premiar velocidad a costa de
cobertura, seguridad o calidad.

## 11. Decisiones y evidencia verificables

Registrar ID de decisión, opciones, decisión literal, responsable, fecha/zona,
alcance y expiración si aplica. Para acciones de producción/irreversibles,
registrar por separado las aprobaciones de Daniel y Derlis.

Evidencia reproducible incluye commit/árbol, ambiente, comando/recorrido, salida,
fixtures y limpieza. Guardar evidencia sensible fuera del repo; en el worklog
anotar solo resumen sanitizado y referencia/checksum cuando sea útil.

## 12. Productividad y calidad

Por paquete medir tiempo LISTO→cierre/bloqueo, espera por dependencia,
requisitos ejecutados/verificados por ID, pruebas PASS/FAIL/BLOQUEADO/NO
EJECUTADO, regresiones, defectos reabiertos, cambios revertidos, automatizaciones
realmente ejecutadas frente a propuestas y costo adicional.

No usar cantidad de commits, velocidad ni porcentaje PASS como incentivo para
reducir alcance o pruebas. Comparar paquetes equivalentes y explicar datos
faltantes.

## 13. Automatización y gates de producción

Documentar no significa instalar. El estado real de CI, protecciones de rama,
staging y ejecución continua se registra en ESTADO_DEL_PROYECTO.md. Marcar como
PENDIENTE DE CONFIGURAR hasta probarlo en la plataforma. No ejecutar workflows
que consulten producción como si fueran pruebas.

Producción requiere gates de aceptación, seguridad, backup/rollback, operación y
autorización explícita de Daniel y Derlis. Este protocolo no es autorización de
release.
