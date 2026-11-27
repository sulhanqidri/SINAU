-- SINAU PostgreSQL 18 Design PoC
-- Rollback-only probe of the row-valued one-call RLS policy across all
-- twelve NOT-NULL tenant+unit relations (academic_years + eleven tables
-- inventoried in 031).
--
-- Run ONLY as PostgreSQL superuser postgres against sinau_design_poc.
-- Replaces each policy only inside one transaction; ROLLBACK restores all
-- original policies and removes all synthetic rows/temp objects.
-- Does not touch tenant-only education_units or nullable-scope audit_events.
--
-- The test inserts one synthetic dependency chain as sinau_rls_test, then
-- performs one protected SELECT per relation and measures exactly twelve
-- verifier calls (one per protected SELECT). It also tests representative
-- WITH CHECK denials under the temporary candidate policy.
--
-- Script 032 already tested CRUD/constraints under the installed policy.
-- This script is specifically about generalizing the single-row candidate
-- validated for academic_years in script 027.

\set ON_ERROR_STOP on
\pset pager off
\echo '===== SINAU POC — SINGLE-ROW POLICY CANDIDATE ACROSS 12 TABLES ====='

DO $guard$
DECLARE
    v_count pg_catalog.int8;
    v_policy_count pg_catalog.int8;
    v_identity_count pg_catalog.int8;
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
      AND c.relkind = 'r'
      AND c.relname = ANY (ARRAY[
          'academic_years',
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

    IF v_count <> 12 THEN
        RAISE EXCEPTION
            'SAFETY STOP: expected 12 tenant+unit tables with ENABLE/FORCE RLS, found %',
            v_count;
    END IF;

    SELECT pg_catalog.count(*) INTO v_policy_count
    FROM pg_catalog.pg_policies AS p
    WHERE p.schemaname = 'public'
      AND p.tablename = ANY (ARRAY[
          'academic_years',
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
      AND p.policyname = 'sinau_rls_isolation'
      AND p.cmd = 'ALL'
      AND 'sinau_rls_test' = ANY (p.roles)
      AND p.qual LIKE '%current_verified_context%'
      AND p.with_check LIKE '%current_verified_context%';

    IF v_policy_count <> 12 THEN
        RAISE EXCEPTION
            'SAFETY STOP: expected twelve installed signed-context policies, found %',
            v_policy_count;
    END IF;

    SELECT pg_catalog.count(*) INTO v_identity_count
    FROM sinau_issuer_poc.poc_identities
    WHERE actor_id = '91000000-0000-0000-0000-000000000001'
      AND account_status = 'active';

    IF v_identity_count <> 1 THEN
        RAISE EXCEPTION
            'SAFETY STOP: expected exactly one active synthetic actor, found %',
            v_identity_count;
    END IF;

    IF pg_catalog.to_regprocedure(
        'sinau_private.verify_context_token(text)'
    ) IS NULL THEN
        RAISE EXCEPTION
            'SAFETY STOP: signed-context verifier function is missing';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.tenants AS t
        JOIN public.education_units AS u ON u.tenant_id = t.id
        JOIN public.academic_years AS ay
          ON ay.tenant_id = u.tenant_id
         AND ay.unit_id = u.id
        WHERE t.id = '00000000-0000-0000-0000-000000000001'
          AND t.code = 'tenant-a'
          AND u.id = '10000000-0000-0000-0000-000000000001'
          AND u.code = 'unit-a1'
          AND ay.id = '30000000-0000-0000-0000-000000000001'
    ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: tenant-A / unit-A1 / academic-year parent fixture missing';
    END IF;

    RAISE NOTICE 'PASS preflight: database, role boundary, twelve RLS tables/policies, active actor, and parent fixture';
END
$guard$;

BEGIN ISOLATION LEVEL READ COMMITTED;

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

SET LOCAL track_functions = 'pl';

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

DO $fixture_preflight$
DECLARE
    v_item record;
    v_exists pg_catalog.bool;
BEGIN
    FOR v_item IN
        SELECT *
        FROM (VALUES
            ('class_groups', '4d000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('student_enrollments', '5d000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('student_class_placements', '6d000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_sessions', '7d000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_session_participants', '71d00000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_records', '9d000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('assessment_definitions', '8d000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('assessment_participants', '81d00000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('student_scores', 'ad000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_corrections', 'bd000000-0000-0000-0000-000000000001'::pg_catalog.uuid),
            ('attendance_record_revisions', 'cd000000-0000-0000-0000-000000000001'::pg_catalog.uuid)
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
        SELECT 1 FROM public.student_enrollments
        WHERE student_code = 'RLS033-ENROLL-001'
    ) OR EXISTS (
        SELECT 1 FROM public.attendance_corrections
        WHERE idempotency_key = 'RLS033-IDEMPOTENCY-001'
    ) OR EXISTS (
        SELECT 1 FROM public.academic_years
        WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
          AND unit_id = '10000000-0000-0000-0000-000000000002'
          AND id = '30000000-0000-0000-0000-000000000099'
    ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: one or more reserved unique values / cross-unit probe IDs already exist';
    END IF;

    RAISE NOTICE 'PASS preflight: all RLS-033 fixture IDs and unique values are unused';
END
$fixture_preflight$;

\echo '===== 1. INSTALL CANDIDATE ROW POLICY TEMPORARILY ON ALL 12 TABLES ====='

DO $candidate_policy$
DECLARE
    v_table pg_catalog.text;
BEGIN
    FOREACH v_table IN ARRAY ARRAY[
        'academic_years',
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
    ]::pg_catalog.text[]
    LOOP
        EXECUTE pg_catalog.format(
            'DROP POLICY sinau_rls_isolation ON public.%I',
            v_table
        );

        EXECUTE pg_catalog.format(
            'CREATE POLICY sinau_rls_isolation ON public.%I '
            'FOR ALL TO sinau_rls_test '
            'USING ((tenant_id, unit_id) = ('
            'SELECT ctx.tenant_id, ctx.unit_id '
            'FROM sinau_private.current_verified_context() AS ctx)) '
            'WITH CHECK ((tenant_id, unit_id) = ('
            'SELECT ctx.tenant_id, ctx.unit_id '
            'FROM sinau_private.current_verified_context() AS ctx))',
            v_table
        );
    END LOOP;

    RAISE NOTICE 'PASS: candidate single-row policy installed transaction-locally on all twelve tables';
END
$candidate_policy$;

SELECT
    p.tablename,
    p.policyname,
    p.cmd,
    p.qual,
    p.with_check
FROM pg_catalog.pg_policies AS p
WHERE p.schemaname = 'public'
  AND p.tablename = ANY (ARRAY[
      'academic_years',
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
ORDER BY p.tablename;

\echo '===== 2. EXECUTE VALID SAME-SCOPE INSERTS UNDER CANDIDATE POLICY ====='

SET LOCAL ROLE sinau_rls_test;

DO $role_check$
BEGIN
    IF current_user <> 'sinau_rls_test' THEN
        RAISE EXCEPTION
            'Expected current_user sinau_rls_test, got %',
            current_user;
    END IF;
END
$role_check$;

INSERT INTO public.class_groups
    (tenant_id, unit_id, id, academic_year_id, grade_code, name)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '4d000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    '9',
    'IX-RLS033'
);

INSERT INTO public.student_enrollments
    (tenant_id, unit_id, id, academic_year_id, student_code)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '5d000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    'RLS033-ENROLL-001'
);

INSERT INTO public.student_class_placements
    (tenant_id, unit_id, id, enrollment_id, academic_year_id,
     class_group_id, starts_on, ends_on)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '6d000000-0000-0000-0000-000000000001',
    '5d000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    '4d000000-0000-0000-0000-000000000001',
    DATE '2026-07-01',
    DATE '2026-12-31'
);

INSERT INTO public.attendance_sessions
    (tenant_id, unit_id, id, class_group_id, session_date, status)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '7d000000-0000-0000-0000-000000000001',
    '4d000000-0000-0000-0000-000000000001',
    DATE '2026-11-27',
    'open'
);

INSERT INTO public.attendance_session_participants
    (tenant_id, unit_id, id, session_id, class_group_id,
     session_date, enrollment_id, placement_id)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '71d00000-0000-0000-0000-000000000001',
    '7d000000-0000-0000-0000-000000000001',
    '4d000000-0000-0000-0000-000000000001',
    DATE '2026-11-27',
    '5d000000-0000-0000-0000-000000000001',
    '6d000000-0000-0000-0000-000000000001'
);

INSERT INTO public.attendance_records
    (tenant_id, unit_id, id, participant_id, enrollment_id, attendance_status)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '9d000000-0000-0000-0000-000000000001',
    '71d00000-0000-0000-0000-000000000001',
    '5d000000-0000-0000-0000-000000000001',
    'present'
);

INSERT INTO public.assessment_definitions
    (tenant_id, unit_id, id, class_group_id, assessment_date, max_score, scoring_rule_version)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    '8d000000-0000-0000-0000-000000000001',
    '4d000000-0000-0000-0000-000000000001',
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
    '81d00000-0000-0000-0000-000000000001',
    '8d000000-0000-0000-0000-000000000001',
    '4d000000-0000-0000-0000-000000000001',
    DATE '2026-11-27',
    '5d000000-0000-0000-0000-000000000001',
    '6d000000-0000-0000-0000-000000000001'
);

INSERT INTO public.student_scores
    (tenant_id, unit_id, id, participant_id, result_status,
     score_value, workflow_status, finalized_at)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'ad000000-0000-0000-0000-000000000001',
    '81d00000-0000-0000-0000-000000000001',
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
    'bd000000-0000-0000-0000-000000000001',
    '9d000000-0000-0000-0000-000000000001',
    'RLS033-IDEMPOTENCY-001',
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
    'cd000000-0000-0000-0000-000000000001',
    '9d000000-0000-0000-0000-000000000001',
    1,
    'bd000000-0000-0000-0000-000000000001',
    'late'
);

UPDATE public.attendance_corrections
   SET applied_revision_id = 'cd000000-0000-0000-0000-000000000001'
 WHERE id = 'bd000000-0000-0000-0000-000000000001';

SET CONSTRAINTS correction_applied_revision_fk IMMEDIATE;

\echo 'PASS: same-scope WITH CHECK accepted valid inserts across all eleven domain tables'

RESET ROLE;

CREATE TEMP TABLE poc_verifier_call_baseline (
    calls pg_catalog.int8 NOT NULL
) ON COMMIT DROP;

INSERT INTO pg_temp.poc_verifier_call_baseline (calls)
SELECT COALESCE(s.calls, 0)
FROM pg_catalog.pg_proc AS p
LEFT JOIN pg_catalog.pg_stat_xact_user_functions AS s
  ON s.funcid = p.oid
WHERE p.oid =
    'sinau_private.verify_context_token(text)'::pg_catalog.regprocedure;

\echo '===== 3. EXPLAIN CANDIDATE POLICY AND RUN ONE SELECT PER TABLE ====='

SET LOCAL ROLE sinau_rls_test;

EXPLAIN (VERBOSE, COSTS OFF)
SELECT count(*)
FROM public.academic_years
WHERE id = '30000000-0000-0000-0000-000000000001';

EXPLAIN (VERBOSE, COSTS OFF)
SELECT count(*)
FROM public.student_scores
WHERE id = 'ad000000-0000-0000-0000-000000000001';

SELECT pg_catalog.set_config(
    'poc.row_policy_candidate.academic_years',
    (SELECT pg_catalog.count(*)::pg_catalog.text
     FROM public.academic_years
     WHERE id = '30000000-0000-0000-0000-000000000001'),
    true
);

SELECT pg_catalog.set_config(
    'poc.row_policy_candidate.assessment_definitions',
    (SELECT pg_catalog.count(*)::pg_catalog.text
     FROM public.assessment_definitions
     WHERE id = '8d000000-0000-0000-0000-000000000001'),
    true
);

SELECT pg_catalog.set_config(
    'poc.row_policy_candidate.assessment_participants',
    (SELECT pg_catalog.count(*)::pg_catalog.text
     FROM public.assessment_participants
     WHERE id = '81d00000-0000-0000-0000-000000000001'),
    true
);

SELECT pg_catalog.set_config(
    'poc.row_policy_candidate.attendance_corrections',
    (SELECT pg_catalog.count(*)::pg_catalog.text
     FROM public.attendance_corrections
     WHERE id = 'bd000000-0000-0000-0000-000000000001'),
    true
);

SELECT pg_catalog.set_config(
    'poc.row_policy_candidate.attendance_record_revisions',
    (SELECT pg_catalog.count(*)::pg_catalog.text
     FROM public.attendance_record_revisions
     WHERE id = 'cd000000-0000-0000-0000-000000000001'),
    true
);

SELECT pg_catalog.set_config(
    'poc.row_policy_candidate.attendance_records',
    (SELECT pg_catalog.count(*)::pg_catalog.text
     FROM public.attendance_records
     WHERE id = '9d000000-0000-0000-0000-000000000001'),
    true
);

SELECT pg_catalog.set_config(
    'poc.row_policy_candidate.attendance_session_participants',
    (SELECT pg_catalog.count(*)::pg_catalog.text
     FROM public.attendance_session_participants
     WHERE id = '71d00000-0000-0000-0000-000000000001'),
    true
);

SELECT pg_catalog.set_config(
    'poc.row_policy_candidate.attendance_sessions',
    (SELECT pg_catalog.count(*)::pg_catalog.text
     FROM public.attendance_sessions
     WHERE id = '7d000000-0000-0000-0000-000000000001'),
    true
);

SELECT pg_catalog.set_config(
    'poc.row_policy_candidate.class_groups',
    (SELECT pg_catalog.count(*)::pg_catalog.text
     FROM public.class_groups
     WHERE id = '4d000000-0000-0000-0000-000000000001'),
    true
);

SELECT pg_catalog.set_config(
    'poc.row_policy_candidate.student_class_placements',
    (SELECT pg_catalog.count(*)::pg_catalog.text
     FROM public.student_class_placements
     WHERE id = '6d000000-0000-0000-0000-000000000001'),
    true
);

SELECT pg_catalog.set_config(
    'poc.row_policy_candidate.student_enrollments',
    (SELECT pg_catalog.count(*)::pg_catalog.text
     FROM public.student_enrollments
     WHERE id = '5d000000-0000-0000-0000-000000000001'),
    true
);

SELECT pg_catalog.set_config(
    'poc.row_policy_candidate.student_scores',
    (SELECT pg_catalog.count(*)::pg_catalog.text
     FROM public.student_scores
     WHERE id = 'ad000000-0000-0000-0000-000000000001'),
    true
);

RESET ROLE;

\echo '===== 4. ASSERT TWELVE VISIBLE ROWS AND EXACTLY TWELVE VERIFIER CALLS ====='

DO $assert$
DECLARE
    v_table pg_catalog.text;
    v_rows pg_catalog.int8;
    v_before pg_catalog.int8;
    v_after pg_catalog.int8;
    v_calls pg_catalog.int8;
BEGIN
    FOREACH v_table IN ARRAY ARRAY[
        'academic_years',
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
    ]::pg_catalog.text[]
    LOOP
        v_rows := pg_catalog.current_setting(
            'poc.row_policy_candidate.' || v_table,
            true
        )::pg_catalog.int8;

        IF v_rows IS DISTINCT FROM 1 THEN
            RAISE EXCEPTION
                'FAIL candidate policy SELECT on %: expected one own row, got %',
                v_table, v_rows;
        END IF;
    END LOOP;

    SELECT calls INTO v_before
    FROM pg_temp.poc_verifier_call_baseline;

    SELECT COALESCE(s.calls, 0) INTO v_after
    FROM pg_catalog.pg_proc AS p
    LEFT JOIN pg_catalog.pg_stat_xact_user_functions AS s
      ON s.funcid = p.oid
    WHERE p.oid =
        'sinau_private.verify_context_token(text)'::pg_catalog.regprocedure;

    IF v_before IS NULL THEN
        RAISE EXCEPTION
            'FAIL candidate verifier count: baseline row is missing';
    END IF;

    v_calls := v_after - v_before;

    IF v_calls IS DISTINCT FROM 12 THEN
        RAISE EXCEPTION
            'FAIL candidate verifier count: expected exactly 12 calls for 12 separate protected SELECTs, got %',
            v_calls;
    END IF;

    RAISE NOTICE
        'PASS: all twelve tenant+unit tables returned their own row with exactly one verifier call per SELECT (12 total)';
END
$assert$;

\echo '===== 5. REPRESENTATIVE CANDIDATE WITH CHECK DENIALS ====='

SET LOCAL ROLE sinau_rls_test;

DO $with_check$
BEGIN
    BEGIN
        INSERT INTO public.academic_years
            (tenant_id, unit_id, id, starts_on, ends_on)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000002',
            '30000000-0000-0000-0000-000000000099',
            DATE '2027-07-01',
            DATE '2028-06-30'
        );

        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'FAIL candidate policy accepted cross-unit INSERT';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS candidate policy rejects cross-unit INSERT';
    END;

    BEGIN
        UPDATE public.class_groups
           SET unit_id = '10000000-0000-0000-0000-000000000002'
         WHERE id = '4d000000-0000-0000-0000-000000000001';

        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'FAIL candidate policy accepted cross-unit UPDATE';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS candidate policy rejects cross-unit UPDATE';
    END;
END
$with_check$;

ROLLBACK;

\echo '===== 6. CONFIRM ORIGINAL POLICIES RESTORED AFTER ROLLBACK ====='

DO $restore_check$
DECLARE
    v_count pg_catalog.int8;
BEGIN
    SELECT pg_catalog.count(*) INTO v_count
    FROM pg_catalog.pg_policies AS p
    WHERE p.schemaname = 'public'
      AND p.tablename = ANY (ARRAY[
          'academic_years',
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
      AND p.policyname = 'sinau_rls_isolation'
      AND p.cmd = 'ALL'
      AND 'sinau_rls_test' = ANY (p.roles)
      AND p.qual LIKE '%current_verified_context%'
      AND p.with_check LIKE '%current_verified_context%'
      AND (
          pg_catalog.length(p.qual)
          - pg_catalog.length(pg_catalog.replace(p.qual, 'current_verified_context', ''))
      ) / pg_catalog.length('current_verified_context') = 2
      AND (
          pg_catalog.length(p.with_check)
          - pg_catalog.length(pg_catalog.replace(p.with_check, 'current_verified_context', ''))
      ) / pg_catalog.length('current_verified_context') = 2;

    IF v_count <> 12 THEN
        RAISE EXCEPTION
            'FAIL original policy restoration: expected twelve original two-subquery policies, found %',
            v_count;
    END IF;

    RAISE NOTICE 'PASS: ROLLBACK restored all twelve original two-subquery policy definitions';
END
$restore_check$;

\echo '===== SINGLE-ROW POLICY CANDIDATE PROBE COMPLETE — ALL CHANGES ROLLED BACK ====='
\echo 'No persistent policy, DDL, role, grant, setting, or synthetic row changes were retained.'
\echo 'Remove /run/authfreshness-context.token and /run/sinau-poc-token-signer/authfreshness-context.token.'
