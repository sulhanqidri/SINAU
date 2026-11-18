# ADR-001: Model Pelanggan dan Batas Tenant

- **Status:** Accepted (keputusan produk)
- **Tanggal:** 2026-11-18
- **Pemilik keputusan:** Product owner SINAU
- **Area:** SaaS tenancy, organisasi, education units

## Konteks

SINAU melayani sekolah umum dan madrasah. Sebagian pelanggan dikelola yayasan yang menaungi beberapa unit pendidikan; sebagian lain berdiri sendiri tanpa yayasan. Memaksa semua pelanggan menjadi yayasan akan menambah entitas administratif yang tidak nyata bagi sekolah mandiri. Menjadikan setiap unit selalu tenant terpisah juga menyulitkan yayasan yang membutuhkan tata kelola lintas unit.

## Keputusan

SINAU menggunakan satu model tenant yang mendukung dua tipe pelanggan:

- foundation: yayasan/badan penyelenggara yang dapat menaungi satu atau banyak education unit.
- independent_provider: sekolah/madrasah mandiri yang menjadi pelanggan langsung tanpa parent foundation.

Tenant menjadi batas kontrak SaaS, billing, konfigurasi pelanggan, dan isolasi data. Education unit menjadi batas operasional pendidikan, identitas sekolah/madrasah, konfigurasi akademik, dan data unit.

Setiap education unit terhubung ke tepat satu tenant aktif pada satu waktu. Tenant mandiri dibuat bersama education unit pertamanya. Tenant yayasan dapat menambahkan beberapa unit, termasuk campuran sekolah umum dan madrasah. Education type dan education level disimpan per unit, bukan pada tenant.

Kedua tipe tenant menggunakan codebase, skema domain, modul akademik, UX, dan mekanisme keamanan yang sama. Tenant membership dan unit membership dipisahkan. Keanggotaan tenant tidak otomatis memberikan akses operasional ke seluruh unit; akses unit harus mengikuti role/permission yang eksplisit.

Perpindahan education unit antar tenant wajib melalui proses transfer terotorisasi dan diaudit. Histori akademik tidak boleh dipindahkan, dihapus, atau dibuka kepada tenant baru secara diam-diam.

## Konsekuensi

### Positif
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
