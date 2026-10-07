BEGIN;

GRANT SELECT
ON public.radar_operational_v2
TO authenticated;

COMMIT;
