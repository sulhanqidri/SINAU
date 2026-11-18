# ERD Konseptual SINAU

Diagram ini menunjukkan hubungan domain utama, bukan seluruh kolom atau constraint final.

```mermaid
erDiagram
  TENANTS ||--o{ EDUCATION_UNITS : owns
  USERS ||--o{ TENANT_MEMBERSHIPS : joins
  TENANTS ||--o{ TENANT_MEMBERSHIPS : has
  USERS ||--o{ UNIT_MEMBERSHIPS : assigned
  EDUCATION_UNITS ||--o{ UNIT_MEMBERSHIPS : grants
  EDUCATION_UNITS ||--o{ ACADEMIC_YEARS : defines
  EDUCATION_UNITS ||--o{ STUDENTS : registers
  STUDENTS ||--o{ STUDENT_ENROLLMENTS : has
  EDUCATION_UNITS ||--o{ STUDENT_ENROLLMENTS : hosts
  ACADEMIC_YEARS ||--o{ STUDENT_ENROLLMENTS : period
  CLASS_GROUPS ||--o{ STUDENT_ENROLLMENTS : groups
  EDUCATION_UNITS ||--o{ CLASS_GROUPS : organizes
  USERS ||--o{ EMPLOYEE_PROFILES : account
  EMPLOYEE_PROFILES ||--o{ TEACHER_ASSIGNMENTS : assigned
  CLASS_GROUPS ||--o{ TEACHER_ASSIGNMENTS : taught
  STUDENT_ENROLLMENTS ||--o{ ATTENDANCE_RECORDS : attendance
  STUDENT_ENROLLMENTS ||--o{ STUDENT_SCORES : assessed
  USERS ||--o{ AUDIT_EVENTS : performs
```

## Catatan
- Diagram ini sengaja menyederhanakan beberapa tabel penghubung.
- Tenant/unit id harus hadir pada aggregate yang memerlukan scope dan constraint relasi harus mencegah referensi lintas tenant.
- Tabel operasional harus memiliki referensi periode yang eksplisit.
- Finalisasi ERD dilakukan setelah keputusan people/student/employee identity dan tenant ownership disepakati.
