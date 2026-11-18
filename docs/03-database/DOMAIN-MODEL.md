# Model Domain Data SINAU

**Status:** Conceptual model 0.4 — model pelanggan dan kebijakan onboarding/unit entitlement dikonfirmasi; bukan skema migration final.

## Prinsip
- Pisahkan identitas orang dari peran orang pada lembaga.
- Pisahkan identitas siswa dari enrollment per unit/tahun ajaran.
- Data historis tidak ditimpa konfigurasi periode baru.
- Tenant adalah pelanggan SaaS; education unit adalah sekolah/madrasah operasional.
- Semua tabel diklasifikasikan platform, tenant, unit, user, atau reference.
- Tenant/unit scope ditegakkan di query, constraint, policy, job, file, cache, dan export.
- Pilihan bentuk pelanggan tidak menentukan jenis atau jenjang unit.

## Platform dan organisasi

### tenants
Pelanggan SaaS dan batas billing, kontrak, konfigurasi pelanggan, serta isolasi data.
- tenant_type: foundation atau independent_provider.
- Menyimpan identitas legal/organisasi, status lifecycle, zona waktu default, dan metadata kontrak.
- Tenant yayasan dapat memiliki banyak unit, termasuk sekolah umum dan madrasah.
- Tenant mandiri mewakili sekolah/madrasah secara langsung dan dibuat bersama unit pertamanya; tidak memerlukan foundation profile.
- Kedua tipe memakai model dan modul pendidikan yang sama.
- Pendaftar pertama bukan platform administrator.

### foundation_profiles
Profil legal/organisasi khusus tenant foundation, misalnya bentuk badan hukum, nomor pengesahan, alamat kantor, dan kontak.
- Memiliki relasi one-to-one dengan tenant foundation.
- Tidak dibuat untuk independent_provider.
- Dokumen legal tidak wajib diunggah pada registrasi awal dan dapat dilengkapi saat verifikasi.\n- Verification status terpisah dari subscription status; fitur tertentu dapat dibatasi sampai verifikasi selesai.

### education_units
Unit sekolah/madrasah di bawah tepat satu tenant aktif.
- Menyimpan identitas unit, nama resmi, identifier resmi relevan (NPSN/NSM boleh nullable saat registrasi), education form, education level, alamat, status, verification status, dan konfigurasi.\n- Identifier yang diisi harus divalidasi format dan keunikannya; konflik tidak boleh membocorkan data pemilik identifier.
- Satu tenant foundation dapat memiliki banyak unit dengan jenis/jenjang berbeda.
- Unit mandiri dan unit di bawah yayasan memakai struktur data yang sama.
- Tenant mandiri memulai dengan unit pendidikan pertamanya.\n- Kedua tipe tenant dapat memiliki multi-unit jika entitlement paket mencukupi; tenant_type bukan penentu kuota.
- Transfer antar tenant melalui workflow khusus dan audit.

### Membership dan akses
- users: akun autentikasi global; email unik global setelah normalisasi dan verifikasi sesuai kebijakan.
- tenant_memberships: keanggotaan user pada tenant; unique user+tenant, status dan periode berlaku.
- unit_memberships: akses user ke unit; unique user+unit, status dan periode berlaku.
- roles, permissions, role_permissions, user_role_assignments: role assignment mencatat scope platform/tenant/unit.
- tenant_subscriptions: status dan periode langganan; dipisahkan dari verifikasi lembaga.\n- tenant_entitlements / tenant_module_entitlements: fitur dan kuota termasuk batas jumlah unit; entitlement berlaku sama untuk kedua tipe tenant.\n- verification_cases atau struktur setara: proses pemeriksaan dokumen legal dan identifier resmi.
- Tenant membership tidak otomatis memberi akses semua unit; akses unit mengikuti permission/grant eksplisit.
- Pendaftar pertama memperoleh tenant-scoped owner/admin role dan unit-scoped admin role hanya pada unit pertama yang didaftarkan.
- Foundation tenant admin mengelola organisasi/daftar unit sesuai permission, tetapi akses data akademik tiap unit tetap memerlukan grant unit.
- Independent provider admin memperoleh akses operasional pada unit mandirinya.
- Role tenant dan role unit merupakan assignment terpisah.

## Subscription, verification, dan entitlement\n- Subscription menyimpan status billing dan periode paket.\n- Entitlement menyimpan fitur serta batas kuantitatif, termasuk jumlah unit yang dapat dimiliki tenant.\n- Verification menyimpan status pemeriksaan tenant/unit dan referensi dokumen/identifier yang diperiksa.\n- Subscription dan verification adalah dua dimensi independen; policy akses mengevaluasi keduanya.\n- Downgrade tidak menghapus tenant, unit, atau data historis. Jika unit melebihi entitlement baru, penambahan unit baru ditolak sampai kuota sesuai atau paket ditingkatkan. Masa tenggang dan mode akses unit di atas kuota belum diputuskan.\n\n## Referensi pendidikan
- education_types: sekolah umum, madrasah, dan jenis lain yang disahkan.
- education_levels: SD, SMP, SMA, SMK, MI, MTs, MA, MAK, dan perluasan yang disetujui.
- Validasi kombinasi education form dan education level dilakukan server-side.
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
3. foundation_profiles hanya berlaku untuk tenant foundation.
4. Setiap operasi unit-scoped memverifikasi unit berada pada tenant context aktif.
5. Tenant membership dan unit membership merupakan dua grant berbeda.
6. Pendaftar pertama bukan platform admin; role awal dibatasi pada tenant dan unit yang sah.
7. Histori enrollment, nilai, presensi, dan penugasan tidak dipindah/dihapus diam-diam saat unit/tenant berubah.
8. Tidak ada akses lintas tenant hanya karena unit berada dalam yayasan atau user mengetahui identifier siswa.\n9. Kuota unit berasal dari entitlement paket, bukan tenant_type.\n10. Verification status tidak disimpulkan dari subscription status atau sebaliknya.\n11. Downgrade tidak melakukan penghapusan unit/data; batas entitlement diterapkan pada penambahan unit baru.

## Keputusan teknis terbuka
- Apakah people menjadi master identitas bersama siswa, wali, dan pegawai.
- Apakah satu siswa boleh memiliki dua enrollment aktif bersamaan.
- Strategi composite foreign key untuk tenant_id/unit_id dan denormalisasi.
- Strategi database fisik per tenant atau shared database/schema.
- Aturan transfer unit dan portabilitas histori.
- Apakah reference catalog bersifat platform-global atau dapat dioverride tenant.
- Daftar dokumen legal, sumber verifikasi, dan sumber otoritatif identifier.\n- Daftar paket, harga, masa trial, dan kuota unit komersial.\n- Masa tenggang dan mode akses unit saat downgrade membuat jumlah unit melebihi entitlement.\n- Persyaratan fitur yang menunggu verifikasi.
Keputusan ini perlu ADR dan uji skenario nyata sebelum migration.
