-- SINAU PostgreSQL 18 Design PoC
-- Script 034: explicit tenant permission for education-unit enumeration.
--
-- Run ONLY as PostgreSQL administrator against sinau_design_poc.
-- All objects, synthetic identities, memberships, and grants are created
-- inside one transaction and removed by the final ROLLBACK.
--
-- This script tests the issuer-side authorization gate only. It does NOT
-- install or change an RLS policy, token format, production schema, or role.
-- Fixed session strings and actor UUIDs are synthetic test data only.

\set ON_ERROR_STOP on
\pset pager off

\echo '===== SINAU POC — EXPLICIT EDUCATION-UNIT ENUMERATION PERMISSION ====='

DO $preflight$
DECLARE
    v_missing text[];
BEGIN
    IF pg_catalog.current_database() <> 'sinau_design_poc' THEN
        RAISE EXCEPTION
            'REFUSING TO RUN: expected database sinau_design_poc, got %',
            pg_catalog.current_database();
    END IF;

    IF current_user <> 'postgres' THEN
        RAISE EXCEPTION
            'REFUSING TO RUN: connect as postgres; current_user=%',
            current_user;
    END IF;

    SELECT pg_catalog.array_agg(required.object_name)
      INTO v_missing
      FROM (
          VALUES
              ('sinau_context_owner'::text),
              ('sinau_context_issuer_poc'::text),
              ('sinau_rls_test'::text)
      ) AS required(object_name)
     WHERE NOT EXISTS (
         SELECT 1 FROM pg_catalog.pg_roles r
         WHERE r.rolname = required.object_name
     );

    IF v_missing IS NOT NULL THEN
        RAISE EXCEPTION 'Missing required PoC roles: %', v_missing;
    END IF;

    IF pg_catalog.to_regclass(
        'sinau_issuer_poc.poc_tenant_memberships'
    ) IS NULL
       OR pg_catalog.to_regclass(
        'sinau_issuer_poc.poc_unit_memberships'
    ) IS NULL
       OR pg_catalog.to_regprocedure(
        'sinau_issuer_poc.validate_context_request(text,uuid,uuid)'
    ) IS NULL THEN
        RAISE EXCEPTION
            'Missing issuer fixtures/function; install and verify script 010 first';
    END IF;

    IF pg_catalog.to_regnamespace('sinau_education_units_poc') IS NOT NULL THEN
        RAISE EXCEPTION
            'Refusing to reuse existing schema sinau_education_units_poc';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM sinau_issuer_poc.poc_identities
        WHERE actor_id IN (
            '97000000-0000-0000-0000-000000000001'::uuid,
            '98000000-0000-0000-0000-000000000001'::uuid
        )
    ) THEN
        RAISE EXCEPTION 'RLS-034 synthetic actor ID collision';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM public.tenants
        WHERE id = '00000000-0000-0000-0000-000000000001'::uuid
    ) IS NOT TRUE THEN
        RAISE EXCEPTION 'Expected synthetic tenant A fixture is missing';
    END IF;

    RAISE NOTICE
        'PASS preflight: disposable database, postgres role boundary, issuer fixtures, and unique IDs';
END
$preflight$;

BEGIN;

LOCK TABLE
    sinau_issuer_poc.poc_identities,
    sinau_issuer_poc.poc_auth_sessions,
    sinau_issuer_poc.poc_tenant_memberships
IN SHARE ROW EXCLUSIVE MODE;

\echo '===== 1. CREATE ROLLBACK-ONLY TENANT ROLE/PERMISSION FIXTURES ====='

-- Create the temporary schema as the administrator, then let the
-- context owner create its tables/functions inside the owned schema.
CREATE SCHEMA sinau_education_units_poc
    AUTHORIZATION sinau_context_owner;

REVOKE ALL ON SCHEMA sinau_education_units_poc
    FROM PUBLIC, sinau_poc, sinau_rls_test, sinau_context_issuer_poc;

GRANT USAGE ON SCHEMA sinau_education_units_poc
    TO sinau_context_issuer_poc;

SET LOCAL ROLE sinau_context_owner;

CREATE TABLE sinau_education_units_poc.poc_tenant_roles (
    role_code pg_catalog.text PRIMARY KEY,
    role_status pg_catalog.text NOT NULL
        CHECK (role_status IN ('active', 'disabled'))
);

CREATE TABLE sinau_education_units_poc.poc_permissions (
    permission_code pg_catalog.text PRIMARY KEY,
    scope_type pg_catalog.text NOT NULL
        CHECK (scope_type IN ('tenant', 'unit'))
);

CREATE TABLE sinau_education_units_poc.poc_tenant_role_permissions (
    role_code pg_catalog.text NOT NULL
        REFERENCES sinau_education_units_poc.poc_tenant_roles(role_code),
    permission_code pg_catalog.text NOT NULL
        REFERENCES sinau_education_units_poc.poc_permissions(permission_code),
    PRIMARY KEY (role_code, permission_code)
);

CREATE TABLE sinau_education_units_poc.poc_tenant_membership_roles (
    actor_id pg_catalog.uuid NOT NULL,
    tenant_id pg_catalog.uuid NOT NULL,
    role_code pg_catalog.text NOT NULL
        REFERENCES sinau_education_units_poc.poc_tenant_roles(role_code),
    assignment_status pg_catalog.text NOT NULL
        CHECK (assignment_status IN ('active', 'suspended', 'revoked')),
    valid_from pg_catalog.timestamptz NOT NULL,
    valid_until pg_catalog.timestamptz,
    revoked_at pg_catalog.timestamptz,
    PRIMARY KEY (actor_id, tenant_id, role_code),
    FOREIGN KEY (actor_id, tenant_id)
        REFERENCES sinau_issuer_poc.poc_tenant_memberships(actor_id, tenant_id),
    CHECK (valid_until IS NULL OR valid_until > valid_from)
);

INSERT INTO sinau_education_units_poc.poc_tenant_roles
    (role_code, role_status)
VALUES
    ('foundation_unit_admin', 'active'),
    ('foundation_unit_admin_disabled', 'disabled');

INSERT INTO sinau_education_units_poc.poc_permissions
    (permission_code, scope_type)
VALUES
    ('education_units.list_all', 'tenant'),
    ('education_units.manage', 'tenant');

-- A role name grants nothing by itself. Only the explicit permission mapping
-- below gives this role tenant-wide enumeration capability.
INSERT INTO sinau_education_units_poc.poc_tenant_role_permissions
    (role_code, permission_code)
VALUES
    ('foundation_unit_admin', 'education_units.list_all');

\echo '===== 2. ADD SYNTHETIC TENANT ADMINISTRATOR AND SUSPENDED CONTROL ====='

INSERT INTO sinau_issuer_poc.poc_identities
    (actor_id, account_status)
VALUES
    ('97000000-0000-0000-0000-000000000001', 'active'),
    ('98000000-0000-0000-0000-000000000001', 'active');

INSERT INTO sinau_issuer_poc.poc_auth_sessions
    (
        session_hash,
        actor_id,
        session_status,
        authenticated_at,
        expires_at,
        revoked_at,
        assurance_level
    )
VALUES
    (
        sinau_crypto.digest(
            pg_catalog.convert_to(
                'SINAU-POC-RLS034-FOUNDATION-ADMIN-SESSION-NOT-A-REAL-CREDENTIAL',
                'UTF8'
            ),
            'sha256'
        ),
        '97000000-0000-0000-0000-000000000001',
        'active',
        pg_catalog.clock_timestamp() - INTERVAL '5 minutes',
        pg_catalog.clock_timestamp() + INTERVAL '1 day',
        NULL,
        'mfa'
    ),
    (
        sinau_crypto.digest(
            pg_catalog.convert_to(
                'SINAU-POC-RLS034-SUSPENDED-ADMIN-SESSION-NOT-A-REAL-CREDENTIAL',
                'UTF8'
            ),
            'sha256'
        ),
        '98000000-0000-0000-0000-000000000001',
        'active',
        pg_catalog.clock_timestamp() - INTERVAL '5 minutes',
        pg_catalog.clock_timestamp() + INTERVAL '1 day',
        NULL,
        'mfa'
    );

INSERT INTO sinau_issuer_poc.poc_tenant_memberships
    (
        actor_id,
        tenant_id,
        membership_status,
        valid_from,
        valid_until,
        revoked_at
    )
VALUES
    (
        '97000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000001',
        'active',
        pg_catalog.clock_timestamp() - INTERVAL '30 days',
        NULL,
        NULL
    ),
    (
        '98000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000001',
        'suspended',
        pg_catalog.clock_timestamp() - INTERVAL '30 days',
        NULL,
        NULL
    );

INSERT INTO sinau_education_units_poc.poc_tenant_membership_roles
    (
        actor_id,
        tenant_id,
        role_code,
        assignment_status,
        valid_from,
        valid_until,
        revoked_at
    )
VALUES
    (
        '97000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000001',
        'foundation_unit_admin',
        'active',
        pg_catalog.clock_timestamp() - INTERVAL '30 days',
        NULL,
        NULL
    ),
    (
        '98000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000001',
        'foundation_unit_admin',
        'active',
        pg_catalog.clock_timestamp() - INTERVAL '30 days',
        NULL,
        NULL
    );

DO $admin_fixture_guard$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sinau_issuer_poc.poc_unit_memberships AS um
        WHERE um.actor_id = '97000000-0000-0000-0000-000000000001'
          AND um.tenant_id = '00000000-0000-0000-0000-000000000001'
    ) THEN
        RAISE EXCEPTION
            'RLS-034 admin fixture must not have a unit membership';
    END IF;
    RAISE NOTICE
        'PASS: tenant administrator fixture has no unit membership; scope is tenant-only';
END
$admin_fixture_guard$;

\echo '===== 3. CREATE NARROW ISSUER-SIDE PERMISSION CHECK ====='

CREATE FUNCTION sinau_education_units_poc.has_tenant_permission(
    p_session_token pg_catalog.text,
    p_tenant_id pg_catalog.uuid,
    p_permission_code pg_catalog.text
)
RETURNS pg_catalog.bool
LANGUAGE plpgsql
VOLATILE
PARALLEL UNSAFE
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $permission_check$
DECLARE
    v_actor_id pg_catalog.uuid;
BEGIN
    IF p_permission_code IS NULL
       OR p_permission_code NOT IN (
           'education_units.list_all',
           'education_units.manage'
       ) THEN
        RETURN false;
    END IF;

    -- Resolve the actor from the synthetic session bearer. The caller cannot
    -- supply actor_id. NULL unit asks only for an active tenant membership;
    -- it does not itself imply the permission being checked here.
    SELECT ctx.actor_id
      INTO v_actor_id
      FROM sinau_issuer_poc.validate_context_request(
          p_session_token,
          p_tenant_id,
          NULL
      ) AS ctx;

    IF v_actor_id IS NULL THEN
        RETURN false;
    END IF;

    RETURN EXISTS (
        SELECT 1
        FROM sinau_education_units_poc.poc_tenant_membership_roles AS mr
        JOIN sinau_education_units_poc.poc_tenant_roles AS r
          ON r.role_code = mr.role_code
        JOIN sinau_education_units_poc.poc_tenant_role_permissions AS rp
          ON rp.role_code = r.role_code
        JOIN sinau_education_units_poc.poc_permissions AS p
          ON p.permission_code = rp.permission_code
       WHERE mr.actor_id = v_actor_id
         AND mr.tenant_id = p_tenant_id
         AND mr.assignment_status = 'active'
         AND mr.valid_from <= pg_catalog.clock_timestamp()
         AND (
             mr.valid_until IS NULL
             OR mr.valid_until > pg_catalog.clock_timestamp()
         )
         AND mr.revoked_at IS NULL
         AND r.role_status = 'active'
         AND rp.permission_code = p_permission_code
         AND p.scope_type = 'tenant'
    );
END
$permission_check$;

REVOKE ALL ON FUNCTION
    sinau_education_units_poc.has_tenant_permission(
        pg_catalog.text, pg_catalog.uuid, pg_catalog.text
    )
FROM PUBLIC, sinau_poc, sinau_rls_test;

GRANT EXECUTE ON FUNCTION
    sinau_education_units_poc.has_tenant_permission(
        pg_catalog.text, pg_catalog.uuid, pg_catalog.text
    )
TO sinau_context_issuer_poc;

\echo '===== 4. TEST TENANT-WIDE ENUMERATION GRANT SEMANTICS ====='

SET LOCAL ROLE sinau_context_issuer_poc;

DO $permission_tests$
DECLARE
    v_allowed pg_catalog.bool;
BEGIN
    -- EU-01: tenant administrator has explicit list_all capability.
    SELECT sinau_education_units_poc.has_tenant_permission(
        'SINAU-POC-RLS034-FOUNDATION-ADMIN-SESSION-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        'education_units.list_all'
    ) INTO v_allowed;

    IF v_allowed IS DISTINCT FROM true THEN
        RAISE EXCEPTION
            'FAIL EU-01: explicit tenant list_all permission was not honored';
    END IF;
    RAISE NOTICE
        'PASS EU-01: active tenant administrator with explicit list_all grant is authorized';

    -- EU-02: the same role does not implicitly grant write/manage permission.
    SELECT sinau_education_units_poc.has_tenant_permission(
        'SINAU-POC-RLS034-FOUNDATION-ADMIN-SESSION-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        'education_units.manage'
    ) INTO v_allowed;

    IF v_allowed IS DISTINCT FROM false THEN
        RAISE EXCEPTION
            'FAIL EU-02: list_all was incorrectly treated as manage';
    END IF;
    RAISE NOTICE
        'PASS EU-02: list_all does not imply education_units.manage';

    -- EU-03: an ordinary member with active tenant and A1 unit memberships
    -- still has no tenant-wide list permission.
    SELECT sinau_education_units_poc.has_tenant_permission(
        'SINAU-POC-ACTIVE-SESSION-A-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        'education_units.list_all'
    ) INTO v_allowed;

    IF v_allowed IS DISTINCT FROM false THEN
        RAISE EXCEPTION
            'FAIL EU-03: ordinary unit member received tenant-wide listing';
    END IF;
    RAISE NOTICE
        'PASS EU-03: unit membership and tenant membership alone do not grant list_all';

    -- EU-04: a role assignment cannot override suspended tenant membership.
    SELECT sinau_education_units_poc.has_tenant_permission(
        'SINAU-POC-RLS034-SUSPENDED-ADMIN-SESSION-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        'education_units.list_all'
    ) INTO v_allowed;

    IF v_allowed IS DISTINCT FROM false THEN
        RAISE EXCEPTION
            'FAIL EU-04: suspended tenant membership retained list_all';
    END IF;
    RAISE NOTICE
        'PASS EU-04: suspended tenant membership blocks an otherwise active role grant';

    -- EU-05: a permission in another tenant must not be inferred or reused.
    SELECT sinau_education_units_poc.has_tenant_permission(
        'SINAU-POC-RLS034-FOUNDATION-ADMIN-SESSION-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000002',
        'education_units.list_all'
    ) INTO v_allowed;

    IF v_allowed IS DISTINCT FROM false THEN
        RAISE EXCEPTION
            'FAIL EU-05: tenant-A permission leaked into tenant B';
    END IF;
    RAISE NOTICE
        'PASS EU-05: tenant-scoped role grant does not cross tenant boundary';

    -- EU-06: unknown session bearer fails closed.
    SELECT sinau_education_units_poc.has_tenant_permission(
        'SINAU-POC-RLS034-UNKNOWN-SESSION-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        'education_units.list_all'
    ) INTO v_allowed;

    IF v_allowed IS DISTINCT FROM false THEN
        RAISE EXCEPTION
            'FAIL EU-06: unknown session credential was accepted';
    END IF;
    RAISE NOTICE
        'PASS EU-06: unknown session credential fails closed';

    -- EU-07: unknown permissions fail closed.
    SELECT sinau_education_units_poc.has_tenant_permission(
        'SINAU-POC-RLS034-FOUNDATION-ADMIN-SESSION-NOT-A-REAL-CREDENTIAL',
        '00000000-0000-0000-0000-000000000001',
        'students.view_all'
    ) INTO v_allowed;

    IF v_allowed IS DISTINCT FROM false THEN
        RAISE EXCEPTION
            'FAIL EU-07: out-of-contract permission code was accepted';
    END IF;
    RAISE NOTICE
        'PASS EU-07: unregistered/out-of-contract permission code fails closed';

    -- EU-08: actor 970 has no unit membership (verified by the fixture
    -- guard before switching to the issuer role). EU-01 nevertheless passed
    -- using only active tenant membership plus the explicit tenant permission.
    RAISE NOTICE
        'PASS EU-08: explicit tenant-scope permission works without a unit membership';
END
$permission_tests$;

\echo '===== 5. VERIFY LEAST-PRIVILEGE TABLE/FUNCTION BOUNDARY ====='

RESET ROLE;

DO $privilege_tests$
BEGIN
    IF has_table_privilege(
        'sinau_context_issuer_poc',
        'sinau_education_units_poc.poc_tenant_membership_roles',
        'SELECT'
    ) THEN
        RAISE EXCEPTION
            'FAIL: issuer role can directly read tenant role assignments';
    END IF;

    IF has_table_privilege(
        'sinau_rls_test',
        'sinau_education_units_poc.poc_tenant_membership_roles',
        'SELECT'
    ) THEN
        RAISE EXCEPTION
            'FAIL: query role can directly read tenant role assignments';
    END IF;

    IF has_schema_privilege(
        'sinau_rls_test',
        'sinau_education_units_poc',
        'USAGE'
    ) THEN
        RAISE EXCEPTION
            'FAIL: query role has direct schema usage on issuer permission fixtures';
    END IF;

    IF has_function_privilege(
        'sinau_rls_test',
        'sinau_education_units_poc.has_tenant_permission(text,uuid,text)',
        'EXECUTE'
    ) THEN
        RAISE EXCEPTION
            'FAIL: query role can call issuer-side permission function';
    END IF;

    IF NOT has_function_privilege(
        'sinau_context_issuer_poc',
        'sinau_education_units_poc.has_tenant_permission(text,uuid,text)',
        'EXECUTE'
    ) THEN
        RAISE EXCEPTION
            'FAIL: issuer capability cannot execute permission function';
    END IF;

    RAISE NOTICE
        'PASS: issuer/query roles cannot directly read permission fixtures; only issuer has helper EXECUTE';
END
$privilege_tests$;

\echo '===== 6. ROLLBACK ALL SYNTHETIC ROLE/PERMISSION OBJECTS ====='

ROLLBACK;

DO $postflight$
BEGIN
    IF pg_catalog.to_regnamespace('sinau_education_units_poc') IS NOT NULL THEN
        RAISE EXCEPTION
            'FAIL: rollback left the synthetic authorization schema behind';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM sinau_issuer_poc.poc_identities
        WHERE actor_id IN (
            '97000000-0000-0000-0000-000000000001'::uuid,
            '98000000-0000-0000-0000-000000000001'::uuid
        )
    ) THEN
        RAISE EXCEPTION
            'FAIL: rollback left synthetic identity rows behind';
    END IF;

    RAISE NOTICE
        'PASS: ROLLBACK removed the synthetic tenant role, permission, helper, identity, session, and membership fixtures';
END
$postflight$;

\echo '===== EDUCATION-UNIT TENANT PERMISSION GATE COMPLETE — ALL CHANGES ROLLED BACK ====='
\echo 'No permanent RLS policy, token format, role, grant, schema, or fixture change was retained.'
