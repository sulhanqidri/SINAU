-- SINAU PostgreSQL 18 Design PoC
-- Rollback-only RLS read/write matrix for three representative policy classes:
--   1) tenant-only:       public.education_units
--   2) tenant + unit:     public.academic_years
--   3) nullable scope:    public.audit_events
--
-- Uses only fixed synthetic tenant/unit/actor fixtures already created by 003
-- and 010. All INSERT/UPDATE/DELETE operations occur in one transaction that
-- is unconditionally rolled back. No persistent policy/DDL/role changes.
--
-- Run ONLY as PostgreSQL superuser postgres against sinau_design_poc.
-- Requires the v1 signer and exact transaction-XID binding.

\set ON_ERROR_STOP on
\pset pager off
\echo '===== SINAU POC — RLS POLICY CLASS READ/WRITE MATRIX ====='

DO $guard$
DECLARE
    v_count pg_catalog.int8;
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

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_roles
        WHERE rolname = 'sinau_rls_test'
          AND NOT rolcanlogin
          AND NOT rolsuper
          AND NOT rolbypassrls
    ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: sinau_rls_test must be NOLOGIN, non-superuser, without BYPASSRLS';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relname = 'education_units'
          AND c.relrowsecurity AND c.relforcerowsecurity
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relname = 'academic_years'
          AND c.relrowsecurity AND c.relforcerowsecurity
    ) OR NOT EXISTS (
        SELECT 1 FROM pg_catalog.pg_class c
        JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relname = 'audit_events'
          AND c.relrowsecurity AND c.relforcerowsecurity
    ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: one or more representative tables do not have ENABLE/FORCE RLS';
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
    FROM sinau_issuer_poc.poc_identities
    WHERE actor_id = '91000000-0000-0000-0000-000000000001'
      AND account_status = 'active';

    IF v_count <> 1 THEN
        RAISE EXCEPTION
            'SAFETY STOP: expected exactly one active synthetic actor, found %',
            v_count;
    END IF;

    IF EXISTS (
        SELECT 1 FROM public.education_units
        WHERE (tenant_id = '00000000-0000-0000-0000-000000000001'
               AND id = '10000000-0000-0000-0000-000000000090')
           OR (tenant_id = '00000000-0000-0000-0000-000000000002'
               AND id = '20000000-0000-0000-0000-000000000090')
    ) OR EXISTS (
        SELECT 1 FROM public.academic_years
        WHERE (tenant_id = '00000000-0000-0000-0000-000000000001'
               AND unit_id = '10000000-0000-0000-0000-000000000001'
               AND id IN (
                   '30000000-0000-0000-0000-000000000090',
                   '30000000-0000-0000-0000-000000000093'
               ))
           OR (tenant_id = '00000000-0000-0000-0000-000000000001'
               AND unit_id = '10000000-0000-0000-0000-000000000002'
               AND id = '30000000-0000-0000-0000-000000000091')
           OR (tenant_id = '00000000-0000-0000-0000-000000000002'
               AND unit_id = '20000000-0000-0000-0000-000000000001'
               AND id = '30000000-0000-0000-0000-000000000092')
    ) OR EXISTS (
        SELECT 1 FROM public.audit_events
        WHERE id IN (
            '40000000-0000-0000-0000-000000000090',
            '40000000-0000-0000-0000-000000000091',
            '40000000-0000-0000-0000-000000000092',
            '40000000-0000-0000-0000-000000000093',
            '40000000-0000-0000-0000-000000000094'
        )
    ) THEN
        RAISE EXCEPTION
            'SAFETY STOP: one or more fixed RLS-030 test IDs already exist';
    END IF;
END
$guard$;

BEGIN ISOLATION LEVEL READ COMMITTED;

CREATE TEMP TABLE poc_signed_context_input (
    token pg_catalog.text NOT NULL
) ON COMMIT DROP;

SELECT pg_catalog.pg_current_xact_id()::pg_catalog.text AS signer_xid \gset
\echo 'Connection XID: ' :signer_xid
\prompt 'In terminal B, sign a v1 token for this exact XID and install it at /run/authfreshness-context.token. Press ENTER when ready: ' ready

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
        RAISE EXCEPTION
            'Expected exactly one non-empty signed token; found %', v_count;
    END IF;

    PERFORM pg_catalog.set_config('app.context_token', v_token, true);
    RAISE NOTICE
        'PASS: transaction-bound token installed without printing token';
END
$install_context$;

SET LOCAL ROLE sinau_rls_test;

DO $role_check$
BEGIN
    IF current_user <> 'sinau_rls_test' THEN
        RAISE EXCEPTION
            'Expected current_user sinau_rls_test, got %', current_user;
    END IF;
END
$role_check$;

\echo '===== CLASS 1 — TENANT-ONLY: education_units ====='

DO $tenant_only$
DECLARE
    v_count pg_catalog.int8;
    v_rows pg_catalog.int4;
BEGIN
    -- Tenant A sees both units, even though the signed unit claim is A1:
    -- education_units is intentionally tenant-scoped, not unit-scoped.
    SELECT pg_catalog.count(*) INTO v_count
    FROM public.education_units;

    IF v_count <> 2 THEN
        RAISE EXCEPTION
            'FAIL tenant-only SELECT: expected 2 tenant-A units, got %',
            v_count;
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
    FROM public.education_units
    WHERE tenant_id = '00000000-0000-0000-0000-000000000002';

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'FAIL tenant-only SELECT: tenant-B rows visible: %',
            v_count;
    END IF;

    INSERT INTO public.education_units (tenant_id, id, code)
    VALUES (
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000090',
        'unit-a-rls-030'
    );

    UPDATE public.education_units
       SET code = 'unit-a-rls-030-updated'
     WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
       AND id = '10000000-0000-0000-0000-000000000090';

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN
        RAISE EXCEPTION
            'FAIL tenant-only UPDATE: expected one row, updated %',
            v_rows;
    END IF;

    BEGIN
        INSERT INTO public.education_units (tenant_id, id, code)
        VALUES (
            '00000000-0000-0000-0000-000000000002',
            '20000000-0000-0000-0000-000000000090',
            'unit-b-rls-030-denied'
        );

        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'FAIL tenant-only cross-tenant INSERT was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS tenant-only: cross-tenant INSERT rejected by WITH CHECK';
    END;

    BEGIN
        UPDATE public.education_units
           SET tenant_id = '00000000-0000-0000-0000-000000000002'
         WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
           AND id = '10000000-0000-0000-0000-000000000090';

        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'FAIL tenant-only cross-tenant UPDATE was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS tenant-only: changing tenant scope rejected by WITH CHECK';
    END;

    DELETE FROM public.education_units
     WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
       AND id = '10000000-0000-0000-0000-000000000090';

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN
        RAISE EXCEPTION
            'FAIL tenant-only DELETE: expected one own row, deleted %',
            v_rows;
    END IF;

    DELETE FROM public.education_units
     WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
       AND id = '20000000-0000-0000-0000-000000000001';

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 0 THEN
        RAISE EXCEPTION
            'FAIL tenant-only cross-tenant DELETE: expected zero rows, deleted %',
            v_rows;
    END IF;

    RAISE NOTICE
        'PASS tenant-only: SELECT/INSERT/UPDATE/DELETE and cross-tenant isolation';
END
$tenant_only$;

\echo '===== CLASS 2 — TENANT + UNIT: academic_years ====='

DO $tenant_unit$
DECLARE
    v_count pg_catalog.int8;
    v_rows pg_catalog.int4;
BEGIN
    SELECT pg_catalog.count(*) INTO v_count
    FROM public.academic_years;

    IF v_count <> 1 THEN
        RAISE EXCEPTION
            'FAIL tenant+unit SELECT: expected one A1 row, got %',
            v_count;
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
    FROM public.academic_years
    WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
      AND unit_id = '10000000-0000-0000-0000-000000000002';

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'FAIL tenant+unit SELECT: tenant A/unit A2 data visible';
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
    FROM public.academic_years
    WHERE tenant_id = '00000000-0000-0000-0000-000000000002';

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'FAIL tenant+unit SELECT: tenant B data visible';
    END IF;

    INSERT INTO public.academic_years
        (tenant_id, unit_id, id, starts_on, ends_on)
    VALUES (
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001',
        '30000000-0000-0000-0000-000000000090',
        '2027-07-01',
        '2028-06-30'
    );

    UPDATE public.academic_years
       SET ends_on = '2028-12-31'
     WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
       AND unit_id = '10000000-0000-0000-0000-000000000001'
       AND id = '30000000-0000-0000-0000-000000000090';

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN
        RAISE EXCEPTION
            'FAIL tenant+unit UPDATE: expected one same-scope row, updated %',
            v_rows;
    END IF;

    BEGIN
        INSERT INTO public.academic_years
            (tenant_id, unit_id, id, starts_on, ends_on)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000002',
            '30000000-0000-0000-0000-000000000091',
            '2027-07-01',
            '2028-06-30'
        );

        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'FAIL cross-unit INSERT was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS tenant+unit: cross-unit INSERT rejected by WITH CHECK';
    END;

    BEGIN
        INSERT INTO public.academic_years
            (tenant_id, unit_id, id, starts_on, ends_on)
        VALUES (
            '00000000-0000-0000-0000-000000000002',
            '20000000-0000-0000-0000-000000000001',
            '30000000-0000-0000-0000-000000000092',
            '2027-07-01',
            '2028-06-30'
        );

        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'FAIL cross-tenant INSERT was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS tenant+unit: cross-tenant INSERT rejected by WITH CHECK';
    END;

    BEGIN
        UPDATE public.academic_years
           SET unit_id = '10000000-0000-0000-0000-000000000002'
         WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
           AND unit_id = '10000000-0000-0000-0000-000000000001'
           AND id = '30000000-0000-0000-0000-000000000090';

        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'FAIL cross-unit UPDATE was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS tenant+unit: changing unit scope rejected by WITH CHECK';
    END;

    UPDATE public.academic_years
       SET ends_on = '2028-12-30'
     WHERE tenant_id = '00000000-0000-0000-0000-000000000002';

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 0 THEN
        RAISE EXCEPTION
            'FAIL cross-tenant UPDATE: expected zero rows, updated %',
            v_rows;
    END IF;

    DELETE FROM public.academic_years
     WHERE tenant_id = '00000000-0000-0000-0000-000000000002';

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 0 THEN
        RAISE EXCEPTION
            'FAIL cross-tenant DELETE: expected zero rows, deleted %',
            v_rows;
    END IF;

    DELETE FROM public.academic_years
     WHERE tenant_id = '00000000-0000-0000-0000-000000000001'
       AND unit_id = '10000000-0000-0000-0000-000000000001'
       AND id = '30000000-0000-0000-0000-000000000090';

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN
        RAISE EXCEPTION
            'FAIL same-scope DELETE: expected one row, deleted %',
            v_rows;
    END IF;

    RAISE NOTICE
        'PASS tenant+unit: SELECT/INSERT/UPDATE/DELETE and cross-scope isolation';
END
$tenant_unit$;

\echo '===== CLASS 3 — NULLABLE SCOPE: audit_events ====='

DO $audit_scope$
DECLARE
    v_count pg_catalog.int8;
    v_rows pg_catalog.int4;
BEGIN
    SELECT pg_catalog.count(*) INTO v_count
    FROM public.audit_events;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'FAIL audit_events baseline: expected empty table from script 029, got %',
            v_count;
    END IF;

    -- Unit-scoped event: same tenant and same unit.
    INSERT INTO public.audit_events
        (id, tenant_id, unit_id, actor_type, actor_user_id, actor_service_code, correlation_id)
    VALUES (
        '40000000-0000-0000-0000-000000000090',
        '00000000-0000-0000-0000-000000000001',
        '10000000-0000-0000-0000-000000000001',
        'user',
        '91000000-0000-0000-0000-000000000001',
        NULL,
        '50000000-0000-0000-0000-000000000090'
    );

    -- Tenant-level event: NULL unit remains visible in the tenant.
    INSERT INTO public.audit_events
        (id, tenant_id, unit_id, actor_type, actor_user_id, actor_service_code, correlation_id)
    VALUES (
        '40000000-0000-0000-0000-000000000091',
        '00000000-0000-0000-0000-000000000001',
        NULL,
        'user',
        '91000000-0000-0000-0000-000000000001',
        NULL,
        '50000000-0000-0000-0000-000000000091'
    );

    SELECT pg_catalog.count(*) INTO v_count
    FROM public.audit_events;

    IF v_count <> 2 THEN
        RAISE EXCEPTION
            'FAIL audit_events SELECT: expected two tenant-A events (one unit, one tenant-level), got %',
            v_count;
    END IF;

    UPDATE public.audit_events
       SET correlation_id = '50000000-0000-0000-0000-000000000094'
     WHERE id = '40000000-0000-0000-0000-000000000090';

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN
        RAISE EXCEPTION
            'FAIL audit_events same-scope UPDATE: expected one row, updated %',
            v_rows;
    END IF;

    BEGIN
        INSERT INTO public.audit_events
            (id, tenant_id, unit_id, actor_type, actor_user_id, actor_service_code, correlation_id)
        VALUES (
            '40000000-0000-0000-0000-000000000094',
            '00000000-0000-0000-0000-000000000002',
            '20000000-0000-0000-0000-000000000001',
            'user',
            '91000000-0000-0000-0000-000000000001',
            NULL,
            '50000000-0000-0000-0000-000000000095'
        );

        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'FAIL audit_events cross-tenant INSERT was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS audit_events: cross-tenant INSERT rejected';
    END;

    BEGIN
        INSERT INTO public.audit_events
            (id, tenant_id, unit_id, actor_type, actor_user_id, actor_service_code, correlation_id)
        VALUES (
            '40000000-0000-0000-0000-000000000092',
            '00000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000002',
            'user',
            '91000000-0000-0000-0000-000000000001',
            NULL,
            '50000000-0000-0000-0000-000000000092'
        );

        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'FAIL audit_events cross-unit INSERT was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS audit_events: cross-unit INSERT rejected';
    END;

    BEGIN
        INSERT INTO public.audit_events
            (id, tenant_id, unit_id, actor_type, actor_user_id, actor_service_code, correlation_id)
        VALUES (
            '40000000-0000-0000-0000-000000000093',
            NULL,
            NULL,
            'system',
            NULL,
            'rls-test',
            '50000000-0000-0000-0000-000000000093'
        );

        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'FAIL audit_events both-NULL scope INSERT was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE
                'PASS audit_events: both-NULL scope row denied by tenant-scoped WITH CHECK';
    END;

    BEGIN
        UPDATE public.audit_events
           SET unit_id = '10000000-0000-0000-0000-000000000002'
         WHERE id = '40000000-0000-0000-0000-000000000090';

        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'FAIL audit_events cross-unit UPDATE was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS audit_events: cross-unit UPDATE rejected by WITH CHECK';
    END;

    UPDATE public.audit_events
       SET actor_service_code = 'unexpected'
     WHERE tenant_id = '00000000-0000-0000-0000-000000000002';

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 0 THEN
        RAISE EXCEPTION
            'FAIL audit_events cross-tenant UPDATE: expected zero rows, updated %',
            v_rows;
    END IF;

    DELETE FROM public.audit_events
     WHERE tenant_id = '00000000-0000-0000-0000-000000000002';

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 0 THEN
        RAISE EXCEPTION
            'FAIL audit_events cross-tenant DELETE: expected zero rows, deleted %',
            v_rows;
    END IF;

    DELETE FROM public.audit_events
     WHERE id = '40000000-0000-0000-0000-000000000090';

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN
        RAISE EXCEPTION
            'FAIL audit_events unit-scoped DELETE: expected one row, deleted %',
            v_rows;
    END IF;

    DELETE FROM public.audit_events
     WHERE id = '40000000-0000-0000-0000-000000000091';

    GET DIAGNOSTICS v_rows = ROW_COUNT;
    IF v_rows <> 1 THEN
        RAISE EXCEPTION
            'FAIL audit_events tenant-level DELETE: expected one row, deleted %',
            v_rows;
    END IF;

    RAISE NOTICE
        'PASS audit_events: unit and tenant-level scope, denied cross-scope writes, UPDATE/DELETE';
END
$audit_scope$;

\echo '===== FAIL-CLOSED — EMPTY AND MALFORMED TOKEN ====='

DO $fail_closed$
DECLARE
    v_count pg_catalog.int8;
    v_token pg_catalog.text;
BEGIN
    PERFORM pg_catalog.set_config('app.context_token', '', true);

    SELECT pg_catalog.count(*) INTO v_count
    FROM public.academic_years;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'FAIL empty token: expected zero rows, got %',
            v_count;
    END IF;

    PERFORM pg_catalog.set_config('app.context_token', 'not-a-valid-token', true);

    SELECT pg_catalog.count(*) INTO v_count
    FROM public.academic_years;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'FAIL malformed token: expected zero rows, got %',
            v_count;
    END IF;

    BEGIN
        INSERT INTO public.academic_years
            (tenant_id, unit_id, id, starts_on, ends_on)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000001',
            '30000000-0000-0000-0000-000000000093',
            '2027-07-01',
            '2028-06-30'
        );

        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'FAIL malformed-token INSERT was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS malformed token: INSERT denied by WITH CHECK';
    END;

    SELECT token INTO STRICT v_token
    FROM pg_temp.poc_signed_context_input;

    PERFORM pg_catalog.set_config('app.context_token', v_token, true);

    RAISE NOTICE 'PASS fail-closed: empty/malformed SELECT hidden and INSERT denied';
END
$fail_closed$;

ROLLBACK;

\echo '===== RLS POLICY CLASS MATRIX COMPLETE — ALL TEST DML ROLLED BACK ====='
\echo 'Remove /run/authfreshness-context.token and /run/sinau-poc-token-signer/authfreshness-context.token.'
