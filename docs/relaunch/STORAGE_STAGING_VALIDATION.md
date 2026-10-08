# Validación real de Portal / Supabase Storage

## Propósito

Ejecutar ACC-SEC-008 y ACC-DATA-001 con el servicio administrado de Supabase
en un proyecto de staging ya existente. Este test no crea proyectos, usuarios,
buckets ni infraestructura y no usa una clave service_role.

## Requisitos previos

- Proyecto Supabase de staging, separado de producción.
- Bucket existente `ticket-attachments` configurado como privado.
- Dos cuentas existentes de prueba Portal A y Portal B, vinculadas a clientes
  distintos y habilitadas para Storage.
- Una cuenta existente de personal interno autorizado según la matriz de
  permisos.
- Dependencia `@supabase/supabase-js` ya presente en el proyecto.
- No usar cuentas reales de clientes ni incluir sus contraseñas en Git.

Proveer estas variables desde un gestor de secretos o el entorno seguro de la
terminal. El script no las escribe en consola:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `STORAGE_PORTAL_A_EMAIL`
- `STORAGE_PORTAL_A_PASSWORD`
- `STORAGE_PORTAL_B_EMAIL`
- `STORAGE_PORTAL_B_PASSWORD`
- `STORAGE_INTERNAL_EMAIL`
- `STORAGE_INTERNAL_PASSWORD`

## Ejecución

`npm run test:storage:staging`

El script autentica las tres cuentas, crea objetos aleatorios bajo
`<auth.uid()>/...`, prueba descarga propia, descarga cruzada y solicitud
cruzada de URL firmada, verifica que anon no lea el objeto y que la ruta
pública no exponga el bucket. También comprueba que la cuenta interna
autorizada pueda generar y usar una URL temporal según la policy actual.

Los objetos se borran con la sesión de su propio dueño en un bloque de limpieza.
Si la eliminación falla, el proceso termina FAIL e informa las rutas QA para
limpieza manual en el staging. No se imprimen tokens ni URLs firmadas.

## Interpretación de URLs firmadas

Una URL firmada es una credencial bearer durante su vigencia; quien obtiene la
URL puede usarla aunque no sea el usuario que la solicitó. Por eso la prueba
verifica que B no pueda descargar el path de A ni generar una URL firmada para
ese path. No afirma que una URL de A, compartida deliberadamente con B, quede
atada a la sesión de A. Esa interpretación estricta de ACC-SEC-008 debe
confirmarse antes del release.

## Alcance

La prueba es solo para Supabase staging. No ejecutada desde este entorno:
no hay acceso a las cuentas ni a las variables de staging. No ejecutar contra
producción. Registrar resultado, fecha, commit y solo los nombres de caso;
nunca registrar credenciales, access tokens o URLs firmadas.
