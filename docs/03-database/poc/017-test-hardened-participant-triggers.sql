\set ON_ERROR_STOP on
\pset pager off
\echo '===== SINAU POC — HARDENED PARTICIPANT TRIGGER REGRESSION ====='
\echo 'Uses existing tenant-a/unit-a1/2026-2027 parents; all synthetic rows roll back.'

BEGIN;

-- Prevent another session from changing the target fixture tables between
-- preflight and assertions. Locks are released by the final ROLLBACK.
LOCK TABLE
  public.class_groups,
  public.student_enrollments,
  public.student_class_placements,
  public.assessment_definitions,
  public.assessment_participants,
  public.attendance_sessions,
  public.attendance_session_participants
IN SHARE ROW EXCLUSIVE MODE;

DO $preflight$
DECLARE
  f integer;
  t integer;
BEGIN
  IF current_database() <> 'sinau_design_poc' OR current_user <> 'postgres' THEN
    RAISE EXCEPTION 'Safety stop: run only as postgres in sinau_design_poc';
  END IF;

  -- Reuse the already-present PoC parent chain; never insert duplicate
  -- tenant, education-unit, or academic-year records.
  IF NOT EXISTS (
    SELECT 1
    FROM public.tenants t
    JOIN public.education_units u
      ON u.tenant_id = t.id
    JOIN public.academic_years ay
      ON ay.tenant_id = u.tenant_id
     AND ay.unit_id = u.id
    WHERE t.id = '00000000-0000-0000-0000-000000000001'
      AND t.code = 'tenant-a'
      AND u.id = '10000000-0000-0000-0000-000000000001'
      AND u.code = 'unit-a1'
      AND ay.id = '30000000-0000-0000-0000-000000000001'
      AND ay.starts_on = DATE '2026-07-01'
      AND ay.ends_on = DATE '2027-06-30'
  ) THEN
    RAISE EXCEPTION 'Safety stop: expected tenant-a/unit-a1/2026-2027 parent fixture not found';
  END IF;

  -- The test uses a dedicated UUID namespace and student code. Only exact
  -- key collisions stop the run; unrelated rows in these tables are allowed.
  IF EXISTS (
       SELECT 1 FROM public.class_groups
       WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
         AND unit_id = '10000000-0000-0000-0000-000000000001'
         AND id IN (
           '4a000000-0000-0000-0000-000000000001',
           '4a000000-0000-0000-0000-000000000002'
         )
     )
     OR EXISTS (
       SELECT 1 FROM public.student_enrollments
       WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
         AND unit_id = '10000000-0000-0000-0000-000000000001'
         AND (
           id = '5a000000-0000-0000-0000-000000000001'
           OR student_code = 'TRGREG-20261126-001'
         )
     )
     OR EXISTS (
       SELECT 1 FROM public.student_class_placements
       WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
         AND unit_id = '10000000-0000-0000-0000-000000000001'
         AND id = '6a000000-0000-0000-0000-000000000001'
     )
     OR EXISTS (
       SELECT 1 FROM public.assessment_definitions
       WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
         AND unit_id = '10000000-0000-0000-0000-000000000001'
         AND id IN (
           '8a000000-0000-0000-0000-000000000001',
           '8a000000-0000-0000-0000-000000000002',
           '8a000000-0000-0000-0000-000000000003'
         )
     )
     OR EXISTS (
       SELECT 1 FROM public.attendance_sessions
       WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
         AND unit_id = '10000000-0000-0000-0000-000000000001'
         AND id IN (
           '7a000000-0000-0000-0000-000000000001',
           '7a000000-0000-0000-0000-000000000002',
           '7a000000-0000-0000-0000-000000000003'
         )
     )
     OR EXISTS (
       SELECT 1 FROM public.assessment_participants
       WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
         AND unit_id = '10000000-0000-0000-0000-000000000001'
         AND id IN (
           '81a00000-0000-0000-0000-000000000001',
           '81a00000-0000-0000-0000-000000000002',
           '81a00000-0000-0000-0000-000000000003'
         )
     )
     OR EXISTS (
       SELECT 1 FROM public.attendance_session_participants
       WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
         AND unit_id = '10000000-0000-0000-0000-000000000001'
         AND id IN (
           '71a00000-0000-0000-0000-000000000001',
           '71a00000-0000-0000-0000-000000000002',
           '71a00000-0000-0000-0000-000000000003'
         )
     ) THEN
    RAISE EXCEPTION 'Safety stop: one or more dedicated regression fixture keys already exist';
  END IF;

  IF to_regclass('pg_temp.student_class_placements') IS NOT NULL THEN
    RAISE EXCEPTION 'Safety stop: temporary student_class_placements already exists in this session';
  END IF;

  SELECT count(*) INTO f
  FROM pg_proc p
  WHERE p.oid IN (
    to_regprocedure('public.poc_check_assessment_participant()'),
    to_regprocedure('public.poc_check_attendance_participant()')
  )
    AND NOT p.prosecdef
    AND coalesce(p.proconfig @> ARRAY['search_path=pg_catalog, pg_temp'], false)
    AND position('public.student_class_placements' IN lower(pg_get_functiondef(p.oid))) > 0;

  IF f <> 2 THEN
    RAISE EXCEPTION 'Safety stop: both participant trigger functions are not hardened';
  END IF;

  SELECT count(*) INTO t
  FROM pg_trigger g
  JOIN pg_class c ON c.oid = g.tgrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE NOT g.tgisinternal
    AND g.tgenabled = 'O'
    AND (
      (n.nspname = 'public'
       AND c.relname = 'assessment_participants'
       AND g.tgname = 'assessment_participant_temporal_check'
       AND g.tgfoid = to_regprocedure('public.poc_check_assessment_participant()'))
      OR
      (n.nspname = 'public'
       AND c.relname = 'attendance_session_participants'
       AND g.tgname = 'attendance_participant_temporal_check'
       AND g.tgfoid = to_regprocedure('public.poc_check_attendance_participant()'))
    );

  IF t <> 2 THEN
    RAISE EXCEPTION 'Safety stop: expected two enabled participant triggers';
  END IF;

  RAISE NOTICE 'PASS: database, existing parent fixture, collision, function, and trigger preconditions';
END
$preflight$;

CREATE TEMP TABLE student_class_placements (
  id uuid,
  tenant_id uuid,
  unit_id uuid,
  enrollment_id uuid,
  class_group_id uuid,
  starts_on date,
  ends_on date
);

DO $shadow$
DECLARE
  s name;
BEGIN
  SELECT n.nspname INTO s
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE c.oid = to_regclass('student_class_placements');

  IF s IS NULL
     OR s NOT LIKE 'pg_temp_%'
     OR to_regclass('public.student_class_placements') IS NULL
     OR to_regclass('student_class_placements') <> to_regclass('pg_temp.student_class_placements') THEN
    RAISE EXCEPTION 'Temporary shadow precondition failed';
  END IF;

  RAISE NOTICE 'PASS: unqualified caller name resolves to %, permanent public relation remains distinct', s;
END
$shadow$;

\echo '===== 1. SYNTHETIC ACADEMIC FIXTURES USING EXISTING PARENTS ====='

-- Existing parents:
-- tenant-a  = 00000000-0000-0000-0000-000000000001
-- unit-a1   = 10000000-0000-0000-0000-000000000001
-- year 26/27= 30000000-0000-0000-0000-000000000001

INSERT INTO public.class_groups VALUES
(
  '00000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '4a000000-0000-0000-0000-000000000001',
  '30000000-0000-0000-0000-000000000001',
  '7',
  'VII-TRGREG-A'
),
(
  '00000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '4a000000-0000-0000-0000-000000000002',
  '30000000-0000-0000-0000-000000000001',
  '7',
  'VII-TRGREG-B'
);

INSERT INTO public.student_enrollments VALUES (
  '00000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '5a000000-0000-0000-0000-000000000001',
  '30000000-0000-0000-0000-000000000001',
  'TRGREG-20261126-001'
);

INSERT INTO public.student_class_placements VALUES (
  '00000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '6a000000-0000-0000-0000-000000000001',
  '5a000000-0000-0000-0000-000000000001',
  '30000000-0000-0000-0000-000000000001',
  '4a000000-0000-0000-0000-000000000001',
  DATE '2026-07-01',
  DATE '2026-12-31'
);

\echo '===== 2. ASSESSMENT / ATTENDANCE PARENT FIXTURES ====='

INSERT INTO public.assessment_definitions VALUES
(
  '00000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '8a000000-0000-0000-0000-000000000001',
  '4a000000-0000-0000-0000-000000000001',
  DATE '2026-10-10',
  100,
  1
),
(
  '00000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '8a000000-0000-0000-0000-000000000002',
  '4a000000-0000-0000-0000-000000000002',
  DATE '2026-10-10',
  100,
  1
),
(
  '00000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '8a000000-0000-0000-0000-000000000003',
  '4a000000-0000-0000-0000-000000000001',
  DATE '2027-01-10',
  100,
  1
);

INSERT INTO public.attendance_sessions VALUES
(
  '00000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '7a000000-0000-0000-0000-000000000001',
  '4a000000-0000-0000-0000-000000000001',
  DATE '2026-10-10',
  'closed'
),
(
  '00000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '7a000000-0000-0000-0000-000000000002',
  '4a000000-0000-0000-0000-000000000002',
  DATE '2026-10-10',
  'closed'
),
(
  '00000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '7a000000-0000-0000-0000-000000000003',
  '4a000000-0000-0000-0000-000000000001',
  DATE '2027-01-10',
  'closed'
);

\echo '===== 3. VALID TRIGGER INSERTS AND NO-OP UPDATES ====='

INSERT INTO public.assessment_participants VALUES (
  '00000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '81a00000-0000-0000-0000-000000000001',
  '8a000000-0000-0000-0000-000000000001',
  '4a000000-0000-0000-0000-000000000001',
  DATE '2026-10-10',
  '5a000000-0000-0000-0000-000000000001',
  '6a000000-0000-0000-0000-000000000001'
);

INSERT INTO public.attendance_session_participants VALUES (
  '00000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  '71a00000-0000-0000-0000-000000000001',
  '7a000000-0000-0000-0000-000000000001',
  '4a000000-0000-0000-0000-000000000001',
  DATE '2026-10-10',
  '5a000000-0000-0000-0000-000000000001',
  '6a000000-0000-0000-0000-000000000001'
);

DO $valid_updates$
DECLARE
  r integer;
BEGIN
  UPDATE public.assessment_participants
  SET assessment_date = assessment_date
  WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
    AND unit_id = '10000000-0000-0000-0000-000000000001'
    AND id = '81a00000-0000-0000-0000-000000000001';
  GET DIAGNOSTICS r = ROW_COUNT;
  IF r <> 1 THEN
    RAISE EXCEPTION 'Expected one valid assessment UPDATE, got %', r;
  END IF;

  UPDATE public.attendance_session_participants
  SET session_date = session_date
  WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
    AND unit_id = '10000000-0000-0000-0000-000000000001'
    AND id = '71a00000-0000-0000-0000-000000000001';
  GET DIAGNOSTICS r = ROW_COUNT;
  IF r <> 1 THEN
    RAISE EXCEPTION 'Expected one valid attendance UPDATE, got %', r;
  END IF;

  RAISE NOTICE 'PASS: valid INSERT and no-op UPDATE paths for both participant triggers';
END
$valid_updates$;

\echo '===== 4. NEGATIVE ASSESSMENT TRIGGER CASES ====='

DO $assessment_negative$
BEGIN
  BEGIN
    INSERT INTO public.assessment_participants VALUES (
      '00000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000001',
      '81a00000-0000-0000-0000-000000000002',
      '8a000000-0000-0000-0000-000000000002',
      '4a000000-0000-0000-0000-000000000002',
      DATE '2026-10-10',
      '5a000000-0000-0000-0000-000000000001',
      '6a000000-0000-0000-0000-000000000001'
    );
    RAISE EXCEPTION 'TEST FAILURE: wrong-class assessment accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'TEST FAILURE: wrong-class assessment accepted'
       OR SQLERRM <> 'participant placement is not valid for assessment date/class' THEN
      RAISE;
    END IF;
    RAISE NOTICE 'PASS: assessment wrong-class case rejected by trigger';
  END;

  BEGIN
    INSERT INTO public.assessment_participants VALUES (
      '00000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000001',
      '81a00000-0000-0000-0000-000000000003',
      '8a000000-0000-0000-0000-000000000003',
      '4a000000-0000-0000-0000-000000000001',
      DATE '2027-01-10',
      '5a000000-0000-0000-0000-000000000001',
      '6a000000-0000-0000-0000-000000000001'
    );
    RAISE EXCEPTION 'TEST FAILURE: out-of-period assessment accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'TEST FAILURE: out-of-period assessment accepted'
       OR SQLERRM <> 'participant placement is not valid for assessment date/class' THEN
      RAISE;
    END IF;
    RAISE NOTICE 'PASS: assessment out-of-period case rejected by trigger';
  END;
END
$assessment_negative$;

\echo '===== 5. NEGATIVE ATTENDANCE TRIGGER CASES ====='

DO $attendance_negative$
BEGIN
  BEGIN
    INSERT INTO public.attendance_session_participants VALUES (
      '00000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000001',
      '71a00000-0000-0000-0000-000000000002',
      '7a000000-0000-0000-0000-000000000002',
      '4a000000-0000-0000-0000-000000000002',
      DATE '2026-10-10',
      '5a000000-0000-0000-0000-000000000001',
      '6a000000-0000-0000-0000-000000000001'
    );
    RAISE EXCEPTION 'TEST FAILURE: wrong-class attendance accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'TEST FAILURE: wrong-class attendance accepted'
       OR SQLERRM <> 'participant placement is not valid for session date/class' THEN
      RAISE;
    END IF;
    RAISE NOTICE 'PASS: attendance wrong-class case rejected by trigger';
  END;

  BEGIN
    INSERT INTO public.attendance_session_participants VALUES (
      '00000000-0000-0000-0000-000000000001',
      '10000000-0000-0000-0000-000000000001',
      '71a00000-0000-0000-0000-000000000003',
      '7a000000-0000-0000-0000-000000000003',
      '4a000000-0000-0000-0000-000000000001',
      DATE '2027-01-10',
      '5a000000-0000-0000-0000-000000000001',
      '6a000000-0000-0000-0000-000000000001'
    );
    RAISE EXCEPTION 'TEST FAILURE: out-of-period attendance accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM = 'TEST FAILURE: out-of-period attendance accepted'
       OR SQLERRM <> 'participant placement is not valid for session date/class' THEN
      RAISE;
    END IF;
    RAISE NOTICE 'PASS: attendance out-of-period case rejected by trigger';
  END;
END
$attendance_negative$;

DO $final_assert$
DECLARE
  assessment_valid integer;
  attendance_valid integer;
  assessment_invalid integer;
  attendance_invalid integer;
BEGIN
  SELECT count(*) INTO assessment_valid
  FROM public.assessment_participants
  WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
    AND unit_id = '10000000-0000-0000-0000-000000000001'
    AND id = '81a00000-0000-0000-0000-000000000001';

  SELECT count(*) INTO attendance_valid
  FROM public.attendance_session_participants
  WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
    AND unit_id = '10000000-0000-0000-0000-000000000001'
    AND id = '71a00000-0000-0000-0000-000000000001';

  SELECT count(*) INTO assessment_invalid
  FROM public.assessment_participants
  WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
    AND unit_id = '10000000-0000-0000-0000-000000000001'
    AND id IN (
      '81a00000-0000-0000-0000-000000000002',
      '81a00000-0000-0000-0000-000000000003'
    );

  SELECT count(*) INTO attendance_invalid
  FROM public.attendance_session_participants
  WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
    AND unit_id = '10000000-0000-0000-0000-000000000001'
    AND id IN (
      '71a00000-0000-0000-0000-000000000002',
      '71a00000-0000-0000-0000-000000000003'
    );

  IF assessment_valid <> 1
     OR attendance_valid <> 1
     OR assessment_invalid <> 0
     OR attendance_invalid <> 0 THEN
    RAISE EXCEPTION
      'Fixture assertion failed: valid assessment %, valid attendance %, invalid assessment %, invalid attendance %',
      assessment_valid, attendance_valid, assessment_invalid, attendance_invalid;
  END IF;

  RAISE NOTICE 'PASS: one valid row per participant table; all four invalid fixture IDs absent';
END
$final_assert$;

ROLLBACK;

\echo '===== ALL PARTICIPANT TRIGGER REGRESSION TESTS PASSED — TRANSACTION ROLLED BACK ====='
\echo 'No synthetic academic rows, locks, or temporary objects were retained.'
