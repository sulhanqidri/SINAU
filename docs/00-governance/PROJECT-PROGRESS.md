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
| Product discovery dan requirement baseline | 🟡 In progress | Dokumen fondasi tersedia; validasi kebutuhan praktisi dan keputusan MVP belum seluruhnya ditutup |
| Master blueprint dan katalog dokumen | 🟡 In progress | Master blueprint, katalog kelengkapan, dan peta proses bisnis memiliki baseline draft; belum tervalidasi/diterima |
| Arsitektur aplikasi | 🟡 In progress | Modular monolith adalah baseline; stack aplikasi masih rekomendasi PoC |
| Tenant dan authorization | 🟡 In progress | Model baseline dan ADR ada; implementasi serta pembuktian keamanan belum dilakukan |
| Database PostgreSQL 18 | 🟡 In progress | Engine diputuskan; CI constraint smoke test lulus, PoC menyeluruh belum lulus |
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
- [ ] Finalisasi prioritas MVP dan keputusan fitur yang ditunda.

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
- [ ] Module catalog, batas modul, dependensi, dan ownership data.
- [ ] Spesifikasi rinci setiap modul dan submodul.
- [ ] Domain model, ERD konseptual/logis, data dictionary, lifecycle dan retention.
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
Urutan dan isi final harus mengikuti MVP scope yang disetujui. Kandidat domain:
- [ ] Platform SaaS, tenant, unit, subscription, entitlement, onboarding/verifikasi.
- [ ] Master data lembaga, kalender, tahun ajaran, semester, kurikulum.
- [ ] Peserta didik, orang tua/wali, pendaftaran/PPDB, enrollment dan riwayat.
- [ ] Guru, pegawai, struktur organisasi, penugasan.
- [ ] Kelas/rombel, mata pelajaran, jadwal, presensi.
- [ ] Pembelajaran, asesmen, nilai, rapor.
- [ ] Keuangan: tagihan, pembayaran, kas, jurnal, anggaran, rekonsiliasi.
- [ ] Kesiswaan, BK, prestasi, pelanggaran, kegiatan.
- [ ] Surat, disposisi, dokumen, arsip, persetujuan.
- [ ] Perpustakaan, inventaris, aset dan pemeliharaan.
- [ ] Portal guru, siswa, orang tua/wali.
- [ ] Dashboard, laporan, notifikasi, komunikasi, import/export.
- **Exit gate:** setiap modul memiliki acceptance criteria, tenant/unit/role tests, audit, dokumentasi, dan persetujuan UAT terkait.

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
