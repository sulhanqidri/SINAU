-- SINAU PostgreSQL 18 Design PoC
-- Test a single row-comparison subquery for tenant_id + unit_id in RLS.
--
-- The installed academic_years policy currently contains two independent
-- scalar subqueries to current_verified_context(), producing two verifier
-- calls for one protected SELECT (see script 026).
--
-- This script replaces that policy ONLY inside a rollback-only transaction
-- with a candidate row comparison that obtains both claims from one subquery.
-- The original policy is restored automatically by ROLLBACK.
--
-- Run ONLY as PostgreSQL superuser postgres in sinau_design_poc.
-- Uses synthetic actor 910...001 and the existing v1 token signer.
-- No persistent schema, policy, role, ACL, setting, or fixture changes.

\set ON_ERROR_STOP on
\pset pager off
\echo '===== SINAU POC — SINGLE ROW-CONTEXT POLICY PROBE ====='

DO $guard$
DECLARE
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

    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_class AS c
        JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relname = 'academic_years'
          AND c.relkind = 'r'
          AND c.relrowsecurity
          AND c.relforcerowsecurity
    ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: academic_years must exist with ENABLE and FORCE RLS';
    END IF;

    SELECT pg_catalog.count(*)
      INTO v_policy_count
      FROM pg_catalog.pg_policies
     WHERE schemaname = 'public'
       AND tablename = 'academic_years'
       AND policyname = 'sinau_rls_isolation'
       AND cmd = 'ALL'
       AND 'sinau_rls_test' = ANY(roles)
       AND qual LIKE '%current_verified_context%'
       AND with_check LIKE '%current_verified_context%';

    IF v_policy_count <> 1 THEN
        RAISE EXCEPTION
            'SAFETY STOP: expected exactly one original signed-context policy; found %',
            v_policy_count;
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

\echo '===== ORIGINAL POLICY BEFORE TEMPORARY REPLACEMENT ====='

SELECT
    schemaname, tablename, policyname, roles, qual, with_check
FROM pg_catalog.pg_policies
WHERE schemaname = 'public'
  AND tablename = 'academic_years'
  AND policyname = 'sinau_rls_isolation';

\echo '===== REPLACE POLICY INSIDE THE OPEN TRANSACTION ====='

DROP POLICY sinau_rls_isolation ON public.academic_years;

CREATE POLICY sinau_rls_isolation
ON public.academic_years
FOR ALL
TO sinau_rls_test
USING (
    (tenant_id, unit_id) = (
        SELECT ctx.tenant_id, ctx.unit_id
        FROM sinau_private.current_verified_context() AS ctx
    )
)
WITH CHECK (
    (tenant_id, unit_id) = (
        SELECT ctx.tenant_id, ctx.unit_id
        FROM sinau_private.current_verified_context() AS ctx
    )
);

\echo '===== CANDIDATE POLICY EXPRESSION ====='

SELECT
    schemaname, tablename, policyname, roles, qual, with_check
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

\echo '===== EXPLAIN CANDIDATE POLICY PLAN ====='

EXPLAIN (VERBOSE, COSTS OFF)
SELECT count(*)
FROM public.academic_years;

\echo '===== EXECUTE ONE PROTECTED SELECT ====='

SELECT count(*) AS visible_rows
FROM public.academic_years
\gset

\echo 'Visible academic_years rows: ' :visible_rows
SELECT pg_catalog.set_config('poc.audit_visible_rows', :'visible_rows', true);

RESET ROLE;

\echo '===== CANDIDATE VERIFIER CALL COUNT ====='

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
    v_visible :=
        pg_catalog.current_setting('poc.audit_visible_rows', true)::pg_catalog.int8;

    SELECT COALESCE(s.calls, 0)
      INTO v_calls
      FROM pg_catalog.pg_proc AS p
      LEFT JOIN pg_catalog.pg_stat_xact_user_functions AS s
        ON s.funcid = p.oid
     WHERE p.oid =
        'sinau_private.verify_context_token(text)'::pg_catalog.regprocedure;

    IF v_visible <> 1 THEN
        RAISE EXCEPTION
            'FAIL: candidate policy expected one visible tenant-A/unit-A1 row, got %',
            v_visible;
    END IF;

    IF v_calls <> 1 THEN
        RAISE EXCEPTION
            'FAIL: expected exactly one verifier call for one protected SELECT, got %',
            v_calls;
    END IF;

    RAISE NOTICE
        'PASS: composite row comparison returned one row with exactly one verifier call';
END
$assert$;

ROLLBACK;

\echo '===== ORIGINAL POLICY RESTORATION CHECK ====='

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

\echo '===== PROBE COMPLETE — TEMPORARY POLICY CHANGE ROLLED BACK ====='
\echo 'Remove /run/authfreshness-context.token and /run/sinau-poc-token-signer/authfreshness-context.token.'
