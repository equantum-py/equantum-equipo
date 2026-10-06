#!/usr/bin/env bash
set -euo pipefail

# Ensayo local/efímero de costo cero.
# Requiere PostgreSQL accesible en TEST_DATABASE_URL.
# NO apuntar TEST_DATABASE_URL a producción.
: "${TEST_DATABASE_URL:?Definí TEST_DATABASE_URL para una base LOCAL/EFIMERA, nunca producción}"

echo "1/3 Verificando destino de ensayo..."
case "$TEST_DATABASE_URL" in
  *oujrahzvljdhzqsdyujh*) echo "ERROR: TEST_DATABASE_URL parece producción. Abortado."; exit 1 ;;
esac

echo "2/3 Ejecutando reconciliación baseline..."
psql "$TEST_DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/phase0_baseline_reconcile.sql

echo "3/3 Entorno listo para aplicar migraciones V2 manualmente y repetir tests."
echo "No se modificó producción."
