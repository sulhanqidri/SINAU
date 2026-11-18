# Kamus Data — Baseline (Inventaris Ringkas)

> Dokumen ini dipertahankan sebagai inventaris ringkas historis. Kamus rinci MVP dengan kandidat atribut, tipe PostgreSQL, nullability, klasifikasi, validasi, dan historisasi berada di [DATA-DICTIONARY-MVP.md](DATA-DICTIONARY-MVP.md). Bila terdapat perbedaan, jangan menganggap salah satu sebagai schema final; lakukan reconciliation pada review logical design.

| Entitas | Scope | Fungsi | Catatan integritas |
|---|---|---|---|
| tenants | Platform | Pelanggan SaaS | tenant_type: foundation/independent_provider; status dan lifecycle |
| education_units | Tenant | Unit sekolah/madrasah | Wajib tenant_id; unique (tenant_id,id) untuk composite reference |
| users | Platform | Akun autentikasi global | Bukan sumber hak akses domain |
| tenant_memberships | Tenant | Keanggotaan user pada tenant | Unique user+tenant; status/periode berlaku |
| unit_memberships | Unit | Akses user ke unit | Tenant konsisten dengan pemilik unit; status/periode berlaku |
| permissions | Reference | Aksi yang dapat diberikan | Kode stabil dan scope jelas |
| roles | Platform/tenant/unit | Kumpulan permission | Scope dan pemilik role tervalidasi |
| platform_user_roles | Platform | Role operator platform | Hanya untuk akses platform |
| tenant_membership_roles | Tenant | Role pada membership tenant | FK ke membership tenant |
| unit_membership_roles | Unit | Role pada membership unit | FK ke membership unit |
| students | Tenant/unit | Profil siswa | Scope eksplisit; identitas tidak menyimpan kelas aktif sebagai histori |
| student_guardians | Unit/tenant | Hubungan wali-siswa | Verifikasi, status, periode berlaku |
| student_enrollments | Unit | Riwayat sekolah/kelas | Periode, status, rombel; scope konsisten |
| academic_years | Unit | Tahun ajaran | Tanggal dan status tervalidasi |
| academic_terms | Unit | Semester/periode | Terikat tahun ajaran |
| curriculum_versions | Unit/reference | Versi kurikulum | Effective dates |
| subject_catalog | Reference/tenant override | Mata pelajaran | Hindari hardcode mapel |
| class_groups | Unit | Rombel | Tahun ajaran dan tingkat |
| teacher_assignments | Unit | Penugasan guru | Guru, kelas/mapel, periode |
| attendance_records | Unit | Presensi | Unique key mencegah duplikasi sesuai sesi |
| student_scores | Unit | Nilai siswa | Asesmen dan enrollment |
| audit_events | Tenant/unit/platform | Audit | Minimalkan PII dan secret |
| stored_files | Tenant/unit | Metadata file privat | Authorization sebelum akses; object key opaque |

## Aturan tenant dan unit
- tenants.tenant_type dibatasi ke foundation atau independent_provider.
- education_units.tenant_id wajib dan menunjuk satu tenant aktif.
- Tenant mandiri tidak memerlukan record yayasan; unit pertamanya terhubung langsung ke tenant.
- Tenant yayasan dapat mempunyai banyak education unit.
- Jenis/jenjang pendidikan adalah atribut/reference education unit, bukan tenant.
- Membership tenant dan unit disimpan terpisah dan tidak saling menggantikan.
- Baseline MVP adalah shared database/shared schema; setiap tabel tenant/unit-scoped harus membawa scope key yang dibutuhkan.
- Tabel unit-scoped menyimpan tenant_id dan unit_id untuk composite FK, kecuali PoC membuktikan strategi setara yang aman.
- Relasi ke unit menggunakan pasangan (tenant_id, unit_id), bukan unit_id saja.
- Role assignment dipisahkan berdasarkan scope agar integritas FK dan otorisasi dapat diuji.

## Aturan kolom umum
- Gunakan primary key yang konsisten; strategi UUID/ULID/integer ditetapkan melalui ADR.
- Timestamp simpan dalam UTC; tampilan mengikuti zona waktu unit.
- Tanggal akademik disimpan sebagai date bila tidak memerlukan waktu.
- Status menggunakan referensi/enum terkontrol dan transisi tervalidasi.
- Hindari soft delete sebagai pengganti kebijakan retensi.
- Simpan created_by/updated_by untuk data yang memerlukan akuntabilitas; audit terpisah untuk perubahan penting.
- Jangan menyimpan file biner atau secret pada kolom umum.
