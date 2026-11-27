-- SINAU PostgreSQL 18 Design PoC
-- Read-only metadata inventory for the eleven tenant+unit domain tables
-- not yet covered by the representative RLS matrix.
--
-- Run ONLY as PostgreSQL superuser postgres against sinau_design_poc.
-- This script reads catalog metadata only. It does not read application rows,
-- create temporary objects, or modify tables, data, policies, grants, or roles.

\set ON_ERROR_STOP on
\pset pager off
\echo '===== SINAU POC — DOMAIN INTEGRITY / RLS INVENTORY (READ ONLY) ====='

DO $guard$
DECLARE
    v_found pg_catalog.int8;
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

    SELECT pg_catalog.count(*) INTO v_found
    FROM pg_catalog.pg_class AS c
    JOIN pg_catalog.pg_namespace AS n
      ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r', 'p')
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
      ]::pg_catalog.text[]);

    IF v_found <> 11 THEN
        RAISE EXCEPTION
            'SAFETY STOP: expected all 11 target tables, found %',
            v_found;
    END IF;
END
$guard$;

BEGIN READ ONLY;

\echo '===== 1. TABLE / RLS STATUS ====='

SELECT
    c.relname AS table_name,
    c.relkind AS relation_kind,
    c.relrowsecurity AS rls_enabled,
    c.relforcerowsecurity AS rls_forced,
    pg_catalog.pg_get_userbyid(c.relowner) AS table_owner
FROM pg_catalog.pg_class AS c
JOIN pg_catalog.pg_namespace AS n
  ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind IN ('r', 'p')
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
ORDER BY c.relname;

\echo '===== 2. COLUMN / DEFAULT / NULLABILITY INVENTORY ====='

SELECT
    c.relname AS table_name,
    a.attnum AS ordinal_position,
    a.attname AS column_name,
    pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
    a.attnotnull AS not_null,
    pg_catalog.pg_get_expr(d.adbin, d.adrelid) AS default_expression,
    a.attidentity AS identity_kind,
    a.attgenerated AS generated_kind
FROM pg_catalog.pg_class AS c
JOIN pg_catalog.pg_namespace AS n
  ON n.oid = c.relnamespace
JOIN pg_catalog.pg_attribute AS a
  ON a.attrelid = c.oid
LEFT JOIN pg_catalog.pg_attrdef AS d
  ON d.adrelid = c.oid
 AND d.adnum = a.attnum
WHERE n.nspname = 'public'
  AND c.relkind IN ('r', 'p')
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
  AND a.attnum > 0
  AND NOT a.attisdropped
ORDER BY c.relname, a.attnum;

\echo '===== 3. PRIMARY / UNIQUE / FOREIGN KEY / CHECK / EXCLUSION CONSTRAINTS ====='

SELECT
    c.relname AS table_name,
    con.conname AS constraint_name,
    CASE con.contype
        WHEN 'p' THEN 'PRIMARY KEY'
        WHEN 'u' THEN 'UNIQUE'
        WHEN 'f' THEN 'FOREIGN KEY'
        WHEN 'c' THEN 'CHECK'
        WHEN 'x' THEN 'EXCLUSION'
        ELSE con.contype::pg_catalog.text
    END AS constraint_type,
    pg_catalog.pg_get_constraintdef(con.oid, true) AS definition,
    con.convalidated AS validated,
    con.condeferrable AS deferrable,
    con.condeferred AS initially_deferred
FROM pg_catalog.pg_constraint AS con
JOIN pg_catalog.pg_class AS c
  ON c.oid = con.conrelid
JOIN pg_catalog.pg_namespace AS n
  ON n.oid = c.relnamespace
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
ORDER BY c.relname, con.contype, con.conname;

\echo '===== 4. NON-INTERNAL TRIGGERS AND TRIGGER FUNCTION SECURITY ====='

SELECT
    c.relname AS table_name,
    t.tgname AS trigger_name,
    CASE t.tgenabled
        WHEN 'O' THEN 'enabled'
        WHEN 'R' THEN 'replica'
        WHEN 'A' THEN 'always'
        WHEN 'D' THEN 'disabled'
        ELSE t.tgenabled::pg_catalog.text
    END AS trigger_state,
    pg_catalog.pg_get_triggerdef(t.oid, true) AS trigger_definition,
    p.oid::pg_catalog.regprocedure AS trigger_function,
    p.prosecdef AS security_definer,
    p.provolatile AS volatility,
    p.proparallel AS parallel_mode,
    p.proconfig AS function_settings
FROM pg_catalog.pg_trigger AS t
JOIN pg_catalog.pg_class AS c
  ON c.oid = t.tgrelid
JOIN pg_catalog.pg_namespace AS n
  ON n.oid = c.relnamespace
JOIN pg_catalog.pg_proc AS p
  ON p.oid = t.tgfoid
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
  AND NOT t.tgisinternal
ORDER BY c.relname, t.tgname;

\echo '===== 5. INDEX INVENTORY ====='

SELECT
    i.tablename AS table_name,
    i.indexname AS index_name,
    i.indexdef AS definition
FROM pg_catalog.pg_indexes AS i
WHERE i.schemaname = 'public'
  AND i.tablename = ANY (ARRAY[
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
ORDER BY i.tablename, i.indexname;

\echo '===== 6. INSTALLED RLS POLICIES ====='

SELECT
    p.tablename AS table_name,
    p.policyname,
    p.permissive,
    p.roles,
    p.cmd,
    p.qual AS using_expression,
    p.with_check
FROM pg_catalog.pg_policies AS p
WHERE p.schemaname = 'public'
  AND p.tablename = ANY (ARRAY[
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
ORDER BY p.tablename, p.policyname, p.cmd;

ROLLBACK;

\echo '===== DOMAIN INTEGRITY INVENTORY COMPLETE — READ ONLY ====='
\echo 'No application rows, schema objects, grants, roles, or policies were changed.'
