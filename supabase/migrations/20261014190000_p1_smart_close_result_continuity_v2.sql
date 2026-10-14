-- P1 Smart Close / Continuity v2 — migration draft for independent review.
-- NOT APPLIED. Do not apply until independent database/security review approves it.
-- Scope: transactional A/B/C continuity and result verification only.
-- No changes to production, task status transitions, RLS on existing tables, or NBA claims.
BEGIN;

CREATE TABLE public.task_continuity_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_task_id uuid NOT NULL REFERENCES public.tasks(id) ON DELETE RESTRICT,
  option_code text NOT NULL CHECK (option_code IN ('A','B','C')),
  actor_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  request_id uuid NOT NULL,
  request_payload jsonb NOT NULL,
  followup_id uuid REFERENCES public.followups(id) ON DELETE RESTRICT,
  child_task_id uuid REFERENCES public.tasks(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT task_continuity_actions_actor_request_uq UNIQUE (actor_id, request_id),
  CONSTRAINT task_continuity_actions_id_followup_uq UNIQUE (id, followup_id),
  CONSTRAINT task_continuity_actions_shape_ck CHECK (
    (option_code IN ('A','B') AND followup_id IS NOT NULL AND child_task_id IS NULL)
    OR (option_code = 'C' AND followup_id IS NULL AND child_task_id IS NOT NULL)
  )
);

CREATE TABLE public.task_outcome_verifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  continuity_action_id uuid NOT NULL UNIQUE,
  source_task_id uuid NOT NULL REFERENCES public.tasks(id) ON DELETE RESTRICT,
  followup_id uuid NOT NULL UNIQUE REFERENCES public.followups(id) ON DELETE RESTRICT,
  expected_result text NOT NULL CHECK (length(btrim(expected_result)) > 0),
  observation_method text NOT NULL CHECK (length(btrim(observation_method)) > 0),
  expected_source text NOT NULL CHECK (length(btrim(expected_source)) > 0),
  conclusion text NOT NULL DEFAULT 'pending'
    CHECK (conclusion IN ('pending','achieved','not_achieved','inconclusive')),
  observed_result text,
  last_evidence_source text,
  last_recorded_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  last_recorded_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT task_outcome_verifications_action_followup_fk
    FOREIGN KEY (continuity_action_id, followup_id)
    REFERENCES public.task_continuity_actions(id, followup_id) ON DELETE RESTRICT,
  CONSTRAINT task_outcome_verifications_observation_ck CHECK (
    (conclusion = 'pending' AND observed_result IS NULL AND last_evidence_source IS NULL AND last_recorded_at IS NULL)
    OR
    (conclusion <> 'pending'
      AND observed_result IS NOT NULL AND length(btrim(observed_result)) > 0
      AND last_evidence_source IS NOT NULL AND length(btrim(last_evidence_source)) > 0
      AND last_recorded_at IS NOT NULL)
  )
);

CREATE TABLE public.task_outcome_verification_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  verification_id uuid NOT NULL REFERENCES public.task_outcome_verifications(id) ON DELETE RESTRICT,
  actor_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  request_id uuid NOT NULL,
  observed_result text NOT NULL CHECK (length(btrim(observed_result)) > 0),
  evidence_source text NOT NULL CHECK (length(btrim(evidence_source)) > 0),
  conclusion text NOT NULL CHECK (conclusion IN ('achieved','not_achieved','inconclusive')),
  recorded_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT task_outcome_verification_events_actor_request_uq UNIQUE (actor_id, request_id)
);

CREATE INDEX task_continuity_actions_source_created_idx
  ON public.task_continuity_actions(source_task_id, created_at);
CREATE INDEX task_continuity_actions_child_idx
  ON public.task_continuity_actions(child_task_id) WHERE child_task_id IS NOT NULL;
CREATE INDEX task_continuity_actions_followup_idx
  ON public.task_continuity_actions(followup_id) WHERE followup_id IS NOT NULL;
CREATE INDEX task_outcome_verification_events_verification_idx
  ON public.task_outcome_verification_events(verification_id, recorded_at);

ALTER TABLE public.task_continuity_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_outcome_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_outcome_verification_events ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.task_continuity_actions FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.task_outcome_verifications FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.task_outcome_verification_events FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.task_continuity_actions,
                public.task_outcome_verifications,
                public.task_outcome_verification_events TO authenticated;

CREATE POLICY task_continuity_actions_internal_scoped_read
ON public.task_continuity_actions FOR SELECT TO authenticated
USING (
  public.is_internal_user()
  AND EXISTS (SELECT 1 FROM public.tasks t WHERE t.id = source_task_id)
);
CREATE POLICY task_outcome_verifications_internal_scoped_read
ON public.task_outcome_verifications FOR SELECT TO authenticated
USING (
  public.is_internal_user()
  AND EXISTS (SELECT 1 FROM public.tasks t WHERE t.id = source_task_id)
);
CREATE POLICY task_outcome_verification_events_internal_scoped_read
ON public.task_outcome_verification_events FOR SELECT TO authenticated
USING (
  public.is_internal_user()
  AND EXISTS (
    SELECT 1
    FROM public.task_outcome_verifications v
    JOIN public.tasks t ON t.id = v.source_task_id
    WHERE v.id = verification_id
  )
);

CREATE OR REPLACE FUNCTION public.create_task_continuity(
  p_source_task_id uuid,
  p_option text,
  p_request_id uuid,
  p_action text DEFAULT NULL,
  p_condition text DEFAULT NULL,
  p_review_at timestamptz DEFAULT NULL,
  p_expected_result text DEFAULT NULL,
  p_observation_method text DEFAULT NULL,
  p_expected_source text DEFAULT NULL,
  p_new_task_title text DEFAULT NULL,
  p_new_task_context text DEFAULT NULL,
  p_new_task_due_date date DEFAULT NULL
)
RETURNS TABLE(action_id uuid, followup_id uuid, child_task_id uuid, replayed boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_task public.tasks%ROWTYPE;
  v_payload jsonb;
  v_existing public.task_continuity_actions%ROWTYPE;
  v_action_id uuid;
  v_followup_id uuid;
  v_child_task_id uuid;
  v_title text;
  v_notes text;
BEGIN
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'TASK_CONTINUITY_AUTH_REQUIRED' USING ERRCODE = '42501';
  END IF;
  IF NOT coalesce(public.is_internal_user(), false)
     OR NOT coalesce(public.is_active_user(), false) THEN
    RAISE EXCEPTION 'TASK_CONTINUITY_INTERNAL_ONLY' USING ERRCODE = '42501';
  END IF;
  IF p_source_task_id IS NULL OR p_request_id IS NULL OR p_option IS NULL
     OR p_option NOT IN ('A','B','C') THEN
    RAISE EXCEPTION 'TASK_CONTINUITY_INVALID_REQUEST' USING ERRCODE = '22023';
  END IF;
  IF NOT public.can_write_task(p_source_task_id) THEN
    RAISE EXCEPTION 'TASK_CONTINUITY_FORBIDDEN' USING ERRCODE = '42501';
  END IF;

  v_payload := jsonb_strip_nulls(jsonb_build_object(
    'source_task_id', p_source_task_id, 'option', p_option,
    'action', nullif(btrim(p_action), ''),
    'condition', nullif(btrim(p_condition), ''),
    'review_at', p_review_at, 'expected_result', nullif(btrim(p_expected_result), ''),
    'observation_method', nullif(btrim(p_observation_method), ''),
    'expected_source', nullif(btrim(p_expected_source), ''),
    'new_task_title', nullif(btrim(p_new_task_title), ''),
    'new_task_context', nullif(btrim(p_new_task_context), ''),
    'new_task_due_date', p_new_task_due_date
  ));

  -- Serialize retries and equivalent requests for the same parent Task.
  PERFORM pg_advisory_xact_lock(hashtextextended(p_source_task_id::text, 0));
  PERFORM pg_advisory_xact_lock(hashtextextended(v_actor::text || ':' || p_request_id::text, 0));

  SELECT * INTO v_task
  FROM public.tasks t
  WHERE t.id = p_source_task_id
  FOR UPDATE;
  IF NOT FOUND OR v_task.archived_at IS NOT NULL OR v_task.status::text <> 'completed' THEN
    RAISE EXCEPTION 'TASK_CONTINUITY_SOURCE_NOT_COMPLETED' USING ERRCODE = '22023';
  END IF;
  -- Re-check authorization after acquiring the parent row lock.
  IF NOT public.can_write_task(p_source_task_id) THEN
    RAISE EXCEPTION 'TASK_CONTINUITY_FORBIDDEN' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_existing
  FROM public.task_continuity_actions a
  WHERE a.actor_id = v_actor AND a.request_id = p_request_id;
  IF FOUND THEN
    IF v_existing.source_task_id <> p_source_task_id
       OR v_existing.request_payload IS DISTINCT FROM v_payload THEN
      RAISE EXCEPTION 'TASK_CONTINUITY_IDEMPOTENCY_KEY_REUSED' USING ERRCODE = '22023';
    END IF;
    RETURN QUERY SELECT v_existing.id, v_existing.followup_id, v_existing.child_task_id, true;
    RETURN;
  END IF;

  IF p_option IN ('A','B') THEN
    IF nullif(btrim(p_action), '') IS NULL OR (p_review_at IS NULL AND nullif(btrim(p_condition), '') IS NULL) THEN
      RAISE EXCEPTION 'TASK_CONTINUITY_ACTION_AND_REVIEW_REQUIRED' USING ERRCODE = '22023';
    END IF;
    IF p_option = 'B' AND (
      nullif(btrim(p_expected_result), '') IS NULL
      OR nullif(btrim(p_observation_method), '') IS NULL
      OR nullif(btrim(p_expected_source), '') IS NULL
    ) THEN
      RAISE EXCEPTION 'TASK_CONTINUITY_VERIFICATION_PLAN_REQUIRED' USING ERRCODE = '22023';
    END IF;

    IF EXISTS (
      SELECT 1 FROM public.followups f
      WHERE f.task_id = p_source_task_id
        AND f.status::text = 'pending'
        AND lower(regexp_replace(btrim(f.next_action), '\s+', ' ', 'g'))
            = lower(regexp_replace(btrim(p_action), '\s+', ' ', 'g'))
    ) THEN
      RAISE EXCEPTION 'TASK_CONTINUITY_DUPLICATE_EXISTS' USING ERRCODE = '23505';
    END IF;

    v_notes := concat_ws(E'\n',
      'Continuidad posterior a tarea completada ' || p_source_task_id::text,
      CASE WHEN nullif(btrim(p_condition), '') IS NOT NULL THEN 'Condición: ' || btrim(p_condition) END,
      CASE WHEN p_option = 'B' THEN 'Resultado esperado: ' || btrim(p_expected_result) END,
      CASE WHEN p_option = 'B' THEN 'Cómo observar: ' || btrim(p_observation_method) END,
      CASE WHEN p_option = 'B' THEN 'Fuente prevista: ' || btrim(p_expected_source) END
    );

    INSERT INTO public.followups(
      task_id, responsible_id, status, next_action, next_followup_at,
      last_movement_at, notes
    ) VALUES (
      p_source_task_id, v_actor, 'pending', btrim(p_action), p_review_at, now(), v_notes
    ) RETURNING id INTO v_followup_id;

    INSERT INTO public.task_continuity_actions(
      source_task_id, option_code, actor_id, request_id, request_payload, followup_id
    ) VALUES (
      p_source_task_id, p_option, v_actor, p_request_id, v_payload, v_followup_id
    ) RETURNING id INTO v_action_id;

    IF p_option = 'B' THEN
      INSERT INTO public.task_outcome_verifications(
        continuity_action_id, source_task_id, followup_id, expected_result,
        observation_method, expected_source
      ) VALUES (
        v_action_id, p_source_task_id, v_followup_id, btrim(p_expected_result),
        btrim(p_observation_method), btrim(p_expected_source)
      );
    END IF;

    INSERT INTO public.task_events(task_id, actor_id, event_type, detail)
    VALUES (
      p_source_task_id, v_actor,
      CASE WHEN p_option = 'A' THEN 'continuity_wait_created' ELSE 'continuity_verification_created' END,
      btrim(p_action)
    );
  ELSIF p_option = 'C' THEN
    v_title := nullif(btrim(p_new_task_title), '');
    IF v_title IS NULL OR NOT public.has_task_permission('create_tasks') THEN
      RAISE EXCEPTION 'TASK_CONTINUITY_CREATE_TASK_FORBIDDEN_OR_INVALID' USING ERRCODE = '42501';
    END IF;

    IF EXISTS (
      SELECT 1
      FROM public.task_continuity_actions a
      JOIN public.tasks child ON child.id = a.child_task_id
      WHERE a.source_task_id = p_source_task_id
        AND a.option_code = 'C'
        AND child.archived_at IS NULL
        AND child.status::text NOT IN ('completed','cancelled')
        AND lower(regexp_replace(btrim(child.title), '\s+', ' ', 'g')) =
            lower(regexp_replace(v_title, '\s+', ' ', 'g'))
        AND child.due_date IS NOT DISTINCT FROM p_new_task_due_date
        AND lower(regexp_replace(btrim(coalesce(a.request_payload->>'new_task_context','')), '\s+', ' ', 'g')) =
            lower(regexp_replace(btrim(coalesce(p_new_task_context,'')), '\s+', ' ', 'g'))
    ) THEN
      RAISE EXCEPTION 'TASK_CONTINUITY_DUPLICATE_EXISTS' USING ERRCODE = '23505';
    END IF;

    INSERT INTO public.tasks(
      title, original_title, area, task_type, created_by, assignee_id,
      client_id, project_id, ticket_id, active_service_id, due_date, description
    ) VALUES (
      v_title, v_title, v_task.area, v_task.task_type, v_actor, v_actor,
      v_task.client_id, v_task.project_id, v_task.ticket_id, v_task.active_service_id,
      p_new_task_due_date,
      concat_ws(E'\n\n',
        'Continuidad de la tarea completada ' || p_source_task_id::text || ': ' || v_task.title,
        nullif(btrim(p_new_task_context), ''),
        CASE WHEN nullif(btrim(v_task.description), '') IS NOT NULL
          THEN 'Contexto conservado: ' || v_task.description END
      )
    ) RETURNING id INTO v_child_task_id;

    INSERT INTO public.task_continuity_actions(
      source_task_id, option_code, actor_id, request_id, request_payload, child_task_id
    ) VALUES (
      p_source_task_id, 'C', v_actor, p_request_id, v_payload, v_child_task_id
    ) RETURNING id INTO v_action_id;

    INSERT INTO public.task_events(task_id, actor_id, event_type, detail)
    VALUES
      (v_child_task_id, v_actor, 'continuity_from_task', 'Continuidad de Tarea ' || p_source_task_id::text),
      (p_source_task_id, v_actor, 'continuity_task_created', 'Nueva Tarea ' || v_child_task_id::text);
  END IF;

  RETURN QUERY SELECT v_action_id, v_followup_id, v_child_task_id, false;
END;
$$;

CREATE OR REPLACE FUNCTION public.record_task_outcome_verification(
  p_verification_id uuid,
  p_request_id uuid,
  p_observed_result text,
  p_evidence_source text,
  p_conclusion text
)
RETURNS TABLE(verification_id uuid, replayed boolean)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_actor uuid := auth.uid();
  v_verification public.task_outcome_verifications%ROWTYPE;
  v_task public.tasks%ROWTYPE;
  v_existing public.task_outcome_verification_events%ROWTYPE;
  v_payload jsonb;
BEGIN
  IF v_actor IS NULL OR NOT coalesce(public.is_internal_user(), false)
     OR NOT coalesce(public.is_active_user(), false) THEN
    RAISE EXCEPTION 'TASK_OUTCOME_INTERNAL_ONLY' USING ERRCODE = '42501';
  END IF;
  IF p_verification_id IS NULL OR p_request_id IS NULL
     OR nullif(btrim(p_observed_result), '') IS NULL
     OR nullif(btrim(p_evidence_source), '') IS NULL
     OR p_conclusion IS NULL
     OR p_conclusion NOT IN ('achieved','not_achieved','inconclusive') THEN
    RAISE EXCEPTION 'TASK_OUTCOME_INVALID_OBSERVATION' USING ERRCODE = '22023';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(v_actor::text || ':' || p_request_id::text, 0));
  SELECT * INTO v_verification
  FROM public.task_outcome_verifications v
  WHERE v.id = p_verification_id
  FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'TASK_OUTCOME_FORBIDDEN' USING ERRCODE = '42501';
  END IF;
  SELECT * INTO v_task
  FROM public.tasks t
  WHERE t.id = v_verification.source_task_id
  FOR UPDATE;
  IF NOT FOUND OR NOT public.can_write_task(v_verification.source_task_id) THEN
    RAISE EXCEPTION 'TASK_OUTCOME_FORBIDDEN' USING ERRCODE = '42501';
  END IF;
  IF v_task.status::text <> 'completed' OR v_task.archived_at IS NOT NULL THEN
    RAISE EXCEPTION 'TASK_OUTCOME_TASK_NOT_COMPLETED' USING ERRCODE = '22023';
  END IF;

  v_payload := jsonb_build_object(
    'verification_id', p_verification_id,
    'observed_result', btrim(p_observed_result),
    'evidence_source', btrim(p_evidence_source),
    'conclusion', p_conclusion
  );

  SELECT * INTO v_existing
  FROM public.task_outcome_verification_events e
  WHERE e.actor_id = v_actor AND e.request_id = p_request_id;
  IF FOUND THEN
    IF v_existing.verification_id <> p_verification_id
       OR v_existing.observed_result <> btrim(p_observed_result)
       OR v_existing.evidence_source <> btrim(p_evidence_source)
       OR v_existing.conclusion <> p_conclusion THEN
      RAISE EXCEPTION 'TASK_OUTCOME_IDEMPOTENCY_KEY_REUSED' USING ERRCODE = '22023';
    END IF;
    RETURN QUERY SELECT p_verification_id, true;
    RETURN;
  END IF;

  INSERT INTO public.task_outcome_verification_events(
    verification_id, actor_id, request_id, observed_result, evidence_source, conclusion
  ) VALUES (
    p_verification_id, v_actor, p_request_id, btrim(p_observed_result),
    btrim(p_evidence_source), p_conclusion
  );

  UPDATE public.task_outcome_verifications v
  SET conclusion = p_conclusion,
      observed_result = btrim(p_observed_result),
      last_evidence_source = btrim(p_evidence_source),
      last_recorded_by = v_actor,
      last_recorded_at = now(),
      updated_at = now()
  WHERE v.id = p_verification_id;

  RETURN QUERY SELECT p_verification_id, false;
END;
$$;

ALTER FUNCTION public.create_task_continuity(uuid,text,uuid,text,text,timestamptz,text,text,text,text,text,date) OWNER TO postgres;
ALTER FUNCTION public.record_task_outcome_verification(uuid,uuid,text,text,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.create_task_continuity(uuid,text,uuid,text,text,timestamptz,text,text,text,text,text,date) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.record_task_outcome_verification(uuid,uuid,text,text,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_task_continuity(uuid,text,uuid,text,text,timestamptz,text,text,text,text,text,date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_task_outcome_verification(uuid,uuid,text,text,text) TO authenticated;

COMMIT;
