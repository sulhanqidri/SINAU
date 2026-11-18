# Spesifikasi Proses Platform SaaS dan Tenant

**Versi:** Draft 0.1.0  
**Tanggal:** 2026-11-18  
**Status:** Draft turunan; belum divalidasi stakeholder dan bukan kontrak implementasi final  
**Cakupan:** BP-PLT-01 sampai BP-PLT-05; BP-PLT-06 dicatat pada Business Process Map sebagai lifecycle tenant/unit dan memerlukan spesifikasi rinci sebelum implementasi.  
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
15. Daftar anggota tenant/unit, undangan, detail penerimaan, pengelolaan role, suspend/revoke membership, dan histori akses.

Setiap layar harus memiliki loading, empty, validation error, permission denied, offline/retry, success, dan responsive states.

## 11. Traceability awal

| Process | Requirement group | Domain/data | Permission scope | UI | Test family |
|---|---|---|---|---|---|
| BP-PLT-01 | REG/ONBOARDING | User, Registration, Tenant, Unit, initial Membership | Public registration; tenant/unit | Registration wizard | Registration, idempotency, IDOR |
| BP-PLT-02 | TENANT/UNIT | Tenant, EducationUnit, Entitlement | Tenant admin; unit scoped | Unit management | Entitlement, concurrency, isolation |
| BP-PLT-03 | VERIFY | VerificationCase, Document, Audit | Tenant submit; platform review | Verification center | Privacy, workflow, deadline |
| BP-PLT-04 | BILLING/ENTITLEMENT | Plan, Subscription, Invoice, Entitlement | Tenant billing; platform billing | Billing center | Webhook, ledger, concurrency |
| BP-PLT-05 | IDENTITY/ACCESS | User, Invitation, TenantMembership, UnitMembership, RoleAssignment | Tenant/unit membership scoped | Member and invitation management | Invitation lifecycle, role ceiling, revoke, cross-scope IDOR |

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
