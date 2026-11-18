# Audit Konsistensi Logical Design MVP SINAU

**ID:** AUD-LD-001  
**Versi:** 0.2.0 — remediation proposal recorded  
**Tanggal:** 2026-11-18  
**Status:** Audit dan remediation dokumenter selesai pada level proposal; temuan belum ditutup sampai review/approval dan test gate lulus  
**Branch:** `feature/phase-0-requirements-blueprint`  
**Ruang lingkup:** Rekonsiliasi MVP-SCOPE, spesifikasi proses organisasi/siswa, akademik/presensi/asesmen, PPDB/HR (khusus bagian minimum MVP), Domain Model, Domain Ownership Matrix, Logical ERD MVP, Data Dictionary MVP, dan Data Integrity.  
**Batas:** Audit ini tidak menjalankan database/PoC dan bukan audit implementasi. Tidak ada migration, kode aplikasi, atau keputusan bisnis baru yang disahkan oleh dokumen ini.

> **Kesimpulan:** fondasi ownership dan pemisahan tenant/unit sudah cukup konsisten sebagai baseline konseptual. Namun logical model belum siap menjadi physical schema atau migration. Temuan paling penting berada pada histori penempatan siswa ke rombel, konteks sesi/peserta presensi, lifecycle nilai, dan constraint lintas entitas yang saat ini masih diserahkan ke service.

## 1. Metode dan kriteria

Dokumen dibandingkan pada empat sumbu:

1. **Coverage proses:** setiap proses MVP memiliki entitas dan relasi yang cukup untuk merekam keadaan serta histori yang diwajibkan.
2. **Ownership dan scope:** setiap fakta memiliki satu owner dan scope platform/tenant/unit/global yang konsisten.
3. **Integrity dan lifecycle:** FK/unique/check/effective dating/idempotency cukup untuk mencegah data lintas scope, transaksi ganda, dan perubahan historis yang merusak.
4. **Privacy dan authorization:** field sensitif diminimalkan dan akses tidak tersirat dari kesamaan identitas, penempatan kerja, atau relasi keluarga.

Severity:
- **Critical:** berpotensi menyebabkan kebocoran lintas tenant/unit atau kehilangan/kerusakan data inti jika diterapkan.
- **High:** proses MVP atau integritas historis tidak dapat dijamin oleh model saat ini.
- **Medium:** model dapat berjalan dengan kontrol tambahan, tetapi kontrak/keputusan penting belum lengkap.
- **Low:** konsistensi dokumentasi atau kejelasan yang perlu dirapikan sebelum finalisasi.

## 2. Ringkasan temuan

| ID | Severity | Area | Temuan | Status |
|---|---|---|---|---|
| AUD-LD-01 | High | Enrollment / rombel | Model belum memiliki histori penempatan siswa ke rombel yang efektif tanggal; `class_group_id` pada enrollment tidak cukup untuk mutasi rombel | Open |
| AUD-LD-02 | High | Attendance session | Model sesi dan peserta belum merepresentasikan assignment serta roster historis/as-of-date secara eksplisit | Open |
| AUD-LD-03 | High | Assessment | Model nilai belum mencakup status hasil, attempt, versi formula/rubrik, dan workflow review/publikasi minimum yang dijelaskan proses | Open |
| AUD-LD-04 | High | Cross-entity integrity | Kesesuaian kelas/periode/enrollment/subject sebagian besar hanya disebut sebagai validasi service; belum ada rancangan constraint/relasi yang dapat diuji | Open |
| AUD-LD-05 | High | Attendance correction | Model correction request belum membuktikan transisi dari approval ke penerapan revision secara atomik dan dapat ditelusuri | Open |
| AUD-LD-06 | Medium | Identity / guardian | Hubungan GuardianProfile dengan User/login dan grant akses wali belum dimodelkan; keputusan terbuka memang ada, tetapi kontrak privasi harus diselesaikan sebelum portal | Open |
| AUD-LD-07 | Medium | HR / academic assignment | Penempatan pegawai dan assignment akademik sudah dipisahkan, tetapi aturan periode aktif/overlap dan efek perubahan status pegawai belum menjadi constraint/test matrix yang rinci | Open |
| AUD-LD-08 | Medium | File / polymorphic refs | Owner reference file dan target audit/import/export bersifat polymorphic; scope dan otorisasi saat setiap akses masih berupa prinsip, belum kontrak teknis teruji | Open |
| AUD-LD-09 | Medium | Audit actor | Logical ERD dan Data Dictionary perlu diseragamkan untuk actor type, system actor, actor FK, serta perlindungan tamper-evident | Open |
| AUD-LD-10 | Medium | MVP boundary | Sejumlah process spec menguraikan workflow lengkap/post-MVP di samping model MVP minimal; perlu traceability eksplisit agar implementasi tidak melebar | Open |
| AUD-LD-11 | Low | Data dictionary | Beberapa kandidat nullability/field dan istilah masih belum seragam antar artefak; perlu satu putaran lintas referensi setelah keputusan terbuka diselesaikan | Open |

## 3. Temuan terperinci

### AUD-LD-01 — Histori penempatan siswa ke rombel belum dimodelkan

**Severity:** High  
**Bukti dokumentasi:**
- MVP-SCOPE bagian C menyebut enrollment siswa per unit, tahun ajaran, dan rombel.
- BP-ACA-01 mengharuskan penempatan siswa ke rombel, perpindahan rombel dengan tanggal efektif, dan histori lama tidak berubah.
- BP-ACA-01 bagian data konseptual menyebut `ClassEnrollment/Placement`.
- Logical ERD dan Data Dictionary hanya memodelkan `student_enrollments.class_group_id` nullable; belum ada aggregate/tabel placement yang efektif tanggal.

**Dampak:** satu kolom `class_group_id` pada enrollment merepresentasikan kelas saat ini, bukan histori perubahan rombel. Update kolom tersebut berisiko mengubah interpretasi presensi/nilai historis dan tidak dapat menjelaskan kelas siswa pada tanggal tertentu. Mengunci satu enrollment ke satu rombel juga tidak mendukung siswa yang belum ditempatkan atau perpindahan dengan tanggal efektif secara bersih.

**Rekomendasi:**
1. Tambahkan kandidat `student_class_placements` / `class_enrollment_history` milik Student atau Academic setelah ownership kontrak diputuskan.
2. Setiap placement membawa `tenant_id, unit_id, student_enrollment_id, class_group_id, starts_on, ends_on, status, actor, reason`.
3. Definisikan aturan tidak overlap untuk enrollment yang sama; izinkan gap/placement belum ada sesuai proses.
4. Attendance dan assessment mengambil konteks kelas melalui placement yang berlaku pada tanggal transaksi atau snapshot peserta.
5. Jangan mempertahankan `class_group_id` pada enrollment sebagai sumber kebenaran kedua jika tabel placement menjadi authoritative source.

**Keputusan diperlukan:** apakah placement dimiliki Student (karena lifecycle enrollment) atau Academic (karena struktur rombel). Matrix saat ini menempatkan StudentEnrollment pada Student dan ClassGroup pada Academic; kontrak lintas domain perlu eksplisit. Jangan menetapkan owner tanpa persetujuan.

### AUD-LD-02 — Sesi presensi belum mempunyai roster dan teaching context historis yang eksplisit

**Severity:** High  
**Bukti dokumentasi:**
- BP-ACA-03 mengharuskan peserta sesi ditentukan dari enrollment dan penempatan/keanggotaan kelompok pada tanggal sesi.
- BP-ATT-01 mengharuskan peserta sesi dibentuk sebelum presensi, sesi batal tidak dihitung, dan hanya guru/role dengan assignment valid yang dapat mencatat.
- Logical ERD memodelkan `attendance_sessions` dengan `class_group_id`, serta `attendance_records` dengan FK ke session dan enrollment. Tidak ada `session_participants` atau referensi teaching assignment pada model inti.

**Dampak:** perubahan roster setelah sesi terjadi dapat mengubah daftar peserta yang ditampilkan saat membaca ulang sesi. Model juga belum membuktikan guru yang membuka sesi memiliki assignment yang tepat untuk kelas/mapel/tanggal tersebut. FK session+enrollment saja tidak membuktikan enrollment berada pada kelas sesi pada tanggal itu.

**Rekomendasi:**
1. Definisikan apakah sesi MVP selalu per kelas atau dapat per mapel/kelompok/kegiatan.
2. Tambahkan kandidat `attendance_session_participants` (snapshot/eligibility) bila perlu mempertahankan daftar peserta sesi pada saat dibuka/ditutup.
3. Tambahkan referensi ke `teaching_assignment_id` atau jenis sumber kewenangan lain; sesi ad hoc harus memiliki jalur authorization yang eksplisit.
4. Tetapkan aturan pembatalan, pembukaan kembali, dan lock.
5. Buat test bahwa roster yang berubah setelah sesi tidak mengubah peserta historis.

**Keputusan diperlukan:** model sesi minimum MVP (harian, per pelajaran, atau kegiatan) tetap terkait OWN-05/DD-07; jangan menambahkan timetable engine ke MVP.

### AUD-LD-03 — Model assessment belum menutup lifecycle hasil belajar yang dijelaskan proses

**Severity:** High  
**Bukti dokumentasi:**
- BP-ASM-01 membedakan draft, review, approval, publication, missing, exempt, absent, pending, zero, remedial/retake, serta versi formula/rubrik.
- MVP-SCOPE hanya mewajibkan penilaian dasar yang dapat dikonfigurasi dan rekap sederhana; rapor formal berada di luar MVP.
- Logical ERD/Data Dictionary memodelkan `assessment_definitions` dan `student_scores` dengan `score_value` numerik, feedback, dan change history; belum ada status hasil/attempt/scale atau version reference.

**Dampak:** nilai kosong, tidak hadir, exempt, pending, dan nilai nol tidak dapat dibedakan secara andal. Nilai yang belum direview berpotensi terbaca sebagai hasil final. Perubahan formula atau remedial tidak dapat direkonstruksi hanya dari nilai numerik dan history lama/baru.

**Rekomendasi:**
1. Tegaskan batas MVP: nilai dasar boleh memiliki status draft/final sederhana, tetapi tidak boleh menyiratkan workflow rapor formal.
2. Tambahkan kandidat `score_status`/result state dan `assessment_scale_version` atau snapshot aturan minimum.
3. Putuskan apakah attempt/remedial masuk MVP; jika tidak, tandai post-MVP secara konsisten pada process spec.
4. Simpan siapa yang mengesahkan/mempublikasikan jika hasil memang dianggap final dalam MVP.
5. Pastikan missing/absent/exempt/zero berbeda dan punya test.

**Keputusan diperlukan:** skala, kategori, bobot, presisi, status hasil, dan tingkat approval (DD-09).

### AUD-LD-04 — Invariant lintas kelas, periode, enrollment, dan subject belum memiliki strategi constraint

**Severity:** High  
**Bukti dokumentasi:**
- Logical ERD menyebut validasi enrollment pada kelas/periode yang tepat untuk attendance dan assessment melalui service/domain invariant.
- BP-ACA-01/ATT-01/ASM-01 mengharuskan unit, periode, kelas, subject, assignment, enrollment, dan tanggal efektif saling cocok.
- DATA-INTEGRITY mengharuskan composite FK unit-scoped; tetapi aturan relasi lintas entitas yang bukan sekadar tenant/unit belum dijabarkan menjadi key/constraint.

**Dampak:** record dapat berada pada tenant/unit yang benar namun tetap salah secara akademik—misalnya nilai dari asesmen kelas A untuk enrollment yang saat itu berada di kelas B, atau attendance session tahun ajaran berbeda dari enrollment. Validasi aplikasi saja rawan race condition, jalur bulk/import yang berbeda, dan kesalahan job.

**Rekomendasi:**
1. Buat daftar invariant per transaksi: session ↔ class ↔ academic year/term ↔ participant/enrollment; assessment ↔ class ↔ curriculum subject ↔ enrollment; assignment ↔ employee placement ↔ effective dates.
2. Untuk invariant yang dapat dinyatakan relasional, gunakan composite candidate keys/FK atau tabel association/snapshot.
3. Untuk invariant temporal/overlap yang tidak praktis sebagai FK, tentukan exclusion constraint/transaction lock/serializable check yang tepat setelah PoC.
4. Dokumentasikan mana yang ditegakkan DB, mana domain service, dan mengapa.
5. Sertakan negative test dan concurrency test untuk setiap invariant.

### AUD-LD-05 — Approval koreksi presensi belum terhubung secara eksplisit ke revision yang diterapkan

**Severity:** High  
**Bukti dokumentasi:**
- BP-ATT-01: correction request → approved/rejected → applied; menyimpan before/after, approver, waktu, alasan, dan histori.
- Logical ERD memodelkan `attendance_corrections` dengan previous/new status dan review_status.
- Data Dictionary menambahkan `reviewed_at`, tetapi belum ada `applied_at`, revision number/reference, atau definisi transaksi atomik penerapan.

**Dampak:** status approved dapat berbeda dari record attendance yang benar-benar berubah. Retry apply dapat menggandakan revisi atau menerapkan koreksi dua kali. Tidak jelas apakah `attendance_records` di-update atau immutable revision baru dibuat.

**Rekomendasi:**
1. Pilih satu pola: immutable `attendance_revisions` + current pointer, atau mutable current record + append-only history; dokumentasikan source of truth.
2. Hubungkan correction request dengan revision yang dihasilkan.
3. Simpan requested/reviewed/applied actor dan timestamp; approved belum berarti applied.
4. Terapkan approval dan revision dalam transaksi idempotent.
5. Tambahkan test reject, approve, retry, concurrent corrections, dan koreksi setelah lock.

**Keputusan diperlukan:** apakah seluruh koreksi perlu approval atau hanya koreksi setelah submit/lock (DD-08).

### AUD-LD-06 — Guardian identity dan akses aplikasi belum menjadi kontrak data

**Severity:** Medium  
**Bukti dokumentasi:**
- Domain Ownership Matrix menyatakan GuardianProfile bukan otomatis user; guardian access dan verifikasi relasi masih terbuka.
- Logical ERD memisahkan `guardian_profiles`, `student_guardians`, dan `users`; belum ada invitation/link/verified access grant.
- BP-ATT/ASM mengizinkan informasi wali hanya setelah relasi terverifikasi dan hak akses ditetapkan.

**Dampak:** jika portal wali dibangun sebelum keputusan, aplikasi dapat menganggap nomor telepon/email yang tercatat sebagai bukti akses atau menghubungkan satu akun ke anak yang salah. Sebaliknya, jika tidak ada kontrak link, akses yang sah sulit dicabut/ditinjau.

**Rekomendasi:**
1. Tetap jangan membuat GuardianProfile otomatis menjadi User.
2. Sebelum portal wali, desain invitation/claim, verifikasi hubungan, consent/authority, expiry, revocation, multi-child, delegated guardian, dan audit.
3. Batasi MVP pada pencatatan relasi wali dan kontak minimum bila memang diperlukan; jangan membuka portal penuh tanpa change approval.
4. Tetapkan apakah relasi wali berlaku pada satu unit atau dapat dipakai lintas unit.

### AUD-LD-07 — Effective dating HR/Academic memerlukan invariant dan test lintas status

**Severity:** Medium  
**Bukti dokumentasi:**
- Ownership Matrix: HR memiliki EmployeeProfile, employment status, dan EmployeePlacement; Academic memiliki TeachingAssignment/HomeroomAssignment.
- Logical ERD/Data Dictionary sudah memisahkan tabel tersebut dan menandai effective dates.
- BP-HR dan BP-ACA mengharuskan status/placement guru valid saat assignment, histori tetap ada saat pegawai berubah status atau penempatan.

**Dampak:** assignment dapat menunjuk placement yang sudah berakhir, overlap, atau pegawai nonaktif. Sekadar FK memastikan record ada, bukan bahwa ia berlaku pada tanggal mengajar.

**Rekomendasi:**
1. Definisikan aturan transisi employment status dan dampaknya pada assignment berjalan.
2. Validasi assignment dates berada dalam placement dates dan status yang diizinkan.
3. Gunakan transaction lock/constraint temporal sesuai hasil PoC untuk mencegah overlap yang dilarang.
4. Buat test pegawai lintas unit dalam satu tenant, placement berakhir, pegawai nonaktif, assignment historis, dan assignment overlap.

### AUD-LD-08 — Polymorphic file/audit/import references memerlukan kontrak scope dan authorization

**Severity:** Medium  
**Bukti dokumentasi:**
- Data Dictionary menggunakan owner_domain/owner_entity_type/owner_entity_id untuk stored_files, target_type/target_id untuk audit, dan result_entity_type/result_entity_id untuk import.
- DATA-INTEGRITY menyebut polymorphic references memerlukan allowlist, scope check, authorization, dan audit.
- Tidak ada FK biasa yang membuktikan target ada dan berada pada tenant/unit yang sama.

**Dampak:** UUID target yang valid dapat menunjuk record yang tidak ada, salah domain, atau lintas tenant jika akses file/job hanya memeriksa metadata file. Risiko tinggi untuk dokumen verifikasi, data anak, dan export meskipun severity temuan ini Medium pada level model karena prinsip pengamanan sudah disebut.

**Rekomendasi:**
1. Pertimbangkan typed owner reference/junction table untuk domain sensitif (verification evidence, student documents, HR files) alih-alih satu polymorphic generic.
2. Tetapkan authorization di upload, attach, preview, download, export, retry job, dan deletion.
3. Pastikan file scope mewarisi owner scope; perubahan owner/scope harus workflow khusus.
4. Wajibkan object storage private, malware scan, short-lived access, encryption, retention, dan audit sesuai klasifikasi.
5. Test cross-tenant/unit IDOR, file swap, stale signed URL, revoked membership, dan background job.

### AUD-LD-09 — Actor model audit belum seragam

**Severity:** Medium  
**Bukti dokumentasi:**
- Logical ERD menjelaskan `actor_user_id` nullable untuk system actor.
- Data Dictionary memodelkan `actor_type` sebagai wajib dan `actor_user_id` nullable.
- Ownership Matrix mengharuskan actor, scope, target, timestamp, correlation dan tamper-evident audit.

**Dampak:** implementasi yang hanya mengikuti salah satu dokumen dapat menghasilkan event tanpa identitas actor yang dapat ditafsirkan. Selain itu, actor_user_id perlu memastikan actor berada pada scope yang diizinkan; nullable tidak boleh menjadi cara melewati audit.

**Rekomendasi:**
1. Samakan logical ERD dengan Data Dictionary: actor_type enum/allowlist wajib; actor_user_id nullable hanya untuk system/service actor yang memiliki service identity/correlation.
2. Definisikan actor service identity, support/break-glass identity, impersonation/delegation, dan request/job correlation.
3. Tetapkan append-only permission, retention, integrity protection, serta siapa yang dapat membaca metadata.
4. Tambahkan test bahwa setiap perubahan sensitif memiliki actor yang dapat ditelusuri.

### AUD-LD-10 — Process spec harus memisahkan kebutuhan MVP dari roadmap secara konsisten

**Severity:** Medium  
**Bukti dokumentasi:**
- MVP-SCOPE mengeluarkan PPDB penuh, payroll/HR lanjutan, timetable engine, LMS, rapor formal, dan portal lengkap.
- Process specs masih mengandung alur rinci post-MVP berdampingan dengan bagian MVP minimal; beberapa bagian menyatakan release boundary secara eksplisit, namun logical data dictionary tidak selalu memberi label release per entitas/field.

**Dampak:** tim implementasi dapat menganggap setiap entitas/alur dalam dokumen proses sebagai komitmen MVP dan menambah scope tanpa change control.

**Rekomendasi:**
1. Tambahkan tag MVP / post-MVP / discovery pada setiap aggregate dan acceptance criteria di process specs.
2. Buat traceability matrix requirement → process step → entity → owner → test → release.
3. Batasi logical ERD MVP pada kebutuhan minimum; entitas post-MVP berada pada appendix/roadmap.
4. Setiap perubahan perilaku tetap melalui change control dan approval product owner.

### AUD-LD-11 — Konsistensi istilah, field, dan nullability perlu reconciliation akhir

**Severity:** Low  
**Bukti dokumentasi:**
- Logical ERD dan Data Dictionary merupakan dua artefak terpisah yang sama-sama menyebut candidate attributes/constraints.
- Contoh: audit actor, status lifecycle, optional identifiers, dan beberapa field history berkembang pada dictionary setelah logical ERD dibuat.

**Dampak:** implementasi dapat memilih definisi yang berbeda karena tidak jelas dokumen mana yang authoritative untuk setiap aspek.

**Rekomendasi:**
1. Tetapkan Logical ERD sebagai sumber relasi/key dan Data Dictionary sebagai sumber definisi atribut; keduanya harus merujuk versi satu sama lain.
2. Tambahkan ID stabil untuk setiap entity/field/constraint agar perubahan dapat ditrace.
3. Jalankan lint dokumentasi untuk nama tabel/kolom, FK, nullability, status, owner, scope, dan klasifikasi.
4. Perbarui keduanya hanya setelah keputusan AUD-LD-01—10 diterima.

## 4. Konsistensi yang sudah baik

- Tenant dan education unit telah dibedakan dengan benar; tenant type tidak dipakai sebagai education type/level.
- Foundation dan independent provider menggunakan pola unit yang sama; tidak memerlukan parent foundation fiktif.
- Global User identity dipisahkan dari EmployeeProfile dan StudentProfile; membership/role merupakan grant eksplisit.
- Subscription/entitlement, verification, operational lifecycle, dan authorization dipisahkan.
- HR menjadi owner EmployeeProfile/status/placement; Academic menjadi owner ClassGroup/TeachingAssignment/HomeroomAssignment; tidak ada duplikasi master pegawai.
- Student owns StudentProfile/GuardianRelationship/Enrollment; Attendance dan Assessment owns transaksi masing-masing.
- Import/Export diposisikan sebagai orchestration, bukan master data.
- Unit-scoped FK dengan tenant_id + unit_id telah ditetapkan sebagai prinsip; DATA-INTEGRITY menegaskan query/job/export/file juga wajib scope-aware.
- Field PII/SENS diminimalkan; NIK siswa, kesehatan, rekening/gaji, dan dokumen personal tidak ditambahkan tanpa tujuan serta approval.
- PostgreSQL 18 dan shared database/shared schema sudah menjadi baseline yang disepakati; migration tetap menunggu PoC dan gate.

## 5. Rencana tindak lanjut dan urutan

| Urutan | Tindakan | Hasil yang diharapkan | Gerbang |
|---|---|---|---|
| 1 | Product/domain owner memutuskan batas MVP untuk placement, session, assessment result, dan correction | Keputusan eksplisit; tidak mengubah scope diam-diam | Product approval |
| 2 | Revisi Logical ERD untuk AUD-LD-01—05 dan AUD-LD-09 | Relasi, key, lifecycle, dan constraint candidate lengkap | Domain review |
| 3 | Revisi Data Dictionary untuk setiap perubahan ERD | Field, nullability, classification, validation, retention owner konsisten | Data owner + privacy |
| 4 | Buat traceability matrix proses → entity → owner → test | Semua proses MVP punya representasi data dan test | Product/domain review |
| 5 | Buat constraint/test matrix positif, negatif, concurrency, temporal | Bukti integritas tenant/unit dan akademik | DBA/architect/security |
| 6 | Jalankan PoC PostgreSQL untuk constraint baru dan authorization boundary | Hasil teknis tercatat; tidak menyentuh database produksi | Technical gate |
| 7 | Review privacy/security untuk data anak, wali, dokumen, nilai, presensi, file, audit | Purpose, access, retention, deletion, incident controls | Security/privacy gate |
| 8 | Minta acceptance logical design dan data dictionary | Persetujuan sebelum physical schema/migration | Product owner |

## 6. Hal yang tidak boleh dianggap selesai

- Seluruh AUD-LD-01—11 berstatus Open sampai keputusan atau perbaikan terdokumentasi dan diuji.
- OWN-01—10 dan DD-01—15 tetap terbuka; audit ini tidak menutupnya.
- Logical ERD dan Data Dictionary tetap Draft.
- Tidak ada physical schema final, migration domain, atau izin implementasi aplikasi.
- PoC constraint PostgreSQL yang sudah pernah dijalankan hanya membuktikan subset constraint dasar; bukan bukti bahwa invariant akademik, RLS, authorization aplikasi, concurrency, atau file security telah lulus.
- PR #1 tetap Draft/open/unmerged.

## 7. Riwayat perubahan

| Tanggal | Versi | Perubahan |
|---|---|---|
| 2026-11-18 | 0.1.0 | Audit awal konsistensi MVP scope, process specs, ownership, logical ERD, data dictionary, dan data integrity. |


## 8. Status remediation — 2026-11-18 (v0.2.0)

Dokumen sumber yang diperbaiki:
- LOGICAL-ERD-MVP.md §16 — candidate logical model v0.2.0.
- DATA-DICTIONARY-MVP.md §11 — candidate attributes, types, nullability, and classification v0.2.0.
- DATA-INTEGRITY.md — academic invariants, enforcement matrix, file and actor security.
- DOMAIN-OWNERSHIP-MATRIX.md §9 — clarified cross-domain ownership proposal.
- ACADEMIC-ATTENDANCE-ASSESSMENT-PROCESS-SPECIFICATIONS.md §10 — MVP/post-MVP boundary and initial traceability.

| Temuan | Remediasi dokumentasi | Status audit |
|---|---|---|
| AUD-LD-01 | StudentClassPlacement effective-dated, class_group_id pada enrollment deprecated, temporal overlap/test proposal | Draft addressed; owner approval + PoC pending |
| AUD-LD-02 | AttendanceSessionParticipant roster snapshot, participant-based attendance record, optional teaching assignment contract | Draft addressed; session policy decision + PoC pending |
| AUD-LD-03 | AssessmentParticipant snapshot, result_status vs score_value, workflow finalization, scoring rule version/snapshot | Draft addressed; DD-09 policy decision + review pending |
| AUD-LD-04 | Cross-entity invariant matrix, composite FK, temporal constraint, serialized transaction and negative/concurrency tests | Draft addressed; PostgreSQL PoC pending |
| AUD-LD-05 | Append-only AttendanceRecordRevision, correction apply state, atomic/idempotent transaction contract | Draft addressed; DD-08 approval policy + PoC pending |
| AUD-LD-06 | Existing guardian separation retained; no automatic User/login or portal access | Open; privacy/guardian authority decision required |
| AUD-LD-07 | Effective-date and overlap contract for HR placement and Academic assignments | Draft addressed; HR policy and temporal PoC pending |
| AUD-LD-08 | Polymorphic metadata explicitly not authorization; typed association for sensitive files; access re-check matrix | Draft addressed; security architecture and implementation test pending |
| AUD-LD-09 | Unified actor_type, actor_user_id, actor_service_code, support reference, mandatory correlation contract | Draft addressed; security review and tamper-evidence design pending |
| AUD-LD-10 | Explicit MVP/post-MVP table and process→entity→owner→test traceability | Draft addressed; product owner acceptance pending |
| AUD-LD-11 | ERD/Dictionary authority rule and v0.2.0 addenda aligned | Draft addressed; final automated/manual reconciliation pending |

**Penting:** “Draft addressed” berarti proposal desain telah ditulis dan artefak disejajarkan. Itu bukan status Accepted/Closed. Seluruh temuan tetap terbuka untuk gerbang persetujuan, test, dan PoC yang disebut di atas. AUD-LD-06 memerlukan keputusan produk/privacy sebelum portal wali atau akses akun wali dirancang.

## 9. Gerbang untuk menutup audit

Audit baru dapat ditutup setelah:
1. Product owner menyetujui atau merevisi batas MVP untuk placement, session, assessment result, dan attendance correction.
2. Student/Academic owner menyetujui ownership StudentClassPlacement dan kontrak lintas domain.
3. Privacy/security menyetujui klasifikasi, file access, guardian boundary, audit actor, dan retention principles.
4. DBA/architect menjalankan PoC PostgreSQL 18 untuk composite FK, temporal overlap, transaction locking, revision idempotency, dan constraint result status.
5. Test matrix LD-01—LD-16 memiliki bukti lulus termasuk negative dan concurrency tests.
6. Logical ERD dan Data Dictionary lulus reconciliation akhir dan disetujui Product Owner.

Tidak ada migration atau physical schema final sebelum semua gerbang di atas lulus.
