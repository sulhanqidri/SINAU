# ERD Konseptual SINAU

Diagram ini menunjukkan hubungan domain utama, bukan seluruh kolom atau constraint final.

```mermaid
erDiagram
  TENANTS ||--|{ EDUCATION_UNITS : serves
  TENANTS ||--o{ TENANT_MEMBERSHIPS : has
  USERS ||--o{ TENANT_MEMBERSHIPS : joins
  EDUCATION_UNITS ||--o{ UNIT_MEMBERSHIPS : grants
  USERS ||--o{ UNIT_MEMBERSHIPS : assigned
  EDUCATION_UNITS ||--o{ ACADEMIC_YEARS : defines
  EDUCATION_UNITS ||--o{ STUDENTS : registers
  STUDENTS ||--o{ STUDENT_ENROLLMENTS : has
  EDUCATION_UNITS ||--o{ STUDENT_ENROLLMENTS : hosts
  ACADEMIC_YEARS ||--o{ STUDENT_ENROLLMENTS : period
  CLASS_GROUPS ||--o{ STUDENT_ENROLLMENTS : groups
  EDUCATION_UNITS ||--o{ CLASS_GROUPS : organizes
  USERS ||--o{ EMPLOYEES : account
  EMPLOYEES ||--o{ TEACHER_ASSIGNMENTS : assigned
  CLASS_GROUPS ||--o{ TEACHER_ASSIGNMENTS : taught
  STUDENT_ENROLLMENTS ||--o{ ATTENDANCE_RECORDS : attendance
  STUDENT_ENROLLMENTS ||--o{ STUDENT_SCORES : assessed
  USERS ||--o{ AUDIT_EVENTS : performs
```

## Interpretasi model pelanggan
- Tenant memiliki satu atau banyak education unit.
- tenant_type pada TENANTS membedakan foundation dan independent_provider.
- Tenant foundation dapat memiliki beberapa unit sekolah/madrasah.
- Tenant independent_provider mewakili sekolah/madrasah mandiri dan dibuat bersama unit pertama.
- Education unit tidak memerlukan relasi yayasan terpisah.
- Education type dan education level disimpan pada education unit; satu yayasan dapat menaungi sekolah umum dan madrasah dengan jenjang berbeda.

## Catatan integritas
- Setiap unit berada pada satu tenant aktif.
- Tenant membership tidak otomatis memberi akses semua unit; unit membership dan permission menentukan akses operasional.
- Tabel unit-scoped harus mempunyai scope terverifikasi dan constraint mencegah relasi lintas tenant.
- Tabel operasional memiliki referensi periode eksplisit.
- Transfer unit melalui workflow terotorisasi dan audit.
