# SINAU — Audit Konsistensi Spesifikasi Proses

**ID dokumen:** AUD-REQ-001  
**Versi:** 0.1.0 — Draft hasil audit dokumentasi  
**Tanggal:** 2026-11-18  
**Branch:** `feature/phase-0-requirements-blueprint`  
**Status:** Audit dokumentasi; bukan persetujuan perubahan scope atau implementasi  
**Cakupan:** Business Process Map, Product Requirements, MVP Scope, spesifikasi proses platform/tenant, organisasi/siswa, akademik/presensi/asesmen, PPDB/HR, Blueprint Catalog, Project Progress, README, dan daftar ADR.

## 1. Tujuan dan metode

Audit memeriksa keselarasan ID proses, definisi proses, batas MVP, ownership data, dependensi lintas domain, keputusan/ADR, status artefak, dan discoverability dokumen. Pemeriksaan dilakukan terhadap versi branch yang disebutkan di atas pada 2026-11-18.

Audit ini tidak mengubah spesifikasi proses sumber dan tidak memutuskan pertanyaan produk yang masih terbuka. Rekomendasi di bawah adalah usulan remediasi untuk ditinjau pemilik produk.

## 2. Ringkasan temuan

| ID | Severity | Temuan | Dampak |
|---|---|---|---|
| AUD-01 | **High — Resolved** | Makna ID BP-PLT-02/03/04 berbeda antara Business Process Map dan spesifikasi Platform/Tenant | Process register dan peta diselaraskan dengan spesifikasi rinci; lifecycle diberi ID BP-PLT-06 |
| AUD-02 | **High — Resolved** | Identity/access sebelumnya berbagi ID BP-PLT-04 dengan subscription | Identity/access sekarang BP-PLT-05 dan memiliki spesifikasi rinci tersendiri |
| AUD-03 | **High** | BP-ADM-01 PPDB lengkap dan sebagian HR ditulis rinci, padahal PPDB secara eksplisit berada setelah MVP dan cakupan HR MVP jauh lebih sempit | Risiko scope creep dan salah tafsir dokumen rinci sebagai komitmen MVP |
| AUD-04 | **High** | Batas ownership data/penugasan pegawai dan penugasan akademik belum tegas | Potensi duplikasi data pegawai/guru dan assignment |
| AUD-05 | **Medium** | BP-ACA-02 jadwal, BP-ACA-03 pelaksanaan pembelajaran, dan BP-ASM-02 rapor formal perlu dipisahkan lebih tegas dari kebutuhan MVP | Implementasi dapat melebar melampaui MVP |
| AUD-06 | **Medium** | BP-STD-02 mencakup lifecycle lanjutan yang belum dipilah menjadi minimum MVP dan roadmap | Acceptance MVP dan desain lifecycle siswa berpotensi terlalu luas |
| AUD-07 | **Medium** | BP-FIN-01/02 tercantum pada peta, tetapi domain keuangan dinyatakan di luar MVP dan belum memiliki spesifikasi rinci/keputusan prioritas | Risiko menganggap finance bagian dari MVP atau memulai desain terlalu dini |
| AUD-08 | **Medium** | Katalog menyatakan beberapa spesifikasi proses tersedia, tetapi status modul domain terkait masih “Not started” tanpa penjelasan perbedaan artefak proses dan blueprint modul | Pembaca dapat salah mengartikan kelengkapan proses sebagai kelengkapan blueprint modul |
| AUD-09 | **Low** | README requirements belum menautkan semua spesifikasi proses yang telah dibuat | Navigasi dan penemuan dokumen kurang lengkap |

## 3. Temuan dan rekomendasi

> Catatan status: uraian AUD-01 dan AUD-02 di bawah merekam kondisi awal saat audit dilakukan. Keduanya telah diremediasi; lihat bagian 8 untuk process ID kanonis dan batas proses setelah perbaikan.

### AUD-01 — Ketidaksesuaian semantik ID BP-PLT-02/03/04 (kondisi sebelum remediasi)

**Bukti:**
- Business Process Map:
  - BP-PLT-02 = verifikasi, subscription, dan entitlement.
  - BP-PLT-03 = lifecycle tenant dan unit.
  - BP-PLT-04 = identity, invitation, membership, dan access.
- `PLATFORM-TENANT-PROCESS-SPECIFICATIONS.md`:
  - BP-PLT-02 = penambahan/pengelolaan unit.
  - BP-PLT-03 = verifikasi tenant/unit.
  - BP-PLT-04 = subscription, entitlement, downgrade, suspend, dan reaktivasi.

**Dampak:** ID yang sama menunjuk proses berbeda. Traceability dari process register ke acceptance criteria, API/event, authorization, dan test case tidak dapat diandalkan.

**Rekomendasi:** tetapkan satu process register kanonis dan lakukan pemetaan ID sebelum perubahan kode. Pilihan yang paling minim risiko adalah mempertahankan ID pada spesifikasi rinci yang sudah digunakan lalu menyesuaikan peta proses; tetapi perubahan ID harus ditinjau terhadap semua referensi. Jangan melakukan renumber otomatis tanpa audit referensi. Pastikan identity/invitation/membership mendapat ID proses sendiri yang tidak bertabrakan.

### AUD-02 — Proses identity dan access belum terpetakan dengan benar (kondisi sebelum remediasi)

**Bukti:** BP-PLT-04 di peta bisnis memuat identity, invitation, membership, dan access, sedangkan BP-PLT-04 di spesifikasi platform memuat subscription dan entitlement.

**Dampak:** proses undangan, penerimaan undangan, perubahan role, pencabutan membership, pemutusan sesi/context aktif, dan pemeriksaan akses tidak memiliki satu referensi proses rinci yang konsisten. Ini penting karena ADR-003 menetapkan identitas global, tenant/unit membership terpisah, dan default-deny.

**Rekomendasi:** buat/namai ulang proses identity & access secara eksplisit setelah keputusan AUD-01. Spesifikasikan lifecycle invitation, membership, role grant/revoke, scope tenant/unit, expiry, dan efek revoke terhadap request/sesi. Hubungkan langsung ke ADR-003 dan test IDOR/cross-scope. Jangan menganggap uraian singkat BP-PLT-04 pada peta sebagai spesifikasi yang sudah lengkap.

### AUD-03 — PPDB dan HR: spesifikasi rinci bukan komitmen MVP

**Bukti:**
- Product Requirements bagian “Di luar MVP awal” dan MVP Scope bagian “Setelah MVP” secara eksplisit menempatkan PPDB end-to-end setelah MVP.
- BP-ADM-01 memiliki spesifikasi rinci yang mencakup gelombang, jalur, seleksi, pengumuman, daftar ulang, waiting list/appeal, dan konversi ke enrollment.
- MVP Scope hanya mensyaratkan data siswa, data guru/pegawai dasar, enrollment, dan operasional akademik dasar.
- Spesifikasi HR memuat hubungan kerja, dokumen, penempatan, teaching assignment, perubahan status, cuti, dan offboarding; cakupan tersebut lebih luas daripada kebutuhan data guru/pegawai dan penugasan minimum pada MVP.

**Dampak:** keberadaan dokumen lengkap dapat disalahartikan sebagai persetujuan implementasi tahap pertama.

**Rekomendasi:**
1. Tandai BP-ADM-01 sebagai roadmap/post-MVP sampai ada change request yang disetujui.
2. Pecah BP-HR-01 menjadi **HR minimum MVP** (profil minimum pegawai/guru, status dasar, unit membership/penempatan yang diperlukan, dan referensi untuk penugasan mengajar) versus **HR lanjutan** (kontrak, dokumen lanjutan, cuti, offboarding workflow, dan fungsi HRIS lainnya).
3. Pertahankan dokumen saat ini sebagai spesifikasi domain draft; tambahkan label scope, bukan menghapus konten.
4. Payroll tetap out of scope sebagaimana dinyatakan dalam spesifikasi.

### AUD-04 — Ownership pegawai/guru dan assignment akademik

**Bukti:** BP-HR-01 mencakup profil pegawai, hubungan kerja, penempatan, dan teaching assignment; BP-ACA-01 juga mencakup penugasan guru ke mapel/rombel. Spesifikasi akademik mengacu kembali pada BP-HR-01.

**Dampak:** tanpa batas ownership, profil pegawai, status hubungan kerja, penempatan organisasi, dan assignment mengajar berisiko disimpan/diubah di lebih dari satu modul.

**Rekomendasi ownership konseptual:**
- HR/staff domain: identitas/profil pegawai, hubungan kerja, status kepegawaian, dokumen dan riwayat penempatan.
- Academic domain: assignment mengajar yang terikat ke unit, tahun ajaran/periode, mapel, rombel/kelas, beban mengajar, dan effective dates.
- Academic assignment mereferensikan employee/teacher profile; tidak membuat salinan profil pegawai.
- Status kerja dapat menjadi constraint eligibility, tetapi perubahan HR tidak boleh diam-diam menghapus histori akademik. Penutupan assignment harus eksplisit, bertanggal efektif, dan diaudit.
- Role aplikasi tetap terpisah dari status kepegawaian, sebagaimana prinsip dalam HR spec dan ADR-003.

### AUD-05 — Batas MVP untuk jadwal, pembelajaran, dan rapor formal

**Bukti:** MVP Scope mensyaratkan kelas/rombel, mata pelajaran, penugasan guru, presensi, penilaian dasar, rekap sederhana, dan ekspor. Penyusunan jadwal, pelaksanaan pembelajaran sebagai LMS, serta rapor formal tidak disebut sebagai kewajiban MVP. Peta proses mengklasifikasikan BP-ACA-02/03 dan BP-ASM-02 sebagai Phase, tetapi tracker Phase 4 masih mencantumkan jadwal, pembelajaran, dan rapor dalam daftar kandidat modul MVP.

**Dampak:** daftar kandidat tracker dapat terbaca sebagai perluasan MVP walaupun dokumen scope membatasi tahap pertama.

**Rekomendasi:** selaraskan tracker dengan MVP Scope: jadwal dan pembelajaran lengkap menjadi kandidat pasca-MVP kecuali product owner menyetujui kebutuhan minimum; BP-ASM-02 dibatasi untuk rekap/keluaran sederhana MVP, sementara pengesahan dan rapor formal berversi diperlakukan sebagai tahap lanjutan. Jangan menghapus kebutuhan konfigurabilitas kurikulum/nilai untuk sekolah umum dan madrasah.

### AUD-06 — Lifecycle siswa perlu dipilah

**Bukti:** BP-STD-02 merinci mutasi, cuti, nonaktif, kenaikan kelas, kelulusan, dan alumni. MVP Scope hanya menyatakan status aktif/nonaktif dan riwayat perubahan, enrollment, serta proses akademik dasar.

**Dampak:** seluruh workflow mutasi/alumni dapat teranggap sebagai syarat pilot.

**Rekomendasi:** tentukan minimum MVP (enrollment aktif, perubahan status dasar dengan alasan/tanggal efektif, histori yang tidak dihapus, serta penutupan enrollment bila dibutuhkan) dan pisahkan transfer lintas unit, cuti formal, alumni, serta workflow kelulusan sebagai roadmap sampai disetujui. Jangan menghilangkan kebutuhan integritas histori dari desain MVP.

### AUD-07 — Keuangan belum memiliki keputusan scope

**Bukti:** BP-FIN-01/02 masuk process register sebagai Candidate. Product Requirements dan MVP Scope menempatkan tagihan/pembayaran, payment gateway, akuntansi penuh, dan RKAS di luar MVP. Belum ada spesifikasi rinci BP-FIN-01/02.

**Dampak:** pengerjaan finance sekarang dapat mendahului keputusan prioritas, model transaksi, kontrol keuangan, dan batas MVP.

**Rekomendasi:** jangan membuat spesifikasi rinci finance atau model data keuangan sebelum product owner memutuskan fase dan use case. Untuk saat ini, pertahankan sebagai roadmap/candidate. Bila kelak disetujui, pisahkan tagihan/penerimaan dari kas/jurnal/rekonsiliasi dan lakukan discovery bendahara serta approval.

### AUD-08 — Status proses versus status blueprint modul

**Bukti:** Blueprint Catalog mencatat dokumen spesifikasi proses PPDB/HR dan akademik telah tersedia, tetapi tabel domain pendidikan masih menandai beberapa domain seperti Admission, Teacher & Staff HR, Attendance, Timetable, Assessment, dan Report Cards sebagai “Not started”.

**Dampak:** status dapat tampak bertentangan padahal yang satu mengukur keberadaan spesifikasi proses, yang lain kelengkapan blueprint modul.

**Rekomendasi:** pertahankan “Not started” bila module blueprint belum dibuat, tetapi tambahkan keterangan “process specification draft tersedia; module blueprint belum dimulai”. Jangan mengubahnya menjadi Accepted/Done hanya karena process spec tersedia.

### AUD-09 — README requirements belum lengkap

**Bukti:** `docs/02-requirements/README.md` hanya mencantumkan PRD, MVP Scope, onboarding, roles, dan acceptance criteria. Dokumen process map serta empat spesifikasi proses belum tercantum.

**Rekomendasi:** tambahkan tautan ke Business Process Map, spesifikasi Platform/Tenant, Organization/Student, Academic/Attendance/Assessment, PPDB/HR, dan audit ini agar pembaca menemukan artefak terkini.

## 4. Konsistensi yang sudah baik

- Model `foundation` versus `independent_provider` konsisten pada PRD, onboarding, dan keputusan tenant: jenis pelanggan tidak menentukan jenis/jenjang unit pendidikan.
- Tenant dan education unit dibedakan sebagai batas kontrak/isolasi versus batas operasional.
- StudentProfile dipisahkan dari Enrollment; applicant/PPDB dipisahkan dari profil siswa.
- EmployeeProfile/UserAccount/ApplicationRole dipisahkan; status kerja tidak otomatis memberi akses aplikasi.
- Histori, effective dates, audit, idempotency, dan scope tenant/unit menjadi prinsip berulang.
- PostgreSQL 18 merupakan keputusan database yang diterima (ADR-006); stack Laravel/Vue masih rekomendasi PoC (ADR-005), bukan keputusan final.
- PR #1 terverifikasi masih open, draft, dan belum merged pada saat audit.

## 5. Urutan remediasi yang disarankan

1. **Wajib sebelum spesifikasi turunan berikutnya:** putuskan pemetaan ID BP-PLT-01—04 dan tetapkan satu process register kanonis (AUD-01/AUD-02).
2. **Wajib sebelum baseline MVP dibekukan:** tandai PPDB post-MVP, pisahkan HR minimum dari HR lanjutan, dan selaraskan jadwal/pembelajaran/rapor/lifecycle siswa dengan MVP Scope (AUD-03/AUD-05/AUD-06).
3. **Wajib sebelum domain model/ERD final:** sepakati ownership HR versus academic assignment, student enrollment lifecycle, serta boundary finance (AUD-04/AUD-07).
4. **Perapihan dokumentasi:** jelaskan status process spec versus module blueprint dan perbarui index requirements (AUD-08/AUD-09).
5. Setelah keputusan disetujui, perbarui spesifikasi sumber, catalog, traceability, acceptance criteria, dan test scenarios secara konsisten.

## 6. Batas audit dan gerbang

- Audit ini adalah pemeriksaan konsistensi dokumentasi, bukan validasi stakeholder atau verifikasi regulasi resmi.
- Temuan tidak mengubah scope, prioritas, atau ADR secara otomatis.
- Tidak ada keputusan baru yang dianggap Accepted melalui dokumen audit ini.
- Tidak ada kode aplikasi, migration domain produksi, konfigurasi server, SQLRadius, atau MikroTik yang diubah.
- PR #1 harus tetap Draft/open dan tidak di-merge tanpa instruksi eksplisit pemilik proyek.

## 7. Bukti versi yang diperiksa

- `BUSINESS-PROCESS-MAP.md` — blob SHA `d5aba7a6152d473756e2a0b048c3a385b8d7c776`.
- `PLATFORM-TENANT-PROCESS-SPECIFICATIONS.md` — blob SHA `45c8a5e313f7c8fdbbcf86c811f79284ff683cd8`.
- `ORGANIZATION-AND-STUDENT-PROCESS-SPECIFICATIONS.md` — blob SHA `f99501bfd4d846ab77090f29baf97497feb2f00e`.
- `ACADEMIC-ATTENDANCE-ASSESSMENT-PROCESS-SPECIFICATIONS.md` — blob SHA `e28ebc639a30e36042f0b881145de5fb65d066f2`.
- `ADMISSIONS-AND-HR-PROCESS-SPECIFICATIONS.md` — blob SHA `b40d80a3db6510c3a68aa400bdc3eb9f381a9bc3`.
- `PRODUCT-REQUIREMENTS.md` — blob SHA `5be5b1d5c8788eba141c8ebb5355fc73e823b708`.
- `MVP-SCOPE.md` — blob SHA `2301d743fe19b65e88e12f0091f5df96f79ba4c8`.


## 8. Remediasi ID platform — 2026-11-18

**Keputusan yang diterapkan:** spesifikasi rinci Platform/Tenant menjadi sumber ID kanonis untuk BP-PLT-01—04. Business Process Map diselaraskan dan identity/access dipisahkan sebagai BP-PLT-05. Lifecycle tenant/unit dipertahankan sebagai proses tersendiri BP-PLT-06 agar tidak dicampur dengan subscription, verification, pengelolaan unit, atau membership.

| ID kanonis | Proses | Dokumen spesifikasi |
|---|---|---|
| BP-PLT-01 | Registrasi dan onboarding tenant | PLATFORM-TENANT-PROCESS-SPECIFICATIONS.md |
| BP-PLT-02 | Penambahan dan pengelolaan unit pendidikan | PLATFORM-TENANT-PROCESS-SPECIFICATIONS.md |
| BP-PLT-03 | Verifikasi tenant dan unit | PLATFORM-TENANT-PROCESS-SPECIFICATIONS.md |
| BP-PLT-04 | Subscription, entitlement, downgrade, suspend, reaktivasi | PLATFORM-TENANT-PROCESS-SPECIFICATIONS.md |
| BP-PLT-05 | Identity, invitation, membership, role, access | PLATFORM-TENANT-PROCESS-SPECIFICATIONS.md |
| BP-PLT-06 | Lifecycle tenant dan unit (suspend, close, transfer, restore) | Business Process Map; spesifikasi rinci masih diperlukan |

**Batas tanggung jawab:** BP-PLT-02 mengatur provisioning/pengelolaan unit; BP-PLT-03 mengatur verifikasi; BP-PLT-04 mengatur hak kontrak dan billing; BP-PLT-05 mengatur grant akses individu; BP-PLT-06 mengatur lifecycle operasional tenant/unit. Suspend akibat billing tetap keputusan BP-PLT-04; suspend/close operasional dicatat di BP-PLT-06. Membership awal pendaftar tetap dibuat oleh BP-PLT-01, sedangkan invitation anggota tambahan dan revoke/change dikelola BP-PLT-05.

**Status AUD-01/AUD-02:** resolved pada tingkat process ID dan dokumentasi baseline. Detail lifecycle BP-PLT-06 masih membutuhkan spesifikasi proses tersendiri sebelum implementasi. Temuan AUD-03 sampai AUD-09 tetap terbuka.

