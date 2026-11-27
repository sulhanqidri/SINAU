-- SINAU PostgreSQL 18 Design PoC
-- Read-only diagnostic: inspect the installed academic_years RLS policy,
-- show its plan, and count actual verify_context_token() calls for one SELECT.
--
-- Run ONLY as PostgreSQL superuser postgres against sinau_design_poc.
-- Uses existing synthetic actor 910...001 and the existing v1 short-lived
-- transaction-bound signer. No persistent object, role, ACL, or row changes.
-- The test transaction rolls back and its token file must be removed.
--
-- track_functions='pl' is set LOCAL to this transaction only. Calls are
-- collected from pg_stat_xact_user_functions for the current transaction.

\set ON_ERROR_STOP on
\pset pager off
\echo '===== SINAU POC — RLS VERIFIER CALL-COUNT AUDIT ====='

DO $guard$
DECLARE
    v_policy_count pg_catalog.int8;
    v_identity_count pg_catalog.int8;
    v_verifier_oid pg_catalog.oid;
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
            'SAFETY STOP: sinau_rls_test must exist as NOLOGIN non-superuser without BYPASSRLS';
    END IF;

    IF NOT pg_catalog.has_table_privilege(
        'sinau_rls_test', 'public.academic_years', 'SELECT'
    ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: sinau_rls_test lacks SELECT on public.academic_years';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_class AS c
        JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relname = 'academic_years'
          AND c.relkind = 'r'
    ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: public.academic_years does not exist as a table';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'academic_years'
          AND column_name = 'tenant_id'
    ) OR NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'academic_years'
          AND column_name = 'unit_id'
    ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: academic_years must have tenant_id and unit_id columns for this diagnostic';
    END IF;

    SELECT pg_catalog.count(*)
      INTO v_policy_count
      FROM pg_catalog.pg_policies
     WHERE schemaname = 'public'
       AND tablename = 'academic_years'
       AND policyname = 'sinau_rls_isolation';

    IF v_policy_count <> 1 THEN
        RAISE EXCEPTION
            'SAFETY STOP: expected exactly one sinau_rls_isolation policy on academic_years, found %',
            v_policy_count;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_class AS c
        JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relname = 'academic_years'
          AND c.relrowsecurity
          AND c.relforcerowsecurity
    ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: academic_years must have ENABLE and FORCE ROW LEVEL SECURITY';
    END IF;

    SELECT p.oid
      INTO v_verifier_oid
      FROM pg_catalog.pg_proc AS p
     WHERE p.oid =
        'sinau_private.verify_context_token(text)'::pg_catalog.regprocedure
       AND p.prolang = (
           SELECT l.oid
           FROM pg_catalog.pg_language AS l
           WHERE l.lanname = 'plpgsql'
       );

    IF v_verifier_oid IS NULL THEN
        RAISE EXCEPTION
            'SAFETY STOP: PL/pgSQL verifier function not found';
    END IF;

    SELECT pg_catalog.count(*)
      INTO v_identity_count
      FROM sinau_issuer_poc.poc_identities
     WHERE actor_id = '91000000-0000-0000-0000-000000000001'
       AND account_status = 'active';

    IF v_identity_count <> 1 THEN
        RAISE EXCEPTION
            'SAFETY STOP: expected exactly one active synthetic identity, found %',
            v_identity_count;
    END IF;
END
$guard$;

BEGIN ISOLATION LEVEL READ COMMITTED;

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
            'Expected exactly one non-empty signed token; found %', v_count;
    END IF;

    PERFORM pg_catalog.set_config('app.context_token', v_token, true);
    RAISE NOTICE
        'PASS: transaction-bound context installed without printing token';
END
$install_context$;

\echo '===== INSTALLED POLICY EXPRESSION ====='

SELECT
    schemaname,
    tablename,
    policyname,
    roles,
    qual,
    with_check
FROM pg_catalog.pg_policies
WHERE schemaname = 'public'
  AND tablename = 'academic_years'
  AND policyname = 'sinau_rls_isolation';

SET LOCAL ROLE sinau_rls_test;

DO $role_check$
BEGIN
    IF current_user <> 'sinau_rls_test' THEN
        RAISE EXCEPTION
            'Expected current_user sinau_rls_test, got %', current_user;
    END IF;
END
$role_check$;

\echo '===== EXPLAIN POLICY PLAN (DOES NOT EXECUTE THE SELECT) ====='

EXPLAIN (VERBOSE, COSTS OFF)
SELECT count(*)
FROM public.academic_years;

\echo '===== RUN ONE PROTECTED SELECT ====='

SELECT count(*) AS visible_rows
FROM public.academic_years
\gset

\echo 'Visible academic_years rows: ' :visible_rows
SELECT pg_catalog.set_config('poc.audit_visible_rows', :'visible_rows', true);

RESET ROLE;

\echo '===== FUNCTION CALL COUNTS FOR THIS TRANSACTION ====='
\echo 'Only the single protected SELECT above is expected to call the verifier.'

SELECT
    p.oid::pg_catalog.regprocedure AS function_signature,
    COALESCE(s.calls, 0) AS calls,
    COALESCE(s.total_time, 0)::pg_catalog.numeric(18,3) AS total_time_ms,
    COALESCE(s.self_time, 0)::pg_catalog.numeric(18,3) AS self_time_ms
FROM pg_catalog.pg_proc AS p
LEFT JOIN pg_catalog.pg_stat_xact_user_functions AS s
  ON s.funcid = p.oid
WHERE p.oid =
    'sinau_private.verify_context_token(text)'::pg_catalog.regprocedure;

DO $assert$
DECLARE
    v_visible pg_catalog.int8;
    v_calls pg_catalog.int8;
BEGIN
    v_visible := pg_catalog.current_setting('poc.audit_visible_rows', true)::pg_catalog.int8;

    SELECT COALESCE(s.calls, 0)
      INTO v_calls
      FROM pg_catalog.pg_proc AS p
      LEFT JOIN pg_catalog.pg_stat_xact_user_functions AS s
        ON s.funcid = p.oid
     WHERE p.oid =
        'sinau_private.verify_context_token(text)'::pg_catalog.regprocedure;

    IF v_visible <> 1 THEN
        RAISE EXCEPTION
            'FAIL: expected one visible tenant-A/unit-A1 academic year, got %',
            v_visible;
    END IF;

    IF v_calls < 1 THEN
        RAISE EXCEPTION
            'FAIL: no verifier calls were recorded; check track_functions and RLS execution';
    END IF;

    RAISE NOTICE
        'PASS: one protected SELECT returned one row and recorded % verifier call(s)',
        v_calls;
END
$assert$;

ROLLBACK;

\echo '===== AUDIT ROLLED BACK — TRANSACTION-LOCAL TOKEN CLEARED ====='
\echo 'Remove /run/authfreshness-context.token and /run/sinau-poc-token-signer/authfreshness-context.token.'
