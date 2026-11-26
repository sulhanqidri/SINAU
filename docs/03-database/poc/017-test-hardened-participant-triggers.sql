\set ON_ERROR_STOP on
\pset pager off
\echo '===== SINAU POC — HARDENED PARTICIPANT TRIGGER REGRESSION ====='
\echo 'All fixtures, updates, and test objects are inside one transaction that ends with ROLLBACK.'

BEGIN;

DO $preflight$
DECLARE f integer; t integer;
BEGIN
  IF current_database() <> 'sinau_design_poc' OR current_user <> 'postgres' THEN
    RAISE EXCEPTION 'Safety stop: run only as postgres in sinau_design_poc';
  END IF;

  IF EXISTS (SELECT 1 FROM public.tenants)
     OR EXISTS (SELECT 1 FROM public.education_units)
     OR EXISTS (SELECT 1 FROM public.academic_years)
     OR EXISTS (SELECT 1 FROM public.class_groups)
     OR EXISTS (SELECT 1 FROM public.student_enrollments)
     OR EXISTS (SELECT 1 FROM public.student_class_placements)
     OR EXISTS (SELECT 1 FROM public.assessment_definitions)
     OR EXISTS (SELECT 1 FROM public.assessment_participants)
     OR EXISTS (SELECT 1 FROM public.attendance_sessions)
     OR EXISTS (SELECT 1 FROM public.attendance_session_participants) THEN
    RAISE EXCEPTION 'Safety stop: one or more fixture tables are not empty';
  END IF;

  SELECT count(*) INTO f
  FROM pg_proc p
  WHERE p.oid IN (
    to_regprocedure('public.poc_check_assessment_participant()'),
    to_regprocedure('public.poc_check_attendance_participant()')
  )
  AND NOT p.prosecdef
  AND coalesce(p.proconfig @> ARRAY['search_path=pg_catalog, pg_temp'], false);
  IF f <> 2 THEN RAISE EXCEPTION 'Safety stop: both trigger functions are not hardened'; END IF;

  SELECT count(*) INTO t
  FROM pg_trigger g
  JOIN pg_class c ON c.oid=g.tgrelid
  JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE NOT g.tgisinternal AND g.tgenabled='O'
    AND (
      (n.nspname='public' AND c.relname='assessment_participants'
       AND g.tgname='assessment_participant_temporal_check'
       AND g.tgfoid=to_regprocedure('public.poc_check_assessment_participant()'))
      OR
      (n.nspname='public' AND c.relname='attendance_session_participants'
       AND g.tgname='attendance_participant_temporal_check'
       AND g.tgfoid=to_regprocedure('public.poc_check_attendance_participant()'))
    );
  IF t <> 2 THEN RAISE EXCEPTION 'Safety stop: expected two enabled participant triggers'; END IF;

  RAISE NOTICE 'PASS: database, empty-table, function, and trigger preconditions';
END
$preflight$;

CREATE TEMP TABLE student_class_placements (
  id uuid, tenant_id uuid, unit_id uuid, enrollment_id uuid,
  class_group_id uuid, starts_on date, ends_on date
);

DO $shadow$
DECLARE s name;
BEGIN
  SELECT n.nspname INTO s
  FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
  WHERE c.oid=to_regclass('student_class_placements');
  IF s IS NULL OR s NOT LIKE 'pg_temp_%'
     OR to_regclass('public.student_class_placements') IS NULL THEN
    RAISE EXCEPTION 'Temporary shadow precondition failed';
  END IF;
  RAISE NOTICE 'PASS: caller resolves unqualified name to %, permanent public table is distinct',s;
END
$shadow$;

\echo '===== 1. PARENT FIXTURES ====='
INSERT INTO public.tenants VALUES
('00000000-0000-0000-0000-000000000001','trigger-test-tenant');
INSERT INTO public.education_units VALUES
('00000000-0000-0000-0000-000000000001',
 '10000000-0000-0000-0000-000000000001','trigger-test-unit');
INSERT INTO public.academic_years VALUES
('00000000-0000-0000-0000-000000000001',
 '10000000-0000-0000-0000-000000000001',
 '30000000-0000-0000-0000-000000000001','2026-07-01','2027-06-30');
INSERT INTO public.class_groups VALUES
('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
 '40000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','7','VII-TRIGGER-A'),
('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
 '40000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000001','7','VII-TRIGGER-B');
INSERT INTO public.student_enrollments VALUES
('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
 '50000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','STUDENT-TRIGGER-001');
INSERT INTO public.student_class_placements VALUES
('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
 '60000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000001',
 '30000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001',
 '2026-07-01','2026-12-31');

\echo '===== 2. ASSESSMENT / ATTENDANCE PARENTS ====='
INSERT INTO public.assessment_definitions VALUES
('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
 '80000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','2026-10-10',100,1),
('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
 '80000000-0000-0000-0000-000000000002','40000000-0000-0000-0000-000000000002','2026-10-10',100,1),
('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
 '80000000-0000-0000-0000-000000000003','40000000-0000-0000-0000-000000000001','2027-01-10',100,1);
INSERT INTO public.attendance_sessions VALUES
('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
 '70000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','2026-10-10','closed'),
('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
 '70000000-0000-0000-0000-000000000002','40000000-0000-0000-0000-000000000002','2026-10-10','closed'),
('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
 '70000000-0000-0000-0000-000000000003','40000000-0000-0000-0000-000000000001','2027-01-10','closed');

\echo '===== 3. VALID TRIGGER INSERTS AND NO-OP UPDATES ====='
INSERT INTO public.assessment_participants VALUES
('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
 '81000000-0000-0000-0000-000000000001','80000000-0000-0000-0000-000000000001',
 '40000000-0000-0000-0000-000000000001','2026-10-10',
 '50000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001');
INSERT INTO public.attendance_session_participants VALUES
('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
 '71000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001',
 '40000000-0000-0000-0000-000000000001','2026-10-10',
 '50000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001');
DO $valid_updates$
DECLARE r integer;
BEGIN
  UPDATE public.assessment_participants SET assessment_date=assessment_date
  WHERE id='81000000-0000-0000-0000-000000000001';
  GET DIAGNOSTICS r=ROW_COUNT;
  IF r<>1 THEN RAISE EXCEPTION 'Expected one valid assessment UPDATE, got %',r; END IF;

  UPDATE public.attendance_session_participants SET session_date=session_date
  WHERE id='71000000-0000-0000-0000-000000000001';
  GET DIAGNOSTICS r=ROW_COUNT;
  IF r<>1 THEN RAISE EXCEPTION 'Expected one valid attendance UPDATE, got %',r; END IF;

  RAISE NOTICE 'PASS: valid INSERT and no-op UPDATE paths for both participant triggers';
END
$valid_updates$;

\echo '===== 4. NEGATIVE ASSESSMENT TRIGGER CASES ====='
DO $assessment_negative$
BEGIN
  BEGIN
    INSERT INTO public.assessment_participants VALUES
    ('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
     '81000000-0000-0000-0000-000000000002','80000000-0000-0000-0000-000000000002',
     '40000000-0000-0000-0000-000000000002','2026-10-10',
     '50000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001');
    RAISE EXCEPTION 'TEST FAILURE: wrong-class assessment accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM='TEST FAILURE: wrong-class assessment accepted'
       OR SQLERRM<>'participant placement is not valid for assessment date/class' THEN RAISE; END IF;
    RAISE NOTICE 'PASS: assessment wrong-class case rejected by trigger';
  END;

  BEGIN
    INSERT INTO public.assessment_participants VALUES
    ('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
     '81000000-0000-0000-0000-000000000003','80000000-0000-0000-0000-000000000003',
     '40000000-0000-0000-0000-000000000001','2027-01-10',
     '50000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001');
    RAISE EXCEPTION 'TEST FAILURE: out-of-period assessment accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM='TEST FAILURE: out-of-period assessment accepted'
       OR SQLERRM<>'participant placement is not valid for assessment date/class' THEN RAISE; END IF;
    RAISE NOTICE 'PASS: assessment out-of-period case rejected by trigger';
  END;
END
$assessment_negative$;

\echo '===== 5. NEGATIVE ATTENDANCE TRIGGER CASES ====='
DO $attendance_negative$
BEGIN
  BEGIN
    INSERT INTO public.attendance_session_participants VALUES
    ('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
     '71000000-0000-0000-0000-000000000002','70000000-0000-0000-0000-000000000002',
     '40000000-0000-0000-0000-000000000002','2026-10-10',
     '50000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001');
    RAISE EXCEPTION 'TEST FAILURE: wrong-class attendance accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM='TEST FAILURE: wrong-class attendance accepted'
       OR SQLERRM<>'participant placement is not valid for session date/class' THEN RAISE; END IF;
    RAISE NOTICE 'PASS: attendance wrong-class case rejected by trigger';
  END;

  BEGIN
    INSERT INTO public.attendance_session_participants VALUES
    ('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',
     '71000000-0000-0000-0000-000000000003','70000000-0000-0000-0000-000000000003',
     '40000000-0000-0000-0000-000000000001','2027-01-10',
     '50000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001');
    RAISE EXCEPTION 'TEST FAILURE: out-of-period attendance accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM='TEST FAILURE: out-of-period attendance accepted'
       OR SQLERRM<>'participant placement is not valid for session date/class' THEN RAISE; END IF;
    RAISE NOTICE 'PASS: attendance out-of-period case rejected by trigger';
  END;
END
$attendance_negative$;

DO $final_assert$
DECLARE a integer; p integer;
BEGIN
  SELECT count(*) INTO a FROM public.assessment_participants;
  SELECT count(*) INTO p FROM public.attendance_session_participants;
  IF a<>1 OR p<>1 THEN
    RAISE EXCEPTION 'Expected exactly one valid row per participant table; got assessment %, attendance %',a,p;
  END IF;
  RAISE NOTICE 'PASS: exactly one valid row per participant table; invalid rows left no residue';
END
$final_assert$;

ROLLBACK;
\echo '===== ALL PARTICIPANT TRIGGER REGRESSION TESTS PASSED — TRANSACTION ROLLED BACK ====='
\echo 'No synthetic fixture rows or temporary objects were retained.'
