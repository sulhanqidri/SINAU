-- SINAU PostgreSQL 18 Design PoC
-- Run ONLY in a disposable database dedicated to this PoC.
-- This is not a production migration or approved physical schema.

BEGIN;
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE TABLE tenants (
  id uuid PRIMARY KEY,
  code text NOT NULL UNIQUE
);

CREATE TABLE education_units (
  tenant_id uuid NOT NULL REFERENCES tenants(id),
  id uuid NOT NULL,
  code text NOT NULL,
  PRIMARY KEY (tenant_id, id),
  UNIQUE (tenant_id, code)
);

CREATE TABLE academic_years (
  tenant_id uuid NOT NULL,
  unit_id uuid NOT NULL,
  id uuid NOT NULL,
  starts_on date NOT NULL,
  ends_on date NOT NULL,
  PRIMARY KEY (tenant_id, unit_id, id),
  CHECK (ends_on >= starts_on),
  FOREIGN KEY (tenant_id, unit_id)
    REFERENCES education_units(tenant_id, id)
);

CREATE TABLE class_groups (
  tenant_id uuid NOT NULL,
  unit_id uuid NOT NULL,
  id uuid NOT NULL,
  academic_year_id uuid NOT NULL,
  grade_code text NOT NULL,
  name text NOT NULL,
  PRIMARY KEY (tenant_id, unit_id, id),
  UNIQUE (tenant_id, unit_id, id, academic_year_id),
  FOREIGN KEY (tenant_id, unit_id, academic_year_id)
    REFERENCES academic_years(tenant_id, unit_id, id)
);

CREATE TABLE student_enrollments (
  tenant_id uuid NOT NULL,
  unit_id uuid NOT NULL,
  id uuid NOT NULL,
  academic_year_id uuid NOT NULL,
  student_code text NOT NULL,
  PRIMARY KEY (tenant_id, unit_id, id),
  UNIQUE (tenant_id, unit_id, id, academic_year_id),
  UNIQUE (tenant_id, unit_id, student_code),
  FOREIGN KEY (tenant_id, unit_id, academic_year_id)
    REFERENCES academic_years(tenant_id, unit_id, id)
);

CREATE TABLE student_class_placements (
  tenant_id uuid NOT NULL,
  unit_id uuid NOT NULL,
  id uuid NOT NULL,
  enrollment_id uuid NOT NULL,
  academic_year_id uuid NOT NULL,
  class_group_id uuid NOT NULL,
  starts_on date NOT NULL,
  ends_on date,
  PRIMARY KEY (tenant_id, unit_id, id),
  UNIQUE (tenant_id, unit_id, id, enrollment_id),
  CHECK (ends_on IS NULL OR ends_on >= starts_on),
  FOREIGN KEY (tenant_id, unit_id, enrollment_id, academic_year_id)
    REFERENCES student_enrollments(tenant_id, unit_id, id, academic_year_id),
  FOREIGN KEY (tenant_id, unit_id, class_group_id, academic_year_id)
    REFERENCES class_groups(tenant_id, unit_id, id, academic_year_id),
  CONSTRAINT student_placement_no_overlap
    EXCLUDE USING gist (
      tenant_id WITH =,
      unit_id WITH =,
      enrollment_id WITH =,
      daterange(starts_on, COALESCE(ends_on, 'infinity'::date), '[]') WITH &&
    )
);

CREATE TABLE attendance_sessions (
  tenant_id uuid NOT NULL,
  unit_id uuid NOT NULL,
  id uuid NOT NULL,
  class_group_id uuid NOT NULL,
  session_date date NOT NULL,
  status text NOT NULL CHECK (status IN ('draft','open','closed','cancelled')),
  PRIMARY KEY (tenant_id, unit_id, id),
  UNIQUE (tenant_id, unit_id, id, class_group_id, session_date),
  FOREIGN KEY (tenant_id, unit_id, class_group_id)
    REFERENCES class_groups(tenant_id, unit_id, id)
);

CREATE TABLE attendance_session_participants (
  tenant_id uuid NOT NULL,
  unit_id uuid NOT NULL,
  id uuid NOT NULL,
  session_id uuid NOT NULL,
  class_group_id uuid NOT NULL,
  session_date date NOT NULL,
  enrollment_id uuid NOT NULL,
  placement_id uuid NOT NULL,
  PRIMARY KEY (tenant_id, unit_id, id),
  UNIQUE (tenant_id, unit_id, session_id, enrollment_id),
  UNIQUE (tenant_id, unit_id, id, enrollment_id),
  FOREIGN KEY (tenant_id, unit_id, session_id, class_group_id, session_date)
    REFERENCES attendance_sessions(tenant_id, unit_id, id, class_group_id, session_date),
  FOREIGN KEY (tenant_id, unit_id, placement_id, enrollment_id)
    REFERENCES student_class_placements(tenant_id, unit_id, id, enrollment_id)
);

CREATE FUNCTION poc_check_attendance_participant() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE p student_class_placements%ROWTYPE;
BEGIN
  SELECT * INTO p
  FROM student_class_placements
  WHERE tenant_id = NEW.tenant_id AND unit_id = NEW.unit_id
    AND id = NEW.placement_id AND enrollment_id = NEW.enrollment_id;
  IF NOT FOUND OR p.class_group_id <> NEW.class_group_id
     OR p.starts_on > NEW.session_date
     OR (p.ends_on IS NOT NULL AND p.ends_on < NEW.session_date) THEN
    RAISE EXCEPTION 'participant placement is not valid for session date/class';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER attendance_participant_temporal_check
BEFORE INSERT OR UPDATE ON attendance_session_participants
FOR EACH ROW EXECUTE FUNCTION poc_check_attendance_participant();

CREATE TABLE attendance_records (
  tenant_id uuid NOT NULL,
  unit_id uuid NOT NULL,
  id uuid NOT NULL,
  participant_id uuid NOT NULL,
  enrollment_id uuid NOT NULL,
  attendance_status text NOT NULL CHECK (attendance_status IN ('present','late','sick','permission','absent')),
  recorded_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, unit_id, id),
  UNIQUE (tenant_id, unit_id, participant_id),
  FOREIGN KEY (tenant_id, unit_id, participant_id, enrollment_id)
    REFERENCES attendance_session_participants(tenant_id, unit_id, id, enrollment_id)
);

CREATE TABLE assessment_definitions (
  tenant_id uuid NOT NULL,
  unit_id uuid NOT NULL,
  id uuid NOT NULL,
  class_group_id uuid NOT NULL,
  assessment_date date NOT NULL,
  max_score numeric(8,2) NOT NULL CHECK (max_score > 0),
  scoring_rule_version integer NOT NULL DEFAULT 1 CHECK (scoring_rule_version > 0),
  PRIMARY KEY (tenant_id, unit_id, id),
  UNIQUE (tenant_id, unit_id, id, class_group_id, assessment_date),
  FOREIGN KEY (tenant_id, unit_id, class_group_id)
    REFERENCES class_groups(tenant_id, unit_id, id)
);

CREATE TABLE assessment_participants (
  tenant_id uuid NOT NULL,
  unit_id uuid NOT NULL,
  id uuid NOT NULL,
  assessment_id uuid NOT NULL,
  class_group_id uuid NOT NULL,
  assessment_date date NOT NULL,
  enrollment_id uuid NOT NULL,
  placement_id uuid NOT NULL,
  PRIMARY KEY (tenant_id, unit_id, id),
  UNIQUE (tenant_id, unit_id, assessment_id, enrollment_id),
  FOREIGN KEY (tenant_id, unit_id, assessment_id, class_group_id, assessment_date)
    REFERENCES assessment_definitions(tenant_id, unit_id, id, class_group_id, assessment_date),
  FOREIGN KEY (tenant_id, unit_id, placement_id, enrollment_id)
    REFERENCES student_class_placements(tenant_id, unit_id, id, enrollment_id)
);

CREATE FUNCTION poc_check_assessment_participant() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE p student_class_placements%ROWTYPE;
BEGIN
  SELECT * INTO p
  FROM student_class_placements
  WHERE tenant_id = NEW.tenant_id AND unit_id = NEW.unit_id
    AND id = NEW.placement_id AND enrollment_id = NEW.enrollment_id;
  IF NOT FOUND OR p.class_group_id <> NEW.class_group_id
     OR p.starts_on > NEW.assessment_date
     OR (p.ends_on IS NOT NULL AND p.ends_on < NEW.assessment_date) THEN
    RAISE EXCEPTION 'participant placement is not valid for assessment date/class';
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER assessment_participant_temporal_check
BEFORE INSERT OR UPDATE ON assessment_participants
FOR EACH ROW EXECUTE FUNCTION poc_check_assessment_participant();

CREATE TABLE student_scores (
  tenant_id uuid NOT NULL,
  unit_id uuid NOT NULL,
  id uuid NOT NULL,
  participant_id uuid NOT NULL,
  result_status text NOT NULL CHECK (result_status IN ('pending','scored','absent','exempt')),
  score_value numeric(8,2),
  workflow_status text NOT NULL DEFAULT 'draft' CHECK (workflow_status IN ('draft','finalized')),
  finalized_at timestamptz,
  PRIMARY KEY (tenant_id, unit_id, id),
  UNIQUE (tenant_id, unit_id, participant_id),
  FOREIGN KEY (tenant_id, unit_id, participant_id)
    REFERENCES assessment_participants(tenant_id, unit_id, id),
  CHECK (
    (result_status = 'scored' AND score_value IS NOT NULL AND score_value >= 0)
    OR
    (result_status IN ('pending','absent','exempt') AND score_value IS NULL)
  ),
  CHECK (
    (workflow_status = 'draft' AND finalized_at IS NULL)
    OR
    (workflow_status = 'finalized' AND finalized_at IS NOT NULL)
  )
);

CREATE TABLE attendance_corrections (
  tenant_id uuid NOT NULL,
  unit_id uuid NOT NULL,
  id uuid NOT NULL,
  attendance_record_id uuid NOT NULL,
  idempotency_key text NOT NULL,
  requested_status text NOT NULL CHECK (requested_status IN ('present','late','sick','permission','absent')),
  review_status text NOT NULL CHECK (review_status IN ('requested','approved','rejected','applied')),
  applied_revision_id uuid,
  PRIMARY KEY (tenant_id, unit_id, id),
  UNIQUE (tenant_id, unit_id, idempotency_key),
  UNIQUE (tenant_id, unit_id, id, attendance_record_id),
  FOREIGN KEY (tenant_id, unit_id, attendance_record_id)
    REFERENCES attendance_records(tenant_id, unit_id, id)
);

CREATE TABLE attendance_record_revisions (
  tenant_id uuid NOT NULL,
  unit_id uuid NOT NULL,
  id uuid NOT NULL,
  attendance_record_id uuid NOT NULL,
  revision_no integer NOT NULL CHECK (revision_no > 0),
  source_correction_id uuid,
  attendance_status text NOT NULL CHECK (attendance_status IN ('present','late','sick','permission','absent')),
  changed_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_id, unit_id, id),
  UNIQUE (tenant_id, unit_id, attendance_record_id, revision_no),
  UNIQUE (tenant_id, unit_id, source_correction_id),
  FOREIGN KEY (tenant_id, unit_id, attendance_record_id)
    REFERENCES attendance_records(tenant_id, unit_id, id),
  FOREIGN KEY (tenant_id, unit_id, source_correction_id, attendance_record_id)
    REFERENCES attendance_corrections(tenant_id, unit_id, id, attendance_record_id)
);

ALTER TABLE attendance_corrections
  ADD CONSTRAINT correction_applied_revision_fk
  FOREIGN KEY (tenant_id, unit_id, applied_revision_id)
  REFERENCES attendance_record_revisions(tenant_id, unit_id, id)
  DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE audit_events (
  id uuid PRIMARY KEY,
  tenant_id uuid,
  unit_id uuid,
  actor_type text NOT NULL CHECK (actor_type IN ('user','system','service','support')),
  actor_user_id uuid,
  actor_service_code text,
  correlation_id uuid NOT NULL,
  CHECK (
    (actor_type IN ('user','support') AND actor_user_id IS NOT NULL AND actor_service_code IS NULL)
    OR
    (actor_type IN ('system','service') AND actor_user_id IS NULL AND actor_service_code IS NOT NULL)
  ),
  CHECK (unit_id IS NULL OR tenant_id IS NOT NULL)
);

COMMIT;
