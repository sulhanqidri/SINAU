-- SINAU database isolation PoC: MySQL 8.4 LTS / InnoDB
-- Destructive reset: run only in a disposable PoC server.
DROP DATABASE IF EXISTS sinau_poc;
CREATE DATABASE sinau_poc CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE sinau_poc;

CREATE TABLE tenants (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    tenant_type VARCHAR(32) NOT NULL,
    status VARCHAR(24) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT tenants_type_chk
        CHECK (tenant_type IN ('foundation', 'independent_provider'))
) ENGINE=InnoDB;

CREATE TABLE education_units (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    tenant_id BIGINT UNSIGNED NOT NULL,
    unit_code VARCHAR(64) NOT NULL,
    name VARCHAR(180) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT education_units_tenant_id_id_uq UNIQUE (tenant_id, id),
    CONSTRAINT education_units_tenant_code_uq UNIQUE (tenant_id, unit_code),
    CONSTRAINT education_units_tenant_fk
        FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE users (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    email VARCHAR(254) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT users_email_uq UNIQUE (email)
) ENGINE=InnoDB;

CREATE TABLE tenant_memberships (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    tenant_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    status VARCHAR(24) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT tenant_memberships_tenant_user_uq UNIQUE (tenant_id, user_id),
    CONSTRAINT tenant_memberships_tenant_fk
        FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE RESTRICT,
    CONSTRAINT tenant_memberships_user_fk
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE unit_memberships (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    tenant_id BIGINT UNSIGNED NOT NULL,
    unit_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    status VARCHAR(24) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT unit_memberships_tenant_unit_user_uq UNIQUE (tenant_id, unit_id, user_id),
    CONSTRAINT unit_memberships_unit_fk
        FOREIGN KEY (tenant_id, unit_id)
        REFERENCES education_units (tenant_id, id) ON DELETE RESTRICT,
    CONSTRAINT unit_memberships_tenant_user_fk
        FOREIGN KEY (tenant_id, user_id)
        REFERENCES tenant_memberships (tenant_id, user_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE INDEX unit_memberships_tenant_user_idx
    ON unit_memberships (tenant_id, user_id);

CREATE TABLE unit_scoped_records (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    tenant_id BIGINT UNSIGNED NOT NULL,
    unit_id BIGINT UNSIGNED NOT NULL,
    record_key VARCHAR(64) NOT NULL,
    payload TEXT,
    PRIMARY KEY (id),
    CONSTRAINT unit_records_tenant_unit_key_uq UNIQUE (tenant_id, unit_id, record_key),
    CONSTRAINT unit_records_unit_fk
        FOREIGN KEY (tenant_id, unit_id)
        REFERENCES education_units (tenant_id, id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- Synthetic fixture only; no real school or personal data.
INSERT INTO tenants (id, tenant_type, status) VALUES
    (1, 'foundation', 'active'),
    (2, 'independent_provider', 'active');

INSERT INTO education_units (id, tenant_id, unit_code, name) VALUES
    (101, 1, 'A-SD', 'Unit A1 - Sekolah Umum'),
    (102, 1, 'A-MI', 'Unit A2 - Madrasah'),
    (201, 2, 'B-SMP', 'Unit B1 - Mandiri');

INSERT INTO users (id, email) VALUES
    (1001, 'u1@example.invalid'),
    (1002, 'u2@example.invalid'),
    (2001, 'u3@example.invalid');

INSERT INTO tenant_memberships (id, tenant_id, user_id, status) VALUES
    (11, 1, 1001, 'active'),
    (12, 1, 1002, 'active'),
    (21, 2, 2001, 'active');

INSERT INTO unit_memberships (id, tenant_id, unit_id, user_id, status) VALUES
    (111, 1, 101, 1001, 'active'),
    (112, 1, 102, 1002, 'active'),
    (121, 2, 201, 2001, 'active');

INSERT INTO unit_scoped_records (id, tenant_id, unit_id, record_key, payload) VALUES
    (10001, 1, 101, 'fixture-1', 'synthetic record A1'),
    (10002, 1, 102, 'fixture-2', 'synthetic record A2'),
    (20001, 2, 201, 'fixture-3', 'synthetic record B1');

-- Sanity query: expected row counts are tenants=2, units=3, records=3.
SELECT 'tenants' AS table_name, COUNT(*) AS row_count FROM tenants
UNION ALL SELECT 'education_units', COUNT(*) FROM education_units
UNION ALL SELECT 'unit_scoped_records', COUNT(*) FROM unit_scoped_records;
