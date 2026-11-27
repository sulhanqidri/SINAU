-- SINAU PostgreSQL 18 Design PoC
-- Correct context-owner default EXECUTE for newly created functions.
-- Run ONLY as PostgreSQL superuser postgres against sinau_design_poc.
--
-- Persistent intended change:
--   ALTER DEFAULT PRIVILEGES FOR ROLE sinau_context_owner
--   REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
--
-- A temporary probe function is created and checked in a second transaction
-- that ends with ROLLBACK. Existing functions/ACLs are inspected, not changed.
-- No table/data/role/membership/schema/RLS-policy changes are performed.

\set ON_ERROR_STOP on
\pset pager off
\echo '===== SINAU POC — CONTEXT OWNER DEFAULT FUNCTION ACL FIX ====='

DO $preflight$
DECLARE
    v_owner_oid pg_catalog.oid;
    v_schema_owner pg_catalog.oid;
    v_function_count pg_catalog.int4;
    v_public_exec_count pg_catalog.int4;
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

    SELECT oid
      INTO v_owner_oid
      FROM pg_catalog.pg_roles
     WHERE rolname = 'sinau_context_owner'
       AND NOT rolcanlogin
       AND NOT rolsuper
       AND NOT rolbypassrls;

    IF v_owner_oid IS NULL THEN
        RAISE EXCEPTION
            'SAFETY STOP: expected NOLOGIN non-superuser sinau_context_owner role';
    END IF;

    SELECT nspowner
      INTO v_schema_owner
      FROM pg_catalog.pg_namespace
     WHERE nspname = 'sinau_private';

    IF v_schema_owner IS DISTINCT FROM v_owner_oid THEN
        RAISE EXCEPTION
            'SAFETY STOP: sinau_private is not owned by sinau_context_owner';
    END IF;

    SELECT pg_catalog.count(*)
      INTO v_function_count
      FROM pg_catalog.pg_proc AS p
      JOIN pg_catalog.pg_namespace AS n
        ON n.oid = p.pronamespace
     WHERE (n.nspname, p.proname) IN (
         ('sinau_private', 'verify_context_token'),
         ('sinau_private', 'current_verified_context'),
         ('sinau_issuer_poc', 'validate_context_request'),
         ('sinau_issuer_poc', 'has_feature_entitlement')
     )
       AND p.proowner = v_owner_oid;

    IF v_function_count <> 4 THEN
        RAISE EXCEPTION
            'SAFETY STOP: expected four installed context functions owned by sinau_context_owner; found %',
            v_function_count;
    END IF;

    SELECT pg_catalog.count(*)
      INTO v_public_exec_count
      FROM pg_catalog.pg_proc AS p
      JOIN pg_catalog.pg_namespace AS n
        ON n.oid = p.pronamespace
     CROSS JOIN LATERAL pg_catalog.aclexplode(
         COALESCE(p.proacl, pg_catalog.acldefault('f', p.proowner))
     ) AS acl
     WHERE (n.nspname, p.proname) IN (
         ('sinau_private', 'verify_context_token'),
         ('sinau_private', 'current_verified_context'),
         ('sinau_issuer_poc', 'validate_context_request'),
         ('sinau_issuer_poc', 'has_feature_entitlement')
     )
       AND acl.grantee = 0
       AND acl.privilege_type = 'EXECUTE';

    IF v_public_exec_count <> 0 THEN
        RAISE EXCEPTION
            'SAFETY STOP: one or more existing context functions still have PUBLIC EXECUTE';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_catalog.pg_proc AS p
        JOIN pg_catalog.pg_namespace AS n
          ON n.oid = p.pronamespace
        WHERE n.nspname = 'sinau_private'
          AND p.proname = 'poc_default_acl_probe'
    ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: temporary probe function name already exists';
    END IF;
END
$preflight$;

\echo '===== 1. PRE-FIX DEFAULT ACL STATE ====='
SELECT
    pg_catalog.pg_get_userbyid(d.defaclrole) AS creator_role,
    CASE WHEN d.defaclnamespace = 0
         THEN '<GLOBAL>'
         ELSE n.nspname
    END AS scope,
    d.defaclobjtype AS object_type_code,
    d.defaclacl AS default_acl,
    EXISTS (
        SELECT 1
        FROM pg_catalog.aclexplode(d.defaclacl) AS acl
        WHERE acl.grantee = 0
          AND acl.privilege_type = 'EXECUTE'
    ) AS public_execute_explicit_in_acl
FROM pg_catalog.pg_default_acl AS d
LEFT JOIN pg_catalog.pg_namespace AS n
  ON n.oid = d.defaclnamespace
WHERE d.defaclrole = (
    SELECT oid
    FROM pg_catalog.pg_roles
    WHERE rolname = 'sinau_context_owner'
)
  AND d.defaclobjtype = 'f'
ORDER BY d.defaclnamespace;

\echo '===== 2. APPLY GLOBAL DEFAULT ACL REVOCATION ====='
BEGIN;
SET LOCAL ROLE sinau_context_owner;

-- IMPORTANT: no IN SCHEMA clause. PostgreSQL's built-in function default
-- EXECUTE for PUBLIC is global; schema-scoped REVOKE cannot remove it.
ALTER DEFAULT PRIVILEGES
    FOR ROLE sinau_context_owner
    REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

COMMIT;

\echo '===== 3. VERIFY STORED GLOBAL DEFAULT ACL ====='
DO $default_acl_assert$
DECLARE
    v_owner_oid pg_catalog.oid;
    v_acl pg_catalog.aclitem[];
    v_public_exec pg_catalog.bool;
BEGIN
    SELECT oid
      INTO v_owner_oid
      FROM pg_catalog.pg_roles
     WHERE rolname = 'sinau_context_owner';

    SELECT defaclacl
      INTO v_acl
      FROM pg_catalog.pg_default_acl
     WHERE defaclrole = v_owner_oid
       AND defaclnamespace = 0
       AND defaclobjtype = 'f';

    IF v_acl IS NULL THEN
        RAISE EXCEPTION
            'FAIL: global function default ACL row for sinau_context_owner is missing';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM pg_catalog.aclexplode(v_acl) AS acl
        WHERE acl.grantee = 0
          AND acl.privilege_type = 'EXECUTE'
    )
    INTO v_public_exec;

    IF v_public_exec THEN
        RAISE EXCEPTION
            'FAIL: PUBLIC still has default EXECUTE on future context-owner functions';
    END IF;

    RAISE NOTICE
        'PASS: global function default ACL exists and PUBLIC EXECUTE is absent';
END
$default_acl_assert$;

SELECT
    pg_catalog.pg_get_userbyid(d.defaclrole) AS creator_role,
    CASE WHEN d.defaclnamespace = 0
         THEN '<GLOBAL>'
         ELSE n.nspname
    END AS scope,
    d.defaclobjtype AS object_type_code,
    d.defaclacl AS default_acl,
    EXISTS (
        SELECT 1
        FROM pg_catalog.aclexplode(d.defaclacl) AS acl
        WHERE acl.grantee = 0
          AND acl.privilege_type = 'EXECUTE'
    ) AS public_execute_explicit_in_acl
FROM pg_catalog.pg_default_acl AS d
LEFT JOIN pg_catalog.pg_namespace AS n
  ON n.oid = d.defaclnamespace
WHERE d.defaclrole = (
    SELECT oid
    FROM pg_catalog.pg_roles
    WHERE rolname = 'sinau_context_owner'
)
  AND d.defaclobjtype = 'f'
ORDER BY d.defaclnamespace;

\echo '===== 4. VERIFY EXISTING CONTEXT FUNCTION ACLS ====='
SELECT
    n.nspname AS schema_name,
    p.proname AS function_name,
    p.oid::pg_catalog.regprocedure AS signature,
    pg_catalog.pg_get_userbyid(p.proowner) AS owner,
    p.proacl AS function_acl,
    EXISTS (
        SELECT 1
        FROM pg_catalog.aclexplode(
            COALESCE(p.proacl, pg_catalog.acldefault('f', p.proowner))
        ) AS acl
        WHERE acl.grantee = 0
          AND acl.privilege_type = 'EXECUTE'
    ) AS public_can_execute
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

\echo '===== 5. CREATE FUTURE-FUNCTION PROBE IN ROLLBACK-ONLY TRANSACTION ====='
BEGIN;
SET LOCAL ROLE sinau_context_owner;

CREATE FUNCTION sinau_private.poc_default_acl_probe()
RETURNS pg_catalog.bool
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
SECURITY INVOKER
SET search_path = pg_catalog, pg_temp
AS $probe$
    SELECT true
$probe$;

RESET ROLE;

DO $probe_assert$
DECLARE
    v_oid pg_catalog.oid;
    v_owner pg_catalog.oid;
    v_acl pg_catalog.aclitem[];
    v_public_exec pg_catalog.bool;
    v_owner_exec pg_catalog.bool;
BEGIN
    SELECT p.oid, p.proowner, p.proacl
      INTO v_oid, v_owner, v_acl
      FROM pg_catalog.pg_proc AS p
      JOIN pg_catalog.pg_namespace AS n
        ON n.oid = p.pronamespace
     WHERE n.nspname = 'sinau_private'
       AND p.proname = 'poc_default_acl_probe'
       AND p.pronargs = 0;

    IF v_oid IS NULL
       OR v_owner <> (
           SELECT oid FROM pg_catalog.pg_roles
           WHERE rolname = 'sinau_context_owner'
       ) THEN
        RAISE EXCEPTION
            'FAIL: probe function is missing or has the wrong owner';
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM pg_catalog.aclexplode(
            COALESCE(v_acl, pg_catalog.acldefault('f', v_owner))
        ) AS acl
        WHERE acl.grantee = 0
          AND acl.privilege_type = 'EXECUTE'
    )
    INTO v_public_exec;

    SELECT EXISTS (
        SELECT 1
        FROM pg_catalog.aclexplode(
            COALESCE(v_acl, pg_catalog.acldefault('f', v_owner))
        ) AS acl
        WHERE acl.grantee = v_owner
          AND acl.privilege_type = 'EXECUTE'
    )
    INTO v_owner_exec;

    IF v_public_exec OR NOT v_owner_exec THEN
        RAISE EXCEPTION
            'FAIL: probe ACL invalid (PUBLIC EXECUTE %, owner EXECUTE %)',
            v_public_exec, v_owner_exec;
    END IF;

    RAISE NOTICE
        'PASS: newly created probe excludes PUBLIC and retains owner EXECUTE';
END
$probe_assert$;

SELECT
    p.oid::pg_catalog.regprocedure AS probe_signature,
    pg_catalog.pg_get_userbyid(p.proowner) AS owner,
    p.proacl AS probe_acl,
    EXISTS (
        SELECT 1
        FROM pg_catalog.aclexplode(
            COALESCE(p.proacl, pg_catalog.acldefault('f', p.proowner))
        ) AS acl
        WHERE acl.grantee = 0
          AND acl.privilege_type = 'EXECUTE'
    ) AS public_can_execute,
    EXISTS (
        SELECT 1
        FROM pg_catalog.aclexplode(
            COALESCE(p.proacl, pg_catalog.acldefault('f', p.proowner))
        ) AS acl
        WHERE acl.grantee = p.proowner
          AND acl.privilege_type = 'EXECUTE'
    ) AS owner_can_execute
FROM pg_catalog.pg_proc AS p
WHERE p.oid = (
    SELECT p2.oid
    FROM pg_catalog.pg_proc AS p2
    JOIN pg_catalog.pg_namespace AS n
      ON n.oid = p2.pronamespace
    WHERE n.nspname = 'sinau_private'
      AND p2.proname = 'poc_default_acl_probe'
      AND p2.pronargs = 0
);

ROLLBACK;

\echo '===== 6. FINAL PERSISTENCE CHECK ====='
BEGIN READ ONLY;

SELECT
    EXISTS (
        SELECT 1
        FROM pg_catalog.pg_proc AS p
        JOIN pg_catalog.pg_namespace AS n
          ON n.oid = p.pronamespace
        WHERE n.nspname = 'sinau_private'
          AND p.proname = 'poc_default_acl_probe'
    ) AS probe_function_persisted,
    EXISTS (
        SELECT 1
        FROM pg_catalog.pg_default_acl AS d
        WHERE d.defaclrole = (
            SELECT oid FROM pg_catalog.pg_roles
            WHERE rolname = 'sinau_context_owner'
        )
          AND d.defaclnamespace = 0
          AND d.defaclobjtype = 'f'
    ) AS global_default_acl_persisted;

ROLLBACK;

\echo '===== CONTEXT OWNER DEFAULT FUNCTION ACL FIX COMPLETE ====='
