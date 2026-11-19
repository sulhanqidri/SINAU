-- SINAU PostgreSQL 18 Design PoC — synthetic identity/session/membership fixtures
-- Run ONLY as PostgreSQL administrator against sinau_design_poc.
-- Creates a private PoC schema separate from public/domain tables.
-- All identities, sessions and memberships are synthetic fixtures.
-- No production application schema or data is modified.

\set ON_ERROR_STOP on

DO $database_guard$
BEGIN
    IF pg_catalog.current_database() <> 'sinau_design_poc' THEN
        RAISE EXCEPTION
            'REFUSING TO RUN: expected database sinau_design_poc, got %',
            pg_catalog.current_database();
    END IF;
END
$database_guard$;

-- Dedicated non-login role that represents the backend issuer's narrow
-- membership-validation capability in this PoC. It is not a production role.
DO $role$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_roles
        WHERE rolname = 'sinau_context_issuer_poc'
    ) THEN
        CREATE ROLE sinau_context_issuer_poc
            NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE
            NOINHERIT NOREPLICATION NOBYPASSRLS;
    END IF;
END
$role$;

-- The existing PoC login is permitted to SET ROLE for this experiment only.
-- Do not copy this convenience grant into production.
GRANT sinau_context_issuer_poc TO sinau_poc;

CREATE SCHEMA IF NOT EXISTS sinau_issuer_poc
    AUTHORIZATION sinau_context_owner;
ALTER SCHEMA sinau_issuer_poc OWNER TO sinau_context_owner;

REVOKE ALL ON SCHEMA sinau_issuer_poc FROM PUBLIC;
REVOKE ALL ON SCHEMA sinau_issuer_poc FROM sinau_poc;
REVOKE ALL ON SCHEMA sinau_issuer_poc FROM sinau_rls_test;
GRANT USAGE ON SCHEMA sinau_issuer_poc TO sinau_context_issuer_poc;

-- Only REFERENCES on the global tenant registry is needed for fixture FKs.
-- Unit membership uses a private synthetic unit catalog because the real
-- public.education_units table is FORCE-RLS protected and must not be queried
-- before the request context has been installed.
GRANT REFERENCES ON TABLE public.tenants
    TO sinau_context_owner;

GRANT USAGE ON SCHEMA sinau_crypto TO sinau_context_owner;
GRANT EXECUTE ON FUNCTION sinau_crypto.digest(bytea, pg_catalog.text)
    TO sinau_context_owner;

BEGIN;

SET LOCAL ROLE sinau_context_owner;

CREATE TABLE IF NOT EXISTS sinau_issuer_poc.poc_identities (
    actor_id pg_catalog.uuid PRIMARY KEY,
    account_status pg_catalog.text NOT NULL
        CHECK (account_status IN ('active', 'disabled', 'locked')),
    created_at pg_catalog.timestamptz NOT NULL DEFAULT pg_catalog.clock_timestamp()
);

CREATE TABLE IF NOT EXISTS sinau_issuer_poc.poc_auth_sessions (
    session_hash pg_catalog.bytea PRIMARY KEY
        CHECK (pg_catalog.octet_length(session_hash) = 32),
    actor_id pg_catalog.uuid NOT NULL
        REFERENCES sinau_issuer_poc.poc_identities(actor_id),
    session_status pg_catalog.text NOT NULL
        CHECK (session_status IN ('active', 'revoked', 'expired')),
    authenticated_at pg_catalog.timestamptz NOT NULL,
    expires_at pg_catalog.timestamptz NOT NULL,
    revoked_at pg_catalog.timestamptz,
    assurance_level pg_catalog.text NOT NULL DEFAULT 'password'
        CHECK (assurance_level IN ('password', 'mfa', 'hardware')),
    CHECK (expires_at > authenticated_at)
);

CREATE TABLE IF NOT EXISTS sinau_issuer_poc.poc_tenant_memberships (
    actor_id pg_catalog.uuid NOT NULL
        REFERENCES sinau_issuer_poc.poc_identities(actor_id),
    tenant_id pg_catalog.uuid NOT NULL
        REFERENCES public.tenants(id),
    membership_status pg_catalog.text NOT NULL
        CHECK (membership_status IN ('active', 'suspended', 'revoked', 'expired')),
    valid_from pg_catalog.timestamptz NOT NULL,
    valid_until pg_catalog.timestamptz,
    revoked_at pg_catalog.timestamptz,
    PRIMARY KEY (actor_id, tenant_id),
    CHECK (valid_until IS NULL OR valid_until > valid_from)
);

CREATE TABLE IF NOT EXISTS sinau_issuer_poc.poc_units (
    tenant_id pg_catalog.uuid NOT NULL
        REFERENCES public.tenants(id),
    unit_id pg_catalog.uuid NOT NULL,
    unit_status pg_catalog.text NOT NULL
        CHECK (unit_status IN ('active', 'inactive', 'closed')),
    PRIMARY KEY (tenant_id, unit_id)
);

CREATE TABLE IF NOT EXISTS sinau_issuer_poc.poc_unit_memberships (
    actor_id pg_catalog.uuid NOT NULL,
    tenant_id pg_catalog.uuid NOT NULL,
    unit_id pg_catalog.uuid NOT NULL,
    membership_status pg_catalog.text NOT NULL
        CHECK (membership_status IN ('active', 'suspended', 'revoked', 'expired')),
    valid_from pg_catalog.timestamptz NOT NULL,
    valid_until pg_catalog.timestamptz,
    revoked_at pg_catalog.timestamptz,
    PRIMARY KEY (actor_id, tenant_id, unit_id),
    FOREIGN KEY (actor_id, tenant_id)
        REFERENCES sinau_issuer_poc.poc_tenant_memberships(actor_id, tenant_id),
    FOREIGN KEY (tenant_id, unit_id)
        REFERENCES sinau_issuer_poc.poc_units(tenant_id, unit_id),
    CHECK (valid_until IS NULL OR valid_until > valid_from)
);

-- Entitlements are deliberately separate from memberships and context.
CREATE TABLE IF NOT EXISTS sinau_issuer_poc.poc_feature_entitlements (
    tenant_id pg_catalog.uuid NOT NULL
        REFERENCES public.tenants(id),
    feature_code pg_catalog.text NOT NULL,
    entitlement_status pg_catalog.text NOT NULL
        CHECK (entitlement_status IN ('active', 'scheduled', 'expired', 'revoked')),
    valid_from pg_catalog.timestamptz NOT NULL,
    valid_until pg_catalog.timestamptz,
    PRIMARY KEY (tenant_id, feature_code),
    CHECK (valid_until IS NULL OR valid_until > valid_from)
);

-- The session bearer is hashed before storage. These fixed strings are public,
-- synthetic test fixtures only; they are NOT real login/session credentials.
INSERT INTO sinau_issuer_poc.poc_identities (actor_id, account_status) VALUES
('91000000-0000-0000-0000-000000000001', 'active'),
('92000000-0000-0000-0000-000000000001', 'disabled'),
('93000000-0000-0000-0000-000000000001', 'active'),
('94000000-0000-0000-0000-000000000001', 'active'),
('95000000-0000-0000-0000-000000000001', 'active'),
('96000000-0000-0000-0000-000000000001', 'active')
ON CONFLICT (actor_id) DO UPDATE
SET account_status = EXCLUDED.account_status;

INSERT INTO sinau_issuer_poc.poc_auth_sessions
    (session_hash, actor_id, session_status, authenticated_at, expires_at, revoked_at, assurance_level)
VALUES
(
    sinau_crypto.digest(
        pg_catalog.convert_to('SINAU-POC-ACTIVE-SESSION-A-NOT-A-REAL-CREDENTIAL', 'UTF8'),
        'sha256'
    ),
    '91000000-0000-0000-0000-000000000001',
    'active',
    pg_catalog.clock_timestamp() - INTERVAL '5 minutes',
    pg_catalog.clock_timestamp() + INTERVAL '1 day',
    NULL,
    'mfa'
),
(
    sinau_crypto.digest(
        pg_catalog.convert_to('SINAU-POC-REVOKED-SESSION-A-NOT-A-REAL-CREDENTIAL', 'UTF8'),
        'sha256'
    ),
    '91000000-0000-0000-0000-000000000001',
    'revoked',
    pg_catalog.clock_timestamp() - INTERVAL '1 day',
    pg_catalog.clock_timestamp() + INTERVAL '1 day',
    pg_catalog.clock_timestamp() - INTERVAL '1 hour',
    'password'
),
(
    sinau_crypto.digest(
        pg_catalog.convert_to('SINAU-POC-EXPIRED-SESSION-A-NOT-A-REAL-CREDENTIAL', 'UTF8'),
        'sha256'
    ),
    '91000000-0000-0000-0000-000000000001',
    'expired',
    pg_catalog.clock_timestamp() - INTERVAL '2 days',
    pg_catalog.clock_timestamp() - INTERVAL '1 day',
    NULL,
    'password'
),
(
    sinau_crypto.digest(
        pg_catalog.convert_to('SINAU-POC-DISABLED-ACTOR-SESSION-NOT-A-REAL-CREDENTIAL', 'UTF8'),
        'sha256'
    ),
    '92000000-0000-0000-0000-000000000001',
    'active',
    pg_catalog.clock_timestamp() - INTERVAL '5 minutes',
    pg_catalog.clock_timestamp() + INTERVAL '1 day',
    NULL,
    'mfa'
),
(
    sinau_crypto.digest(
        pg_catalog.convert_to('SINAU-POC-FUTURE-MEMBER-SESSION-NOT-A-REAL-CREDENTIAL', 'UTF8'),
        'sha256'
    ),
    '93000000-0000-0000-0000-000000000001',
    'active',
    pg_catalog.clock_timestamp() - INTERVAL '5 minutes',
    pg_catalog.clock_timestamp() + INTERVAL '1 day',
    NULL,
    'mfa'
),
(
    sinau_crypto.digest(
        pg_catalog.convert_to('SINAU-POC-EXPIRED-UNIT-SESSION-NOT-A-REAL-CREDENTIAL', 'UTF8'),
        'sha256'
    ),
    '94000000-0000-0000-0000-000000000001',
    'active',
    pg_catalog.clock_timestamp() - INTERVAL '5 minutes',
    pg_catalog.clock_timestamp() + INTERVAL '1 day',
    NULL,
    'mfa'
),
(
    sinau_crypto.digest(
        pg_catalog.convert_to('SINAU-POC-SUSPENDED-MEMBER-SESSION-NOT-A-REAL-CREDENTIAL', 'UTF8'),
        'sha256'
    ),
    '95000000-0000-0000-0000-000000000001',
    'active',
    pg_catalog.clock_timestamp() - INTERVAL '5 minutes',
    pg_catalog.clock_timestamp() + INTERVAL '1 day',
    NULL,
    'mfa'
),
(
    sinau_crypto.digest(
        pg_catalog.convert_to('SINAU-POC-EXPIRED-TENANT-MEMBER-SESSION-NOT-A-REAL-CREDENTIAL', 'UTF8'),
        'sha256'
    ),
    '96000000-0000-0000-0000-000000000001',
    'active',
    pg_catalog.clock_timestamp() - INTERVAL '5 minutes',
    pg_catalog.clock_timestamp() + INTERVAL '1 day',
    NULL,
    'mfa'
)
ON CONFLICT (session_hash) DO UPDATE
SET actor_id = EXCLUDED.actor_id,
    session_status = EXCLUDED.session_status,
    authenticated_at = EXCLUDED.authenticated_at,
    expires_at = EXCLUDED.expires_at,
    revoked_at = EXCLUDED.revoked_at,
    assurance_level = EXCLUDED.assurance_level;

INSERT INTO sinau_issuer_poc.poc_tenant_memberships
    (actor_id, tenant_id, membership_status, valid_from, valid_until, revoked_at)
VALUES
(
    '91000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'active',
    pg_catalog.clock_timestamp() - INTERVAL '30 days',
    NULL,
    NULL
),
(
    '91000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002',
    'revoked',
    pg_catalog.clock_timestamp() - INTERVAL '30 days',
    NULL,
    pg_catalog.clock_timestamp() - INTERVAL '1 day'
),
(
    '92000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'active',
    pg_catalog.clock_timestamp() - INTERVAL '30 days',
    NULL,
    NULL
),
(
    '93000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'active',
    pg_catalog.clock_timestamp() + INTERVAL '1 day',
    NULL,
    NULL
),
(
    '94000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'active',
    pg_catalog.clock_timestamp() - INTERVAL '30 days',
    NULL,
    NULL
),
(
    '95000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'suspended',
    pg_catalog.clock_timestamp() - INTERVAL '30 days',
    NULL,
    NULL
),
(
    '96000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'expired',
    pg_catalog.clock_timestamp() - INTERVAL '30 days',
    pg_catalog.clock_timestamp() - INTERVAL '1 day',
    NULL
)
ON CONFLICT (actor_id, tenant_id) DO UPDATE
SET membership_status = EXCLUDED.membership_status,
    valid_from = EXCLUDED.valid_from,
    valid_until = EXCLUDED.valid_until,
    revoked_at = EXCLUDED.revoked_at;

INSERT INTO sinau_issuer_poc.poc_units
    (tenant_id, unit_id, unit_status)
VALUES
(
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'active'
),
(
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000002',
    'active'
),
(
    '00000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000001',
    'active'
)
ON CONFLICT (tenant_id, unit_id) DO UPDATE
SET unit_status = EXCLUDED.unit_status;

INSERT INTO sinau_issuer_poc.poc_unit_memberships
    (actor_id, tenant_id, unit_id, membership_status, valid_from, valid_until, revoked_at)
VALUES
(
    '91000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'active',
    pg_catalog.clock_timestamp() - INTERVAL '30 days',
    NULL,
    NULL
),
(
    '91000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000002',
    'revoked',
    pg_catalog.clock_timestamp() - INTERVAL '30 days',
    NULL,
    pg_catalog.clock_timestamp() - INTERVAL '1 day'
),
(
    '91000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000001',
    'active',
    pg_catalog.clock_timestamp() - INTERVAL '30 days',
    NULL,
    NULL
),
(
    '92000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'active',
    pg_catalog.clock_timestamp() - INTERVAL '30 days',
    NULL,
    NULL
),
(
    '93000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'active',
    pg_catalog.clock_timestamp() - INTERVAL '30 days',
    NULL,
    NULL
),
(
    '94000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'expired',
    pg_catalog.clock_timestamp() - INTERVAL '30 days',
    pg_catalog.clock_timestamp() - INTERVAL '1 day',
    NULL
),
(
    '95000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'active',
    pg_catalog.clock_timestamp() - INTERVAL '30 days',
    NULL,
    NULL
),
(
    '96000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000001',
    'active',
    pg_catalog.clock_timestamp() - INTERVAL '30 days',
    NULL,
    NULL
)
ON CONFLICT (actor_id, tenant_id, unit_id) DO UPDATE
SET membership_status = EXCLUDED.membership_status,
    valid_from = EXCLUDED.valid_from,
    valid_until = EXCLUDED.valid_until,
    revoked_at = EXCLUDED.revoked_at;

INSERT INTO sinau_issuer_poc.poc_feature_entitlements
    (tenant_id, feature_code, entitlement_status, valid_from, valid_until)
VALUES
(
    '00000000-0000-0000-0000-000000000001',
    'poc.feature.active',
    'active',
    pg_catalog.clock_timestamp() - INTERVAL '1 day',
    pg_catalog.clock_timestamp() + INTERVAL '1 day'
),
(
    '00000000-0000-0000-0000-000000000001',
    'poc.feature.expired',
    'expired',
    pg_catalog.clock_timestamp() - INTERVAL '2 days',
    pg_catalog.clock_timestamp() - INTERVAL '1 day'
)
ON CONFLICT (tenant_id, feature_code) DO UPDATE
SET entitlement_status = EXCLUDED.entitlement_status,
    valid_from = EXCLUDED.valid_from,
    valid_until = EXCLUDED.valid_until;

-- The issuer role cannot directly read or mutate the synthetic source tables.
REVOKE ALL ON ALL TABLES IN SCHEMA sinau_issuer_poc
    FROM PUBLIC, sinau_poc, sinau_rls_test, sinau_context_issuer_poc;

-- Membership validation is performed by a narrow SECURITY DEFINER function.
CREATE OR REPLACE FUNCTION sinau_issuer_poc.validate_context_request(
    p_session_token pg_catalog.text,
    p_tenant_id pg_catalog.uuid,
    p_unit_id pg_catalog.uuid DEFAULT NULL
)
RETURNS TABLE (
    actor_id pg_catalog.uuid,
    tenant_id pg_catalog.uuid,
    unit_id pg_catalog.uuid
)
LANGUAGE plpgsql
VOLATILE
PARALLEL UNSAFE
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $validate$
DECLARE
    v_now pg_catalog.timestamptz;
    v_session_hash pg_catalog.bytea;
    v_actor_id pg_catalog.uuid;
BEGIN
    IF p_session_token IS NULL
       OR pg_catalog.octet_length(p_session_token) < 16
       OR pg_catalog.octet_length(p_session_token) > 512
       OR p_tenant_id IS NULL THEN
        RETURN;
    END IF;

    v_now := pg_catalog.clock_timestamp();
    v_session_hash := sinau_crypto.digest(
        pg_catalog.convert_to(p_session_token, 'UTF8'),
        'sha256'
    );

    SELECT s.actor_id
      INTO v_actor_id
      FROM sinau_issuer_poc.poc_auth_sessions AS s
      JOIN sinau_issuer_poc.poc_identities AS i
        ON i.actor_id = s.actor_id
     WHERE s.session_hash = v_session_hash
       AND s.session_status = 'active'
       AND s.authenticated_at <= v_now
       AND s.expires_at > v_now
       AND s.revoked_at IS NULL
       AND i.account_status = 'active';

    IF NOT FOUND THEN
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM sinau_issuer_poc.poc_tenant_memberships AS tm
        WHERE tm.actor_id = v_actor_id
          AND tm.tenant_id = p_tenant_id
          AND tm.membership_status = 'active'
          AND tm.valid_from <= v_now
          AND (tm.valid_until IS NULL OR tm.valid_until > v_now)
          AND tm.revoked_at IS NULL
    ) THEN
        RETURN;
    END IF;

    IF p_unit_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1
            FROM sinau_issuer_poc.poc_units AS pu
            WHERE pu.tenant_id = p_tenant_id
              AND pu.unit_id = p_unit_id
              AND pu.unit_status = 'active'
        ) THEN
            RETURN;
        END IF;

        IF NOT EXISTS (
            SELECT 1
            FROM sinau_issuer_poc.poc_unit_memberships AS um
            WHERE um.actor_id = v_actor_id
              AND um.tenant_id = p_tenant_id
              AND um.unit_id = p_unit_id
              AND um.membership_status = 'active'
              AND um.valid_from <= v_now
              AND (um.valid_until IS NULL OR um.valid_until > v_now)
              AND um.revoked_at IS NULL
        ) THEN
            RETURN;
        END IF;
    END IF;

    actor_id := v_actor_id;
    tenant_id := p_tenant_id;
    unit_id := p_unit_id;
    RETURN NEXT;
    RETURN;
END
$validate$;

CREATE OR REPLACE FUNCTION sinau_issuer_poc.has_feature_entitlement(
    p_tenant_id pg_catalog.uuid,
    p_feature_code pg_catalog.text
)
RETURNS pg_catalog.boolean
LANGUAGE sql
VOLATILE
PARALLEL UNSAFE
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $entitlement$
    SELECT EXISTS (
        SELECT 1
        FROM sinau_issuer_poc.poc_feature_entitlements AS e
        WHERE e.tenant_id = p_tenant_id
          AND e.feature_code = p_feature_code
          AND e.entitlement_status = 'active'
          AND e.valid_from <= pg_catalog.clock_timestamp()
          AND (e.valid_until IS NULL OR e.valid_until > pg_catalog.clock_timestamp())
    )
$entitlement$;

REVOKE ALL ON FUNCTION sinau_issuer_poc.validate_context_request(
    pg_catalog.text, pg_catalog.uuid, pg_catalog.uuid
) FROM PUBLIC;

REVOKE ALL ON FUNCTION sinau_issuer_poc.has_feature_entitlement(
    pg_catalog.uuid, pg_catalog.text
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION sinau_issuer_poc.validate_context_request(
    pg_catalog.text, pg_catalog.uuid, pg_catalog.uuid
) TO sinau_context_issuer_poc;

GRANT EXECUTE ON FUNCTION sinau_issuer_poc.has_feature_entitlement(
    pg_catalog.uuid, pg_catalog.text
) TO sinau_context_issuer_poc;

COMMIT;

-- Report metadata and effective privileges; never output session tokens or hashes.
\echo '===== ISSUER VALIDATOR METADATA ====='

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
    'sinau_issuer_poc.validate_context_request(text,uuid,uuid)'::pg_catalog.regprocedure;

\echo '===== ISSUER PRIVILEGES ====='

SELECT
    has_schema_privilege(
        'sinau_context_issuer_poc',
        'sinau_issuer_poc',
        'USAGE'
    ) AS issuer_schema_usage,
    has_function_privilege(
        'sinau_context_issuer_poc',
        'sinau_issuer_poc.validate_context_request(text,uuid,uuid)',
        'EXECUTE'
    ) AS issuer_can_validate_context,
    has_function_privilege(
        'sinau_rls_test',
        'sinau_issuer_poc.validate_context_request(text,uuid,uuid)',
        'EXECUTE'
    ) AS query_role_can_validate_context,
    has_table_privilege(
        'sinau_context_issuer_poc',
        'sinau_issuer_poc.poc_tenant_memberships',
        'SELECT'
    ) AS issuer_can_read_membership_tables,
    has_table_privilege(
        'sinau_rls_test',
        'sinau_issuer_poc.poc_tenant_memberships',
        'SELECT'
    ) AS query_role_can_read_membership_tables,
    has_table_privilege(
        'sinau_context_issuer_poc',
        'sinau_private.context_keys',
        'SELECT'
    ) AS issuer_can_read_signing_keys;

\echo '===== SYNTHETIC ISSUER FIXTURES INSTALLED ====='
