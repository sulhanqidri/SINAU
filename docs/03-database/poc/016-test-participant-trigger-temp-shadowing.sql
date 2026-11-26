\set ON_ERROR_STOP on
\pset pager off

\echo '===== SINAU POC — PARTICIPANT TRIGGER TEMP-SHADOW REGRESSION TEST ====='
\echo 'This test creates one empty temporary shadow table, invokes each existing BEFORE trigger with a no-op UPDATE when fixture rows exist, then ROLLBACKs.'

BEGIN;

DO $preflight$
DECLARE
    v_count integer;
BEGIN
    IF current_database() <> 'sinau_design_poc' THEN
        RAISE EXCEPTION 'Wrong database: expected sinau_design_poc, got %',
            current_database();
    END IF;

    IF current_user <> 'postgres' THEN
        RAISE EXCEPTION 'Run this PoC regression test as PostgreSQL administrator (current_user=postgres); got %',
            current_user;
    END IF;

    SELECT count(*)
    INTO v_count
    FROM pg_proc p
    WHERE p.oid IN (
        to_regprocedure('public.poc_check_assessment_participant()'),
        to_regprocedure('public.poc_check_attendance_participant()')
    )
    AND coalesce(
        p.proconfig @> ARRAY['search_path=pg_catalog, pg_temp'],
        false
    );

    IF v_count <> 2 THEN
        RAISE EXCEPTION 'Apply 015-harden-participant-trigger-search-path.sql first; only % of 2 functions are hardened',
            v_count;
    END IF;
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

\echo
\echo '===== 1. CONFIRM THE SESSION HAS A TEMPORARY SHADOW ====='

SELECT
    current_user,
    current_schemas(true) AS effective_search_schemas,
    pg_my_temp_schema()::regnamespace AS temporary_schema,
    to_regclass('student_class_placements') AS unqualified_relation,
    to_regclass('public.student_class_placements') AS permanent_relation,
    to_regtype('student_class_placements') AS unqualified_row_type;

DO $assert_shadow$
DECLARE
    v_schema name;
BEGIN
    SELECT n.nspname
    INTO v_schema
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.oid = to_regclass('student_class_placements');

    IF v_schema IS NULL OR v_schema NOT LIKE 'pg_temp_%' THEN
        RAISE EXCEPTION 'Test setup failed: unqualified name does not resolve to the test temporary table';
    END IF;

    IF to_regclass('public.student_class_placements') IS NULL THEN
        RAISE EXCEPTION 'Permanent public.student_class_placements relation is missing';
    END IF;

    RAISE NOTICE 'PASS: the caller session resolves the unqualified name to %, while the permanent table remains separately addressable',
        v_schema;
END
$assert_shadow$;

\echo
\echo '===== 2. INVOKE ASSESSMENT TRIGGER ====='

DO $test_assessment$
DECLARE
    v_ctid tid;
    v_rows integer;
BEGIN
    SELECT ctid
    INTO v_ctid
    FROM public.assessment_participants
    ORDER BY ctid
    LIMIT 1;

    IF v_ctid IS NULL THEN
        RAISE NOTICE 'SKIP: assessment_participants has no fixture row; trigger invocation was not tested';
        RETURN;
    END IF;

    UPDATE public.assessment_participants
    SET assessment_date = assessment_date
    WHERE ctid = v_ctid;

    GET DIAGNOSTICS v_rows = ROW_COUNT;

    IF v_rows <> 1 THEN
        RAISE EXCEPTION 'Assessment trigger test expected one row update, got %',
            v_rows;
    END IF;

    RAISE NOTICE 'PASS: assessment BEFORE trigger completed with an empty temporary shadow table present';
END
$test_assessment$;

\echo
\echo '===== 3. INVOKE ATTENDANCE TRIGGER ====='

DO $test_attendance$
DECLARE
    v_ctid tid;
    v_rows integer;
BEGIN
    SELECT ctid
    INTO v_ctid
    FROM public.attendance_session_participants
    ORDER BY ctid
    LIMIT 1;

    IF v_ctid IS NULL THEN
        RAISE NOTICE 'SKIP: attendance_session_participants has no fixture row; trigger invocation was not tested';
        RETURN;
    END IF;

    UPDATE public.attendance_session_participants
    SET session_date = session_date
    WHERE ctid = v_ctid;

    GET DIAGNOSTICS v_rows = ROW_COUNT;

    IF v_rows <> 1 THEN
        RAISE EXCEPTION 'Attendance trigger test expected one row update, got %',
            v_rows;
    END IF;

    RAISE NOTICE 'PASS: attendance BEFORE trigger completed with an empty temporary shadow table present';
END
$test_attendance$;

ROLLBACK;

\echo
\echo '===== REGRESSION TEST COMPLETE — TRANSACTION ROLLED BACK ====='
\echo 'Review PASS/SKIP notices above. Each PASS proves that the attached trigger completed despite the empty temporary shadow table.'
\echo 'A SKIP means the corresponding participant table needs a valid PoC fixture row before that trigger can be accepted as tested.'
