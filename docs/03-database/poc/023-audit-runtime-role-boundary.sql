-- SINAU PostgreSQL 18 Design PoC
-- Read-only audit of the runtime executor / issuer / query role boundary.
-- Run ONLY as PostgreSQL superuser postgres against sinau_design_poc.
-- Reads catalog metadata and effective ACLs only; never reads token, key,
-- password, session-hash, fixture-row, or application-row values.
-- Ends with ROLLBACK. This script performs no DDL, DML, GRANT, or REVOKE.

\set ON_ERROR_STOP on
\pset pager off
\echo '===== SINAU POC — READ-ONLY RUNTIME ROLE BOUNDARY AUDIT ====='

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
       )
       OR pg_catalog.current_setting('transaction_read_only') <> 'on' THEN
        RAISE EXCEPTION
            'SAFETY STOP: run only as PostgreSQL superuser postgres in read-only sinau_design_poc';
    END IF;
END
$guard$;

\echo '===== 1. ROLE ATTRIBUTES ====='
SELECT
    rolname,
    rolsuper,
    rolcanlogin,
    rolinherit,
    rolcreaterole,
    rolcreatedb,
    rolreplication,
    rolbypassrls,
    rolconnlimit
FROM pg_catalog.pg_roles
WHERE rolname IN (
    'sinau_app_runtime_poc',
    'sinau_context_issuer_poc',
    'sinau_rls_test',
    'sinau_context_owner',
    'sinau_poc'
)
ORDER BY rolname;

\echo '===== 2. RELEVANT ROLE MEMBERSHIP EDGES AND OPTIONS ====='
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
        'sinau_app_runtime_poc',
        'sinau_context_issuer_poc',
        'sinau_rls_test',
        'sinau_context_owner',
        'sinau_poc'
    )
   OR granted_role.rolname IN (
        'sinau_app_runtime_poc',
        'sinau_context_issuer_poc',
        'sinau_rls_test',
        'sinau_context_owner',
        'sinau_poc'
    )
ORDER BY member_role.rolname, granted_role.rolname;

\echo '===== 3. ALL ROLES REACHABLE BY SET ROLE FROM RUNTIME ====='
WITH RECURSIVE set_paths AS (
    SELECT
        r.oid AS role_oid,
        ARRAY[r.oid]::pg_catalog.oid[] AS visited_oids,
        ARRAY[r.rolname::pg_catalog.text]::pg_catalog.text[] AS role_path,
        0 AS depth
    FROM pg_catalog.pg_roles AS r
    WHERE r.rolname = 'sinau_app_runtime_poc'

    UNION ALL

    SELECT
        target_role.oid,
        pg_catalog.array_append(path.visited_oids, target_role.oid),
        pg_catalog.array_append(path.role_path, target_role.rolname::pg_catalog.text),
        path.depth + 1
    FROM set_paths AS path
    JOIN pg_catalog.pg_auth_members AS am
      ON am.member = path.role_oid
     AND am.set_option
    JOIN pg_catalog.pg_roles AS target_role
      ON target_role.oid = am.roleid
    WHERE NOT target_role.oid = ANY(path.visited_oids)
)
SELECT
    pg_catalog.array_to_string(path.role_path, ' -> ') AS set_role_path,
    path.depth,
    target.rolname AS reachable_role,
    target.rolcanlogin,
    target.rolsuper,
    target.rolcreaterole,
    target.rolcreatedb,
    target.rolbypassrls
FROM set_paths AS path
JOIN pg_catalog.pg_roles AS target
  ON target.oid = path.role_oid
WHERE path.depth > 0
ORDER BY path.depth, set_role_path;

\echo '===== 4. ROLES WHOSE PRIVILEGES ARE INHERITED BY RUNTIME ====='
WITH RECURSIVE inherit_paths AS (
    SELECT
        r.oid AS role_oid,
        ARRAY[r.oid]::pg_catalog.oid[] AS visited_oids,
        ARRAY[r.rolname::pg_catalog.text]::pg_catalog.text[] AS role_path,
        0 AS depth
    FROM pg_catalog.pg_roles AS r
    WHERE r.rolname = 'sinau_app_runtime_poc'

    UNION ALL

    SELECT
        target_role.oid,
        pg_catalog.array_append(path.visited_oids, target_role.oid),
        pg_catalog.array_append(path.role_path, target_role.rolname::pg_catalog.text),
        path.depth + 1
    FROM inherit_paths AS path
    JOIN pg_catalog.pg_auth_members AS am
      ON am.member = path.role_oid
     AND am.inherit_option
    JOIN pg_catalog.pg_roles AS target_role
      ON target_role.oid = am.roleid
    WHERE NOT target_role.oid = ANY(path.visited_oids)
)
SELECT
    pg_catalog.array_to_string(path.role_path, ' -> ') AS inherit_role_path,
    path.depth,
    target.rolname AS inherited_role
FROM inherit_paths AS path
JOIN pg_catalog.pg_roles AS target
  ON target.oid = path.role_oid
WHERE path.depth > 0
ORDER BY path.depth, inherit_role_path;

\echo '===== 5. DIRECT RUNTIME SCHEMA AND FUNCTION PRIVILEGES ====='
WITH runtime AS (
    SELECT oid
    FROM pg_catalog.pg_roles
    WHERE rolname = 'sinau_app_runtime_poc'
),
target_schemas AS (
    SELECT oid, nspname
    FROM pg_catalog.pg_namespace
    WHERE nspname IN ('sinau_issuer_poc', 'sinau_private', 'sinau_crypto')
)
SELECT
    s.nspname AS schema_name,
    pg_catalog.has_schema_privilege(r.oid, s.oid, 'USAGE') AS can_use,
    pg_catalog.has_schema_privilege(r.oid, s.oid, 'CREATE') AS can_create
FROM runtime AS r
CROSS JOIN target_schemas AS s
ORDER BY s.nspname;

WITH runtime AS (
    SELECT oid
    FROM pg_catalog.pg_roles
    WHERE rolname = 'sinau_app_runtime_poc'
),
target_functions AS (
    SELECT p.oid, n.nspname, p.proname,
           p.oid::pg_catalog.regprocedure AS signature
    FROM pg_catalog.pg_proc AS p
    JOIN pg_catalog.pg_namespace AS n
      ON n.oid = p.pronamespace
    WHERE (n.nspname, p.proname) IN (
        ('sinau_issuer_poc', 'validate_context_request'),
        ('sinau_issuer_poc', 'has_feature_entitlement'),
        ('sinau_private', 'verify_context_token'),
        ('sinau_private', 'current_verified_context')
    )
)
SELECT
    f.nspname AS schema_name,
    f.proname AS function_name,
    f.signature,
    pg_catalog.has_function_privilege(r.oid, f.oid, 'EXECUTE')
        AS runtime_can_execute_without_switch
FROM runtime AS r
CROSS JOIN target_functions AS f
ORDER BY f.nspname, f.proname, f.signature::pg_catalog.text;

\echo '===== 6. OBJECT OWNERSHIP AND RUNTIME CREATE/ALTER SURFACE ====='
SELECT
    'SCHEMA' AS object_type,
    n.nspname AS object_name,
    pg_catalog.pg_get_userbyid(n.nspowner) AS owner,
    pg_catalog.has_schema_privilege(
        'sinau_app_runtime_poc', n.oid, 'CREATE'
    ) AS runtime_can_create
FROM pg_catalog.pg_namespace AS n
WHERE n.nspname IN ('sinau_issuer_poc', 'sinau_private', 'sinau_crypto')

UNION ALL

SELECT
    'RELATION' AS object_type,
    n.nspname || '.' || c.relname AS object_name,
    pg_catalog.pg_get_userbyid(c.relowner) AS owner,
    pg_catalog.has_table_privilege(
        'sinau_app_runtime_poc', c.oid, 'TRIGGER'
    ) AS runtime_can_create_trigger
FROM pg_catalog.pg_class AS c
JOIN pg_catalog.pg_namespace AS n
  ON n.oid = c.relnamespace
WHERE (n.nspname, c.relname) IN (
    ('sinau_issuer_poc', 'poc_identities'),
    ('sinau_issuer_poc', 'poc_auth_sessions'),
    ('sinau_issuer_poc', 'poc_tenant_memberships'),
    ('sinau_issuer_poc', 'poc_unit_memberships'),
    ('sinau_private', 'context_keys')
)

UNION ALL

SELECT
    'FUNCTION' AS object_type,
    n.nspname || '.' || p.proname || '(' ||
        pg_catalog.pg_get_function_identity_arguments(p.oid) || ')' AS object_name,
    pg_catalog.pg_get_userbyid(p.proowner) AS owner,
    pg_catalog.has_function_privilege(
        'sinau_app_runtime_poc', p.oid, 'EXECUTE'
    ) AS runtime_can_execute
FROM pg_catalog.pg_proc AS p
JOIN pg_catalog.pg_namespace AS n
  ON n.oid = p.pronamespace
WHERE (n.nspname, p.proname) IN (
    ('sinau_issuer_poc', 'validate_context_request'),
    ('sinau_issuer_poc', 'has_feature_entitlement'),
    ('sinau_private', 'verify_context_token'),
    ('sinau_private', 'current_verified_context')
)
ORDER BY object_type, object_name;

\echo '===== 7. DEFAULT PRIVILEGES FOR THE CONTEXT OWNER ====='
SELECT
    pg_catalog.pg_get_userbyid(d.defaclrole) AS object_creator_role,
    COALESCE(n.nspname, '<all schemas>') AS schema_name,
    d.defaclobjtype AS object_type_code,
    d.defaclacl AS default_acl
FROM pg_catalog.pg_default_acl AS d
LEFT JOIN pg_catalog.pg_namespace AS n
  ON n.oid = d.defaclnamespace
WHERE d.defaclrole = (
    SELECT oid
    FROM pg_catalog.pg_roles
    WHERE rolname = 'sinau_context_owner'
)
ORDER BY schema_name, object_type_code;

ROLLBACK;

\echo '===== RUNTIME ROLE BOUNDARY AUDIT COMPLETE — ROLLED BACK ====='
