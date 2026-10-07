const RESTRICTED_FINANCIAL_PATTERNS = [
  /\bcost[oa]s?\b/i,
  /\bgastos?\b/i,
  /\bm[aá]rgen(?:es)?\b/i,
  /\brentabilidad\b/i,
  /\butilidad(?:es)?\b/i,
  /\bganancias?\b/i,
  /\bgan(?:o|ó|amos|aron|ando)\b/i,
  /\bcu[aá]nto (?:ganamos|ganamos realmente|queda|nos queda|deja|nos deja)\b/i,
  /\bbeneficios?\b/i,
  /\bcomisiones?\b/i,
  /\bflujo de caja\b/i,
  /\bcash\s*flow\b/i,
  /\bcaja global\b/i,
  /\bEBITDA\b/i,
  /\bROI\b/i,
  /\bROAS\b/i,
  /\bratios?\s+(?:financieros?|gerenciales?)\b/i,
  /\bproyecci[oó]n(?:es)?\s+financieras?\b/i,
  /\bdespu[eé]s de gastos\b/i,
  /\bdespu[eé]s de costos\b/i,
  /\bcu[aá]nto nos queda\b/i,
];

export function asksRestrictedFinancialInfo(question: string): boolean {
  return RESTRICTED_FINANCIAL_PATTERNS.some((pattern) => pattern.test(question));
}
