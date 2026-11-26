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

### RLS PoC checkpoint — 2026-11-18 (tenant + unit context spoofing confirmed)
- User menjalankan demonstrasi spoofing dengan koneksi awal administrator lalu `SET SESSION AUTHORIZATION sinau_poc`, transaksi, dan `SET LOCAL ROLE sinau_rls_test`. Effective role pada query RLS adalah `sinau_rls_test`; session authorization adalah `sinau_poc`.
- Konteks asli tenant A / unit A1 menghasilkan 1 baris dari `academic_years`.
- Spoof tenant B saja, sambil mempertahankan unit A1, menghasilkan 0 baris. Ini konsisten dengan policy yang mensyaratkan pasangan tenant dan unit.
- Setelah `app.unit_id` diubah ke unit B1 sementara tenant context tetap tenant B, query menghasilkan 1 baris. Ini membuktikan caller role dapat mengganti kedua custom GUC dan membaca data milik tenant B jika ia memasok pasangan konteks tenant/unit yang valid.
- Transaksi berakhir `ROLLBACK`; pengujian hanya SELECT dan perubahan GUC lokal. Tidak ada perubahan data fixture.
- Kesimpulan keamanan: RLS predicates bekerja terhadap nilai context yang diberikan, tetapi nilai GUC tidak autentik/tepercaya. Kontrol ini belum mencegah cross-tenant access dari caller yang dapat menjalankan SQL sebagai role runtime/test.
- Rancangan kandidat untuk PoC lanjutan: backend memvalidasi principal dan tenant/unit membership, lalu menandatangani payload konteks berumur pendek; PostgreSQL memverifikasi tanda tangan dengan fungsi terkontrol yang menggunakan secret di schema/table terlindungi (atau verifikasi signature asimetris bila tersedia dan layak). RLS harus mengambil tenant/unit hanya dari payload yang lolos verifikasi; GUC mentah tetap dianggap untrusted. Payload minimal perlu mengikat actor, tenant, unit, audience, issued-at/expiry, dan nonce/session binding; token wajib scope transaksi dan dibersihkan oleh transaction boundary.
- Jangan menganggap `SECURITY DEFINER` atau setter GUC biasa cukup. Fungsi verifikasi harus owner NOLOGIN terpisah, search_path aman, EXECUTE minimum, tanpa akses runtime ke secret; invalid/missing/expired signature menghasilkan no-row (fail closed). Uji pool reset, role inheritance, dan pencabutan membership kemudian.
- Berikutnya: pemeriksaan read-only ketersediaan `pgcrypto` pada instance PoC, schema privilege, dan parameter role untuk memilih metode penandatanganan/verifikasi. Belum ada extension, schema, function, secret, policy, atau table yang dibuat/diubah.
- Safety: hanya `sinau_design_poc` / role PoC. Tidak menyentuh database aplikasi `sinau`, role `sinau_app`, SQLRadius, atau MikroTik. PR #1 tetap Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (pgcrypto and privilege preflight)
- User memeriksa kesiapan kriptografi dalam `sinau_design_poc` tanpa perubahan database.
- PostgreSQL melaporkan `pgcrypto` tersedia pada versi default 1.4 tetapi `installed_version` kosong; extension belum terpasang, sehingga tidak ada fungsi `hmac`/`digest` di database. `btree_gist` 1.8 dan `plpgsql` 1.0 terpasang.
- Schema `public` dimiliki `pg_database_owner`; ACL yang tampil memberi PUBLIC USAGE, membership test USAGE, dan tidak memberi PUBLIC CREATE. `sinau_poc` memiliki USAGE + CREATE (hak efektif database owner); role test hanya USAGE dan tidak CREATE.
- Role `sinau_poc`: LOGIN, bukan superuser, bukan BYPASSRLS, bukan CREATEROLE/CREATEDB/REPLICATION; role test NOLOGIN, bukan superuser/BYPASSRLS. Koneksi menggunakan `search_path="$user", public`.
- Tidak ada objek hmac/digest karena extension belum dipasang. Belum dibuat schema cryptography, role owner, function, key, token, atau policy.
- Rancangan ditinjau terhadap dokumentasi resmi PostgreSQL 18: `pgcrypto` menyediakan HMAC-SHA-256; extension ditandai trusted, tetapi fungsi cryptographic-nya berjalan di server database dan dokumentasi meminta pengguna mempercayai system/database administrator. Ini berarti skema HMAC dalam DB melindungi runtime role dari pemalsuan GUC, bukan dari superuser/DBA atau kompromi host. Secret HMAC tidak boleh bisa dibaca runtime; verifier mesti diproteksi dan dipanggil oleh RLS dengan fail-closed semantics. Search-path hardening dan schema instalasi yang tidak dapat ditulis role tidak tepercaya wajib.
- Next: read-only preflight `pg_available_extension_versions.trusted/superuser/relocatable`, database CREATE privilege, serta nama/ACL schema kandidat. Setelah dikonfirmasi, minta pengguna memasang `pgcrypto` hanya pada database PoC dalam schema khusus yang tidak writable oleh runtime; jangan memasang di `public`.
- Safety: hanya `sinau_design_poc`; jangan menyentuh database aplikasi `sinau`, role `sinau_app`, SQLRadius, atau MikroTik. PR #1 tetap Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (pgcrypto installation preflight completed)
- User checked `pg_available_extension_versions`: pgcrypto 1.3 and 1.4 are available; both report `superuser=true`, `trusted=true`, and `relocatable=true`. No version installed. PostgreSQL documentation explains that trusted extensions may be installed by a non-superuser with database CREATE privilege even when control metadata marks superuser=true; the installation runs its script as bootstrap superuser. The PoC database owner `sinau_poc` has database CREATE, while `sinau_rls_test` does not.
- Database `sinau_design_poc` is owned by `sinau_poc`. No protected crypto/private schema exists yet.
- Decision for next controlled mutation: create a dedicated NOLOGIN, non-superuser, non-BYPASSRLS role `sinau_context_owner`; create `sinau_crypto` owned by PostgreSQL administrator and `sinau_private` owned by `sinau_context_owner`; install pgcrypto 1.4 only into `sinau_crypto`; revoke PUBLIC function execution and grant only the minimum required to `sinau_context_owner`. Runtime/test roles must have no schema CREATE and no direct secret read. Use schema-qualified crypto calls and hardened SECURITY DEFINER verifier in later steps.
- PostgreSQL documentation warning is followed: trusted extension installation schemas must not be writable by untrusted users. This schema is not public and will be owned by the administrator; runtime/test roles receive no CREATE/USAGE unless needed for the verifier call.
- This is a PoC setup only, not a production key-management endorsement. HMAC key will need a secure backend secret-manager source and a protected verifier copy in PostgreSQL; DBA/superuser and host administrator remain trusted.
- No database objects changed in this checkpoint.
- Safety: only `sinau_design_poc`; do not touch application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik. PR #1 stays Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (isolated pgcrypto installation succeeded)
- User menjalankan setup dalam satu transaksi pada database `sinau_design_poc`; transaksi COMMIT berhasil.
- Role `sinau_context_owner` berhasil dibuat: NOLOGIN, NOSUPERUSER, NOCREATEDB, NOCREATEROLE, NOINHERIT, NOREPLICATION, NOBYPASSRLS.
- Schema `sinau_crypto` dibuat dengan owner `postgres`; schema `sinau_private` dibuat dengan owner `sinau_context_owner`.
- Extension `pgcrypto` versi 1.4 terpasang hanya di `sinau_design_poc`, schema `sinau_crypto`; owner extension dan owner schema adalah `postgres`.
- Fungsi `sinau_crypto.hmac(text,text,text)` dan `sinau_crypto.hmac(bytea,bytea,text)` dimiliki postgres. EXECUTE diberikan kepada `sinau_context_owner`; pemeriksaan privilege menyatakan role tersebut dapat execute dan `sinau_rls_test` tidak dapat execute. Schema crypto USAGE hanya diberikan kepada context owner selain owner postgres.
- Schema private hanya memberi owner `sinau_context_owner` hak USAGE/CREATE; PUBLIC, `sinau_poc`, dan `sinau_rls_test` tidak diberi akses. Belum ada secret atau table/function verifier.
- Pemeriksaan role mengonfirmasi `sinau_context_owner` NOLOGIN, bukan superuser, bukan CREATEDB/CREATEROLE, dan bukan BYPASSRLS.
- Berikutnya: jalankan HMAC-SHA256 bytea primitive test memakai RFC 4231 Test Case 1 (key 0b x 20 bytes, data "Hi There") sebagai `sinau_context_owner`; cocokkan hasil dengan digest acuan. Ini hanya tes fungsi tanpa secret/token permanen dan tanpa perubahan database. Setelah tes kriptografi lulus, baru rancang payload canonical dan key lifecycle; belum membuat verifier atau mengubah RLS policies.
- Catatan trust boundary: PostgreSQL `pgcrypto` menjalankan operasi di server database; host administrator dan database superuser tetap tepercaya. Signed context mengurangi pemalsuan oleh runtime role yang tidak dapat membaca key, bukan kompromi DBA/host.
- Safety: hanya `sinau_design_poc` / role PoC. Jangan sentuh database aplikasi `sinau`, role `sinau_app`, SQLRadius, atau MikroTik. PR #1 tetap Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (HMAC RFC 4231 test invocation correction)
- User executed the initial HMAC-SHA256 test vector as `sinau_context_owner`; the resulting MAC did not match RFC 4231 Case 1. Transaction ended with ROLLBACK and no persistent data changes.
- Inspection against the official PostgreSQL 18 pgcrypto documentation found the test SQL supplied arguments in the wrong order. The documented signature is `hmac(data bytea, key bytea, type text)`; the previous test passed key as data and data as key.
- This mismatch is a test-call defect, not evidence of a broken pgcrypto installation. The correct rerun must use `hmac(convert_to('Hi There','UTF8'), decode(repeat('0b',20),'hex'), 'sha256')`.
- Runtime role restrictions were independently confirmed: `sinau_rls_test` has no USAGE on `sinau_crypto` and no EXECUTE on the bytea HMAC overload.
- Status: RFC vector test is NOT YET PASSED; do not create the secret store, signed payload, verifier, or RLS policy changes until the corrected vector returns the expected digest.
- Safety boundary unchanged: only `sinau_design_poc`; no application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik changes. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (HMAC-SHA256 primitive verified)
- User reran RFC 4231 HMAC-SHA256 Test Case 1 with the documented PostgreSQL argument order `hmac(data, key, type)`.
- Actual output exactly matched expected MAC `b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7`; `test_pass=true`. Test ran as `sinau_context_owner` and ended with ROLLBACK.
- Access boundary confirmed again: `sinau_rls_test` has no USAGE on `sinau_crypto` and no EXECUTE on `sinau_crypto.hmac(bytea,bytea,text)`.
- HMAC primitive and installation can now be treated as verified. This does NOT yet validate secret lifecycle, external signer compatibility, token canonicalization, expiry, transaction binding, replay resistance, verifier safety, or RLS integration.
- PostgreSQL 18 documentation confirms `pg_current_xact_id()` returns (and if needed assigns) the top-level transaction ID. Candidate design may bind a signed context to this value, but implementation must ensure the application obtains it only inside the active transaction and verifier compares it to the current top-level transaction. This is a proposed anti-replay scope, not yet tested.
- Next: document the exact token contract and threat boundary before any key creation. Candidate claims: version, audience/database, key id, actor UUID, tenant UUID, unit UUID (nullable only for tenant-scope operations), transaction ID, issued-at, expiry, random nonce. Use an unambiguous canonical serialization or a carefully defined JSON canonical form; reject unknown versions, malformed encodings, duplicate/unknown claims, mismatched audience, expired/future-issued tokens, wrong transaction ID, wrong tenant/unit shape, and unknown/revoked key IDs. Do not accept tenant/unit directly from caller-supplied GUCs.
- Secret/key separation remains a design issue: HMAC requires the same key at the backend signer and database verifier. The test key must be synthetic, not a production credential, delivered out-of-band with restrictive OS permissions, and never printed in logs/chat/SQL history. For production, evaluate an asymmetric signing approach or dedicated identity/context broker if eliminating shared verifier secret from the database is required.
- No key store, secret, token, verifier function, or policy changes have been created. No persistent database mutation occurred in this test.
- Safety: only `sinau_design_poc`; never touch application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (transaction binding preflight)
- User ran the transaction binding preflight on `sinau_design_poc`.
- Both `sinau_rls_test` and `sinau_context_owner` can execute `pg_catalog.pg_current_xact_id()`. This is a public PostgreSQL system function; it does not grant access to context-owner role or secrets.
- Neither `sinau_poc` nor `sinau_rls_test` is a member of `sinau_context_owner`.
- Neither `sinau_poc` nor `sinau_rls_test` has USAGE or CREATE on `sinau_private`.
- One transaction returned XID 799 before a savepoint, after savepoint, and after rollback to that savepoint. This verifies the same top-level transaction ID is returned across that subtransaction boundary. It does not yet test distinct top-level transactions.
- PostgreSQL 18 docs confirm `pg_current_xact_id()` assigns an XID if none is assigned, and `pg_current_xact_id_if_assigned()` returns NULL rather than assigning one; use the latter inside the verifier to fail closed without allocating an XID when the caller has not established a transaction binding. The signer flow would have to call `pg_current_xact_id()` inside an explicit transaction, sign that value, set the signed token transaction-locally, and keep all scoped queries on the same connection/transaction. This intentionally allocates an XID for read-only scoped transactions; measure overhead before adopting.
- Next: verify two separate top-level transactions produce distinct XIDs using a psql script. After that, draft the token contract and verifier threat model before creating any secret/key table or function. A nonce is for uniqueness/audit; transaction binding prevents replay in another transaction. Reuse of the same valid token within its own transaction is expected so several scoped SQL statements can execute under one authorization context.
- No persistent database changes in this check.
- Safety: only `sinau_design_poc`; no application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik changes. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (distinct top-level transaction binding verified)
- User completed the separate-transaction test on `sinau_design_poc`.
- First explicit transaction allocated XID `800` and COMMITted; second explicit transaction allocated XID `801` and ROLLBACKed. Comparison returned `different_transaction = true`.
- A fresh transaction queried `pg_current_xact_id_if_assigned()` before any XID allocation and returned NULL, then ROLLBACKed.
- Together with the earlier savepoint check (same top-level XID 799 before/after savepoint and rollback-to-savepoint), the PoC confirms XID is stable inside a top-level transaction, including its subtransactions, and differs across the tested top-level transactions. This supports transaction-bound token scope.
- PostgreSQL 18 official docs distinguish `pg_current_xact_id()` (allocates an XID if missing) from `pg_current_xact_id_if_assigned()` (returns NULL if none exists and avoids unnecessary XID consumption); verifier should use the latter, while the backend's explicit transaction-binding step deliberately allocates the XID before signing.
- Token contract proposal (not yet implemented): strict canonical ASCII payload with fixed field order and separators, avoiding JSON serialization ambiguity. Fields: `v1|audience|kid|actor_uuid|tenant_uuid|unit_uuid-or-dash|xid8|iat_epoch|exp_epoch|nonce_hex`; MAC is HMAC-SHA256 over the exact UTF-8 payload and encoded as 64 lowercase hex characters in a separate final field. Reject malformed/noncanonical values, unknown version/audience/key id, revoked key, future iat beyond small skew, expired token, excessive lifetime, missing current XID, and transaction mismatch. Actor/tenant/unit membership is validated by the backend before signing; database verifier authenticates integrity, audience, time and transaction scope but does not independently prove application membership.
- Use NULL unit only for explicitly tenant-scoped operations, not as wildcard for unit-scoped tables. Unit-scoped RLS must fail closed if unit is absent.
- A nonce provides uniqueness/correlation, not replay prevention by itself. Transaction binding prevents replay in a different top-level transaction; the same signed context may be reused for several queries within its authorized transaction.
- Secret distribution remains an explicit PoC design issue. HMAC requires a shared secret between backend signer and database verifier; runtime SQL role must not read the database copy. For production, compare this with asymmetric signing or a dedicated broker. Do not place secrets in shell history, terminal output, Git, PROJECT-PROGRESS, chat, or SQL literals.
- Next: approve the exact token contract and the controlled secret-provisioning method before creating key storage or verifier objects. Prefer a synthetic, disposable PoC key injected through a protected local file/secret channel with 0600 permissions; do not reuse a production secret. Then build a narrow SECURITY DEFINER verifier under `sinau_context_owner`, hardened search_path, schema-qualified references, revoked PUBLIC EXECUTE, and explicit grant to the RLS test role only. Use `pg_current_xact_id_if_assigned()` in the verifier to fail closed without allocating XID.
- No persistent objects or policy changes were made in this checkpoint; only XID allocation occurred in the explicit test transaction which committed (XID 800).
- Safety: only `sinau_design_poc`; no application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik changes. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (top-level transaction XID separation confirmed)
- User executed the distinct-transaction check. First explicit transaction allocated XID `800` and COMMITted; second explicit transaction allocated XID `801` and ROLLBACKed. SQL comparison returned `different_transaction = t`.
- In a fresh transaction, `pg_current_xact_id_if_assigned()` returned NULL before any XID was allocated. That transaction was rolled back.
- Previous savepoint test had returned XID 799 consistently before SAVEPOINT, after SAVEPOINT, and after rollback to SAVEPOINT. This confirms the same top-level XID remains stable through a subtransaction while distinct top-level transactions in this test had distinct XIDs.
- Token contract proposal is now narrowed to a fixed-field ASCII string to avoid cross-language JSON canonicalization ambiguity:
  - Payload: `v1|sinau_design_poc|poc-k1|<actor_uuid>|<tenant_uuid>|<unit_uuid-or->|<xid8-decimal>|<iat-unix-seconds>|<exp-unix-seconds>|<nonce-lowercase-hex>`
  - Token: `<payload>|<mac-lowercase-hex>`; MAC is HMAC-SHA256 over the exact UTF-8 bytes of payload (without final separator or MAC).
  - Fixed fields/order, exactly 10 payload fields plus final MAC; lowercase canonical UUIDs; unit `-` only for explicitly tenant-scoped operations; decimal integers without sign or leading zeros; nonce is 16 random bytes encoded as 32 lowercase hex chars; MAC is 32 bytes encoded as 64 lowercase hex chars.
  - Audience is the target database/environment. Key ID identifies an active key. XID is the top-level transaction ID allocated by backend within the same explicit transaction/connection used for scoped queries.
  - Verifier rejects invalid structure/encoding, unknown version/audience/key, revoked key, bad signature, missing current XID, XID mismatch, iat more than 5 seconds in future, expired token, exp <= iat, and lifetime over 300 seconds. Same token is reusable only within its bound transaction; a nonce is correlation/uniqueness, not a standalone replay defense.
  - For operations on tables requiring unit scope, absence of unit must deny access. Tenant-only scope functions must be separate/explicit rather than treating NULL unit as wildcard.
- Important boundary: the database verifier checks cryptographic integrity, audience, time and transaction binding; backend must independently authenticate actor and verify active actor-tenant-unit membership before signing. The database does not infer that membership merely from a valid HMAC.
- Shared-secret tradeoff remains: HMAC signer and verifier need the same key. Runtime SQL roles must not read the database copy; only backend secret provider and protected verifier may access it. DBA/host admin remain trusted. Consider asymmetric signatures before production if reducing shared-key exposure is required.
- Next step: create only a synthetic disposable PoC HMAC key in a local secret file with restrictive permissions; do not print it, commit it, paste it, or use a production credential. Then securely import it into a private key table accessible only to `sinau_context_owner`, and test an external signer/verifier round trip before changing RLS policies.
- No persistent database objects, key material, functions, or policies were changed in this checkpoint. XID 800 was allocated in a transaction that committed; XID 801 was allocated in a transaction that rolled back.
- Safety: only `sinau_design_poc`; never touch application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (synthetic HMAC key created on application host)
- User generated a fresh 32-byte random PoC HMAC key with OpenSSL on the SINAU host. File: `/home/sinauadmin/.local/share/sinau-poc-secrets/context-hmac-v1.hex`.
- Verified metadata reported permission 0600, owner/group `sinauadmin:sinauadmin`, size 65 bytes (64 lowercase hex characters plus newline). The secret value was not printed or shared.
- Key is explicitly synthetic and for `sinau_design_poc` only. Do not reuse for production or another environment; do not commit it, paste it into chat, put it in shell arguments/history, or log it.
- Next controlled operation: copy it temporarily into `/run` only after verifying `/run` is tmpfs, as owner postgres mode 0600; import via psql client-side `\\copy` so the raw value never appears in SQL source/command-line arguments/output; create a `sinau_private.context_keys` table owned by `sinau_context_owner`; verify only key id and byte length, never key bytes. Remove the staging copy immediately after successful transaction. If `/run` is not tmpfs or the path already exists, stop rather than fall back to persistent staging.
- No database object or secret copy inside PostgreSQL has been created yet. The original secret remains only in the restricted host file.
- Safety: database target remains `sinau_design_poc` only. Do not touch application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik. PR #1 stays Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (synthetic HMAC key imported into protected store)
- User completed the controlled import to `sinau_design_poc`. Source file remained `/home/sinauadmin/.local/share/sinau-poc-secrets/context-hmac-v1.hex`, mode 0600, owned by `sinauadmin`; secret value was not printed or shared.
- `/run` was confirmed as `tmpfs`. A temporary staging file was created for postgres with mode 0600 and removed successfully after import.
- Table `sinau_private.context_keys` was created with owner `sinau_context_owner`. One row exists for key ID `poc-k1`, with `octet_length(secret_bytes)=32`; key material was not displayed.
- Effective privilege results: `sinau_context_owner` can read key store; `sinau_poc` cannot; `sinau_rls_test` cannot. No direct runtime grant was made. Transaction COMMIT succeeded.
- The imported key is synthetic and valid only for this disposable PoC. It is not a production secret. The backend signing process must be separately modelled; the current file is owned by `sinauadmin`, so application runtime cannot be assumed to have safe access. Do not grant broad filesystem/database access merely to make signing convenient.
- Next: preflight `context_keys` table constraints/defaults and exact function owner/schema ACL; then create a narrowly scoped `SECURITY DEFINER` verifier owned by `sinau_context_owner`, with a fixed safe `search_path`, all object references schema-qualified, no dynamic SQL, no secret-returning path, and EXECUTE granted only to `sinau_rls_test` for PoC testing. Verifier must validate strict token structure, key active state, HMAC, audience, timestamps and current top-level XID; use `pg_current_xact_id_if_assigned()` so no XID is allocated by verification. Test with independent signer reading the local key file without revealing it; never use SQL literal containing the key.
- No RLS policies were changed. No application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik was touched. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (key store audit completed)
- User audited `sinau_private.context_keys`: columns are `key_id text NOT NULL` (primary key, constrained to lowercase identifier syntax), `secret_bytes bytea NOT NULL` (CHECK exactly 32 bytes), `created_at timestamptz NOT NULL DEFAULT clock_timestamp()`, `not_before timestamptz NOT NULL DEFAULT clock_timestamp()`, and nullable `revoked_at timestamptz`.
- Table owner is `sinau_context_owner`; ACL contains only owner privileges. Table has no RLS/FORCE RLS, by design as an internal key store whose access is controlled strictly by ownership/ACL.
- Effective SELECT privilege: context owner=true, sinau_poc=false, sinau_rls_test=false.
- `sinau_private.verify_context_token(text)` does not yet exist.
- PostgreSQL 18 SECURITY DEFINER hardening requirements confirmed against official docs: set a fixed safe search_path excluding untrusted writable schemas and put `pg_temp` last; schema-qualify sensitive references; revoke default PUBLIC EXECUTE and grant selectively within the same transaction. The planned function will use `SET search_path = pg_catalog, pg_temp` and schema-qualified references to the key table and HMAC function.
- Next: create the verifier, owned by `sinau_context_owner`, returning at most one row of verified `actor_id, tenant_id, unit_id`. Strict parser will require exactly 11 pipe-delimited fields, canonical lowercase UUIDs, decimal XID and timestamps, fixed audience/version, nonce and MAC hex lengths; validate active key, HMAC-SHA256 (constant 32-byte comparison loop), issue/expiry skew and lifetime, and exact match to `pg_current_xact_id_if_assigned()`. Malformed/invalid token returns zero rows. Grant schema USAGE and function EXECUTE only to `sinau_rls_test` for PoC; no direct access to key table or HMAC function.
- This verifies token integrity, audience, time, and transaction binding only; the backend must authenticate actor and verify active tenant/unit membership before signing. This shared-key HMAC design still trusts PostgreSQL DBA/host administrators.
- No verifier or RLS policy has been created/changed yet. Key store and synthetic key remain in disposable PoC database only.
- Safety: only `sinau_design_poc`; no application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (first SECURITY DEFINER verifier script added)
- Key-store audit results were recorded: context key table owner is `sinau_context_owner`, secret bytes are exactly 32 bytes, and neither `sinau_poc` nor `sinau_rls_test` has direct SELECT access. No verifier existed at audit time.
- Added `docs/03-database/poc/005-verify-context-token.sql` on the feature branch (commit `ce799ad0742a72a52781b8cc22612b8e6a4f7b43`; current file blob `c870e00fb3161346bcb06d22c3d4ca00bdb950a0`). The script creates `sinau_private.verify_context_token(text)` owned by `sinau_context_owner), returning at most one verified actor/tenant/unit row.
- Script uses `SECURITY DEFINER`, `VOLATILE`, `PARALLEL UNSAFE`, fixed `search_path = pg_catalog, pg_temp`, schema-qualified key/HMAC references, strict 11-field canonical parser, fixed audience `sinau_design_poc`, active-key check, 300-second maximum lifetime with 5-second future-IAT skew, `pg_current_xact_id_if_assigned()` transaction binding, HMAC-SHA256 and fixed 32-byte compare loop.
- Script revokes default PUBLIC EXECUTE in the same transaction and grants schema USAGE/function EXECUTE only to `sinau_rls_test` for PoC. It does not grant key-table SELECT or direct HMAC EXECUTE and does not alter any RLS policy.
- Script includes malformed/empty-token negative checks, expected to return zero rows; valid signed-token interoperability, token tampering, expiry, revocation and cross-transaction replay are not yet tested.
- Static source inspection confirmed required security clauses and absence of policy DDL; this does not substitute for PostgreSQL runtime parsing/execution. The verifier script must be run and reviewed on the user's PostgreSQL 18.7 PoC before any valid-token test or policy integration.
- Next: user downloads/runs only `005-verify-context-token.sql` against `sinau_design_poc` as postgres. Review SQL errors and metadata (owner, prosecdef, proconfig, ACL) plus malformed token tests. Only after successful install, build a separate non-disclosing external signer round-trip to verify a valid token; do not expose secret or token.
- Safety: only `sinau_design_poc`; no app database `sinau`, role `sinau_app`, SQLRadius, or MikroTik touched. PR #1 remains Draft/open/unmerged.

### Verifier source refinement — 2026-11-18
- Before asking the user to execute the new verifier, the script was refined to require the token audience to equal both the PoC's fixed audience `sinau_design_poc` and `pg_catalog.current_database()`. This prevents accidental acceptance when the script/key is copied to a differently named database.
- Updated source: `docs/03-database/poc/005-verify-context-token.sql`; latest commit `2082a249dc146bf27622fa26d253f597d2e344c5`; verified blob `ce490de5f6023020ec6d756520cbc0fbdc28a12c`.
- The database-name audience is only an environment boundary for this PoC; production should use a unique deployment/environment audience identifier, because a clone restored under the same database name is not distinguished by database-name comparison alone.
- Source inspection verifies the audience comparison is present. Runtime SQL syntax and behavior remain unverified until executed against the user's PostgreSQL 18.7 PoC.

### RLS PoC checkpoint — 2026-11-18 (verifier execution blocked by filesystem permissions)
- User successfully downloaded `docs/03-database/poc/005-verify-context-token.sql` from commit `2082a249dc146bf27622fa26d253f597d2e344c5` into `~/sinau-poc`; local validation showed 223 lines and expected SECURITY DEFINER, fixed search_path, current_database audience, no-XID-allocation function, and PUBLIC EXECUTE revocation clauses.
- Attempted `sudo -u postgres psql ... -f 005-verify-context-token.sql` returned `Permission denied` while reading the script. The script is under `/home/sinauadmin`, which is not traversable/readable by the `postgres` OS account. The SSH connection subsequently closed.
- This is an operating-system file-access failure, not a PostgreSQL SQL/runtime failure. No verifier installation or SQL test result is established; do not claim the function exists.
- Next: reconnect to the SINAU host as `sinauadmin`; verify `/run` is tmpfs; stage the SQL file under a new dedicated `/run/sinau-poc-sql` directory owned by postgres mode 0700, file mode 0600, execute `psql -f` from that staging path, and use an EXIT trap to delete staging. Do not loosen permissions on `/home/sinauadmin` or the project folder.
- Only after psql completes successfully, inspect function owner, SECURITY DEFINER flag, fixed function settings, ACL, and malformed-token zero-row tests. If SQL fails, capture the error and stop; do not rerun setup or modify existing key material.
- Safety remains `sinau_design_poc` only; do not touch application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (SECURITY DEFINER verifier installed)
- User staged `005-verify-context-token.sql` into `/run` tmpfs with postgres ownership/mode 0600 because postgres OS account could not traverse the user's home directory. Staging was removed after execution; no home-directory permissions were relaxed.
- PostgreSQL execution completed successfully: CREATE FUNCTION, PUBLIC EXECUTE revoked, schema USAGE and function EXECUTE granted to `sinau_rls_test`, default privileges updated, transaction COMMIT.
- Metadata confirmed `sinau_private.verify_context_token(text)` owner `sinau_context_owner`, `prosecdef=true`, volatility VOLATILE, PARALLEL UNSAFE, and `proconfig={"search_path=pg_catalog, pg_temp"}`.
- Function ACL contains only owner EXECUTE and `sinau_rls_test` EXECUTE. Effective privilege checks: test schema USAGE=true; test EXECUTE verifier=true; test SELECT key store=false; test EXECUTE HMAC directly=false.
- Malformed token and empty token calls both returned zero rows (boolean assertions true). Transaction rolled back. This validates install and those negative cases only; no valid signed token interoperability, tampering, expiration, key revocation, or cross-transaction replay has yet been demonstrated.
- No existing RLS policy was changed. Key store remains protected; no secret value or signed token was shown.
- Next: run a controlled valid-token round trip in two terminal sessions. Terminal A must keep one explicit DB transaction open after allocating its XID under effective role `sinau_rls_test`; Terminal B (OS user sinauadmin) signs the exact token payload using the original 0600 local PoC key file and writes the bearer token only to tmpfs, then copies it to a postgres-readable 0600 tmpfs file. Terminal A imports token with psql `\\copy` into a temp table (grant INSERT/SELECT to test role before SET ROLE) and calls verifier in the SAME transaction. Token must expire within 300s and never be printed or pasted into chat/logs. Do not put key or token literals in SQL, shell arguments, shell history, or Git. If the transaction is lost/committed/rolled back, discard token and begin a fresh session with a fresh XID and token.
- For this PoC only, use synthetic actor UUID `90000000-0000-0000-0000-000000000001`, tenant A `00000000-0000-0000-0000-000000000001`, and unit A1 `10000000-0000-0000-0000-000000000001`. This verifier proves token integrity/time/audience/XID but does not validate real actor membership; production backend must do so before signing.
- Safety: only `sinau_design_poc`; no application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik touched. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (verifier runtime installation confirmed; external signer prepared)
- User ran the staged SQL script `005-verify-context-token.sql` from `/run` tmpfs as OS user postgres. Installation completed and committed. The staging SQL file was successfully removed afterward.
- Runtime metadata observed: function `sinau_private.verify_context_token(text)`, owner `sinau_context_owner`, `SECURITY DEFINER=true`, VOLATILE, PARALLEL UNSAFE, `proconfig={"search_path=pg_catalog, pg_temp"}`. Function ACL grants EXECUTE only to owner and `sinau_rls_test`; PUBLIC has no EXECUTE.
- Effective checks: `sinau_rls_test` schema USAGE=true and verifier EXECUTE=true; direct key-store SELECT=false; direct HMAC EXECUTE=false.
- Empty and malformed input tests both returned zero rows. This confirms fail-closed behavior for those two shapes only. Valid token, tampering, expiry, revocation, audience mismatch, and cross-transaction replay tests remain outstanding.
- Added `docs/03-database/poc/006-sign-context-token.py` (commit `8e95d2b4862bbcf9f5e028201346e076f92313d7`). This stdlib-only PoC signer reads the user's 0600 key file, validates its owner/mode/format, creates a 240-second token for fixed synthetic actor/tenant/unit and supplied XID, writes only to a new file in `/run` mode 0600, and never prints token or key. It refuses to overwrite an existing output file and checks `/run` is tmpfs. Static source only; it has not been executed by the model or user.
- Next: prove an external signer/verifier valid-token round trip across two SSH terminals. Terminal A must hold an explicit transaction open with session authorization `sinau_poc` and effective role `sinau_rls_test`, allocate XID, and remain open. Terminal B downloads/runs the signer for that XID, then copies the token to a postgres-owned 0600 file in `/run`. Terminal A uses psql `\\copy` to import it to a temp table and calls the verifier inside that same transaction. Expected valid row: synthetic actor `90000000-0000-0000-0000-000000000001`, tenant A and unit A1. Tampered MAC must return zero rows. Do not print or paste bearer token; if transaction ends or token expires, discard it and begin a fresh transaction/XID.
- The verifier only authenticates claims, audience, lifetime and transaction binding. It does not verify actor membership; backend membership checks remain a prerequisite before signing. No current RLS policy has been changed.
- No production secret; local key remains synthetic PoC-only. DBA/host admins remain trusted in HMAC design.
- Safety boundary: only `sinau_design_poc`. No application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik changes. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (valid-token round trip attempt paused; signer staging fixed)
- User opened Terminal A with `SET SESSION AUTHORIZATION sinau_poc`, began a transaction, created the temporary token input table, granted access to `sinau_rls_test`, set local role, and allocated XID `805`.
- User then invoked signer with literal placeholder `NOMOR_XID`; signer correctly rejected the non-decimal input before creating a token. The PostgreSQL session was subsequently exited with `\\q`/connection closed; open transaction was rolled back by session termination. XID 805, temporary table and transaction context are no longer usable. No token was created and no verifier test ran.
- After reconnect, signer was invoked from `/home/sinauadmin`, while downloaded script is located in `~/sinau-poc`; Python therefore reported file not found. The attempted copy from `/run/sinau-poc-token-sinauadmin` failed because the signer never generated that file.
- Review found a further signer script issue: it originally attempted to create a regular file directly under `/run`, typically not writable by an unprivileged user. Updated `006-sign-context-token.py` to write into `/run/sinau-poc-token-signer/context-hmac-v1.token`, require that directory to exist, be owned by the current user, and have mode 0700. Updated commit `26c4a65a1b0cee296941375cf6051581e86b16c0`; verified file blob `20564389684ad9f8126797a5fe789102e6fa362f`. This corrected script has not yet been executed.
- Next: open two SSH terminals. Terminal B creates the signer directory as a user-owned 0700 directory under tmpfs using `sudo install -d -o sinauadmin -g sinauadmin -m 700 /run/sinau-poc-token-signer`, changes to `~/sinau-poc`, downloads signer from the corrected commit, and verifies it exists. Terminal A starts a fresh explicit transaction, creates temp input table/grants, sets role test, allocates a NEW XID and remains open. Terminal B signs using exactly that displayed XID, copies the token to a postgres-owned 0600 file in /run, and Terminal A imports/validates it inside the same transaction. If session closes or transaction ends, discard token and start over with a fresh XID.
- Never pass the literal word `NOMOR_XID`; use the numeric value returned by `pg_current_xact_id()`. Do not run SQL commands at Bash prompt; `\\copy` and verifier SELECT must be entered at the psql prompt in Terminal A.
- No token/key was displayed or copied to persistent disk; no persistent database objects or RLS policy changed during the failed attempt.
- Safety: only `sinau_design_poc`; no application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (valid signed token and MAC tampering tests passed)
- User completed the external signer/verifier round trip using synthetic key `poc-k1` and PostgreSQL top-level XID `806`.
- The verifier returned exactly one row with the expected synthetic claims: actor `90000000-0000-0000-0000-000000000001`, tenant A `00000000-0000-0000-0000-000000000001`, and unit A1 `10000000-0000-0000-0000-000000000001`.
- Reusing the same valid token in the same transaction returned `valid_token_reusable=true`.
- Mutating the final MAC character caused zero verifier rows; `tampered_mac_rejected=true`.
- Transaction was rolled back and temporary token files were removed from `/run`. Token and secret values were not printed in the submitted output.
- This confirms Python HMAC-SHA256 signer and PostgreSQL pgcrypto verifier interoperability for the tested token, key lookup, audience, current XID, expiry window, and claim parser. It does not yet demonstrate expiry rejection, revoked-key rejection, audience mismatch, cross-transaction replay rejection, or real membership verification. The actor/tenant/unit values are synthetic and membership is not checked by verifier; backend membership validation remains a prerequisite.
- Next: extend PoC signer with a bounded `--ttl-seconds` option (1..300) while keeping default 240, then test a 1-second token after expiry. Test key revocation within controlled transaction with key-store update performed as `sinau_context_owner`, verify rejection, then restore `revoked_at=NULL` and confirm active key again. Finally, sign token for one XID, end that transaction, begin a fresh transaction with a distinct XID and verify same token returns zero rows. Keep token only in `/run` until replay test completes; remove all temporary copies afterward.
- Do not change RLS policies until expiry, revocation and cross-transaction replay tests pass. No policy was modified in this checkpoint.
- Safety: only `sinau_design_poc`; no application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik touched. PR #1 remains Draft/open/unmerged.

### Expiry-test preparation — 2026-11-18
- Updated `docs/03-database/poc/006-sign-context-token.py` to accept optional `--ttl-seconds`, constrained to 1–300 seconds; default remains 240 seconds. Payload signing and non-disclosing tmpfs output behavior are unchanged.
- Updated signer commit: `7c08d0b5e8fc242434329b65db7d4bdd79241da2`; verified file blob `6c15db9f36c2d072afdfed6475cc3283d421926b`. Static inspection confirmed option, default, bounds check and expiry calculation. This revision has not yet been run on the server.
- Next security tests remain: short-TTL expiry rejection; key revocation rejection and safe reactivation; same token rejected in a different top-level XID. Keep all tokens in /run only and avoid displaying token/key material.

### RLS PoC checkpoint — 2026-11-18 (cross-transaction replay attempt not started)
- User invoked signer with literal placeholder `XID_SUMBER` rather than the numeric XID from an open PostgreSQL transaction. Signer correctly rejected it with `XID must be canonical unsigned decimal` before creating any token.
- Subsequent `install` could not find `/run/sinau-poc-token-signer/context-hmac-v1.token`; this is expected because signing never occurred. No token was created or staged, and no replay verifier query was run.
- Next: open a fresh Terminal A psql session and explicit transaction, allocate a new XID with `pg_current_xact_id()::text`, leave that transaction open, and use the exact numeric XID (not a word placeholder) in the signer command in Terminal B. If Terminal A closes or transaction ends, discard that XID and start fresh.
- Safety boundary unchanged: only `sinau_design_poc`; no application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik changes. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (cross-transaction replay rejection passed)
- User completed replay test with original transaction XID `813` and replay attempt transaction XID `814`.
- The signed token returned one verified row inside its original transaction: `valid_in_original_transaction=true`.
- After COMMIT of the original transaction and BEGIN of a new transaction with XID 814, reusing the exact same token returned zero rows: `cross_transaction_replay_rejected=true`.
- Replay-test transaction ended ROLLBACK; the temporary table survived the first COMMIT as expected and disappeared when the psql session ended. Both temporary token files under `/run` were removed.
- This confirms the verifier enforces the top-level XID binding across the tested transaction boundary. The same token is reusable within its original transaction, but rejected in the later transaction.
- Remaining negative tests: short-TTL expiration and key revocation. After these pass, test audience mismatch and malformed field/canonical encodings. Do not change RLS policies before the negative test suite is complete.
- No persistent data or key material was modified by the replay test. No RLS policy changed.
- Safety boundary unchanged: only `sinau_design_poc`; never touch app DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (expiration test inconclusive due to XID mismatch)
- User attempted short-TTL expiration test. PostgreSQL Terminal A reported transaction XID `818`, but the signer command used XID `815` with `--ttl-seconds 5`.
- The verifier returned `expired_token_rejected=true` twice, but this is not valid evidence of expiration because verifier also rejects any token whose signed XID differs from `pg_current_xact_id_if_assigned()`. The observed token was already bound to XID 815 while current transaction was 818; rejection can be fully explained by XID mismatch, independently of expiry.
- Therefore expiration behavior remains UNVERIFIED. Do not count these results as a pass.
- User rolled back the transaction and removed both temporary token files from `/run`. No persistent data/key or RLS policy changed.
- Next: rerun with one fresh Terminal A transaction and capture its XID; use exactly that numeric XID as signer argument. Use TTL 15 seconds to allow time for transfer. Import token into the temp table in the same still-open transaction; immediately verify once and require one row (`valid_before_expiry=true`); wait at least 17 seconds; verify same token again and require zero rows (`expired_after_ttl=true`). This paired test isolates expiry from XID mismatch. If the first verification is zero rows, stop and inspect rather than claiming expiration.
- Safety: only `sinau_design_poc`; no app DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik changes. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (expiration test still inconclusive; wait ordering corrected)
- User's expiry-session XID was `822`. Token imported into the temp table was accepted on the first verifier call (`valid_before_expiry=true`).
- The immediate second verifier call returned `expired_after_ttl=false`, meaning verifier still accepted the token at that second check. No elapsed-time wait occurred between the two SQL calls in the submitted Terminal A transcript.
- The `sleep 32` command and another signer invocation using XID 822 appear after the Terminal A ROLLBACK/`\\q` in the submitted transcript. They therefore happened after the transaction that owned XID 822 was closed and cannot establish expiration of the token that was already checked. A token signed after the XID's transaction ended is not a valid same-transaction expiry test.
- Result: expiration remains UNVERIFIED. The first valid check confirms the imported token was accepted in transaction XID 822; the second shows it had not expired at the time of the immediate second call. No expiry pass should be recorded.
- Both reported token staging paths were removed. Transaction 822 was rolled back; no persistent row/policy was modified.
- Next attempt must be strictly ordered: (1) open a NEW psql transaction, get a fresh XID; (2) while it remains open, sign token using exactly that XID with `--ttl-seconds 30`; (3) copy token to postgres-readable tmpfs; (4) import and call verifier once, requiring `valid_before_expiry=true`; (5) leave psql transaction open and, in Terminal B, execute `sleep 32`; (6) only after sleep completes, call verifier again in same still-open transaction and require `expired_after_ttl=true`; (7) then ROLLBACK/close and clean both tmpfs files. Do not run signer or sleep after closing the transaction. If first check is false, stop and inspect before waiting.
- Safety boundary unchanged: only `sinau_design_poc`; no application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (signer output collision; token not generated)
- Current expiration-test PostgreSQL transaction is reported as XID `826` and remains open in Terminal A.
- Signer invocation with XID 826 and TTL 30 returned `Token output already exists` because the fixed tmpfs output path `/run/sinau-poc-token-signer/context-hmac-v1.token` already exists. The signer uses exclusive create and refused to overwrite it.
- This invocation did not create or replace a token. No PostgreSQL import or verifier call occurred in this attempt. Treat the pre-existing file as a leftover candidate: inspect only metadata (regular file, not symlink, owner sinauadmin, mode 0600) and remove it before regenerating; never display its contents.
- Keep Terminal A/XID 826 open. After safe removal, generate a fresh token using exactly XID 826 and a 60-second TTL, copy it into a new postgres-owned mode-0600 tmpfs path, then perform valid-before-expiry check, wait 62 seconds while the same transaction remains open, and perform expired-after-TTL check.
- No DB object/key/policy changed. PR #1 remains Draft/open/unmerged; target remains `sinau_design_poc` only.

### RLS PoC checkpoint — 2026-11-18 (expiry test interrupted by shell command entered in psql)
- In the expiry test, the first verifier call in transaction XID `826` returned `valid_before_expiry=true`.
- User entered `sleep 62` at the PostgreSQL `psql` prompt instead of Terminal B's Bash prompt. PostgreSQL raised a syntax error and marked the transaction aborted; the following verifier query was rejected with `current transaction is aborted`. Therefore no after-expiry verifier result was obtained.
- After the abort, user generated and staged another token using XID 826 and TTL 60. That token is invalid for a new test because its signed XID belongs to the already-aborted/closed transaction; it must be discarded, not verified.
- Current token copies are expected at `/run/sinau-poc-token-signer/context-hmac-v1.token` and `/run/sinau-poc-token-postgres`; user should first ROLLBACK and exit the aborted psql session, then remove both files.
- Expiry remains UNVERIFIED. No successful after-expiration rejection has been demonstrated.
- Next attempt: Terminal A opens a fresh transaction and gets a fresh XID; Terminal B signs with that exact XID and TTL 60, transfers token; Terminal A verifies immediately (must return one row), leaves transaction open; Terminal B Bash runs `sleep 62`; only after sleep finishes, type the second SQL verifier query at Terminal A's psql prompt; it must return zero rows. Never type shell commands at psql. Then ROLLBACK and clean token files.
- Existing key store and verifier are unchanged; no RLS policy changed. No production DB/role, SQLRadius or MikroTik touched. PR #1 remains Draft/open/unmerged.

### Expiry test procedure refinement — 2026-11-18
- To avoid confusion between Bash and psql prompts during the short-TTL test, use PostgreSQL's SQL function `SELECT pg_catalog.pg_sleep(32);` between the before-expiry and after-expiry verifier calls in the SAME explicit transaction. This keeps the transaction and signed XID open while elapsed time passes.
- Before retry, ROLLBACK and close any aborted XID 826 session; delete both token files under `/run`. Start a new transaction and sign for its exact new XID.

### RLS PoC checkpoint — 2026-11-18 (token expiration verified)
- User completed a paired short-TTL test with PostgreSQL transaction XID `830` and signer TTL 30 seconds.
- The token was imported into the transaction-bound temporary table and verifier returned one row before expiration: `valid_before_expiry=true`.
- User then executed `SELECT pg_catalog.pg_sleep(32);` at the psql prompt while the same transaction remained open. A subsequent verifier call in that same transaction returned zero rows: `expired_after_ttl=true`.
- This is valid evidence of expiration enforcement because the token passed first, elapsed time exceeded its 30-second TTL inside the same XID, and the same token was rejected afterward. This supersedes prior inconclusive expiry attempts caused by XID mismatch or shell command entered at the psql prompt.
- Transaction was ROLLBACKed. User reports token staging files were cleaned; logs were interleaved between terminal sessions, but no key/token contents were exposed.
- Negative test suite now passed for malformed/empty token, MAC tampering, cross-transaction replay, and expiration. Key revocation remains outstanding.
- Next: test revocation with a valid token in an open transaction. First verify it succeeds; from a second PostgreSQL admin connection, `SET ROLE sinau_context_owner` and set `revoked_at=clock_timestamp()` for `poc-k1`, COMMIT; then re-run verifier in the still-open original transaction and expect zero rows. Restore `revoked_at=NULL` from the admin connection and verify the token becomes valid again within the same transaction (optional but useful). Always restore active status in a guaranteed cleanup step; do not leave the synthetic key revoked. Never select or display secret bytes. Only after revocation tests pass proceed to audience/malformed-claim tests and RLS integration.
- No RLS policy changed. Key remains synthetic PoC-only. Safety boundary unchanged: only `sinau_design_poc`; no app DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik touched. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (key revocation and reactivation verified)
- User repeated the revocation test in a clean transaction bound to PostgreSQL top-level XID `840`.
- With key `poc-k1` active, the signed token for XID 840 was imported and accepted by `sinau_private.verify_context_token(text)`: `active_key_token_accepted_before_revoke=true`.
- After the key was revoked and that change committed from the separate administrative connection, the same token in the still-open XID 840 transaction returned zero rows: `revoked_key_token_rejected=true`.
- After key reactivation, the same token in the same transaction was accepted again: `restored_key_token_accepted=true`.
- Final independent status query showed `poc-k1` as `ACTIVE`. User removed both temporary token files from `/run`; checks reported `Token signer: BERSIH` and `Token PostgreSQL: BERSIH`. Token and secret contents were never displayed.
- This demonstrates active-key lookup and immediate revocation enforcement under the tested READ COMMITTED transaction behavior, including reactivation visibility from a still-open transaction. It does not establish production key-management controls, resistance to a privileged DBA/host administrator, or real actor-membership validation.
- The first revocation attempt (XID 835) did not yield a valid test because the psql transaction entered an aborted state; it was discarded. The successful, clean rerun is XID 840 and supersedes that attempt.
- **Session cleanup still to confirm:** Terminal A's final `ROLLBACK`/psql exit was requested but not yet shown in the submitted output. Before starting another SQL test, confirm the XID 840 session has been rolled back/closed.
- Negative PoC tests now demonstrated: malformed/empty token rejection, MAC tampering rejection, cross-transaction replay rejection, expiry rejection, and revoked-key rejection. Same-transaction acceptance before revocation and after key reactivation also passed.
- No RLS policy was changed by these tests. Only synthetic PoC database `sinau_design_poc` and roles were used; application database `sinau`, role `sinau_app`, SQLRadius, and MikroTik were not touched.
- Next: confirm Terminal A rollback/close; then test audience mismatch and canonical field/claim validation before considering a dedicated RLS policy integration PoC. Do not alter application schemas or production systems. PR #1 remains Draft/open/unmerged.

### RLS PoC checkpoint — 2026-11-18 (audience and canonical claim validation passed)
- User ran nine signed-token cases in one open PostgreSQL transaction bound to XID `846`, with effective role `sinau_rls_test` and session authorization `sinau_poc`.
- The valid baseline token returned exactly one row. Eight negative tokens returned zero rows: wrong audience, uppercase actor UUID, leading-zero XID, leading-zero issued-at timestamp, uppercase nonce hex, short nonce, extra field, and uppercase MAC hex.
- Each case's HMAC was recalculated using the synthetic PoC key after altering the target field/structure. Therefore the negative cases exercise verifier audience/parser/canonical-format checks rather than simply failing due to a stale MAC. All nine `expected_result_passed` values were `t`.
- Every case ran under the same XID `846`; baseline acceptance demonstrates the common transaction/key/time prerequisites were valid during the run.
- User rolled back the test transaction and exited psql. Both TSV token files were removed from signer and PostgreSQL tmpfs paths; checks reported `Signer test file: BERSIH` and `PostgreSQL test file: BERSIH`. Independent status query confirmed key `poc-k1` is `ACTIVE`.
- The latest demonstrated negative PoC suite now includes malformed/empty token, MAC tampering, cross-transaction replay, expiry, key revocation, audience mismatch, and canonical claim/field-format rejection. This does not yet prove full application authentication, membership authorization, context provenance, or production key-management security.
- No RLS policies were modified. Only disposable database `sinau_design_poc` was used; application database `sinau`, role `sinau_app`, SQLRadius, and MikroTik were not touched.
- Next: review the boundary between token verification and trusted context installation. Design a narrowly scoped SECURITY DEFINER context-establishment function or equivalent trusted broker that validates authenticated actor membership before transaction-local context is installed; include rollback/reset, nested transaction, connection-pool reuse, and privilege tests. Do not enable or alter tenant RLS policies yet, and do not treat the current PoC token verifier as complete production authorization. PR #1 remains Draft/open/unmerged.

### RLS PoC architecture refinement — 2026-11-18 (signed token as policy context)
- Code review confirmed the original `003-rls-setup.sql` predicates directly trusted client-writable `current_setting('app.tenant_id')` and `current_setting('app.unit_id')`. Prior PoC spoofing already demonstrated that arbitrary SQL callers can change those settings; a SECURITY DEFINER setter that merely writes those two GUCs would not fix the trust boundary.
- Architecture refinement: use `app.context_token` only as a transaction-local carrier for the opaque signed token. The RLS policy must derive tenant/unit scope from `verify_context_token(text)` results via `sinau_private.current_verified_context()`; never use unsigned tenant/unit GUCs in policy predicates.
- Added `docs/03-database/poc/007-rls-signed-context.sql` (commit `985a91fe5667205530797930148cd36e2467bd6a`; verified file blob `d19a38eef3a8af716076d36eb4aec05ae66592ef`). It creates an invoker-rights, VOLATILE, PARALLEL UNSAFE accessor with fixed `search_path`, grants execution to `sinau_rls_test`, and replaces PoC RLS predicates to read only verified claims. The file is committed but has NOT been executed on the server.
- Updated `docs/03-database/poc/README.md` with the safety boundary, execution command, test sequence, and limitations (commit `b603bbfe4cf5880040c60820f7b880674215e74e`; verified blob `9ff6ad27357c9832498fba02027a1c93f9578e05`).
- Critical limitation retained: the current external signer uses hard-coded synthetic actor/tenant/unit IDs and does not authenticate a real principal or verify membership. Production signer/backend must authenticate the actor and confirm active tenant/unit membership before issuing a token. The signed token is a bearer credential within its bound transaction; this PoC is not production authorization approval.
- Next: review the new SQL file and README, then execute `007-rls-signed-context.sql` only in `sinau_design_poc`. Test valid signed context, legacy-GUC spoof attempts, invalid/missing token fail-closed behavior, valid same-scope write, cross-scope write rejection, rollback, and transaction/pool context reset. Do not touch `sinau`, `sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.

### Signed-context RLS setup checkpoint — 2026-11-18 (14 policies verified)
- User executed `007-rls-signed-context.sql` against the disposable database `sinau_design_poc` as PostgreSQL administrator. The output showed `sinau_private.current_verified_context()` owned by `sinau_context_owner`, SECURITY INVOKER (`prosecdef=false`), VOLATILE, PARALLEL UNSAFE, with fixed `search_path=pg_catalog, pg_temp`; EXECUTE was granted to `sinau_rls_test` and not PUBLIC.
- Policy inventory showed 14 `sinau_rls_isolation` policies using `sinau_private.current_verified_context()`.
- Follow-up catalog query confirmed 14 tenant-scoped tables, all 14 with RLS enabled and FORCE ROW LEVEL SECURITY; total policies 14; signed-context policies 14; policies still referring to legacy `app.tenant_id` / `app.unit_id` settings: 0.
- This verifies installation/catalog shape only. Functional behavior with valid token, forged legacy GUCs, invalid/missing token, cross-scope writes, and transaction-local context cleanup has NOT yet been tested.
- The prior policy setup changes are confined to `sinau_design_poc`; no production/application database, `sinau_app`, SQLRadius, or MikroTik was touched.
- Next: test in one disposable transaction under `sinau_poc` / `sinau_rls_test`: valid signed token reveals only the token's synthetic tenant A/unit A1 data; setting legacy tenant/unit GUCs to tenant B/unit B1 must not change visibility; invalid/missing `app.context_token` must fail closed; same-scope INSERT succeeds and cross-scope INSERT is rejected; finally ROLLBACK and confirm transaction-local token context is not carried into a subsequent transaction. Token remains a synthetic bearer credential; current signer does not authenticate actors or check membership. PR #1 remains Draft/open/unmerged.

### Signed-context RLS functional test harness prepared — 2026-11-18
- Prepared `docs/03-database/poc/008-test-signed-context-rls.sql` (commit `b4b47765b19819712ba78b09fb855310036ab222`). It is an assertion-oriented script intended to run via `\\i` in the same open psql transaction that owns the signed token XID and temporary token table.
- The harness checks: valid token reveals exactly tenant A/unit A1; attempts to spoof legacy `app.tenant_id` / `app.unit_id` to tenant B/unit B1 do not alter scope; empty and malformed token context fail closed; same-scope academic-year INSERT succeeds; cross-tenant and cross-unit INSERTs are rejected by RLS `WITH CHECK`.
- Updated `docs/03-database/poc/README.md` with exact same-session execution order and rollback/cleanup requirements (commit `b62c73a93736886632f7a994485b4774f5304c8b`; verified blob `2d0ef0770c50b0509246fa078fff85c09922654a`).
- Static source preparation only: the new functional test file has NOT been run against PostgreSQL; do not mark its assertions passed until user provides server output.
- At handoff, user had opened a new psql transaction with XID `857`, created temporary table `poc_signed_context_input`, set role `sinau_rls_test`, and created/copied a 240-second token for that XID to `/run/sinau-poc-token-postgres/context-hmac-v1.token`. The token has not yet been imported or used by the functional test harness in the submitted transcript; it may expire, and the psql transaction may remain open in the user's terminal. On resume, first inspect/close that session with ROLLBACK (or confirm it already ended), remove both old token copies, then start a fresh transaction and generate a fresh token for its new XID. Do not reuse XID 857 after its transaction ends or token expiration.
- Scope boundary: all testing remains within `sinau_design_poc`; no production database `sinau`, role `sinau_app`, SQLRadius, or MikroTik changes. PR #1 remains Draft/open/unmerged.
- Next user-assisted step: execute the prepared `008-test-signed-context-rls.sql` using a fresh same-session token, verify the expected NOTICE messages, ROLLBACK, and clean tmpfs token files. After that, assess transaction context reset, role/privilege bypass cases, and RLS query performance before any further integration. Do not treat this as production-ready authorization.

### Signed-context RLS harness expanded — 2026-11-18 (functional and reset tests prepared)
- Added `docs/03-database/poc/008-test-signed-context-rls.sql` (commit `b4b47765b19819712ba78b09fb855310036ab222`; verified blob `263296c7181ef413e5bc40af19dd4b6774673b2d`). The same-session assertion harness checks signed-scope visibility, legacy-GUC spoof resistance, empty/malformed token fail-closed behavior, same-scope INSERT success, and cross-tenant/cross-unit INSERT rejection. It intentionally leaves the caller's outer transaction open for an explicit ROLLBACK.
- Added `docs/03-database/poc/009-test-context-reset.sql` (commit `0bb7ab394c92f4769cad93d08d4555c33523d0ba`). It is intended to run in the same psql connection after rollback of the token-bearing transaction; it checks that transaction-local `app.context_token` is absent/empty in the next transaction and that tenant-scoped rows remain invisible without a token.
- Updated `docs/03-database/poc/README.md` with the ordered 008/009 execution flow and limitations (latest README commit `074e882cc7e68fb9ba5ee8684688b9d140a6d722`; verified blob `935b500bab6d43c500c6fd0fc6eee3bb70525de9`).
- These two new SQL harness files have NOT been executed against PostgreSQL. They are prepared artifacts only; do not claim functional RLS or context-reset acceptance until the user runs them and supplies actual output.
- User last opened a separate psql transaction with XID `857`, created temp table `poc_signed_context_input`, set local role `sinau_rls_test`, then created and copied a 240-second token for XID 857 to `/run/sinau-poc-token-postgres/context-hmac-v1.token`. It was not imported or tested before the user paused. At resume, do not assume that session or token remains active: first inspect the psql session; ROLLBACK/close it if still open; remove old token files from both tmpfs paths; then start a fresh transaction and generate a fresh token for its exact new XID.
- All work remains documentation/static test-harness preparation for `sinau_design_poc`. No production database `sinau`, `sinau_app`, SQLRadius, or MikroTik has been touched. PR #1 remains Draft/open/unmerged.
- Next user-assisted sequence: apply no new schema changes; start fresh transaction/token; run 008 in the same psql session; ROLLBACK; run 009 in the same psql session; ROLLBACK and exit; clean token files; record actual results. Follow with actual pooler/worker reuse and query-plan/performance tests before production architecture decisions.

### Signed-context RLS functional checkpoint — 2026-11-19 (functional assertions passed)
- User executed `docs/03-database/poc/008-test-signed-context-rls.sql` on PostgreSQL 18.7 inside the same open psql session/transaction bound to XID `861`, with `session_user=sinau_poc` and `current_user=sinau_rls_test`.
- Import into `pg_temp.poc_signed_context_input` succeeded (`COPY 1`). Script 008 completed with all six notices: valid token reveals only tenant A/unit A1; spoofing legacy tenant/unit GUCs does not change signed scope; empty/malformed token fails closed; same-tenant/same-unit INSERT accepted; cross-tenant INSERT rejected by RLS WITH CHECK; cross-unit INSERT rejected by RLS WITH CHECK.
- Final script output: `SIGNED CONTEXT RLS FUNCTIONAL ASSERTIONS PASSED`. No error was reported.
- **Transaction cleanup pending at handoff:** the user has not yet shown the outer transaction rollback. Do not mark data cleanup complete until `ROLLBACK;` is executed. The same psql session is needed for the follow-up `009-test-context-reset.sql` check after rollback.
- After 009 passes, roll back its verification transaction, exit psql, remove the signer and postgres token files under `/run`, and confirm `poc-k1` remains ACTIVE. The 240-second token must not be reused after the transaction ends or expires.
- This functional pass demonstrates the intended signed-token policy behavior for the tested rows/operations only. It does not prove actual application membership validation, pooler/worker integration, role-escalation resistance, support access boundaries, or production readiness. No RLS policy changed in this test step; only the already-installed policies in `sinau_design_poc` were exercised.
- No application DB `sinau`, role `sinau_app`, SQLRadius, or MikroTik was touched. PR #1 remains Draft/open/unmerged.
- Next: run `ROLLBACK;` in the still-open XID 861 session; stage and run `009-test-context-reset.sql` in that same psql connection; rollback again; clean token files; verify key and final session state.
### Signed-context RLS handoff recovery — 2026-11-19
- After the successful 008 functional assertions on XID `861`, the user later ran `ROLLBACK; \\q` in a separate psql session and queried `pg_stat_activity`. The query returned zero rows for `datname='sinau_design_poc' AND usename='sinau_poc'`, confirming no signed-test session remained connected. Any uncommitted test writes from XID 861 are therefore rolled back by transaction/session termination; the user-visible log does not show a direct `ROLLBACK` in the original XID 861 session.
- The signer-side token file `/run/sinau-poc-token-signer/context-hmac-v1.token` still existed (owner sinauadmin, mode 0600, 262 bytes); the PostgreSQL copy did not exist. The token was bound to the ended XID 861 and must be discarded. Cleanup of the remaining signer token was requested but not yet confirmed.
- The 009 reset test has NOT been run. Because the original XID 861 psql session is no longer present, the context-reset check must be repeated with a fresh same-session sequence: create a new token/XID, run 008, ROLLBACK in that same psql connection, run 009 in that same connection, ROLLBACK again, then exit and clean tmpfs token files.
- Do not reuse XID 861 or its token. Do not create a new `sinau_poc` session for 009 without first completing the 008/ROLLBACK sequence in that same connection.
### Signed-context RLS functional checkpoint — 2026-11-19 (XID 867 rerun passed)
- User repeated `008-test-signed-context-rls.sql` in a clean PostgreSQL 18.7 psql transaction bound to XID `867`, session authorization `sinau_poc`, and effective role `sinau_rls_test`.
- Import of the one signed token succeeded (`COPY 1`). Script 008 again passed all six assertions: valid token reveals tenant A/unit A1; spoofed legacy tenant/unit GUCs do not change signed scope; empty and malformed tokens fail closed; same-scope INSERT succeeds; cross-tenant and cross-unit INSERTs are rejected by RLS WITH CHECK.
- The script emitted `SIGNED CONTEXT RLS FUNCTIONAL ASSERTIONS PASSED` with no error. This is a second successful run, independently using fresh XID 867.
- **Pending in the active psql session:** the outer XID 867 transaction is still open. User must execute `ROLLBACK;` before running `009-test-context-reset.sql` in the same psql connection. Do not COMMIT.
- After the 009 assertions pass, ROLLBACK its verification transaction, exit psql, remove both token copies from /run, and verify the PoC key is ACTIVE. Do not reuse the token after its transaction ends.
- This confirms the scripted RLS behavior for the tested PoC scope but does not prove application membership validation, actual pooler/worker reuse, or production authorization readiness. No production database, `sinau_app`, SQLRadius, or MikroTik was touched. PR #1 remains Draft/open/unmerged.
### Signed-context RLS end-to-end PoC checkpoint — 2026-11-19 (008 and 009 passed)
- User reran signed-context RLS functional tests with fresh PostgreSQL top-level XID `867`, `session_user=sinau_poc`, and `current_user=sinau_rls_test`. Token import succeeded (`COPY 1`); `008-test-signed-context-rls.sql` completed without error and emitted all six PASS notices: signed tenant A/unit A1 visibility; legacy `app.tenant_id` / `app.unit_id` spoofing does not change scope; empty/malformed token fail closed; same-scope INSERT accepted; cross-tenant INSERT rejected; cross-unit INSERT rejected.
- User explicitly ROLLBACKed the XID 867 token-bearing transaction, then in the same psql session executed `009-test-context-reset.sql`. Both assertions passed: transaction-local signed token was reset; next transaction without a token sees no tenant data. The 009 verification transaction was also explicitly ROLLBACKed.
- Final cleanup output confirmed signer token file absent, PostgreSQL token file absent, script staging files removed, and signer/PostgreSQL token directories cleaned as applicable. Key `poc-k1` was confirmed `ACTIVE`. Final `pg_stat_activity` query returned `remaining_sinau_poc_sessions = 0`.
- This completes the current signed-context RLS PoC acceptance for the tested synthetic fixtures and operations: signature/audience/time/XID/parser validation, key revocation/reactivation, tenant/unit policy scope, resistance to legacy GUC spoofing, fail-closed missing/malformed token behavior, same-scope and cross-scope INSERT checks, and transaction-local token reset on the same connection.
- Important boundaries remain: the signer still uses synthetic fixed actor/tenant/unit values and does not authenticate real users or check membership; no real application backend, connection pooler, worker lifecycle, support access, concurrency, or query-performance test has been completed. Do not treat this as production authorization approval or approval to create production migrations.
- No production/application database `sinau`, role `sinau_app`, SQLRadius, or MikroTik was touched. All test writes were rolled back. PR #1 remains Draft/open/unmerged.
- Next work before production consideration: design and test a trusted backend issuer that authenticates the actor and checks active membership/entitlement before signing; test actual connection-pool checkout/checkin reset and worker/job contexts; test role escalation/ownership/bypass paths; benchmark RLS plans and latency; extend SELECT/UPDATE/DELETE, bulk, and `audit_events` tenant-level behavior; then conduct threat-model and design review. Keep the current PoC isolated.
### Trusted backend context issuer design checkpoint — 2026-11-19
- Reviewed ADR-003, ADR-004, BP-PLT-05, ROLES-AND-PERMISSIONS.md, MULTI-TENANT.md, DOMAIN-OWNERSHIP-MATRIX.md, and the current PostgreSQL PoC schema/verifier/signer. The source baseline requires global identity to be separate from tenant/unit grants; tenant membership does not imply unit membership; role/permission, lifecycle, verification, subscription, and entitlement remain separate dimensions.
- Added `docs/05-security/TRUSTED-CONTEXT-ISSUER-DESIGN.md` (commit `e391b1958e69312d59758bfe8d92d77ddda2a500`; verified file blob `9d803075a0a62586b2cca655f491e9f59f42baf9`). It defines trusted-principal input, server-side membership validation, tenant/unit scope, role/resource authorization, separate entitlement gates, transaction/XID-bound issuance, secret handling, revocation semantics, least privilege, threats, and ISS-01—ISS-14 acceptance cases.
- Updated `docs/05-security/TENANT-ISOLATION-TEST-PLAN.md` with the issuer validation boundary (commit `ac05709132693e22a49661224e67c3646fd719a5`; verified blob `2ee066d245c6f01073b28067096b5a9af7216de5`). Updated `docs/03-database/poc/README.md` to state that current schema does not implement identity/session/membership/role/entitlement tables and that the existing fixed-claim signer is not a production issuer (commit `06c2d8f4e18871f47ae0256f0ed86f8e0dd1d297`; verified blob `1767051703acda0c62bb4b217216d06209aaef65`).
- Important design boundary: the current PostgreSQL PoC contains no physical identity, auth-session, tenant-membership, unit-membership, role-assignment, or entitlement schema. ADR-003 defines conceptual entities only. No executable context issuer or membership fixture has been implemented or run yet; no production application stack is approved. Avoid adding production migrations or assuming table names/columns are final.
- The issuer design explicitly keeps entitlement as a separate feature/quota decision and explains that a valid RLS context token is not a permission to perform every business action. It also records the open decision about whether in-flight transactions may finish after membership revocation or require an immediate authorization-epoch check.
- Next: prepare a database-only, isolated synthetic identity/session/membership fixture and issuer-validation SQL tests in `sinau_design_poc` (separate PoC schema, no real users). Validate active/missing/revoked/expired membership, tenant-only versus unit scope, cross-tenant unit mismatch, disabled user/session, and separate feature entitlement. Use a dedicated issuer/query test role distinct from the PoC table owner; do not grant fixture mutation or secret access to the query role. Only after the fixture model is reviewed should we write an executable signer integration. Do not touch `sinau`, `sinau_app`, SQLRadius, or MikroTik.
- PR #1 remains Draft/open/unmerged; no stack or production migration decision has been made.
### Trusted issuer membership-validation PoC prepared — 2026-11-19
- Added isolated design document `docs/05-security/TRUSTED-CONTEXT-ISSUER-DESIGN.md` (initial commit `e391b1958e69312d59758bfe8d92d77ddda2a500`; latest verified blob `74843daba66efd67a9dbf47f2190c6c2a19538f8`). It separates authentication principal, membership, lifecycle, role/permission, resource relationship, entitlement, token signing, and database RLS responsibilities.
- Updated `docs/05-security/TENANT-ISOLATION-TEST-PLAN.md` (commit `ac05709132693e22a49661224e67c3646fd719a5`) and `docs/03-database/poc/README.md` (latest commit `abe303f5599105ad7634c8a9562a312654308b14`) to document the issuer boundary and the fact that the current PoC schema has no real identity/membership model.
- Added `docs/03-database/poc/010-context-issuer-fixtures.sql` (initial commit `76ea5256cabe1811ae3f317fd7203786f14cc797`; latest fix commit `e3692c4184fb8bb8ab8cccc88eddfa220bc634c8`). It creates a private synthetic issuer schema, a NOLOGIN issuer-test role, hashed dummy session fixtures, active/disabled identities, tenant/unit membership states, a private synthetic unit catalog, separate feature-entitlement fixtures, and a narrow SECURITY DEFINER membership validator. The validator does not accept an actor_id argument; it resolves actor identity from a hashed session credential. It deliberately does not query FORCE-RLS-protected public.education_units before a signed context exists.
- Added `docs/03-database/poc/011-context-issuer-validation-tests.sql` (initial commit `2f68b4e994bbb172f6963a6f6b45fda32d103dc6`; privilege-test correction commit `4c0349c10d1ced9a96460604895ddad97fe66605`). It covers active membership, missing/revoked unit grant, revoked tenant membership, tenant-only context, disabled account, revoked/expired session, future tenant membership, expired unit membership, unit/tenant mismatch, separate entitlement behavior, and query-role restrictions.
- Static source review only: scripts 010/011 are committed but NOT yet executed on the server. The validator is a membership-validation gate, not a complete backend signer; it does not yet sign an RLS context token, use a real browser authentication session, evaluate role/permission delegation, or enforce the final tenant/unit lifecycle policy. Test session strings are public synthetic fixture values only.
- The PoC uses a NOLOGIN role `sinau_context_issuer_poc`, granted to `sinau_poc` solely to simulate SET ROLE in the disposable database. This is not a production role arrangement. The real web runtime, issuer, and migration roles must be separated and least-privileged after the application/auth stack is decided.
- Next: inspect the final SQL script blobs and README instructions, then stage/run 010 as PostgreSQL administrator against `sinau_design_poc` only; run 011 in an interactive psql session with session authorization `sinau_poc`; capture output, then review fixture cleanup and role privileges. After membership validation passes, decide how the actual backend process receives the authenticated principal and same-connection transaction/XID before implementing its signer. Never touch `sinau`, `sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.
### Trusted issuer validation matrix refined — 2026-11-19
- Refined `docs/03-database/poc/010-context-issuer-fixtures.sql`; latest relevant commit `4a5c0a2245169029bce31d552395e8fed69573b6`, verified blob `d4aec6229c721678caeadb8d2950c2567cb2183f`. Fixture now includes active/inactive unit lifecycle states plus active, suspended, revoked, expired, and not-yet-valid membership cases. It uses a private synthetic unit catalog so the SECURITY DEFINER validator does not read the FORCE-RLS-protected public education_units table before context installation.
- Refined `docs/03-database/poc/011-context-issuer-validation-tests.sql`; latest relevant commit `c0bf21985f777042d4a22e58f24af5dceb4a9e6d`, verified blob `1572f39c86d2d3826746a630b0e4bac64272c516`. Scenarios are numbered ISS-01 through ISS-14 and include active access, missing/revoked unit grant, revoked tenant membership, tenant-only context, disabled identity, revoked/expired session, future/suspended/expired tenant membership, expired unit membership, inactive unit, tenant/unit mismatch, independent feature-entitlement check, no caller-supplied actor_id argument, and denial of fixture/key access or membership mutation to the RLS query role.
- The validator accepts a synthetic session bearer, tenant selector, and optional unit selector; it derives the actor by hashing the session bearer and looking up an active synthetic session. It does not accept actor_id from the caller. This is a membership-validation primitive only; it does not sign the RLS context token or prove a real browser authentication session.
- Updated `docs/05-security/TRUSTED-CONTEXT-ISSUER-DESIGN.md` with the expanded fixture/test coverage (commit `d57145e94784ef1df3c23bb60f8a3f1af3b52e43`; verified blob `aebca90b0e53f3ec28f7652c52f6714d47b01428`). Updated `docs/03-database/poc/README.md` with the full fixture and validation matrix (commit `0d95a94e51bb0c0586df3403c42b78dc8a2a786e`; verified blob `66ef51023a860bf89c7d8955baf8df1d87737fa8`).
- Static source checks confirm target-database guard, no lookup of `public.education_units` in the issuer validator, ISS-01—ISS-14 coverage, separate entitlement check, and no actor_id input. **Neither 010 nor 011 has been executed on the server yet.** Treat all SQL as prepared PoC artifacts until the user runs it and supplies actual output.
- Next: stage 010 and 011 under `/run` with owner postgres/mode 0600. Run 010 as PostgreSQL administrator only against `sinau_design_poc`; inspect its metadata/privilege report. Then, in an interactive psql session on `sinau_design_poc`, `SET SESSION AUTHORIZATION sinau_poc` and run 011; it performs role switches and ends in ROLLBACK. Inspect test notices and final privileges before deciding whether to implement an actual transaction-bound backend signer.
- No production database `sinau`, role `sinau_app`, SQLRadius, or MikroTik was touched. PR #1 remains Draft/open/unmerged.


### Trusted issuer validation PoC executed successfully — 2026-11-19
- Executed `docs/03-database/poc/010-context-issuer-fixtures.sql` on the server against `sinau_design_poc` only. The first attempt exposed a PostgreSQL type qualification typo (`pg_catalog.boolean`); corrected it to `pg_catalog.bool` in commit `b51f2227187482c623664f14dfd09ad2ac8db042`. The rerun completed and reported `validate_context_request(text,uuid,uuid)` owned by `sinau_context_owner`, `SECURITY DEFINER`, VOLATILE, PARALLEL UNSAFE, fixed `search_path=pg_catalog, pg_temp`; issuer EXECUTE granted, PUBLIC/query-role execute denied, and no direct fixture/key-table access for issuer/query role.
- Executed the corrected `011-context-issuer-validation-tests.sql` in an interactive `psql` session authorized as `sinau_poc`. ISS-01 through ISS-14 all passed, including tenant-only scope, missing/revoked/expired/future/suspended memberships, inactive unit, tenant/unit mismatch, disabled identity, revoked/expired/unknown/empty session credentials, and separate feature-entitlement evaluation.
- The first 011 run exposed a privilege-test implementation issue: resolving a private-schema function name via `regprocedure` required schema USAGE. The test was corrected in commit `4c6ced509d65a84c345b47eab8bb9e67a5b0c6a4` to resolve function/relation OIDs through `pg_proc`, `pg_class`, and `pg_namespace`; the corrected test verifies that `sinau_rls_test` cannot execute the issuer validator, read membership fixtures or the key store, or mutate membership fixtures. Final output: `PASS: RLS query role cannot issue context, read fixtures/key, or mutate memberships`, followed by `ROLLBACK` and `CONTEXT ISSUER VALIDATION TESTS PASSED — TRANSACTION ROLLED BACK`.
- The fixture setup in 010 is installed in the isolated design PoC; 011's test transaction was rolled back. This is verified synthetic membership-validation coverage only. It is NOT a real application authentication integration, role/permission/resource-relationship authorization implementation, tenant/unit lifecycle policy approval, or signed RLS-context issuer. The session strings and identity/membership rows are synthetic.
- Next: review how the eventual Laravel backend obtains the authenticated principal from trusted server-side authentication middleware and how it pins validation, token signing, and context installation to the same database connection and top-level transaction/XID. Define runtime/issuer/migration role separation, transaction cleanup, revocation semantics, role/permission and resource relationship checks before writing a real signer. Do not use caller-supplied actor_id, browser-visible tokens, connection-pool leakage, or direct application table access as a substitute for these checks.
- No production database `sinau`, role `sinau_app`, SQLRadius, or MikroTik was accessed or modified. PR #1 must remain Draft/open/unmerged unless the owner explicitly authorizes otherwise.


### Backend issuer integration readiness reviewed — 2026-11-19
- Reviewed `IMPLEMENTATION-PLAN.md`, ADR-005, `SECURITY-BASELINE.md`, `MULTI-TENANT.md`, `TRUSTED-CONTEXT-ISSUER-DESIGN.md`, and the database documentation. ADR-005 remains Proposed: Laravel 13 + Vue 3 + Inertia is a PoC recommendation, web session is recommended, and API/client authentication (including Sanctum) remains under evaluation.
- Inspected the complete branch tree (102 entries): no `composer.json`, `app/`, `routes/`, `resources/`, or application migration paths exist yet. There is therefore no real Laravel authentication middleware, server-side principal contract, DB connection pool/runtime role, or transaction boundary to integrate with. Implementation Plan places application bootstrap in Stage E only after the preceding product/technical/UX/database stages are approved.
- Updated `docs/05-security/TRUSTED-CONTEXT-ISSUER-DESIGN.md` (commit `beb1370f0392e05963ad81a447746744f15d048f`) and `docs/03-database/poc/README.md` (commit `4d0a8b22eb50a61f2cc06bfb43138fcd3d476610`) to record the actual successful synthetic SQL execution and clearly separate it from the unimplemented real backend issuer.
- Next prerequisite: prepare/review a separate ADR for authentication/session principal provenance, tenant/unit selector validation, runtime/issuer/migration PostgreSQL roles, connection-pool behavior, same-connection XID-bound transaction flow, transaction-local context cleanup, and revocation/in-flight request semantics. Only after the authentication and application bootstrap decisions are approved should an executable Laravel signer be designed.
- PR #1 remains open and Draft, unmerged. No Laravel application code or production migration was added. No production database `sinau`, role `sinau_app`, SQLRadius, or MikroTik was accessed or modified.


### ADR-007 trusted context issuer contract drafted — 2026-11-19
- Created `docs/09-decisions/ADR-007-TRUSTED-CONTEXT-ISSUER.md` (commit `71f2152ee16b84d7b5e76836d23374ac1df41475`; verified blob `2cad1f871eac70e0f00820c17510027ec9bcdd2d`). It records the server-authenticated principal contract, scope validation, same-connection/top-level-XID transaction sequence, transaction-local token installation, conceptual least-privilege PostgreSQL roles, connection-pool compatibility requirements, revocation semantics, key algorithm options, and implementation acceptance tests.
- ADR-007 remains **Proposed**. It deliberately does not finalize Laravel/session/API auth, Sanctum, session store, HMAC versus asymmetric signing, production database role names, pooler mode, or immediate revocation inside an already-running transaction.
- Linked ADR-007 from `docs/05-security/TRUSTED-CONTEXT-ISSUER-DESIGN.md` (commit `a468900833ab9d0eb2f94df6ee6a4466ff485862`; verified blob `a355652134cd1ea09f56635fd9d31cd8bd2c9547`).
- Next: review ADR-007 with Product Owner/security; then build a database-only PoC for role switching issuer executor → query role on one connection and one top-level XID, including rollback/exception/connection reuse and pooler behavior. Do not write Laravel signer code until stack/auth decisions and Stage E bootstrap are approved.
- No application code, production migration, production DB role, or new server credential was created. All database work remains restricted to `sinau_design_poc`; do not touch `sinau`, `sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.


### Same-transaction role-switch PoC prepared — 2026-11-19
- Added `docs/03-database/poc/012-test-issuer-query-role-switch.sql` (commit `788f230c6cce375e39c0b42c526027ca065f6e78`; verified blob `f9d430518e12264408d5be51ba46917b5f7d77fe`). It is guarded to `sinau_design_poc` and session/current user `sinau_poc`; it performs no persistent DDL or application-row writes. It tests switching issuer executor → RLS query → issuer executor in one explicit transaction while retaining the same top-level XID and transaction-local probe, then ROLLBACK and checks cleanup.
- Documented the runbook in `docs/03-database/poc/README.md` (commit `8c1f7c3515b480fda8803205cf32f01290e97e2a`) and added it as the next gate in ADR-007 (commit `058b44de299f7dd0c764fafbc65281829c0d6618`). The SQL has been checked statically but **has not been executed**; do not record it as passed until actual PostgreSQL output is supplied.
- Next user action: stage script 012 under `/run` with owner postgres/mode 0600, open psql against `sinau_design_poc`, `SET SESSION AUTHORIZATION sinau_poc`, and run the script in that session. This is still a direct-session role/XID test, not a real Laravel/PgBouncer pooler test.
- No application code, production migration, production DB role, or server credential was created. Do not touch `sinau`, `sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.


### Same-transaction role-switch PoC passed — 2026-11-19
- Executed `docs/03-database/poc/012-test-issuer-query-role-switch.sql` on PostgreSQL 18.7 with session authorization `sinau_poc`, database guard `sinau_design_poc`. It passed issuer → query → issuer role transitions within one explicit transaction. The allocated top-level XID remained `890` across both role switches; the issuer could execute the narrow validator but not read memberships directly; the query role could execute the RLS accessor but could not execute the issuer validator or read membership/key tables.
- The script ended with `ROLLBACK`; PostgreSQL confirmed session authorization/current role returned to `sinau_poc` and transaction-local probe state was cleared. Final notice: `ROLE SWITCH / XID CONTINUITY TESTS PASSED — TRANSACTION ROLLED BACK`.
- This proves role-switch and XID continuity on one direct PostgreSQL connection. It is not evidence for PgBouncer/Laravel pool behavior, actual signed-token issuance within this role-switch flow, or production privileges.
- Next: test transaction-local `app.context_token` and `SET LOCAL ROLE` cleanup after both COMMIT and ROLLBACK on the same psql connection; then test a fresh transaction with no token remains fail-closed. Pooler tests require the selected deployment topology and remain a later gate.
- No production database `sinau`, role `sinau_app`, SQLRadius, MikroTik, production credentials, application migrations, or application code were changed. PR #1 remains Draft/open/unmerged.


### Transaction-local cleanup PoC prepared — 2026-11-19
- Added `docs/03-database/poc/013-test-context-and-role-cleanup.sql` (initial commit `449dffc5800353cfca58de0a33a9a561c96bd774`; final reviewed blob `ee6e46022e3f057fc2d4057d2a06a8a17a57fa1f`). It tests invalid synthetic `app.context_token` markers under the RLS query role, fail-closed visibility, and cleanup of `app.context_token` plus `SET LOCAL ROLE` after both COMMIT and ROLLBACK; it also checks a fresh transaction on the same connection has no context and sees zero academic rows. It creates no persistent DDL and performs no application-row writes.
- Static review confirmed the database/session guards, COMMIT/ROLLBACK cleanup checks, fresh-transaction fail-closed assertion, and final transaction rollback. The script has **not yet been executed** on the server.
- Updated `docs/03-database/poc/README.md` (commit `53a2e1cc4a2c791f8d81fb82e835159375ecd4bb`) and ADR-007 (commit `0688bb7aa390ad144fc2ca530ba8c7f6bed08521`) with the next runbook/gate.
- Next user action: stage 013 under `/run` with owner postgres/mode 0600, then run it in an interactive psql session against `sinau_design_poc` after `SET SESSION AUTHORIZATION sinau_poc`. Do not run it against production.
- No production database `sinau`, role `sinau_app`, SQLRadius, MikroTik, application migration, production role, or new server credential was touched. PR #1 remains Draft/open/unmerged.


### Transaction-local cleanup PoC passed — 2026-11-19
- Executed `docs/03-database/poc/013-test-context-and-role-cleanup.sql` on PostgreSQL 18.7 in one interactive session against `sinau_design_poc`, with session authorization `sinau_poc`.
- COMMIT path passed: the deliberately invalid synthetic `app.context_token` did not verify and exposed zero rows from `public.academic_years`; after COMMIT, PostgreSQL confirmed `app.context_token` was empty and `SET LOCAL ROLE` had restored `sinau_poc`.
- ROLLBACK path passed: the invalid marker exposed zero academic rows; after ROLLBACK, `app.context_token` was empty and session/current role returned to `sinau_poc`.
- A fresh transaction on that same connection, without a token, had zero verified context and zero visible academic rows. Final notice: `CONTEXT AND ROLE CLEANUP TESTS PASSED — COMMIT/ROLLBACK COMPLETE`.
- This proves direct-session transaction-local GUC and role cleanup across COMMIT/ROLLBACK plus same-connection reuse. It does not prove behavior under PgBouncer, Laravel/PDO, persistent application connections, worker cancellation, or real request exceptions.
- Next: add a controlled SQL-error/aborted-transaction test that requires rollback and then checks a fresh transaction on the same connection. Pooler integration remains pending until the deployment pooler topology is selected.
- No production database `sinau`, role `sinau_app`, SQLRadius, MikroTik, application migration, production role, or server credential was touched. PR #1 remains Draft/open/unmerged.


### Aborted transaction recovery PoC prepared — 2026-11-19
- Added `docs/03-database/poc/014-test-aborted-transaction-recovery.sql` (commit `073bbccd5131bc9068858c671ba51f79324d2cfd`; reviewed blob `3aac957df0a804cf062946db9ff7dea80c579c6d`). It installs an invalid transaction-local context marker, switches to the query role, deliberately triggers division-by-zero (SQLSTATE 22012), checks that psql observed the expected error, rolls back the aborted transaction, verifies context/role cleanup, and reuses the same connection for a fresh fail-closed transaction. It creates no persistent DDL and performs no application-row writes.
- Added its runbook to `docs/03-database/poc/README.md` (commit `fa635a1cfd259e805e858cd791f29f90334d05a5`) and moved ADR-007's next gate to test 014 (commit `10118c77ce9a41d81aced7b5de8cf735299dd6c5`).
- Static review confirms database/session guards, explicit SQLSTATE 22012 detection, rollback after the aborted statement, same-connection reuse, and final cleanup checks. Script 014 has **not yet been executed** on the server. The expected division-by-zero error is deliberate; the pass condition is that psql detects it and the rest of the script completes.
- Next user action: stage 014 under `/run` with owner postgres/mode 0600, run inside an interactive psql session on `sinau_design_poc` after `SET SESSION AUTHORIZATION sinau_poc`. Do not run it against production.
- No production database `sinau`, role `sinau_app`, SQLRadius, MikroTik, app migration, production role, or server credential was touched. PR #1 remains Draft/open/unmerged.


### Aborted transaction recovery PoC passed — 2026-11-19
- Executed `docs/03-database/poc/014-test-aborted-transaction-recovery.sql` on PostgreSQL 18.7 in an interactive psql session against `sinau_design_poc`, after setting session authorization to `sinau_poc`.
- The controlled `SELECT 1 / 0` raised the expected `division by zero` error (SQLSTATE `22012`), and the psql script detected it as the expected condition. After ROLLBACK, session/current role returned to `sinau_poc` and the transaction-local `app.context_token` was empty.
- The same direct PostgreSQL connection then started a fresh transaction as `sinau_rls_test`; no verified context was present and zero academic rows were visible. Final notice: `ABORTED TRANSACTION RECOVERY TESTS PASSED — SAME CONNECTION REUSED`.
- This verifies recovery after an aborted SQL transaction on one direct psql connection. It does not verify a Laravel/PDO exception handler, PgBouncer, network disconnect, cancellation, or a production connection pool.
- Next: perform a read-only environment check for an installed/configured PgBouncer or other pooler, without reading credentials or changing services. Do not create a pooler or alter the PostgreSQL topology before the deployment choice is approved.
- No production database `sinau`, role `sinau_app`, SQLRadius, MikroTik, application migration, production role, or server credential was touched. PR #1 remains Draft/open/unmerged.


### Read-only pooler inventory completed — 2026-11-19
- Read-only command inventory found no `pgbouncer`, `pgcat`, or `odyssey` binary; `pgbouncer.service` reported `inactive`; and no matching pooler service unit was listed.
- Follow-up listener check `sudo ss -lntp | grep -E ':(6432|6433)\\b'` returned no output. Therefore no listener was observed on ports 6432 or 6433 at the time of the check. This does not exclude a pooler on a nonstandard port, a remote pooler, or a process hidden by namespace/network boundaries.
- Inventory conclusion: no local PgBouncer/PgCat/Odyssey installation or common 6432/6433 listener was detected. No package was installed, no service/configuration was changed, and PostgreSQL topology remains unchanged.
- Next: do not install a pooler on this server just for the PoC. Once the owner selects an application deployment topology, build a disposable/lab PgBouncer transaction-pooling test (or test the actual approved managed pooler) and verify one explicit transaction pins XID allocation, issuer validation, role switching, token installation, and protected SQL to one backend connection. Include commit/rollback, aborted transaction, and connection reuse.
- No production database `sinau`, role `sinau_app`, SQLRadius, MikroTik, app migration, production role, or server credential was touched. PR #1 remains Draft/open/unmerged.

### Resource constraint — pooler deferred, no new server required — 2026-11-19
- Owner confirmed there is no spare resource for a separate test server. No new server is required for the SINAU PoC or the next application-bootstrap planning step; all existing database tests have used the current PostgreSQL server and isolated database `sinau_design_poc`.
- Decision for the current phase: do not provision another server and do not install PgBouncer/PgCat/Odyssey on the existing host. Continue with direct PostgreSQL connections and same-connection explicit transactions. This is a resource-constrained working recommendation, not a final performance/capacity decision.
- Updated ADR-007 to defer connection pooling until real workload/capacity measurements justify it and the owner approves. Pooler testing is optional/later, not a blocker for proceeding with authentication and application design.
- No package/service/configuration was changed. Production database `sinau`, role `sinau_app`, SQLRadius, and MikroTik remain untouched. PR #1 remains Draft/open/unmerged.


### Application stack and web auth baseline accepted — 2026-11-19
- Product Owner instructed to proceed with the proposed Laravel 13 + Vue 3 + Inertia web bootstrap. ADR-005 is now Accepted for the initial web application shell: PHP 8.4 baseline, official Laravel Vue starter kit (Vue 3 Composition API, TypeScript, Inertia 3, Tailwind 4, shadcn-vue), Fortify, PostgreSQL 18, direct DB connections, and no Redis/PgBouncer/VPS requirement. Runtime and extension compatibility still require host preflight.
- Added ADR-008 `docs/09-decisions/ADR-008-AUTHENTICATION-AND-SESSION.md` (commit `9bfd22edf30cef49d2913a55e4bf474537b813a1`; verified blob `6c1585887d2da93d1f3ad0d2e7013c7adad3c82e`). It specifies global-user-only registration, email verification before tenant/unit onboarding, Fortify-backed same-origin sessions, database session driver, cookie/session controls, optional 2FA, no Laravel Teams, no API bearer auth in the initial bootstrap, and the trusted principal boundary.
- Added `docs/00-governance/APP-BOOTSTRAP-RUNBOOK.md` (latest runbook fix commit `dcc9f82d56f8b725e3c19e8f2799583f4a405638`) and read-only host check script `scripts/check-sinau-bootstrap-host.sh` (commit `b2e1dcb26a31c8eae798e5817cc0fb1a9bf4e15c`). The script only reports PHP/extensions, Composer, Node/npm, Git, PostgreSQL client, disk/memory, and path presence; it installs nothing and changes no service.
- Updated `DECISION-LOG.md` (commit `3da88cf10b9bed1135a07b113820ade173d05d3a`), `IMPLEMENTATION-PLAN.md` (commit `edad321a70ca50982c28b4f5a48adac51d4aeb0a`), and `README.md` (commit `07a187f8b51fec793df63f7d822fa48b3be3bbc2`). Stage E0 is now an application shell bootstrap only; tenant/unit/membership/domain migrations remain gated.
- Application scaffold has **not yet been generated**. Next user action: run the read-only preflight script from `~/sinau-poc` and send its complete output. Only after confirming PHP 8.4, required extensions including `pdo_pgsql`, Composer, Node/npm, and available disk/memory should we generate the official Vue starter kit into a separate temporary directory and merge it into the SINAU checkout. Do not install packages or create databases/roles before that review.
- Never use `sinau_design_poc` as the application DB. Proposed application PoC database name is `sinau_app_poc`, separate on the same PostgreSQL host; it has not been created. No production database `sinau`, role `sinau_app`, SQLRadius, or MikroTik was accessed or modified. PR #1 remains Draft/open/unmerged.


### Host preflight passed for PHP/database stack; Node is the only bootstrap blocker — 2026-11-19
- Read-only preflight run on the existing host: PHP 8.4.27, Composer 2.8.8, PostgreSQL client 18.7, all required PHP extensions present including `pdo_pgsql`; Git/curl/rsync available. Disk: 16 GB free of 18 GB; RAM available: 7.3 GiB; swap unused. No SINAU checkout or temporary Laravel scaffold exists yet. The reported `SQLRADIUS_PATH_PRESENT=no` is a path check only; no SQLRadius directory was changed.
- Node.js and npm are absent. No packages/services were changed by the preflight.
- Selected Node.js 24.22.3 LTS installed per-user via NVM v0.41.0, not through APT/global npm and not as a service. This satisfies Vite+ 1.x supported Node range (Node 24.11+). Official Node release page lists v24 as LTS and v24.22.3 as current patch; Vite+ release notes state supported CLI ranges include `^24.11.0`. See Node.js releases and Vite+ 1.4 release notes.
- Added NVM installation instructions to `APP-BOOTSTRAP-RUNBOOK.md` (commit `4c84b9a487da38debf8d86f67f81ced92e51d4f1`) and recorded Node baseline in ADR-005 (commit `def57564ef2f3e9300c49de4d3950fea4ce94447`).
- Next user action: install NVM/Node 24.22.3 as `sinauadmin` without sudo, then report `node --version`, `npm --version`, `command -v node`, and `command -v npm`. Do not run a global npm install. After that, clone the SINAU branch into `$HOME/SINAU`, generate official Vue starter kit into the separate `$HOME/sinau-laravel-bootstrap` path, and merge it carefully while retaining docs.
- Application scaffold remains ungenerated. Do not create `sinau_app_poc` database/role or run migrations until Node/toolchain, scaffold, and database isolation plan have been reviewed. Never use `sinau_design_poc` as app DB and never touch production `sinau`/`sinau_app`, SQLRadius, or MikroTik. PR #1 remains Draft/open/unmerged.


### Node.js LTS installed for sinauadmin — 2026-11-19
- User installed NVM v0.41.0 and Node.js v24.22.3 under `/home/sinauadmin/.nvm`; npm v11.19.1 is bundled. Checksums matched during download. `node` resolves to `/home/sinauadmin/.nvm/versions/node/v24.22.3/bin/node`; npm resolves from the same NVM installation. No sudo/global APT Node installation was used.
- PHP 8.4.27, Composer 2.8.8, pdo_pgsql, required PHP extensions, disk (16 GB free), and memory (7.3 GiB available) passed the earlier read-only preflight.
- Updated the bootstrap runbook (latest commit `b6f5fbceb720280c35391c8c297573b0cfd9c296`) to use explicit Laravel installer flags `--vue --pest --no-boost --no-node`, no Teams/WorkOS, and a temporary installer SQLite database only for starter-kit initialization. The actual SINAU application database remains a separate PostgreSQL PoC database and has not been created.
- Next user action: clone branch `feature/phase-0-requirements-blueprint` into `$HOME/SINAU` (preflight confirmed the path did not exist), install Laravel installer per-user using Composer, add Composer's global bin directory to PATH, and verify `laravel --version`. Then create scaffold in `$HOME/sinau-laravel-bootstrap`.
- Application scaffold has not yet been generated. No `sinau_app_poc` DB/role exists, and no app migrations were run against PostgreSQL. Production `sinau`/`sinau_app`, SQLRadius, and MikroTik remain untouched. PR #1 remains Draft/open/unmerged.


### Laravel Vue starter scaffold generated — 2026-11-19
- User successfully cloned the SINAU branch into `/home/sinauadmin/SINAU`; installed Composer-global Laravel Installer v5.33.0. The installer created the separate temporary scaffold at `/home/sinauadmin/sinau-laravel-bootstrap`.
- Composer lint, Wayfinder generation, and Pest setup completed. Laravel installer reported its database migration step failed.
- User's read-only checks show `DB_CONNECTION=sqlite`, `pdo_sqlite=MISSING`, `sqlite3=MISSING`, `pdo_pgsql=AVAILABLE`, and an empty `database/database.sqlite` file. This explains why SQLite migration cannot run. Do not install new services or redirect this scaffold at `sinau_design_poc` or production. Defer app DB migration until the dedicated PostgreSQL application PoC database `sinau_app_poc` and least-privilege role are reviewed and created.
- The user config currently contains Fortify declarations for registration, email verification, two-factor authentication, and passkeys. Review the exact config before deciding whether to disable the latter two; do not silently change authentication features.
- Next: inspect the exact Laravel log exception and Fortify feature block; then review scaffold files and `.gitignore` before selectively merging source into `~/SINAU`. Keep `.env`, generated APP_KEY, vendor, node_modules, and temporary SQLite artifacts out of Git.
- No app schema was migrated to PostgreSQL. No change to SQLRadius, MikroTik, production `sinau`/`sinau_app`. PR #1 must remain Draft/open/unmerged.


### Laravel scaffold diagnostic details — 2026-11-19
- The uploaded terminal output confirms Laravel log exception `could not find driver` for the SQLite connection to `database/database.sqlite`; PDO SQLite extensions are absent. This is the exact migration failure. The SQLite file is empty (0 bytes); no PostgreSQL migration was run.
- Fortify config has registration, reset-passwords, email verification, TOTP two-factor authentication (with confirmation), and Passkeys. Re-read ADR-008: it explicitly accepts optional TOTP 2FA for bootstrap; do not remove the TOTP feature. Passkeys remains an open design decision in ADR-008 and should be disabled in initial bootstrap pending a separate design/review.
- Updated `APP-BOOTSTRAP-RUNBOOK.md` to clarify TOTP 2FA is optional and should be tested, while Passkeys stays disabled until separately designed. Runbook change commit `d0e8613ab8b3044751792e1053429bed2798796b`.
- Next local action: remove only the `Features::passkeys([...]),` entry from `config/fortify.php`, preserve `Features::twoFactorAuthentication([...])`, `Features::emailVerification()`, registration, and password reset. Then verify PHP syntax and the resulting feature block. Do not edit `.env` or reveal APP_KEY.
- `.env` exists and contains a generated application key; it must remain private and untracked. `.env.example`, `.gitignore`, Composer/package manifests and source files require review before selective merge into SINAU.


### Fortify bootstrap feature set verified — 2026-11-19
- User successfully removed only `Features::passkeys([...])` from the temporary Laravel scaffold `config/fortify.php`. `php -l config/fortify.php` passed. Verified remaining Fortify feature declarations: registration, password reset, email verification, and TOTP two-factor authentication. TOTP was preserved per accepted ADR-008; passkeys is deferred.
- The change is currently in the temporary scaffold only. Backup was created at `/tmp/sinau-fortify.php.before-passkeys-change`. Do not copy `.env`, APP_KEY, empty temporary SQLite DB, `vendor/`, or runtime files into Git.
- Next: update local SINAU checkout via fetch + fast-forward only (remote branch now has subsequent governance commits), inspect `.gitignore`, `composer.json`, `package.json`, and key root directories in temporary scaffold, then plan a selective merge. No app migrations to PostgreSQL have been run.


### Scaffold manifest and checkout review — 2026-11-19
- User's local checkout `~/SINAU` fast-forwarded cleanly from `4b2ee0f` to `a4ed3f9`; current working tree was clean after update.
- Scaffold inventory reviewed from user output. `composer.json`: PHP `^8.3`, Laravel Framework `^13.17`, Inertia Laravel `^3.0`, Fortify `^1.37.2`, Wayfinder `^0.1.14`, Pest 5. `package.json`: Vue `^3.5.13`, Inertia Vue 3, Tailwind 4, TypeScript, Vite+ 1.4. Host PHP 8.4.27 and Node 24.22.3 meet the declared runtime baselines.
- `.gitignore` ignores `.env`, vendor, node_modules, public/build and other local tooling, but the temporary `database/database.sqlite` file is not explicitly excluded in the displayed root ignore file. Runbook rsync now explicitly excludes it. Do not copy `.env`, APP_KEY, vendor/, node_modules/, generated frontend bundles, or runtime logs.
- `package.json` still declares `@laravel/passkeys` even though the Fortify passkeys feature was removed from `config/fortify.php`. Inspect actual code references before removing dependency. `pnpm-workspace.yaml` and `.npmrc` exist, no package lockfile appeared in root file listing; inspect package manager settings before choosing npm install.
- `composer.json` contains a `setup` script that runs `artisan migrate --force` and npm install/build; do not run `composer run setup`. Runbook updated to make this explicit and exclude `database/database.sqlite` (commit `98835f0b81ec1cecc96c8712d7b42782b167aecf`).
- Next: inspect `.npmrc`, `pnpm-workspace.yaml`, package-lock/pnpm lock status, `@laravel/passkeys` references, scaffold directory structure and embedded .gitignore files. Then selectively copy the scaffold to `~/SINAU` with a dry-run first, preserving existing docs and excluding all secrets/runtime artifacts.


### Passkeys surface and package-manager inventory — 2026-11-19
- User fast-forwarded local checkout `~/SINAU` to `8704481` and ran scaffold package-manager/code inventory.
- Scaffold `.npmrc` contains `ignore-scripts=true`. `pnpm-workspace.yaml` declares one root package; there is no package lockfile in the root listing. Do not install frontend dependencies until the package manager, scripts policy, and lockfile strategy are reviewed. Avoid casually toggling `ignore-scripts` because lifecycle scripts are a supply-chain/security boundary.
- Passkeys are integrated in more than Fortify's feature array: `app/Models/User.php` implements `PasskeyUser` and uses `PasskeyAuthenticatable`; `app/Providers/FortifyServiceProvider.php` defines a passkey limiter; `SecurityController.php` calls `Features::canManagePasskeys()` and queries passkeys; `resources/js/pages/settings/Security.vue`, `Login.vue`, and `ConfirmPassword.vue` import passkey components; generated `resources/js/routes/passkey/index.ts` contains passkey routes. The JS dependency `@laravel/passkeys` is therefore referenced by actual UI and must not simply be removed from `package.json` before all associated code paths are resolved.
- The Fortify feature array no longer registers Passkeys, but generated starter code has passkey-specific routes/components/models still present. Before treating passkeys as disabled, inspect provider route registration, the User model, migrations, controllers, components, generated route helpers, and composer/npm dependencies. Keep TOTP (`TwoFactorAuthenticatable` and `Features::twoFactorAuthentication`) intact.
- No scaffold merge, npm/pnpm install, or PostgreSQL migration has occurred. Runbook must preserve explicit SQLite exclusion and prohibit `composer run setup` at this stage.


### Fortify and Passkeys package relationship verified — 2026-11-19
- Detailed source review shows `laravel/passkeys` is a required dependency of current Laravel Fortify 1.x (`laravel/fortify` requires `laravel/passkeys ^0.3.0`), so keep the PHP package as a transitive dependency; do not try to remove it from Composer while Fortify remains. The frontend npm package `@laravel/passkeys` can be reviewed separately after all Vue imports/components are removed.
- `Laravel\Passkeys\PasskeysServiceProvider` registers the package routes only when `Passkeys::shouldRegisterRoutes()` returns true. `Passkeys::ignoreRoutes()` sets this flag false. To prevent all package endpoints while retaining Fortify/TOTP, call `Passkeys::ignoreRoutes()` during application provider registration (before providers boot), then regenerate Wayfinder files after the route table is verified.
- Keep `TwoFactorAuthenticatable` model trait and Fortify `Features::twoFactorAuthentication()`; remove only passkey interface/trait, passkey limiter, controller props/query, Vue imports/components, passkeys migration, and stale generated helpers if no route remains.
- Before applying edits, inspect `app/Providers/AppServiceProvider.php`, `bootstrap/providers.php`, `composer why laravel/passkeys`, all Passkey component imports, and the passkeys migration content. No local files changed by this diagnosis.


### Safe Passkeys disable procedure documented — 2026-11-19
- User's dependency inspection confirms `laravel/fortify v1.43.0` requires `laravel/passkeys ^0.3.0`; retain PHP package as transitive dependency. Do not remove it from Composer.
- `Passkeys::ignoreRoutes()` is available on package facade/class and prevents the PasskeysServiceProvider from loading package routes; calling it in `AppServiceProvider::register()` makes the flag false before provider boot.
- Planned cleanup retains TOTP: `TwoFactorAuthenticatable`, `Features::twoFactorAuthentication()`, TOTP routes/views. Remove Passkeys User interface/trait, app rate limiter, SecurityController passkey props/query, Vue imports/components, package migration, generated Wayfinder route/action helpers, and JS dependency `@laravel/passkeys` after imports are removed. No DB migration has been run; deleting the unused passkey migration is safe in this uninitialized scaffold.
- Updated runbook with these steps and verification requirements in commit `85aae91f76edf39c5a58a9013572a68247a7fd73`.
- Next local task: apply the asserted backup-first patch to the temporary scaffold, regenerate Wayfinder, verify `route:list` has no Passkeys routes while TOTP remains, and grep app/frontend source for dangling references. No actual patch has yet been applied to user files as of this record.


### Residual W3C Passkeys discovery route identified — 2026-11-19
- After the application Passkeys source cleanup, `php artisan route:list --path=passkey` showed one remaining route: `GET /.well-known/passkey-endpoints`, sourced from `routes/settings.php:29`. Nine `two-factor` routes remained present.
- Verified the official `laravel/vue-starter-kit` `routes/settings.php`: this route sits inside the `/* @chisel-passkeys */ ... /* @end-chisel-passkeys */` block and advertises `security.edit` as enroll/manage URLs. It should be removed while Passkeys are deferred. The URL is defined by the W3C Passkey Endpoints Working Draft as a discovery document for passkey support and management URLs; removing it avoids advertising a feature that is not enabled.
- Updated `APP-BOOTSTRAP-RUNBOOK.md` to require removing the `@chisel-passkeys` block in addition to suppressing package routes (commit `26321f9d30fe0f4ec72b138fa957dad4c9d3dea0`).
- Next local action: remove exactly the marked `@chisel-passkeys` block from `routes/settings.php`, regenerate Wayfinder, verify `route:list --path=passkey` is empty and `route:list --name=two-factor` still shows the expected endpoints. Then update local checkout before subsequent work. No database migrations or PostgreSQL changes.


### Passkeys discovery route marker mismatch — 2026-11-19
- User's local `routes/settings.php` does not contain the `@chisel-passkeys` marker comments expected by the initial safe-delete script; that script aborted and made no change. The discovery route remains at line 29 and generated Wayfinder still has `resources/js/routes/well-known/index.ts`.
- Next: remove exactly the one route definition bounded by `Route::get('.well-known/passkey-endpoints'` and `})->name('well-known.passkeys');`, after asserting each boundary occurs exactly once; then lint, clear route cache, verify discovery route is absent and all nine TOTP routes persist, and only then regenerate Wayfinder.


### Passkeys discovery endpoint removed and TOTP routes reverified — 2026-11-19
- User successfully removed the route definition `/.well-known/passkey-endpoints` from temporary scaffold `routes/settings.php` using exact path/name boundary checks. A backup was created under `/tmp/sinau-settings-route-20261119-135416.php`.
- `php -l routes/settings.php` passed; `php artisan route:clear` succeeded. `php artisan route:list --path=passkey` reports no matching routes. Regenerated Wayfinder successfully and grep across `routes` and `resources/js` found no `well-known.passkeys` or `well-known/passkey-endpoints` references.
- `php artisan route:list --name=two-factor` still shows all nine expected TOTP routes. Previous PHP syntax checks passed; `User` continues to implement `TwoFactorAuthenticatable`, and Fortify config retains `Features::twoFactorAuthentication()`.
- Passkeys route suppression via `Passkeys::ignoreRoutes()` is active in `AppServiceProvider::register()`. PHP `laravel/passkeys` package remains as required Fortify dependency; frontend package was removed from `package.json`, and Passkeys UI/controller/model references were cleaned earlier. Further broad residual-source grep should be run before the scaffold merge.
- No PostgreSQL migrations, dependency installation, or scaffold merge have occurred. `sinau_app_poc` remains uncreated. Next step: run full residual Passkeys grep, verify frontend/build manifests and gitignore, then do rsync dry-run before a real selective copy.


### Final residual Passkeys and artifact audit — 2026-11-19
- User's final residual grep found only intentional PHP package route suppression in `AppServiceProvider.php`, generated Composer package provider cache files under `bootstrap/cache`, Fortify's own `config/fortify.php` Passkeys config section, and orphan UI artifacts `resources/js/components/PasskeyItem.vue` plus `resources/js/types/auth.ts` Passkey type. The generated Wayfinder passkey route/action files were no longer present. `@laravel/passkeys` frontend dependency is absent. `composer validate --no-check-publish` and `package.json` JSON parse passed.
- Keep `Laravel\Passkeys\Passkeys::ignoreRoutes()` and the Fortify-transitive PHP package. Do not delete `bootstrap/cache` provider entries manually; these are generated from installed Composer packages and are excluded from the rsync plan. Inspect Fortify config's unused passkeys settings before deciding whether to remove only that config sub-block; leave package configuration untouched if Fortify still expects it.
- Next: inspect `PasskeyItem.vue`, the full `types/auth.ts`, and all imports of `@/types/auth` / `PasskeyItem`; remove orphan component and only the unused Passkey type (preserve any other shared types). Add `/database/database.sqlite` to root `.gitignore` before merge. Runbook updated accordingly in commit `ddd4c006d999224c3039d131ef0d04e648e01e4f`.
- Do not run composer update/install, npm/pnpm install, setup script, or migrations until package-manager policy and database separation are approved. Then produce rsync dry-run only.


### Orphan Passkey UI and auth type cleanup identified — 2026-11-19
- User's latest source inspection confirms `resources/js/types/auth.ts` exports `User`, `Auth`, `Passkey`, and `TwoFactorConfigContent`. Only `Auth` is imported elsewhere (`resources/js/types/global.d.ts`); `Passkey` is referenced only by the orphan `resources/js/components/PasskeyItem.vue`. The component is not imported elsewhere after the prior page cleanup. Remove that component and only the `Passkey` type block; preserve the other auth types.
- Fortify default config contains dormant passkeys keys (`limiters.passkeys` and a `passkeys` settings array), while no `Features::passkeys()` declaration exists. Leave these defaults intact for now; active routes are suppressed via `Passkeys::ignoreRoutes()` and the feature is not enabled. Do not remove the transitive PHP package.
- Root scaffold `.gitignore` does not currently list `database/database.sqlite`; add `/database/database.sqlite` before merge. The temporary file is 0 bytes, and must not be copied/committed.
- Next: backup-first cleanup of orphan `PasskeyItem.vue` + only the `Passkey` type, add SQLite ignore rule, rerun JS/grep checks, then proceed to rsync dry-run. No actual scaffold merge or DB migration yet.


### Final Passkeys frontend residue removed and SQLite ignored — 2026-11-19
- User successfully removed orphan `resources/js/components/PasskeyItem.vue` and only the unused `Passkey` type from `resources/js/types/auth.ts`. Remaining shared exports `User`, `Auth`, and `TwoFactorConfigContent` were preserved. Grep for `PasskeyItem|PasskeyRegister|PasskeyVerify|types/auth.*Passkey|Passkey =` across Vue/TS returned no matches.
- Added `/database/database.sqlite` to scaffold root `.gitignore`; the temporary SQLite database remains empty and excluded. `composer validate --no-check-publish` reports `./composer.json is valid`.
- Full scaffold Passkey cleanup status: package routes suppressed with `Passkeys::ignoreRoutes()`, starter-kit discovery route removed, Wayfinder regenerated, no passkey route/action helpers remain, app model/controller/frontend passkey implementations removed; PHP `laravel/passkeys` remains as transitive Fortify dependency; Fortify's dormant passkey configuration remains in config but no feature is enabled. TOTP retained with nine routes verified.
- Next: synchronize `~/SINAU` to current branch head, run `rsync --dry-run` only with explicit exclusions for `.env`, vendor, node_modules, runtime cache/log artifacts, and SQLite while preserving nested Laravel `.gitignore` placeholders; review complete dry-run output for collisions/additions. Do not perform actual rsync until list is reviewed.
- No dependency installs, app migrations, or scaffold merge have happened. Dedicated app database `sinau_app_poc` not created.


### First scaffold rsync dry-run reviewed — 2026-11-19
- User fast-forwarded local `~/SINAU` to commit `cca2f4e97c4b80693ddc338e9051b4f0f7af86e1`; working tree output was clean.
- `rsync -avni --ignore-existing` dry-run from `~/sinau-laravel-bootstrap/` to `~/SINAU/` completed with DRY RUN, proposing only additions. No `.env`, `vendor/`, `node_modules/`, `public/build/`, `bootstrap/cache/*.php`, storage logs/runtime cache, or `database/database.sqlite` appeared. It proposes app shell files, manifests, Vue source, route/test files, `.env.example`, root `.gitignore`, `.github/dependabot.yml`, and `.github/workflows/tests.yml`.
- Read-only GitHub tree inspection at branch head confirms no Laravel app paths currently exist at repo root (`app`, `bootstrap`, `config`, `database`, `public`, `resources`, `routes`, `tests`, Composer/npm manifests absent). Existing `.github/workflows/` contains only `postgresql-poc.yml`; dry-run's `tests.yml` is a distinct addition. No expected app-path collisions detected at that remote head.
- Before real rsync, still inspect new `tests.yml` and `dependabot.yml` to ensure CI does not run migrations against an unintended database and check `.env.example` secret-like keys by printing only EMPTY/PLACEHOLDER/PRESENT status, not values. Also inspect package scripts/workflow for npm/pnpm assumptions. Then can approve selective merge, keeping `.env`, runtime, caches, and SQLite excluded.
- No actual rsync performed yet; dry-run has not modified files. No dependency install or migration.


### CI workflow and env example review — 2026-11-19
- User's CI review: `.github/workflows/tests.yml` uses immutable action SHAs and read-only `contents: read`; runs `composer setup` then `composer ci:check`. `composer setup` runs composer install, copies `.env.example`, creates APP_KEY, runs `artisan migrate --force`, `npm install`, and `npm run build`. These migrations happen on a disposable GitHub Actions runner, not on this host or production, but workflow must explicitly force `DB_CONNECTION=sqlite`, `DB_DATABASE=database/database.sqlite`, `APP_ENV=testing`, create the SQLite file, and enable pdo_sqlite/sqlite3. Keep pdo_pgsql extension in CI for target runtime coverage. No production DB secrets belong in Actions.
- CI uses Node `22`; correction to previous advice: Vite+ 1.4.0 supports Node `^22.18.0 || ^24.11.0 || >=26.0.0`, so Node 22 is compatible if current patch is >=22.18. Use Node 24.22.3 in CI for consistency with host. Sources checked: Vite+ 1.4.0 package engine range in lockfile evidence and release notes; official npm docs explain `ignore-scripts=true` suppresses dependency lifecycle scripts.
- `.env.example` secret-like variables were all empty/placeholders; current DB_CONNECTION is sqlite. Before commit it will be switched to `pgsql` and example DB name `sinau_app_poc`; CI must retain job-level SQLite overrides so `composer setup` cannot try PostgreSQL. The empty `database/database.sqlite` remains excluded from Git.
- Workflow's use of npm matches its `composer setup` script, but there is no package lockfile in the scaffold. Commit `package-lock.json` after first verified npm install/build to pin frontend dependencies; retain `.npmrc ignore-scripts=true` pending review rather than disabling it.
- Updated runbook with CI-specific isolated SQLite migration rules and Node compatibility note in commit `054341605d364b77f857798bbccecdd72342a002`. No actual rsync yet; no dependency install or local migration.


### CI isolation patch applied and validated — 2026-11-19
- User applied CI changes to `~/sinau-laravel-bootstrap/.github/workflows/tests.yml`: job env forces APP_ENV=testing, DB_CONNECTION=sqlite, DB_DATABASE=database/database.sqlite; PHP extension setup includes pdo_pgsql, pdo_sqlite, sqlite3; Node is 24.22.3; creates SQLite file before composer setup. `composer validate --no-check-publish`, package JSON parse, and `.gitignore` SQLite exclusion all passed.
- Verified Laravel 13 `SQLiteConnector::parseDatabasePath()` resolves an existing relative file from the job working directory or falls back to `base_path()`. For additional robustness, updated the runbook (commit `19ef99a7cf437c920dbe1384ff5abe08e3eb9b9f`) to recommend absolute `${{ github.workspace }}/database/database.sqlite` in job env and `touch "$DB_DATABASE"`.
- Next user action: apply the absolute workspace path to the local scaffold workflow, verify it, then sync checkout `~/SINAU` and repeat the dry-run with the updated workflow. The previous dry-run list was all new files with explicit exclusions; no actual rsync has been run.
- Before actual copy, change `.env.example` to PostgreSQL `DB_CONNECTION=pgsql`, `DB_DATABASE=sinau_app_poc`, `DB_HOST=127.0.0.1`, port 5432, username placeholder and password placeholder; CI job-level env overrides must still force SQLite. Set `SESSION_DRIVER=database`, `SESSION_CONNECTION=pgsql` if the generated config supports it (otherwise same default connection); do not create DB/role or run migration yet.


### Second scaffold rsync dry-run reviewed — 2026-11-19
- User synchronized the local SINAU checkout to `a0850fb` via fast-forward and repeated the rsync dry-run after local CI workflow path hardening. Dry-run completed successfully with DRY RUN, proposing root manifests, Laravel app/config/database/public/resources/routes/storage/tests and a new `.github/workflows/tests.yml`; no file was actually copied.
- Existing GitHub repo tree at previous read-only inspection contained no Laravel app folders or Composer/npm files, and existing `.github/workflows/postgresql-poc.yml` does not collide with new `tests.yml`. `--ignore-existing` keeps existing README and project docs.
- Exclusions remained effective for `.env`, `.env.*.local`, `.env.backup`, `.env.production`, `vendor/`, `node_modules/`, `public/build/`, `public/hot`, storage logs/runtime content, `bootstrap/cache/*.php`, and `database/database.sqlite`.
- Before actual merge, adjust `.env.example` from SQLite to PostgreSQL application PoC values: DB_CONNECTION=pgsql, DB_HOST=127.0.0.1, DB_PORT=5432, DB_DATABASE=sinau_app_poc, username placeholder and blank/placeholder password. Verify `config/session.php` uses database session and supports SESSION_CONNECTION; inspect whether migration creates `sessions`, `cache`, and `jobs` tables. CI must continue overriding DB_CONNECTION and DB_DATABASE to SQLite with an absolute workspace path.
- No actual rsync performed, no app dependencies installed, and no migration. Production, `sinau_design_poc`, SQLRadius and MikroTik untouched.


### Session migration and PostgreSQL example pre-merge review — 2026-11-19
- Laravel 13 starter config confirms session driver default is `database`, session connection reads `SESSION_CONNECTION`, and the users migration creates the `sessions` table alongside users/password_reset_tokens. Cache migration creates `cache` and `cache_locks`; jobs migration creates jobs, job_batches, failed_jobs. Therefore database session/cache/queue migrations exist in the scaffold.
- Before merge, set `.env.example`: `DB_CONNECTION=pgsql`, `DB_HOST=127.0.0.1`, `DB_PORT=5432`, `DB_DATABASE=sinau_app_poc`, `DB_USERNAME=sinau_app_poc_app` as a proposed placeholder role name, `DB_PASSWORD=` empty pending provisioning, and `SESSION_CONNECTION=pgsql`. Preserve `SESSION_DRIVER=database`, `SESSION_LIFETIME=120`, `SESSION_DOMAIN=null`, `SESSION_HTTP_ONLY=true`, `SESSION_SAME_SITE=lax`. Keep `SESSION_ENCRYPT=false` until compatibility is tested, and set `SESSION_SECURE_COOKIE=true` only in HTTPS environment configuration.
- Important CI correction: because `.env.example` will explicitly set `SESSION_CONNECTION=pgsql`, GitHub Actions must override `SESSION_CONNECTION=sqlite` in job env in addition to DB_CONNECTION/DB_DATABASE. Use absolute `$`{{ github.workspace }} path for DB_DATABASE and `touch "$DB_DATABASE"` before composer setup. This prevents CI session storage from reaching app PostgreSQL.
- Updated runbook with the PostgreSQL example and explicit isolated session override for CI in commit `4aceff4bd11a474aa61edf93d8e8535fe5095fb9`.
- No `.env.example` edit, actual rsync, dependency installation, PostgreSQL DB/role creation, or migration has been performed yet.


### PostgreSQL example and CI session override validated locally — 2026-11-19
- User applied PostgreSQL app defaults to the temporary Laravel scaffold `.env.example`: APP_NAME=SINAU, DB_CONNECTION=pgsql, DB_HOST=127.0.0.1, DB_PORT=5432, DB_DATABASE=sinau_app_poc, DB_USERNAME=sinau_app_poc_app (proposed placeholder role), DB_PASSWORD empty; SESSION_DRIVER=database, SESSION_CONNECTION=pgsql, SESSION_HTTP_ONLY=true, SESSION_SAME_SITE=lax, SESSION_LIFETIME=120, SESSION_ENCRYPT=false, SESSION_PATH=/, SESSION_DOMAIN=null.
- User updated `.github/workflows/tests.yml` job environment with `SESSION_CONNECTION: sqlite` alongside `DB_CONNECTION: sqlite` and absolute workspace `DB_DATABASE`; `touch "$DB_DATABASE"` remains in the workflow. This keeps CI session storage isolated from the future application DB.
- Validation output: Composer manifest valid; package.json parses; grep confirms PostgreSQL/session values and CI overrides. Built-in migrations include sessions, cache, jobs, job_batches, failed_jobs; cache_locks is present in cache migration. Migration inspection was read-only.
- Local `~/SINAU` fast-forwarded to `35a14a1`. No scaffold files have been rsynced; no dependency install, PostgreSQL database/role creation, or migration was run. No production, design PoC, SQLRadius or MikroTik changes.

### Laravel scaffold copied into local repository — 2026-11-19
- User ran the approved rsync actual copy from `$HOME/sinau-laravel-bootstrap/` to `$HOME/SINAU/` using `--ignore-existing`, all previously reviewed safety exclusions, and `--itemize-changes`.
- Rsync completed successfully; output reports 336 new files copied. `git status --short` shows expected untracked Laravel scaffold paths including `.env.example`, Composer manifests, CI workflow, app/config/database/public/resources/routes/storage/tests.
- Post-copy checks passed: `.env` absent, `database/database.sqlite` absent, `vendor/` absent, `node_modules/` absent. No migration or Composer/npm install performed. Files remain local untracked; not committed or pushed. PR #1 remains draft/open/unmerged.

### Post-copy Laravel scaffold audit passed — 2026-11-19
- User pulled documentation through commit `68cbc47` and audited the copied Laravel scaffold in `~/SINAU`. Sensitive/runtime checks passed: no `.env`, no `database/database.sqlite`, no `vendor`, no `node_modules`; `.gitignore` ignores `.env`, vendor, node_modules, and temporary SQLite database.
- `.env.example` confirms SINAU PostgreSQL app DB defaults and DB-backed session settings; CI workflow confirms disposable SQLite overrides for DB_CONNECTION, absolute DB_DATABASE, and SESSION_CONNECTION, with Node 24.22.3.
- PHP syntax check passed for all PHP files under app/bootstrap/config/database/routes/tests. Composer manifest validates and package.json parses. Git status shows expected new scaffold paths remain untracked.
- Grep found only the intentional Passkeys::ignoreRoutes() import/call in AppServiceProvider and dormant Fortify limiter/config defaults. Earlier scaffold validation removed passkey routes/UI/model concerns; the package remains as Fortify transitive dependency. No route:list yet because vendor has not been installed.
- No Composer/npm dependency install, no migration, no database/role provisioning, and no commit/push of scaffold files. PR remains draft/open/unmerged.

### Dependency-install preflight passed — 2026-11-19
- Host preflight for the SINAU checkout reports 15 GiB free disk on an 18 GiB filesystem, inode usage 6%, 7.2 GiB available memory, 1 GiB swap unused, and 8 CPUs. No existing Composer/npm cache size was reported.
- Composer requirements: PHP ^8.3 and Laravel ^13.17. Composer scripts include `setup` which runs migrations and npm build; do not invoke `composer setup` on the host. `post-autoload-dump` runs `artisan package:discover`; a safe first install can use `composer install --no-scripts` and call package discovery explicitly afterward, with no migration.
- Frontend uses npm scripts `vp build`, `vp check`, `vue-tsc --noEmit`; 14 runtime and 9 dev dependencies. No package-lock exists. `.npmrc` reports `ignore-scripts=true`; retain this setting and use explicit `npm install --ignore-scripts --no-audit --no-fund`, followed by explicit build only after dependency review.
- Node/npm are v24.22.3/11.19.1. Git working tree contains the intended untracked Laravel scaffold. Dependency install not started; no migration/database provisioning.

### Runtime signed-context PostgreSQL PoC checkpoint — 2026-11-21

**Lingkup dan batas pengujian**
- Pengujian memakai database khusus `sinau_design_poc`, fixture sintetis, dan runtime login `sinau_app_runtime_poc`.
- Database `sinau`, role produksi `sinau_app`, SQLRadius, MikroTik, dan layanan produksi tidak diubah.
- Runtime login PoC bukan superuser, bukan owner tabel, tidak memiliki `BYPASSRLS`, menggunakan `NOINHERIT`, dan dibatasi HBA ke database PoC melalui TCP localhost/SCRAM. Membership ke issuer/query role memerlukan role switch eksplisit.
- Runtime tidak dapat membaca key table secara langsung. Hasil pemeriksaan juga menunjukkan runtime bukan anggota `sinau_context_owner`.

**Bukti pengujian**
- Laravel PDO runtime: 18 pemeriksaan berhasil. Koneksi PDO yang sama dipertahankan, issuer/query role dapat dipakai secara eksplisit, direct key/data access ditolak, context transaction-local dibersihkan pada commit/rollback, dan recovery setelah SQL error berhasil.
- Signed-context runtime: 36 pemeriksaan berhasil. Termasuk validasi issuer, key file permission check tanpa menampilkan secret, signature/MAC, expiry, future issue time, TTL, audience, unknown key ID, malformed token, replay lintas XID, serta fail-closed RLS.
- Revocation signing key pada `READ COMMITTED`: koneksi A dengan XID `913` awalnya menerima token dan melihat satu row fixture. Setelah revocation dari koneksi B, token ditolak dan RLS mengembalikan 0 row. Koneksi A kemudian rollback; key sintetis dipulihkan.
- Isolasi dua transaksi runtime: 11 pemeriksaan berhasil. Koneksi A dan B memakai PDO terpisah dengan XID `920` dan `921`. Token masing-masing diterima pada transaksi asal, token silang ditolak, RLS mengembalikan 0 row saat token silang dipasang, dan konteks asli dapat dipulihkan sebelum rollback.
- Uji `REPEATABLE READ`: koneksi A dengan XID `924` tetap menerima token dan melihat satu row fixture setelah melanjutkan transaksi. Audit independen sesudahnya menunjukkan `poc-k1` berstatus revoked dengan `revoked_at = 2026-11-21 10:07:52.081753+07`. Output mentah koneksi B (`UPDATE 1` dan `COMMIT`) tidak tercakup dalam transkrip; keterbatasan bukti ini dipertahankan. Key kemudian dipulihkan dan pemeriksaan akhir menunjukkan aktif.
- Hasil tersebut adalah bukti PoC, bukan security acceptance produksi atau bukti integrasi penuh Laravel/Fortify.

**Batasan yang belum selesai**
- Belum ada integrasi trusted-context service dan middleware Laravel/Fortify end-to-end.
- Verifier PoC belum memeriksa account/session/membership authorization state pada setiap protected SQL statement.
- Ownership 14 tabel RLS PoC masih perlu diaudit; jangan mengubah ownership sebelum inventaris sequence, function, grant, policy, dan dependency lengkap.
- Belum ada test stress/multi-process, real connection pooler, key custody produksi, atau immediate cancellation of in-flight statements.

### Keputusan desain — ADR-007 revocation baseline disetujui — 2026-11-26

- Product Owner memilih kebijakan revocation recommended sebagai baseline desain awal SINAU.
- Seluruh protected transaction wajib menggunakan PostgreSQL `READ COMMITTED`.
- Protected statement yang mulai setelah revocation berhasil di-commit wajib ditolak apabila context sudah tidak berwenang.
- Statement yang sudah berjalan sebelum commit revocation boleh menyelesaikan eksekusinya; kebijakan tidak menjanjikan pembatalan paksa statement berjalan atau penarikan data yang sudah dibaca.
- `REPEATABLE READ` dilarang untuk protected transaction. `SERIALIZABLE` bukan baseline dan memerlukan review terpisah.
- Transaksi harus singkat, memiliki batas waktu terukur, tidak boleh idle, dan pemeriksaan revocation tidak boleh di-cache lintas protected statement. Angka timeout akan ditetapkan setelah desain runtime dan pengukuran.
- Gap yang belum selesai: verifier PoC belum memeriksa account/session/membership authorization state pada setiap protected statement. Implementasi authorization version/epoch atau mekanisme fresh-state ekuivalen masih menjadi gate.
- HMAC tetap untuk PoC; algoritma dan custody key produksi belum diputuskan.
- ADR-007 tetap **Proposed**. Persetujuan kebijakan revocation bukan persetujuan signer atau deployment produksi.
- Tidak ada database, schema, table, role, credential, migration, atau service produksi yang diubah. Database `sinau`, role `sinau_app`, SQLRadius, dan MikroTik tetap di luar ruang lingkup.


### Participant trigger search_path finding confirmed; PoC hardening scripts prepared — 2026-11-26

**Read-only evidence**
- public.poc_check_assessment_participant() is a SECURITY INVOKER trigger function (prosecdef=false), owned by sinau_poc, with no function-level search_path (proconfig is NULL). Its row type declaration and SELECT use unqualified student_class_placements.
- public.poc_check_attendance_participant() has the same characteristics.
- Both enabled BEFORE triggers are attached to public.assessment_participants and public.attendance_session_participants.
- sinau_app_runtime_poc, sinau_rls_test, sinau_context_issuer_poc, and sinau_context_owner have database TEMP privilege in the audited PoC. Runtime and query roles cannot create triggers on the two participant tables.
- Under SET LOCAL ROLE sinau_rls_test, creating an empty temporary student_class_placements table caused to_regclass('student_class_placements') and to_regtype('student_class_placements') to resolve to pg_temp_1, while public.student_class_placements remained separately addressable. The test transaction was rolled back. This confirms name/type shadowing, not by itself a completed trigger exploit.
- The read-only constraint audit returned 40 constraint rows, all validated=true. Composite foreign keys preserve tenant/unit/placement/enrollment relationships. They do not include the participant class_group_id comparison or the placement start/end-date comparison; those checks remain in the trigger functions.

**PoC remediation prepared**
- Added 015-harden-participant-trigger-search-path.sql. It has strict database/role/function/trigger preconditions; replaces only the two audited function bodies; schema-qualifies public.student_class_placements and its %ROWTYPE; pins each invoker function to search_path=pg_catalog, pg_temp; verifies the postconditions; and commits the function-only change. It does not alter table rows, role membership, grants, RLS policies, or production objects.
- Added 016-test-participant-trigger-temp-shadowing.sql. It creates an empty temporary shadow table, confirms the caller session resolves the unqualified name to that temp table, invokes each attached BEFORE trigger using a no-op UPDATE if a fixture row exists, and always ends with ROLLBACK. If a target participant table is empty, the corresponding trigger test is explicitly SKIPPED rather than reported as passed.
- These scripts are source artifacts only at this checkpoint. They have not yet been executed on the user's PostgreSQL host; their SQL behavior and test outcomes remain pending server execution.

**Safety boundary**
- Both scripts hard-stop unless current_database() = sinau_design_poc and current_user = postgres.
- No changes were made to sinau, sinau_app, production services, SQLRadius, or MikroTik.
- ADR-007 remains Proposed. This finding and remediation do not approve production RLS, application integration, or production migrations.


### First trigger-hardening script run — postflight assertion corrected — 2026-11-26

- User downloaded the committed 015/016 scripts from the SINAU documentation branch. Script 015 passed all preflight checks and reached both `CREATE OR REPLACE FUNCTION` statements, but then stopped at postflight because it searched a lowercase `pg_get_functiondef()` output using an uppercase `%ROWTYPE` literal.
- The patch script runs within a transaction. The psql command used `ON_ERROR_STOP=1` and exited on the postflight error, so the uncommitted function replacements were rolled back. This is corroborated by script 016 reporting 0 of 2 functions hardened.
- Script 016 stopped at its preflight before creating the temporary relation or running participant UPDATEs; no regression DML was performed.
- Corrected script 015 to compare `lower('public.student_class_placements%ROWTYPE')` against `lower(v_def)`. Re-download the corrected version before retrying.
- No retained database changes from this attempt; no production database/role/service, SQLRadius, or MikroTik changes.
- Status remains pending: rerun corrected 015, then 016. Require PASS for both assessment and attendance triggers; SKIP is not a full pass.


### Participant trigger functions hardened in sinau_design_poc; regression fixture gap remains — 2026-11-26

**Patch execution**
- Corrected PoC script 015 was installed and executed by the user against `sinau_design_poc` as PostgreSQL administrator.
- Preflight passed, both `CREATE FUNCTION` statements succeeded, postflight passed, and the transaction committed.
- The postflight output confirms both functions now schema-qualify the placement row type/relation and store function configuration `search_path=pg_catalog, pg_temp`.
- No table definitions, application rows, role memberships, grants, RLS policies, production database, SQLRadius, or MikroTik were changed by the patch.

**Regression result — incomplete, not a pass**
- Script 016 successfully created an empty temporary `student_class_placements` table and confirmed the session resolves the unqualified name to `pg_temp_9`, while `public.student_class_placements` remains independently addressable.
- The assessment trigger test was SKIPPED because `public.assessment_participants` contained no rows.
- The attendance trigger test was SKIPPED because `public.attendance_session_participants` contained no rows.
- The test transaction rolled back successfully.
- Therefore the function hardening is applied, but actual trigger invocation under temporary-object shadowing remains unverified. Do not close this security gate until both trigger tests have a valid PoC fixture row and report PASS.

**Next work**
- Read-only inspect row counts and required non-sensitive fixture columns/constraints in the participant tables and their referenced parent rows.
- Prepare the smallest valid synthetic fixture set inside one explicit rollback-only test transaction, after dependency inventory. Do not use production records or commit fixture data.
- Re-run the temp-shadow regression test under the same controlled scope and require both triggers to report PASS.
- ADR-007 remains Proposed. This PoC result is not production security acceptance.


### Full rollback-only participant-trigger regression script prepared — 2026-11-26

- Read-only inventory found all seven target academic tables empty; both participant triggers remain enabled, both functions remain SECURITY INVOKER and owned by `sinau_poc`, and both store `search_path=pg_catalog, pg_temp`.
- The PoC schema 001 and smoke-test fixture convention were reviewed. Added `017-test-hardened-participant-triggers.sql`.
- Script 017 hard-stops unless database is `sinau_design_poc`, current role is `postgres`, all ten participating tables are empty, both functions have the expected hardened configuration, and both expected triggers are enabled.
- In one transaction it creates an empty temporary shadow, inserts a minimal synthetic tenant/unit/year/two-class/enrollment/placement chain, creates valid and invalid-date parent records, executes both valid trigger INSERT + no-op UPDATE paths, and checks four expected rejections (wrong class and outside placement period for assessment and attendance).
- It asserts one valid participant row remains in each table inside the transaction, then ROLLBACKs. The script is only a GitHub artifact at this point; server execution is pending.
- The earlier script 016 skipped both trigger invocations because the tables were empty. It rolled back successfully and did not persist fixture rows.
- No production database, roles, services, SQLRadius, or MikroTik changes. ADR-007 remains Proposed.


### Participant-trigger regression fixture strategy corrected to reuse existing parent rows — 2026-11-26

- User ran the requested read-only inventory against \`sinau_design_poc\`. It returned 2 tenants, 3 education units, and 3 academic years; the seven target academic tables (\`class_groups\`, \`student_enrollments\`, \`student_class_placements\`, \`assessment_definitions\`, \`assessment_participants\`, \`attendance_sessions\`, and \`attendance_session_participants\`) each contained 0 rows.
- A second read-only join confirmed the parent chain \`tenant-a / unit-a1 / academic_year 2026–2027\` with IDs \`00000000-0000-0000-0000-000000000001\`, \`10000000-0000-0000-0000-000000000001\`, and \`30000000-0000-0000-0000-000000000001\`.
- The previous version of script 017 stopped at its all-ten-tables-empty preflight because the three parent tables were already seeded. It stopped before creating the temporary shadow or executing fixture DML; the test transaction rolled back.
- Revised \`017-test-hardened-participant-triggers.sql\` to reuse the existing parent records and insert no new tenant, unit, or academic-year rows. It uses a dedicated fixture UUID namespace/student code, checks exact key collisions, locks the seven target tables during the rollback-only transaction, and continues to test valid INSERT/UPDATE plus four expected trigger rejections.
- The revised script's server execution is pending. Do not mark the regression gate passed until both participant triggers report PASS and the final rollback marker appears.
- No parent rows or other database data were changed by the read-only inspections. The revised test script has not yet been run. No production database, role, service, SQLRadius, or MikroTik changes. ADR-007 remains Proposed.


### Participant trigger temporary-table shadow regression passed — 2026-11-26

- User successfully downloaded the pinned revised script 017 from commit \`66c6770f278d97fa5e5b02cb4e45e094d8463183\`, validated that it referenced the existing parent chain and exact fixture-key collision guard, then installed it at \`/run/017-test-hardened-participant-triggers.sql\` with owner \`postgres:postgres\` and mode 0600.
- Executed the script against \`sinau_design_poc\` as PostgreSQL administrator using \`ON_ERROR_STOP=1\`.
- Preflight passed: existing \`tenant-a / unit-a1 / academic_year 2026–2027\` parent chain, fixture key collision checks, both hardened SECURITY INVOKER functions, and both enabled participant triggers.
- Temporary shadow test passed. The caller resolved the unqualified name to \`pg_temp_14\`, while the permanent \`public.student_class_placements\` relation remained distinct.
- Both valid participant INSERTs passed; both no-op UPDATE trigger paths passed.
- All four expected negative cases passed: assessment wrong-class, assessment date outside placement, attendance wrong-class, and attendance date outside placement.
- Final assertions passed: exactly one valid synthetic row remained inside the transaction in each participant table; all four invalid fixture IDs were absent.
- Script completed \`ROLLBACK\` and printed \`ALL PARTICIPANT TRIGGER REGRESSION TESTS PASSED — TRANSACTION ROLLED BACK\`. No synthetic academic rows, locks, or temporary objects were retained.
- **Result:** the PoC regression gate for participant trigger temporary-table shadowing is closed as PASS. The two functions remain hardened in \`sinau_design_poc\`.
- **Boundary:** this is a successful PoC regression, not production security acceptance, trusted-context/application integration approval, or production migration approval. ADR-007 remains Proposed. No \`sinau\` / \`sinau_app\`, SQLRadius, MikroTik, or production services were changed.


### Next security gate prepared — per-statement account/session/membership freshness — 2026-11-26

- Source review of \`005-verify-context-token.sql\` confirms the verifier checks token syntax, MAC, audience/database, issue/expiry window, top-level XID, and signing-key status. Its documented contract explicitly says it does not establish actor membership.
- Source review of \`007-rls-signed-context.sql\` confirms \`current_verified_context()\` delegates to \`verify_context_token()\`, and the public RLS policies use that accessor.
- Source review of \`010-context-issuer-fixtures.sql\` and \`011-context-issuer-validation-tests.sql\` confirms the separate issuer validator checks synthetic identity, authentication-session, tenant-membership, and unit-membership state at context request time. ISS-01—ISS-14 therefore covers issuance-time validation, not state changes after a token is issued.
- ADR-007 explicitly requires fresh authoritative account/session/membership state for each protected statement, without caching authorization state across statements. This is still an open security gate.
- Added \`018-audit-authorization-freshness.sql\`, a read-only catalog audit that checks installed verifier/accessor/issuer function metadata and definitions, lists RLS policies using the accessor, and compares verifier dependencies to the four synthetic authorization-state tables. It is designed for \`sinau_design_poc\` only, uses \`BEGIN READ ONLY\`, performs no DDL/DML, and ends with ROLLBACK.
- Server execution of script 018 is pending. A subsequent two-connection, rollback-only revocation test is not yet prepared; it must be designed after the installed-function audit confirms the exact server state and test fixture/token contract.
- No production database, role, service, SQLRadius, or MikroTik changes. ADR-007 remains Proposed.


### Installed-function audit confirms missing per-statement authorization freshness — 2026-11-26

- User executed script 018 against \`sinau_design_poc\` as PostgreSQL administrator. It began with \`BEGIN READ ONLY\` and ended with \`ROLLBACK\`; no DDL/DML was run.
- Installed metadata confirmed \`verify_context_token()\` is SECURITY DEFINER with \`search_path=pg_catalog, pg_temp\`; \`current_verified_context()\` is SECURITY INVOKER and calls the verifier; \`validate_context_request()\` is SECURITY DEFINER with the same fixed search path.
- The audit confirmed the installed verifier function body does not reference \`poc_identities\`, \`poc_auth_sessions\`, \`poc_tenant_memberships\`, or \`poc_unit_memberships\`.
- The installed issuer validator does reference all four authorization source tables. This establishes that current tests validate state at context request/issuance time, but the later RLS verifier does not refresh that state.
- All 14 listed public RLS policies call \`sinau_private.current_verified_context()\`. Therefore the missing verifier check is relevant to every listed RLS-protected table, not just the academic year fixture.
- Added \`019-sign-authorization-freshness-token.py\` and \`020-test-live-authorization-revocation.sql\` for a controlled two-connection \`READ COMMITTED\` behavior test with existing synthetic actor \`910...001\`. The test will separately revoke account status, the actor's single active synthetic session, tenant membership, and unit membership, then restore each exact fixture row.
- Revocation in connection B must COMMIT so connection A can observe it. The exact fixture row is restored and committed after Session A rolls back. This is not an all-rollback transaction; it is a bounded reversible PoC experiment on synthetic fixture rows only. Do not run another case before the previous restore succeeds.
- The existing token format carries actor/tenant/unit/XID but no session identifier. The session test is limited to the actor's single active fixture session and records an additional design requirement for exact per-session revocation.
- Server execution of scripts 019/020 and the four concurrency scenarios is pending. No verifier/function/policy code was changed. No production database, role, service, SQLRadius, or MikroTik changes. ADR-007 remains Proposed.
