# Spesifikasi Proses Platform SaaS dan Tenant

**Versi:** Draft 0.1.0  
**Tanggal:** 2026-11-18  
**Status:** Draft turunan; belum divalidasi stakeholder dan bukan kontrak implementasi final  
**Cakupan:** BP-PLT-01 sampai BP-PLT-06; seluruh proses memiliki uraian rinci draft dalam dokumen ini, tetapi belum divalidasi stakeholder dan bukan persetujuan implementasi.  
**Rujukan:** [Business Process Map](BUSINESS-PROCESS-MAP.md), [Registration and Onboarding Flow](REGISTRATION-AND-ONBOARDING-FLOW.md), [Multi-Tenant Blueprint](../01-blueprint/MULTI-TENANT.md), ADR-001 sampai ADR-004.

> Dokumen ini menguraikan perilaku proses dan kontrol yang diperlukan. Ia tidak menetapkan harga, paket komersial, SLA, sumber verifikasi legal, atau skema fisik database yang belum diputuskan. Jika ada perbedaan, keputusan Accepted pada ADR dan kebijakan produk yang telah disahkan lebih tinggi daripada asumsi dalam dokumen draft ini.

## 1. Tujuan dan prinsip lintas proses

Spesifikasi ini menjadi dasar penurunan proses platform SINAU ke requirement, model domain, authorization, UI, API, dan test case.

Prinsip wajib:
1. **Tenant adalah pelanggan SaaS** dan batas kontrak, subscription, billing, konfigurasi pelanggan, serta isolasi data.
2. **Education unit adalah satuan operasional pendidikan.** Satu tenant dapat memiliki satu atau banyak unit.
3. Tipe tenant hanya `foundation` atau `independent_provider`; ini bukan tipe atau jenjang pendidikan.
4. Yayasan dapat mengelola unit sekolah umum dan madrasah lintas jenjang. Provider mandiri tidak memerlukan foundation fiktif.
5. Tenant membership dan unit membership terpisah. Keanggotaan tenant tidak otomatis memberi akses ke seluruh data akademik setiap unit.
6. Verification, tenant lifecycle, subscription, entitlement, dan membership adalah state/dimensi berbeda.
7. Tidak ada penghapusan data operasional akibat downgrade, suspend, atau pembatalan subscription.
8. Setiap mutasi sensitif harus authorized, auditable, idempotent, dan tenant-scoped.
9. Konteks tenant/unit ditentukan server dari sesi dan membership tervalidasi, bukan dipercaya dari request browser.
10. Kegagalan proses tidak boleh meninggalkan relasi parsial atau status yang saling bertentangan.

## 2. Aktor dan swimlane

| Aktor | Tanggung jawab | Batas kewenangan |
|---|---|---|
| Calon pelanggan / pendaftar | Membuat akun dan mengajukan tenant/unit | Tidak otomatis menjadi platform operator |
| Tenant owner | Mengelola tenant sesuai permission dan kontrak | Tidak otomatis memiliki akses akademik semua unit |
| Tenant administrator | Mengelola profil, unit, undangan, dan administrasi tenant | Hanya tindakan yang diberikan permission |
| Unit administrator | Mengelola konfigurasi dan pengguna unit yang ditugaskan | Terbatas pada unit tersebut |
| Pengelola unit | Menjalankan tugas operasional sesuai role unit | Tidak dapat mengubah billing/tenant global tanpa grant |
| Platform verification officer | Memeriksa dokumen/identitas dan memutuskan verifikasi | Akses minimum; tidak otomatis dapat membaca data siswa |
| Platform billing operator / billing service | Mengelola subscription, invoice, payment reconciliation | Tidak memiliki akses akademik |
| Platform support | Membantu pelanggan melalui akses terbatas dan tercatat | Break-glass wajib beralasan, scoped, dan time-bound |
| Notification service / scheduler | Mengirim notifikasi dan menjalankan transisi terjadwal | Bukan pemilik keputusan bisnis; hanya mengeksekusi policy yang disahkan |

**Swimlane konseptual:** Pendaftar/Tenant Admin → Platform API & Policy Engine → Verification/Billing Officer atau provider → Audit & Notification. Setiap lane harus memeriksa permission dan tenant context sebelum perubahan.

## 3. BP-PLT-01 — Registrasi dan pembentukan tenant

### 3.1 Tujuan, trigger, dan hasil

- **Tujuan:** membuat identitas pelanggan SaaS dan unit pendidikan pertama secara konsisten.
- **Trigger:** calon pelanggan memilih mulai registrasi.
- **Precondition:** koneksi tersedia; pendaftar memiliki email yang dapat diverifikasi; persetujuan syarat layanan dan privasi tercatat.
- **Hasil sukses:** satu tenant, unit pertama, tenant membership, unit membership, role assignment, dan audit event terbentuk konsisten.
- **Rujukan rinci:** kebijakan field dan pilihan pelanggan mengikuti dokumen Registration and Onboarding Flow.

### 3.2 Alur utama

1. Pendaftar membuat akun global dengan nama, email, dan password.
2. Sistem menormalisasi email, menerapkan rate limit, mengirim verifikasi, dan menunggu verifikasi sesuai policy.
3. Pendaftar memilih bentuk pelanggan: foundation atau independent_provider.
4. Untuk foundation, pendaftar mengisi profil badan penyelenggara. Untuk independent_provider, pendaftar mengisi profil lembaga mandiri.
5. Pendaftar mengisi data unit pertama, termasuk bentuk dan jenjang pendidikan dari reference catalog.
6. Sistem memvalidasi kombinasi tipe, field, identifier bila diisi, duplikasi, dan kewenangan pendaftar.
7. Sistem menampilkan ringkasan dan meminta konfirmasi.
8. Backend memeriksa ulang seluruh prasyarat dan melakukan pembuatan tenant, profil, unit, membership, role assignment, dan audit secara atomik.
9. Sistem menetapkan status onboarding dan verification yang eksplisit, merekam `registration_completed_at`, lalu menampilkan dashboard onboarding.
10. Sistem mengirim konfirmasi dan daftar pekerjaan onboarding yang tersisa.

### 3.3 Alternatif dan exception

| Kondisi | Perilaku yang diwajibkan |
|---|---|
| Email belum diverifikasi | Akun boleh berada pada status pra-onboarding; tenant operasional belum dibuat |
| Email sudah terdaftar | Tampilkan pesan aman dan jalur login/pemulihan; jangan mengungkap profil akun |
| Identifier tidak diisi | Izinkan bila kebijakan registrasi memperbolehkan; tandai perlu dilengkapi/diverifikasi |
| Identifier bentrok | Jangan mengungkap nama atau data tenant pemilik; berikan jalur dukungan |
| Kombinasi bentuk/jenjang tidak valid | Tolak server-side dan arahkan perbaikan |
| Pendaftar tidak mengonfirmasi kewenangan | Hentikan pengajuan |
| Request dikirim ulang | Gunakan idempotency key/registration state agar tidak membuat tenant/unit ganda |
| Kegagalan di tengah transaksi | Rollback seluruh perubahan; sediakan retry aman |
| Pembuatan tenant berhasil tetapi notifikasi gagal | Jangan rollback data inti; masukkan notifikasi ke retry/outbox |

### 3.4 Aturan bisnis

- BR-PLT-01-01: satu user adalah identitas global dan dapat memiliki membership pada beberapa tenant.
- BR-PLT-01-02: satu registrasi membuat tepat satu tenant dengan tipe yang dipilih.
- BR-PLT-01-03: independent_provider tidak memiliki foundation profile dan tidak memerlukan tenant yayasan.
- BR-PLT-01-04: foundation wajib memiliki minimal satu unit pendidikan untuk menyelesaikan onboarding.
- BR-PLT-01-05: jenis/jenjang pendidikan melekat pada unit, bukan tenant.
- BR-PLT-01-06: role pendaftar dibatasi pada tenant dan unit yang dibuat/ditugaskan; pendaftar bukan platform admin.
- BR-PLT-01-07: tenant admin tidak otomatis memperoleh hak membaca data akademik semua unit.
- BR-PLT-01-08: tipe tenant tidak dapat diubah melalui edit profil biasa; perubahan memerlukan workflow migrasi yang disetujui dan diaudit.
- BR-PLT-01-09: pembuatan inti atomik; side effect eksternal dijalankan melalui outbox/retry setelah commit.
- BR-PLT-01-10: validasi dan constraint identifier harus mempertimbangkan jenis identifier, otoritas penerbit, ruang lingkup keunikan, dan kemungkinan perubahan regulasi.

### 3.5 State dan transisi

| Aggregate | State awal | Transisi yang diizinkan | Guard |
|---|---|---|---|
| Registration | started | email_pending → profile_pending → review_ready → completed / abandoned | Email verified, field lengkap, konfirmasi |
| Tenant | draft | active / suspended / closed | Hanya policy lifecycle dan aktor berwenang |
| Tenant verification | not_started | pending → verified / requires_changes / rejected | Bukti dan keputusan reviewer |
| Unit | draft | pending_verification → active / inactive | Profil valid dan policy verifikasi |
| Membership | invited atau active | active / suspended / revoked / expired | Invitation/authorization policy |

Transisi final perlu dituangkan sebagai state machine formal. Jangan menyatukan status tenant dengan verification atau subscription.

### 3.6 Data dan audit minimum

Aggregate/entitas konseptual: User, RegistrationAttempt, Tenant, FoundationProfile (khusus foundation), EducationUnit, TenantMembership, UnitMembership, RoleAssignment, VerificationCase, AuditEvent, OutboxMessage.

Audit minimum:
- actor dan subject;
- tenant_id dan unit_id bila relevan;
- action, timestamp, correlation/request ID;
- nilai perubahan yang aman (hindari password, token, dokumen mentah);
- sumber keputusan dan alasan untuk tindakan manual.

### 3.7 Acceptance criteria

- AC-PLT-01-01: kedua tipe pelanggan dapat menyelesaikan registrasi dengan jalur yang benar.
- AC-PLT-01-02: tenant mandiri dibuat tanpa foundation fiktif.
- AC-PLT-01-03: foundation dapat mendaftarkan unit campuran sekolah/madrasah dan jenjang yang didukung.
- AC-PLT-01-04: user pendaftar menjadi tenant member dan hanya unit member pada unit yang ditugaskan.
- AC-PLT-01-05: pendaftar tidak mendapat privilege platform.
- AC-PLT-01-06: retry tidak membuat duplikasi.
- AC-PLT-01-07: kegagalan transaksi tidak meninggalkan tenant tanpa unit atau membership yatim.
- AC-PLT-01-08: konflik identifier tidak membocorkan data pelanggan lain.
- AC-PLT-01-09: seluruh mutasi inti tercatat audit.

### 3.8 Test scenario minimum

1. Happy path foundation dengan dua jenis unit.
2. Happy path independent_provider.
3. Email belum diverifikasi dan token kedaluwarsa.
4. Email/identifier duplikat dan respons anti-enumeration.
5. Kombinasi education form dan level tidak valid.
6. Fault injection pada setiap langkah transaksi.
7. Dua request registrasi bersamaan dengan idempotency key sama.
8. Pendaftar mencoba mengirim role platform_admin atau tenant_id lain.
9. Pemeriksaan tidak adanya akses akademik lintas unit tanpa membership/grant.

## 4. BP-PLT-02 — Penambahan dan pengelolaan unit pendidikan

### 4.1 Tujuan dan trigger

- **Tujuan:** memungkinkan tenant menambah dan mengelola unit tanpa merusak isolasi data unit yang sudah berjalan.
- **Trigger:** tenant owner/admin memilih tambah unit atau mengubah status unit.
- **Precondition:** user memiliki tenant membership aktif, permission yang sesuai, tenant tidak berada pada status yang melarang perubahan, dan entitlement tersedia.

### 4.2 Alur tambah unit

1. Tenant admin membuka daftar unit dan memilih tambah unit.
2. Server memeriksa tenant context, membership, permission, status tenant, subscription, entitlement unit, dan batas percobaan.
3. Sistem menampilkan form berdasarkan reference catalog.
4. Admin mengisi profil dan identifier unit (bila tersedia).
5. Sistem memvalidasi data, format, kombinasi education form/level, dan konflik identifier.
6. Sistem menampilkan ringkasan dan meminta konfirmasi.
7. Backend membuat unit dalam tenant aktif dan mencatat audit.
8. Tenant admin menugaskan unit administrator/pengelola melalui undangan.
9. Sistem mengirim undangan dan menampilkan status unit.

### 4.3 Alur pengelolaan status dan profil

- Perubahan nama, alamat, kontak, atau data operasional dilakukan oleh role yang memiliki permission.
- Perubahan identifier resmi, legal entity, bentuk, atau jenjang yang berdampak pada identitas memerlukan validasi tambahan dan jejak perubahan.
- Menonaktifkan unit memerlukan alasan, konfirmasi dampak, dan pemeriksaan proses akademik/keuangan yang masih terbuka.
- Pemindahan unit antar-tenant bukan edit `tenant_id`; wajib workflow transfer terpisah dengan otorisasi platform, persetujuan pihak terkait, konflik data, kontrak, histori, dan audit.
- Penghapusan permanen bukan operasi rutin. Retensi dan kewajiban arsip harus diselesaikan terlebih dahulu.

### 4.4 Aturan bisnis

- BR-PLT-02-01: kedua tipe tenant dapat memiliki lebih dari satu unit jika entitlement mengizinkan.
- BR-PLT-02-02: kuota diperiksa server-side pada saat transaksi, bukan hanya saat halaman dibuka.
- BR-PLT-02-03: pemeriksaan kuota harus aman terhadap race condition; dua request paralel tidak boleh melewati limit.
- BR-PLT-02-04: unit baru tidak otomatis memberi semua tenant member akses unit.
- BR-PLT-02-05: setiap unit memiliki identitas, konfigurasi, periode akademik, dan membership sendiri.
- BR-PLT-02-06: downgrade tidak menghapus unit/data; unit yang melebihi kuota mengikuti kebijakan akses yang harus ditetapkan sebelum implementasi.
- BR-PLT-02-07: tidak ada perpindahan unit lintas tenant melalui perubahan foreign key biasa.
- BR-PLT-02-08: unit inactive tidak dapat menerima operasi baru kecuali operasi administrasi/arsip yang diizinkan.

### 4.5 State unit

`draft → pending_verification → active → inactive`

Transisi tambahan:
- `pending_verification → requires_changes` bila reviewer meminta perbaikan;
- `requires_changes → pending_verification` setelah pengajuan ulang;
- `inactive → active` hanya jika syarat reaktivasi terpenuhi.

State `rejected` dan penghapusan/arsip harus memiliki kebijakan terpisah. Jangan menghapus data historis hanya karena unit tidak aktif.

### 4.6 Acceptance criteria dan test

- AC-PLT-02-01: unit dapat ditambahkan oleh tenant dengan entitlement dan permission.
- AC-PLT-02-02: tenant yang tidak berhak ditolak meskipun memanggil endpoint langsung.
- AC-PLT-02-03: kuota tidak dapat dilewati oleh request paralel.
- AC-PLT-02-04: unit dari tenant berbeda tidak dapat diakses atau diubah.
- AC-PLT-02-05: tenant member tidak otomatis menjadi unit member.
- AC-PLT-02-06: downgrade tidak menghapus unit atau histori.
- AC-PLT-02-07: transfer unit memakai workflow terpisah dan audit lengkap.

Test: kuota penuh, entitlement habis/expired, request paralel, unit inactive, cross-tenant IDOR, tenant admin tanpa permission, perubahan identifier, transfer ditolak, dan rollback.

## 5. BP-PLT-03 — Verifikasi tenant dan unit

### 5.1 Tujuan dan prinsip

Memastikan identitas pelanggan dan unit dapat diverifikasi tanpa menghambat pelanggan yang telah menyerahkan persyaratan tepat waktu hanya karena antrean pemeriksaan internal.

Status verification harus terpisah dari status tenant dan subscription.

### 5.2 Alur utama

1. Setelah onboarding, sistem membuat verification case dan checklist persyaratan berdasarkan tipe tenant/unit.
2. Tenant owner/admin mengunggah dokumen atau melengkapi identifier melalui kanal privat.
3. Sistem memvalidasi tipe file, ukuran, malware policy, metadata, akses, dan checksum.
4. Case berubah menjadi pending_review dan masuk antrean reviewer.
5. Reviewer memeriksa bukti berdasarkan checklist dan sumber verifikasi yang disahkan.
6. Reviewer memutuskan verified, requires_changes, atau rejected dengan alasan dan bukti.
7. Jika requires_changes, tenant admin memperbaiki dan mengajukan ulang; histori versi tetap tersimpan sesuai retention policy.
8. Jika verified, policy engine mengevaluasi apakah tenant/unit dapat diaktifkan berdasarkan status lifecycle dan subscription.
9. Sistem mengirim hasil dan mencatat audit.

### 5.3 SLA dan tenggat

Kebijakan yang sudah tercatat pada ADR-004 dan onboarding flow:
- Masa tenggang kelengkapan persyaratan wajib: 7 hari kalender sejak `registration_completed_at`.
- Jika persyaratan wajib belum diserahkan hingga akhir hari ke-7, tenant dapat otomatis disuspend sesuai policy yang disahkan.
- Jika dokumen/identifier wajib sudah diserahkan tepat waktu dan hanya menunggu pemeriksaan internal, tenant tetap pending dan tidak disuspend karena antrean internal.
- Tenggat ini adalah tenggat pemenuhan pelanggan, bukan SLA reviewer.

SLA review internal, hari libur, zona waktu penentuan akhir hari, pengingat, dan eskalasi belum ditetapkan. Scheduler harus menggunakan timestamp tersimpan dan zona waktu kebijakan yang eksplisit, bukan jam browser.

### 5.4 Aturan bisnis

- BR-PLT-03-01: setiap verification decision memiliki reviewer, waktu, alasan, dan referensi bukti.
- BR-PLT-03-02: reviewer tidak boleh menyetujui case miliknya sendiri bila segregation-of-duties diwajibkan oleh kebijakan final.
- BR-PLT-03-03: dokumen bersifat privat; URL unduhan sementara dan akses tercatat.
- BR-PLT-03-04: file lama tidak ditimpa tanpa jejak; revisi membentuk versi baru.
- BR-PLT-03-05: verification status tidak mengubah subscription status secara otomatis.
- BR-PLT-03-06: submission tepat waktu menghentikan suspend otomatis berbasis kelalaian pelanggan selama review internal berlangsung.
- BR-PLT-03-07: keputusan rejected harus menyertakan alasan yang dapat ditindaklanjuti dan jalur banding/dukungan sesuai kebijakan.
- BR-PLT-03-08: akses platform terhadap data siswa tidak diperlukan untuk verifikasi organisasi dan tidak boleh diberikan secara default.

### 5.5 State verification case

`not_started → pending_submission → pending_review → verified`

Cabang:
- `pending_submission → overdue` bila tenggat pelanggan terlewati tanpa persyaratan wajib;
- `pending_review → requires_changes → pending_submission`;
- `pending_review → rejected`;
- `rejected → appeal_pending → pending_review` hanya jika mekanisme banding disetujui.

State case tidak boleh disamakan dengan tenant status. Suspend karena verifikasi adalah efek policy terhadap tenant access, bukan status verifikasi itu sendiri.

### 5.6 Acceptance criteria dan test

- AC-PLT-03-01: checklist berbeda dapat ditentukan untuk foundation dan unit.
- AC-PLT-03-02: dokumen privat tidak dapat diakses oleh tenant lain atau URL publik.
- AC-PLT-03-03: submission tepat waktu tidak terkena suspend otomatis saat menunggu reviewer.
- AC-PLT-03-04: persyaratan yang tidak diserahkan sesuai tenggat menjalankan policy suspend yang tercatat.
- AC-PLT-03-05: keputusan reviewer memerlukan alasan dan tercatat.
- AC-PLT-03-06: status verification dan subscription dapat berbeda.
- AC-PLT-03-07: re-submit mempertahankan histori dokumen dan keputusan.
- AC-PLT-03-08: reviewer tidak memperoleh akses data akademik yang tidak diperlukan.

Test: dokumen tidak valid/malware, file terlalu besar, deadline boundary dengan timezone, submission tepat waktu, scheduler retry/idempotency, reviewer conflict, cross-tenant file access, rejected/re-submit, dan audit.

## 6. BP-PLT-04 — Subscription, entitlement, downgrade, suspend, dan reaktivasi

### 6.1 Tujuan dan batas

Mengelola hak penggunaan layanan SaaS dan kuota secara konsisten tanpa mencampur status kontrak, tenant, verification, unit, dan membership.

Detail paket, harga, trial, metode pembayaran, pajak, masa tenggang billing, refund, dan SLA komersial masih terbuka dan tidak ditetapkan oleh dokumen ini.

### 6.2 Alur subscription

1. Tenant owner/admin yang memiliki permission membuka pilihan paket yang tersedia.
2. Sistem menampilkan fitur, kuota, periode, harga, pajak/biaya, dan syarat yang telah disahkan.
3. Admin memilih paket dan periode; server membuat subscription change/checkout intent.
4. Pembayaran atau aktivasi kontrak diverifikasi melalui mekanisme billing yang disetujui.
5. Setelah status transaksi terkonfirmasi, sistem membuat/mengaktifkan subscription dan entitlement dengan periode efektif.
6. Perubahan entitlement dicatat sebagai snapshot/ledger yang dapat diaudit.
7. Sistem menampilkan status, periode, pemakaian, kuota, dan tanggal perpanjangan.

### 6.3 Enforcement entitlement

- Semua operasi yang mengonsumsi kuota harus memeriksa entitlement di backend.
- UI boleh memberi peringatan, tetapi bukan kontrol keamanan.
- Pemeriksaan harus transaction-safe dan mencegah race condition.
- Entitlement perlu menyimpan sumber (plan, add-on, manual grant), nilai, unit, masa berlaku, dan versi kebijakan.
- Perubahan paket harus memiliki effective_at dan aturan prorata yang disahkan.
- Entitlement yang berakhir tidak menghapus data; operasi baru yang melampaui hak dapat dibatasi.
- Audit wajib mencatat perubahan paket, sumber perubahan, nilai sebelum/sesudah, aktor, dan alasan.

### 6.4 Downgrade

1. Tenant owner/admin mengajukan downgrade.
2. Sistem menghitung penggunaan saat ini dan membandingkan dengan entitlement paket tujuan.
3. Sistem menjelaskan dampak sebelum konfirmasi.
4. Jika penggunaan melebihi kuota baru, sistem menerapkan policy yang telah disahkan (misalnya mencegah penambahan unit baru dan mempertahankan unit yang sudah ada); tidak menghapus data.
5. Perubahan dijadwalkan pada effective date sesuai kontrak.
6. Sistem mengirim konfirmasi dan memperbarui entitlement pada waktu efektif.

**Belum diputuskan:** apakah unit yang melebihi kuota tetap aktif penuh, read-only, atau dibatasi pada fitur tertentu; masa tenggang; pilihan unit prioritas; dan aturan prorata. Tidak boleh memilih salah satu secara diam-diam saat implementasi.

### 6.5 Past due, suspension, cancellation, reactivation

- Past due harus memiliki sumber tagihan, jumlah, due date, dan status rekonsiliasi.
- Suspensi billing hanya berjalan setelah grace period dan notice policy disahkan.
- Tenant suspended tetap memiliki akses terbatas untuk melihat alasan, mengelola pembayaran, menghubungi dukungan, dan mengekspor data sesuai policy.
- Cancel/expired tidak berarti penghapusan data langsung.
- Reaktivasi memerlukan subscription yang valid dan seluruh guard lain (verification/lifecycle) terpenuhi.
- Pemulihan hak akses tidak boleh membuka kembali membership yang sudah revoked atau mengaktifkan unit yang ditutup tanpa workflow terpisah.

### 6.6 Dimensi state terpisah

| Dimensi | Contoh state | Dampak |
|---|---|---|
| Tenant lifecycle | draft, active, suspended, closed | Akses tenant secara keseluruhan |
| Verification | not_started, pending, verified, requires_changes, rejected | Kelayakan berdasarkan identitas/dokumen |
| Subscription | trial, active, past_due, suspended, cancelled, expired | Hak layanan berdasarkan kontrak/billing |
| Entitlement | effective, scheduled, expired, revoked | Kuota/fitur yang dapat digunakan |
| Unit lifecycle | draft, pending_verification, active, inactive | Operasi unit |
| Membership | invited, active, suspended, revoked, expired | Akses individu |

Access decision harus merupakan hasil policy evaluation terhadap seluruh dimensi yang relevan, bukan satu kolom status tunggal.

### 6.7 Acceptance criteria dan test

- AC-PLT-04-01: paket dan harga yang ditampilkan berasal dari katalog yang disahkan.
- AC-PLT-04-02: entitlement diperiksa server-side untuk setiap operasi terbatas.
- AC-PLT-04-03: transaksi paralel tidak dapat melampaui kuota.
- AC-PLT-04-04: perubahan paket memiliki effective date dan audit trail.
- AC-PLT-04-05: downgrade tidak menghapus unit atau data.
- AC-PLT-04-06: kondisi penggunaan melebihi kuota mengikuti policy yang eksplisit; jika belum diputuskan, implementasi diblokir.
- AC-PLT-04-07: past_due/suspended/cancelled/expired memiliki akses yang dibatasi secara konsisten.
- AC-PLT-04-08: reaktivasi tidak mengaktifkan kembali membership revoked atau unit closed.
- AC-PLT-04-09: payment retry/webhook duplicate tidak menggandakan subscription atau entitlement.

Test: checkout gagal/berhasil, webhook duplicate/out-of-order, pembayaran terlambat, renewal, downgrade dengan pemakaian berlebih, upgrade segera/terjadwal, entitlement expired, concurrency, cancel, suspend, reactivation, dan tenant isolation.

## 7. BP-PLT-05 — Identity, invitation, membership, role, dan access

### 7.1 Tujuan dan batas

Mengelola lifecycle invitation dan grant akses pengguna pada scope tenant/unit. Identitas pengguna bersifat global, sedangkan membership dan role assignment selalu memiliki scope eksplisit. Membership tidak sama dengan subscription/entitlement, status pegawai, atau hubungan akademik.

Pembuatan membership dan role awal pendaftar dalam transaksi registrasi tetap menjadi bagian BP-PLT-01. BP-PLT-05 mencakup undangan anggota tambahan, penerimaan undangan, perubahan role, suspend/revoke membership, dan enforcement akses. Hak paket/fitur/kuota tetap menjadi tanggung jawab BP-PLT-04.

### 7.2 Alur invitation dan acceptance

1. Tenant/unit admin membuka undangan dan memilih email, scope (tenant dan/atau unit), role yang diizinkan, serta masa berlaku.
2. Server memvalidasi membership aktif pemberi undangan, permission untuk mengundang/memberi role, status tenant/unit, serta kebijakan jumlah anggota.
3. Sistem membuat invitation dengan token acak sekali pakai, expiry, scope, role yang diminta, inviter, dan audit; token tidak disimpan atau dicatat dalam bentuk terbuka.
4. Penerima membuka tautan, login atau membuat User global, lalu meninjau scope/role sebelum menerima.
5. Server memvalidasi token, expiry, status invitation, identitas penerima, status tenant/unit, dan apakah inviter masih berwenang.
6. Dalam transaksi atomik, invitation ditandai accepted dan membership/role assignment yang diperlukan dibuat atau diaktifkan.
7. Penerima mendapat konfirmasi scope yang diberikan; akses ke unit lain tidak ikut terbuka.

### 7.3 Perubahan dan pencabutan akses

- Perubahan role memerlukan permission khusus, validasi scope, alasan bila sensitif, dan audit nilai sebelum/sesudah.
- Suspend membership bersifat reversible sesuai policy; revoke mengakhiri grant dan tidak dipulihkan otomatis oleh renewal subscription.
- Revoke harus efektif untuk request berikutnya, termasuk API, file, export, queue/job, dan context/session aktif. Cache permission/context harus diinvalidasi.
- Penghapusan user global bukan cara mencabut akses tenant/unit; revoke membership/role pada scope yang benar.
- Support/break-glass mengikuti approval, time limit, reason, dan audit terpisah.

### 7.4 State konseptual

| Entitas | State | Catatan |
|---|---|---|
| Invitation | pending, accepted, expired, revoked | Terminal state tidak dapat diterima ulang |
| TenantMembership | invited, active, suspended, revoked, expired | Scope tenant |
| UnitMembership | invited, active, suspended, revoked, expired | Scope unit; tidak diwariskan otomatis |
| RoleAssignment | active, revoked, expired | Role dan permission terikat scope/effective period |

Status tenant, unit, verification, subscription, dan entitlement tetap merupakan dimensi terpisah yang diperiksa dalam access policy.

### 7.5 Aturan bisnis dan keamanan

- Invitation hanya dapat dibuat oleh actor yang memiliki permission invite pada scope terkait.
- Role yang dapat diberikan dibatasi oleh delegation/role ceiling; admin tidak boleh memberi privilege yang tidak dimilikinya.
- Email penerima harus diverifikasi sesuai kebijakan sebelum membership aktif.
- Token invitation sekali pakai, memiliki expiry, tidak boleh muncul di log, analytics, atau event payload.
- Penerimaan invitation idempotent; token expired/revoked/accepted tidak dapat dipakai ulang.
- Tenant membership tidak otomatis memberikan unit membership.
- Revoke membership/role harus segera menutup akses; cache/session tidak boleh mempertahankan grant yang telah dicabut.
- Setiap akses memeriksa scope di server; ID resource dari browser bukan bukti otorisasi.

### 7.6 Acceptance criteria

- AC-PLT-05-01: hanya actor dengan permission yang sesuai dapat mengundang anggota pada scope yang diizinkan.
- AC-PLT-05-02: invitation token memiliki expiry, sekali pakai, dan tidak dapat ditebak atau dipakai ulang.
- AC-PLT-05-03: penerimaan invitation membuat membership/role pada scope yang tepat secara atomik dan idempotent.
- AC-PLT-05-04: tenant membership tidak otomatis memberi akses unit.
- AC-PLT-05-05: actor tidak dapat memberikan role di atas delegation ceiling miliknya.
- AC-PLT-05-06: perubahan/revoke membership atau role tercatat dengan actor, alasan, waktu, dan before/after.
- AC-PLT-05-07: revoke segera menolak request/API/file/export/job berikutnya dan menginvalidasi cache/context aktif.
- AC-PLT-05-08: undangan tidak dapat diterima jika tenant/unit closed atau statusnya melarang operasi.
- AC-PLT-05-09: retry, duplicate acceptance, dan concurrent acceptance tidak membuat membership ganda.
- AC-PLT-05-10: akses lintas tenant/unit ditolak walaupun pemanggil mengetahui ID resource.

Test minimum: invitation valid/expired/revoked, email belum diverifikasi, existing user, duplicate invitation, duplicate/concurrent acceptance, inviter kehilangan permission, role escalation, unit berbeda dalam tenant sama, tenant berbeda, membership suspended/revoked, session/cache invalidation, file/export/background job, dan break-glass audit.

## 8. Authorization matrix awal

| Aksi | Pendaftar | Tenant owner/admin | Unit admin | Verification officer | Billing operator | Support |
|---|---|---|---|---|---|---|
| Buat registrasi sendiri | Ya | — | — | — | — | — |
| Edit profil tenant | Sebelum submit | Sesuai permission | Tidak | Tidak | Tidak | Tidak, kecuali workflow bantuan tercatat |
| Tambah unit | — | Ya + entitlement | Tidak kecuali diberi permission tenant | Tidak | Tidak | Tidak |
| Kelola unit profile | — | Sesuai grant | Unit yang ditugaskan | Tidak | Tidak | Tidak secara default |
| Upload dokumen verifikasi | — | Ya | Hanya bila diberi grant | Tidak | Tidak | Tidak |
| Review verifikasi | Tidak | Tidak | Tidak | Ya | Tidak | Tidak |
| Ubah paket/subscription | Tidak | Ya + billing permission | Tidak | Tidak | Operasional sesuai separation | Tidak |
| Suspend tenant | Tidak | Tidak | Tidak | Hanya akibat workflow verifikasi jika policy memberi hak | Hanya akibat workflow billing jika policy memberi hak | Tidak |
| Break-glass support | Tidak | Tidak | Tidak | Tidak | Tidak | Hanya grant sementara dengan alasan/approval/audit |

Matrix ini baseline, bukan daftar permission final. Permission harus granular, scoped, default-deny, dan diuji untuk UI/API/background jobs.

## 9. API/event dan integrasi konseptual

Nama endpoint final ditetapkan setelah API blueprint. Operasi minimum:
- registration create/confirm/status;
- tenant profile read/update;
- unit create/read/update/status;
- membership invitation/accept/revoke;
- verification case submit/review/decision;
- plan catalog read;
- subscription checkout/change/cancel/status;
- entitlement evaluate/usage;
- audit history read sesuai permission.

Event konseptual:
- `registration.completed`
- `tenant.created`
- `education_unit.created`
- `membership.invited`, `membership.activated`, `membership.revoked`
- `verification.submitted`, `verification.decided`
- `subscription.activated`, `subscription.changed`, `subscription.past_due`, `subscription.cancelled`
- `entitlement.changed`
- `tenant.suspended`, `tenant.reactivated`

Semua event harus memiliki event ID, aggregate ID, tenant context, occurred_at, schema version, dan idempotency strategy. Jangan memasukkan dokumen legal, password, token, atau data pribadi berlebihan ke payload event.

## 10. Screen inventory awal

1. Registrasi akun dan verifikasi email.
2. Pemilihan bentuk pelanggan.
3. Profil yayasan atau lembaga mandiri.
4. Form unit pertama dan reference education level.
5. Review/konfirmasi registrasi.
6. Dashboard onboarding dan checklist verifikasi.
7. Profil tenant dan daftar unit.
8. Form tambah/edit unit dan penugasan pengelola.
9. Verification case, upload dokumen, status, dan riwayat.
10. Platform verification queue dan detail review.
11. Paket, perbandingan entitlement, checkout, dan status subscription.
12. Penggunaan kuota, notifikasi batas, downgrade impact preview.
13. Suspended/limited access page dan reactivation flow.
14. Audit activity untuk tenant admin dan platform privileged roles sesuai scope.
15. Lifecycle tenant/unit: suspend, close, restore, transfer, manifest, export, reconciliation, dan histori lifecycle.
16. Daftar anggota tenant/unit, undangan, detail penerimaan, pengelolaan role, suspend/revoke membership, dan histori akses.

Setiap layar harus memiliki loading, empty, validation error, permission denied, offline/retry, success, dan responsive states.

## 11. Traceability awal

| Process | Requirement group | Domain/data | Permission scope | UI | Test family |
|---|---|---|---|---|---|
| BP-PLT-01 | REG/ONBOARDING | User, Registration, Tenant, Unit, initial Membership | Public registration; tenant/unit | Registration wizard | Registration, idempotency, IDOR |
| BP-PLT-02 | TENANT/UNIT | Tenant, EducationUnit, Entitlement | Tenant admin; unit scoped | Unit management | Entitlement, concurrency, isolation |
| BP-PLT-03 | VERIFY | VerificationCase, Document, Audit | Tenant submit; platform review | Verification center | Privacy, workflow, deadline |
| BP-PLT-04 | BILLING/ENTITLEMENT | Plan, Subscription, Invoice, Entitlement | Tenant billing; platform billing | Billing center | Webhook, ledger, concurrency |
| BP-PLT-05 | IDENTITY/ACCESS | User, Invitation, TenantMembership, UnitMembership, RoleAssignment | Tenant/unit membership scoped | Member and invitation management | Invitation lifecycle, role ceiling, revoke, cross-scope IDOR |
| BP-PLT-06 | TENANT/UNIT LIFECYCLE | TenantLifecycleCase, UnitLifecycleCase, TransferCase, TransferManifest, DataDispositionPlan, AuditEvent | Tenant/unit scoped; platform approval for high-impact transitions | Lifecycle, suspend/close/restore, transfer, export | Lifecycle policy, consent/approval, retention, transfer integrity, reconciliation, tenant isolation |

Requirement IDs final perlu diselaraskan dengan PRODUCT-REQUIREMENTS dan acceptance register sebelum dianggap stable.

## 12. Keputusan terbuka dan blocker implementasi

| ID | Pertanyaan | Mengapa penting | Status |
|---|---|---|---|
| OPEN-PLT-01 | Dokumen legal dan sumber verifikasi resmi untuk setiap tipe lembaga | Menentukan checklist, reviewer, dan validitas bukti | Open |
| OPEN-PLT-02 | Sumber otoritatif, format, dan ruang lingkup unik NPSN/NSM/identifier lain | Mencegah false duplicate dan data salah | Open |
| OPEN-PLT-03 | Daftar paket, harga, trial, kuota, add-on, pajak, billing cycle | Dibutuhkan sebelum checkout dan entitlement final | Open |
| OPEN-PLT-04 | Grace period billing, dunning, prorata, refund, dan cancellation | Menentukan state dan akses | Open |
| OPEN-PLT-05 | Perilaku unit yang melebihi kuota setelah downgrade | Mencegah suspend/penguncian data yang tidak disetujui | Open |
| OPEN-PLT-06 | SLA review verifikasi dan eskalasi internal | Memerlukan target operasional yang realistis | Open |
| OPEN-PLT-07 | Kebijakan akses tenant admin lintas unit dan approval delegasi | Menentukan authorization matrix | Open |
| OPEN-PLT-08 | Pemilik beberapa tenant, transfer unit, dan perubahan tenant type | Menentukan workflow khusus dan audit | Open |
| OPEN-PLT-09 | Definisi zona waktu akhir tenggat 7 hari dan kalender hari libur | Menjamin scheduler konsisten | Open |
| OPEN-PLT-10 | Appeal/review kedua untuk verification rejected | Menentukan fairness dan separation of duties | Open |
| OPEN-PLT-11—18 | Kebijakan suspend/close/restore/transfer dan retensi BP-PLT-06 | Kewenangan, legal basis, privasi, kontrak, integritas transfer, dan akses pasca-penutupan; rincian pada §14.12 | Open |

**Gate:** implementasi subscription/checkout dan policy suspend/downgrade tidak boleh dimulai sebelum OPEN-PLT-03 sampai OPEN-PLT-05 diputuskan. Implementasi verifikasi otomatis tidak boleh mengasumsikan sumber resmi sebelum OPEN-PLT-01/02 diselesaikan.

## 13. Exit criteria spesifikasi

Spesifikasi ini baru dapat dinyatakan siap baseline setelah:
- proses divalidasi oleh perwakilan pelanggan dan operator platform;
- seluruh open decision memiliki owner dan keputusan;
- requirement IDs dan process IDs memiliki traceability;
- state machine, authorization matrix, data ownership, dan exception flow ditinjau;
- test case ditautkan ke acceptance criteria;
- pemilik produk menyetujui versi baseline.

Sampai itu terpenuhi, dokumen berstatus Draft. Tidak ada migration, endpoint produksi, atau implementasi fitur yang diotorisasi hanya oleh keberadaan dokumen ini.



## 14. BP-PLT-06 — Lifecycle tenant dan unit: suspend, close, transfer, dan restore

### 14.1 Tujuan dan batas proses

BP-PLT-06 mengelola lifecycle operasional tenant/unit. Proses ini terpisah dari:
- BP-PLT-02: provisioning dan pengelolaan profil/unit.
- BP-PLT-03: verifikasi identitas dan dokumen.
- BP-PLT-04: subscription, entitlement, downgrade, suspend karena billing, dan reaktivasi pembayaran.
- BP-PLT-05: invitation, membership, role, grant/revoke akses individu.

BP-PLT-06 mencakup suspend operasional non-billing, close tenant/unit, transfer unit antar-tenant, restore, ekspor terbatas, dan retensi. Suspend bukan delete; close bukan penghapusan langsung. Tenant lifecycle dan unit lifecycle adalah state terpisah. Setiap transisi harus memiliki actor, authority, scope, reason code, effective date, approval yang diperlukan, dan audit. Semua proses harus idempotent, tenant-scoped, serta aman terhadap request dan job bersamaan.

### 14.2 Aktor dan otorisasi

| Aktor | Kewenangan konseptual | Batas |
|---|---|---|
| Tenant owner | Mengajukan suspend/close tenant | Tidak dapat melewati kontrak, retensi, legal hold, atau persetujuan pihak lain |
| Tenant admin | Mengajukan lifecycle bila didelegasikan | Tidak otomatis berwenang close/transfer |
| Unit representative | Mengajukan close/transfer unit bila kewenangannya terbukti | Perlu bukti representasi/pengelolaan |
| Receiving tenant owner | Meninjau dan menyetujui penerimaan transfer | Tidak mendapat akses sebelum cutover sah |
| Platform lifecycle officer | Memeriksa dan menjalankan workflow | Tidak menetapkan legal ownership tanpa bukti |
| Compliance/legal reviewer | Memeriksa consent, kontrak, legal basis, dan privasi | Segregation of duties |
| Platform support | Bantuan terbatas | Break-glass, time-bound, reason, approval, audit |
| Workflow/scheduler | Menjalankan transisi yang sudah disetujui | Tidak mengambil keputusan bisnis |

Matriks kewenangan final, bukti representasi, dan pihak yang wajib menyetujui masih open decision.

### 14.3 Suspend operasional

Trigger yang dapat dipertimbangkan setelah policy disahkan: permintaan sukarela pihak berwenang, risiko keamanan/penyalahgunaan, perintah hukum/regulator terverifikasi, sengketa kewenangan/ownership, atau alasan operasional yang disetujui. Suspend karena billing/verifikasi tetap dicatat di BP-PLT-04/BP-PLT-03, bukan diduplikasi di BP-PLT-06.

Alur:
1. Pemohon memilih tenant/unit, reason code, uraian, tanggal efektif, dan durasi jika sementara.
2. Server memvalidasi identitas, scope, permission, status, dan bukti kewenangan.
3. Sistem menghitung dampak pada unit, anggota, transaksi berjalan, job, integrasi, file, token, dan akses.
4. Impact preview ditampilkan sebelum konfirmasi.
5. Approval dijalankan sesuai reason code dan separation of duties. Emergency containment dapat memakai jalur cepat hanya dengan review pasca-tindakan wajib.
6. Setelah disetujui, lifecycle case dibuat dan transisi dijalankan pada effective date.
7. Policy engine memblokir transaksi operasional baru dan membatasi API, upload, export, file, job, serta integrasi sesuai scope.
8. Notifikasi dikirim kepada pihak yang berhak tanpa membuka alasan sensitif kepada penerima yang tidak berwenang.

Saat suspended, audit dan arsip tetap tersedia sesuai permission; job mutasi operasional dihentikan/karantina; job retensi, cleanup, dan export yang disetujui dapat berjalan. Membership tidak otomatis direvoke karena revoke individu tetap BP-PLT-05. Suspend satu unit tidak otomatis menghentikan unit lain.

### 14.4 Close tenant atau unit

1. Pemohon berwenang mengajukan close dengan scope, alasan, dan effective date.
2. Sistem memeriksa subscription/kontrak, invoice/kewajiban, proses akademik/keuangan berjalan, sengketa, legal hold, export, integrasi, unit turunan, dan membership.
3. Sistem menampilkan checklist dan dampak; tidak ada penghapusan data pada tahap permohonan.
4. Approval pihak yang diwajibkan diperoleh.
5. Sistem menjadwalkan close dan menyelesaikan export/arsip yang disetujui.
6. Pada effective date, transaksi baru diblokir, credential/integration dibatasi, dan histori dikunci kecuali koreksi/retensi sah.
7. Case ditutup setelah checklist selesai dan bukti tersimpan.

Close tenant harus menutup atau mengarsipkan semua unit di bawahnya secara konsisten; tidak boleh meninggalkan unit active. Close unit tidak otomatis menutup tenant/unit lain. Hard delete bukan bagian close normal. Disposal/anonymization setelah retention period adalah proses data governance terpisah yang memeriksa legal hold, dasar hukum, approval, dan audit.

### 14.5 Transfer unit antar-tenant

Transfer mengubah tenant boundary dan merupakan proses high-impact, bukan edit tenant_id atau perubahan profil biasa. Transfer tidak boleh diimplementasikan sebelum legal, privacy, dan kebijakan kepemilikan disetujui.

Preconditions:
- Identitas unit dan tenant asal/tujuan diverifikasi.
- Kewenangan pihak yang meminta dan menerima dibuktikan.
- Consent tertulis dari pihak yang diwajibkan diperoleh.
- Dasar kontrak, pengelolaan/kepemilikan, serta peran data controller/processor ditinjau.
- Tenant tujuan memenuhi eligibility dan entitlement.
- Konflik identifier dan duplikasi diselesaikan.
- Subscription, invoice, kewajiban, integrasi, dokumen, dan data yang tidak dapat dialihkan diperiksa.
- Kategori data yang ikut, tertinggal, diekspor, dianonimkan, atau dikecualikan disetujui.
- Effective date, downtime, komunikasi, snapshot, dan compensation/rollback plan disepakati.

Alur transfer:
1. Pihak asal mengajukan request dengan unit, tenant tujuan, alasan, dokumen, dan proposed effective date.
2. Sistem membuat transfer case dan membekukan perubahan identitas kritis bila perlu.
3. Platform memvalidasi authority asal/tujuan, consent, kontrak, sengketa, entitlement, dan identifier.
4. Sistem menyusun transfer manifest berisi aggregate, relasi, dokumen, histori, membership, konfigurasi, integrasi, serta keputusan disposition per kategori.
5. Kedua pihak meninjau manifest dan dampak.
6. Compliance/legal dan platform memberikan approval sesuai separation of duties.
7. Unit dijadwalkan cutover dan masuk transfer_pending/transfer_locked; transaksi baru dihentikan atau dibatasi.
8. Preflight memeriksa backup/snapshot, checksum/count, referential integrity, dan kesiapan tujuan.
9. Workflow versioned dan idempotent menjalankan transfer, mapping ID, ownership metadata, dan grant baru secara terkoordinasi; bukan update foreign key ad hoc.
10. Post-transfer verification memeriksa jumlah record, referential integrity, tenant isolation, file, audit, akses, dan histori.
11. Unit baru aktif di tenant tujuan setelah seluruh postcondition lulus.
12. Tenant asal kehilangan akses operasional pada effective cutover. Akses histori yang diwajibkan harus terpisah, terbatas, dan time-bound.
13. Manifest, approval, checksum, mapping, hasil verifikasi, dan audit disimpan.

Data tidak otomatis ikut atau tertinggal. Riwayat siswa/enrollment/nilai/presensi, data wali dan pegawai, dokumen, transaksi, komunikasi, serta audit memerlukan keputusan kategori dan legal basis. Invoice/pembayaran dan kewajiban kontrak dapat memiliki pemilik berbeda dari data operasional unit. Membership tenant asal tidak diwariskan; membership/role tujuan dibuat melalui BP-PLT-05. API key, webhook secret, storage permission, cache, search index, background job, dan integration binding harus dirotasi/dipetakan.

Jika preflight gagal, transfer tidak dimulai. Jika cutover gagal, case masuk failed/needs_reconciliation. Unit tidak boleh aktif pada dua tenant sekaligus. Jangan retry buta atau menghapus data parsial; gunakan snapshot dan compensation yang disetujui.

### 14.6 Restore

Restore dari suspended/closed hanya boleh jika policy mengizinkan:
1. Pemohon mengajukan restore dengan case asal, alasan, scope, dan tanggal efektif.
2. Sistem memeriksa kewenangan, legal hold/sengketa, kewajiban close, subscription/entitlement, verification, dan status tenant/unit.
3. Dependency yang menghalangi restore ditampilkan.
4. Approval diperoleh sesuai reason code.
5. Integritas data, konfigurasi, membership, credential, integrasi, dan job diperiksa.
6. Lifecycle status dipulihkan pada effective date.
7. Policy engine tetap mengevaluasi subscription, verification, entitlement, dan membership secara terpisah.
8. Membership revoked/expired tidak diaktifkan kembali.
9. Integrasi dan scheduler dinyalakan bertahap dengan health check dan audit.

Restore dari closed tidak selalu tersedia. Disposal/anonymization yang sah dapat membuat restore tidak mungkin.

### 14.7 State machine konseptual

| Aggregate | State | Transisi dan guard |
|---|---|---|
| Tenant lifecycle | active, suspended, closing, closed | active ↔ suspended; active/suspended → closing → closed; restore hanya jika policy, approval, dan dependency mengizinkan |
| Unit lifecycle | draft, pending_verification, active, suspended, transfer_pending, transfer_locked, inactive, closing, closed | Suspend/restore scoped; close melalui closing; transfer melalui lock, cutover, dan verification |
| Lifecycle case | draft, pending_review, approved, scheduled, executing, completed, rejected, cancelled, failed, needs_reconciliation | Idempotency, approval, audit, compensation |
| Transfer case | draft, pending_review, approved, scheduled, preflight, locked, executing, verifying, completed, rejected, cancelled, failed, needs_reconciliation | Consent dua pihak, manifest, snapshot/checksum, no dual-active state |

Subscription, verification, entitlement, membership, dan lifecycle adalah dimensi terpisah.

### 14.8 Aturan bisnis

- BR-PLT-06-01: setiap perubahan memiliki case ID, actor, scope, reason, effective date, dan audit.
- BR-PLT-06-02: suspend billing/verifikasi tetap berasal dari BP-PLT-04/BP-PLT-03.
- BR-PLT-06-03: suspend satu unit tidak otomatis men-suspend tenant/unit lain.
- BR-PLT-06-04: tenant closed tidak boleh memiliki unit active.
- BR-PLT-06-05: close tidak hard delete; disposal tunduk retention/legal hold.
- BR-PLT-06-06: restore tidak mengaktifkan membership revoked/expired atau subscription tidak valid.
- BR-PLT-06-07: transfer wajib memiliki consent/authority, manifest, approval, preflight, cutover, post-transfer verification, dan audit.
- BR-PLT-06-08: unit tidak boleh aktif pada dua tenant sekaligus; kegagalan masuk reconciliation.
- BR-PLT-06-09: histori dan personal data tidak otomatis ikut transfer; kategori dan legal basis harus disetujui.
- BR-PLT-06-10: membership tenant asal tidak diwariskan ke tenant tujuan.
- BR-PLT-06-11: job, cache, search, file, token, API credential, dan integrasi tenant-aware saat lifecycle berubah.
- BR-PLT-06-12: endpoint dan job memeriksa lifecycle state server-side.
- BR-PLT-06-13: emergency suspend memerlukan role policy dan review pasca-tindakan.
- BR-PLT-06-14: transisi terjadwal idempotent dan concurrency-safe.
- BR-PLT-06-15: read-only/export selama suspend/close harus eksplisit, scoped, time-bound, dan diaudit.

### 14.9 Data, API, event, dan layar konseptual

Aggregate konseptual: TenantLifecycleCase, UnitLifecycleCase, TransferCase, TransferManifest, LifecycleApproval, ConsentRecord, DataDispositionPlan, ExportJob, IntegrityCheck, CompensationAction, AuditEvent, OutboxMessage. Ini bukan keputusan skema fisik.

Operasi konseptual: lifecycle case create/read/submit/approve/reject/cancel; tenant/unit suspend/close/restore; transfer request/consent/manifest/approve/schedule/preflight/cutover/verify/reconcile; export request/status/download; lifecycle history read sesuai permission.

Event konseptual:
- tenant.lifecycle.suspend_requested, tenant.lifecycle.suspended, tenant.lifecycle.close_scheduled, tenant.lifecycle.closed, tenant.lifecycle.restored;
- education_unit.lifecycle.suspend_requested, education_unit.lifecycle.suspended, education_unit.lifecycle.closed, education_unit.lifecycle.restored;
- education_unit.transfer.requested, education_unit.transfer.approved, education_unit.transfer.started, education_unit.transfer.completed, education_unit.transfer.failed, education_unit.transfer.reconciled.

Layar awal: lifecycle overview; suspend request dan impact preview; close checklist; approval queue; restore dependency checklist; transfer request/consent; transfer manifest; cutover/integrity/reconciliation; export center.

### 14.10 Acceptance criteria

- AC-PLT-06-01: suspend operasional hanya oleh aktor berwenang dengan reason dan audit.
- AC-PLT-06-02: suspend billing/verifikasi tetap tercatat di proses sumber.
- AC-PLT-06-03: suspend satu unit tidak mengganggu unit lain di luar scope.
- AC-PLT-06-04: tenant closed tidak memiliki unit active; close menghentikan transaksi baru tanpa menghapus histori.
- AC-PLT-06-05: close memeriksa kewajiban, proses berjalan, legal hold, export, dan retention.
- AC-PLT-06-06: restore memeriksa guard dan tidak menghidupkan membership revoked/expired atau subscription tidak valid.
- AC-PLT-06-07: transfer memerlukan approval asal/tujuan dan bukti kewenangan.
- AC-PLT-06-08: transfer memiliki manifest, snapshot/checksum, preflight, effective date, post-transfer integrity test, dan audit.
- AC-PLT-06-09: unit tidak pernah aktif di dua tenant; kegagalan cutover masuk reconciliation.
- AC-PLT-06-10: data pribadi/akademik/keuangan tidak otomatis ikut transfer; kategori dan legal basis terdokumentasi.
- AC-PLT-06-11: membership dan credential tenant asal tidak memberi akses tenant tujuan.
- AC-PLT-06-12: API, file, export, cache, search, queue, scheduler, dan integrasi menegakkan lifecycle.
- AC-PLT-06-13: transisi terjadwal dan retry idempotent serta concurrency-safe.
- AC-PLT-06-14: read-only/export selama suspend/close hanya sesuai grant, masa berlaku, dan audit.

### 14.11 Test scenario minimum

1. Suspend tenant dengan approval valid; actor tanpa permission ditolak.
2. Suspend satu unit dan pastikan unit lain tetap beroperasi.
3. Suspend operasional dibedakan dari billing dan verification.
4. Emergency suspend, review pasca-tindakan, dan audit.
5. Close ditolak saat kewajiban/approval/legal hold belum selesai.
6. Close unit tidak menutup tenant atau unit lain.
7. Close tenant tidak meninggalkan unit active.
8. Close tidak hard delete; retention/legal hold mencegah disposal.
9. Restore dengan subscription expired, verification rejected, atau legal hold tertahan.
10. Restore tidak mengaktifkan membership revoked/expired.
11. Transfer tanpa consent asal/tujuan atau bukti kewenangan ditolak.
12. Transfer dengan entitlement tujuan habis atau identifier conflict ditolak.
13. Manifest membedakan data ikut, tertinggal, diekspor, atau tidak dapat dialihkan.
14. Failure injection sebelum cutover, saat lock, saat transfer, dan post-validation.
15. Retry/concurrent transfer tidak membuat unit aktif di dua tenant.
16. Checksum, count, FK, tenant isolation, file permission, cache/search/job, dan integration binding diverifikasi.
17. Membership asal tidak diwariskan; penerima mendapat grant melalui BP-PLT-05.
18. Audit historis mempertahankan tenant asal/tujuan tanpa memodifikasi event lama.
19. Export link expired dan akses lintas tenant ditolak.
20. Queue/scheduler tertunda tidak memodifikasi unit setelah close/transfer cutover.

### 14.12 Keputusan terbuka khusus BP-PLT-06

| ID | Pertanyaan | Risiko/ketergantungan | Status |
|---|---|---|---|
| OPEN-PLT-11 | Reason code, trigger, authority, dan approval suspend operasional/emergency | Akses, keselamatan, sengketa, false suspension | Open |
| OPEN-PLT-12 | Siapa berwenang meminta/menyetujui close tenant/unit dan bukti representasinya | Legal authority dan sengketa kepemilikan | Open |
| OPEN-PLT-13 | Legal basis, consent, data controller/processor, dan kategori data yang boleh ikut transfer | Privasi siswa/wali/pegawai | Open — blocker transfer |
| OPEN-PLT-14 | Identifier unit, kontrak/subscription, invoice, kewajiban, dan entitlement saat transfer | Duplikasi, billing, legal ownership | Open — blocker transfer |
| OPEN-PLT-15 | Retention schedule, legal hold, export window, anonymization, dan disposal setelah close | Kepatuhan, pemulihan, biaya | Open |
| OPEN-PLT-16 | Apakah restore dari closed diizinkan, sampai kapan, dan kondisi irreversible | Integritas arsip dan retensi | Open |
| OPEN-PLT-17 | Mode read-only dan export untuk tenant/unit suspended/closed | Privasi dan hak akses pasca-penutupan | Open |
| OPEN-PLT-18 | Strategi transfer: downtime, snapshot, mapping ID, rollback/compensation, dan verifikasi | Integritas dan isolasi tenant | Open — blocker transfer |

Gate: spesifikasi BP-PLT-06 tersedia sebagai draft, tetapi implementasi suspend/close/restore menunggu OPEN-PLT-11, 12, 15, 16, dan 17. Transfer lintas tenant diblokir sampai OPEN-PLT-13, 14, dan 18 disetujui serta ditinjau dari sisi hukum, privasi, dan teknis. Dokumen ini bukan persetujuan otomatis untuk memindahkan data.
