# ADR-004: Verifikasi Onboarding dan Hak Unit Berdasarkan Paket

- **Status:** Accepted (keputusan produk)
- **Tanggal:** 2026-11-18
- **Pemilik keputusan:** Product owner SINAU
- **Area:** Registrasi, verifikasi lembaga, subscription, unit entitlement

## Konteks

SINAU perlu memungkinkan calon pelanggan mulai menggunakan proses onboarding tanpa harus menyiapkan seluruh dokumen legal dan identifier resmi pada detik pendaftaran. Pada saat yang sama, sistem harus menjaga keaslian identitas lembaga, mencegah klaim atas NPSN/NSM milik lembaga lain, dan menerapkan batas jumlah unit secara konsisten untuk pelanggan yayasan maupun mandiri.

Status legal/verifikasi lembaga berbeda dari status pembayaran/langganan. Keduanya tidak boleh digabung menjadi satu status karena memiliki alasan, alur, dan konsekuensi yang berbeda.

## Keputusan

### 1. Dokumen legal yayasan dapat menyusul

- Pendaftar foundation wajib mengisi identitas dasar yayasan/badan penyelenggara, penanggung jawab, dan kontak pada registrasi.
- Dokumen legal pendukung tidak wajib diunggah pada langkah awal pendaftaran.
- Dokumen dapat diminta dan diunggah pada tahap verifikasi, sebelum aktivasi kemampuan yang mensyaratkan bukti legal, atau sesuai kebijakan kontrak/risiko.
- Tenant boleh berada pada status `pending_verification` selama dokumen belum diperiksa.
- Fitur yang berdampak tinggi atau memerlukan status terverifikasi dapat dibatasi sampai pemeriksaan selesai. Batas fitur harus ditampilkan secara jelas dan tidak boleh menghilangkan akses pengguna ke data yang telah dimasukkan.

### 2. NPSN/NSM dapat dilengkapi saat verifikasi

- Nama lembaga, bentuk pendidikan, jenjang, dan alamat unit tetap wajib pada pendaftaran.
- NPSN/NSM atau identifier resmi relevan boleh kosong pada pendaftaran awal dan dilengkapi pada tahap verifikasi.
- Jika identifier diberikan, sistem memvalidasi format, tipe identifier terhadap bentuk/jenjang lembaga, dan keunikannya sesuai cakupan otoritatif yang ditetapkan.
- Identifier yang belum diberikan atau belum diverifikasi tidak boleh dianggap valid/terverifikasi.
- Sistem tidak boleh mengungkap nama atau data tenant lain ketika terjadi konflik identifier. Pengguna diarahkan menghubungi dukungan.
- Tidak boleh membuat, menebak, atau mengisi identifier resmi palsu untuk melewati verifikasi.

### 3. Multi-unit mandiri ditentukan oleh entitlement paket

- Yayasan dan pelanggan mandiri dapat memiliki lebih dari satu education unit jika paket/langganannya memberikan entitlement jumlah unit yang memadai.
- Paket dasar dapat membatasi satu unit; paket multi-unit berbayar dapat menaikkan batas unit. Nama paket, harga, dan batas komersial rinci ditentukan terpisah dan tidak dikunci oleh ADR ini.
- Tipe tenant (`foundation` atau `independent_provider`) tidak dengan sendirinya menentukan kuota unit.
- Unit dalam tenant yang sama tetap memiliki konfigurasi, membership, permission, dan data akademik terpisah.
- Penambahan unit memerlukan entitlement aktif, otorisasi tenant, validasi identitas unit, dan audit.

### 4. Status verifikasi dan subscription terpisah

- `verification_status` dan `subscription_status` adalah dua dimensi lifecycle yang independen.
- Contoh verification: `not_started`, `pending`, `verified`, `rejected`, `requires_changes`.
- Status subscription mengikuti lifecycle billing tersendiri, misalnya trial, active, past_due, suspended, cancelled/expired sesuai desain billing.
- Tenant dapat terverifikasi tetapi subscription tidak aktif, atau memiliki subscription trial/aktif tetapi verifikasi belum selesai.
- Policy access menghitung kedua status secara eksplisit; tidak boleh menyimpulkan status verifikasi dari pembayaran atau sebaliknya.

### 5. Downgrade dan unit melebihi entitlement

- Penurunan paket tidak menghapus tenant, education unit, siswa, histori akademik, file, atau audit.
- Jika jumlah unit yang sudah ada melebihi entitlement baru, tenant tidak dapat menambahkan unit baru sampai jumlah unit aktif sesuai batas atau paket ditingkatkan.
- Tidak ada penghapusan otomatis, pemindahan tenant otomatis, atau penonaktifan unit secara diam-diam.
- Perubahan akses operasional pada unit yang melebihi kuota harus mengikuti kebijakan downgrade yang ditampilkan sebelum perubahan paket dan memberi masa transisi yang wajar. Kebijakan rinci masa tenggang dan mode akses (tetap aktif atau read-only) masih memerlukan keputusan produk tersendiri.
- Pengguna tetap memperoleh jalur untuk melihat informasi paket, mengekspor data sesuai hak, menghubungi dukungan, dan meningkatkan paket.

## Konsekuensi

- Onboarding dapat dimulai lebih cepat tanpa menganggap klaim lembaga telah diverifikasi.
- UI harus membedakan data yang belum diberikan, menunggu pemeriksaan, dan telah diverifikasi.
- Dokumen legal memerlukan private storage, akses terbatas, audit, dan retention policy.
- Identifier resmi memerlukan validasi unik dan mekanisme penanganan konflik yang tidak membocorkan data pihak lain.
- Billing harus menyediakan entitlement terukur, termasuk batas jumlah unit, dan memeriksanya pada server setiap penambahan unit.
- Perubahan paket dan verifikasi harus menghasilkan audit event.
- Database/domain model perlu memisahkan subscription, entitlement, verification case/status, dan unit.

## Kriteria verifikasi

1. Foundation dapat mendaftar tanpa mengunggah dokumen legal dan melengkapinya pada verifikasi.
2. Unit dapat didaftarkan tanpa NPSN/NSM, tetapi statusnya tidak dianggap terverifikasi.
3. Identifier yang sama tidak dapat diklaim dua unit yang berbeda; respons konflik tidak membocorkan data pemilik.
4. Foundation dan independent provider dengan entitlement yang sama tunduk pada batas unit yang sama.
5. Penambahan unit ditolak server-side saat kuota habis.
6. Downgrade tidak menghapus data atau unit.
7. Verification status dan subscription status dapat berubah independen.
8. Semua perubahan verifikasi, entitlement, dan subscription tercatat dalam audit.

## Belum diputuskan

- Daftar dokumen legal per bentuk badan penyelenggara dan sumber verifikasi.
- Sumber otoritatif, format final, serta cakupan keunikan NPSN/NSM/identifier lainnya.
- Daftar paket, harga, masa trial, dan kuota unit komersial.
- Masa tenggang dan mode akses unit ketika downgrade membuat jumlah unit melebihi kuota.
- Daftar fitur yang wajib menunggu verifikasi sebelum dapat digunakan.
