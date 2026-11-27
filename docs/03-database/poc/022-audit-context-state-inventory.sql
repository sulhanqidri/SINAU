-- SINAU PostgreSQL 18 Design PoC
-- Read-only inventory of account/session/membership/key/verifier structure.
-- Run ONLY as PostgreSQL administrator against sinau_design_poc.
-- This script reads PostgreSQL catalogs only; it does not read fixture rows,
-- token values, session hashes, key bytes, credentials, or application data.

\set ON_ERROR_STOP on
\pset pager off
\echo '===== SINAU POC — READ-ONLY CONTEXT STATE INVENTORY ====='

BEGIN READ ONLY;

SET LOCAL statement_timeout = '30s';

DO $guard$
BEGIN
    IF pg_catalog.current_database() <> 'sinau_design_poc'
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

\echo '===== 1. RUNTIME AND DATABASE IDENTITY ====='
SELECT
    pg_catalog.current_database() AS database_name,
    current_user AS audit_role,
    pg_catalog.current_setting('server_version') AS server_version,
    pg_catalog.current_setting('transaction_isolation') AS transaction_isolation,
    pg_catalog.current_setting('transaction_read_only') AS transaction_read_only,
    pg_catalog.current_setting('search_path') AS session_search_path;

\echo '===== 2. EXPECTED RELATION PRESENCE ====='
WITH expected(schema_name, table_name) AS (
    VALUES
        ('sinau_issuer_poc', 'poc_identities'),
        ('sinau_issuer_poc', 'poc_auth_sessions'),
        ('sinau_issuer_poc', 'poc_tenant_memberships'),
        ('sinau_issuer_poc', 'poc_unit_memberships'),
        ('sinau_issuer_poc', 'poc_units'),
        ('sinau_issuer_poc', 'poc_feature_entitlements'),
        ('sinau_private', 'context_keys'),
        ('public', 'tenants')
)
SELECT
    e.schema_name,
    e.table_name,
    c.oid IS NOT NULL AS relation_exists,
    CASE WHEN c.oid IS NULL THEN NULL ELSE c.relkind END AS relkind,
    CASE WHEN c.oid IS NULL THEN NULL ELSE pg_catalog.pg_get_userbyid(c.relowner) END AS owner,
    CASE WHEN c.oid IS NULL THEN NULL ELSE c.relrowsecurity END AS rls_enabled,
    CASE WHEN c.oid IS NULL THEN NULL ELSE c.relforcerowsecurity END AS rls_forced
FROM expected AS e
LEFT JOIN pg_catalog.pg_namespace AS n
  ON n.nspname = e.schema_name
LEFT JOIN pg_catalog.pg_class AS c
  ON c.relnamespace = n.oid
 AND c.relname = e.table_name
ORDER BY e.schema_name, e.table_name;

\echo '===== 3. COLUMN DEFINITIONS — NO ROW DATA ====='
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    a.attnum AS ordinal_position,
    a.attname AS column_name,
    pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
    a.attnotnull AS not_null,
    a.attidentity AS identity_kind,
    a.attgenerated AS generated_kind,
    pg_catalog.pg_get_expr(d.adbin, d.adrelid) AS default_expression
FROM pg_catalog.pg_class AS c
JOIN pg_catalog.pg_namespace AS n
  ON n.oid = c.relnamespace
JOIN pg_catalog.pg_attribute AS a
  ON a.attrelid = c.oid
LEFT JOIN pg_catalog.pg_attrdef AS d
  ON d.adrelid = c.oid
 AND d.adnum = a.attnum
WHERE (n.nspname, c.relname) IN (
    ('sinau_issuer_poc', 'poc_identities'),
    ('sinau_issuer_poc', 'poc_auth_sessions'),
    ('sinau_issuer_poc', 'poc_tenant_memberships'),
    ('sinau_issuer_poc', 'poc_unit_memberships'),
    ('sinau_issuer_poc', 'poc_units'),
    ('sinau_issuer_poc', 'poc_feature_entitlements'),
    ('sinau_private', 'context_keys'),
    ('public', 'tenants')
)
  AND a.attnum > 0
  AND NOT a.attisdropped
ORDER BY n.nspname, c.relname, a.attnum;

\echo '===== 4. CONSTRAINTS — PRIMARY, UNIQUE, FOREIGN KEY, CHECK ====='
SELECT
    n.nspname AS schema_name,
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
    con.convalidated AS validated,
    con.condeferrable AS deferrable,
    con.condeferred AS initially_deferred,
    pg_catalog.pg_get_constraintdef(con.oid, true) AS definition
FROM pg_catalog.pg_constraint AS con
JOIN pg_catalog.pg_class AS c
  ON c.oid = con.conrelid
JOIN pg_catalog.pg_namespace AS n
  ON n.oid = c.relnamespace
WHERE (n.nspname, c.relname) IN (
    ('sinau_issuer_poc', 'poc_identities'),
    ('sinau_issuer_poc', 'poc_auth_sessions'),
    ('sinau_issuer_poc', 'poc_tenant_memberships'),
    ('sinau_issuer_poc', 'poc_unit_memberships'),
    ('sinau_issuer_poc', 'poc_units'),
    ('sinau_issuer_poc', 'poc_feature_entitlements'),
    ('sinau_private', 'context_keys')
)
ORDER BY n.nspname, c.relname, con.contype, con.conname;

\echo '===== 5. INDEXES — VALIDITY AND DEFINITIONS ====='
SELECT
    n.nspname AS schema_name,
    tbl.relname AS table_name,
    idx.relname AS index_name,
    i.indisprimary AS is_primary,
    i.indisunique AS is_unique,
    i.indisvalid AS is_valid,
    i.indisready AS is_ready,
    i.indislive AS is_live,
    pg_catalog.pg_get_indexdef(i.indexrelid) AS index_definition
FROM pg_catalog.pg_index AS i
JOIN pg_catalog.pg_class AS tbl
  ON tbl.oid = i.indrelid
JOIN pg_catalog.pg_namespace AS n
  ON n.oid = tbl.relnamespace
JOIN pg_catalog.pg_class AS idx
  ON idx.oid = i.indexrelid
WHERE (n.nspname, tbl.relname) IN (
    ('sinau_issuer_poc', 'poc_identities'),
    ('sinau_issuer_poc', 'poc_auth_sessions'),
    ('sinau_issuer_poc', 'poc_tenant_memberships'),
    ('sinau_issuer_poc', 'poc_unit_memberships'),
    ('sinau_issuer_poc', 'poc_units'),
    ('sinau_issuer_poc', 'poc_feature_entitlements'),
    ('sinau_private', 'context_keys')
)
ORDER BY n.nspname, tbl.relname, i.indisprimary DESC, idx.relname;

\echo '===== 6. CONTEXT FUNCTIONS — METADATA ====='
WITH expected(
    schema_name, function_name, argument_count,
    argument_1_type, argument_2_type, argument_3_type
) AS (
    VALUES
        ('sinau_private', 'verify_context_token', 1, 'pg_catalog.text', NULL::pg_catalog.text, NULL::pg_catalog.text),
        ('sinau_private', 'current_verified_context', 0, NULL::pg_catalog.text, NULL::pg_catalog.text, NULL::pg_catalog.text),
        ('sinau_issuer_poc', 'validate_context_request', 3, 'pg_catalog.text', 'pg_catalog.uuid', 'pg_catalog.uuid'),
        ('sinau_issuer_poc', 'has_feature_entitlement', 2, 'pg_catalog.uuid', 'pg_catalog.text', NULL::pg_catalog.text)
)
SELECT
    e.schema_name AS expected_schema,
    e.function_name AS expected_function,
    p.oid::pg_catalog.regprocedure AS installed_signature,
    pg_catalog.pg_get_userbyid(p.proowner) AS owner,
    p.prosecdef AS security_definer,
    p.provolatile AS volatility_code,
    CASE p.provolatile WHEN 'i' THEN 'IMMUTABLE' WHEN 's' THEN 'STABLE' WHEN 'v' THEN 'VOLATILE' END AS volatility,
    p.proparallel AS parallel_code,
    p.proisstrict AS strict,
    p.proleakproof AS leakproof,
    p.proconfig AS function_settings,
    p.proacl AS function_acl
FROM expected AS e
LEFT JOIN pg_catalog.pg_namespace AS n
  ON n.nspname = e.schema_name
LEFT JOIN pg_catalog.pg_proc AS p
  ON p.pronamespace = n.oid
 AND p.proname = e.function_name
 AND p.pronargs = e.argument_count
 AND CASE e.argument_count
       WHEN 0 THEN true
       WHEN 1 THEN
           p.proargtypes[0] = pg_catalog.to_regtype(e.argument_1_type)::pg_catalog.oid
       WHEN 2 THEN
           p.proargtypes[0] = pg_catalog.to_regtype(e.argument_1_type)::pg_catalog.oid
           AND p.proargtypes[1] = pg_catalog.to_regtype(e.argument_2_type)::pg_catalog.oid
       WHEN 3 THEN
           p.proargtypes[0] = pg_catalog.to_regtype(e.argument_1_type)::pg_catalog.oid
           AND p.proargtypes[1] = pg_catalog.to_regtype(e.argument_2_type)::pg_catalog.oid
           AND p.proargtypes[2] = pg_catalog.to_regtype(e.argument_3_type)::pg_catalog.oid
       ELSE false
     END
ORDER BY e.schema_name, e.function_name;

\echo '===== 7. CONTEXT FUNCTION SOURCE — DEFINITIONS ONLY ====='
SELECT
    n.nspname AS schema_name,
    p.proname AS function_name,
    p.oid::pg_catalog.regprocedure AS signature,
    pg_catalog.pg_get_functiondef(p.oid) AS function_definition
FROM pg_catalog.pg_proc AS p
JOIN pg_catalog.pg_namespace AS n
  ON n.oid = p.pronamespace
WHERE (n.nspname, p.proname) IN (
    ('sinau_private', 'verify_context_token'),
    ('sinau_private', 'current_verified_context'),
    ('sinau_issuer_poc', 'validate_context_request'),
    ('sinau_issuer_poc', 'has_feature_entitlement')
)
ORDER BY n.nspname, p.proname, p.oid::pg_catalog.regprocedure::pg_catalog.text;

\echo '===== 8. TABLE PRIVILEGES — EFFECTIVE CHECKS ====='
WITH target_roles AS (
    SELECT oid, rolname
    FROM pg_catalog.pg_roles
    WHERE rolname IN (
        'postgres',
        'sinau_poc',
        'sinau_context_owner',
        'sinau_context_issuer_poc',
        'sinau_rls_test',
        'sinau_app_runtime_poc'
    )
),
target_tables AS (
    SELECT c.oid, n.nspname, c.relname
    FROM pg_catalog.pg_class AS c
    JOIN pg_catalog.pg_namespace AS n
      ON n.oid = c.relnamespace
    WHERE (n.nspname, c.relname) IN (
        ('sinau_issuer_poc', 'poc_identities'),
        ('sinau_issuer_poc', 'poc_auth_sessions'),
        ('sinau_issuer_poc', 'poc_tenant_memberships'),
        ('sinau_issuer_poc', 'poc_unit_memberships'),
        ('sinau_issuer_poc', 'poc_units'),
        ('sinau_issuer_poc', 'poc_feature_entitlements'),
        ('sinau_private', 'context_keys')
    )
)
SELECT
    r.rolname AS role_name,
    t.nspname AS schema_name,
    t.relname AS table_name,
    pg_catalog.has_table_privilege(r.oid, t.oid, 'SELECT') AS can_select,
    pg_catalog.has_table_privilege(r.oid, t.oid, 'INSERT') AS can_insert,
    pg_catalog.has_table_privilege(r.oid, t.oid, 'UPDATE') AS can_update,
    pg_catalog.has_table_privilege(r.oid, t.oid, 'DELETE') AS can_delete,
    pg_catalog.has_table_privilege(r.oid, t.oid, 'TRUNCATE') AS can_truncate
FROM target_roles AS r
CROSS JOIN target_tables AS t
ORDER BY r.rolname, t.nspname, t.relname;

\echo '===== 9. FUNCTION EXECUTE PRIVILEGES ====='
WITH target_roles AS (
    SELECT oid, rolname
    FROM pg_catalog.pg_roles
    WHERE rolname IN (
        'postgres',
        'sinau_poc',
        'sinau_context_owner',
        'sinau_context_issuer_poc',
        'sinau_rls_test',
        'sinau_app_runtime_poc'
    )
),
target_functions AS (
    SELECT p.oid, n.nspname, p.proname
    FROM pg_catalog.pg_proc AS p
    JOIN pg_catalog.pg_namespace AS n
      ON n.oid = p.pronamespace
    WHERE (n.nspname, p.proname) IN (
        ('sinau_private', 'verify_context_token'),
        ('sinau_private', 'current_verified_context'),
        ('sinau_issuer_poc', 'validate_context_request'),
        ('sinau_issuer_poc', 'has_feature_entitlement')
    )
)
SELECT
    r.rolname AS role_name,
    f.nspname AS schema_name,
    f.proname AS function_name,
    f.oid::pg_catalog.regprocedure AS signature,
    pg_catalog.has_function_privilege(r.oid, f.oid, 'EXECUTE') AS can_execute
FROM target_roles AS r
CROSS JOIN target_functions AS f
ORDER BY r.rolname, f.nspname, f.proname, f.oid::pg_catalog.regprocedure::pg_catalog.text;

\echo '===== 10. ROLE ATTRIBUTES AND MEMBERSHIP ====='
SELECT
    rolname,
    rolsuper,
    rolcanlogin,
    rolinherit,
    rolcreaterole,
    rolcreatedb,
    rolreplication,
    rolbypassrls
FROM pg_catalog.pg_roles
WHERE rolname IN (
    'sinau_poc',
    'sinau_context_owner',
    'sinau_context_issuer_poc',
    'sinau_rls_test'
)
ORDER BY rolname;

SELECT
    member_role.rolname AS member_role,
    granted_role.rolname AS granted_role,
    grantor_role.rolname AS grantor_role,
    am.admin_option,
    am.inherit_option,
    am.set_option
FROM pg_catalog.pg_auth_members AS am
JOIN pg_catalog.pg_roles AS member_role
  ON member_role.oid = am.member
JOIN pg_catalog.pg_roles AS granted_role
  ON granted_role.oid = am.roleid
JOIN pg_catalog.pg_roles AS grantor_role
  ON grantor_role.oid = am.grantor
WHERE member_role.rolname IN (
        'sinau_poc',
        'sinau_context_owner',
        'sinau_context_issuer_poc',
        'sinau_rls_test',
        'sinau_app_runtime_poc'
    )
   OR granted_role.rolname IN (
        'sinau_context_owner',
        'sinau_context_issuer_poc',
        'sinau_rls_test',
        'sinau_app_runtime_poc'
    )
ORDER BY member_role.rolname, granted_role.rolname;

\echo '===== 11. RLS POLICY INVENTORY FOR PUBLIC TABLES ====='
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
  AND (
      coalesce(qual, '') ILIKE '%current_verified_context%'
      OR coalesce(with_check, '') ILIKE '%current_verified_context%'
  )
ORDER BY tablename, policyname;

\echo '===== 12. CATALOG-RECORDED FUNCTION DEPENDENCIES ====='
\echo 'Note: PL/pgSQL body references may not appear in pg_depend; compare function source above.'
SELECT
    p.oid::pg_catalog.regprocedure AS function_signature,
    rn.nspname AS referenced_schema,
    rc.relname AS referenced_relation,
    d.deptype AS dependency_type
FROM pg_catalog.pg_depend AS d
JOIN pg_catalog.pg_proc AS p
  ON d.classid = 'pg_catalog.pg_proc'::pg_catalog.regclass
 AND d.objid = p.oid
JOIN pg_catalog.pg_namespace AS pn
  ON pn.oid = p.pronamespace
JOIN pg_catalog.pg_class AS rc
  ON d.refclassid = 'pg_catalog.pg_class'::pg_catalog.regclass
 AND d.refobjid = rc.oid
JOIN pg_catalog.pg_namespace AS rn
  ON rn.oid = rc.relnamespace
WHERE (pn.nspname, p.proname) IN (
    ('sinau_private', 'verify_context_token'),
    ('sinau_private', 'current_verified_context'),
    ('sinau_issuer_poc', 'validate_context_request'),
    ('sinau_issuer_poc', 'has_feature_entitlement')
)
ORDER BY pn.nspname, p.proname, rn.nspname, rc.relname;

ROLLBACK;

\echo '===== READ-ONLY CONTEXT STATE INVENTORY COMPLETE — ROLLED BACK ====='
