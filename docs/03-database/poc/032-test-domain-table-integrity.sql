-- SINAU PostgreSQL 18 Design PoC
-- Rollback-only domain CRUD / constraint / RLS regression for eleven
-- tenant+unit tables, following read-only inventory 031.
--
-- Run ONLY as PostgreSQL superuser postgres against sinau_design_poc.
-- Uses the v1 transaction-bound synthetic token for tenant A / unit A1.
-- All fixture IDs and unique values are preflighted while target tables
-- are locked. Every DML statement is rolled back; no persistent DDL,
-- policy, role, grant, or application data changes are made.
--
-- Participant temporal trigger shadowing/negative cases are already covered
-- by script 017. This script only exercises the valid trigger paths and
-- tests the remaining domain constraints plus per-table RLS CRUD behavior.

\set ON_ERROR_STOP on
\pset pager off
\echo '===== SINAU POC — DOMAIN TABLE CRUD / INTEGRITY REGRESSION ====='

DO $guard$
DECLARE
    v_count pg_catalog.int8;
BEGIN
    IF pg_catalog.current_database() <> 'sinau_design_poc'
       OR session_user <> 'postgres'
       OR current_user <> 'postgres'
       OR NOT EXISTS (
           SELECT 1
           FROM pg_catalog.pg_roles
           WHERE rolname = current_user
             AND rolsuper
       ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: run only as PostgreSQL superuser postgres in sinau_design_poc';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_roles
        WHERE rolname = 'sinau_rls_test'
          AND NOT rolcanlogin
          AND NOT rolsuper
          AND NOT rolbypassrls
    ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: sinau_rls_test must be NOLOGIN, non-superuser, without BYPASSRLS';
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
    FROM pg_catalog.pg_class AS c
    JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = ANY (ARRAY[
          'assessment_definitions',
          'assessment_participants',
          'attendance_corrections',
          'attendance_record_revisions',
          'attendance_records',
          'attendance_session_participants',
          'attendance_sessions',
          'class_groups',
          'student_class_placements',
          'student_enrollments',
          'student_scores'
      ]::pg_catalog.text[])
      AND c.relrowsecurity
      AND c.relforcerowsecurity;

    IF v_count <> 11 THEN
        RAISE EXCEPTION
            'SAFETY STOP: expected 11 target tables with ENABLE/FORCE RLS, found %',
            v_count;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.tenants AS t
        JOIN public.education_units AS u
          ON u.tenant_id = t.id
        JOIN public.academic_years AS ay
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
        RAISE EXCEPTION
            'SAFETY STOP: expected tenant-A / unit-A1 / academic-year fixture missing';
    END IF;

    RAISE NOTICE 'PASS preflight: database, test role, RLS flags, and parent fixture';
END
$guard$;

BEGIN ISOLATION LEVEL READ COMMITTED;

-- Serialize the preflight/write/rollback window against other PoC writers.
LOCK TABLE
    public.academic_years,
    public.assessment_definitions,
    public.assessment_participants,
    public.attendance_corrections,
    public.attendance_record_revisions,
    public.attendance_records,
    public.attendance_session_participants,
    public.attendance_sessions,
    public.class_groups,
    public.student_class_placements,
    public.student_enrollments,
    public.student_scores
IN SHARE ROW EXCLUSIVE MODE;

DO $fixture_preflight$
DECLARE
    v_item record;
    v_exists pg_catalog.bool;
BEGIN
    FOR v_item IN
        SELECT *
        FROM (VALUES
            ('class_groups', '4c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('class_groups', '4c000000-0000-0000-0000-000000000002'::pg_catalog.uuid),
            ('student_enrollments', '5c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('student_enrollments', '5c000000-0000-0000-0000-000000000002'::pg_catalog.uuid),
            ('student_class_placements', '6c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('student_class_placements', '6c000000-0000-0000-0000-000000000002'::pg_catalog.uuid),
            ('attendance_sessions', '7c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_sessions', '7c000000-0000-0000-0000-000000000002'::pg_catalog.uuid),
            ('attendance_session_participants', '71c00000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_session_participants', '71c00000-0000-0000-0000-000000000002'::pg_catalog.uuid),
            ('attendance_records', '9c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('assessment_definitions', '8c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('assessment_definitions', '8c000000-0000-0000-0000-000000000002'::pg_catalog.uuid),
            ('assessment_participants', '81c00000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('assessment_participants', '81c00000-0000-0000-0000-000000000002'::pg_catalog.uuid),
            ('student_scores', 'ac000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_corrections', 'bc000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_corrections', 'bc000000-0000-0000-0000-000000000002'::pg_catalog.uuid),
            ('attendance_record_revisions', 'cc000000-0000-0000-0000-000000000001'::pg_catalog.uuid)
        ) AS fixtures(table_name, row_id)
    LOOP
        EXECUTE pg_catalog.format(
            'SELECT EXISTS (SELECT 1 FROM public.%I WHERE id = $1)',
            v_item.table_name
        )
        INTO v_exists
        USING v_item.row_id;

        IF v_exists THEN
            RAISE EXCEPTION
                'SAFETY STOP: reserved fixture ID already exists in public.%',
                v_item.table_name;
        END IF;
    END LOOP;

    IF EXISTS (
        SELECT 1
        FROM public.student_enrollments
        WHERE student_code IN (
            'RLS032-ENROLL-001',
            'RLS032-ENROLL-UPDATED'
        )
    ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: reserved student_code already exists';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.attendance_corrections
        WHERE idempotency_key IN (
            'RLS032-IDEMPOTENCY-001',
            'RLS032-IDEMPOTENCY-002'
        )
    ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: reserved correction idempotency key already exists';
    END IF;

    RAISE NOTICE 'PASS preflight: all reserved IDs and unique values are unused';
END
$fixture_preflight$;

CREATE TEMP TABLE poc_signed_context_input (
    token pg_catalog.text NOT NULL
) ON COMMIT DROP;

SELECT pg_catalog.pg_current_xact_id()::pg_catalog.text AS signer_xid \gset
\echo 'Connection XID: ' :signer_xid
\prompt 'In terminal B, sign a v1 token for this exact XID and install it at /run/authfreshness-context.token. Press ENTER when ready: ' ready

\copy pg_temp.poc_signed_context_input(token) FROM '/run/authfreshness-context.token' WITH (FORMAT text)

DO $install_context$
DECLARE
    v_count pg_catalog.int4;
    v_token pg_catalog.text;
BEGIN
    SELECT pg_catalog.count(*), pg_catalog.min(token)
      INTO v_count, v_token
      FROM pg_temp.poc_signed_context_input;

    IF v_count <> 1 OR v_token IS NULL OR v_token = '' THEN
        RAISE EXCEPTION
            'Expected exactly one non-empty signed token; found %',
            v_count;
    END IF;

    PERFORM pg_catalog.set_config('app.context_token', v_token, true);
    RAISE NOTICE 'PASS: transaction-bound token installed without printing token';
END
$install_context$;

SET LOCAL ROLE sinau_rls_test;

DO $role_check$
BEGIN
    IF current_user <> 'sinau_rls_test' THEN
        RAISE EXCEPTION
            'Expected current_user sinau_rls_test, got %',
            current_user;
    END IF;
    RAISE NOTICE 'PASS: domain DML runs under the non-owner RLS test role';
END
$role_check$;

\echo '===== 1. CREATE VALID DOMAIN FIXTURES ACROSS ALL ELEVEN TABLES ====='

DO $valid_inserts$
BEGIN
    INSERT INTO public.class_groups
        (tenant_id, unit_id, id, academic_year_id, grade_code, name)
    VALUES (
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001',
        '4c000000-0000-0000-0000-000000000001',
        '30000000-0000-0000-0000-000000000001',
        '8',
        'VIII-RLS032'
    );

    INSERT INTO public.student_enrollments
        (tenant_id, unit_id, id, academic_year_id, student_code)
    VALUES (
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001',
        '5c000000-0000-0000-0000-000000000001',
        '30000000-0000-0000-0000-000000000001',
        'RLS032-ENROLL-001'
    );

    INSERT INTO public.student_class_placements
        (tenant_id, unit_id, id, enrollment_id, academic_year_id,
         class_group_id, starts_on, ends_on)
    VALUES (
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001',
        '6c000000-0000-0000-0000-000000000001',
        '5c000000-0000-0000-0000-000000000001',
        '30000000-0000-0000-0000-000000000001',
        '4c000000-0000-0000-0000-000000000001',
        DATE '2026-07-01',
        DATE '2026-12-31'
    );

    INSERT INTO public.attendance_sessions
        (tenant_id, unit_id, id, class_group_id, session_date, status)
    VALUES (
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001',
        '7c000000-0000-0000-0000-000000000001',
        '4c000000-0000-0000-0000-000000000001',
        DATE '2026-11-27',
        'open'
    );

    INSERT INTO public.attendance_session_participants
        (tenant_id, unit_id, id, session_id, class_group_id,
         session_date, enrollment_id, placement_id)
    VALUES (
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001',
        '71c00000-0000-0000-0000-000000000001',
        '7c000000-0000-0000-0000-000000000001',
        '4c000000-0000-0000-0000-000000000001',
        DATE '2026-11-27',
        '5c000000-0000-0000-0000-000000000001',
        '6c000000-0000-0000-0000-000000000001'
    );

    INSERT INTO public.attendance_records
        (tenant_id, unit_id, id, participant_id, enrollment_id, attendance_status)
    VALUES (
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001',
        '9c000000-0000-0000-0000-000000000001',
        '71c00000-0000-0000-0000-000000000001',
        '5c000000-0000-0000-0000-000000000001',
        'present'
    );

    INSERT INTO public.assessment_definitions
        (tenant_id, unit_id, id, class_group_id, assessment_date, max_score, scoring_rule_version)
    VALUES (
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001',
        '8c000000-0000-0000-0000-000000000001',
        '4c000000-0000-0000-0000-000000000001',
        DATE '2026-11-27',
        100,
        1
    );

    INSERT INTO public.assessment_participants
        (tenant_id, unit_id, id, assessment_id, class_group_id,
         assessment_date, enrollment_id, placement_id)
    VALUES (
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001',
        '81c00000-0000-0000-0000-000000000001',
        '8c000000-0000-0000-0000-000000000001',
        '4c000000-0000-0000-0000-000000000001',
        DATE '2026-11-27',
        '5c000000-0000-0000-0000-000000000001',
        '6c000000-0000-0000-0000-000000000001'
    );

    INSERT INTO public.student_scores
        (tenant_id, unit_id, id, participant_id, result_status,
         score_value, workflow_status, finalized_at)
    VALUES (
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001',
        'ac000000-0000-0000-0000-000000000001',
        '81c00000-0000-0000-0000-000000000001',
        'scored',
        95,
        'draft',
        NULL
    );

    INSERT INTO public.attendance_corrections
        (tenant_id, unit_id, id, attendance_record_id, idempotency_key,
         requested_status, review_status, applied_revision_id)
    VALUES (
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001',
        'bc000000-0000-0000-0000-000000000001',
        '9c000000-0000-0000-0000-000000000001',
        'RLS032-IDEMPOTENCY-001',
        'late',
        'requested',
        NULL
    );

    INSERT INTO public.attendance_record_revisions
        (tenant_id, unit_id, id, attendance_record_id, revision_no,
         source_correction_id, attendance_status)
    VALUES (
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001',
        'cc000000-0000-0000-0000-000000000001',
        '9c000000-0000-0000-0000-000000000001',
        1,
        'bc000000-0000-0000-0000-000000000001',
        'late'
    );

    UPDATE public.attendance_corrections
       SET applied_revision_id = 'cc000000-0000-0000-0000-000000000001'
     WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
       AND unit_id = '10000000-0000-0000-0000-000000000001'
       AND id = 'bc000000-0000-0000-0000-000000000001';

    RAISE NOTICE 'PASS: valid parent/child rows inserted across all 11 domain tables';
    RAISE NOTICE 'PASS: attendance correction and revision linked through deferred FK';
END
$valid_inserts$;

-- Force the initially-deferred correction -> revision FK to be checked now,
-- rather than relying only on a rollback before commit-time validation.
SET CONSTRAINTS correction_applied_revision_fk IMMEDIATE;
\echo 'PASS: deferred correction/revision FK validated with SET CONSTRAINTS IMMEDIATE'

\echo '===== 2. SAME-SCOPE SELECT / UPDATE / DELETE READINESS ====='

DO $crud_checks$
DECLARE
    v_item record;
    v_count pg_catalog.int8;
    v_rows pg_catalog.int8;
BEGIN
    FOR v_item IN
        SELECT *
        FROM (VALUES
            ('class_groups', '4c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('student_enrollments', '5c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('student_class_placements', '6c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_sessions', '7c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_session_participants', '71c00000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_records', '9c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('assessment_definitions', '8c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('assessment_participants', '81c00000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('student_scores', 'ac000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_corrections', 'bc000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_record_revisions', 'cc000000-0000-0000-0000-000000000001'::pg_catalog.uuid)
        ) AS fixtures(table_name, row_id)
    LOOP
        EXECUTE pg_catalog.format(
            'SELECT pg_catalog.count(*) FROM public.%I WHERE tenant_id = $1 AND unit_id = $2 AND id = $3',
            v_item.table_name
        )
        INTO v_count
        USING
            '00000000-0000-0000-0000-000000000001'::pg_catalog.uuid,
            '10000000-0000-0000-0000-000000000001'::pg_catalog.uuid,
            v_item.row_id;

        IF v_count <> 1 THEN
            RAISE EXCEPTION
                'FAIL same-scope SELECT on %, expected one row, got %',
                v_item.table_name, v_count;
        END IF;
    END LOOP;

    UPDATE public.class_groups
       SET name = 'VIII-RLS032-UPDATED'
     WHERE id = '4c000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'class_groups UPDATE failed'; END IF;

    UPDATE public.student_enrollments
       SET student_code = 'RLS032-ENROLL-UPDATED'
     WHERE id = '5c000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'student_enrollments UPDATE failed'; END IF;

    UPDATE public.student_class_placements
       SET ends_on = DATE '2026-12-30'
     WHERE id = '6c000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'student_class_placements UPDATE failed'; END IF;

    UPDATE public.attendance_sessions
       SET status = 'closed'
     WHERE id = '7c000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'attendance_sessions UPDATE failed'; END IF;

    UPDATE public.attendance_session_participants
       SET session_date = DATE '2026-11-27'
     WHERE id = '71c00000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'attendance_session_participants UPDATE failed'; END IF;

    UPDATE public.attendance_records
       SET attendance_status = 'late'
     WHERE id = '9c000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'attendance_records UPDATE failed'; END IF;

    UPDATE public.assessment_definitions
       SET max_score = 99
     WHERE id = '8c000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'assessment_definitions UPDATE failed'; END IF;

    UPDATE public.assessment_participants
       SET assessment_date = DATE '2026-11-27'
     WHERE id = '81c00000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'assessment_participants UPDATE failed'; END IF;

    UPDATE public.student_scores
       SET score_value = 96,
           workflow_status = 'finalized',
           finalized_at = pg_catalog.clock_timestamp()
     WHERE id = 'ac000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'student_scores UPDATE failed'; END IF;

    UPDATE public.attendance_corrections
       SET review_status = 'approved'
     WHERE id = 'bc000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'attendance_corrections UPDATE failed'; END IF;

    UPDATE public.attendance_record_revisions
       SET attendance_status = 'late'
     WHERE id = 'cc000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'attendance_record_revisions UPDATE failed'; END IF;

    RAISE NOTICE 'PASS: SELECT and same-scope UPDATE succeeded on all eleven tables';
END
$crud_checks$;

\echo '===== 3. RLS WITH CHECK DENIAL ON REMAINING NON-TRIGGER TABLES ====='

DO $cross_unit_updates$
DECLARE
    v_item record;
    v_rows pg_catalog.int8;
BEGIN
    -- Participant tables have BEFORE UPDATE temporal triggers. Their trigger
    -- behavior is covered separately by script 017. The other nine tables
    -- exercise direct RLS WITH CHECK denial when scope is changed to unit A2.
    FOR v_item IN
        SELECT *
        FROM (VALUES
            ('class_groups', '4c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('student_enrollments', '5c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('student_class_placements', '6c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_sessions', '7c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_records', '9c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('assessment_definitions', '8c000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('student_scores', 'ac000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_corrections', 'bc000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_record_revisions', 'cc000000-0000-0000-0000-000000000001'::pg_catalog.uuid)
        ) AS fixtures(table_name, row_id)
    LOOP
        BEGIN
            EXECUTE pg_catalog.format(
                'UPDATE public.%I SET unit_id = $1 WHERE tenant_id = $2 AND unit_id = $3 AND id = $4',
                v_item.table_name
            )
            USING
                '10000000-0000-0000-0000-000000000002'::pg_catalog.uuid,
                '00000000-0000-0000-0000-000000000001'::pg_catalog.uuid,
                '10000000-0000-0000-0000-000000000001'::pg_catalog.uuid,
                v_item.row_id;

            GET DIAGNOSTICS v_rows = ROW_COUNT;
            IF v_rows <> 1 THEN
                RAISE EXCEPTION USING
                    ERRCODE = 'P0001',
                    MESSAGE = pg_catalog.format(
                        'FAIL: cross-unit UPDATE unexpectedly affected %s rows on %s',
                        v_rows, v_item.table_name
                    );
            END IF;

            RAISE EXCEPTION USING
                ERRCODE = 'P0001',
                MESSAGE = pg_catalog.format(
                    'FAIL: cross-unit UPDATE accepted on %s',
                    v_item.table_name
                );
        EXCEPTION
            WHEN insufficient_privilege THEN
                RAISE NOTICE
                    'PASS: cross-unit UPDATE rejected by RLS on %',
                    v_item.table_name;
        END;
    END LOOP;
END
$cross_unit_updates$;

\echo '===== 4. DOMAIN CONSTRAINT NEGATIVE CASES ====='

DO $domain_negative$
BEGIN
    -- Class group must reference an existing academic year.
    BEGIN
        INSERT INTO public.class_groups
            (tenant_id, unit_id, id, academic_year_id, grade_code, name)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000001',
            '4c000000-0000-0000-0000-000000000002',
            '30000000-0000-0000-0000-000000000099',
            '8',
            'INVALID-YEAR-RLS032'
        );
        RAISE EXCEPTION USING ERRCODE = 'P0001',
            MESSAGE = 'FAIL: class_groups accepted missing academic year';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'PASS: class_groups rejects missing academic year';
    END;

    -- Student code is unique within one tenant/unit.
    BEGIN
        INSERT INTO public.student_enrollments
            (tenant_id, unit_id, id, academic_year_id, student_code)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000001',
            '5c000000-0000-0000-0000-000000000002',
            '30000000-0000-0000-0000-000000000001',
            'RLS032-ENROLL-UPDATED'
        );
        RAISE EXCEPTION USING ERRCODE = 'P0001',
            MESSAGE = 'FAIL: duplicate student_code accepted';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'PASS: duplicate student_code rejected';
    END;

    -- The exclusion constraint rejects overlapping placement periods
    -- for the same tenant, unit, and enrollment.
    BEGIN
        INSERT INTO public.student_class_placements
            (tenant_id, unit_id, id, enrollment_id, academic_year_id,
             class_group_id, starts_on, ends_on)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000001',
            '6c000000-0000-0000-0000-000000000002',
            '5c000000-0000-0000-0000-000000000001',
            '30000000-0000-0000-0000-000000000001',
            '4c000000-0000-0000-0000-000000000001',
            DATE '2026-11-01',
            DATE '2027-02-01'
        );
        RAISE EXCEPTION USING ERRCODE = 'P0001',
            MESSAGE = 'FAIL: overlapping student placement accepted';
    EXCEPTION WHEN exclusion_violation THEN
        RAISE NOTICE 'PASS: overlapping student placement rejected';
    END;

    -- Assessment maximum score must be positive.
    BEGIN
        INSERT INTO public.assessment_definitions
            (tenant_id, unit_id, id, class_group_id, assessment_date, max_score, scoring_rule_version)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000001',
            '8c000000-0000-0000-0000-000000000002',
            '4c000000-0000-0000-0000-000000000001',
            DATE '2026-11-27',
            0,
            1
        );
        RAISE EXCEPTION USING ERRCODE = 'P0001',
            MESSAGE = 'FAIL: non-positive assessment max_score accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS: assessment max_score must be positive';
    END;

    -- Attendance session state is constrained to the declared workflow values.
    BEGIN
        INSERT INTO public.attendance_sessions
            (tenant_id, unit_id, id, class_group_id, session_date, status)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000001',
            '7c000000-0000-0000-0000-000000000002',
            '4c000000-0000-0000-0000-000000000001',
            DATE '2026-11-27',
            'pending'
        );
        RAISE EXCEPTION USING ERRCODE = 'P0001',
            MESSAGE = 'FAIL: invalid attendance session status accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS: invalid attendance session status rejected';
    END;

    -- The same student cannot participate twice in one attendance session.
    BEGIN
        INSERT INTO public.attendance_session_participants
            (tenant_id, unit_id, id, session_id, class_group_id,
             session_date, enrollment_id, placement_id)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000001',
            '71c00000-0000-0000-0000-000000000002',
            '7c000000-0000-0000-0000-000000000001',
            '4c000000-0000-0000-0000-000000000001',
            DATE '2026-11-27',
            '5c000000-0000-0000-0000-000000000001',
            '6c000000-0000-0000-0000-000000000001'
        );
        RAISE EXCEPTION USING ERRCODE = 'P0001',
            MESSAGE = 'FAIL: duplicate attendance session participant accepted';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'PASS: duplicate attendance session participant rejected';
    END;

    -- Attendance status is a constrained enumeration.
    BEGIN
        UPDATE public.attendance_records
           SET attendance_status = 'unknown'
         WHERE id = '9c000000-0000-0000-0000-000000000001';
        RAISE EXCEPTION USING ERRCODE = 'P0001',
            MESSAGE = 'FAIL: invalid attendance status accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS: invalid attendance status rejected';
    END;

    -- Assessment participant uniqueness is per assessment and enrollment.
    BEGIN
        INSERT INTO public.assessment_participants
            (tenant_id, unit_id, id, assessment_id, class_group_id,
             assessment_date, enrollment_id, placement_id)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000001',
            '81c00000-0000-0000-0000-000000000002',
            '8c000000-0000-0000-0000-000000000001',
            '4c000000-0000-0000-0000-000000000001',
            DATE '2026-11-27',
            '5c000000-0000-0000-0000-000000000001',
            '6c000000-0000-0000-0000-000000000001'
        );
        RAISE EXCEPTION USING ERRCODE = 'P0001',
            MESSAGE = 'FAIL: duplicate assessment participant accepted';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'PASS: duplicate assessment participant rejected';
    END;

    -- A score marked scored must have a non-negative value.
    BEGIN
        UPDATE public.student_scores
           SET result_status = 'scored',
               score_value = NULL
         WHERE id = 'ac000000-0000-0000-0000-000000000001';
        RAISE EXCEPTION USING ERRCODE = 'P0001',
            MESSAGE = 'FAIL: scored result without score_value accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS: scored result without score_value rejected';
    END;

    -- Finalized scores must carry finalized_at.
    BEGIN
        UPDATE public.student_scores
           SET workflow_status = 'finalized',
               finalized_at = NULL
         WHERE id = 'ac000000-0000-0000-0000-000000000001';
        RAISE EXCEPTION USING ERRCODE = 'P0001',
            MESSAGE = 'FAIL: finalized score without finalized_at accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS: finalized score without finalized_at rejected';
    END;

    -- Correction review state and idempotency are constrained.
    BEGIN
        UPDATE public.attendance_corrections
           SET review_status = 'unknown'
         WHERE id = 'bc000000-0000-0000-0000-000000000001';
        RAISE EXCEPTION USING ERRCODE = 'P0001',
            MESSAGE = 'FAIL: invalid attendance correction review state accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS: invalid correction review state rejected';
    END;

    BEGIN
        INSERT INTO public.attendance_corrections
            (tenant_id, unit_id, id, attendance_record_id, idempotency_key,
             requested_status, review_status, applied_revision_id)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000001',
            'bc000000-0000-0000-0000-000000000002',
            '9c000000-0000-0000-0000-000000000001',
            'RLS032-IDEMPOTENCY-001',
            'late',
            'requested',
            NULL
        );
        RAISE EXCEPTION USING ERRCODE = 'P0001',
            MESSAGE = 'FAIL: duplicate attendance correction idempotency key accepted';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'PASS: duplicate correction idempotency key rejected';
    END;

    -- Revision numbers must be positive.
    BEGIN
        UPDATE public.attendance_record_revisions
           SET revision_no = 0
         WHERE id = 'cc000000-0000-0000-0000-000000000001';
        RAISE EXCEPTION USING ERRCODE = 'P0001',
            MESSAGE = 'FAIL: non-positive attendance revision number accepted';
    EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'PASS: non-positive attendance revision number rejected';
    END;

    RAISE NOTICE 'PASS: selected domain CHECK, UNIQUE, EXCLUSION, and FK constraints';
END
$domain_negative$;

\echo '===== 5. SAME-SCOPE DELETE IN REVERSE FOREIGN-KEY ORDER ====='

DO $valid_deletes$
DECLARE
    v_rows pg_catalog.int8;
BEGIN
    DELETE FROM public.student_scores
     WHERE id = 'ac000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'student_scores DELETE failed'; END IF;

    DELETE FROM public.assessment_participants
     WHERE id = '81c00000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'assessment_participants DELETE failed'; END IF;

    DELETE FROM public.assessment_definitions
     WHERE id = '8c000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'assessment_definitions DELETE failed'; END IF;

    UPDATE public.attendance_corrections
       SET applied_revision_id = NULL
     WHERE id = 'bc000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'attendance_corrections unlink failed'; END IF;

    DELETE FROM public.attendance_record_revisions
     WHERE id = 'cc000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'attendance_record_revisions DELETE failed'; END IF;

    DELETE FROM public.attendance_corrections
     WHERE id = 'bc000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'attendance_corrections DELETE failed'; END IF;

    DELETE FROM public.attendance_records
     WHERE id = '9c000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'attendance_records DELETE failed'; END IF;

    DELETE FROM public.attendance_session_participants
     WHERE id = '71c00000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'attendance_session_participants DELETE failed'; END IF;

    DELETE FROM public.attendance_sessions
     WHERE id = '7c000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'attendance_sessions DELETE failed'; END IF;

    DELETE FROM public.student_class_placements
     WHERE id = '6c000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'student_class_placements DELETE failed'; END IF;

    DELETE FROM public.student_enrollments
     WHERE id = '5c000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'student_enrollments DELETE failed'; END IF;

    DELETE FROM public.class_groups
     WHERE id = '4c000000-0000-0000-0000-000000000001';
    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN RAISE EXCEPTION 'class_groups DELETE failed'; END IF;

    RAISE NOTICE 'PASS: same-scope DELETE succeeded on all eleven tables';
END
$valid_deletes$;

ROLLBACK;

\echo '===== DOMAIN TABLE CRUD / INTEGRITY REGRESSION COMPLETE — ALL DML ROLLED BACK ====='
\echo 'No synthetic rows, table locks, temporary token table, or transaction-local context were retained.'
