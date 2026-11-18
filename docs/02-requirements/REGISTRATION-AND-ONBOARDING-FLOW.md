# Registrasi dan Onboarding Pelanggan SINAU

**Status:** Proposed product flow — siap direview sebelum implementasi  
**Tanggal:** 2026-11-18  
**Terkait:** ADR-001, ADR-003, PRODUCT-REQUIREMENTS.md, DOMAIN-MODEL.md

## 1. Tujuan

Menyediakan satu alur pendaftaran pelanggan dengan dua pilihan bentuk pelanggan:
1. Yayasan/penyelenggara pendidikan (`foundation`).
2. Sekolah/madrasah mandiri (`independent_provider`).

Pilihan tersebut menentukan tipe tenant. Pilihan itu tidak menentukan jenis atau jenjang pendidikan. Jenis dan jenjang dipilih ketika pengguna mendaftarkan education unit.

SINAU tidak membuat entitas yayasan fiktif untuk pelanggan mandiri. Sebaliknya, yayasan tidak perlu membuat akun tenant terpisah untuk setiap sekolah yang dinaunginya.

## 2. Peta alur

```mermaid
flowchart TD
    A[Mulai registrasi] --> B[Verifikasi email akun]
    B --> C{Bentuk pelanggan}
    C -->|Yayasan/penyelenggara| D[Isi profil yayasan]
    C -->|Sekolah/madrasah mandiri| E[Isi profil satuan pendidikan]
    D --> F[Daftarkan unit pendidikan pertama]
    E --> G[Konfirmasi profil unit]
    F --> H[Validasi dan tinjau data]
    G --> H
    H --> I[Buat tenant dan unit dalam transaksi]
    I --> J[Buat tenant membership dan unit membership admin]
    J --> K[Masuk ke dashboard onboarding]
    K --> L{Tipe tenant}
    L -->|Yayasan| M[Tambah unit lain atau undang pengelola]
    L -->|Mandiri| N[Lengkapi konfigurasi unit]
    M --> O[Siap menggunakan modul]
    N --> O
```

## 3. Langkah registrasi

### Langkah 1 — Akun pengguna pertama

Field minimum:
- Nama lengkap.
- Email aktif.
- Kata sandi sesuai kebijakan keamanan.
- Persetujuan syarat layanan dan kebijakan privasi.

Aturan:
- Email diverifikasi sebelum tenant aktif dapat digunakan.
- Akun pengguna global dan tidak diduplikasi untuk setiap tenant.
- Satu user dapat memiliki membership ke beberapa tenant jika diundang secara sah.
- Jangan menganggap pemilik email otomatis berhak mengelola yayasan atau sekolah yang namanya ia masukkan.
- Proses verifikasi kepemilikan/otorisasi organisasi dapat dilakukan bertahap sesuai risiko dan kebijakan onboarding.

### Langkah 2 — Pilih bentuk pelanggan

Tampilkan dua pilihan yang setara dan mudah dibedakan:

**A. Yayasan/penyelenggara pendidikan**
Deskripsi: "Kami mengelola satu atau beberapa sekolah/madrasah di bawah satu yayasan atau badan penyelenggara."

**B. Sekolah/madrasah mandiri**
Deskripsi: "Sekolah/madrasah kami mendaftar dan mengelola akun SINAU secara mandiri, tanpa akun yayasan."

Pilihan disimpan sebagai `tenants.tenant_type`:
- `foundation`
- `independent_provider`

Tipe ini tidak boleh diubah hanya melalui edit profil biasa. Perubahan tipe tenant memerlukan proses dukungan/migrasi yang diaudit karena berdampak pada struktur organisasi dan billing.

### Langkah 3A — Profil yayasan

Field:
- Nama resmi yayasan/badan penyelenggara (wajib).
- Nama singkat/brand (opsional).
- Bentuk badan penyelenggara (wajib; pilihan terkontrol, dengan "lainnya" bila diperlukan).
- Nomor pengesahan/identitas legal (opsional pada draft; dapat diwajibkan saat verifikasi/kontrak).
- Alamat kantor.
- Email dan nomor kontak organisasi.
- Nama pengurus/penanggung jawab pendaftar.
- Dokumen pendukung (opsional sesuai tahap verifikasi).

Setelah profil yayasan, pendaftar harus mendaftarkan minimal satu unit pendidikan pertama agar tenant dapat menyelesaikan onboarding operasional.

### Langkah 3B — Profil sekolah/madrasah mandiri

Field:
- Nama resmi sekolah/madrasah (wajib).
- Bentuk satuan pendidikan: sekolah umum atau madrasah (wajib).
- Jenjang (wajib; pilihan bergantung bentuk satuan pendidikan).
- NPSN atau NSM/identitas resmi yang relevan (opsional pada draft; validasi keunikan bila diisi).
- Alamat lengkap.
- Email dan nomor telepon unit.
- Nama kepala sekolah/madrasah (opsional pada draft).
- Data penyelenggara dapat dicatat sebagai informasi legal bila memang ada, tetapi tidak membuat tenant foundation secara otomatis.

Sistem membuat tenant `independent_provider` dan education unit yang terhubung langsung pada tenant tersebut.

### Langkah 4 — Data unit pendidikan pertama

Untuk tenant yayasan maupun mandiri, setiap unit memiliki field:
- Nama resmi unit.
- Bentuk pendidikan: `school` atau `madrasah`.
- Jenjang yang sesuai:
  - `school`: SD, SMP, SMA, SMK.
  - `madrasah`: MI, MTs, MA, MAK.
- NPSN/NSM atau identifier resmi relevan.
- Alamat unit.
- Kontak unit.
- Status operasional.
- Zona waktu (default dari tenant, dapat dioverride bila kebijakan produk mengizinkan).

Daftar jenjang harus berasal dari reference catalog yang dapat dikembangkan, bukan hard-coded branching di seluruh modul. Validasi kombinasi bentuk pendidikan dan jenjang harus dilakukan server-side.

### Langkah 5 — Review dan konfirmasi

Sebelum membuat tenant:
- Tampilkan ringkasan akun, tipe pelanggan, profil organisasi, dan unit pertama.
- Pengguna mengonfirmasi bahwa ia berwenang mengajukan pendaftaran.
- Validasi field wajib, format identifier, duplikasi yang terdeteksi, dan konsistensi tipe/jenjang.
- Jika identifier resmi belum tersedia, tandai status verifikasi sebagai pending, bukan mengarang nilai.
- Jangan mengungkap data pelanggan lain saat mendeteksi duplikasi; tampilkan instruksi menghubungi dukungan.

### Langkah 6 — Buat tenant, unit, dan akses administrator

Pembuatan dilakukan secara atomik dalam satu transaksi database:
1. Buat `tenants` dengan `tenant_type` sesuai pilihan.
2. Buat `education_units` yang terhubung ke tenant.
3. Buat `tenant_memberships` untuk user pendaftar.
4. Berikan role tenant-scoped yang sesuai, misalnya `tenant_owner` atau `tenant_admin`.
5. Buat `unit_memberships` untuk unit pertama.
6. Berikan role unit-scoped yang sesuai, misalnya `unit_admin`.
7. Catat audit event untuk pembuatan tenant, unit, dan pemberian role.
8. Set status verifikasi/onboarding secara eksplisit.

Jika salah satu langkah gagal, seluruh transaksi dibatalkan. Jangan sampai tenant terbentuk tanpa unit pertama atau akun admin tanpa membership yang konsisten.

## 4. Hak akses akun pertama

| Tipe pelanggan | Membership tenant | Membership unit pertama | Batas penting |
|---|---|---|---|
| Foundation | `tenant_owner` / `tenant_admin` | `unit_admin` hanya pada unit yang didaftarkan atau ditugaskan | Tenant admin mengelola organisasi dan administrasi tenant; akses data akademik unit tetap membutuhkan grant unit |
| Independent provider | `tenant_owner` / `tenant_admin` | `unit_admin` pada unit mandiri | Tidak ada entitas yayasan; akses operasional hanya pada unit yang dimiliki tenant |

Prinsip:
- Pendaftar pertama tidak menjadi platform administrator.
- Role tenant dan role unit adalah assignment terpisah.
- Foundation tenant admin dapat mengelola daftar unit, undangan, paket, dan konfigurasi tenant sesuai permission.
- Label "admin yayasan" tidak otomatis memberikan akses ke seluruh data akademik unit. Jika produk menghendaki akses lintas unit, berikan permission eksplisit dengan scope yang jelas dan audit.
- Pengelola unit lain diundang dan diberi membership pada unit yang relevan.
- Perubahan/pencabutan membership harus langsung memengaruhi akses aktif.

## 5. Penambahan unit setelah onboarding

Khusus tenant `foundation`:
1. Tenant admin memilih "Tambah unit pendidikan".
2. Mengisi profil dan jenis/jenjang unit.
3. Sistem memvalidasi hak tenant admin dan identifier unit.
4. Unit dibuat di tenant yang sama.
5. Pendaftar memilih pengelola awal unit atau mengundang user.
6. Sistem membuat unit membership dan role sesuai persetujuan.
7. Semua perubahan dicatat dalam audit.

Tenant `independent_provider` tidak menampilkan fitur pengelolaan banyak unit sebagai default MVP. Jika kebutuhan multi-unit mandiri disetujui kelak, itu harus menjadi keputusan produk dan aturan paket yang eksplisit, bukan asumsi tersembunyi.

## 6. Status lifecycle yang disarankan

Status tenant:
- `draft`: registrasi belum lengkap.
- `pending_verification`: menunggu pemeriksaan yang diwajibkan.
- `active`: dapat menggunakan fitur sesuai paket dan status verifikasi.
- `suspended`: akses operasional dibatasi berdasarkan kebijakan.
- `closed`: tenant ditutup sesuai proses retensi/ekspor data.

Status unit:
- `draft`
- `pending_verification`
- `active`
- `inactive`

Status membership:
- `invited`
- `active`
- `suspended`
- `revoked`
- `expired`

Status harus memiliki transisi yang tervalidasi dan audit. Tenant yang belum terverifikasi dapat dibatasi pada onboarding, bukan diberi akses penuh.

## 7. Struktur data konseptual

### tenants
- `id`
- `tenant_type` — enum/reference: foundation, independent_provider
- `display_name`
- `legal_name`
- `status`
- `verification_status`
- `created_by_user_id`
- `created_at`, `updated_at`

### foundation_profiles
- `tenant_id` (PK/FK ke tenants)
- `legal_form`
- `legal_registration_number` (nullable)
- `office_address`
- `contact_email`
- `contact_phone`
- `responsible_person_name`

Profil foundation hanya ada untuk tenant bertipe foundation.

### education_units
- `id`
- `tenant_id`
- `unit_code` (internal, unik dalam tenant)
- `name`
- `education_form` — school/madrasah
- `education_level_id`
- `official_identifier_type` — NPSN/NSM/other
- `official_identifier` (nullable sampai diverifikasi)
- `address`
- `contact_email`, `contact_phone`
- `status`, `verification_status`
- `created_at`, `updated_at`

Constraint konseptual:
- `UNIQUE(tenant_id, id)`
- `UNIQUE(tenant_id, unit_code)`
- unique identifier resmi hanya bila nilainya tersedia dan aturan ruang lingkup keunikannya sudah ditetapkan.
- composite FK pada tabel unit-scoped harus menjaga pasangan `tenant_id, unit_id` berasal dari tenant yang sama.

### users
- `id`
- `name`
- `email` (unique global setelah normalisasi)
- `email_verified_at`
- `password_hash`
- `status`
- timestamp

### tenant_memberships
- `id`
- `tenant_id`
- `user_id`
- `status`
- `joined_at`, `expires_at`
- `invited_by_user_id`
- unique pasangan tenant dan user sesuai kebijakan membership.

### unit_memberships
- `id`
- `tenant_id`
- `unit_id`
- `user_id`
- `status`
- `joined_at`, `expires_at`
- `invited_by_user_id`
- composite FK `(tenant_id, unit_id)` ke `education_units(tenant_id, id)`.

### role assignments
- Tenant role assignment mengacu ke tenant membership.
- Unit role assignment mengacu ke unit membership.
- Role dan permission dipisah dari membership agar satu user dapat memiliki role berbeda pada scope berbeda.

Skema di atas adalah model konseptual, bukan perintah membuat migration final. Nama tabel, tipe kolom, index, cascade policy, dan constraint final harus diuji pada database engine yang dipilih.

## 8. Validasi dan keamanan

- Semua pilihan tipe tenant dan education level divalidasi di server.
- Jangan menerima `tenant_id`, `unit_id`, atau role istimewa dari input browser tanpa otorisasi server.
- Pembuatan tenant/unit/membership/role harus atomik dan idempotent untuk retry request.
- Gunakan rate limit dan proteksi spam pada registrasi, undangan, dan verifikasi.
- Simpan password dengan password hashing standar framework; jangan pernah log password/token.
- Email verification dan reset password harus menggunakan token sekali pakai yang kedaluwarsa.
- Cegah enumeration: respons untuk email/identifier yang sudah digunakan tidak membocorkan data pemiliknya.
- Semua perubahan status, membership, role, dan profil legal dicatat audit.
- File dokumen legal disimpan privat dengan akses terbatas dan URL sementara.
- Platform support tidak otomatis dapat melihat data siswa; akses khusus memerlukan alasan, scope, waktu, dan audit.

## 9. Acceptance criteria

1. Pendaftar dapat memilih yayasan atau mandiri dengan penjelasan yang tidak membingungkan.
2. Yayasan dapat mendaftarkan unit SD/SMP/SMA/SMK, MI/MTs/MA/MAK, atau kombinasi.
3. Sekolah/madrasah mandiri dapat selesai onboarding tanpa membuat foundation profile.
4. Jenis/jenjang unit tidak ditentukan oleh tenant type.
5. Akun pendaftar menjadi user global dan memperoleh tenant membership.
6. Akun pendaftar memperoleh unit membership hanya pada unit yang ditugaskan saat onboarding.
7. Pendaftar bukan platform admin.
8. Foundation tenant dapat menambahkan unit dan mengundang admin unit lain.
9. Independent provider tidak otomatis memperoleh alur multi-unit foundation pada MVP.
10. Kegagalan saat pembuatan tenant/unit/membership tidak meninggalkan data parsial.
11. Tenant/unit yang pending verification dibatasi sesuai kebijakan.
12. Percobaan akses lintas tenant/unit ditolak dan tercatat bila relevan.
13. UI registrasi dapat digunakan melalui desktop dan ponsel serta menjelaskan istilah dengan bahasa sederhana.

## 10. Pertanyaan yang masih perlu keputusan sebelum coding

- Apakah dokumen legal yayasan wajib sebelum tenant aktif, atau dapat menyusul setelah trial?
- Apakah NPSN/NSM wajib saat registrasi atau hanya saat verifikasi unit?
- Apakah tenant mandiri boleh menambah unit kedua pada paket tertentu, atau selalu satu unit?
- Apakah satu email boleh menjadi pemilik beberapa tenant tanpa undangan tambahan?
- Siapa yang menyetujui transfer unit dan perubahan tipe tenant?

Jangan mengunci aturan di atas dalam migration atau UI final sebelum keputusan produk dibuat.
