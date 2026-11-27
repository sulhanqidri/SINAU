-- SINAU PostgreSQL 18 Design PoC
-- Create a SECURITY DEFINER verifier for signed, transaction-bound context tokens.
-- Run ONLY against sinau_design_poc as PostgreSQL administrator.
-- This does not modify existing RLS policies.
--
-- Token contract:
-- v1|sinau_design_poc|<kid>|<actor_uuid>|<tenant_uuid>|<unit_uuid-or->|<xid8>|<iat>|<exp>|<nonce_hex>|<mac_hex>
-- HMAC-SHA256 is calculated over the exact UTF-8 bytes of the first 10 fields.
-- This verifier checks authenticity, audience, time and transaction binding.
-- It does NOT establish actor membership; the backend must verify membership before signing.

\set ON_ERROR_STOP on

BEGIN;

SET LOCAL ROLE sinau_context_owner;

CREATE FUNCTION sinau_private.verify_context_token(p_token pg_catalog.text)
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
AS $verify$
DECLARE
    v_parts              pg_catalog.text[];
    v_payload            pg_catalog.text;
    v_actor              pg_catalog.uuid;
    v_tenant             pg_catalog.uuid;
    v_unit               pg_catalog.uuid;
    v_iat                pg_catalog.int8;
    v_exp                pg_catalog.int8;
    v_now                pg_catalog.timestamptz;
    v_now_epoch          pg_catalog.int8;
    v_current_xid        pg_catalog.xid8;
    v_secret             pg_catalog.bytea;
    v_expected_mac       pg_catalog.bytea;
    v_supplied_mac       pg_catalog.bytea;
    v_diff               pg_catalog.int4 := 0;
    v_i                  pg_catalog.int4;
BEGIN
    -- Bound input work and reject NULL/empty tokens.
    IF p_token IS NULL
       OR pg_catalog.octet_length(p_token) = 0
       OR pg_catalog.octet_length(p_token) > 512 THEN
        RETURN;
    END IF;

    v_parts := pg_catalog.string_to_array(p_token, '|');

    -- Exactly 10 payload fields plus one MAC field.
    IF pg_catalog.array_length(v_parts, 1) IS DISTINCT FROM 11 THEN
        RETURN;
    END IF;

    IF v_parts[1] <> 'v1'
       OR v_parts[2] <> 'sinau_design_poc'
       OR v_parts[2] <> pg_catalog.current_database()
       OR v_parts[3] !~ '^[a-z0-9][a-z0-9-]{0,31}$'
       OR v_parts[4] !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
       OR v_parts[5] !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
       OR (v_parts[6] <> '-' AND
           v_parts[6] !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
       OR v_parts[7] !~ '^(0|[1-9][0-9]{0,19})$'
       OR v_parts[8] !~ '^(0|[1-9][0-9]{0,11})$'
       OR v_parts[9] !~ '^(0|[1-9][0-9]{0,11})$'
       OR v_parts[10] !~ '^[0-9a-f]{32}$'
       OR v_parts[11] !~ '^[0-9a-f]{64}$' THEN
        RETURN;
    END IF;

    -- Rebuild to enforce exact canonical separators and field representation.
    v_payload := pg_catalog.array_to_string(v_parts[1:10], '|');
    IF (v_payload || '|' || v_parts[11]) <> p_token THEN
        RETURN;
    END IF;

    -- Cast only after strict canonical syntax validation.
    v_actor := v_parts[4]::pg_catalog.uuid;
    v_tenant := v_parts[5]::pg_catalog.uuid;
    IF v_parts[6] = '-' THEN
        v_unit := NULL;
    ELSE
        v_unit := v_parts[6]::pg_catalog.uuid;
    END IF;

    v_iat := v_parts[8]::pg_catalog.int8;
    v_exp := v_parts[9]::pg_catalog.int8;

    v_now := pg_catalog.clock_timestamp();
    v_now_epoch := pg_catalog.floor(EXTRACT(EPOCH FROM v_now))::pg_catalog.int8;

    -- Accept at most 5 seconds of signer clock skew and a maximum 300s lifetime.
    IF v_iat > v_now_epoch + 5
       OR v_exp <= v_now_epoch
       OR v_exp <= v_iat
       OR (v_exp - v_iat) > 300 THEN
        RETURN;
    END IF;

    -- Do not allocate an XID inside the verifier.
    v_current_xid := pg_catalog.pg_current_xact_id_if_assigned();
    IF v_current_xid IS NULL
       OR v_parts[7] <> v_current_xid::pg_catalog.text THEN
        RETURN;
    END IF;

    -- Only active keys can verify tokens.
    SELECT ck.secret_bytes
      INTO v_secret
      FROM sinau_private.context_keys AS ck
     WHERE ck.key_id = v_parts[3]
       AND ck.not_before <= v_now
       AND ck.revoked_at IS NULL;

    IF NOT FOUND OR v_secret IS NULL THEN
        RETURN;
    END IF;

    v_expected_mac := sinau_crypto.hmac(
        pg_catalog.convert_to(v_payload, 'UTF8'),
        v_secret,
        'sha256'
    );
    v_supplied_mac := pg_catalog.decode(v_parts[11], 'hex');

    IF pg_catalog.octet_length(v_expected_mac) <> 32
       OR pg_catalog.octet_length(v_supplied_mac) <> 32 THEN
        RETURN;
    END IF;

    -- Fixed 32-byte comparison loop; do not exit early on the first mismatch.
    FOR v_i IN 0..31 LOOP
        v_diff := v_diff |
            (pg_catalog.get_byte(v_expected_mac, v_i) #
             pg_catalog.get_byte(v_supplied_mac, v_i));
    END LOOP;

    IF v_diff <> 0 THEN
        RETURN;
    END IF;

    actor_id := v_actor;
    tenant_id := v_tenant;
    unit_id := v_unit;
    RETURN NEXT;
    RETURN;
END;
$verify$;

-- Newly created functions grant EXECUTE to PUBLIC by default.
-- Revoke it and grant only to the PoC RLS test role in this transaction.
REVOKE ALL ON FUNCTION sinau_private.verify_context_token(pg_catalog.text)
    FROM PUBLIC;

GRANT USAGE ON SCHEMA sinau_private TO sinau_rls_test;

GRANT EXECUTE ON FUNCTION sinau_private.verify_context_token(pg_catalog.text)
    TO sinau_rls_test;

-- Revoke the built-in global default EXECUTE grant for every future
-- function created by sinau_context_owner. A schema-scoped REVOKE cannot
-- remove PostgreSQL's global default PUBLIC EXECUTE privilege.
ALTER DEFAULT PRIVILEGES
    FOR ROLE sinau_context_owner
    REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

COMMIT;

\echo '===== VERIFIER METADATA ====='

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
    'sinau_private.verify_context_token(pg_catalog.text)'::pg_catalog.regprocedure;

\echo '===== EFFECTIVE PRIVILEGES ====='

SELECT
    has_schema_privilege('sinau_rls_test', 'sinau_private', 'USAGE')
        AS test_schema_usage,
    has_function_privilege(
        'sinau_rls_test',
        'sinau_private.verify_context_token(pg_catalog.text)',
        'EXECUTE'
    ) AS test_can_execute_verifier,
    has_table_privilege(
        'sinau_rls_test',
        'sinau_private.context_keys',
        'SELECT'
    ) AS test_can_read_key_store,
    has_function_privilege(
        'sinau_rls_test',
        'sinau_crypto.hmac(bytea,bytea,text)',
        'EXECUTE'
    ) AS test_can_execute_hmac;

\echo '===== MALFORMED TOKEN NEGATIVE TEST ====='

BEGIN;
SET LOCAL ROLE sinau_rls_test;

SELECT
    pg_catalog.count(*) = 0 AS malformed_token_rejected
FROM sinau_private.verify_context_token('not-a-token');

SELECT
    pg_catalog.count(*) = 0 AS empty_token_rejected
FROM sinau_private.verify_context_token('');

ROLLBACK;

\echo '===== VERIFIER INSTALLATION COMPLETE ====='
