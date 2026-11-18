-- SINAU PostgreSQL 18 Design PoC — RLS setup
-- Run ONLY against sinau_design_poc as PostgreSQL administrator.
-- Creates a non-login test role; does not modify the application database.

\set ON_ERROR_STOP on

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sinau_rls_test') THEN
    CREATE ROLE sinau_rls_test NOLOGIN;
  END IF;
END $$;

GRANT sinau_rls_test TO sinau_poc;

-- Deterministic fixtures are inserted by the cluster administrator before
-- FORCE ROW LEVEL SECURITY is enabled. Re-running is safe for these IDs.
INSERT INTO tenants (id, code) VALUES
('00000000-0000-0000-0000-000000000001','tenant-a'),
('00000000-0000-0000-0000-000000000002','tenant-b')
ON CONFLICT (id) DO NOTHING;

INSERT INTO education_units (tenant_id, id, code) VALUES
('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','unit-a1'),
('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002','unit-a2'),
('00000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','unit-b1')
ON CONFLICT (tenant_id, id) DO NOTHING;

INSERT INTO academic_years (tenant_id, unit_id, id, starts_on, ends_on) VALUES
('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','2026-07-01','2027-06-30'),
('00000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000002','2026-07-01','2027-06-30'),
('00000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000003','2026-07-01','2027-06-30')
ON CONFLICT (tenant_id, unit_id, id) DO NOTHING;

GRANT USAGE ON SCHEMA public TO sinau_rls_test;

DO $$
DECLARE
  t record;
  predicate text;
BEGIN
  FOR t IN
    SELECT c.table_name,
           bool_or(c.column_name = 'unit_id') AS has_unit_id
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
      AND c.column_name IN ('tenant_id', 'unit_id')
    GROUP BY c.table_name
    HAVING bool_or(c.column_name = 'tenant_id')
  LOOP
    -- tenants is a global registry and is intentionally not granted to
    -- the test role. All tenant-scoped tables receive a policy.
    IF t.table_name = 'tenants' THEN
      CONTINUE;
    END IF;

    IF t.has_unit_id THEN
      IF t.table_name = 'audit_events' THEN
        predicate := $p$
          tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid
          AND (unit_id IS NULL OR unit_id = NULLIF(current_setting('app.unit_id', true), '')::uuid)
        $p$;
      ELSE
        predicate := $p$
          tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid
          AND unit_id = NULLIF(current_setting('app.unit_id', true), '')::uuid
        $p$;
      END IF;
    ELSE
      predicate := $p$
        tenant_id = NULLIF(current_setting('app.tenant_id', true), '')::uuid
      $p$;
    END IF;

    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t.table_name);
    EXECUTE format('ALTER TABLE public.%I FORCE ROW LEVEL SECURITY', t.table_name);
    EXECUTE format('DROP POLICY IF EXISTS sinau_rls_isolation ON public.%I', t.table_name);
    EXECUTE format(
      'CREATE POLICY sinau_rls_isolation ON public.%I FOR ALL TO sinau_rls_test USING (%s) WITH CHECK (%s)',
      t.table_name, predicate, predicate
    );
    EXECUTE format(
      'GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.%I TO sinau_rls_test',
      t.table_name
    );
  END LOOP;
END $$;

-- Report the tables covered by the test policy.
SELECT schemaname, tablename, rowsecurity, forcerowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
