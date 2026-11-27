\set ON_ERROR_STOP on
\pset pager off
\echo '===== SINAU POC — READ-ONLY AUTHORIZATION FRESHNESS AUDIT ====='
\echo 'Checks installed verifier/issuer definitions and RLS accessor wiring; no data or schema changes.'

BEGIN READ ONLY;

DO $audit$
DECLARE
    v_verify_oid pg_catalog.oid;
    v_accessor_oid pg_catalog.oid;
    v_issuer_oid pg_catalog.oid;
    v_verify_def pg_catalog.text;
    v_accessor_def pg_catalog.text;
    v_issuer_def pg_catalog.text;
    v_missing pg_catalog.text[] := ARRAY[]::pg_catalog.text[];
    v_name pg_catalog.text;
    v_verify_secdef boolean;
    v_verify_config pg_catalog.text[];
    v_issuer_secdef boolean;
BEGIN
    IF pg_catalog.current_database() <> 'sinau_design_poc'
       OR current_user <> 'postgres' THEN
        RAISE EXCEPTION
            'Safety stop: run only as postgres in sinau_design_poc';
    END IF;

    v_verify_oid :=
        pg_catalog.to_regprocedure('sinau_private.verify_context_token(pg_catalog.text)');
    v_accessor_oid :=
        pg_catalog.to_regprocedure('sinau_private.current_verified_context()');
    v_issuer_oid :=
        pg_catalog.to_regprocedure(
            'sinau_issuer_poc.validate_context_request(pg_catalog.text,pg_catalog.uuid,pg_catalog.uuid)'
        );

    IF v_verify_oid IS NULL OR v_accessor_oid IS NULL OR v_issuer_oid IS NULL THEN
        RAISE EXCEPTION
            'Audit incomplete: expected verifier, accessor, or issuer validator function is missing';
    END IF;

    SELECT p.prosecdef, p.proconfig
      INTO v_verify_secdef, v_verify_config
      FROM pg_catalog.pg_proc p
     WHERE p.oid = v_verify_oid;

    SELECT p.prosecdef
      INTO v_issuer_secdef
      FROM pg_catalog.pg_proc p
     WHERE p.oid = v_issuer_oid;

    v_verify_def := pg_catalog.lower(pg_catalog.pg_get_functiondef(v_verify_oid));
    v_accessor_def := pg_catalog.lower(pg_catalog.pg_get_functiondef(v_accessor_oid));
    v_issuer_def := pg_catalog.lower(pg_catalog.pg_get_functiondef(v_issuer_oid));

    IF NOT v_verify_secdef THEN
        RAISE EXCEPTION 'Unexpected verifier metadata: SECURITY DEFINER is not enabled';
    END IF;

    IF NOT coalesce(
        v_verify_config @> ARRAY['search_path=pg_catalog, pg_temp'],
        false
    ) THEN
        RAISE EXCEPTION 'Unexpected verifier metadata: fixed search_path is missing';
    END IF;

    IF pg_catalog.strpos(v_accessor_def, 'sinau_private.verify_context_token') = 0 THEN
        RAISE EXCEPTION 'Unexpected accessor definition: it does not call verify_context_token';
    END IF;

    IF NOT v_issuer_secdef THEN
        RAISE EXCEPTION 'Unexpected issuer metadata: SECURITY DEFINER is not enabled';
    END IF;

    FOREACH v_name IN ARRAY ARRAY[
        'sinau_issuer_poc.poc_identities',
        'sinau_issuer_poc.poc_auth_sessions',
        'sinau_issuer_poc.poc_tenant_memberships',
        'sinau_issuer_poc.poc_unit_memberships'
    ] LOOP
        IF pg_catalog.strpos(v_verify_def, v_name) = 0 THEN
            v_missing := pg_catalog.array_append(v_missing, v_name);
        END IF;
    END LOOP;

    RAISE NOTICE
        'AUDIT: verifier SECURITY DEFINER=true; search_path=%',
        v_verify_config;
    RAISE NOTICE
        'AUDIT: current_verified_context() calls verify_context_token()';
    RAISE NOTICE
        'AUDIT: issuer validator SECURITY DEFINER=true';

    IF pg_catalog.cardinality(v_missing) = 4 THEN
        RAISE NOTICE
            'FINDING CONFIRMED: verify_context_token() does not reference account, authentication-session, tenant-membership, or unit-membership state tables.';
        RAISE NOTICE
            'MISSING LIVE AUTHORIZATION REFERENCES: %',
            pg_catalog.array_to_string(v_missing, ', ');
    ELSIF pg_catalog.cardinality(v_missing) > 0 THEN
        RAISE NOTICE
            'PARTIAL GAP: verifier is missing references to: %',
            pg_catalog.array_to_string(v_missing, ', ');
    ELSE
        RAISE NOTICE
            'VERIFIER REFERENCES ALL FOUR AUTHORIZATION TABLES; inspect predicates and freshness semantics separately.';
    END IF;

    FOREACH v_name IN ARRAY ARRAY[
        'sinau_issuer_poc.poc_identities',
        'sinau_issuer_poc.poc_auth_sessions',
        'sinau_issuer_poc.poc_tenant_memberships',
        'sinau_issuer_poc.poc_unit_memberships'
    ] LOOP
        IF pg_catalog.strpos(v_issuer_def, v_name) = 0 THEN
            RAISE EXCEPTION
                'Audit incomplete: issuer validator definition does not reference expected source table %',
                v_name;
        END IF;
    END LOOP;

    RAISE NOTICE
        'PASS: issuer validator definition references all four account/session/membership source tables.';
END
$audit$;

\echo '===== RLS POLICIES USING THE VERIFIED CONTEXT ACCESSOR ====='
SELECT
    schemaname,
    tablename,
    policyname,
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

\echo '===== FUNCTION METADATA ====='
SELECT
    n.nspname AS schema_name,
    p.proname AS function_name,
    pg_catalog.pg_get_userbyid(p.proowner) AS function_owner,
    p.prosecdef AS security_definer,
    p.provolatile AS volatility,
    p.proconfig AS function_config
FROM pg_catalog.pg_proc p
JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE p.oid IN (
    pg_catalog.to_regprocedure('sinau_private.verify_context_token(pg_catalog.text)'),
    pg_catalog.to_regprocedure('sinau_private.current_verified_context()'),
    pg_catalog.to_regprocedure(
        'sinau_issuer_poc.validate_context_request(pg_catalog.text,pg_catalog.uuid,pg_catalog.uuid)'
    )
)
ORDER BY n.nspname, p.proname;

ROLLBACK;

\echo '===== READ-ONLY AUTHORIZATION FRESHNESS AUDIT COMPLETE — ROLLED BACK ====='
