# Kamus Data — Baseline

| Entitas | Scope | Fungsi | Catatan integritas |
|---|---|---|---|
| tenants | Platform | Pelanggan SaaS | ID stabil, status dan lifecycle |
| education_units | Tenant | Unit sekolah/madrasah | Relasi tenant wajib |
| users | Platform | Akun autentikasi | Bukan sumber hak akses unit |
| tenant_memberships | Tenant | Keanggotaan tenant | Unique user+tenant |
| unit_memberships | Unit | Akses unit | Unique user+unit |
| roles | Tenant/platform sesuai desain | Kelompok permission | Scope harus jelas |
| permissions | Reference | Aksi yang dapat diberikan | Nama stabil |
| students | Tenant/unit | Profil siswa | Tidak menyimpan riwayat kelas sebagai atribut tunggal |
| student_guardians | Unit/tenant | Hubungan wali-siswa | Verifikasi dan periode berlaku |
| student_enrollments | Unit | Riwayat sekolah/kelas | Periode, status, rombel |
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

## Aturan kolom umum
- Gunakan primary key yang konsisten; strategi UUID/ULID/integer ditetapkan melalui ADR.
- Timestamp simpan dalam UTC; tampilan mengikuti zona waktu unit.
- Tanggal akademik disimpan sebagai date bila tidak memerlukan waktu.
- Status menggunakan referensi/enum terkontrol dan transisi tervalidasi.
- Hindari soft delete sebagai pengganti kebijakan retensi.
- Simpan created_by/updated_by untuk data yang memerlukan akuntabilitas; audit terpisah untuk perubahan penting.
- Jangan menyimpan file biner atau secret pada kolom umum.
