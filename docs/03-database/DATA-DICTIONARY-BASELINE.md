# Kamus Data — Baseline

| Entitas | Scope | Fungsi | Catatan integritas |
|---|---|---|---|
| tenants | Platform | Pelanggan SaaS | tenant_type: foundation/independent_provider; status dan lifecycle |
| education_units | Tenant | Unit sekolah/madrasah | Wajib tenant_id; tepat satu tenant aktif |
| users | Platform | Akun autentikasi | Bukan sumber hak akses unit |
| tenant_memberships | Tenant | Keanggotaan tenant | Unique user+tenant; status/periode berlaku |
| unit_memberships | Unit | Akses unit | Unique user+unit; status/periode berlaku |
| roles | Platform/tenant/unit | Kelompok permission | Role assignment wajib mencatat scope |
| permissions | Reference | Aksi yang dapat diberikan | Nama stabil dan scope jelas |
| students | Tenant/unit | Profil siswa | Tidak menyimpan riwayat kelas sebagai atribut tunggal |
| student_guardians | Unit/tenant | Hubungan wali-siswa | Verifikasi dan periode berlaku |
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
| stored_files | Tenant/unit | Metadata file privat | Otorisasi sebelum akses |

## Aturan tenant dan unit
- tenants.tenant_type dibatasi ke foundation atau independent_provider.
- education_units.tenant_id wajib dan menunjuk satu tenant aktif.
- Tenant mandiri tidak memerlukan record yayasan; unit pertamanya terhubung langsung ke tenant.
- Tenant yayasan dapat mempunyai banyak education unit.
- Jenis/jenjang pendidikan adalah atribut/reference education unit, bukan tenant.
- Membership tenant dan unit disimpan terpisah dan tidak saling menggantikan.
- Untuk tabel unit-scoped, gunakan unit_id dan strategi konsistensi tenant_id yang diputuskan melalui ADR database.

## Aturan kolom umum
- Gunakan primary key yang konsisten; strategi UUID/ULID/integer ditetapkan melalui ADR.
- Timestamp simpan dalam UTC; tampilan mengikuti zona waktu unit.
- Tanggal akademik disimpan sebagai date bila tidak memerlukan waktu.
- Status menggunakan referensi/enum terkontrol dan transisi tervalidasi.
- Hindari soft delete sebagai pengganti kebijakan retensi.
- Simpan created_by/updated_by untuk data yang memerlukan akuntabilitas; audit terpisah untuk perubahan penting.
- Jangan menyimpan file biner atau secret pada kolom umum.
