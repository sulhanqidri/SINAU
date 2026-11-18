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
- Dokumen legal tidak wajib diunggah pada registrasi awal dan dapat dilengkapi saat verifikasi.
- Verification status terpisah dari subscription status; fitur tertentu dapat dibatasi sampai verifikasi selesai.

### education_units
Unit sekolah/madrasah di bawah tepat satu tenant aktif.
- Menyimpan identitas unit, nama resmi, identifier resmi relevan (NPSN/NSM boleh nullable saat registrasi), education form, education level, alamat, status, verification status, dan konfigurasi.
- Identifier yang diisi harus divalidasi format dan keunikannya; konflik tidak boleh membocorkan data pemilik identifier.
- Satu tenant foundation dapat memiliki banyak unit dengan jenis/jenjang berbeda.
- Unit mandiri dan unit di bawah yayasan memakai struktur data yang sama.
- Tenant mandiri memulai dengan unit pendidikan pertamanya.
- Kedua tipe tenant dapat memiliki multi-unit jika entitlement paket mencukupi; tenant_type bukan penentu kuota.
- Transfer antar tenant melalui workflow khusus dan audit.

### Membership dan akses
- users: akun autentikasi global; email unik global setelah normalisasi dan verifikasi sesuai kebijakan.
- tenant_memberships: keanggotaan user pada tenant; unique user+tenant, status dan periode berlaku.
- unit_memberships: akses user ke unit; unique user+unit, status dan periode berlaku.
- roles, permissions, role_permissions, user_role_assignments: role assignment mencatat scope platform/tenant/unit.
- tenant_subscriptions: status dan periode langganan; dipisahkan dari verifikasi lembaga.
- tenant_entitlements / tenant_module_entitlements: fitur dan kuota termasuk batas jumlah unit; entitlement berlaku sama untuk kedua tipe tenant.
- verification_cases atau struktur setara: proses pemeriksaan dokumen legal dan identifier resmi.
- Tenant membership tidak otomatis memberi akses semua unit; akses unit mengikuti permission/grant eksplisit.
- Pendaftar pertama memperoleh tenant-scoped owner/admin role dan unit-scoped admin role hanya pada unit pertama yang didaftarkan.
- Foundation tenant admin mengelola organisasi/daftar unit sesuai permission, tetapi akses data akademik tiap unit tetap memerlukan grant unit.
- Independent provider admin memperoleh akses operasional pada unit mandirinya.
- Role tenant dan role unit merupakan assignment terpisah.

## Subscription, verification, dan entitlement
- Subscription menyimpan status billing dan periode paket.
- Entitlement menyimpan fitur serta batas kuantitatif, termasuk jumlah unit yang dapat dimiliki tenant.
- Verification menyimpan status pemeriksaan tenant/unit, referensi dokumen/identifier, dan tenggat verifikasi.
- Masa tenggang verifikasi adalah 7 hari kalender sejak `registration_completed_at`. Jika persyaratan wajib belum dilengkapi sampai akhir hari ke-7, tenant menjadi `suspended`.
- Jika persyaratan sudah diserahkan tepat waktu dan hanya menunggu pemeriksaan internal, status tetap pending dan tenant tidak disuspend karena antrean internal.
- Simpan `registration_completed_at`, `verification_deadline_at`, `verification_submitted_at`, `suspended_at`, `suspension_reason`, dan `suspension_source` atau struktur audit/status-history yang setara.
- Tenant suspended karena verifikasi tetap dapat login pada area terbatas untuk melengkapi persyaratan, melihat alasan, menghubungi dukungan, serta mengakses/mengekspor data sesuai hak. Data tidak dihapus.
- Subscription dan verification adalah dua dimensi independen; penangguhan karena verifikasi tidak otomatis membatalkan atau mengubah subscription.
- Downgrade tidak menghapus tenant, unit, atau data historis. Jika unit melebihi entitlement baru, penambahan unit baru ditolak sampai kuota sesuai atau paket ditingkatkan. Masa tenggang dan mode akses unit di atas kuota masih memerlukan keputusan tersendiri.

## Referensi pendidikan
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
8. Tidak ada akses lintas tenant hanya karena unit berada dalam yayasan atau user mengetahui identifier siswa.
9. Kuota unit berasal dari entitlement paket, bukan tenant_type.
10. Verification status tidak disimpulkan dari subscription status atau sebaliknya.
11. Downgrade tidak melakukan penghapusan unit/data; batas entitlement diterapkan pada penambahan unit baru.
12. Tenggat verifikasi 7 hari dihitung dari timestamp server `registration_completed_at`.
13. Penyerahan persyaratan tepat waktu menghentikan pemicu auto-suspension karena deadline, meskipun review internal belum selesai.

## Keputusan teknis terbuka
- Apakah people menjadi master identitas bersama siswa, wali, dan pegawai.
- Apakah satu siswa boleh memiliki dua enrollment aktif bersamaan.
- Strategi composite foreign key untuk tenant_id/unit_id dan denormalisasi.
- Strategi database fisik per tenant atau shared database/schema.
- Aturan transfer unit dan portabilitas histori.
- Apakah reference catalog bersifat platform-global atau dapat dioverride tenant.
- Daftar dokumen legal, sumber verifikasi, dan sumber otoritatif identifier.
- Daftar paket, harga, masa trial, dan kuota unit komersial.
- Masa tenggang dan mode akses unit saat downgrade membuat jumlah unit melebihi entitlement.
- Persyaratan fitur yang menunggu verifikasi.
Keputusan ini perlu ADR dan uji skenario nyata sebelum migration.


## Pemetaan domain terhadap baseline MVP yang disetujui

Bagian ini mengikat model konseptual ke release boundary pada `docs/02-requirements/MVP-SCOPE.md`. Status MVP tidak otomatis berarti detail entitas/atribut telah final. Nama entitas di bawah bersifat konseptual sampai logical ERD, data dictionary, privacy review, dan PoC diselesaikan.

### Bounded context dan ownership data

| Domain / bounded context | Data yang menjadi ownership utama | Batas tanggung jawab |
|---|---|---|
| SaaS Platform & Tenant | Tenant, FoundationProfile, EducationUnit, tenant lifecycle | Pelanggan SaaS, organisasi/unit, status operasional |
| Identity & Access | User, TenantMembership, UnitMembership, Role, Permission, RoleAssignment, Invitation | Identitas login, grant akses, role dan permission; tidak memiliki profil akademik/pegawai |
| Subscription & Entitlement | Subscription, Plan, Entitlement, Usage | Hak layanan, billing status, kuota dan fitur; tidak menentukan role |
| Verification | VerificationCase, VerificationEvidence, VerificationDecision | Pemeriksaan tenant/unit; terpisah dari subscription dan lifecycle operasional |
| Institution Configuration | InstitutionProfile, EducationType, EducationLevel, AcademicCalendar, AcademicYear, AcademicTerm | Konfigurasi lembaga dan periode akademik |
| Curriculum & Learning Structure | CurriculumVersion, Subject, CurriculumSubject, GradeLevel | Struktur kurikulum dan mapel berversi |
| Student | StudentProfile, GuardianProfile/Person, StudentGuardian, StudentEnrollment | Identitas siswa/wali dan status enrollment per unit/periode/rombel |
| HR | EmployeeProfile, EmploymentStatusHistory, EmployeePlacement | Profil dan status pegawai minimum; tidak memiliki akun login atau role |
| Academic Organization | ClassGroup, HomeroomAssignment, TeachingAssignment | Rombel dan penugasan akademik efektif; merujuk EmployeeProfile dari HR |
| Attendance | AttendanceSession/SessionContext, AttendanceRecord, AttendanceCorrection | Presensi siswa, koreksi, audit dan rekap |
| Assessment | AssessmentDefinition, AssessmentCategory, StudentScore, AssessmentSummary | Penilaian dasar dan rekap sederhana; tidak mengesahkan rapor formal |
| Import & Export | ImportBatch, ImportRow, ExportJob | Validasi, hasil per baris, status, dan audit proses data |
| Audit & File | AuditEvent, StoredFile | Jejak aktivitas dan metadata file sesuai klasifikasi/ownership |

### Batas MVP dan roadmap dalam model domain

- MVP: SaaS tenant/unit, identity/access, subscription/entitlement, verification, konfigurasi institusi/periode, kurikulum/mapel dasar, student/guardian/enrollment dasar, HR minimum, rombel/penugasan guru, attendance, assessment dasar, import CSV, export dan audit.
- Post-MVP: PPDB end-to-end, HRIS lanjutan, timetable engine lengkap, LMS/learning delivery, workflow rapor formal, lifecycle siswa lanjutan, finance, BK, library, assets, correspondence, portal lengkap, dan integrasi eksternal.
- Entitas post-MVP yang sudah disebut pada bagian konseptual sebelumnya adalah placeholder arah domain, bukan komitmen implementasi MVP. Contohnya ClassSchedule, ReportCard, Payroll, atau Finance entities tidak boleh diturunkan menjadi migration MVP tanpa change request.
- Finance tetap di luar model rinci sampai ada discovery, keputusan scope, dan spesifikasi proses tersendiri.

### Aturan ownership lintas domain

1. HR adalah sumber kebenaran EmployeeProfile, employment status, dan placement dasar. Academic merujuk pegawai tersebut dan memiliki TeachingAssignment/HomeroomAssignment beserta periode efektif.
2. Identity & Access memiliki User, credential, membership, role, permission, dan invitation. EmployeeProfile/StudentProfile bukan akun login secara otomatis.
3. Student domain memiliki StudentProfile, relasi wali, dan enrollment. ClassGroup berada pada Academic Organization; enrollment mengacu pada class group dan periode yang valid.
4. Attendance dan Assessment merujuk StudentEnrollment (dan session context jika diperlukan), bukan hanya StudentProfile, agar unit/periode akademik tetap eksplisit.
5. Subscription/Entitlement tidak memberi akses pengguna. Authorization tidak boleh disimpulkan dari paket; sebaliknya, role tidak boleh melewati entitlement.
6. Verification, subscription suspension, dan operational tenant/unit suspension merupakan status/dimensi terpisah sesuai process specifications.
7. Setiap relasi unit-scoped harus menjaga tenant_id dan unit_id tetap konsisten melalui composite key/FK atau mekanisme integritas yang dibuktikan PoC.

### Keputusan model yang masih terbuka

- Pemilihan `Person` sebagai shared identity master untuk siswa, wali, dan pegawai; jangan menggabungkan profil sebelum kebutuhan deduplikasi, privasi, dan lifecycle divalidasi.
- Apakah satu StudentProfile dapat memiliki lebih dari satu StudentEnrollment aktif pada saat yang sama, termasuk lintas unit.
- Identitas siswa lintas tenant, portabilitas histori, dasar hukum, consent, dan pembatasan disclosure.
- Apakah employee profile selalu unit-scoped atau dapat memiliki penempatan lintas unit dalam satu tenant.
- Model sesi minimal untuk attendance tanpa timetable engine lengkap.
- Granularitas kurikulum, mata pelajaran, grade level, dan variasi sekolah umum/madrasah.
- Aturan wali jamak, primary guardian, verifikasi hubungan, dan hak akses.
- Retensi, penghapusan, pseudonimisasi, serta legal hold data anak dan pegawai.

Tidak ada keputusan terbuka di atas yang boleh dianggap selesai hanya karena nama entitas muncul dalam diagram. Catat keputusan berdampak tinggi melalui ADR/change control sebelum logical ERD final atau migration.
