# ADR-001: Model Pelanggan dan Batas Tenant

- **Status:** Accepted (keputusan produk)
- **Tanggal:** 2026-11-18
- **Pemilik keputusan:** Product owner SINAU
- **Area:** SaaS tenancy, organisasi, education units

## Konteks

SINAU melayani sekolah umum (SD, SMP, SMA, SMK) dan madrasah (MI, MTs, MA, MAK). Keduanya dapat berada di bawah naungan yayasan/badan penyelenggara; keduanya juga dapat menjadi pelanggan mandiri. Karena itu, pilihan bentuk pelanggan saat registrasi harus dipisahkan dari jenis dan jenjang pendidikan unit. Memaksa semua pelanggan menjadi yayasan akan menambah entitas administratif yang tidak nyata bagi sekolah mandiri. Membatasi model yayasan hanya untuk madrasah juga keliru karena yayasan dapat menaungi sekolah umum, madrasah, atau kombinasi keduanya.

## Keputusan

SINAU menggunakan satu model tenant yang mendukung dua tipe pelanggan:

- foundation: yayasan/badan penyelenggara pendidikan yang dapat menaungi satu atau banyak unit pendidikan, baik sekolah umum maupun madrasah.
- independent_provider: sekolah/madrasah mandiri yang menjadi pelanggan langsung tanpa parent foundation.

Pilihan ini menjawab apakah akun pelanggan didaftarkan sebagai yayasan atau satuan pendidikan mandiri; bukan menentukan jenis atau jenjang sekolah.

Tenant menjadi batas kontrak SaaS, billing, konfigurasi pelanggan, dan isolasi data. Education unit menjadi batas operasional pendidikan, identitas sekolah/madrasah, konfigurasi akademik, dan data unit.

Setiap education unit terhubung ke tepat satu tenant aktif pada satu waktu. Tenant mandiri dibuat bersama education unit pertamanya. Tenant yayasan dapat menambahkan beberapa unit: SD, SMP, SMA, SMK, MI, MTs, MA, MAK, atau kombinasi sekolah umum dan madrasah. Education type dan education level disimpan per unit, bukan pada tenant.

Kedua tipe tenant menggunakan codebase, skema domain, modul akademik, UX, dan mekanisme keamanan yang sama. Tenant membership dan unit membership dipisahkan. Keanggotaan tenant tidak otomatis memberikan akses operasional ke seluruh unit; akses unit harus mengikuti role/permission yang eksplisit.

Perpindahan education unit antar tenant wajib melalui proses transfer terotorisasi dan diaudit. Histori akademik tidak boleh dipindahkan, dihapus, atau dibuka kepada tenant baru secara diam-diam.

## Konsekuensi

### Positif
- Yayasan penyelenggara sekolah umum dapat mendaftar dan mengelola satu atau banyak sekolah.
- Yayasan penyelenggara madrasah dapat melakukan hal yang sama.
- Yayasan yang menaungi sekolah umum sekaligus madrasah dapat mengelolanya dalam satu tenant.
- Sekolah/madrasah mandiri dapat onboarding tanpa membuat yayasan fiktif.
- Yayasan dapat mengelola banyak unit dari satu tenant.
- Unit umum dan madrasah dapat hidup dalam satu tenant dengan konfigurasi pendidikan masing-masing.
- Billing dan isolasi pelanggan tetap konsisten.
- Pengguna dapat memiliki akses lintas unit secara eksplisit tanpa menggabungkan data unit.

### Trade-off dan kontrol
- Permission perlu membedakan scope platform, tenant, dan unit.
- Semua query, file, cache, export, queue, webhook, dan laporan harus menjaga tenant/unit scope.
- Transfer unit memerlukan workflow dan kebijakan retensi.
- Data siswa lintas unit/tenant membutuhkan aturan privasi dan otorisasi khusus.

## Model konseptual

```text
SINAU Platform
  ├── Tenant: Foundation A
  │     ├── Unit: SD ...
  │     ├── Unit: MI ...
  │     └── Unit: MTs ...
  └── Tenant: Independent School B
        └── Unit: SMA ...
```

## Yang tidak diputuskan oleh ADR ini

- Shared database/schema versus database per tenant.
- Bentuk final composite foreign key dan denormalisasi tenant_id.
- Model master identitas people/student/employee.
- Default permission administrator yayasan pada seluruh unit.
- Prosedur detail transfer, retensi, dan portabilitas data.
- Stack teknologi final.

Keputusan teknis tersebut harus memiliki ADR/PoC terpisah sebelum migration awal.

## Kriteria verifikasi

1. Tenant foundation dapat memiliki minimal dua unit berbeda jenis/jenjang.
2. Tenant independent_provider dapat dibuat tanpa entitas yayasan.
3. Kedua tenant dapat menjalankan alur akademik yang sama.
4. User tenant/unit tidak dapat mengakses data di luar membership dan permission.
5. Relasi lintas tenant/unit ditolak oleh constraint atau mekanisme integritas yang teruji.
6. Transfer unit dan pencabutan akses tercatat serta menjaga histori.
