\set ON_ERROR_STOP on
\pset pager off
\echo '===== SINAU POC — TWO-CONNECTION AUTHORIZATION REVOCATION TEST (SESSION A) ====='
\echo 'Target: sinau_design_poc only. Synthetic actor 910...001. READ COMMITTED.'
\echo 'This test intentionally keeps one transaction/XID open while connection B commits a revocation.'

SET SESSION AUTHORIZATION sinau_poc;

BEGIN ISOLATION LEVEL READ COMMITTED;

CREATE TEMP TABLE poc_signed_context_input (
    token pg_catalog.text NOT NULL
) ON COMMIT DROP;

SELECT pg_catalog.pg_current_xact_id()::pg_catalog.text AS signer_xid \gset
\echo 'Connection A XID: ' :signer_xid
\prompt 'In terminal B, sign a token for this XID and install it at /run/authfreshness-context.token. Press ENTER when ready: ' ready

\copy pg_temp.poc_signed_context_input(token) FROM '/run/authfreshness-context.token' WITH (FORMAT text)

DO $install_context$
DECLARE
    v_count pg_catalog.int4;
    v_token pg_catalog.text;
BEGIN
    SELECT pg_catalog.count(*), pg_catalog.min(token)
      INTO v_count, v_token
      FROM pg_temp.poc_signed_context_input;

    IF v_count <> 1 OR v_token IS NULL OR v_token = '' THEN
        RAISE EXCEPTION 'Expected exactly one non-empty signed token; found %', v_count;
    END IF;

    PERFORM pg_catalog.set_config('app.context_token', v_token, true);
    RAISE NOTICE 'PASS: signed context installed transaction-locally without printing token';
END
$install_context$;

SET LOCAL ROLE sinau_rls_test;

DO $baseline$
DECLARE
    v_count pg_catalog.int8;
BEGIN
    IF current_user <> 'sinau_rls_test' THEN
        RAISE EXCEPTION 'Expected current_user sinau_rls_test, got %', current_user;
    END IF;

    v_count := (SELECT pg_catalog.count(*) FROM public.academic_years);

    IF v_count <> 1 THEN
        RAISE EXCEPTION 'Baseline failed: expected exactly one academic year before revoke, got %', v_count;
    END IF;

    RAISE NOTICE 'PASS: baseline context sees exactly one tenant-a/unit-a1 academic year';
END
$baseline$;

\echo '===== CONNECTION A IS WAITING FOR A COMMITTED REVOCATION IN CONNECTION B ====='
\prompt 'After connection B UPDATE + COMMIT succeeds, press ENTER to run the next protected statement: ' ready

DO $after_revoke$
DECLARE
    v_count pg_catalog.int8;
BEGIN
    v_count := (SELECT pg_catalog.count(*) FROM public.academic_years);

    IF v_count = 0 THEN
        RAISE NOTICE 'PASS: next protected statement denied the revoked authorization state';
    ELSIF v_count = 1 THEN
        RAISE NOTICE 'FINDING REPRODUCED: next protected statement STILL sees one row after revocation commit';
    ELSE
        RAISE EXCEPTION 'Unexpected post-revocation row count: %', v_count;
    END IF;
END
$after_revoke$;

ROLLBACK;
\echo '===== SESSION A ROLLED BACK; TRANSACTION-LOCAL CONTEXT CLEARED ====='
\echo 'Restore the synthetic fixture row in connection B before the next scenario.'
