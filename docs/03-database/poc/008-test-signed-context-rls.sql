-- SINAU PostgreSQL 18 Design PoC — signed-context RLS functional tests
-- Run with \i ONLY inside the already-open psql transaction that:
--   1) uses session authorization sinau_poc,
--   2) has SET LOCAL ROLE sinau_rls_test,
--   3) has allocated a top-level XID,
--   4) imported exactly one token into pg_temp.poc_signed_context_input.
--
-- The token must be signed for that exact current XID and must still be valid.
-- This file never prints the token. All writes are inside the caller's
-- transaction; finish with ROLLBACK after these tests pass.
--
-- Target: sinau_design_poc only. Never run against sinau / sinau_app.

\set ON_ERROR_STOP on

\echo '===== SIGNED CONTEXT RLS FUNCTIONAL TESTS ====='

-- Set the bearer token transaction-locally without returning it to psql output.
DO $install_context$
DECLARE
    v_token pg_catalog.text;
    v_count pg_catalog.int4;
BEGIN
    SELECT pg_catalog.count(*), pg_catalog.min(token)
      INTO v_count, v_token
      FROM pg_temp.poc_signed_context_input;

    IF v_count <> 1 OR v_token IS NULL OR v_token = '' THEN
        RAISE EXCEPTION
            'Expected exactly one non-empty token in pg_temp.poc_signed_context_input; got %',
            v_count;
    END IF;

    PERFORM pg_catalog.set_config('app.context_token', v_token, true);
END
$install_context$;

-- Baseline and negative assertions. Fixtures from 003-rls-setup.sql:
-- tenant A / unit A1 has one academic year; A2 and tenant B / unit B1
-- each have their own rows. The signer fixture represents tenant A / unit A1.
DO $tests$
DECLARE
    v_count pg_catalog.int4;
    v_token pg_catalog.text;
BEGIN
    -- 1. Valid signed context: tenant A / unit A1 sees exactly one row.
    SELECT pg_catalog.count(*) INTO v_count
    FROM public.academic_years;

    IF v_count <> 1 THEN
        RAISE EXCEPTION
            'FAIL baseline: expected 1 academic year for signed tenant A/unit A1; got %',
            v_count;
    END IF;
    RAISE NOTICE 'PASS: valid token reveals only tenant A/unit A1';

    -- 2. Legacy unsigned GUC spoofing must not change the signed scope.
    PERFORM pg_catalog.set_config(
        'app.tenant_id',
        '00000000-0000-0000-0000-000000000002',
        true
    );
    PERFORM pg_catalog.set_config(
        'app.unit_id',
        '20000000-0000-0000-0000-000000000001',
        true
    );

    SELECT pg_catalog.count(*) INTO v_count
    FROM public.academic_years;

    IF v_count <> 1 THEN
        RAISE EXCEPTION
            'FAIL legacy GUC spoof: expected signed tenant A/unit A1 to remain visible; got % rows',
            v_count;
    END IF;

    SELECT pg_catalog.count(*) INTO v_count
    FROM public.academic_years
    WHERE tenant_id = '00000000-0000-0000-0000-000000000002'
      AND unit_id = '20000000-0000-0000-0000-000000000001';

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'FAIL legacy GUC spoof: tenant B/unit B1 data became visible';
    END IF;
    RAISE NOTICE 'PASS: spoofing legacy tenant/unit GUCs does not change signed scope';

    -- 3. Invalid/empty bearer context must fail closed.
    PERFORM pg_catalog.set_config('app.context_token', '', true);

    SELECT pg_catalog.count(*) INTO v_count
    FROM public.academic_years;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'FAIL empty context: expected zero visible rows; got %',
            v_count;
    END IF;

    PERFORM pg_catalog.set_config('app.context_token', 'not-a-valid-token', true);

    SELECT pg_catalog.count(*) INTO v_count
    FROM public.academic_years;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'FAIL malformed context: expected zero visible rows; got %',
            v_count;
    END IF;
    RAISE NOTICE 'PASS: empty and malformed context tokens fail closed';

    -- Restore the original valid token without printing it.
    SELECT token INTO STRICT v_token
    FROM pg_temp.poc_signed_context_input;

    PERFORM pg_catalog.set_config('app.context_token', v_token, true);

    -- 4. A write within the signed tenant/unit must succeed.
    INSERT INTO public.academic_years
        (tenant_id, unit_id, id, starts_on, ends_on)
    VALUES
        (
            '00000000-0000-0000-0000-000000000001',
            '10000000-0000-0000-0000-000000000001',
            '30000000-0000-0000-0000-000000000099',
            '2027-07-01',
            '2028-06-30'
        );

    SELECT pg_catalog.count(*) INTO v_count
    FROM public.academic_years
    WHERE id = '30000000-0000-0000-0000-000000000099';

    IF v_count <> 1 THEN
        RAISE EXCEPTION
            'FAIL same-scope INSERT: inserted row is not visible in signed scope';
    END IF;
    RAISE NOTICE 'PASS: same-tenant/same-unit INSERT accepted';

    -- 5. Cross-tenant INSERT must be rejected by RLS WITH CHECK.
    BEGIN
        INSERT INTO public.academic_years
            (tenant_id, unit_id, id, starts_on, ends_on)
        VALUES
            (
                '00000000-0000-0000-0000-000000000002',
                '20000000-0000-0000-0000-000000000001',
                '30000000-0000-0000-0000-000000000098',
                '2027-07-01',
                '2028-06-30'
            );

        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'FAIL cross-tenant INSERT was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS: cross-tenant INSERT rejected by RLS WITH CHECK';
    END;

    -- 6. Cross-unit INSERT inside tenant A must also be rejected.
    BEGIN
        INSERT INTO public.academic_years
            (tenant_id, unit_id, id, starts_on, ends_on)
        VALUES
            (
                '00000000-0000-0000-0000-000000000001',
                '10000000-0000-0000-0000-000000000002',
                '30000000-0000-0000-0000-000000000097',
                '2027-07-01',
                '2028-06-30'
            );

        RAISE EXCEPTION USING
            ERRCODE = 'P0001',
            MESSAGE = 'FAIL cross-unit INSERT was accepted';
    EXCEPTION
        WHEN insufficient_privilege THEN
            RAISE NOTICE 'PASS: cross-unit INSERT rejected by RLS WITH CHECK';
    END;
END
$tests$;

\echo 'SIGNED CONTEXT RLS FUNCTIONAL ASSERTIONS PASSED'
\echo 'IMPORTANT: caller must ROLLBACK the outer transaction; do not COMMIT.'
