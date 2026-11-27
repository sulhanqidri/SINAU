-- SINAU PostgreSQL 18 Design PoC
-- Read-only inventory of tenant/unit table classes and installed RLS policies.
--
-- Run ONLY as PostgreSQL superuser postgres against sinau_design_poc.
-- This script performs catalog/metadata reads only. It does not create,
-- alter, grant, revoke, or modify any object, setting, or row.
--
-- Purpose: build the policy matrix before considering any persistent rewrite
-- of 007-rls-signed-context.sql. Special attention: tenant-only relations and
-- audit_events rows where unit_id IS NULL are intentionally permitted.

\set ON_ERROR_STOP on
\pset pager off
\echo '===== SINAU POC — READ-ONLY RLS POLICY TABLE MATRIX ====='

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
END
$guard$;

BEGIN READ ONLY;

\echo '===== 1. ALL PUBLIC TABLES WITH TENANT OR UNIT COLUMNS ====='

WITH public_tables AS (
    SELECT
        c.oid,
        c.relname,
        c.relrowsecurity,
        c.relforcerowsecurity
    FROM pg_catalog.pg_class AS c
    JOIN pg_catalog.pg_namespace AS n
      ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r', 'p')
),
classified AS (
    SELECT
        t.*,
        EXISTS (
            SELECT 1
            FROM pg_catalog.pg_attribute AS a
            WHERE a.attrelid = t.oid
              AND a.attname = 'tenant_id'
              AND a.attnum > 0
              AND NOT a.attisdropped
        ) AS has_tenant_id,
        (
            SELECT a.attnotnull
            FROM pg_catalog.pg_attribute AS a
            WHERE a.attrelid = t.oid
              AND a.attname = 'tenant_id'
              AND a.attnum > 0
              AND NOT a.attisdropped
        ) AS tenant_id_not_null,
        EXISTS (
            SELECT 1
            FROM pg_catalog.pg_attribute AS a
            WHERE a.attrelid = t.oid
              AND a.attname = 'unit_id'
              AND a.attnum > 0
              AND NOT a.attisdropped
        ) AS has_unit_id,
        (
            SELECT a.attnotnull
            FROM pg_catalog.pg_attribute AS a
            WHERE a.attrelid = t.oid
              AND a.attname = 'unit_id'
              AND a.attnum > 0
              AND NOT a.attisdropped
        ) AS unit_id_not_null
    FROM public_tables AS t
)
SELECT
    relname AS table_name,
    CASE
        WHEN has_tenant_id AND has_unit_id THEN
            CASE
                WHEN unit_id_not_null THEN 'TENANT_PLUS_UNIT_NOT_NULL'
                ELSE 'TENANT_PLUS_UNIT_NULLABLE'
            END
        WHEN has_tenant_id THEN 'TENANT_ONLY'
        WHEN has_unit_id THEN 'UNIT_ONLY_REVIEW'
        ELSE 'NO_TENANT_OR_UNIT_COLUMN'
    END AS scope_class,
    has_tenant_id,
    tenant_id_not_null,
    has_unit_id,
    unit_id_not_null,
    relrowsecurity AS rls_enabled,
    relforcerowsecurity AS rls_forced
FROM classified
WHERE has_tenant_id
   OR has_unit_id
   OR relrowsecurity
ORDER BY
    CASE
        WHEN relname = 'tenants' THEN 0
        WHEN relname = 'education_units' THEN 1
        WHEN relname = 'audit_events' THEN 2
        ELSE 3
    END,
    relname;

\echo '===== 2. EXACT INSTALLED POLICY EXPRESSIONS ====='

SELECT
    p.schemaname,
    p.tablename,
    p.policyname,
    p.permissive,
    p.roles,
    p.cmd,
    p.qual,
    p.with_check
FROM pg_catalog.pg_policies AS p
WHERE p.schemaname = 'public'
ORDER BY p.tablename, p.policyname, p.cmd;

\echo '===== 3. TENANT/UNIT TABLES WITH RLS DISABLED OR NOT FORCED ====='

WITH scoped_tables AS (
    SELECT
        c.oid,
        c.relname,
        c.relrowsecurity,
        c.relforcerowsecurity,
        EXISTS (
            SELECT 1
            FROM pg_catalog.pg_attribute AS a
            WHERE a.attrelid = c.oid
              AND a.attname = 'tenant_id'
              AND a.attnum > 0
              AND NOT a.attisdropped
        ) AS has_tenant_id,
        EXISTS (
            SELECT 1
            FROM pg_catalog.pg_attribute AS a
            WHERE a.attrelid = c.oid
              AND a.attname = 'unit_id'
              AND a.attnum > 0
              AND NOT a.attisdropped
        ) AS has_unit_id
    FROM pg_catalog.pg_class AS c
    JOIN pg_catalog.pg_namespace AS n
      ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r', 'p')
)
SELECT
    relname AS table_name,
    has_tenant_id,
    has_unit_id,
    relrowsecurity AS rls_enabled,
    relforcerowsecurity AS rls_forced
FROM scoped_tables
WHERE (has_tenant_id OR has_unit_id)
  AND (NOT relrowsecurity OR NOT relforcerowsecurity)
ORDER BY relname;

\echo '===== 4. RLS TABLES WITHOUT A PUBLIC POLICY ====='

SELECT
    c.relname AS table_name,
    c.relrowsecurity AS rls_enabled,
    c.relforcerowsecurity AS rls_forced
FROM pg_catalog.pg_class AS c
JOIN pg_catalog.pg_namespace AS n
  ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind IN ('r', 'p')
  AND c.relrowsecurity
  AND NOT EXISTS (
      SELECT 1
      FROM pg_catalog.pg_policies AS p
      WHERE p.schemaname = 'public'
        AND p.tablename = c.relname
  )
ORDER BY c.relname;

\echo '===== 5. SPECIAL TABLE CHECKS ====='

SELECT
    c.relname AS table_name,
    c.relrowsecurity AS rls_enabled,
    c.relforcerowsecurity AS rls_forced,
    EXISTS (
        SELECT 1
        FROM pg_catalog.pg_attribute AS a
        WHERE a.attrelid = c.oid
          AND a.attname = 'tenant_id'
          AND a.attnum > 0
          AND NOT a.attisdropped
    ) AS has_tenant_id,
    (
        SELECT a.attnotnull
        FROM pg_catalog.pg_attribute AS a
        WHERE a.attrelid = c.oid
          AND a.attname = 'unit_id'
          AND a.attnum > 0
          AND NOT a.attisdropped
    ) AS unit_id_not_null,
    (
        SELECT p.qual
        FROM pg_catalog.pg_policies AS p
        WHERE p.schemaname = 'public'
          AND p.tablename = c.relname
          AND p.policyname = 'sinau_rls_isolation'
    ) AS isolation_using_expression,
    (
        SELECT p.with_check
        FROM pg_catalog.pg_policies AS p
        WHERE p.schemaname = 'public'
          AND p.tablename = c.relname
          AND p.policyname = 'sinau_rls_isolation'
    ) AS isolation_with_check_expression
FROM pg_catalog.pg_class AS c
JOIN pg_catalog.pg_namespace AS n
  ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind IN ('r', 'p')
  AND c.relname IN ('tenants', 'education_units', 'audit_events')
ORDER BY c.relname;

ROLLBACK;

\echo '===== READ-ONLY RLS POLICY TABLE MATRIX COMPLETE ====='
\echo 'No persistent database objects, settings, privileges, policies, or rows were changed.'
