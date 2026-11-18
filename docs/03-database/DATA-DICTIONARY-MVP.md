# Data Dictionary SINAU — MVP Baseline

**Status:** Draft v0.1.0 — kandidat tipe dan atribut; belum disetujui sebagai schema/migration  
**Tanggal:** 2026-11-18  
**Acuan:** `LOGICAL-ERD-MVP.md`, `DOMAIN-OWNERSHIP-MATRIX.md`, `MVP-SCOPE.md`, `DATA-INTEGRITY.md`  
**Database:** PostgreSQL 18; shared database/shared schema sebagai baseline.

> Kamus ini menjelaskan makna, scope, kandidat tipe PostgreSQL, nullability, klasifikasi, validasi, dan historisasi. Tipe adalah rekomendasi awal untuk dibahas, bukan keputusan final. Field yang menyentuh anak, wali, identitas resmi, kontak, atau dokumen harus melalui privacy/security review. Jangan membuat migration dari dokumen ini sebelum review dan approval.

## 1. Konvensi kamus data

### 1.1 Tipe dan format kandidat

| Notasi | Kandidat PostgreSQL | Penggunaan |
|---|---|---|
| ID | `uuid` | PK/FK; strategi UUID vs ULID vs identity masih perlu ADR |
| CODE | `varchar(50)` | Kode stabil/reference; case normalization ditentukan per domain |
| NAME | `varchar(160)` | Nama/label; batas panjang perlu UX validation |
| TEXT | `text` | Catatan atau alasan terbatas; bukan tempat menaruh payload bebas sensitif |
| BOOL | `boolean` | Flag true/false |
| DATE | `date` | Tanggal kalender/akademik lokal |
| TS | `timestamptz` | Timestamp absolut; simpan UTC |
| INT | `integer` | Counter/sequence/kapasitas |
| BIGINT | `bigint` | Ukuran byte/counter besar |
| NUMERIC | `numeric(p,s)` | Nilai/angka presisi; skala disesuaikan aturan domain |
| JSON | `jsonb` | Konfigurasi terstruktur terbatas dan tervalidasi; bukan pengganti kolom domain |
| EMAIL | `varchar(254)` | Email normalized; kebijakan verifikasi dan keunikan perlu disahkan |
| PHONE | `varchar(32)` | Nomor telepon E.164 bila memungkinkan; simpan normalized/display terpisah bila perlu |
| HASH | `text` | Password hash/credential hash; tidak pernah plaintext |
| URI/KEY | `text` / `varchar(512)` | Opaque storage key atau external reference; bukan URL publik yang dapat ditebak |

### 1.2 Klasifikasi informasi

| Kode | Makna | Aturan akses |
|---|---|---|
| PUB | Informasi publik atau katalog nonpersonal | Boleh dibaca sesuai kebutuhan produk |
| INT | Internal operasional | Pengguna terotorisasi pada scope terkait |
| CONF | Rahasia organisasi/operasional | Role dan purpose dibatasi; tidak tampil pada daftar umum |
| PII | Data pribadi | Minimization, purpose limitation, access log, retention |
| SENS | Data pribadi berisiko tinggi/anak/dokumen resmi/credential | Default-deny, akses sangat terbatas, enkripsi/secret controls, audit akses bila relevan |
| SYS | Metadata teknis sistem | Tidak mengandung secret/PII yang tidak diperlukan |

Klasifikasi per kolom pada tabel di bawah adalah kandidat minimum. Kombinasi data dapat menaikkan klasifikasi. PII anak dan dokumen wali harus diperlakukan sebagai SENS sampai privacy review menyatakan lain.

### 1.3 Aturan umum

- Semua tabel memiliki `id UUID PRIMARY KEY` sebagai kandidat, kecuali tabel junction/event yang dapat memakai composite PK bila dinilai tepat.
- `created_at timestamptz NOT NULL` dan `updated_at timestamptz NOT NULL` untuk entitas mutable; event/history append-only umumnya hanya `occurred_at/effective_at` dan `created_at`.
- Scope tenant/unit harus konsisten dengan Logical ERD: tabel unit-scoped membawa `tenant_id` dan `unit_id`; composite FK membuktikan scope.
- FK actor ke `users.id` boleh nullable untuk system actor atau data hasil migrasi, tetapi harus mencatat actor type bila nullable berisiko ambigu.
- Status adalah kode terkendali dengan state transition di domain service; bukan string bebas.
- Jangan gunakan cascade delete untuk histori, audit, file evidence, atau transaksi. Retention dan legal hold belum diputuskan.
- `jsonb` hanya untuk metadata/configuration yang memiliki schema dan batas ukuran; jangan menyimpan seluruh row, credential, atau dokumen sensitif sebagai JSON.
- Nilai tanggal efektif memakai DATE untuk kebijakan kalender; timestamp untuk kejadian aktual. Zona waktu tampilan mengikuti unit.
- `NULL` harus memiliki arti eksplisit (belum diketahui/tidak berlaku/belum diberikan), bukan nilai default untuk menyembunyikan data.

## 2. Platform, tenant, dan unit

### 2.1 `tenants`

**Owner:** SaaS Tenant & Organization · **Scope:** platform · **Lifecycle:** registrasi → aktif/pending/suspended/closed (state final perlu lifecycle spec).

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_type | CODE | Tidak | INT | `foundation` atau `independent_provider`; CHECK allowlist |
| legal_name | NAME | Tidak* | CONF | Nama legal organisasi; *wajib saat proses registrasi selesai, aturan draft-save perlu diputuskan |
| display_name | NAME | Tidak | INT | Nama tampilan tenant |
| status | CODE | Tidak | INT | Status lifecycle; transisi tervalidasi |
| timezone | CODE | Tidak | INT | IANA timezone; default saat onboarding |
| registration_completed_at | TS | Ya | SYS | Waktu registrasi lengkap; dasar deadline verifikasi |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

**Candidate constraint:** PK(id); CHECK tenant_type; timezone divalidasi terhadap katalog timezone. `legal_name` tidak unique global.

### 2.2 `foundation_profiles`

**Owner:** SaaS Tenant & Organization · **Scope:** tenant · **Lifecycle:** mengikuti tenant foundation.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id | ID | Tidak | INT | FK unik ke tenants; subtype foundation harus ditegakkan |
| legal_form | CODE | Ya | CONF | Bentuk badan hukum dari katalog |
| registration_number | varchar(100) | Ya | SENS | Nomor pengesahan; akses terbatas |
| office_address | TEXT | Ya | SENS | Alamat kantor; minimization |
| contact_name | NAME | Ya | PII | Kontak organisasi |
| contact_email | EMAIL | Ya | PII | Email kontak |
| contact_phone | PHONE | Ya | PII | Nomor kontak |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

**Constraint terbuka:** unique(tenant_id); hanya tenant_type foundation boleh memiliki profile. Pilih FK subtype/trigger/controlled write setelah PoC.

### 2.3 `education_units`

**Owner:** Institution Configuration · **Scope:** tenant · **Lifecycle:** draft/onboarding → active/suspended/closed (final state machine belum disahkan).

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id | ID | Tidak | INT | FK tenant; unique(tenant_id,id) |
| unit_code | CODE | Tidak | INT | Kode internal unik dalam tenant |
| official_name | NAME | Tidak | INT | Nama resmi lembaga |
| display_name | NAME | Ya | INT | Nama singkat/tampilan |
| education_type_code | CODE | Tidak | INT | Sekolah umum/madrasah/jenis yang disahkan |
| education_level_code | CODE | Tidak | INT | SD/SMP/SMA/SMK/MI/MTs/MA/MAK/dll |
| npsn | varchar(20) | Ya | CONF | Identifier resmi; format/namespace diverifikasi |
| nsm | varchar(20) | Ya | CONF | Identifier resmi madrasah; format/namespace diverifikasi |
| address_line | TEXT | Ya | PII | Alamat unit |
| province_code | CODE | Ya | INT | Referensi wilayah resmi |
| city_code | CODE | Ya | INT | Referensi wilayah resmi; konsisten dengan province |
| postal_code | varchar(10) | Ya | INT | Format sesuai wilayah |
| timezone | CODE | Tidak | INT | IANA timezone operasional |
| operational_status | CODE | Tidak | INT | Status operasional unit |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

**Candidate constraint:** unique(tenant_id,id), unique(tenant_id,unit_code). Partial unique NPSN dan NSM secara terpisah setelah sumber referensi dan aturan duplikasi diputuskan. Validasi education_type + level dilakukan server-side.

## 3. Identity & Access

### 3.1 `users`

**Owner:** Identity & Authentication · **Scope:** global/platform · **Lifecycle:** invited/pending/active/locked/disabled (final state machine TBD).

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| email_normalized | EMAIL | Tidak* | PII | Unique global setelah aturan verifikasi/normalisasi disahkan; *opsi login tanpa email belum diputuskan |
| email_verified_at | TS | Ya | SYS | Bukti verifikasi email |
| password_hash | HASH | Ya | SENS | Argon2id/bcrypt sesuai ADR; nullable bila external auth/passwordless |
| account_status | CODE | Tidak | INT | Status akun |
| last_authenticated_at | TS | Ya | SYS | Metadata keamanan; retensi dibatasi |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Jangan menyimpan nama siswa/pegawai, role, tenant, atau unit sebagai source of truth di tabel users.

### 3.2 `tenant_memberships`

**Owner:** Membership & Authorization · **Scope:** tenant.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id | ID | Tidak | INT | FK tenant; unique(tenant_id,id) |
| user_id | ID | Tidak | PII | FK global user |
| status | CODE | Tidak | INT | invited/active/suspended/revoked candidate |
| valid_from | TS | Ya | SYS | Awal grant; null berarti saat aktivasi bila didefinisikan |
| valid_until | TS | Ya | SYS | Batas grant; harus > valid_from |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Candidate unique(tenant_id,user_id) untuk satu membership kanonis per pasangan. Histori grant/revoke dicatat pada event/audit atau membership history yang ditetapkan pada authorization blueprint.

### 3.3 `unit_memberships`

**Owner:** Membership & Authorization · **Scope:** unit.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id | ID | Tidak | INT | Bagian composite FK |
| unit_id | ID | Tidak | INT | FK (tenant_id,unit_id) ke education_units |
| tenant_membership_id | ID | Tidak | INT | Composite FK ke membership tenant yang sama |
| status | CODE | Tidak | INT | invited/active/suspended/revoked candidate |
| valid_from / valid_until | TS | Ya | SYS | Rentang grant; validasi urutan |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Candidate unique(tenant_id,unit_id,id) dan unique(tenant_id,unit_id,tenant_membership_id). Tidak boleh membuat unit membership tanpa tenant membership aktif/valid.

### 3.4 `roles`

**Owner:** Membership & Authorization · **Scope:** platform/tenant/unit.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| owner_scope | CODE | Tidak | INT | platform/tenant/unit |
| tenant_id | ID | Ya | INT | Null untuk platform; wajib tenant/unit |
| unit_id | ID | Ya | INT | Wajib hanya untuk unit scope |
| code | CODE | Tidak | INT | Kode stabil dalam scope pemilik |
| name | NAME | Tidak | INT | Label role |
| is_system | BOOL | Tidak | SYS | Role bawaan tidak diedit bebas |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

CHECK scope: platform iff tenant_id/unit_id NULL; tenant iff tenant_id NOT NULL dan unit_id NULL; unit iff keduanya NOT NULL. Unique role code sesuai scope. Unit role harus composite FK ke education_units.

### 3.5 `permissions`

**Owner:** Membership & Authorization · **Scope:** platform reference.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| code | CODE | Tidak | INT | Unique global, stabil dan tidak berubah karena label |
| description | TEXT | Tidak | INT | Makna permission |
| resource | CODE | Tidak | INT | Domain/resource |
| action | CODE | Tidak | INT | read/create/update/delete/approve/export dll |
| allowed_scope | CODE | Tidak | INT | platform/tenant/unit atau kombinasi terdefinisi |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

### 3.6 Junction role

| Tabel | Kolom kandidat | PK/unique dan validasi |
|---|---|---|
| `role_permissions` | role_id ID, permission_id ID, created_at TS | PK(role_id,permission_id); FK kedua master; permission scope harus kompatibel dengan role scope |
| `platform_user_roles` | user_id ID, role_id ID, assigned_at TS, assigned_by_user_id ID nullable | PK(user_id,role_id); hanya role owner_scope=platform; perubahan wajib audit |
| `tenant_membership_roles` | tenant_id ID, tenant_membership_id ID, role_id ID, assigned_at TS, assigned_by_user_id ID nullable | Composite FK membership tenant; role harus tenant-scoped dengan tenant_id sama |
| `unit_membership_roles` | tenant_id ID, unit_id ID, unit_membership_id ID, role_id ID, assigned_at TS, assigned_by_user_id ID nullable | Composite FK unit membership; role harus unit-scoped dengan tenant/unit sama |

Klasifikasi seluruh assignment: INT; actor ID dan waktu assignment wajib tersedia atau tercatat pada audit event.

## 4. Subscription, entitlement, verification, lifecycle

### 4.1 `plans` dan `plan_entitlements`

**Owner:** SaaS Commercial · **Scope:** platform.

| Tabel/kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| plans.id | ID | Tidak | SYS | PK |
| plans.code | CODE | Tidak | INT | Unique plan code |
| plans.name | NAME | Tidak | INT | Nama paket |
| plans.version | INT | Tidak | INT | Versi definisi paket |
| plans.status | CODE | Tidak | INT | draft/active/retired candidate |
| plan_entitlements.plan_id | ID | Tidak | SYS | FK plan |
| plan_entitlements.feature_code | CODE | Tidak | INT | Kode fitur/kuota |
| plan_entitlements.limit_value | JSON | Ya | INT | Nilai konfigurasi terstruktur; schema per feature |
| plan_entitlements.created_at | TS | Tidak | SYS | Waktu perubahan |

Candidate PK plan_entitlements(plan_id,feature_code). Perubahan paket tidak boleh mengubah histori subscription lama tanpa versi/snapshot.

### 4.2 `tenant_subscriptions`

**Owner:** SaaS Commercial · **Scope:** tenant.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id | ID | Tidak | INT | FK tenant |
| plan_id | ID | Tidak | INT | FK plan version yang dipilih |
| status | CODE | Tidak | INT | trial/active/past_due/cancelled/expired candidate |
| starts_at / ends_at | TS | Ya | INT | Periode subscription; ends_at > starts_at bila ada |
| billing_reference | varchar(160) | Ya | CONF | Referensi provider; bukan credential |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Riwayat subscription dipertahankan. Unique active subscription per tenant adalah aturan domain/concurrency yang harus diuji, bukan diasumsikan oleh UI.

### 4.3 `tenant_entitlement_snapshots`

**Owner:** SaaS Commercial · **Scope:** tenant.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id | ID | Tidak | INT | FK tenant |
| subscription_id | ID | Tidak | INT | Composite FK subscription tenant yang sama |
| feature_code | CODE | Tidak | INT | Fitur/kuota |
| limit_value | JSON | Ya | INT | Snapshot konfigurasi efektif |
| effective_from | TS | Tidak | SYS | Mulai berlaku |
| effective_until | TS | Ya | SYS | Akhir berlaku; harus setelah start |

Unique kandidat(tenant_id,subscription_id,feature_code,effective_from). Penurunan kuota tidak menghapus data/unit; aturan grace dan akses melebihi kuota belum final.

### 4.4 `verification_cases`

**Owner:** Verification · **Scope:** tenant atau unit.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id | ID | Tidak | INT | Scope tenant |
| unit_id | ID | Ya | INT | Null untuk subject tenant; terisi untuk unit |
| subject_scope | CODE | Tidak | INT | tenant/unit; CHECK konsisten dengan unit_id |
| status | CODE | Tidak | CONF | draft/submitted/pending/approved/rejected/expired candidate |
| registration_completed_at | TS | Ya | SYS | Snapshot tanggal selesai registrasi |
| deadline_at | TS | Ya | SYS | Deadline verifikasi |
| submitted_at / decided_at | TS | Ya | SYS | Waktu submit/keputusan |
| decision_by_user_id | ID | Ya | PII | Reviewer; harus platform-authorized |
| decision_reason | TEXT | Ya | CONF | Alasan keputusan; tanpa data pribadi berlebihan |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Index kandidat(tenant_id,subject_scope,status,deadline_at). Verification bukan subscription atau lifecycle. Tenggat 7 hari yang telah dicatat pada domain model perlu ditautkan ke process acceptance dan zona waktu/batas akhir hari yang eksplisit.

### 4.5 `verification_evidence`

**Owner:** Verification (makna/status bukti), File Storage (objek) · **Scope:** tenant/unit.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id | ID | Tidak | INT | Scope |
| unit_id | ID | Ya | INT | Scope unit bila kasus unit |
| verification_case_id | ID | Tidak | SENS | Composite FK case pada scope sama |
| stored_file_id | ID | Tidak | SENS | FK file private |
| document_type | CODE | Tidak | SENS | Jenis dokumen allowlist |
| submitted_at | TS | Tidak | SYS | Waktu submit |
| review_status | CODE | Tidak | CONF | pending/accepted/rejected candidate |
| review_note | TEXT | Ya | SENS | Catatan reviewer, minimization |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Akses file harus memeriksa permission dan hubungan dengan case setiap kali diunduh. Jangan menyimpan file biner atau public URL.

### 4.6 `tenant_lifecycle_events` dan `unit_lifecycle_events`

**Owner:** Tenant Operations · **Scope:** tenant/unit · **Append-only**.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id | ID | Tidak | INT | Scope |
| unit_id (unit event) | ID | Tidak untuk unit event | INT | Composite FK unit |
| event_type | CODE | Tidak | CONF | suspended/closed/restore/transfer-requested candidate |
| reason_code | CODE | Tidak | CONF | Alasan terkendali |
| reason_detail | TEXT | Ya | CONF | Detail minimum |
| effective_at | TS | Tidak | SYS | Waktu efektif |
| actor_user_id | ID | Ya | PII | Nullable hanya untuk system actor |
| correlation_id | UUID | Ya | SYS | Korelasi workflow |
| created_at | TS | Tidak | SYS | Timestamp pencatatan |

Transfer lintas tenant tidak boleh dilakukan dengan update tenant_id langsung. Event saja tidak menyelesaikan workflow transfer; proses dan legal/privacy gate belum disahkan.

## 5. Kalender, kurikulum, dan organisasi akademik

### 5.1 `academic_years`

**Owner:** Academic Configuration · **Scope:** unit.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope + composite FK |
| code | CODE | Tidak | INT | Unik per unit |
| name | NAME | Tidak | INT | Contoh label tahun ajaran |
| starts_on / ends_on | DATE | Tidak | INT | ends_on >= starts_on |
| status | CODE | Tidak | INT | draft/active/closed candidate |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

### 5.2 `academic_terms`

**Owner:** Academic Configuration · **Scope:** unit.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| academic_year_id | ID | Tidak | INT | Composite FK tahun ajaran |
| code | CODE | Tidak | INT | Unik dalam tahun ajaran |
| name | NAME | Tidak | INT | Semester/periode |
| starts_on / ends_on | DATE | Tidak | INT | Harus berada dalam tahun ajaran |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

### 5.3 `curriculum_versions`

**Owner:** Curriculum · **Scope:** unit.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| code | CODE | Tidak | INT | Unik per unit |
| name | NAME | Tidak | INT | Nama versi kurikulum |
| effective_from | DATE | Tidak | INT | Awal berlaku |
| effective_until | DATE | Ya | INT | Akhir berlaku; tidak sebelum start |
| status | CODE | Tidak | INT | draft/active/retired candidate |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

### 5.4 `subject_catalog`

**Owner:** Curriculum Reference · **Scope:** platform reference (tenant override belum diputuskan).

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| code | CODE | Tidak | PUB | Kode katalog stabil |
| name | NAME | Tidak | PUB | Nama mata pelajaran |
| subject_category | CODE | Ya | PUB | Kelompok mapel |
| status | CODE | Tidak | PUB | active/retired candidate |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

### 5.5 `grade_levels`

**Owner:** Academic Configuration · **Scope:** unit.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| code | CODE | Tidak | INT | Unik per unit |
| name | NAME | Tidak | INT | Label tingkat/kelas |
| sequence_no | INT | Tidak | INT | Urutan positif |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

### 5.6 `curriculum_subjects`

**Owner:** Curriculum · **Scope:** unit.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| curriculum_version_id | ID | Tidak | INT | FK versi kurikulum unit |
| subject_catalog_id | ID | Tidak | INT | FK katalog referensi |
| grade_level_id | ID | Ya | INT | FK tingkat unit; nullable bila lintas tingkat |
| local_code | CODE | Ya | INT | Kode lokal unit |
| display_name_override | NAME | Ya | INT | Label lokal jika diperlukan |
| weekly_load | NUMERIC(4,1) | Ya | INT | Beban mingguan; unit pengukuran perlu disahkan |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Unique kandidat(tenant_id,unit_id,curriculum_version_id,grade_level_id,subject_catalog_id); NULL uniqueness harus dipertimbangkan (NULLS NOT DISTINCT atau index terpisah).

### 5.7 `student_profiles`

**Owner:** Student · **Scope:** unit · **Klasifikasi:** dominan SENS karena data anak.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| local_student_no | varchar(40) | Tidak | CONF | Nomor lokal unik per unit; normalisasi |
| full_name | NAME | Tidak | SENS | Nama siswa |
| birth_date | DATE | Ya | SENS | Hanya jika tujuan operasional sah |
| gender_code | CODE | Ya | SENS | Hanya bila dibutuhkan; katalog dan dasar pemrosesan ditinjau |
| profile_status | CODE | Tidak | INT | active/inactive/archived candidate |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Tidak mengasumsikan NIK/NISN sebagai wajib. Identifier nasional, foto, alamat rumah, agama, disabilitas, dan data kesehatan tidak dimasukkan tanpa requirement, legal basis, klasifikasi, akses, dan retensi yang disetujui.

### 5.8 `guardian_profiles`

**Owner:** Student · **Scope:** unit · **Klasifikasi:** PII/SENS.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| full_name | NAME | Tidak | PII | Nama wali |
| email | EMAIL | Ya | PII | Kontak; bukan akun login |
| phone | PHONE | Ya | PII | Kontak; minimal satu kanal hanya jika proses mensyaratkan |
| profile_status | CODE | Tidak | INT | active/inactive candidate |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Alamat, NIK, hubungan hukum, dan dokumen wali belum dimasukkan; perlu proses dan privacy review tersendiri.

### 5.9 `student_guardians`

**Owner:** Student · **Scope:** unit · **Lifecycle:** relasi efektif dan dapat diverifikasi.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| student_profile_id | ID | Tidak | SENS | Composite FK student pada unit sama |
| guardian_profile_id | ID | Tidak | PII | Composite FK guardian pada unit sama |
| relationship_code | CODE | Tidak | SENS | Orang tua/wali/relasi lain dari katalog |
| is_primary | BOOL | Tidak | SENS | Kandidat penanda utama; kebijakan multi-wali belum final |
| valid_from / valid_until | DATE | Ya | SENS | Rentang relasi; validasi urutan |
| verification_status | CODE | Tidak | SENS | unverified/pending/verified/rejected candidate |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Akses wali terhadap data siswa tidak muncul otomatis dari relasi ini; guardian login/consent/authority workflow belum disetujui.

### 5.10 `student_enrollments`

**Owner:** Student · **Scope:** unit · **Lifecycle:** admission/enrolled/leave/completed/withdrawn candidate.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| student_profile_id | ID | Tidak | SENS | Composite FK student |
| academic_year_id | ID | Tidak | INT | Composite FK tahun ajaran |
| academic_term_id | ID | Ya | INT | Composite FK term dalam tahun ajaran |
| grade_level_id | ID | Tidak | INT | Composite FK tingkat unit |
| class_group_id | ID | Ya | INT | Nullable selama belum ditempatkan ke rombel |
| enrollment_no | varchar(40) | Tidak | CONF | Nomor enrollment unik per unit sesuai policy |
| status | CODE | Tidak | INT | Status enrollment |
| effective_from / effective_until | DATE | Tidak / Ya | SENS | Rentang status; akhir tidak sebelum awal |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Tidak ada unique constraint satu enrollment aktif per siswa sebelum keputusan multi-enrollment. Validasi concurrency dan perpindahan kelas wajib menjaga histori.

### 5.11 `student_enrollment_status_history`

**Owner:** Student · **Scope:** unit · **Append-only**.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| student_enrollment_id | ID | Tidak | SENS | Composite FK enrollment |
| from_status | CODE | Ya | INT | Null hanya untuk status awal |
| to_status | CODE | Tidak | INT | Status baru |
| effective_at | TS | Tidak | SYS | Waktu efektif |
| reason | TEXT | Ya | CONF | Alasan minimal |
| changed_by_user_id | ID | Ya | PII | Actor; system actor harus dibedakan |
| created_at | TS | Tidak | SYS | Waktu pencatatan |

## 6. HR minimum dan academic organization

### 6.1 `employee_profiles`

**Owner:** HR · **Scope:** tenant · **Klasifikasi:** PII/CONF.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id | ID | Tidak | INT | Scope tenant |
| employee_no | varchar(40) | Tidak | CONF | Unik per tenant; identifier internal |
| full_name | NAME | Tidak | PII | Nama pegawai |
| employment_status | CODE | Tidak | CONF | active/on_leave/inactive/terminated candidate |
| email | EMAIL | Ya | PII | Kontak kerja; bukan credential |
| phone | PHONE | Ya | PII | Kontak kerja |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Tidak ada NIK, NPWP, rekening, gaji, kontrak, riwayat kesehatan, atau dokumen personal dalam HR minimum MVP tanpa persetujuan scope/privasi.

### 6.2 `employee_status_history`

**Owner:** HR · **Scope:** tenant · **Append-only**.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id | ID | Tidak | INT | Scope |
| employee_profile_id | ID | Tidak | CONF | Composite FK employee |
| from_status | CODE | Ya | CONF | Null untuk status pertama |
| to_status | CODE | Tidak | CONF | Status berikutnya |
| effective_at | TS | Tidak | CONF | Waktu efektif |
| reason | TEXT | Ya | CONF | Alasan terbatas |
| changed_by_user_id | ID | Ya | PII | Actor |
| created_at | TS | Tidak | SYS | Waktu pencatatan |

### 6.3 `employee_placements`

**Owner:** HR · **Scope:** unit dengan referensi employee tenant-scoped.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope unit |
| employee_profile_id | ID | Tidak | CONF | FK tenant employee pada tenant sama |
| placement_type | CODE | Tidak | CONF | permanent/temporary/contract/other candidate |
| starts_on | DATE | Tidak | CONF | Awal penempatan |
| ends_on | DATE | Ya | CONF | Akhir; >= start |
| status | CODE | Tidak | CONF | active/ended/cancelled candidate |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Penempatan bukan grant akses aplikasi. Seorang pegawai dapat memiliki beberapa placement dalam tenant; overlap dan visibility lintas unit perlu policy.

### 6.4 `class_groups`

**Owner:** Academic Organization · **Scope:** unit.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| academic_year_id | ID | Tidak | INT | FK tahun ajaran unit |
| grade_level_id | ID | Tidak | INT | FK tingkat unit |
| code | CODE | Tidak | INT | Unik per tahun ajaran/unit |
| name | NAME | Tidak | INT | Nama rombel |
| capacity | INT | Ya | INT | Kapasitas positif; bukan batas enrollment tanpa policy |
| status | CODE | Tidak | INT | draft/active/closed candidate |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

### 6.5 `homeroom_assignments`

**Owner:** Academic Organization · **Scope:** unit · **Lifecycle:** effective-dated.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| class_group_id | ID | Tidak | INT | FK rombel unit |
| employee_placement_id | ID | Tidak | CONF | FK placement unit sama |
| starts_on / ends_on | DATE | Tidak / Ya | CONF | Periode assignment |
| status | CODE | Tidak | INT | active/ended/cancelled candidate |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Aturan satu wali kelas aktif per rombel/periode dan overlap assignment harus ditentukan pada process spec.

### 6.6 `teaching_assignments`

**Owner:** Academic Organization · **Scope:** unit · **Lifecycle:** effective-dated.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| class_group_id | ID | Tidak | INT | FK rombel unit |
| employee_placement_id | ID | Tidak | CONF | FK placement unit sama |
| curriculum_subject_id | ID | Tidak | INT | FK subject kurikulum unit |
| starts_on / ends_on | DATE | Tidak / Ya | CONF | Periode assignment |
| status | CODE | Tidak | INT | active/ended/cancelled candidate |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Validasi bahwa employee placement aktif pada periode tersebut, subject termasuk kurikulum/tingkat kelas, dan tidak ada konflik assignment.

## 7. Attendance dan assessment dasar

### 7.1 `attendance_sessions`

**Owner:** Attendance · **Scope:** unit · **Lifecycle:** draft/open/closed/cancelled candidate.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| academic_year_id | ID | Tidak | INT | FK tahun ajaran |
| academic_term_id | ID | Ya | INT | FK term dalam tahun ajaran |
| class_group_id | ID | Tidak | INT | FK rombel unit |
| session_date | DATE | Tidak | INT | Tanggal sesi lokal unit |
| session_label | NAME | Tidak | INT | Label sesi; contoh kegiatan/pertemuan |
| starts_at / ends_at | TS | Ya | INT | Waktu aktual bila diperlukan; kedua nilai konsisten |
| created_by_user_id | ID | Tidak | PII | Actor pembuat sesi |
| status | CODE | Tidak | INT | Status sesi |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Sesi manual bukan timetable. Perlu diputuskan apakah assignment mengajar harus direferensikan dan apakah beberapa sesi per kelas/hari diperbolehkan.

### 7.2 `attendance_records`

**Owner:** Attendance · **Scope:** unit · **Klasifikasi:** SENS (data kehadiran anak).

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| attendance_session_id | ID | Tidak | SENS | FK sesi unit |
| student_enrollment_id | ID | Tidak | SENS | FK enrollment unit |
| attendance_status | CODE | Tidak | SENS | present/absent/sick/permission/late candidate |
| recorded_at | TS | Tidak | SYS | Waktu catat |
| recorded_by_user_id | ID | Tidak | PII | Actor pencatat |
| note | TEXT | Ya | SENS | Catatan minimal; jangan simpan diagnosis/health details |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Unique(session,enrollment) dalam scope; transaksi dan idempotency mencegah double submit. Validasi enrollment milik kelas/periode yang tepat.

### 7.3 `attendance_corrections`

**Owner:** Attendance · **Scope:** unit · **Append-only correction request**.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| attendance_record_id | ID | Tidak | SENS | FK record |
| previous_status / new_status | CODE | Tidak | SENS | Snapshot nilai sebelum/sesudah |
| reason | TEXT | Tidak | SENS | Alasan koreksi wajib |
| requested_by_user_id | ID | Tidak | PII | Actor pengaju |
| reviewed_by_user_id | ID | Ya | PII | Actor reviewer |
| review_status | CODE | Tidak | INT | pending/approved/rejected candidate |
| reviewed_at | TS | Ya | SYS | Waktu keputusan |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Jangan overwrite record tanpa audit. Apakah semua koreksi memerlukan approval masih harus dicocokkan dengan spesifikasi proses attendance.

### 7.4 `assessment_definitions`

**Owner:** Assessment · **Scope:** unit.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| academic_year_id | ID | Tidak | INT | FK tahun ajaran |
| academic_term_id | ID | Ya | INT | FK term |
| class_group_id | ID | Tidak | INT | FK rombel |
| curriculum_subject_id | ID | Tidak | INT | FK mapel kurikulum |
| code | CODE | Tidak | INT | Unik per kelas/periode sesuai policy |
| name | NAME | Tidak | INT | Nama asesmen |
| assessment_category | CODE | Tidak | INT | kategori terkelola |
| max_score | NUMERIC(8,2) | Tidak | INT | > 0 |
| weight | NUMERIC(8,4) | Ya | INT | >= 0; total weight policy belum ditetapkan |
| assessment_date | DATE | Ya | INT | Tanggal pelaksanaan |
| status | CODE | Tidak | INT | draft/open/closed candidate |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

### 7.5 `student_scores`

**Owner:** Assessment · **Scope:** unit · **Klasifikasi:** SENS (hasil belajar anak).

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| assessment_definition_id | ID | Tidak | SENS | FK asesmen unit |
| student_enrollment_id | ID | Tidak | SENS | FK enrollment unit |
| score_value | NUMERIC(8,2) | Tidak | SENS | 0 <= score <= max_score |
| feedback | TEXT | Ya | SENS | Umpan balik profesional; tidak memuat data sensitif tak relevan |
| entered_by_user_id | ID | Tidak | PII | Actor penginput |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Unique(assessment_definition_id,student_enrollment_id) dalam scope. Validasi enrollment pada kelas, tingkat, tahun, dan subject yang dinilai.

### 7.6 `student_score_change_history`

**Owner:** Assessment · **Scope:** unit · **Append-only**.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id / unit_id | ID | Tidak | INT | Scope |
| student_score_id | ID | Tidak | SENS | FK nilai |
| old_value / new_value | NUMERIC(8,2) | Ya / Tidak | SENS | Nilai lama nullable hanya untuk create event bila disepakati |
| reason | TEXT | Tidak | SENS | Alasan perubahan |
| changed_by_user_id | ID | Tidak | PII | Actor |
| changed_at | TS | Tidak | SYS | Waktu perubahan |

## 8. Import, export, audit, dan file

### 8.1 `import_batches`

**Owner:** Data Import (orchestration) · **Scope:** tenant; optional unit target.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id | ID | Tidak | INT | Scope |
| unit_id | ID | Ya | INT | Target unit bila import unit-scoped |
| target_domain | CODE | Tidak | INT | Allowlist domain target |
| source_file_id | ID | Tidak | CONF | FK stored_files private |
| status | CODE | Tidak | INT | queued/validating/ready/processing/completed/failed/cancelled |
| requested_by_user_id | ID | Tidak | PII | Actor peminta |
| started_at / completed_at | TS | Ya | SYS | Waktu proses |
| summary | JSON | Ya | INT | Ringkasan hitungan/error codes, tanpa PII mentah |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

### 8.2 `import_rows`

**Owner:** Data Import · **Scope:** inherit tenant/unit dari batch.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id | ID | Tidak | INT | Scope |
| unit_id | ID | Ya | INT | Harus sama dengan batch |
| import_batch_id | ID | Tidak | INT | Composite FK batch |
| row_number | INT | Tidak | INT | > 0; unique per batch |
| raw_payload_reference | KEY | Ya | SENS | Referensi staging terenkripsi/TTL; hindari raw PII di tabel |
| validation_status | CODE | Tidak | INT | pending/valid/invalid/imported/skipped |
| error_code | CODE | Ya | INT | Kode error, bukan pesan yang membocorkan data |
| result_entity_type | CODE | Ya | INT | Domain target |
| result_entity_id | ID | Ya | INT | Referensi hasil; polymorphic, wajib scope validation |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

### 8.3 `export_jobs`

**Owner:** Data Export · **Scope:** tenant; optional unit.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id | ID | Tidak | INT | Scope |
| unit_id | ID | Ya | INT | Unit target bila relevan |
| export_type | CODE | Tidak | CONF | Allowlist export |
| filters_reference | JSON | Ya | CONF | Filter tervalidasi; hindari menyimpan PII berlebihan |
| status | CODE | Tidak | INT | queued/processing/completed/failed/expired |
| requested_by_user_id | ID | Tidak | PII | Actor peminta |
| stored_file_id | ID | Ya | SENS | File private hasil export |
| expires_at | TS | Tidak | SYS | Kedaluwarsa artefak |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Authorization wajib diperiksa ketika job dibuat, saat proses membaca data, dan setiap kali file diunduh.

### 8.4 `audit_events`

**Owner:** Audit/Platform Security · **Scope:** platform/tenant/unit · **Append-only**.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id | ID | Ya | INT | Null hanya untuk platform event |
| unit_id | ID | Ya | INT | Null kecuali unit event; CHECK scope |
| actor_user_id | ID | Ya | PII | Null untuk system actor; actor_type diperlukan bila tidak ada user |
| actor_type | CODE | Tidak | SYS | user/system/service/support candidate |
| action_code | CODE | Tidak | INT | Aksi stabil |
| target_type | CODE | Tidak | INT | Allowlist entity/domain |
| target_id | ID | Ya | INT | Null untuk aksi tanpa target tunggal |
| occurred_at | TS | Tidak | SYS | Waktu kejadian |
| correlation_id | UUID | Ya | SYS | Trace lintas request/job |
| metadata_minimal | JSON | Ya | INT | Allowlist metadata; redaksi secret/PII |
| created_at | TS | Tidak | SYS | Waktu ingest |

Audit event tidak boleh menjadi tempat menyimpan request/response body utuh, password, token, dokumen, atau data anak berlebihan. Perlindungan tamper-evident/retensi masih perlu desain.

### 8.5 `stored_files`

**Owner:** File Storage (metadata/object reference) · **Scope:** platform/tenant/unit.

| Kolom | Tipe kandidat | Null | Klasifikasi | Definisi/validasi |
|---|---|---:|---|---|
| id | ID | Tidak | SYS | PK |
| tenant_id | ID | Ya | INT | Null untuk file platform; bukan berarti publik |
| unit_id | ID | Ya | INT | Null kecuali unit-scoped; scope CHECK |
| owner_domain | CODE | Tidak | INT | Domain pemilik makna file |
| owner_entity_type | CODE | Tidak | INT | Allowlist entity |
| owner_entity_id | ID | Tidak | INT | Polymorphic ref; authorize via owner domain |
| storage_key | KEY | Tidak | SENS | Opaque unique key; jangan expose ke user |
| original_filename | varchar(255) | Tidak | PII | Sanitized display name |
| mime_type | varchar(127) | Tidak | INT | Server-detected MIME; jangan percaya client |
| size_bytes | BIGINT | Tidak | SYS | >= 0 dan batas ukuran |
| classification | CODE | Tidak | SENS | PUB/INT/CONF/PII/SENS |
| scan_status | CODE | Tidak | INT | pending/clean/quarantined/failed |
| retention_until | TS | Ya | SYS | Retention belum final |
| created_at / updated_at | TS | Tidak | SYS | Timestamp UTC |

Object storage harus private. Download melalui authorization, malware scan, content disposition aman, signed URL berumur pendek bila dipakai, dan audit sesuai klasifikasi.

## 9. Ringkasan relasi, key, dan index kandidat

| Area | Kandidat | Catatan |
|---|---|---|
| Tenant | PK tenants.id; unique education_units(tenant_id,id) | Foundation subtype dan minimal satu unit perlu workflow enforcement |
| Tenant membership | unique(tenant_id,user_id) | Satu membership kanonis; histori perubahan terpisah |
| Unit membership | composite FK (tenant_id,tenant_membership_id) dan (tenant_id,unit_id) | Mencegah akses lintas tenant/unit |
| Role | CHECK scope + composite FK role scope | Hindari nullable scope tanpa CHECK |
| Student | unique(tenant_id,unit_id,local_student_no) | Jangan menganggap identifier nasional wajib |
| Guardian relation | FK student + guardian dengan scope sama | Akses portal wali tidak otomatis |
| Enrollment | index(student_profile_id, academic_year_id, status) | Tidak unique satu aktif sebelum OWN-02 diputuskan |
| Employee placement | FK employee tenant + unit tenant sama | Bukan grant login |
| Academic assignments | index(unit, class, effective dates) | Exclusion/overlap constraint dipertimbangkan setelah aturan disepakati |
| Attendance | unique(session,enrollment); index(unit,session_date) | Idempotensi pencatatan |
| Assessment | unique(assessment,enrollment); score range check | Validasi hubungan enrollment/kelas/subject |
| Verification | index(tenant,scope,status,deadline) | Tidak campur subscription |
| Import/export | index(scope,status,created_at/expiry) | Authorization saat proses dan download |
| Audit | index(scope,occurred_at), correlation_id | Append-only dan minimisasi |
| File | unique(storage_key), index(scope,classification,scan_status) | Private object + authorization |

Index final ditetapkan dari query workload, EXPLAIN ANALYZE, dan benchmark. Jangan menambahkan index pada semua kolom tanpa bukti.

## 10. Pertanyaan terbuka dan gerbang finalisasi

| ID | Pertanyaan | Dampak kamus/schema | Pemilik review |
|---|---|---|---|
| DD-01 | Email wajib untuk semua akun? | Nullability dan unique users.email_normalized | Identity/Product |
| DD-02 | Apakah NPSN/NSM perlu disimpan/unik secara global? | Identifier tables/index dan privacy | Institution/Verification |
| DD-03 | Data siswa minimum apa yang benar-benar diperlukan? | PII fields, consent/legal basis, retention | Student/Product/Privacy |
| DD-04 | Apakah kontak wali wajib dan satu atau lebih? | Nullable email/phone, validation | Student/Product |
| DD-05 | Bagaimana enrollment paralel, mutasi kelas, dan transfer? | Unique/exclusion constraints dan status history | Student/Academic |
| DD-06 | Pegawai dapat ditempatkan lintas unit dan siapa dapat melihat? | HR scope, assignment, authorization | HR/Identity |
| DD-07 | Apakah sesi presensi harian, per pelajaran, atau keduanya? | Session fields/uniqueness | Attendance/Teacher |
| DD-08 | Apakah semua koreksi presensi harus approval? | Correction workflow and fields | Attendance/Product |
| DD-09 | Skala nilai, bobot, kategori, dan presisi? | NUMERIC precision/constraints | Assessment/Teacher |
| DD-10 | Retensi, archive, deletion, legal hold? | Retention fields, partition, deletion policy | Privacy/Operations |
| DD-11 | Subject/grade reference global atau dapat di-override? | Catalog ownership and uniqueness | Curriculum |
| DD-12 | Strategi ID dan subtype tenant? | PK/FK and conditional constraint | Architecture/DB |
| DD-13 | Audit event tamper-evidence dan support access? | Actor schema, retention, security controls | Security |
| DD-14 | File storage provider, encryption, malware scan? | Storage metadata, lifecycle, access | Security/Operations |
| DD-15 | Import staging perlu menyimpan raw rows berapa lama? | TTL, encrypted staging, privacy | Import/Privacy |

Tidak ada jawaban pada tabel ini yang boleh diasumsikan telah disetujui.

## 11. Acceptance checklist kamus data

- [ ] Setiap entitas logical ERD memiliki owner dan scope yang eksplisit.
- [ ] Semua field mempunyai definisi, tipe kandidat, nullability, dan klasifikasi.
- [ ] Field sensitif mempunyai purpose, minimum necessity, access policy, dan retention owner.
- [ ] Semua composite FK membuktikan tenant/unit scope.
- [ ] Unique/check constraints memiliki skenario positif, negatif, dan concurrency.
- [ ] Status/lifecycle memiliki state transition dan histori.
- [ ] Field yang tidak diperlukan (misalnya data kesehatan, NIK siswa, rekening/gaji) tidak ditambahkan tanpa change approval.
- [ ] Data dictionary ditinjau pemilik domain, security/privacy, DBA/architect, dan product owner.
- [ ] Logical ERD dan process specifications konsisten sebelum physical schema/migration.

## 12. Riwayat perubahan

| Tanggal | Versi | Perubahan |
|---|---|---|
| 2026-11-18 | 0.1.0 | Draft dictionary MVP: kandidat atribut/tipenya, nullability, klasifikasi, validasi, histori, constraint, dan pertanyaan terbuka. |
