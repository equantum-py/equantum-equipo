#!/usr/bin/env python3
"""Build a read-only index across the three official acceptance inventories."""
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/relaunch/acceptance/UNIFIED_ACCEPTANCE_INDEX.csv"


def read_csv(path):
    with path.open(encoding="utf-8-sig", newline="") as source:
        return list(csv.DictReader(source))


def row(suite, source_id, source_status, requirement, actor, action, expected, evidence, pending):
    return {
        "suite": suite,
        "source_id": source_id,
        "source_status_verbatim": source_status,
        "requirement_verbatim": requirement,
        "actor_verbatim": actor,
        "action_verbatim": action,
        "expected_verbatim": expected,
        "evidence_verbatim": evidence,
        "result_this_run": "NO EJECUTADO",
        "run_evidence": "",
        "remaining_work_verbatim": pending,
    }


formal = read_csv(ROOT / "docs/relaunch/acceptance/REQUIREMENTS_TRACEABILITY_00_19_2026-10-08.csv")
p1 = read_csv(ROOT / "docs/relaunch/acceptance/P1_SCENARIOS_59.csv")
doc08 = read_csv(ROOT / "docs/relaunch/acceptance/DOC08_SCENARIOS_42_TRACEABILITY.csv")
if len(formal) != 401 or len({r["id_oficial"] for r in formal}) != 401:
    raise SystemExit("BLOCKED: official formal inventory count/IDs changed")
if len(p1) != 59 or len({r["Caso_P1"] for r in p1}) != 59:
    raise SystemExit("BLOCKED: P1 inventory count/IDs changed")
if len(doc08) != 42:
    raise SystemExit("BLOCKED: DOC08 §80 inventory count changed")

rows = []
for r in formal:
    rows.append(row("DOC00-19 / 401", r["id_oficial"], r.get("ejecucion_formal", ""),
        r.get("requisito_y_esperado", ""), "", "", r.get("validacion_de_cierre", ""),
        r.get("evidencia_concreta_registrada", ""), r.get("brecha", "")))
for r in p1:
    rows.append(row("P1 / 59", r["Caso_P1"], r.get("Estado_de_ejecución", ""),
        r.get("Requisito_fuente", ""), r.get("Actor", ""), r.get("Acción", ""),
        r.get("Resultado_esperado", ""), r.get("Evidencia_a_recolectar", ""), r.get("Precondición", "")))
for r in doc08:
    rows.append(row("DOC08 §80 / 42", r["Referencia_original"], r.get("Estado", ""),
        r.get("Escenario_original", ""), "", "", "", r.get("Evidencia_ejecutada", ""),
        r.get("Pendiente", "")))

fields = ["suite", "source_id", "source_status_verbatim", "requirement_verbatim", "actor_verbatim",
          "action_verbatim", "expected_verbatim", "evidence_verbatim", "result_this_run", "run_evidence",
          "remaining_work_verbatim"]
with OUT.open("w", encoding="utf-8", newline="") as target:
    writer = csv.DictWriter(target, fieldnames=fields, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
print(f"PASS: {len(formal)} formal IDs + {len(p1)} original P1 IDs + {len(doc08)} DOC08 scenarios = {len(rows)} rows")
print(f"Generated: {OUT.relative_to(ROOT)}")
