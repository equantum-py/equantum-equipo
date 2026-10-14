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
  recommendedOption: "A" | "B" | "C" | "D" | "E";
  actionHint?: string;
};

/**
 * Gives a deterministic, explainable completion hint from existing records.
 * It does not create/close followups, tickets, or tasks and does not rank NBA
 * actions. Completion itself remains the existing one-click task transition.
 */
export function taskCompletionRecommendation(
  task: {
    id: string;
    title?: string;
    task_type?: string;
    description?: string | null;
    ticket_id?: string | null;
    client_id?: string | null;
    project_id?: string | null;
    active_service_id?: string | null;
  },
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
      recommendedOption: "A",
      actionHint: "Revisar primero el seguimiento existente",
    };
  }
  if (activeRadar.length > 0) {
    return {
      kind: "preserve-radar",
      title: "La tarea se completó; Radar conserva la continuidad activa.",
      detail: "El seguimiento existente permanece abierto hasta que su motivo deje de requerir continuidad.",
      destination: "radar",
      recommendedOption: "A",
      actionHint: "Revisar primero la continuidad ya abierta",
    };
  }

  const sourceText = `${task.task_type ?? ""} ${task.title ?? ""} ${task.description ?? ""}`;
  const explicitNextStep = task.description?.match(/pr[oó]ximo paso\s*:\s*([^\n.]+)/i)?.[1]?.trim();
  if (
    task.active_service_id ||
    /servicio|instalaci[oó]n|implementar|implementaci[oó]n|campa[nñ]a|optimizaci[oó]n|puesta en marcha|entrega|mejora/i.test(sourceText)
  ) {
    return {
      kind: "no-open-continuity",
      title: "Conviene comprobar el resultado después de completar esta tarea.",
      detail: "La recomendación se basa en el tipo o contexto registrado. Confirmá el resultado esperado y cuándo observarlo antes de guardar una verificación.",
      destination: null,
      recommendedOption: "B",
      actionHint: "Verificar el resultado de esta acción",
    };
  }
  if (explicitNextStep) {
    return {
      kind: "no-open-continuity",
      title: "La descripción ya señala una próxima acción.",
      detail: "Podés convertir ese paso explícito en una nueva Tarea vinculada; Triage calculará su prioridad oficial.",
      destination: null,
      recommendedOption: "C",
      actionHint: explicitNextStep,
    };
  }
  if (/presupuesto|propuesta|respuesta|confirmaci[oó]n|aprobaci[oó]n|tercero|proveedor|cliente/i.test(sourceText)) {
    return {
      kind: "no-open-continuity",
      title: "Puede quedar una respuesta de otra persona por recibir.",
      detail: "Registrá la espera solamente si hay un compromiso real; indicá responsable y fecha o condición para revisar.",
      destination: "radar",
      recommendedOption: "A",
      actionHint: "Esperar una respuesta o confirmación",
    };
  }
  if (task.ticket_id) {
    return {
      kind: "linked-ticket",
      title: "La tarea se completó; el Ticket mantiene su propio estado.",
      detail: "Completar la tarea no cierra el caso del cliente ni cambia su historial.",
      destination: "tickets",
      recommendedOption: "D",
      actionHint: "Revisar el proceso en el módulo dueño",
    };
  }
  if (task.client_id || task.project_id) {
    return {
      kind: "no-open-continuity",
      title: "La tarea está vinculada a otro proceso.",
      detail: "Revisá ese proceso en su módulo dueño; completar la tarea no actualiza ventas, servicios ni proyectos por sí solo.",
      destination: null,
      recommendedOption: "D",
      actionHint: "Abrir el proceso relacionado",
    };
  }
  return {
    kind: "no-open-continuity",
    title: "La tarea se completó y no hay continuidad activa registrada.",
    detail: "Si quedó una acción ejecutable o un compromiso futuro, registralo en Tareas o Radar según corresponda.",
    destination: null,
    recommendedOption: "E",
    actionHint: "Nada más por ahora",
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
