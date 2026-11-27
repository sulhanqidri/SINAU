-- SINAU PostgreSQL 18 Design PoC
-- Replace spoofable app.tenant_id/app.unit_id RLS predicates with
-- predicates derived from a signed, transaction-bound context token.
--
-- Run ONLY as PostgreSQL administrator against sinau_design_poc.
-- This is an isolated PoC experiment, not a production migration.
--
-- Caller sets transaction-local app.context_token to the opaque token.
-- RLS policies call current_verified_context(), which re-verifies the MAC,
-- audience, time window and current top-level transaction XID.
--
-- IMPORTANT:
-- - Do not trust app.tenant_id or app.unit_id. They remain client-writable.
-- - The token issuer/backend must authenticate the actor and verify active
--   tenant/unit membership BEFORE signing. The current PoC signer uses fixed
--   synthetic claims and does not perform membership checks.
-- - This script changes only policies inside sinau_design_poc.
-- - Do not run against database sinau or use role sinau_app.

\set ON_ERROR_STOP on

-- Create a narrow invoker-rights accessor. The caller receives only verified
-- claims; the underlying HMAC key remains protected by verify_context_token().
BEGIN;

SET LOCAL ROLE sinau_context_owner;

CREATE OR REPLACE FUNCTION sinau_private.current_verified_context()
RETURNS TABLE (
    actor_id pg_catalog.uuid,
    tenant_id pg_catalog.uuid,
    unit_id pg_catalog.uuid
)
LANGUAGE sql
VOLATILE
PARALLEL UNSAFE
SECURITY INVOKER
SET search_path = pg_catalog, pg_temp
AS $function$
    SELECT
        v.actor_id,
        v.tenant_id,
        v.unit_id
    FROM sinau_private.verify_context_token(
        pg_catalog.current_setting('app.context_token', true)
    ) AS v
$function$;

REVOKE ALL ON FUNCTION sinau_private.current_verified_context()
    FROM PUBLIC;

GRANT USAGE ON SCHEMA sinau_private TO sinau_rls_test;

GRANT EXECUTE ON FUNCTION sinau_private.current_verified_context()
    TO sinau_rls_test;

COMMIT;

-- Replace the old policies. The PostgreSQL administrator executes this block
-- because the test role does not own the application PoC tables.
BEGIN;

DO $policies$
DECLARE
    t record;
    predicate pg_catalog.text;
BEGIN
    FOR t IN
        SELECT
            c.table_name,
            pg_catalog.bool_or(c.column_name = 'unit_id') AS has_unit_id
        FROM information_schema.columns AS c
        WHERE c.table_schema = 'public'
          AND c.column_name IN ('tenant_id', 'unit_id')
        GROUP BY c.table_name
        HAVING pg_catalog.bool_or(c.column_name = 'tenant_id')
    LOOP
        -- The tenant registry is global and intentionally outside RLS.
        IF t.table_name = 'tenants' THEN
            CONTINUE;
        END IF;

        IF t.has_unit_id THEN
            IF t.table_name = 'audit_events' THEN
                predicate := $p$
                    tenant_id = (
                        SELECT ctx.tenant_id
                        FROM sinau_private.current_verified_context() AS ctx
                    )
                    AND (
                        unit_id IS NULL
                        OR unit_id = (
                            SELECT ctx.unit_id
                            FROM sinau_private.current_verified_context() AS ctx
                        )
                    )
                $p$;
            ELSE
                predicate := $p$
                    tenant_id = (
                        SELECT ctx.tenant_id
                        FROM sinau_private.current_verified_context() AS ctx
                    )
                    AND unit_id = (
                        SELECT ctx.unit_id
                        FROM sinau_private.current_verified_context() AS ctx
                    )
                $p$;
            END IF;
        ELSE
            -- education_units is tenant-scoped, not unit-scoped.
            predicate := $p$
                tenant_id = (
                    SELECT ctx.tenant_id
                    FROM sinau_private.current_verified_context() AS ctx
                )
            $p$;
        END IF;

        EXECUTE pg_catalog.format(
            'ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',
            t.table_name
        );

        EXECUTE pg_catalog.format(
            'ALTER TABLE public.%I FORCE ROW LEVEL SECURITY',
            t.table_name
        );

        EXECUTE pg_catalog.format(
            'DROP POLICY IF EXISTS sinau_rls_isolation ON public.%I',
            t.table_name
        );

        EXECUTE pg_catalog.format(
            'CREATE POLICY sinau_rls_isolation ON public.%I '
            'FOR ALL TO sinau_rls_test USING (%s) WITH CHECK (%s)',
            t.table_name,
            predicate,
            predicate
        );
    END LOOP;
END
$policies$;

COMMIT;

-- Report policies and function metadata without exposing any token or key.
\echo '===== SIGNED CONTEXT FUNCTION ====='

SELECT
    p.oid::pg_catalog.regprocedure AS function_signature,
    p.proowner::pg_catalog.regrole AS function_owner,
    p.prosecdef AS security_definer,
    p.provolatile AS volatility,
    p.proparallel AS parallel_mode,
    p.proconfig AS function_settings,
    p.proacl AS function_acl
FROM pg_catalog.pg_proc AS p
WHERE p.oid =
    'sinau_private.current_verified_context()'::pg_catalog.regprocedure;

\echo '===== POLICY INVENTORY ====='

SELECT
    schemaname,
    tablename,
    policyname,
    roles,
    qual,
    with_check
FROM pg_catalog.pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

\echo '===== RLS STATUS ====='

SELECT
    c.relname AS table_name,
    c.relrowsecurity AS rls_enabled,
    c.relforcerowsecurity AS rls_forced
FROM pg_catalog.pg_class AS c
JOIN pg_catalog.pg_namespace AS n
  ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
ORDER BY c.relname;

\echo '===== SIGNED CONTEXT RLS SETUP COMPLETE ====='
