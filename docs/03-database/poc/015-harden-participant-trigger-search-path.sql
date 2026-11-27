\set ON_ERROR_STOP on
\pset pager off

\echo '===== SINAU POC — HARDEN PARTICIPANT TRIGGER SEARCH_PATH ====='

BEGIN;

DO $preflight$
DECLARE
    v_assessment_oid oid;
    v_attendance_oid oid;
    v_assessment_def text;
    v_attendance_def text;
    v_trigger_count integer;
BEGIN
    IF current_database() <> 'sinau_design_poc' THEN
        RAISE EXCEPTION 'Wrong database: expected sinau_design_poc, got %',
            current_database();
    END IF;

    IF current_user <> 'postgres' THEN
        RAISE EXCEPTION 'Run this PoC patch as PostgreSQL administrator (current_user=postgres); got %',
            current_user;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'sinau_poc'
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_roles WHERE rolname = 'sinau_rls_test'
    ) THEN
        RAISE EXCEPTION 'Expected PoC roles sinau_poc and sinau_rls_test were not found';
    END IF;

    v_assessment_oid :=
        to_regprocedure('public.poc_check_assessment_participant()');
    v_attendance_oid :=
        to_regprocedure('public.poc_check_attendance_participant()');

    IF v_assessment_oid IS NULL OR v_attendance_oid IS NULL THEN
        RAISE EXCEPTION 'Expected participant trigger function is missing';
    END IF;

    SELECT pg_get_functiondef(v_assessment_oid) INTO v_assessment_def;
    SELECT pg_get_functiondef(v_attendance_oid) INTO v_attendance_def;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_proc p
        WHERE p.oid = v_assessment_oid
          AND pg_get_userbyid(p.proowner) = 'sinau_poc'
          AND p.prorettype = 'trigger'::regtype
          AND NOT p.prosecdef
          AND p.prolang = (SELECT oid FROM pg_language WHERE lanname = 'plpgsql')
    ) THEN
        RAISE EXCEPTION 'Assessment trigger function owner/type/security/language differs from audited PoC baseline';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_proc p
        WHERE p.oid = v_attendance_oid
          AND pg_get_userbyid(p.proowner) = 'sinau_poc'
          AND p.prorettype = 'trigger'::regtype
          AND NOT p.prosecdef
          AND p.prolang = (SELECT oid FROM pg_language WHERE lanname = 'plpgsql')
    ) THEN
        RAISE EXCEPTION 'Attendance trigger function owner/type/security/language differs from audited PoC baseline';
    END IF;

    IF position('p.class_group_id <> NEW.class_group_id' IN v_assessment_def) = 0
       OR position('p.starts_on > NEW.assessment_date' IN v_assessment_def) = 0
       OR position('p.ends_on < NEW.assessment_date' IN v_assessment_def) = 0
       OR position('participant placement is not valid for assessment date/class' IN v_assessment_def) = 0 THEN
        RAISE EXCEPTION 'Assessment trigger body differs from the audited baseline; refusing to replace it';
    END IF;

    IF position('p.class_group_id <> NEW.class_group_id' IN v_attendance_def) = 0
       OR position('p.starts_on > NEW.session_date' IN v_attendance_def) = 0
       OR position('p.ends_on < NEW.session_date' IN v_attendance_def) = 0
       OR position('participant placement is not valid for session date/class' IN v_attendance_def) = 0 THEN
        RAISE EXCEPTION 'Attendance trigger body differs from the audited baseline; refusing to replace it';
    END IF;

    SELECT count(*)
    INTO v_trigger_count
    FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE NOT t.tgisinternal
      AND t.tgenabled = 'O'
      AND (
          (n.nspname = 'public'
           AND c.relname = 'assessment_participants'
           AND t.tgname = 'assessment_participant_temporal_check'
           AND t.tgfoid = v_assessment_oid)
          OR
          (n.nspname = 'public'
           AND c.relname = 'attendance_session_participants'
           AND t.tgname = 'attendance_participant_temporal_check'
           AND t.tgfoid = v_attendance_oid)
      );

    IF v_trigger_count <> 2 THEN
        RAISE EXCEPTION 'Expected both enabled PoC triggers on their audited tables; found % of 2',
            v_trigger_count;
    END IF;

    IF NOT has_table_privilege(
        'sinau_rls_test',
        'public.student_class_placements',
        'SELECT'
    ) THEN
        RAISE EXCEPTION 'sinau_rls_test lacks SELECT on public.student_class_placements; trigger invocation would not have the audited privilege path';
    END IF;

    RAISE NOTICE 'Preflight passed: database, roles, function owners/bodies, trigger bindings, and query-role SELECT privilege match the audited PoC baseline';
END
$preflight$;

CREATE OR REPLACE FUNCTION public.poc_check_assessment_participant()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, pg_temp
AS $function$
DECLARE
    p public.student_class_placements%ROWTYPE;
BEGIN
    SELECT *
    INTO p
    FROM public.student_class_placements
    WHERE tenant_id = NEW.tenant_id
      AND unit_id = NEW.unit_id
      AND id = NEW.placement_id
      AND enrollment_id = NEW.enrollment_id;

    IF NOT FOUND
       OR p.class_group_id <> NEW.class_group_id
       OR p.starts_on > NEW.assessment_date
       OR (p.ends_on IS NOT NULL AND p.ends_on < NEW.assessment_date) THEN
        RAISE EXCEPTION 'participant placement is not valid for assessment date/class';
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.poc_check_attendance_participant()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = pg_catalog, pg_temp
AS $function$
DECLARE
    p public.student_class_placements%ROWTYPE;
BEGIN
    SELECT *
    INTO p
    FROM public.student_class_placements
    WHERE tenant_id = NEW.tenant_id
      AND unit_id = NEW.unit_id
      AND id = NEW.placement_id
      AND enrollment_id = NEW.enrollment_id;

    IF NOT FOUND
       OR p.class_group_id <> NEW.class_group_id
       OR p.starts_on > NEW.session_date
       OR (p.ends_on IS NOT NULL AND p.ends_on < NEW.session_date) THEN
        RAISE EXCEPTION 'participant placement is not valid for session date/class';
    END IF;

    RETURN NEW;
END;
$function$;

DO $postflight$
DECLARE
    v_oid oid;
    v_config text[];
    v_def text;
BEGIN
    FOREACH v_oid IN ARRAY ARRAY[
        to_regprocedure('public.poc_check_assessment_participant()'),
        to_regprocedure('public.poc_check_attendance_participant()')
    ]::oid[]
    LOOP
        SELECT p.proconfig, pg_get_functiondef(p.oid)
        INTO v_config, v_def
        FROM pg_proc p
        WHERE p.oid = v_oid;

        IF NOT coalesce(
            v_config @> ARRAY['search_path=pg_catalog, pg_temp'],
            false
        ) THEN
            RAISE EXCEPTION 'Postflight failed: function % does not have the expected pinned search_path',
                v_oid::regprocedure;
        END IF;

        IF position(
            lower('public.student_class_placements%ROWTYPE')
            IN lower(v_def)
        ) = 0 OR position(
            'from public.student_class_placements'
            IN lower(v_def)
        ) = 0 THEN
            RAISE EXCEPTION 'Postflight failed: function % does not schema-qualify the row type and relation',
                v_oid::regprocedure;
        END IF;
    END LOOP;

    RAISE NOTICE 'Postflight passed: both trigger functions use public-qualified relation/type references and search_path=pg_catalog, pg_temp';
END
$postflight$;

COMMIT;

\echo 'PATCH APPLIED — no application rows, table definitions, roles, grants, or RLS policies were changed.'
\echo 'Next: run 016-test-participant-trigger-temp-shadowing.sql to test both attached triggers under an empty temporary shadow table.'
