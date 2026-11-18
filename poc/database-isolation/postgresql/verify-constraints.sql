-- Automated negative/positive checks for the PostgreSQL isolation PoC.
-- Run after schema-and-fixtures.sql in the disposable sinau_poc database.
SET search_path TO sinau_poc;

DO $$
BEGIN
    -- DB-02: a unit cannot reference a missing tenant.
    BEGIN
        INSERT INTO education_units (tenant_id, unit_code, name)
        VALUES (999999, 'BAD-TENANT', 'Must fail');
        RAISE EXCEPTION 'DB-02 FAILED: insert with missing tenant unexpectedly succeeded';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'DB-02 PASS: missing tenant rejected by FK';
    END;

    -- DB-04: a record cannot pair Tenant A with Tenant B's unit.
    BEGIN
        INSERT INTO unit_scoped_records (tenant_id, unit_id, record_key)
        VALUES (1, 201, 'invalid-cross-tenant');
        RAISE EXCEPTION 'DB-04 FAILED: cross-tenant record unexpectedly succeeded';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'DB-04 PASS: cross-tenant record rejected by composite FK';
    END;

    -- DB-05: changing only tenant_id must not detach the unit from its owner.
    BEGIN
        UPDATE unit_scoped_records SET tenant_id = 2 WHERE id = 10001;
        RAISE EXCEPTION 'DB-05 FAILED: mismatched scope update unexpectedly succeeded';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'DB-05 PASS: mismatched scope update rejected';
    END;

    -- DB-06: a unit code is unique within a tenant.
    BEGIN
        INSERT INTO education_units (tenant_id, unit_code, name)
        VALUES (1, 'A-SD', 'Duplicate code');
        RAISE EXCEPTION 'DB-06 FAILED: duplicate unit code unexpectedly succeeded';
    EXCEPTION WHEN unique_violation THEN
        RAISE NOTICE 'DB-06 PASS: duplicate unit code rejected';
    END;

    -- DB-07: the same code may be used by another tenant.
    INSERT INTO education_units (tenant_id, unit_code, name)
    VALUES (2, 'A-SD', 'Same code, different tenant');
    RAISE NOTICE 'DB-07 PASS: same unit code accepted in another tenant';

    -- Unit membership must refer to a user who belongs to that tenant.
    BEGIN
        INSERT INTO unit_memberships (tenant_id, unit_id, user_id, status)
        VALUES (1, 101, 2001, 'active');
        RAISE EXCEPTION 'DB-08 FAILED: foreign tenant membership unexpectedly succeeded';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'DB-08 PASS: unit membership without tenant membership rejected';
    END;

    -- Deleting a tenant with dependent units must be restricted.
    BEGIN
        DELETE FROM tenants WHERE id = 1;
        RAISE EXCEPTION 'DB-09 FAILED: referenced tenant unexpectedly deleted';
    EXCEPTION WHEN foreign_key_violation THEN
        RAISE NOTICE 'DB-09 PASS: tenant deletion restricted by FK';
    END;
END
$$;

-- DB-10: a failed multi-step operation must leave no partial tenant behind.
DO $$
DECLARE
    new_tenant_id BIGINT;
BEGIN
    BEGIN
        INSERT INTO tenants (tenant_type, status)
        VALUES ('independent_provider', 'active')
        RETURNING id INTO new_tenant_id;

        INSERT INTO education_units (tenant_id, unit_code, name)
        VALUES (new_tenant_id, 'ROLLBACK-UNIT', 'Must roll back');

        RAISE EXCEPTION 'force rollback' USING ERRCODE = 'P0001';
    EXCEPTION WHEN SQLSTATE 'P0001' THEN
        NULL;
    END;

    IF EXISTS (SELECT 1 FROM tenants WHERE id = new_tenant_id) THEN
        RAISE EXCEPTION 'DB-10 FAILED: transaction left a partial tenant behind';
    END IF;
    RAISE NOTICE 'DB-10 PASS: failed operation rolled back all writes';
END
$$;

-- Positive fixture assertions.
DO $$
BEGIN
    IF (SELECT COUNT(*) FROM tenants) <> 2 THEN
        RAISE EXCEPTION 'Fixture assertion failed: expected 2 tenants';
    END IF;
    IF (SELECT COUNT(*) FROM education_units) <> 5 THEN
        RAISE EXCEPTION 'Fixture assertion failed: expected 4 fixture units plus DB-07 test unit';
    END IF;
    IF (SELECT COUNT(*) FROM unit_scoped_records) <> 4 THEN
        RAISE EXCEPTION 'Fixture assertion failed: expected 4 unit-scoped records';
    END IF;
    RAISE NOTICE 'FIXTURES PASS: expected tenant, unit, and record counts verified';
END
$$;
