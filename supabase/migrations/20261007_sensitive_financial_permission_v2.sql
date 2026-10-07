BEGIN;

DROP TRIGGER IF EXISTS trg_guard_sensitive_financial_permission
ON public.user_permissions;

DROP FUNCTION IF EXISTS public.guard_sensitive_financial_permission();

CREATE OR REPLACE FUNCTION public.set_financial_info_permission(
  p_user_id uuid,
  p_enabled boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_actor uuid;
  v_master boolean;
BEGIN
  v_actor := auth.uid();

  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'authenticated actor required'
      USING ERRCODE='42501';
  END IF;

  SELECT p.active AND p.is_master
  INTO v_master
  FROM public.profiles p
  WHERE p.id=v_actor;

  IF COALESCE(v_master,false) IS NOT TRUE THEN
    RAISE EXCEPTION 'only Master can change financial_info'
      USING ERRCODE='42501';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id=p_user_id
  ) THEN
    RAISE EXCEPTION 'target user not found';
  END IF;

  UPDATE public.user_permissions
  SET financial_info=p_enabled
  WHERE user_id=p_user_id;

  IF NOT FOUND THEN
    INSERT INTO public.user_permissions(
      user_id,
      financial_info
    )
    VALUES(
      p_user_id,
      p_enabled
    );
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION
public.set_financial_info_permission(uuid,boolean)
FROM PUBLIC;

REVOKE ALL ON FUNCTION
public.set_financial_info_permission(uuid,boolean)
FROM anon;

GRANT EXECUTE ON FUNCTION
public.set_financial_info_permission(uuid,boolean)
TO authenticated;

COMMIT;
