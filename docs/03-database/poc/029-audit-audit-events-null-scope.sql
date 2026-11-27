-- SINAU PostgreSQL 18 Design PoC
-- Read-only audit of audit_events tenant_id/unit_id nullability and row mix.
--
-- Run ONLY as PostgreSQL superuser postgres against sinau_design_poc.
-- This script reads catalogs and aggregates counts only; it does not expose
-- audit payloads, actor IDs, or correlation IDs and performs no mutations.

\set ON_ERROR_STOP on
\pset pager off
\echo '===== SINAU POC — AUDIT_EVENTS NULL-SCOPE SEMANTICS ====='

DO $guard$
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
        FROM pg_catalog.pg_class AS c
        JOIN pg_catalog.pg_namespace AS n
          ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relname = 'audit_events'
          AND c.relkind = 'r'
    ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: public.audit_events table not found';
    END IF;
END
$guard$;

BEGIN READ ONLY;

\echo '===== 1. COLUMN NULLABILITY ====='

SELECT
    a.attname AS column_name,
    NOT a.attnotnull AS nullable,
    format_type(a.atttypid, a.atttypmod) AS data_type
FROM pg_catalog.pg_attribute AS a
WHERE a.attrelid = 'public.audit_events'::pg_catalog.regclass
  AND a.attname IN ('tenant_id', 'unit_id')
  AND a.attnum > 0
  AND NOT a.attisdropped
ORDER BY a.attname;

\echo '===== 2. CHECK CONSTRAINT DEFINITIONS ====='

SELECT
    c.conname AS constraint_name,
    pg_catalog.pg_get_constraintdef(c.oid, true) AS definition,
    c.convalidated AS validated
FROM pg_catalog.pg_constraint AS c
WHERE c.conrelid = 'public.audit_events'::pg_catalog.regclass
  AND c.contype = 'c'
ORDER BY c.conname;

\echo '===== 3. ROW DISTRIBUTION WITHOUT DISCLOSING AUDIT CONTENT ====='

SELECT
    count(*) AS total_rows,
    count(*) FILTER (
        WHERE tenant_id IS NULL
    ) AS tenant_id_null_rows,
    count(*) FILTER (
        WHERE unit_id IS NULL
    ) AS unit_id_null_rows,
    count(*) FILTER (
        WHERE tenant_id IS NULL AND unit_id IS NULL
    ) AS global_scope_rows_both_null,
    count(*) FILTER (
        WHERE tenant_id IS NOT NULL AND unit_id IS NULL
    ) AS tenant_scope_rows,
    count(*) FILTER (
        WHERE tenant_id IS NOT NULL AND unit_id IS NOT NULL
    ) AS unit_scope_rows,
    count(*) FILTER (
        WHERE tenant_id IS NULL AND unit_id IS NOT NULL
    ) AS invalid_by_check_constraint
FROM public.audit_events;

\echo '===== 4. NULL-SCOPE COUNTS BY ACTOR TYPE ====='

SELECT
    actor_type,
    count(*) AS total_rows,
    count(*) FILTER (
        WHERE tenant_id IS NULL AND unit_id IS NULL
    ) AS both_scope_columns_null,
    count(*) FILTER (
        WHERE tenant_id IS NOT NULL AND unit_id IS NULL
    ) AS tenant_only_rows,
    count(*) FILTER (
        WHERE tenant_id IS NOT NULL AND unit_id IS NOT NULL
    ) AS tenant_unit_rows
FROM public.audit_events
GROUP BY actor_type
ORDER BY actor_type;

\echo '===== 5. CURRENT POLICY FOR AUDIT EVENTS ====='

SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_catalog.pg_policies
WHERE schemaname = 'public'
  AND tablename = 'audit_events'
ORDER BY policyname, cmd;

ROLLBACK;

\echo '===== AUDIT_EVENTS NULL-SCOPE AUDIT COMPLETE ====='
\echo 'Read-only transaction rolled back; no database objects or rows changed.'
