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
