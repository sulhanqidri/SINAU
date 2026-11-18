# Model Domain Data SINAU

**Status:** Conceptual model 0.1 — bukan skema migration final.

## Prinsip pemodelan
- Pisahkan identitas orang dari peran orang pada lembaga.
- Pisahkan identitas siswa dari enrollment per unit/tahun ajaran.
- Data historis tidak ditimpa oleh konfigurasi periode baru.
- Semua tabel diklasifikasikan platform, tenant, unit, user, atau reference.
- Tenant/unit scope harus ditegakkan di query, constraint, policy, job, file, cache, dan export.

## Domain dan entitas inti

### Platform dan organisasi
- `tenants`: pelanggan SaaS.
- `schools` atau `education_units`: unit pendidikan di bawah tenant.
- `tenant_memberships`: keanggotaan pengguna pada tenant.
- `school_memberships`: akses pengguna pada unit.
- `users`: akun login.
- `roles`, `permissions`, `role_permissions`, `user_role_assignments`.
- `tenant_subscriptions`, `tenant_module_entitlements`: langganan dan fitur (fase SaaS).

### Referensi pendidikan
- `education_types`: sekolah umum/madrasah/jenis lain yang disahkan.
- `education_levels`: SD, SMP, SMA, SMK, MI, MTs, MA, MAK, dan perluasan yang disetujui.
- `academic_years`, `academic_terms`.
- `curriculum_versions`, `curriculum_subjects`, `subject_catalog`.
- `grade_levels`, `class_groups`, `teacher_assignments`.

### Orang dan enrollment
- `people`: identitas dasar orang bila model identitas bersama dipilih.
- `students`: profil siswa.
- `guardians`: profil wali atau relasi ke people.
- `student_guardians`: hubungan siswa-wali, jenis hubungan, verifikasi, periode berlaku.
- `employees`, `teachers`: profil pegawai dan penugasan guru.
- `student_enrollments`: riwayat siswa per unit, tahun ajaran, tingkat, rombel, status.
- `employee_assignments`: riwayat penugasan pegawai per unit.

### Operasional akademik
- `class_subjects`, `class_schedules`, `learning_sessions`.
- `attendance_records`, `attendance_corrections`.
- `assessment_categories`, `assessments`, `student_scores`, `score_approvals`.
- `report_periods`, `report_cards`, `report_card_items` (setelah format dan workflow disepakati).

### Audit dan file
- `audit_events`: aktor, aksi, target, scope, waktu, correlation id, metadata minimal.
- `stored_files`: metadata file, owner/scope, klasifikasi, storage key privat.
- `imports`, `import_rows`, `exports`: proses dan hasil impor/ekspor.

## Relasi utama
- Tenant memiliki banyak unit pendidikan.
- User memiliki membership pada tenant dan dapat diberi membership pada unit.
- Unit memiliki periode akademik dan konfigurasi kurikulum.
- Student memiliki banyak enrollment historis.
- Enrollment mengacu ke unit, tahun ajaran, tingkat, dan rombel.
- Student dapat memiliki beberapa guardian; guardian dapat terhubung ke beberapa student.
- Guru memiliki penugasan pada unit/rombel/mapel dan periode.
- Presensi/nilai mengacu ke enrollment atau sesi akademik yang tepat, bukan hanya student_id.

## Keputusan yang belum final
- Apakah people menjadi master identitas bersama untuk siswa, wali, dan pegawai.
- Apakah satu siswa boleh memiliki dua enrollment aktif bersamaan.
- Apakah unit dapat berpindah tenant dan bagaimana histori kepemilikannya.
- Apakah reference catalog bersifat platform-global atau dapat dioverride tenant.
- Strategi composite foreign key untuk tenant_id/unit_id.
Keputusan ini perlu ADR dan uji skenario nyata sebelum migration.
