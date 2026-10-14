const test = require("node:test");
const assert = require("node:assert/strict");
const workflow = require("../../lib/operations/task-triage-radar.ts");

test("legacy task states display within the six official states", () => {
  assert.equal(workflow.officialTaskStatus("paused"), "in_progress");
  assert.equal(workflow.officialTaskStatus("waiting_client"), "waiting");
  assert.equal(workflow.taskStatusLabel("waiting_client"), "Esperando");
  assert.equal(workflow.officialTaskStatus("unexpected"), null);
});

test("human priority taxonomy does not expose the legacy low band", () => {
  assert.equal(workflow.taskPriorityLabel("low"), "Normal");
  assert.equal(workflow.taskPriorityLabel("critical"), "Crítica");
});

test("Radar reports overdue and unprotected conditions together", () => {
  const base = {
    state: "active",
    is_overdue: false,
    next_action: "Revisar aprobación",
    next_review_at: "2026-10-09T12:00:00Z",
    condition_text: "Cliente responde",
    responsible_id: "user-a",
  };
  assert.equal(workflow.radarHealth(base), "protected");
  assert.equal(workflow.radarHealth({ ...base, is_overdue: true }), "requires_review");
  assert.equal(workflow.radarHealth({ ...base, responsible_id: null }), "unprotected");
  assert.equal(workflow.radarHealth({ ...base, condition_text: "Seguimiento operativo" }), "unprotected");
  const overdueAndUnprotected = workflow.radarHealth({
    ...base,
    is_overdue: true,
    responsible_id: null,
  });
  assert.equal(overdueAndUnprotected, "requires_review_unprotected");
  assert.deepEqual(workflow.radarHealthFlags(overdueAndUnprotected), {
    requiresReview: true,
    unprotected: true,
    protected: false,
    closed: false,
  });
  assert.equal(workflow.radarHealth({ ...base, state: "closed" }), "closed");
});

test("task transitions enforce required waiting/blocking/reopen context", () => {
  assert.equal(workflow.canTransitionTask("pending", "waiting"), true);
  assert.equal(workflow.canTransitionTask("completed", "pending"), true);
  assert.equal(workflow.canTransitionTask("cancelled", "pending"), true);
  assert.equal(workflow.canTransitionTask("cancelled", "in_progress"), false);
  assert.equal(workflow.canTransitionTask("completed", "cancelled"), false);
  assert.match(workflow.validateTransitionContext("waiting", {}), /dependencia/);
  assert.match(
    workflow.validateTransitionContext("waiting", { waitingOn: "Aprobación" }),
    /fecha de revisión o una condición/,
  );
  assert.equal(
    workflow.validateTransitionContext("waiting", {
      waitingOn: "Aprobación del cliente",
      condition: "Cliente responde",
    }),
    null,
  );
  assert.match(workflow.validateTransitionContext("blocked", {}), /impedimento/);
  assert.equal(workflow.validateTransitionContext("pending", {}), null);
  assert.match(workflow.validateTransitionContext("pending", { from: "completed" }), /reapertura/);
  assert.match(workflow.validateTransitionContext("in_progress", { from: "completed" }), /reapertura/);
  assert.match(workflow.validateTransitionContext("pending", { from: "cancelled" }), /reapertura/);
  assert.equal(
    workflow.validateTransitionContext("pending", {
      from: "cancelled",
      reason: "La solicitud vuelve a ser válida",
    }),
    null,
  );
  assert.match(workflow.validateTransitionContext("cancelled", {}), /motivo/);
  assert.match(
    workflow.validateTransitionContext("in_progress", {
      from: "waiting",
      waitingSatisfied: true,
    }),
    /evidencia/,
  );
  assert.match(
    workflow.validateTransitionContext("in_progress", {
      from: "waiting",
      waitingSatisfied: false,
      waitingResolutionEvidence: "Aprobación recibida",
    }),
    /Confirmá la resolución/,
  );
  assert.equal(
    workflow.validateTransitionContext("in_progress", {
      from: "waiting",
      waitingSatisfied: true,
      waitingResolutionEvidence: "Aprobación recibida",
    }),
    null,
  );
});

test("task completion recommendation preserves an existing pending followup without duplicating it", () => {
  const recommendation = workflow.taskCompletionRecommendation(
    { id: "task-1" },
    [{ task_id: "task-1", status: "pending" }],
    [{ source_type: "task", source_id: "task-1", state: "active" }],
  );
  assert.equal(recommendation.kind, "preserve-followup");
  assert.equal(recommendation.destination, "radar");
  assert.equal(recommendation.recommendedOption, "A");
  assert.match(recommendation.detail, /no se crea otro/);
});

test("task completion recommendation preserves an active Radar item even without an open followup row", () => {
  const recommendation = workflow.taskCompletionRecommendation(
    { id: "task-2" },
    [],
    [{ source_type: "task", source_id: "task-2", state: "active" }],
  );
  assert.equal(recommendation.kind, "preserve-radar");
  assert.equal(recommendation.destination, "radar");
  assert.equal(recommendation.recommendedOption, "A");
});

test("task completion recommendation keeps a linked Ticket independent", () => {
  const recommendation = workflow.taskCompletionRecommendation(
    { id: "task-3", ticket_id: "ticket-3" },
    [],
    [],
  );
  assert.equal(recommendation.kind, "linked-ticket");
  assert.equal(recommendation.destination, "tickets");
  assert.equal(recommendation.recommendedOption, "D");
  assert.match(recommendation.detail, /no cierra el caso/);
});

test("task completion recommendation explains when no active continuity was found", () => {
  const recommendation = workflow.taskCompletionRecommendation({ id: "task-4" }, [], []);
  assert.equal(recommendation.kind, "no-open-continuity");
  assert.equal(recommendation.destination, null);
  assert.equal(recommendation.recommendedOption, "E");
  assert.match(recommendation.detail, /acción ejecutable o un compromiso futuro/);
});

test("contextual recommendation suggests outcome verification for recorded service work", () => {
  const recommendation = workflow.taskCompletionRecommendation(
    { id: "task-5", task_type: "Instalación de servicio", title: "Instalar sistema" },
    [],
    [],
  );
  assert.equal(recommendation.recommendedOption, "B");
  assert.match(recommendation.detail, /Confirmá el resultado esperado/);
});

test("explicit next step recommends a linked Task only when no higher-priority signal exists", () => {
  const recommendation = workflow.taskCompletionRecommendation(
    { id: "task-6", title: "Revisar documentos", description: "Próximo paso: llamar para coordinar" },
    [],
    [],
  );
  assert.equal(recommendation.recommendedOption, "C");
  assert.equal(recommendation.actionHint, "llamar para coordinar");
});

test("a recorded service result takes priority over a possible response signal", () => {
  const recommendation = workflow.taskCompletionRecommendation(
    { id: "task-7", title: "Instalar servicio y esperar confirmación del cliente" },
    [],
    [],
  );
  assert.equal(recommendation.recommendedOption, "B");
});

test("existing continuity is recommended before any inferred option", () => {
  const recommendation = workflow.taskCompletionRecommendation(
    { id: "task-8", title: "Instalar servicio" },
    [{ task_id: "task-8", status: "pending" }],
    [],
  );
  assert.equal(recommendation.recommendedOption, "A");
  assert.match(recommendation.detail, /Se conservan/);
});
