# Model Domain Data SINAU

**Status:** Conceptual model 0.2 — keputusan model pelanggan dikonfirmasi; bukan skema migration final.

## Prinsip
- Pisahkan identitas orang dari peran orang pada lembaga.
- Pisahkan identitas siswa dari enrollment per unit/tahun ajaran.
- Data historis tidak ditimpa konfigurasi periode baru.
- Tenant adalah pelanggan SaaS; education unit adalah sekolah/madrasah operasional.
- Semua tabel diklasifikasikan platform, tenant, unit, user, atau reference.
- Tenant/unit scope ditegakkan di query, constraint, policy, job, file, cache, dan export.

## Platform dan organisasi

### tenants
Pelanggan SaaS dan batas billing, kontrak, konfigurasi pelanggan, serta isolasi data.
- tenant_type: foundation atau independent_provider.
- Menyimpan identitas legal/organisasi, status lifecycle, zona waktu default, dan metadata kontrak.
- Tenant yayasan dapat memiliki banyak unit.
- Tenant mandiri mewakili sekolah/madrasah secara langsung dan dibuat bersama unit pertamanya.
- Kedua tipe memakai model dan modul pendidikan yang sama.

### education_units
Unit sekolah/madrasah di bawah tepat satu tenant aktif.
- Menyimpan identitas unit, nama resmi, identitas resmi relevan (misalnya NPSN/NSM), education type, education level, alamat, status, dan konfigurasi.
- Satu tenant dapat memiliki satu atau banyak unit.
- Unit yayasan dan unit mandiri memakai struktur data yang sama.
- Tenant mandiri lazimnya dimulai dengan satu unit; tidak ada parent foundation wajib.
- Transfer antar tenant melalui workflow khusus dan audit.

### Membership dan akses
- users: akun autentikasi global.
- tenant_memberships: keanggotaan user pada tenant; unique user+tenant, status dan periode berlaku.
- unit_memberships: akses user ke unit; unique user+unit, status dan periode berlaku.
- roles, permissions, role_permissions, user_role_assignments: role assignment mencatat scope platform/tenant/unit.
- tenant_subscriptions, tenant_module_entitlements: langganan dan fitur SaaS.
- Tenant membership tidak otomatis memberi akses semua unit; akses unit mengikuti permission/grant eksplisit.

## Referensi pendidikan
- education_types: sekolah umum, madrasah, dan jenis lain yang disahkan.
- education_levels: SD, SMP, SMA, SMK, MI, MTs, MA, MAK, dan perluasan yang disetujui.
- academic_years, academic_terms.
- curriculum_versions, curriculum_subjects, subject_catalog.
- grade_levels, class_groups, teacher_assignments.

Jenis dan jenjang melekat pada education unit, bukan tenant. Satu tenant yayasan dapat menaungi unit umum dan madrasah dengan konfigurasi akademik masing-masing.

## Orang dan enrollment
- people: identitas dasar orang bila model identitas bersama dipilih.
- students: profil siswa.
- guardians: profil wali atau relasi ke people.
- student_guardians: hubungan siswa-wali, jenis hubungan, verifikasi, periode berlaku.
- employees, teachers: profil pegawai dan penugasan guru.
- student_enrollments: riwayat siswa per unit, tahun ajaran, tingkat, rombel, status.
- employee_assignments: riwayat penugasan pegawai per unit.

Identitas siswa dapat tetap dikenali saat pindah unit/tenant, tetapi akses dan pengungkapan histori mengikuti dasar hukum, persetujuan, dan permission. Perpindahan tidak otomatis memberi unit baru akses ke seluruh data privat lama.

## Operasional akademik
- class_subjects, class_schedules, learning_sessions.
- attendance_records, attendance_corrections.
- assessment_categories, assessments, student_scores, score_approvals.
- report_periods, report_cards, report_card_items (setelah format dan workflow disepakati).

## Audit dan file
- audit_events: aktor, aksi, target, scope tenant/unit/platform, waktu, correlation id, metadata minimal.
- stored_files: metadata file, owner/scope, klasifikasi, storage key privat.
- imports, import_rows, exports: proses dan hasil impor/ekspor.

## Relasi utama
- Tenant memiliki satu atau banyak education unit.
- User memiliki membership tenant dan dapat diberi membership unit.
- Unit memiliki periode akademik dan konfigurasi kurikulum.
- Student memiliki banyak enrollment historis pada unit/periode berbeda.
- Enrollment mengacu ke unit, tahun ajaran, tingkat, dan rombel dalam scope sama.
- Student dapat memiliki beberapa guardian; guardian dapat terhubung ke beberapa student.
- Guru memiliki penugasan pada unit/rombel/mapel dan periode.
- Presensi/nilai mengacu ke enrollment atau sesi akademik yang tepat, bukan hanya student_id.

## Invarian domain
1. Setiap education unit memiliki tepat satu tenant aktif.
2. tenant_type hanya mengklasifikasikan pelanggan, bukan jenis/jenjang pendidikan.
3. Setiap operasi unit-scoped memverifikasi unit berada pada tenant context aktif.
4. Tenant membership dan unit membership merupakan dua grant berbeda.
5. Histori enrollment, nilai, presensi, dan penugasan tidak dipindah/dihapus diam-diam saat unit/tenant berubah.
6. Tidak ada akses lintas tenant hanya karena unit berada dalam yayasan atau user mengetahui identifier siswa.

## Keputusan teknis terbuka
- Apakah people menjadi master identitas bersama siswa, wali, dan pegawai.
- Apakah satu siswa boleh memiliki dua enrollment aktif bersamaan.
- Strategi composite foreign key untuk tenant_id/unit_id dan denormalisasi.
- Strategi database fisik per tenant atau shared database/schema.
- Aturan transfer unit dan portabilitas histori.
- Apakah reference catalog bersifat platform-global atau dapat dioverride tenant.
Keputusan ini perlu ADR dan uji skenario nyata sebelum migration.
