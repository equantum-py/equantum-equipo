export type OfficialTaskStatus =
  | "pending"
  | "in_progress"
  | "waiting"
  | "blocked"
  | "completed"
  | "cancelled";

export type RadarHealth =
  | "protected"
  | "requires_review"
  | "unprotected"
  | "requires_review_unprotected"
  | "closed";

export type TaskCompletionRecommendation = {
  kind: "preserve-followup" | "preserve-radar" | "linked-ticket" | "no-open-continuity";
  title: string;
  detail: string;
  destination: "radar" | "tickets" | null;
};

/**
 * Gives a deterministic, explainable completion hint from existing records.
 * It does not create/close followups, tickets, or tasks and does not rank NBA
 * actions. Completion itself remains the existing one-click task transition.
 */
export function taskCompletionRecommendation(
  task: { id: string; ticket_id?: string | null },
  followups: Array<{ task_id: string; status: string }>,
  radarItems: Array<{ source_type: string; source_id: string; state: string }>,
): TaskCompletionRecommendation {
  const pendingFollowups = followups.filter(
    (item) => item.task_id === task.id && item.status === "pending",
  );
  const activeRadar = radarItems.filter(
    (item) => item.source_type === "task" && item.source_id === task.id && item.state === "active",
  );

  if (pendingFollowups.length > 0) {
    return {
      kind: "preserve-followup",
      title: "La tarea se completó; el seguimiento sigue en Radar.",
      detail: `Hay ${pendingFollowups.length} seguimiento(s) pendiente(s). Se conservan y no se crea otro automáticamente.`,
      destination: "radar",
    };
  }
  if (activeRadar.length > 0) {
    return {
      kind: "preserve-radar",
      title: "La tarea se completó; Radar conserva la continuidad activa.",
      detail: "El seguimiento existente permanece abierto hasta que su motivo deje de requerir continuidad.",
      destination: "radar",
    };
  }
  if (task.ticket_id) {
    return {
      kind: "linked-ticket",
      title: "La tarea se completó; el Ticket mantiene su propio estado.",
      detail: "Completar la tarea no cierra el caso del cliente ni cambia su historial.",
      destination: "tickets",
    };
  }
  return {
    kind: "no-open-continuity",
    title: "La tarea se completó y no hay continuidad activa registrada.",
    detail: "Si quedó una acción ejecutable o un compromiso futuro, registralo en Tareas o Radar según corresponda.",
    destination: null,
  };
}

const legacyStatus: Record<string, OfficialTaskStatus> = {
  pending: "pending",
  in_progress: "in_progress",
  paused: "in_progress",
  waiting_client: "waiting",
  waiting: "waiting",
  blocked: "blocked",
  completed: "completed",
  cancelled: "cancelled",
};

export function officialTaskStatus(status: string): OfficialTaskStatus | null {
  return legacyStatus[status] ?? null;
}

export function taskStatusLabel(status: string): string {
  const labels: Record<OfficialTaskStatus, string> = {
    pending: "Por hacer",
    in_progress: "En curso",
    waiting: "Esperando",
    blocked: "Bloqueada",
    completed: "Completada",
    cancelled: "Cancelada",
  };
  const official = officialTaskStatus(status);
  return official ? labels[official] : "Estado por revisar";
}

export function taskPriorityLabel(priority: string): string {
  // The old V2 rule persists `low`; the rector's human-facing taxonomy has
  // four bands, so low is presented as Normal without altering the score.
  if (priority === "low") return "Normal";
  const labels: Record<string, string> = {
    normal: "Normal",
    medium: "Media",
    high: "Alta",
    critical: "Crítica",
  };
  return labels[priority] ?? "Sin clasificar";
}

export function radarHealth(item: {
  state: string;
  is_overdue: boolean;
  next_action: string | null;
  next_review_at: string | null;
  condition_text: string | null;
  responsible_id: string | null;
}): RadarHealth {
  if (item.state !== "active") return "closed";
  const unprotected =
    !item.responsible_id ||
    !item.next_action?.trim() ||
    (!item.next_review_at && !item.condition_text?.trim()) ||
    item.condition_text?.trim().toLowerCase() === "seguimiento operativo";
  if (item.is_overdue && unprotected) return "requires_review_unprotected";
  if (item.is_overdue) return "requires_review";
  if (unprotected) return "unprotected";
  return "protected";
}

export function radarHealthFlags(health: RadarHealth) {
  return {
    requiresReview: health === "requires_review" || health === "requires_review_unprotected",
    unprotected: health === "unprotected" || health === "requires_review_unprotected",
    protected: health === "protected",
    closed: health === "closed",
  };
}

export function canTransitionTask(
  from: string,
  to: OfficialTaskStatus,
): boolean {
  const current = officialTaskStatus(from);
  if (!current) return false;
  if (current === to) return false;
  const transitions: Record<OfficialTaskStatus, OfficialTaskStatus[]> = {
    pending: ["in_progress", "waiting", "blocked", "cancelled"],
    in_progress: ["pending", "waiting", "blocked", "completed", "cancelled"],
    waiting: ["pending", "in_progress", "blocked", "cancelled"],
    blocked: ["pending", "in_progress", "waiting", "cancelled"],
    completed: ["pending", "in_progress"],
    // D2 approved: a cancelled task can be recovered only to pending; the
    // server requires an explicit reason and records the transition.
    cancelled: ["pending"],
  };
  return transitions[current].includes(to);
}

export function validateTransitionContext(
  status: OfficialTaskStatus,
  context: {
    reason?: string;
    waitingOn?: string;
    reviewAt?: string;
    condition?: string;
    from?: OfficialTaskStatus | null;
    waitingSatisfied?: boolean;
    waitingResolutionEvidence?: string;
  },
): string | null {
  if (status === "waiting" && !context.waitingOn?.trim()) {
    return "Indicá qué dependencia estamos esperando.";
  }
  if (
    status === "waiting" &&
    !context.reviewAt &&
    !context.condition?.trim()
  ) {
    return "Indicá una fecha de revisión o una condición para volver a revisar.";
  }
  if (status === "blocked" && !context.reason?.trim()) {
    return "Describí el impedimento que bloquea el avance.";
  }
  if (status === "cancelled" && !context.reason?.trim()) {
    return "Indicá el motivo de cancelación.";
  }
  if (
    (status === "pending" || status === "in_progress") &&
    (context.from === "completed" || (context.from === "cancelled" && status === "pending")) &&
    !context.reason?.trim()
  ) {
    return "Indicá el motivo de reapertura.";
  }
  if (context.from === "waiting" && context.waitingSatisfied && !context.waitingResolutionEvidence?.trim()) {
    return "Describí la evidencia de que la dependencia se cumplió.";
  }
  if (context.from === "waiting" && !context.waitingSatisfied && context.waitingResolutionEvidence?.trim()) {
    return "Confirmá la resolución antes de registrar su evidencia.";
  }
  return null;
}
