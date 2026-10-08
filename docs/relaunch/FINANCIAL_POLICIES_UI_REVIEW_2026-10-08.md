# Políticas financieras — evidencia de interfaz

Base: relanzamiento-2026, 1095759.

La sección Finanzas incorpora un panel para crear versiones fiscales y de
comisión, consultar las versiones registradas y aprobar el tratamiento fiscal
de partidas de propuestas existentes con justificación y referencia de evidencia.
La aprobación invoca approve_proposal_item_fiscal_v3; los importes los calcula
PostgreSQL. No se crean tasas ni clasificaciones operativas por defecto.

El acceso visual requiere una cuenta maestra activa. Antes de cargar datos y
antes de guardar, el componente verifica getUser, el perfil activo/is_master y
has_financial_info. Las escrituras usan la sesión del usuario y los controles
RLS/RPC existentes. No se agregan permisos ni migraciones en este candidato.

Las versiones son inmutables y se crean por código y número explícitos.
El panel muestra errores, bloquea envíos simultáneos y carga los registros con
paginación. Se carga al abrirlo desde Finanzas.

Validación local del candidato 931115b, ejecutada en Cloud Shell:
- git diff --check: sin errores.
- Pruebas del resumen financiero: 9/9 PASS.
- TypeScript del repositorio: PASS.
- Build Next.js 15.5.27: PASS, 11/11 páginas estáticas.
- QA SQL sobre equantum_restore_clean: PASS=26 FAIL=0 TOTAL=26.
- Evidencia local: /home/equantumg/equantum-policies-ui-validacion.txt.

El recorrido de navegador y las operaciones por Data API con una sesión real
siguen PENDIENTES. Compilar y pasar la regresión SQL no certifica ese recorrido.

La creación de una versión de comisión no asigna esa versión a una propuesta.
La selección de comisión por propuesta sigue pendiente de un contrato de escritura
autorizado y su prueba con rol real. También siguen pendientes la configuración
fiscal operativa aprobada, los flujos comerciales completos y la validación E2E
de Auth/Storage. Este candidato no cierra los criterios formales de release.

Main y producción no se modifican.
