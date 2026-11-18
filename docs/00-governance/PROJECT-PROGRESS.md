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
