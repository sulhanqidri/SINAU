-- SINAU PostgreSQL 18 Design PoC
-- Script 036: query-side RLS enforcement for education_units.list_all.
--
-- Run ONLY as PostgreSQL administrator against sinau_design_poc.
-- Every schema/function/policy/fixture/token is transaction-scoped and the
-- final ROLLBACK must restore the original tenant-only education_units policy.
--
-- The v1 context token has actor/tenant/unit/XID claims, but no permission
-- claim. This candidate therefore derives current authorization from the
-- cryptographically verified actor/tenant/unit context AND synthetic current
-- membership/role/permission state inside a SECURITY DEFINER query helper.
-- A NULL unit claim alone never grants tenant-wide enumeration.
--
-- This is test-only. It does not alter the token verifier or any permanent
-- RLS policy. All identities and session strings are synthetic.

\set ON_ERROR_STOP on
\pset pager off

\echo '===== SINAU POC — EDUCATION-UNIT PERMISSION STATE FRESHNESS ====='

DO $preflight$
DECLARE
    v_policy_count pg_catalog.int8;
    v_total_policies pg_catalog.int8;
    v_tenant_a_units pg_catalog.int8;
    v_tenant_b_units pg_catalog.int8;
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

    IF pg_catalog.to_regprocedure(
        'sinau_private.current_verified_context()'
    ) IS NULL
       OR pg_catalog.to_regprocedure(
        'sinau_private.verify_context_token(text)'
    ) IS NULL
       OR pg_catalog.to_regclass(
        'sinau_private.context_keys'
    ) IS NULL THEN
        RAISE EXCEPTION
            'Signed-context verifier/accessor/key store is missing';
    END IF;

    IF pg_catalog.to_regclass(
        'sinau_issuer_poc.poc_identities'
    ) IS NULL
       OR pg_catalog.to_regclass(
        'sinau_issuer_poc.poc_auth_sessions'
    ) IS NULL
       OR pg_catalog.to_regclass(
        'sinau_issuer_poc.poc_tenant_memberships'
    ) IS NULL
       OR pg_catalog.to_regclass(
        'sinau_issuer_poc.poc_unit_memberships'
    ) IS NULL
       OR pg_catalog.to_regclass(
        'sinau_issuer_poc.poc_units'
    ) IS NULL THEN
        RAISE EXCEPTION
            'Synthetic issuer fixtures are missing; install script 010 first';
    END IF;

    IF pg_catalog.to_regnamespace('sinau_education_units_query_freshness_poc') IS NOT NULL
       OR pg_catalog.to_regprocedure(
            'sinau_private.current_verified_education_unit_scope_freshness_poc()'
       ) IS NOT NULL THEN
        RAISE EXCEPTION
            'Refusing to reuse existing script-036 schema/function';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM sinau_issuer_poc.poc_identities
        WHERE actor_id = '97000000-0000-0000-0000-000000000001'::uuid
    ) THEN
        RAISE EXCEPTION
            'RLS-036 administrator actor fixture ID already exists';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_catalog.pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'education_units'
          AND policyname = 'education_units_select_scope_freshness_poc'
    ) THEN
        RAISE EXCEPTION
            'RLS-036 candidate policy name already exists';
    END IF;

    SELECT pg_catalog.count(*)
      INTO v_policy_count
      FROM pg_catalog.pg_policies
     WHERE schemaname = 'public'
       AND tablename = 'education_units'
       AND policyname = 'sinau_rls_isolation'
       AND cmd = 'ALL'
       AND roles @> ARRAY['sinau_rls_test']::name[];

    IF v_policy_count <> 1 THEN
        RAISE EXCEPTION
            'Expected exactly one original ALL policy for sinau_rls_test; found %',
            v_policy_count;
    END IF;

    SELECT pg_catalog.count(*)
      INTO v_total_policies
      FROM pg_catalog.pg_policies
     WHERE schemaname = 'public'
       AND tablename = 'education_units';

    IF v_total_policies <> 1 THEN
        RAISE EXCEPTION
            'Expected one total education_units policy before probe; found %',
            v_total_policies;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_class AS c
        JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relname = 'education_units'
          AND c.relrowsecurity
          AND c.relforcerowsecurity
    ) THEN
        RAISE EXCEPTION
            'education_units must already have RLS ENABLE and FORCE';
    END IF;

    IF NOT has_table_privilege(
        'sinau_rls_test', 'public.education_units', 'SELECT'
    ) OR NOT has_table_privilege(
        'sinau_rls_test', 'public.education_units', 'INSERT'
    ) OR NOT has_table_privilege(
        'sinau_rls_test', 'public.education_units', 'UPDATE'
    ) OR NOT has_table_privilege(
        'sinau_rls_test', 'public.education_units', 'DELETE'
    ) THEN
        RAISE EXCEPTION
            'Query role must hold SELECT/INSERT/UPDATE/DELETE so write denials can be attributed to RLS';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM sinau_private.context_keys
        WHERE key_id = 'poc-k1'
          AND not_before <= pg_catalog.clock_timestamp()
          AND revoked_at IS NULL
    ) THEN
        RAISE EXCEPTION
            'Active synthetic signing key poc-k1 is unavailable';
    END IF;

    SELECT
        pg_catalog.count(*) FILTER (
            WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
        ),
        pg_catalog.count(*) FILTER (
            WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
        )
      INTO v_tenant_a_units, v_tenant_b_units
      FROM public.education_units;

    IF v_tenant_a_units <> 2 OR v_tenant_b_units <> 1
       OR NOT EXISTS (
           SELECT 1
           FROM public.education_units
           WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
             AND id = '10000000-0000-0000-0000-000000000001'
       )
       OR NOT EXISTS (
           SELECT 1
           FROM public.education_units
           WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
             AND id = '10000000-0000-0000-0000-000000000002'
       )
       OR NOT EXISTS (
           SELECT 1
           FROM public.education_units
           WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
             AND id = '20000000-0000-0000-0000-000000000001'
       ) THEN
        RAISE EXCEPTION
            'Expected public education_units fixtures tenant-A=2/tenant-B=1 are not present';
    END IF;

    SELECT
        pg_catalog.count(*) FILTER (
            WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
              AND unit_status = 'active'
        ),
        pg_catalog.count(*) FILTER (
            WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
              AND unit_status = 'active'
        )
      INTO v_tenant_a_units, v_tenant_b_units
      FROM sinau_issuer_poc.poc_units;

    IF v_tenant_a_units <> 2 OR v_tenant_b_units <> 1
       OR NOT EXISTS (
           SELECT 1 FROM sinau_issuer_poc.poc_units
           WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
             AND unit_id = '10000000-0000-0000-0000-000000000001'
             AND unit_status = 'active'
       )
       OR NOT EXISTS (
           SELECT 1 FROM sinau_issuer_poc.poc_units
           WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
             AND unit_id = '10000000-0000-0000-0000-000000000002'
             AND unit_status = 'active'
       )
       OR NOT EXISTS (
           SELECT 1 FROM sinau_issuer_poc.poc_units
           WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
             AND unit_id = '20000000-0000-0000-0000-000000000001'
             AND unit_status = 'active'
       ) THEN
        RAISE EXCEPTION
            'Expected private synthetic unit catalogue active rows A1/A2/B1 are not present';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM sinau_issuer_poc.poc_unit_memberships
        WHERE actor_id = '91000000-0000-0000-0000-000000000001'
          AND tenant_id = '00000000-0000-0000-0000-000000000001'
          AND unit_id = '10000000-0000-0000-0000-000000000001'
          AND membership_status = 'active'
          AND valid_from <= pg_catalog.clock_timestamp()
          AND (valid_until IS NULL OR valid_until > pg_catalog.clock_timestamp())
          AND revoked_at IS NULL
    ) THEN
        RAISE EXCEPTION
            'Expected active synthetic A1 unit-member fixture is missing';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM sinau_issuer_poc.poc_identities
        WHERE actor_id = '91000000-0000-0000-0000-000000000001'
          AND account_status = 'active'
    ) OR NOT EXISTS (
        SELECT 1
        FROM sinau_issuer_poc.poc_tenant_memberships
        WHERE actor_id = '91000000-0000-0000-0000-000000000001'
          AND tenant_id = '00000000-0000-0000-0000-000000000001'
          AND membership_status = 'active'
          AND valid_from <= pg_catalog.clock_timestamp()
          AND (valid_until IS NULL OR valid_until > pg_catalog.clock_timestamp())
          AND revoked_at IS NULL
    ) THEN
        RAISE EXCEPTION
            'Active synthetic account/tenant membership for actor 910...001 is missing';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM sinau_issuer_poc.poc_auth_sessions
        WHERE session_hash = sinau_crypto.digest(
            pg_catalog.convert_to(
                'SINAU-POC-RLS036-UNIT-MEMBER-SESSION-NOT-A-REAL-CREDENTIAL',
                'UTF8'
            ),
            'sha256'
        )
    ) THEN
        RAISE EXCEPTION
            'RLS-036 synthetic unit-member session hash collision';
    END IF;

    RAISE NOTICE
        'PASS preflight: database, verifier, roles, original RLS policy, public unit fixtures, and signing key';
END
$preflight$;

-- Keep the original policy definition outside the rollback-only transaction
-- so the postflight can compare it after ROLLBACK.
CREATE TEMP TABLE poc_education_units_policy_before AS
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
  AND tablename = 'education_units';

DO $policy_snapshot_guard$
BEGIN
    IF (SELECT pg_catalog.count(*) FROM pg_temp.poc_education_units_policy_before) <> 1 THEN
        RAISE EXCEPTION
            'Could not snapshot exactly one original education_units policy';
    END IF;
END
$policy_snapshot_guard$;

BEGIN ISOLATION LEVEL READ COMMITTED;

LOCK TABLE public.education_units
    IN ACCESS EXCLUSIVE MODE;

-- Serialize access to the synthetic authorization source rows used by this
-- test. The fresh unit-member session below is inserted and rolled back here.
LOCK TABLE
    sinau_issuer_poc.poc_identities,
    sinau_issuer_poc.poc_auth_sessions,
    sinau_issuer_poc.poc_tenant_memberships,
    sinau_issuer_poc.poc_unit_memberships,
    sinau_issuer_poc.poc_units
IN SHARE ROW EXCLUSIVE MODE;

SET LOCAL track_functions = 'pl';

\echo '===== 1. CREATE ROLLBACK-ONLY TENANT ROLE/PERMISSION FIXTURES ====='

-- PostgreSQL database CREATE privilege is kept out of the context owner.
-- Create the temporary schema as postgres, then create contents as owner.
CREATE SCHEMA sinau_education_units_query_freshness_poc
    AUTHORIZATION sinau_context_owner;

REVOKE ALL ON SCHEMA sinau_education_units_query_freshness_poc
    FROM PUBLIC, sinau_poc, sinau_rls_test, sinau_context_issuer_poc;

GRANT USAGE ON SCHEMA sinau_education_units_query_freshness_poc
    TO sinau_context_owner;

SET LOCAL ROLE sinau_context_owner;

CREATE TABLE sinau_education_units_query_freshness_poc.poc_tenant_roles (
    role_code pg_catalog.text PRIMARY KEY,
    role_status pg_catalog.text NOT NULL
        CHECK (role_status IN ('active', 'disabled'))
);

CREATE TABLE sinau_education_units_query_freshness_poc.poc_permissions (
    permission_code pg_catalog.text PRIMARY KEY,
    scope_type pg_catalog.text NOT NULL
        CHECK (scope_type IN ('tenant', 'unit'))
);

CREATE TABLE sinau_education_units_query_freshness_poc.poc_tenant_role_permissions (
    role_code pg_catalog.text NOT NULL
        REFERENCES sinau_education_units_query_freshness_poc.poc_tenant_roles(role_code),
    permission_code pg_catalog.text NOT NULL
        REFERENCES sinau_education_units_query_freshness_poc.poc_permissions(permission_code),
    PRIMARY KEY (role_code, permission_code)
);

CREATE TABLE sinau_education_units_query_freshness_poc.poc_tenant_membership_roles (
    actor_id pg_catalog.uuid NOT NULL,
    tenant_id pg_catalog.uuid NOT NULL,
    role_code pg_catalog.text NOT NULL
        REFERENCES sinau_education_units_query_freshness_poc.poc_tenant_roles(role_code),
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

INSERT INTO sinau_education_units_query_freshness_poc.poc_tenant_roles
    (role_code, role_status)
VALUES
    ('foundation_unit_admin', 'active');

INSERT INTO sinau_education_units_query_freshness_poc.poc_permissions
    (permission_code, scope_type)
VALUES
    ('education_units.list_all', 'tenant');

INSERT INTO sinau_education_units_query_freshness_poc.poc_tenant_role_permissions
    (role_code, permission_code)
VALUES
    ('foundation_unit_admin', 'education_units.list_all');

-- Create a fresh, dedicated unit-member session for this test run.
-- Script 010's original fixture session has a one-day expiry and may be stale
-- when this later PoC runs. This synthetic session is transaction-local and
-- is removed by the final ROLLBACK; it is not bound to a session claim in v1.
RESET ROLE;

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
                'SINAU-POC-RLS036-UNIT-MEMBER-SESSION-NOT-A-REAL-CREDENTIAL',
                'UTF8'
            ),
            'sha256'
        ),
        '91000000-0000-0000-0000-000000000001',
        'active',
        pg_catalog.clock_timestamp() - INTERVAL '5 minutes',
        pg_catalog.clock_timestamp() + INTERVAL '1 day',
        NULL,
        'mfa'
    );

-- The admin has an active tenant membership and explicit list_all grant.
-- Deliberately do not create any unit membership for this actor.
INSERT INTO sinau_issuer_poc.poc_identities
    (actor_id, account_status)
VALUES
    ('97000000-0000-0000-0000-000000000001', 'active');

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
                'SINAU-POC-RLS036-FOUNDATION-ADMIN-SESSION-NOT-A-REAL-CREDENTIAL',
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
    );

INSERT INTO sinau_education_units_query_freshness_poc.poc_tenant_membership_roles
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
    );

DO $admin_fixture_guard$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sinau_issuer_poc.poc_unit_memberships
        WHERE actor_id = '97000000-0000-0000-0000-000000000001'
          AND tenant_id = '00000000-0000-0000-0000-000000000001'
    ) THEN
        RAISE EXCEPTION
            'RLS-036 administrator fixture unexpectedly has a unit membership';
    END IF;

    RAISE NOTICE
        'PASS: tenant administrator has explicit list_all but no unit membership';
END
$admin_fixture_guard$;

\echo '===== 2. CREATE VERIFIED ALLOWED-UNIT SCOPE ACCESSOR ====='

-- The function returns the exact allowed unit IDs for the current verified
-- token. All mutable identity/membership/permission checks are in one SQL
-- statement snapshot. It never trusts caller-provided actor/tenant claims.
-- Unit context: only the explicitly active unit membership is returned.
-- Tenant context: all active tenant units are returned only with list_all.
SET LOCAL ROLE sinau_context_owner;

CREATE FUNCTION sinau_private.current_verified_education_unit_scope_freshness_poc()
RETURNS TABLE (
    tenant_id pg_catalog.uuid,
    allowed_unit_ids pg_catalog.uuid[]
)
LANGUAGE sql
VOLATILE
PARALLEL UNSAFE
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $unit_scope$
    WITH verified AS MATERIALIZED (
        SELECT
            ctx.actor_id,
            ctx.tenant_id,
            ctx.unit_id
        FROM sinau_private.current_verified_context() AS ctx
    ),
    active_tenant AS MATERIALIZED (
        SELECT
            v.actor_id,
            v.tenant_id,
            v.unit_id
        FROM verified AS v
        JOIN sinau_issuer_poc.poc_identities AS i
          ON i.actor_id = v.actor_id
         AND i.account_status = 'active'
        JOIN sinau_issuer_poc.poc_tenant_memberships AS tm
          ON tm.actor_id = v.actor_id
         AND tm.tenant_id = v.tenant_id
         AND tm.membership_status = 'active'
         AND tm.valid_from <= pg_catalog.clock_timestamp()
         AND (
             tm.valid_until IS NULL
             OR tm.valid_until > pg_catalog.clock_timestamp()
         )
         AND tm.revoked_at IS NULL
        -- v1 has no session identifier. This test can confirm that the actor
        -- currently has an active session, but cannot bind/revoke this exact
        -- token against one of several concurrent sessions.
        WHERE EXISTS (
            SELECT 1
            FROM sinau_issuer_poc.poc_auth_sessions AS s
            WHERE s.actor_id = v.actor_id
              AND s.session_status = 'active'
              AND s.authenticated_at <= pg_catalog.clock_timestamp()
              AND s.expires_at > pg_catalog.clock_timestamp()
              AND s.revoked_at IS NULL
        )
    ),
    unit_member_scope AS (
        SELECT
            tenant_ctx.tenant_id,
            ARRAY[tenant_ctx.unit_id]::pg_catalog.uuid[] AS allowed_unit_ids
        FROM active_tenant AS tenant_ctx
        WHERE tenant_ctx.unit_id IS NOT NULL
          AND EXISTS (
              SELECT 1
              FROM sinau_issuer_poc.poc_unit_memberships AS um
              JOIN sinau_issuer_poc.poc_units AS pu
                ON pu.tenant_id = um.tenant_id
               AND pu.unit_id = um.unit_id
               AND pu.unit_status = 'active'
              WHERE um.actor_id = tenant_ctx.actor_id
                AND um.tenant_id = tenant_ctx.tenant_id
                AND um.unit_id = tenant_ctx.unit_id
                AND um.membership_status = 'active'
                AND um.valid_from <= pg_catalog.clock_timestamp()
                AND (
                    um.valid_until IS NULL
                    OR um.valid_until > pg_catalog.clock_timestamp()
                )
                AND um.revoked_at IS NULL
          )
    ),
    tenant_admin_scope AS (
        SELECT
            tenant_ctx.tenant_id,
            ARRAY(
                SELECT pu.unit_id
                FROM sinau_issuer_poc.poc_units AS pu
                WHERE pu.tenant_id = tenant_ctx.tenant_id
                  AND pu.unit_status = 'active'
                ORDER BY pu.unit_id
            )::pg_catalog.uuid[] AS allowed_unit_ids
        FROM active_tenant AS tenant_ctx
        WHERE tenant_ctx.unit_id IS NULL
          AND EXISTS (
              SELECT 1
              FROM sinau_education_units_query_freshness_poc.poc_tenant_membership_roles AS mr
              JOIN sinau_education_units_query_freshness_poc.poc_tenant_roles AS r
                ON r.role_code = mr.role_code
              JOIN sinau_education_units_query_freshness_poc.poc_tenant_role_permissions AS rp
                ON rp.role_code = r.role_code
              JOIN sinau_education_units_query_freshness_poc.poc_permissions AS p
                ON p.permission_code = rp.permission_code
              WHERE mr.actor_id = tenant_ctx.actor_id
                AND mr.tenant_id = tenant_ctx.tenant_id
                AND mr.assignment_status = 'active'
                AND mr.valid_from <= pg_catalog.clock_timestamp()
                AND (
                    mr.valid_until IS NULL
                    OR mr.valid_until > pg_catalog.clock_timestamp()
                )
                AND mr.revoked_at IS NULL
                AND r.role_status = 'active'
                AND rp.permission_code = 'education_units.list_all'
                AND p.scope_type = 'tenant'
          )
    )
    SELECT unit_member_scope.tenant_id, unit_member_scope.allowed_unit_ids
    FROM unit_member_scope
    UNION ALL
    SELECT tenant_admin_scope.tenant_id, tenant_admin_scope.allowed_unit_ids
    FROM tenant_admin_scope
$unit_scope$;

REVOKE ALL ON FUNCTION
    sinau_private.current_verified_education_unit_scope_freshness_poc()
FROM PUBLIC, sinau_poc;

GRANT EXECUTE ON FUNCTION
    sinau_private.current_verified_education_unit_scope_freshness_poc()
TO sinau_rls_test;

RESET ROLE;

DO $helper_privilege_guard$
BEGIN
    IF NOT has_function_privilege(
        'sinau_rls_test',
        'sinau_private.current_verified_education_unit_scope_freshness_poc()',
        'EXECUTE'
    ) THEN
        RAISE EXCEPTION
            'Query role cannot execute the scoped authorization helper';
    END IF;

    IF has_table_privilege(
        'sinau_rls_test',
        'sinau_issuer_poc.poc_tenant_memberships',
        'SELECT'
    ) OR has_table_privilege(
        'sinau_rls_test',
        'sinau_issuer_poc.poc_unit_memberships',
        'SELECT'
    ) OR has_table_privilege(
        'sinau_rls_test',
        'sinau_education_units_query_freshness_poc.poc_tenant_membership_roles',
        'SELECT'
    ) THEN
        RAISE EXCEPTION
            'Query role can directly read authorization source tables';
    END IF;

    RAISE NOTICE
        'PASS: query role can execute only the narrow helper, not read membership/permission source tables';
END
$helper_privilege_guard$;

\echo '===== 3. TEMPORARILY INSTALL SELECT-ONLY CANDIDATE POLICY ====='

DROP POLICY sinau_rls_isolation ON public.education_units;

CREATE POLICY education_units_select_scope_freshness_poc
ON public.education_units
FOR SELECT
TO sinau_rls_test
USING (
    (tenant_id, id) IN (
        SELECT
            scope.tenant_id,
            allowed.unit_id
        FROM sinau_private.current_verified_education_unit_scope_freshness_poc() AS scope
        CROSS JOIN LATERAL
            pg_catalog.unnest(scope.allowed_unit_ids) AS allowed(unit_id)
    )
);

\echo 'PASS: SELECT-only RLS policy candidate installed inside transaction'

-- Sign three v1 contexts directly inside this disposable admin transaction.
-- The HMAC key is read only by postgres and token contents are never selected
-- or printed. Each token is bound to this transaction's XID.
CREATE TEMP TABLE poc_education_units_context_tokens (
    token_name pg_catalog.text PRIMARY KEY,
    token_value pg_catalog.text NOT NULL
) ON COMMIT DROP;

WITH signing_key AS MATERIALIZED (
    SELECT ck.key_id, ck.secret_bytes
    FROM sinau_private.context_keys AS ck
    WHERE ck.key_id = 'poc-k1'
      AND ck.not_before <= pg_catalog.clock_timestamp()
      AND ck.revoked_at IS NULL
),
claims(token_name, actor_id, tenant_id, unit_id) AS (
    VALUES
        (
            'ordinary-unit-a1'::pg_catalog.text,
            '91000000-0000-0000-0000-000000000001'::pg_catalog.uuid,
            '00000000-0000-0000-0000-000000000001'::pg_catalog.uuid,
            '10000000-0000-0000-0000-000000000001'::pg_catalog.uuid
        ),
        (
            'ordinary-tenant-only'::pg_catalog.text,
            '91000000-0000-0000-0000-000000000001'::pg_catalog.uuid,
            '00000000-0000-0000-0000-000000000001'::pg_catalog.uuid,
            NULL::pg_catalog.uuid
        ),
        (
            'foundation-admin-tenant-only'::pg_catalog.text,
            '97000000-0000-0000-0000-000000000001'::pg_catalog.uuid,
            '00000000-0000-0000-0000-000000000001'::pg_catalog.uuid,
            NULL::pg_catalog.uuid
        )
),
clock_values AS MATERIALIZED (
    SELECT
        pg_catalog.floor(
            EXTRACT(EPOCH FROM pg_catalog.clock_timestamp())
        )::pg_catalog.int8 AS issued_at,
        pg_catalog.pg_current_xact_id()::pg_catalog.text AS xid_text
),
payloads AS (
    SELECT
        c.token_name,
        sk.secret_bytes,
        'v1|sinau_design_poc|' || sk.key_id || '|' ||
        c.actor_id::pg_catalog.text || '|' ||
        c.tenant_id::pg_catalog.text || '|' ||
        COALESCE(c.unit_id::pg_catalog.text, '-') || '|' ||
        cv.xid_text || '|' ||
        cv.issued_at::pg_catalog.text || '|' ||
        (cv.issued_at + 240)::pg_catalog.text || '|' ||
        pg_catalog.replace(pg_catalog.gen_random_uuid()::pg_catalog.text, '-', '')
        AS payload
    FROM claims AS c
    CROSS JOIN signing_key AS sk
    CROSS JOIN clock_values AS cv
)
INSERT INTO pg_temp.poc_education_units_context_tokens
    (token_name, token_value)
SELECT
    token_name,
    payload || '|' ||
    pg_catalog.encode(
        sinau_crypto.hmac(
            pg_catalog.convert_to(payload, 'UTF8'),
            secret_bytes,
            'sha256'
        ),
        'hex'
    )
FROM payloads;

DO $token_guard$
BEGIN
    IF (
        SELECT pg_catalog.count(*)
        FROM pg_temp.poc_education_units_context_tokens
    ) <> 3 THEN
        RAISE EXCEPTION
            'Expected three synthetic transaction-bound context tokens';
    END IF;

    RAISE NOTICE
        'PASS: three synthetic v1 contexts signed for this XID; token values remain in postgres-owned temporary storage';
END
$token_guard$;

\echo '===== 3A. EXPLAIN THE SELECT POLICY SUBPLAN ====='

DO $load_explain_context$
DECLARE
    v_token pg_catalog.text;
BEGIN
    SELECT token_value INTO v_token
    FROM pg_temp.poc_education_units_context_tokens
    WHERE token_name = 'foundation-admin-tenant-only';

    IF v_token IS NULL THEN
        RAISE EXCEPTION 'Missing synthetic administrator token';
    END IF;

    PERFORM pg_catalog.set_config('app.context_token', v_token, true);
    RAISE NOTICE 'PASS: administrator context staged without printing its token';
END
$load_explain_context$;

SET LOCAL ROLE sinau_rls_test;

EXPLAIN (VERBOSE, COSTS OFF)
SELECT pg_catalog.count(*)
FROM public.education_units;

RESET ROLE;

CREATE TEMP TABLE poc_education_units_verifier_baseline (
    calls pg_catalog.int8 NOT NULL
) ON COMMIT DROP;

INSERT INTO pg_temp.poc_education_units_verifier_baseline(calls)
SELECT COALESCE(s.calls, 0)
FROM pg_catalog.pg_proc AS p
LEFT JOIN pg_catalog.pg_stat_xact_user_functions AS s
  ON s.funcid = p.oid
WHERE p.oid =
    'sinau_private.verify_context_token(text)'::pg_catalog.regprocedure;

\echo '===== 4. TEST ROW VISIBILITY UNDER VERIFIED CONTEXT ====='

-- EU-RLS-01: a unit-A1 member sees A1 only.
DO $load_unit_member_context$
DECLARE
    v_token pg_catalog.text;
BEGIN
    SELECT token_value INTO v_token
    FROM pg_temp.poc_education_units_context_tokens
    WHERE token_name = 'ordinary-unit-a1';

    IF v_token IS NULL THEN
        RAISE EXCEPTION 'Missing synthetic unit-member token';
    END IF;

    PERFORM pg_catalog.set_config('app.context_token', v_token, true);
END
$load_unit_member_context$;

SET LOCAL ROLE sinau_rls_test;

DO $unit_member_visibility$
DECLARE
    v_rows pg_catalog.int8;
    v_a1 pg_catalog.int8;
    v_a2 pg_catalog.int8;
    v_b1 pg_catalog.int8;
BEGIN
    SELECT
        pg_catalog.count(*),
        pg_catalog.count(*) FILTER (
            WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
              AND id = '10000000-0000-0000-0000-000000000001'
        ),
        pg_catalog.count(*) FILTER (
            WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
              AND id = '10000000-0000-0000-0000-000000000002'
        ),
        pg_catalog.count(*) FILTER (
            WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
              AND id = '20000000-0000-0000-0000-000000000001'
        )
      INTO v_rows, v_a1, v_a2, v_b1
      FROM public.education_units;

    IF v_rows <> 1 OR v_a1 <> 1 OR v_a2 <> 0 OR v_b1 <> 0 THEN
        RAISE EXCEPTION
            'FAIL EU-RLS-01: unit A1 expected only A1, got rows/A1/A2/B1=%/%/%/%',
            v_rows, v_a1, v_a2, v_b1;
    END IF;
    RAISE NOTICE
        'PASS EU-RLS-01: unit-scoped member sees A1 only; sibling and foreign units hidden';
END
$unit_member_visibility$;

RESET ROLE;

-- EU-RLS-02: a tenant-only member without list_all sees no unit rows.
DO $load_ordinary_tenant_context$
DECLARE
    v_token pg_catalog.text;
BEGIN
    SELECT token_value INTO v_token
    FROM pg_temp.poc_education_units_context_tokens
    WHERE token_name = 'ordinary-tenant-only';

    IF v_token IS NULL THEN
        RAISE EXCEPTION 'Missing synthetic ordinary tenant token';
    END IF;

    PERFORM pg_catalog.set_config('app.context_token', v_token, true);
END
$load_ordinary_tenant_context$;

SET LOCAL ROLE sinau_rls_test;

DO $ordinary_tenant_visibility$
DECLARE
    v_rows pg_catalog.int8;
BEGIN
    SELECT pg_catalog.count(*)
      INTO v_rows
      FROM public.education_units;

    IF v_rows <> 0 THEN
        RAISE EXCEPTION
            'FAIL EU-RLS-02: tenant-only member without list_all saw % rows',
            v_rows;
    END IF;
    RAISE NOTICE
        'PASS EU-RLS-02: tenant membership without list_all cannot enumerate sibling units';
END
$ordinary_tenant_visibility$;

RESET ROLE;

-- EU-RLS-03: an admin with explicit tenant list_all sees A1/A2 only.
DO $load_tenant_admin_context$
DECLARE
    v_token pg_catalog.text;
BEGIN
    SELECT token_value INTO v_token
    FROM pg_temp.poc_education_units_context_tokens
    WHERE token_name = 'foundation-admin-tenant-only';

    IF v_token IS NULL THEN
        RAISE EXCEPTION 'Missing synthetic administrator token';
    END IF;

    PERFORM pg_catalog.set_config('app.context_token', v_token, true);
END
$load_tenant_admin_context$;

SET LOCAL ROLE sinau_rls_test;

DO $tenant_admin_visibility$
DECLARE
    v_rows pg_catalog.int8;
    v_a1 pg_catalog.int8;
    v_a2 pg_catalog.int8;
    v_b1 pg_catalog.int8;
BEGIN
    SELECT
        pg_catalog.count(*),
        pg_catalog.count(*) FILTER (
            WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
              AND id = '10000000-0000-0000-0000-000000000001'
        ),
        pg_catalog.count(*) FILTER (
            WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
              AND id = '10000000-0000-0000-0000-000000000002'
        ),
        pg_catalog.count(*) FILTER (
            WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
              AND id = '20000000-0000-0000-0000-000000000001'
        )
      INTO v_rows, v_a1, v_a2, v_b1
      FROM public.education_units;

    IF v_rows <> 2 OR v_a1 <> 1 OR v_a2 <> 1 OR v_b1 <> 0 THEN
        RAISE EXCEPTION
            'FAIL EU-RLS-03: admin expected tenant A units A1/A2 only, got rows/A1/A2/B1=%/%/%/%',
            v_rows, v_a1, v_a2, v_b1;
    END IF;
    RAISE NOTICE
        'PASS EU-RLS-03: explicit tenant list_all sees A1/A2 but not tenant B';
END
$tenant_admin_visibility$;

RESET ROLE;

\\echo '===== 5. RE-EVALUATE TENANT ROLE/PERMISSION STATE BETWEEN PROTECTED SELECTS ====='

-- Revoke the administrator's tenant-role assignment. The existing signed
-- context token and transaction XID remain unchanged.
SET LOCAL ROLE sinau_context_owner;
DO $revoke_role_assignment$
DECLARE
    v_rows pg_catalog.int8;
BEGIN
    UPDATE sinau_education_units_query_freshness_poc.poc_tenant_membership_roles
       SET assignment_status = 'revoked',
           revoked_at = pg_catalog.clock_timestamp()
     WHERE actor_id = '97000000-0000-0000-0000-000000000001'
       AND tenant_id = '00000000-0000-0000-0000-000000000001'
       AND role_code = 'foundation_unit_admin';

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN
        RAISE EXCEPTION
            'Expected to revoke exactly one tenant-role assignment; changed %',
            v_rows;
    END IF;
END
$revoke_role_assignment$;
RESET ROLE;

SET LOCAL ROLE sinau_rls_test;
DO $role_assignment_revocation_visibility$
DECLARE
    v_rows pg_catalog.int8;
BEGIN
    SELECT pg_catalog.count(*) INTO v_rows
    FROM public.education_units;

    IF v_rows <> 0 THEN
        RAISE EXCEPTION
            'FAIL EU-RLS-08: revoked tenant-role assignment still exposed % units',
            v_rows;
    END IF;
    RAISE NOTICE
        'PASS EU-RLS-08: tenant-role assignment revocation is observed by the next protected SELECT';
END
$role_assignment_revocation_visibility$;
RESET ROLE;

-- Restore the role assignment and prove the same context can regain only its
-- explicitly granted tenant list capability.
SET LOCAL ROLE sinau_context_owner;
DO $restore_role_assignment$
DECLARE
    v_rows pg_catalog.int8;
BEGIN
    UPDATE sinau_education_units_query_freshness_poc.poc_tenant_membership_roles
       SET assignment_status = 'active',
           revoked_at = NULL
     WHERE actor_id = '97000000-0000-0000-0000-000000000001'
       AND tenant_id = '00000000-0000-0000-0000-000000000001'
       AND role_code = 'foundation_unit_admin';

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN
        RAISE EXCEPTION
            'Expected to restore exactly one tenant-role assignment; changed %',
            v_rows;
    END IF;
END
$restore_role_assignment$;
RESET ROLE;

SET LOCAL ROLE sinau_rls_test;
DO $role_assignment_restoration_visibility$
DECLARE
    v_rows pg_catalog.int8;
BEGIN
    SELECT pg_catalog.count(*) INTO v_rows
    FROM public.education_units;

    IF v_rows <> 2 THEN
        RAISE EXCEPTION
            'FAIL EU-RLS-09: restored tenant-role assignment expected two units, got %',
            v_rows;
    END IF;
    RAISE NOTICE
        'PASS EU-RLS-09: restored active tenant-role assignment restores only tenant-A listing';
END
$role_assignment_restoration_visibility$;
RESET ROLE;

-- Remove the explicit permission mapping while leaving the tenant-role
-- assignment active. The permission must be re-evaluated, not cached.
SET LOCAL ROLE sinau_context_owner;
DO $remove_permission_mapping$
DECLARE
    v_rows pg_catalog.int8;
BEGIN
    DELETE FROM sinau_education_units_query_freshness_poc.poc_tenant_role_permissions
     WHERE role_code = 'foundation_unit_admin'
       AND permission_code = 'education_units.list_all';

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN
        RAISE EXCEPTION
            'Expected to remove exactly one list_all mapping; deleted %',
            v_rows;
    END IF;
END
$remove_permission_mapping$;
RESET ROLE;

SET LOCAL ROLE sinau_rls_test;
DO $permission_mapping_revocation_visibility$
DECLARE
    v_rows pg_catalog.int8;
BEGIN
    SELECT pg_catalog.count(*) INTO v_rows
    FROM public.education_units;

    IF v_rows <> 0 THEN
        RAISE EXCEPTION
            'FAIL EU-RLS-10: removed list_all permission mapping still exposed % units',
            v_rows;
    END IF;
    RAISE NOTICE
        'PASS EU-RLS-10: removal of education_units.list_all mapping is observed by the next protected SELECT';
END
$permission_mapping_revocation_visibility$;
RESET ROLE;

-- Reinsert the explicit mapping and prove that the helper sees the restored
-- grant on the next statement. The outer transaction still rolls everything
-- back, including this temporary reinsert.
SET LOCAL ROLE sinau_context_owner;
INSERT INTO sinau_education_units_query_freshness_poc.poc_tenant_role_permissions
    (role_code, permission_code)
VALUES
    ('foundation_unit_admin', 'education_units.list_all');
RESET ROLE;

SET LOCAL ROLE sinau_rls_test;
DO $permission_mapping_restoration_visibility$
DECLARE
    v_rows pg_catalog.int8;
BEGIN
    SELECT pg_catalog.count(*) INTO v_rows
    FROM public.education_units;

    IF v_rows <> 2 THEN
        RAISE EXCEPTION
            'FAIL EU-RLS-11: restored list_all mapping expected two units, got %',
            v_rows;
    END IF;
    RAISE NOTICE
        'PASS EU-RLS-11: restored education_units.list_all mapping restores tenant-A listing';
END
$permission_mapping_restoration_visibility$;
RESET ROLE;

-- EU-RLS-04: a malformed token fails closed.
SELECT pg_catalog.set_config(
    'app.context_token',
    'not-a-valid-context-token',
    true
) IS NOT NULL AS malformed_context_staged;

SET LOCAL ROLE sinau_rls_test;

DO $malformed_context_visibility$
DECLARE
    v_rows pg_catalog.int8;
BEGIN
    SELECT pg_catalog.count(*)
      INTO v_rows
      FROM public.education_units;

    IF v_rows <> 0 THEN
        RAISE EXCEPTION
            'FAIL EU-RLS-04: malformed token exposed % education units',
            v_rows;
    END IF;
    RAISE NOTICE
        'PASS EU-RLS-04: malformed context token exposes zero education units';
END
$malformed_context_visibility$;

RESET ROLE;

\echo '===== 6. VERIFY ONE VERIFIED-CONTEXT CALL PER PROTECTED SELECT ====='

DO $call_count_tests$
DECLARE
    v_before pg_catalog.int8;
    v_after pg_catalog.int8;
BEGIN
    SELECT calls INTO v_before
    FROM pg_temp.poc_education_units_verifier_baseline;

    SELECT COALESCE(s.calls, 0)
      INTO v_after
      FROM pg_catalog.pg_proc AS p
      LEFT JOIN pg_catalog.pg_stat_xact_user_functions AS s
        ON s.funcid = p.oid
     WHERE p.oid =
        'sinau_private.verify_context_token(text)'::pg_catalog.regprocedure;

    IF (v_after - v_before) <> 8 THEN
        RAISE EXCEPTION
            'FAIL: expected exactly eight verifier calls for eight SELECT statements; before/after/delta=%/%/%',
            v_before, v_after, v_after - v_before;
    END IF;

    RAISE NOTICE
        'PASS: eight protected SELECTs caused exactly eight verifier calls (one per statement)';
END
$call_count_tests$;

\echo '===== 7. CHECK SELECT-ONLY POLICY AND WRITE DENIAL ====='

DO $load_write_admin_context$
DECLARE
    v_token pg_catalog.text;
BEGIN
    SELECT token_value INTO v_token
    FROM pg_temp.poc_education_units_context_tokens
    WHERE token_name = 'foundation-admin-tenant-only';

    IF v_token IS NULL THEN
        RAISE EXCEPTION 'Missing synthetic administrator token for write test';
    END IF;

    PERFORM pg_catalog.set_config('app.context_token', v_token, true);
END
$load_write_admin_context$;

SET LOCAL ROLE sinau_rls_test;

DO $write_boundary_tests$
DECLARE
    v_rows pg_catalog.int8;
    v_insert_denied pg_catalog.bool := false;
BEGIN
    -- The candidate policy is explicitly SELECT-only. Because the role has
    -- table DML privileges, denied INSERT/UPDATE/DELETE outcomes are RLS
    -- behavior, not missing SQL grants.
    IF NOT EXISTS (
        SELECT 1
        FROM pg_catalog.pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'education_units'
          AND policyname = 'education_units_select_scope_freshness_poc'
          AND cmd = 'SELECT'
    ) THEN
        RAISE EXCEPTION
            'FAIL: candidate listing policy is not SELECT-only';
    END IF;

    BEGIN
        INSERT INTO public.education_units (tenant_id, id, code)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            '11000000-0000-0000-0000-000000000099',
            'RLS036-DENIED-INSERT'
        );
    EXCEPTION
        WHEN insufficient_privilege THEN
            v_insert_denied := true;
    END;

    IF NOT v_insert_denied THEN
        RAISE EXCEPTION
            'FAIL: SELECT-only candidate policy unexpectedly allowed INSERT';
    END IF;

    RAISE NOTICE
        'PASS EU-RLS-05: tenant list_all does not grant INSERT';

    UPDATE public.education_units
       SET code = 'RLS036-DENIED-UPDATE'
     WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
       AND id = '10000000-0000-0000-0000-000000000001';

    GET DIAGNOSTICS v_rows = ROW_COUNT;

    IF v_rows <> 0 THEN
        RAISE EXCEPTION
            'FAIL: SELECT-only candidate policy allowed UPDATE of % rows',
            v_rows;
    END IF;

    RAISE NOTICE
        'PASS EU-RLS-06: tenant list_all does not grant UPDATE';

    DELETE FROM public.education_units
     WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
       AND id = '10000000-0000-0000-0000-000000000001';

    GET DIAGNOSTICS v_rows = ROW_COUNT;

    IF v_rows <> 0 THEN
        RAISE EXCEPTION
            'FAIL: SELECT-only candidate policy allowed DELETE of % rows',
            v_rows;
    END IF;

    RAISE NOTICE
        'PASS EU-RLS-07: tenant list_all does not grant DELETE';
END
$write_boundary_tests$;

RESET ROLE;

\echo '===== 8. ROLLBACK AND VERIFY ORIGINAL POLICY RESTORATION ====='

ROLLBACK;

DO $postflight$
DECLARE
    v_diff pg_catalog.int8;
BEGIN
    SELECT pg_catalog.count(*)
      INTO v_diff
      FROM (
          (
              SELECT
                  schemaname, tablename, policyname,
                  permissive, roles, cmd, qual, with_check
              FROM pg_catalog.pg_policies
              WHERE schemaname = 'public'
                AND tablename = 'education_units'
              EXCEPT
              SELECT
                  schemaname, tablename, policyname,
                  permissive, roles, cmd, qual, with_check
              FROM pg_temp.poc_education_units_policy_before
          )
          UNION ALL
          (
              SELECT
                  schemaname, tablename, policyname,
                  permissive, roles, cmd, qual, with_check
              FROM pg_temp.poc_education_units_policy_before
              EXCEPT
              SELECT
                  schemaname, tablename, policyname,
                  permissive, roles, cmd, qual, with_check
              FROM pg_catalog.pg_policies
              WHERE schemaname = 'public'
                AND tablename = 'education_units'
          )
      ) AS differences;

    IF v_diff <> 0 THEN
        RAISE EXCEPTION
            'FAIL: original education_units policy differs after ROLLBACK';
    END IF;

    IF pg_catalog.to_regnamespace('sinau_education_units_query_freshness_poc') IS NOT NULL
       OR pg_catalog.to_regprocedure(
            'sinau_private.current_verified_education_unit_scope_freshness_poc()'
       ) IS NOT NULL THEN
        RAISE EXCEPTION
            'FAIL: rollback left temporary schema/function behind';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM sinau_issuer_poc.poc_identities
        WHERE actor_id = '97000000-0000-0000-0000-000000000001'
    ) THEN
        RAISE EXCEPTION
            'FAIL: rollback left synthetic administrator identity behind';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM sinau_issuer_poc.poc_auth_sessions
        WHERE session_hash = sinau_crypto.digest(
            pg_catalog.convert_to(
                'SINAU-POC-RLS036-UNIT-MEMBER-SESSION-NOT-A-REAL-CREDENTIAL',
                'UTF8'
            ),
            'sha256'
        )
    ) THEN
        RAISE EXCEPTION
            'FAIL: rollback left synthetic unit-member session behind';
    END IF;

    RAISE NOTICE
        'PASS: ROLLBACK restored the exact original education_units policy and removed temporary schema/function/fixtures';
END
$postflight$;

\echo '===== EDUCATION-UNIT PERMISSION FRESHNESS PROBE COMPLETE — ALL CHANGES ROLLED BACK ====='
\echo 'No persistent policy, verifier, role, grant, schema, token, or synthetic row changes were retained.'
