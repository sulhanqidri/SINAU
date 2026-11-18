# SINAU — Project Progress & Handoff Tracker

**Versi tracker:** 1.0  
**Tanggal checkpoint:** 2026-11-18  
**Status proyek:** Perencanaan dan validasi fondasi; belum memasuki implementasi aplikasi  
**Repository:** `sulhanqidri/SINAU`  
**Branch kerja dokumentasi:** `feature/phase-0-requirements-blueprint`  
**Pull request:** [PR #1 — Draft](https://github.com/sulhanqidri/SINAU/pull/1)  
**Aturan:** PR tetap draft dan tidak boleh di-merge tanpa persetujuan pemilik proyek.

> Dokumen ini adalah sumber kebenaran untuk mengetahui posisi pekerjaan SINAU saat sesi kerja berakhir atau dilanjutkan. Status hanya boleh berubah berdasarkan artefak, keputusan, atau hasil pengujian yang dapat diperiksa.

## 1. Status singkat

| Area | Status | Catatan |
|---|---|---|
| Product discovery dan requirement baseline | 🟡 In progress | Baseline MVP disetujui 2026-11-18; validasi stakeholder/praktisi dan requirement rinci tetap berjalan |
| Master blueprint dan katalog dokumen | 🟡 In progress | Master blueprint, katalog kelengkapan, dan peta proses bisnis memiliki baseline draft; belum tervalidasi/diterima |
| Arsitektur aplikasi | 🟡 In progress | Modular monolith adalah baseline; stack aplikasi masih rekomendasi PoC |
| Tenant dan authorization | 🟡 In progress | Model baseline dan ADR ada; implementasi serta pembuktian keamanan belum dilakukan |
| Database PostgreSQL 18 | 🟡 In progress | Engine diputuskan; logical ERD dan data dictionary MVP draft tersedia; review dan PoC menyeluruh belum lulus |
| Design system dan UX | 🟡 In progress | Prinsip dan inventory awal ada; prototipe dan tokens final belum disahkan |
| Aplikasi Laravel/Vue | ⚪ Not started | Belum ada kode aplikasi atau migration domain produksi |
| Modul operasional pendidikan | ⚪ Not started | Belum ada implementasi modul |
| QA, UAT, security hardening | ⚪ Not started | Strategi perlu dilengkapi dan dieksekusi |
| Deployment/release online dan offline | ⚪ Not started | Rencana dokumentasi ada; skrip belum dibuat |

Legenda: 🟢 Done (bukti tersedia dan acceptance terpenuhi) · 🟡 In progress/partial · 🔴 Blocked · ⚪ Not started.

## 2. Checkpoint terakhir yang terverifikasi

### Repository dan tata kelola
- [x] Repository SINAU tersedia dan dapat diakses.
- [x] Branch kerja `feature/phase-0-requirements-blueprint` tersedia.
- [x] PR #1 terbuka dalam status Draft menuju `main`; jangan merge tanpa persetujuan.
- [x] Konstitusi proyek, aturan pengembangan, dan change control tersedia.
- [x] Keputusan penting menggunakan ADR/Decision Log.

### Produk dan model organisasi
- [x] SINAU ditetapkan sebagai SaaS administrasi pendidikan multi-tenant.
- [x] Cakupan baseline: SD, SMP, SMA, SMK, MI, MTs, MA, dan MAK; RA masih calon perluasan.
- [x] Model `foundation` dapat memiliki banyak unit pendidikan.
- [x] Model `independent_provider` dapat menjadi tenant langsung tanpa yayasan fiktif.
- [x] Tenant adalah batas pelanggan/kontrak/billing dan isolasi; education unit adalah batas operasional.
- [ ] Validasi kebutuhan langsung dengan perwakilan sekolah umum, madrasah, yayasan, guru, TU, bendahara, siswa, dan orang tua/wali.
- [x] Baseline prioritas MVP disetujui pemilik produk pada 2026-11-18; revisi selanjutnya melalui change control.
- [ ] Validasi detail kebutuhan dan acceptance criteria dengan stakeholder/praktisi.

### Keputusan teknis
- [x] PostgreSQL 18 dipilih sebagai database utama (ADR-006).
- [x] Shared database/shared schema menjadi baseline isolasi MVP (ADR-002), dengan composite key/FK dan tenant context.
- [x] Authorization baseline: identitas global, tenant/unit membership terpisah, default-deny (ADR-003).
- [ ] Laravel 13 + Vue 3 + Inertia + Tailwind masih rekomendasi PoC, belum keputusan stack final.
- [ ] Finalisasi versi PHP, dependency, authentication/session, queue, cache, storage, observability, dan deployment melalui PoC/ADR.
- [ ] Tidak boleh membuat migration domain produksi sebelum gerbang PoC dan persetujuan pemilik proyek terpenuhi.

### PostgreSQL PoC
- [x] Harness PostgreSQL 18 tersedia di `poc/database-isolation/postgresql/`.
- [x] GitHub Actions run #3 berhasil untuk PostgreSQL 18.7.
- [x] Smoke test constraint relasional berhasil: FK tenant, composite FK, update scope, unique per tenant, membership, delete restriction, dan rollback.
- [ ] Jalankan PoC lengkap dan simpan hasil/bukti.
- [ ] Uji authorization/IDOR, RLS defense-in-depth, raw SQL, concurrency entitlement, query plan/benchmark, serta backup/restore/PITR.
- [ ] Review hasil PoC dan tandai gerbang database diterima secara eksplisit.

### Server SINAU
- [x] VM khusus SINAU dengan Debian 13.7 tersedia.
- [x] PostgreSQL 18.7, PHP 8.4, Composer, Nginx, dan PHP-FPM telah dipasang.
- [x] Cloudflare Tunnel untuk hostname `sinau.sqlradius.my.id` terhubung dan HTTPS publik telah diuji.
- [x] Nginx menampilkan placeholder 503 yang disengaja karena aplikasi belum di-deploy.
- [ ] Aplikasi belum di-clone/deploy; jangan menganggap server sudah menjalankan SINAU.
- [ ] DNS UDP dari server internal pernah bermasalah; akses publik dari HP/komputer sudah berfungsi. Troubleshooting DNS internal dihentikan atas keputusan pemilik proyek. Jangan mengubah NAT/DNS MikroTik lebih lanjut tanpa permintaan.

## 3. Roadmap dan checklist pekerjaan

### Phase 0 — Product discovery & requirements baseline
- [x] Identitas produk, visi, dan cakupan lembaga baseline.
- [x] Model tenant foundation dan independent provider.
- [x] Baseline onboarding, verifikasi, dan unit entitlement (ADR-004).
- [ ] Persona, kebutuhan, pain points, dan journey tiap aktor.
- [ ] SRS lengkap dengan requirement fungsional/nonfungsional dan prioritas.
- [ ] MVP scope final: Must/Should/Could/Out of scope.
- [ ] Acceptance criteria per alur bisnis utama.
- [ ] Register asumsi, risiko, dependensi, dan pertanyaan terbuka.
- **Exit gate:** kebutuhan prioritas disetujui pemilik produk dan tervalidasi dengan skenario pengguna nyata/sintetis yang representatif.

### Phase 1 — Complete blueprint & technical architecture
- [ ] Master blueprint lengkap dan konsisten dengan seluruh spesifikasi.
- [ ] Business process map end-to-end untuk setiap domain utama. (Baseline draft tersedia di `docs/02-requirements/BUSINESS-PROCESS-MAP.md`; menunggu validasi dan spesifikasi turunan.)
- [x] Draft Domain Ownership Matrix MVP tersedia di `docs/03-database/DOMAIN-OWNERSHIP-MATRIX.md`; review/approval ownership masih terbuka.
- [ ] Module catalog, batas modul, dependensi, dan ownership data final.
- [ ] Spesifikasi rinci setiap modul dan submodul.
- [x] Domain model dan ERD konseptual diperbarui agar konsisten dengan baseline MVP yang disetujui; logical ERD, data dictionary, lifecycle dan retention masih terbuka.
- [ ] Tenant/unit context, membership, authorization matrix, dan support access.
- [ ] API/integration blueprint, event, webhook, queue, retry, idempotency.
- [ ] Security/privacy threat model, data classification, audit, consent, retention.
- [ ] UX information architecture, screen inventory, user flow, design tokens, accessibility.
- [ ] Reporting/analytics, import/export, notification, search, file storage.
- [ ] Deployment, environment, backup/restore, disaster recovery, monitoring, SLO/SLA.
- [ ] Regulatory register dan sumber resmi; jangan klaim kepatuhan sebelum verifikasi.
- **Exit gate:** semua domain dan kontrak lintas modul terdokumentasi; konflik keputusan ditutup atau dicatat sebagai blocker; pemilik produk menyetujui blueprint baseline.

### Phase 2 — Technical proof of concept
- [ ] PoC PostgreSQL lengkap sesuai DATABASE-POC-PLAN.
- [ ] PoC stack aplikasi dan kompatibilitas dependency.
- [ ] PoC tenant/unit resolver dan authorization.
- [ ] PoC RLS (bila dipilih) dan evaluasi connection pooling/context reset.
- [ ] PoC queue, cache, private storage, search, export, dan audit.
- [ ] PoC concurrency, load, query plan, backup/restore, dan recovery.
- [ ] Simpan command, environment, hasil, log yang sudah disanitasi, dan keputusan.
- **Exit gate:** seluruh blocker kritis lulus; hasil ditinjau dan disetujui pemilik proyek.

### Phase 3 — Application foundation
- [ ] Buat branch implementasi sesuai aturan Git.
- [ ] Bootstrap Laravel/Vue/Inertia/Tailwind setelah stack disetujui.
- [ ] CI lint, static analysis, unit/feature test, dependency/security scan.
- [ ] Authentication, session/security baseline, tenant/unit context.
- [ ] Membership, authorization default-deny, audit trail.
- [ ] PostgreSQL migrations fondasi dan test harness isolasi.
- [ ] Private file storage, queue, cache, notification foundation.
- [ ] Shell UI, navigation, tenant/unit switcher, design tokens.
- **Exit gate:** fondasi aman dan test tenant isolation lulus sebelum modul domain dimulai.

### Phase 4 — MVP domain modules
Urutan dan isi baseline mengikuti MVP-SCOPE.md yang disetujui pemilik produk pada 2026-11-18; revisi tetap dimungkinkan melalui change control. Daftar berikut memisahkan **minimum MVP** dari **roadmap/post-MVP** agar kandidat modul tidak terbaca sebagai komitmen fitur.

**Minimum MVP yang diturunkan dari MVP-SCOPE.md:**
- [ ] Platform SaaS: tenant, unit, onboarding/verifikasi, subscription/entitlement, identity, membership, role, permission.
- [ ] Master data lembaga, kalender, tahun ajaran, semester, kurikulum/versi, mata pelajaran.
- [ ] StudentProfile, guardian relationship minimum, StudentEnrollment per unit/periode/rombel; status dasar dan histori.
- [ ] HR minimum: profil pegawai/guru, status kerja dasar, penempatan yang diperlukan; TeachingAssignment/HomeroomAssignment dikelola academic domain.
- [ ] Kelas/rombel, mata pelajaran, penugasan guru dasar.
- [ ] Presensi siswa per kelas/sesi, koreksi beralasan, audit, rekap sederhana.
- [ ] Penilaian dasar yang dapat dikonfigurasi, rekap hasil belajar sederhana, dan ekspor sesuai permission.
- [ ] Import CSV awal dengan preview, validasi, hasil per baris, dan audit.
- **Exit gate:** acceptance criteria, tenant/unit/role tests, audit, dokumentasi, UAT sekolah umum dan madrasah, serta persetujuan product owner.

**Roadmap / post-MVP — jangan masuk sprint MVP tanpa change request:**
- [ ] PPDB end-to-end dan pembayaran pendaftaran (BP-ADM-01).
- [ ] HRIS lanjutan: kontrak terperinci, cuti, presensi pegawai, payroll, offboarding lanjutan.
- [ ] Timetable engine lengkap dan publikasi jadwal periodik (BP-ACA-02).
- [ ] Learning delivery, tugas, materi, aktivitas, dan LMS (BP-ACA-03).
- [ ] Workflow pengesahan formal, rapor resmi, transkrip, publikasi dan arsip (BP-ASM-02).
- [ ] Lifecycle siswa lanjutan: transfer lintas unit, cuti formal, promosi massal, kelulusan formal, alumni (BP-STD-02).
- [ ] Keuangan: tagihan, pembayaran, kas, jurnal, anggaran, rekonsiliasi (BP-FIN-01/02); belum ada persetujuan scope atau spesifikasi rinci.
- [ ] Kesiswaan/BK, surat/disposisi, perpustakaan, inventaris/aset, portal lengkap, integrasi eksternal, dan analitik lanjutan.
- **Gate:** masing-masing domain memerlukan discovery, keputusan scope, privacy/legal review, module blueprint, dan change request sebelum implementasi.

### Phase 5 — Quality, security, UAT & release readiness
- [ ] Regression, integration, E2E, accessibility, responsive, performance tests.
- [ ] Tenant isolation/IDOR test menyeluruh untuk API, query, file, export, cache, search, queue, scheduler.
- [ ] Threat-model review, dependency scan, secret scan, vulnerability remediation.
- [ ] UAT sekolah umum dan madrasah untuk skenario yang relevan.
- [ ] Data migration/import validation dan rollback/forward-fix plan.
- [ ] Backup restore drill, disaster recovery drill, monitoring dan alert.
- [ ] Release notes, support runbook, incident response, privacy/retention policy.
- **Exit gate:** tidak ada blocker keamanan/data; UAT dan restore drill lulus; release disetujui.

### Phase 6 — Deployment, operations & continuous improvement
- [ ] Deployment online idempotent dan aman.
- [ ] Offline release bundle dan deployment tanpa akses internet.
- [ ] install-server, health-check, backup, restore, rollback, logging.
- [ ] Preproduction-to-production promotion dan release verification.
- [ ] Monitoring kapasitas, queue, database, error, uptime, dan biaya.
- [ ] Prosedur upgrade, patch security, incident, support, dan lifecycle.
- [ ] Roadmap pasca-MVP berdasarkan feedback dan metrik.
- **Exit gate:** prosedur deployment/rollback/restore diuji pada environment disposable/staging dan runbook disetujui.

## 4. Aturan pembaruan tracker

Setiap sesi kerja wajib melakukan langkah berikut:

1. Baca dokumen ini terlebih dahulu, lalu baca dokumen yang dirujuk pada bagian pekerjaan aktif.
2. Sebelum mengubah status, periksa file, commit, PR, test run, atau bukti yang relevan.
3. Ubah `[ ]` menjadi `[x]` hanya jika acceptance criteria terpenuhi dan bukti dicatat.
4. Untuk pekerjaan parsial, tetap gunakan `[ ]` dan tambahkan catatan kemajuan; jangan menandai selesai.
5. Catat keputusan baru di ADR/Decision Log, bukan hanya di tracker.
6. Setelah sesi, perbarui bagian checkpoint berikut dan commit perubahan dokumentasi pada branch kerja.
7. Jangan mengubah status PR menjadi ready atau merge tanpa persetujuan pemilik proyek.

## 5. Session handoff — checkpoint terbaru

**Tanggal:** 2026-11-18  
**Fokus terakhir:** membangun baseline Master Blueprint dan peta proses, lalu menurunkan BP-PLT-01—04, BP-ORG-01/02, BP-STD-01/02, serta BP-ACA-01—03, BP-ATT-01, BP-ASM-01—02, BP-ADM-01, dan BP-HR-01 menjadi spesifikasi proses draft.

**Yang sudah dikonfirmasi pada sesi ini:**
- README, Master Blueprint, Project Constitution, Development Rules, Change Control, Implementation Plan, Decision Log, dan dokumen sekolah umum/madrasah telah ditinjau.
- `docs/01-blueprint/MASTER-BLUEPRINT.md` telah diperluas menjadi baseline v0.2.0; tetap Draft dan belum final.
- `docs/01-blueprint/BLUEPRINT-CATALOG.md` telah dibuat sebagai matriks kelengkapan blueprint lintas produk, pendidikan, data, arsitektur, keamanan, UX, testing, dan operasi.
- `docs/00-governance/PROJECT-PROGRESS.md` telah dibuat sebagai sumber status dan handoff sesi.
- README telah diperbarui agar memulai dari tracker dan katalog blueprint, serta menautkan peta proses bisnis.
- `docs/02-requirements/BUSINESS-PROCESS-MAP.md` telah dibuat sebagai draft baseline proses end-to-end, mencakup platform SaaS, onboarding, siklus akademik, keuangan, layanan pendukung, komunikasi, laporan, keamanan, dan penutupan periode.
- Process register, aktor, output, alur utama, variasi, kontrol tenant/unit, serta pertanyaan terbuka telah dicatat. Dokumen belum tervalidasi dengan stakeholder dan bukan spesifikasi final.
- Blueprint Catalog telah ditautkan ke peta proses dan mencatat pekerjaan validasi/turunan yang tersisa.
- Perubahan berada pada branch `feature/phase-0-requirements-blueprint`; PR #1 tetap Draft dan belum merged.

**Pekerjaan berikutnya (urutan wajib):**
1. Audit seluruh struktur dokumen repository dan cocokkan semua tautan/path dalam README serta Blueprint Catalog.
2. Validasi peta proses bisnis dengan stakeholder/perwakilan yayasan, sekolah umum, madrasah, operator, guru, bendahara, siswa, dan wali; putuskan prioritas MVP.
3. Turunkan BP-PLT-01 sampai BP-PLT-04 dan BP-ORG/STD/ACA/ATT/ASM prioritas menjadi spesifikasi proses rinci dengan swimlane, state machine, exception, approval, dan acceptance criteria.
4. Susun persona/journey dan RACI; setelah proses disepakati, sinkronkan domain model, ERD logis, data dictionary, dan authorization matrix.
5. Perbarui tracker setiap selesai satu artefak atau gerbang.

**Jangan dilakukan sebelum persetujuan/gerbang:**
- Jangan merge PR #1.
- Jangan membuat migration domain produksi.
- Jangan memulai implementasi fitur akademik/keuangan.
- Jangan menganggap stack Laravel final sebelum PoC dan ADR final.
- Jangan mengubah konfigurasi SQLRadius/MikroTik; SINAU adalah proyek terpisah.



**Checkpoint tambahan — 2026-11-18:** Spesifikasi proses platform SaaS dan tenant BP-PLT-01—04 telah dibuat sebagai Draft 0.1.0. Dokumen mencakup registrasi/pembentukan tenant, penambahan unit, verifikasi, subscription/entitlement, downgrade/suspend/reaktivasi, aktor, aturan bisnis, state, authorization baseline, API/event konseptual, screen inventory, acceptance criteria, test scenario, dan open decisions. Ini bukan persetujuan implementasi. Pekerjaan berikutnya: validasi stakeholder, putuskan OPEN-PLT-01—10 (terutama verifikasi legal dan kebijakan komersial/kuota), lalu lanjutkan spesifikasi BP-ORG dan BP-STD.



**Checkpoint tambahan — 2026-11-18:** Spesifikasi BP-ORG-01 (profil/struktur lembaga), BP-ORG-02 (kalender/tahun ajaran/kurikulum), BP-STD-01 (registrasi siswa/enrollment), dan BP-STD-02 (mutasi, cuti, nonaktif, kenaikan kelas, kelulusan, alumni) telah dibuat sebagai Draft 0.1.0 di `docs/02-requirements/ORGANIZATION-AND-STUDENT-PROCESS-SPECIFICATIONS.md`. Dokumen memuat alur, aturan bisnis, state konseptual, data, authorization, acceptance criteria, test minimum, screen inventory, traceability, dan 20 keputusan terbuka. Katalog blueprint diperbarui. Status tetap draft; belum validasi stakeholder, belum verifikasi regulasi/kurikulum, dan bukan izin implementasi.

## 6. Format catatan sesi berikutnya

Salin dan isi bagian ini setiap mengakhiri sesi:

```md
### Session checkpoint — YYYY-MM-DD
- Fokus:
- Branch/commit:
- Dokumen/kode yang diubah:
- Pekerjaan selesai (bukti):
- Pekerjaan parsial:
- Test/CI yang dijalankan dan hasil:
- Keputusan/ADR baru:
- Risiko/blocker:
- Next action paling dekat:
- Hal yang tidak boleh dilakukan:
```


**Checkpoint tambahan — 2026-11-18:** Spesifikasi proses akademik, presensi, dan asesmen BP-ACA-01—03, BP-ATT-01, BP-ASM-01—02 telah dibuat sebagai Draft 0.1.0 di `docs/02-requirements/ACADEMIC-ATTENDANCE-ASSESSMENT-PROCESS-SPECIFICATIONS.md`. Cakupan meliputi struktur kelas/rombel/mapel/penugasan, jadwal dan konflik, sesi pembelajaran, presensi dan koreksi, perencanaan asesmen, pengolahan nilai, review/pengesahan, snapshot rapor, publikasi, authorization baseline, data/API/event konseptual, screen inventory, acceptance criteria, 26 test minimum, traceability, dan 21 keputusan terbuka. Blueprint Catalog diperbarui. Status tetap draft; belum divalidasi stakeholder, belum diverifikasi terhadap regulasi/kurikulum, dan bukan izin implementasi.

**Pekerjaan berikutnya (urutan):**
1. Validasi spesifikasi BP-PLT, BP-ORG/STD, dan BP-ACA/ATT/ASM bersama perwakilan foundation, sekolah umum, madrasah, operator, guru, kepala, siswa, serta wali; putuskan batas MVP.
2. Tutup keputusan terbuka yang berdampak pada model data, terutama penempatan siswa/mapel, metode dan periode presensi, status kehadiran, formula/skala nilai, remedial, approval, dan rapor.
3. Susun spesifikasi proses keuangan (BP-FIN) dan layanan pendukung yang disetujui; audit konsistensi seluruh spesifikasi proses.
4. Setelah proses prioritas tervalidasi, susun persona/journey, RACI, domain model, ERD logis, data dictionary, authorization matrix, API/event contracts.
5. Jalankan PoC teknis sesuai gerbang; jangan mulai migration domain produksi sebelum persetujuan eksplisit.

**Batasan tetap:** PR #1 tetap Draft/open dan tidak di-merge; server SINAU tetap placeholder, belum deploy aplikasi; tidak mengubah SQLRadius/MikroTik.


**Checkpoint tambahan — 2026-11-18:** Spesifikasi proses PPDB dan HR BP-ADM-01/BP-HR-01 telah dibuat sebagai Draft 0.1.0 di `docs/02-requirements/ADMISSIONS-AND-HR-PROCESS-SPECIFICATIONS.md`. Cakupan PPDB meliputi konfigurasi gelombang/jalur/kuota, pendaftaran, verifikasi dokumen, seleksi, keputusan, pengumuman privat, daftar ulang, waiting list, appeal, dan conversion ke StudentProfile/Enrollment. Cakupan HR meliputi employee profile, hubungan kerja, penempatan organisasi, teaching assignment, perubahan status, offboarding, serta pemisahan status kepegawaian dari user account/permission. Dokumen memuat authorization baseline, data/API/event konseptual, screen inventory, acceptance criteria, 28 skenario pengujian minimum, traceability, dan 20 keputusan terbuka. Blueprint Catalog diperbarui. Status tetap draft; belum divalidasi stakeholder dan belum diverifikasi terhadap peraturan resmi.

**Pekerjaan berikutnya (urutan):**
1. Audit konsistensi seluruh process specifications terhadap Business Process Map, Product Requirements, MVP Scope, ADR, dan antar-domain; perbaiki ID, istilah, dependency, serta tautan yang tidak konsisten.
2. Turunkan BP-FIN-01/02 hanya setelah prioritas keuangan dan boundary MVP disetujui; jika belum, lanjutkan persona/user journey dan stakeholder/RACI untuk domain yang sudah memiliki baseline.
3. Tutup keputusan terbuka lintas proses yang berdampak pada domain model: identitas/enrollment, hubungan wali, PPDB conversion, employee/user separation, assignment, presensi, formula nilai, privacy, retention, approval.
4. Susun domain model, ERD logis, data dictionary, authorization matrix, dan API/event contracts setelah hasil validasi kebutuhan.
5. Pertahankan semua artefak sebagai draft sampai ada validasi stakeholder dan persetujuan product owner; jangan membuat migration domain produksi sebelum gerbang PoC.

**Batasan tetap:** PR #1 tetap Draft/open dan tidak di-merge; server SINAU tetap placeholder, belum deploy aplikasi; tidak mengubah SQLRadius/MikroTik.


**Verifikasi penutup sesi — 2026-11-18:** Dokumen BP-ADM/BP-HR ter-fetch kembali (39.633 karakter); kedua process ID dan seluruh bagian wajib ditemukan; 21 keputusan terbuka terdaftar. Blueprint Catalog telah diperiksa ulang, baris PPDB/HR dan checklist turunan tercatat, serta line break markdown dibersihkan. PR #1 masih open, draft=true, merged=false. Head branch terakhir setelah pembaruan katalog: `25e3793ecc2c9d479806a530fa3e3b22342b2309`.


---

### Session checkpoint — 2026-11-18 (audit konsistensi proses)
- Fokus: audit konsistensi Business Process Map, PRD, MVP Scope, process specifications, ADR, Blueprint Catalog, README, dan Project Progress.
- Branch: `feature/phase-0-requirements-blueprint`.
- Dokumen baru: `docs/02-requirements/PROCESS-SPECIFICATION-CONSISTENCY-AUDIT.md` (AUD-REQ-001, Draft 0.1.0).
- Temuan: 4 High, 4 Medium, 1 Low. Isu utama adalah ketidaksesuaian semantik ID BP-PLT-02/03/04; BP-PLT-04 identity/access belum terpetakan konsisten; PPDB/HR perlu dipisahkan tegas dari batas MVP; ownership HR employee profile versus academic teaching assignment perlu ditetapkan.
- Konsistensi yang terkonfirmasi: model foundation/independent_provider, tenant versus education unit, pemisahan StudentProfile/Enrollment, pemisahan EmployeeProfile/UserAccount/ApplicationRole, PostgreSQL 18 accepted, stack aplikasi masih PoC recommendation.
- Blueprint Catalog diperbarui dengan tautan audit dan checklist audit. Temuan belum diremediasi ke spesifikasi sumber karena perubahan ID, ownership, dan scope memerlukan keputusan product owner.
- Tidak ada kode aplikasi, migration domain produksi, konfigurasi server, SQLRadius, atau MikroTik yang diubah.
- PR #1 tetap Draft/open/unmerged; jangan merge tanpa instruksi eksplisit.
- Next action: putuskan mapping ID BP-PLT, lalu scope PPDB/HR minimum, ownership HR versus academic assignment, dan boundary MVP jadwal/pembelajaran/rapor. Setelah keputusan, lakukan remediation ke dokumen sumber dan sinkronkan traceability.


---

### Session checkpoint — 2026-11-18 (remediasi konflik ID BP-PLT)
- Fokus: menghilangkan konflik process ID platform antara Business Process Map dan spesifikasi Platform/Tenant.
- Branch: `feature/phase-0-requirements-blueprint`.
- ID kanonis: BP-PLT-01 registrasi/onboarding; BP-PLT-02 penambahan/pengelolaan unit; BP-PLT-03 verifikasi; BP-PLT-04 subscription/entitlement; BP-PLT-05 identity/invitation/membership/role/access; BP-PLT-06 lifecycle tenant/unit.
- Business Process Map diperbarui: process register dan uraian BP-PLT-02—06 diselaraskan; batas provisioning unit, verification, billing, access grant, dan operational lifecycle dinyatakan eksplisit.
- PLATFORM-TENANT-PROCESS-SPECIFICATIONS.md diperluas menjadi BP-PLT-01—05; BP-PLT-05 memiliki alur invitation/acceptance, perubahan/revoke, state konseptual, aturan keamanan, acceptance criteria AC-PLT-05-01—10, dan test minimum.
- BP-PLT-01 tetap membuat membership awal dalam transaksi onboarding; BP-PLT-05 mengatur invitation anggota tambahan dan perubahan/pencabutan akses.
- Audit AUD-01 dan AUD-02 ditandai resolved pada tingkat ID/dokumentasi. BP-PLT-06 masih perlu spesifikasi rinci sebelum implementasi.
- Blueprint Catalog dan README requirements diperbarui; checkpoint dicatat untuk handoff.
- Tidak ada kode aplikasi, migration, deployment, SQLRadius, atau MikroTik yang diubah.
- PR #1 tetap Draft/open dan tidak di-merge.
- Next action: verifikasi menyeluruh semua referensi BP-PLT, lalu remediasi AUD-03—AUD-09 sesuai prioritas dan keputusan scope.


---

### Session checkpoint — 2026-11-18 (spesifikasi rinci BP-PLT-06)
- Fokus: menurunkan BP-PLT-06 lifecycle tenant/unit ke spesifikasi proses rinci dan menyelaraskan artefak referensi.
- Branch: feature/phase-0-requirements-blueprint.
- Dokumen diubah:
  - PLATFORM-TENANT-PROCESS-SPECIFICATIONS.md: cakupan diperluas menjadi BP-PLT-01—06; ditambahkan §14 untuk suspend operasional, close tenant/unit, transfer unit antar-tenant, restore, state konseptual, 15 business rules, 14 acceptance criteria, 20 test scenario, API/event/screen inventory, serta OPEN-PLT-11—18.
  - BUSINESS-PROCESS-MAP.md: uraian BP-PLT-06 diselaraskan dengan spesifikasi rinci dan batas BP-PLT-02—05.
  - PROCESS-SPECIFICATION-CONSISTENCY-AUDIT.md: referensi BP-PLT-06 diperbarui; kekosongan dokumen rinci dinyatakan selesai pada tingkat artefak, bukan policy approval.
  - BLUEPRINT-CATALOG.md: status spesifikasi platform diperbarui ke BP-PLT-01—06; checklist BP-PLT-06 ditandai tersedia sebagai draft.
- Batas proses dipertahankan: BP-PLT-04 = billing/subscription; BP-PLT-03 = verification; BP-PLT-05 = membership/role/access; BP-PLT-06 = operational lifecycle; BP-PLT-02 = provisioning/pengelolaan unit.
- Risiko/keputusan terbuka: OPEN-PLT-11—18. Khusus transfer unit lintas tenant, legal basis, consent/authority, kategori data, identifier/kontrak, retention, dan strategi cutover/rollback belum diputuskan. Tidak ada asumsi bahwa seluruh data ikut transfer.
- Validasi dokumentasi dan status PR harus dilakukan setelah commit.
- Tidak ada kode aplikasi, migration domain, deployment, konfigurasi server, SQLRadius, atau MikroTik yang diubah.
- PR #1 harus tetap Draft/open/unmerged; tidak ada instruksi merge.
- Next action: verifikasi hasil dokumentasi dan status PR; kemudian lanjutkan remediasi AUD-03—AUD-09 atau stakeholder validation sesuai prioritas product owner.
- Hal yang tidak boleh dilakukan: jangan implementasikan transfer lintas tenant, jangan membuat migration domain produksi, jangan merge PR #1, dan jangan mengubah SQLRadius/MikroTik.


---

### Session checkpoint — 2026-11-18 (remediasi AUD-03—AUD-09)
- Fokus: menyelaraskan spesifikasi proses rinci dengan release boundary MVP dan ownership data lintas HR/akademik.
- Dokumen yang diperbarui:
  - ADMISSIONS-AND-HR-PROCESS-SPECIFICATIONS.md: BP-ADM-01 diberi label post-MVP; BP-HR-01 dipilah HR minimum MVP versus HR lanjutan; HR sebagai owner EmployeeProfile/employment status/placement; academic domain sebagai owner TeachingAssignment/HomeroomAssignment.
  - ACADEMIC-ATTENDANCE-ASSESSMENT-PROCESS-SPECIFICATIONS.md: timetable lengkap, learning delivery/LMS, dan rapor formal ditandai post-MVP; presensi, penilaian dasar, rekap sederhana tetap minimum MVP; assignment akademik ditegaskan sebagai ownership academic domain.
  - ORGANIZATION-AND-STUDENT-PROCESS-SPECIFICATIONS.md: lifecycle siswa minimum MVP dipisahkan dari transfer lintas unit, cuti formal, promosi massal, kelulusan formal, dan alumni post-MVP.
  - BUSINESS-PROCESS-MAP.md: register dan deskripsi BP-ADM-01, BP-HR-01, BP-STD-02, BP-ACA-02/03, BP-ASM-02, serta BP-FIN-01/02 diselaraskan dengan release boundary.
  - Blueprint Catalog dan README requirements diperbarui untuk membedakan process spec draft dari module blueprint yang belum dimulai.
  - Audit AUD-03—AUD-09 diperbarui pada tingkat dokumentasi; keputusan produk/field sensitif/finance priority tetap menunggu product owner.
- Ownership baseline: HR owns EmployeeProfile, employment status, organization placement; Academic owns TeachingAssignment/HomeroomAssignment; BP-PLT-05 owns application identity/membership/role. Tidak ada duplikasi profil pegawai atau assignment.
- Finance: BP-FIN-01/02 tetap Candidate/roadmap dan out of MVP. Tidak dibuat spesifikasi rinci atau domain model keuangan.
- Tidak ada kode aplikasi, migration, deployment, database schema, server, SQLRadius, atau MikroTik yang diubah.
- PR #1 harus tetap Draft/open/unmerged.
- Next action: verifikasi konsistensi tujuh temuan audit, tautan README, process register, MVP Scope, Phase 4 tracker, dan status PR. Setelah verifikasi, minta product owner mengesahkan MVP boundary dan ownership baseline sebelum domain model/ERD logis.
- Hal yang tidak boleh dilakukan: jangan implementasikan PPDB, HRIS lanjutan, timetable engine, LMS, rapor formal, finance, atau transfer siswa lintas tenant tanpa change request/approval; jangan merge PR #1.


### Checkpoint tambahan — 2026-11-18: Persetujuan baseline MVP

- Pemilik produk menyetujui `docs/02-requirements/MVP-SCOPE.md` sebagai baseline perencanaan MVP.
- Persetujuan dicatat pada `docs/09-decisions/DECISION-LOG.md` dan di dalam MVP-SCOPE.md.
- Scope dapat direvisi di tengah proyek. Perubahan perilaku/scope wajib melalui change control, mencatat alasan dan dampak lintas proses, modul, data, keamanan/privasi, jadwal, dan acceptance criteria, serta memperoleh persetujuan pemilik produk.
- Persetujuan MVP bukan persetujuan final atas setiap detail proses/data/regulasi/stack dan bukan izin memulai migration atau deployment produksi.
- Tahap berikut: audit dan pemutakhiran domain model serta ERD konseptual agar konsisten dengan MVP yang disetujui; setelah itu lanjut ke ownership domain, logical ERD, data dictionary, dan traceability.
- Tidak ada kode aplikasi, migration, konfigurasi server, SQLRadius, atau MikroTik yang diubah. PR #1 tetap Draft/open/unmerged.


### Checkpoint tambahan — 2026-11-18: Domain model dan ERD konseptual

**Keputusan yang tercatat**
- MVP-SCOPE.md berstatus Accepted sebagai baseline perencanaan setelah persetujuan pemilik produk. Revisi di tengah jalan diperbolehkan melalui change control.
- Decision Log dan MVP-SCOPE.md menjelaskan bahwa perubahan scope/perilaku harus mencatat alasan, dampak lintas domain, keamanan/privasi, jadwal, acceptance criteria, dan persetujuan pemilik produk.
- Persetujuan MVP tidak mengesahkan otomatis detail field, aturan regulasi, stack, logical schema, atau implementasi produksi.

**Artefak diperbarui**
- `docs/03-database/DOMAIN-MODEL.md`: bounded context, ownership data, pemetaan MVP/post-MVP, batas lintas domain, dan daftar keputusan model yang masih terbuka ditambahkan.
- `docs/03-database/ERD-CONCEPTUAL.md`: batas interpretasi diagram, ownership HR/Academic/Identity/Student, dan batas teknis yang belum diputuskan ditambahkan.
- `docs/09-decisions/DECISION-LOG.md`: persetujuan baseline MVP dicatat.
- `docs/02-requirements/MVP-SCOPE.md`: status dan prosedur revisi ditambahkan.

**Status pekerjaan**
- Domain model/ERD konseptual diselaraskan pada level konseptual; belum merupakan logical ERD atau skema database final.
- Keputusan tentang Person master, multi-enrollment aktif, portabilitas identitas siswa, penempatan pegawai lintas unit, attendance session context, guardian access, retention/privacy masih terbuka.
- Tidak ada migration, kode aplikasi, deployment, atau perubahan server.
- PR #1 tetap Draft/open/unmerged.

**Langkah berikutnya**
1. Buat domain ownership matrix yang lebih rinci per entitas, termasuk authoritative owner, scope (platform/tenant/unit), lifecycle, dan consumer.
2. Turunkan entity relationship dan cardinality ke logical ERD untuk domain MVP.
3. Lengkapi data dictionary dengan definisi, scope, klasifikasi, source of truth, nullability kandidat, dan aturan historisasi.
4. Validasi keputusan privasi/identitas anak, akses wali, serta enrollment sebelum logical schema dianggap siap.
5. Jangan membuat migration domain sebelum logical model direview dan gerbang PoC/keamanan dipenuhi.


### Checkpoint tambahan — 2026-11-18: Domain Ownership Matrix v0.1.0

- Dibuat `docs/03-database/DOMAIN-OWNERSHIP-MATRIX.md` berisi 20 bounded context/domain, authoritative owner, scope, entitas konseptual, consumer, batas tanggung jawab, kontrak lintas domain, keputusan terbuka, dan acceptance criteria.
- Penegasan utama: HR memiliki EmployeeProfile/status/placement; Academic memiliki ClassGroup/TeachingAssignment/HomeroomAssignment; Identity memiliki User/credential/membership/role; Student memiliki StudentProfile/GuardianRelationship/Enrollment; Attendance dan Assessment masing-masing memiliki transaksi domainnya.
- Import/Export adalah orchestration domain; record master tetap dimiliki domain target/sumber.
- Domain ownership matrix berstatus Draft, bukan persetujuan final. OWN-01—OWN-10 tetap terbuka untuk validasi.
- `docs/03-database/README.md` dan Blueprint Catalog ditautkan ke artefak baru.
- Langkah berikut: review matrix dan lanjutkan logical ERD MVP dengan hanya entitas yang scope/ownership-nya cukup jelas; unresolved decisions tetap ditandai, tidak ditebak.
- Tidak ada kode aplikasi, migration, deployment, atau perubahan server. PR #1 tetap Draft/open/unmerged.


### Checkpoint tambahan — 2026-11-18: Logical ERD MVP v0.1.0

- Dibuat `docs/03-database/LOGICAL-ERD-MVP.md` sebagai draft logical design: relasi utama, kandidat tabel/kolom, PK/unique/FK scope, candidate constraints/index, histori, serta 10 keputusan terbuka.
- Logical ERD mengadopsi PostgreSQL 18 dan shared database/shared schema sebagai baseline; semua unit-scoped FK dirancang membawa tenant_id + unit_id.
- Profil siswa dan wali sementara unit-scoped; employee profile tenant-scoped dengan employee placement per unit; tidak ada asumsi identity resolution lintas tenant.
- Attendance memakai session context manual berbasis tanggal dan class group sebagai kandidat minimum MVP, bukan timetable engine.
- Role scope dirinci platform/tenant/unit dengan CHECK/composite-FK candidate; perlu PoC constraint dan authorization.
- Diagram konseptual diperbarui agar tidak mengaitkan EmployeeProfile ke User secara otomatis dan menampilkan enrollment, placement, attendance session, dan assessment.
- Database README dan Blueprint Catalog ditautkan ke logical ERD.
- Ditemukan dan diperbaiki literal "\
" yang sebelumnya tampil di beberapa checklist/katalog sebagai teks, bukan line break.
- Status: logical ERD masih Draft, belum direview/diterima; acceptance criteria belum dicentang. Belum ada SQL migration, kode aplikasi, atau deployment.
- Langkah berikut: review logical ERD terhadap process specs; lanjutkan data dictionary per entitas/atribut setelah ownership dan keputusan terbuka divalidasi. Khusus OWN-01—OWN-10 dan LERD-01—LERD-10 tidak dianggap selesai.
- PR #1 tetap Draft/open/unmerged.


### Checkpoint tambahan — 2026-11-18: Data Dictionary MVP v0.1.0

- Dibuat `docs/03-database/DATA-DICTIONARY-MVP.md` sebagai kamus rinci untuk entitas pada Logical ERD MVP.
- Memuat kandidat tipe PostgreSQL, nullability, definisi, klasifikasi PUB/INT/CONF/PII/SENS/SYS, validasi, scope, lifecycle/historisasi, candidate constraints/index, dan 15 pertanyaan terbuka.
- Data siswa, wali, presensi, nilai, dokumen verifikasi, dan credential ditandai sensitif sesuai kebutuhan minimisasi; sejumlah field berisiko tinggi sengaja tidak dimasukkan (mis. NIK siswa, data kesehatan, rekening/gaji) tanpa requirement dan approval.
- `DATA-DICTIONARY-BASELINE.md` dipertahankan sebagai inventaris ringkas dan diarahkan ke kamus rinci; README, Blueprint Catalog, dan DATA-INTEGRITY diperbarui.
- Status kamus tetap Draft; tipe dan atribut belum disahkan. Tidak ada migration SQL, kode aplikasi, atau deployment yang dibuat.
- Langkah berikut: lakukan reconciliation antara Logical ERD, kamus, process specs, dan ownership matrix; kemudian review domain/privacy/security dan siapkan test matrix constraint positif/negatif/concurrency. Jangan melanjutkan ke migration sebelum review dan gate PoC/approval.
- PR #1 tetap Draft/open/unmerged.


---

### Session checkpoint — 2026-11-18 (audit konsistensi logical design MVP)
- Fokus: merekonsiliasi MVP Scope, spesifikasi proses organisasi/siswa, akademik/presensi/asesmen, bagian minimum HR, Domain Ownership Matrix, Logical ERD MVP, Data Dictionary MVP, dan Data Integrity.
- Branch: `feature/phase-0-requirements-blueprint`.
- Dokumen baru: `docs/03-database/LOGICAL-DESIGN-CONSISTENCY-AUDIT.md` (AUD-LD-001 v0.1.0).
- Hasil audit: 11 temuan — 4 High, 6 Medium, 1 Low. Isu High: histori penempatan siswa ke rombel belum dimodelkan; sesi presensi belum memiliki roster/teaching context historis; model assessment belum menutup status/lifecycle hasil; invariant kelas-periode-enrollment-subject belum dirancang sebagai constraint/test yang cukup; approval koreksi presensi belum terhubung eksplisit ke revision yang diterapkan.
- Isu Medium: guardian identity/access; effective dating HR/Academic; polymorphic file/audit/import references; konsistensi actor audit; pemisahan MVP versus roadmap. Satu temuan Low terkait reconciliation istilah/field/nullability.
- Konsistensi yang baik: tenant versus unit, foundation versus independent provider, global User versus profil siswa/pegawai, separation Identity/HR/Academic/Student/Attendance/Assessment, entitlement versus authorization, serta minimisasi field sensitif.
- `docs/03-database/README.md` dan `docs/01-blueprint/BLUEPRINT-CATALOG.md` diperbarui dengan tautan dan status audit.
- Semua temuan masih Open. Audit tidak mengambil keputusan tentang owner placement, model session, approval, assessment attempt, guardian access, atau retensi; keputusan OWN-01—10 dan DD-01—15 tetap terbuka.
- Tidak ada kode aplikasi, migration, physical schema, deployment, server, SQLRadius, atau MikroTik yang diubah. PR #1 tetap Draft/open/unmerged.
- Next action: putuskan batas MVP dan kontrak domain untuk AUD-LD-01—05; setelah disetujui, revisi Logical ERD dan Data Dictionary lalu buat traceability/test matrix. Jangan membuat migration sebelum domain/privacy/security review dan gate PoC lulus.
- Hal yang tidak boleh dilakukan: jangan merge PR #1; jangan implementasikan PPDB, HRIS lanjutan, timetable engine, LMS, rapor formal, finance, atau transfer lintas tenant; jangan menganggap audit sebagai approval schema.


---

### Session checkpoint — 2026-11-18 (remediation logical design audit v0.2.0)
- User meminta perbaikan atas audit konsistensi logical design.
- Branch: feature/phase-0-requirements-blueprint.
- Logical ERD diperbarui ke proposal v0.2.0: StudentClassPlacement effective-dated; class_group_id pada enrollment deprecated; attendance session participant snapshot; assessment participant snapshot; result_status terpisah dari score_value; scoring rule version/snapshot; attendance record revisions; correction approval/apply terpisah; effective dating HR/Academic; actor contract; file authorization; MVP boundary dan LD-01—LD-16 test matrix.
- Data Dictionary diperbarui ke proposal v0.2.0 dengan field candidate, nullability, klasifikasi, validasi, dan histori yang sesuai.
- Data Integrity ditambah invariant akademik, enforcement matrix, concurrency/negative test expectations, serta file/audit access controls.
- Domain Ownership Matrix menambahkan proposal Student sebagai candidate owner StudentClassPlacement, dengan Academic tetap owner ClassGroup; keputusan owner final menunggu persetujuan.
- Spesifikasi proses akademik/presensi/asesmen menambahkan batas MVP/post-MVP dan traceability awal. Tidak ada timetable engine, LMS, rapor formal, remedial/retake, biometric/GPS, atau portal wali yang dimasukkan sebagai MVP.
- Audit AUD-LD-001 diperbarui ke v0.2.0. 10 temuan memiliki proposal remediation dokumenter; AUD-LD-06 (guardian access) tetap terbuka untuk keputusan product/privacy. Semua temuan masih menunggu acceptance/PoC; "draft addressed" bukan closed.
- README database dan Blueprint Catalog diperbarui.
- Tidak ada kode aplikasi, migration, physical schema, database/server, deployment, SQLRadius, atau MikroTik yang diubah.
- PR #1 tetap Draft/open/unmerged; jangan merge tanpa instruksi eksplisit.
- Next: review proposal bersama Product Owner/domain owners, terutama ownership StudentClassPlacement, session granularity/teaching assignment, score scale/status, correction approval policy; kemudian privacy/security review dan PoC PostgreSQL 18. Jangan membuat migration sebelum gate lulus.


---

### Session checkpoint — 2026-11-18 (persiapan PoC PostgreSQL 18)

- Fokus: menyiapkan PoC desain database yang dapat dijalankan pada database disposable terpisah; belum mengeksekusi DDL pada server.
- Branch: \`feature/phase-0-requirements-blueprint\`.
- Artefak baru:
  - \`docs/03-database/poc/README.md\`: batas keselamatan, pembuatan database/role khusus, instruksi eksekusi, evidence, exit criteria, dan keterbatasan.
  - \`docs/03-database/poc/001-schema.sql\`: subset skema uji untuk tenant/unit composite FK, academic year/class/enrollment, effective-dated placement dengan exclusion constraint \`btree_gist\`, attendance/assessment participant snapshots, score-state CHECK, correction/revision linkage, dan audit actor CHECK.
  - \`docs/03-database/poc/002-tests.sql\`: fixture sintetis dan smoke/negative tests untuk cross-scope FK, overlap placement, class/date mismatch pada snapshot, nilai nol, invalid score state, correction idempotency key, dan audit actor.
- \`docs/03-database/README.md\` ditautkan ke artefak PoC.
- Safety boundary: hanya database disposable \`sinau_design_poc\` dengan role terpisah \`sinau_poc\`; dilarang menggunakan database \`sinau\`, role \`sinau_app\`, database SQLRadius, atau migration aplikasi.
- Status eksekusi: BELUM DIJALANKAN. Lingkungan percakapan tidak memiliki PostgreSQL client/server untuk menjalankan atau memverifikasi SQL; file telah disimpan ke branch, tetapi syntax/runtime dan hasil constraint belum dibuktikan. Pengguna perlu menjalankan instruksi README pada server uji dan mengirim output yang sudah disensor.
- Keterbatasan yang diketahui dan dicatat dalam panduan: PoC belum membuktikan RLS/authorization boundary, concurrency temporal secara otomatis, max_score enforcement, immutable snapshot terhadap perubahan placement berikutnya, maupun atomic correction approve/apply. AUD-LD-06 guardian access tetap terbuka. Temuan audit belum ditutup.
- Tidak ada koneksi atau perubahan pada server SINAU, database \`sinau\`, aplikasi, migration produksi, SQLRadius, atau MikroTik.
- PR #1 tetap Draft/open/unmerged; jangan merge tanpa instruksi eksplisit.
- Next: jalankan hanya pada database disposable sesuai README; kumpulkan versi PostgreSQL, extension version, exit code, output tests, dan hasil dua-session concurrency. Setelah hasil ada, perbaiki SQL/strategi yang gagal, lanjutkan PoC RLS dan transaksi correction, kemudian review privacy/security dan minta acceptance logical design.


---

### Session checkpoint — 2026-11-18 (PoC schema created; test script syntax fix)
- Server PoC environment: Debian 13.7, PostgreSQL 18.7. Dedicated role `sinau_poc` and database `sinau_design_poc` were created and verified; TCP password authentication succeeded.
- User downloaded `001-schema.sql` and `002-tests.sql` into `~/sinau-poc`.
- `001-schema.sql` executed successfully with `ON_ERROR_STOP=1` and reached COMMIT. User verified 15 public tables exist.
- User verified temporal triggers: BEFORE INSERT/UPDATE on `attendance_session_participants` and `assessment_participants`.
- First execution of `002-tests.sql` stopped at line 35 with syntax error `DO $`; inspection of repository source found two malformed anonymous-block opening delimiters (`DO $` rather than `DO $$`).
- Fixed both delimiters in `docs/03-database/poc/002-tests.sql` on branch `feature/phase-0-requirements-blueprint`; commit: `fbc5eec801e325638f5cb11e509421ea95add455`.
- The server's local `~/sinau-poc/002-tests.sql` is still the previously downloaded broken copy; it must be re-downloaded from the branch before rerunning tests. The failed test transaction did not commit; schema created by `001-schema.sql` remains committed.
- PoC test suite has NOT passed yet. Do not claim database design acceptance. Known PoC limitations and AUD-LD-06 remain as documented above.
- Safety boundary unchanged: only `sinau_design_poc` / `sinau_poc`; do not touch `sinau`, `sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.
- Next: re-download corrected `002-tests.sql`, inspect corrected delimiters, rerun with `ON_ERROR_STOP=1`, capture complete output/exit code, then inspect any runtime failures before making further changes.


### Correction checkpoint — 2026-11-18 (verified PostgreSQL PoC test delimiter fix)
- User reran the test file and confirmed the downloaded copy still contained two malformed `DO $` delimiters at lines 31 and 92; test execution therefore stopped at line 35. No test assertions completed.
- Root cause: the earlier attempted repository update did not change the file content; its blob SHA remained unchanged. The earlier checkpoint claim that the delimiters were fixed was premature and is superseded by this verified correction.
- Replaced both exact lines with `DO $$` and fetched the file again to verify all six anonymous blocks now open with `DO $$`.
- Corrected file commit: `3ec1e9c431fa0992026f56785e802a45b605bbf2`; verified blob SHA: `40eccc8b17c7638eaf4d4d6fb5fa220b4531562f`.
- Next: download `002-tests.sql` from commit `3ec1e9c431fa0992026f56785e802a45b605bbf2`, verify `grep -n '^DO '` shows six `DO $$` lines, then rerun the test suite. No assertion has passed yet.
- Safety boundary unchanged: only `sinau_design_poc` / `sinau_poc`; no changes to `sinau`, `sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.


### Correction checkpoint — 2026-11-18 (remaining PoC test block terminators)
- User downloaded the previously corrected test script and verified all six `DO $$` openings. Execution then stopped at line 47 with a syntax error near `BEGIN`.
- Reinspection found two remaining malformed anonymous-block terminators, `END $;`, at lines 40 and 101. These left the dollar-quoted blocks unterminated.
- Replaced both with `END $$;` in `docs/03-database/poc/002-tests.sql`.
- Corrected commit: `8bedabb8dd9e46228a21313aff7b017212e12ab5`; verified blob SHA: `c36da2b8298a38eaaaa1bd6a784879701c9fcfe4`.
- Re-fetched repository file and verified all six `DO $$` openings have matching `END $$;` terminators (lines 40, 52, 71, 101, 113, 125). This verifies textual delimiter pairing only; PostgreSQL execution and all assertions remain unverified.
- Next: download `002-tests.sql` from commit `8bedabb8dd9e46228a21313aff7b017212e12ab5`, confirm six openings and six terminators, then rerun on `sinau_design_poc` with `ON_ERROR_STOP=1`. Review any runtime/constraint errors before claiming PoC success.
- Failed test transactions have not committed; the previously committed schema remains. Use only `sinau_design_poc` / `sinau_poc`; do not touch `sinau`, `sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.


### PoC execution checkpoint — 2026-11-18 (schema and smoke/negative tests passed)
- User confirmed `001-schema.sql` completed successfully on PostgreSQL 18.7 in the dedicated disposable database `sinau_design_poc`; 15 public tables and temporal participant triggers were previously verified.
- User downloaded the corrected `002-tests.sql` from commit `8bedabb8dd9e46228a21313aff7b017212e12ab5`. Six `DO $$` openings and six `END $$;` terminators were verified on the server.
- User executed `psql -h 127.0.0.1 -U sinau_poc -d sinau_design_poc -X -v ON_ERROR_STOP=1 -f 002-tests.sql`; script reached final `ROLLBACK` with no errors.
- Confirmed PASS notices: cross-tenant/unit composite-FK rejection; overlapping student class placement rejection; mismatched attendance participant class snapshot rejection; duplicate attendance-correction idempotency key rejection; absent score with numeric value rejection; system audit actor without service identity rejection.
- The test script intentionally rolls back fixtures; this is expected. Schema remains committed from `001-schema.sql`. This confirms only the tested constraints/triggers and does not constitute full logical-design acceptance or production migration authorization.
- Remaining PoC/design gates: inspect actual constraint/index definitions; test RLS and tenant/unit authorization; test temporal concurrency using two sessions; assess snapshot immutability; implement/test max-score enforcement; test correction approval/application atomicity and revision linkage; resolve AUD-LD-06 guardian access; complete LD-01—LD-16 evidence and product/domain/privacy/security reviews.
- Safety boundary unchanged: only disposable `sinau_design_poc` / `sinau_poc`; do not touch application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.


### PoC execution checkpoint — 2026-11-18 (constraint and index inventory)
- User successfully reran the index inventory query on `sinau_design_poc`; PostgreSQL returned 33 indexes.
- Inventory includes primary-key/unique B-tree indexes and one GiST index, `student_placement_no_overlap`, supporting the temporal placement exclusion constraint. Earlier constraint inventory returned 155 catalog rows (including NOT NULL entries); `btree_gist` 1.8 and `plpgsql` 1.0 were confirmed installed.
- Index inventory confirms indexes created by PK/UNIQUE/exclusion constraints. It does not establish that all referencing foreign-key columns or application query patterns have suitable non-unique indexes; PostgreSQL does not automatically create indexes on referencing FK columns. Review query patterns and FK-side indexes before finalizing indexing design; avoid adding indexes without workload justification.
- Next: inspect candidate schema and map FK columns/query patterns, then continue RLS tenant/unit isolation tests. Follow with two-session temporal concurrency and correction transaction/revision tests. Existing limitations (max_score enforcement, snapshot immutability, atomic correction workflow, AUD-LD-06) remain open.
- PoC remains limited to `sinau_design_poc` / `sinau_poc`; no application database `sinau`, `sinau_app`, SQLRadius, or MikroTik changes. PR #1 remains Draft/open/unmerged.


### RLS PoC scripts prepared — 2026-11-18
- Added `docs/03-database/poc/003-rls-setup.sql` (commit `82cc81c5a33c9fad7edc653bb50d762dc495f880`) and `004-rls-tests.sql` (commit `903e41de255189b6d94ee895ad260ce016a87602`).
- Setup is intended to run as PostgreSQL administrator only against `sinau_design_poc`; it creates/reuses non-login role `sinau_rls_test`, inserts deterministic fixtures, enables and forces RLS on tenant-scoped tables, and grants table privileges to the test role.
- Test is intended to run as `sinau_poc`, switches to `sinau_rls_test`, and checks same-unit SELECT/INSERT, cross-unit and cross-tenant SELECT, cross-unit UPDATE, cross-tenant DELETE, and cross-tenant INSERT rejection. Test transaction ends with ROLLBACK.
- Important limitation: `app.tenant_id` and `app.unit_id` are caller-settable custom GUCs in this experiment. Passing tests demonstrate policy filtering only; they do not prove a trusted authentication/context boundary. A membership-validated context setter, pool reset, background-job/export/support paths, and IDOR tests remain required.
- Status: scripts prepared and documented; NOT YET EXECUTED by user. Do not claim RLS tests passed until output is reviewed.
- Safety: run only against `sinau_design_poc`; never touch `sinau`, `sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (status verified; context trust still open)
- User menjalankan pemeriksaan katalog pada database khusus `sinau_design_poc` melalui `sudo -u postgres psql`, kemudian `SET ROLE sinau_poc`. Identitas hasil: database `sinau_design_poc`, session role `postgres`, effective role `sinau_poc`, PostgreSQL `18.7`.
- Verifikasi memakai `pg_class.relrowsecurity` dan `pg_class.relforcerowsecurity` (bukan `pg_tables.forcerowsecurity`) menunjukkan 14 tabel berstatus RLS enabled + FORCE: `academic_years`, `assessment_definitions`, `assessment_participants`, `attendance_corrections`, `attendance_record_revisions`, `attendance_records`, `attendance_session_participants`, `attendance_sessions`, `audit_events`, `class_groups`, `education_units`, `student_class_placements`, `student_enrollments`, dan `student_scores`.
- `tenants` adalah satu-satunya tabel tanpa `tenant_id` pada schema PoC; DDL 001 mendefinisikannya sebagai registry global, dan setup 003 sengaja melewatinya serta tidak memberi grant tabel kepada `sinau_rls_test`. Akses efektif ke tabel global ini tetap perlu diverifikasi lewat privilege audit.
- Katalog `pg_policies` memperlihatkan 14 policy `sinau_rls_isolation`, semuanya untuk role `sinau_rls_test`, dengan command `ALL` dan predicate `USING`/ `WITH CHECK` sesuai tenant/unit context. Setup 003 memberi membership `sinau_rls_test` kepada `sinau_poc`; role inheritance/membership dan privilege efektif masih perlu diperiksa.
- Script 003 memang mengaktifkan dan memaksa RLS dalam loop. Query laporan penutup script memakai kolom `forcerowsecurity` dari `pg_tables`, padahal pemeriksaan katalog yang benar adalah `pg_class.relforcerowsecurity`; kegagalan laporan penutup tidak membatalkan DDL sebelumnya. Status aktual telah diverifikasi langsung dari `pg_class`.
- Belum ada klaim trusted context. Policy mempercayai custom GUC `app.tenant_id` dan `app.unit_id`; script 004 sendiri menyatakan pengujian policy bukan bukti pencegahan pemalsuan konteks dan mendemonstrasikan pergantian unit context. Trusted-context design dan negative test eksplisit untuk pemalsuan tenant/unit masih terbuka.
- Next: audit dinamis semua relasi public yang memiliki kolom `tenant_id`/ `unit_id`, cocokkan jumlahnya dengan RLS + FORCE + policy untuk `sinau_rls_test`, periksa membership/inherit/BYPASSRLS dan akses `tenants`. Setelah hasil diterima, uji pemalsuan konteks hanya dalam transaksi rollback di `sinau_design_poc`, lalu tetapkan pola konteks terverifikasi sebelum perubahan setup.
- Safety boundary tetap: hanya `sinau_design_poc` dan role PoC terkait. Jangan menyentuh database aplikasi `sinau`, role `sinau_app`, SQLRadius, atau MikroTik. PR #1 tetap Draft/open/unmerged; jangan merge tanpa instruksi eksplisit.

### RLS PoC checkpoint — 2026-11-18 (tenant-scoped inventory and role audit)
- User menyelesaikan audit katalog pada `sinau_design_poc` sebagai administrator PostgreSQL.
- Inventaris public schema: 15 tabel. Tepat 14 tabel memiliki kolom `tenant_id`; semuanya memiliki `ENABLE ROW LEVEL SECURITY`, `FORCE ROW LEVEL SECURITY`, satu policy `sinau_rls_isolation` untuk `sinau_rls_test`, serta privilege SELECT/INSERT terdeteksi untuk role pengujian.
- `education_units` hanya memiliki `tenant_id` (tidak memiliki `unit_id`), sehingga cakupan tenant-only policy sesuai struktur. `audit_events` memiliki tenant dan unit nullable sesuai predicate policy khusus audit. Tidak ditemukan tabel tenant-scoped tanpa policy.
- `tenants` adalah global registry tanpa `tenant_id`, tanpa RLS/policy, dan bukan bagian dari grant role test. `sinau_rls_test` tidak memiliki SELECT/INSERT di tabel ini; `sinau_poc` memiliki SELECT/INSERT.
- Role audit: `sinau_poc` LOGIN, bukan SUPERUSER, `rolinherit=true`, `rolbypassrls=false`; `sinau_rls_test` NOLOGIN, bukan SUPERUSER, `rolinherit=true`, `rolbypassrls=false`. `sinau_poc` adalah anggota `sinau_rls_test` dan mewarisi privilege (USAGE=true).
- Risiko desain PoC: `sinau_poc` memiliki seluruh tabel. FORCE RLS membuat owner tunduk pada policy saat query biasa, tetapi tidak menjadikan owner cocok sebagai runtime role tidak tepercaya karena owner tetap mempunyai kewenangan DDL/administrasi objek dan dapat mengubah policy/menonaktifkan RLS. Desain produksi perlu memisahkan NOLOGIN schema/table owner dari runtime role non-owner berprivilege minimum.
- Berikutnya: lakukan demonstrasi terbatas bahwa role runtime uji dapat mengganti GUC tenant/unit dan membaca fixture tenant lain; semua operasi read-only dalam transaksi yang diakhiri ROLLBACK. Unit context switching sebelumnya sudah diuji pada 004 (tidak perlu mengulang tes PASS yang sama); fokus tambahan adalah perpindahan tenant dan pembuktian pasangan tenant/unit. Setelah itu rancang trusted context yang mengikat identitas ke membership terverifikasi, bukan menerima tenant/unit bebas dari caller.
- Safety: hanya `sinau_design_poc` dan role PoC. Tidak menyentuh database aplikasi `sinau`, role `sinau_app`, SQLRadius, atau MikroTik. PR #1 tetap Draft/open/unmerged.
