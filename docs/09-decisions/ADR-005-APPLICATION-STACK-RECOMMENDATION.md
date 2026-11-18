# ADR-005: Rekomendasi Stack Aplikasi

- **Status:** Proposed — stack aplikasi menunggu PoC dan persetujuan pemilik produk; pilihan database ditetapkan terpisah pada ADR-006.
- **Tanggal:** 2026-11-18
- **Area:** Backend, frontend, runtime, framework
- **Terkait:** SYSTEM-ARCHITECTURE.md, TECHNOLOGY-OPTIONS.md, IMPLEMENTATION-PLAN.md, ADR-006

## Konteks

SINAU membutuhkan fondasi yang dapat dipelihara sebagai modular monolith, mendukung UI web responsif, API ter-versioning, antrean pekerjaan, autentikasi, pengujian otomatis, dan isolasi tenant/unit. Stack harus dipilih berdasarkan kompatibilitas, keamanan, kemampuan tim, biaya operasional, serta hasil PoC — bukan hanya popularitas framework.

## Rekomendasi stack

| Lapisan | Rekomendasi untuk PoC | Status |
|---|---|---|
| Backend | Laravel 13 | Kandidat utama |
| Runtime | PHP 8.4 dan 8.5 diuji; pilih satu versi yang didukung penuh oleh dependency | Belum final |
| Frontend | Vue 3 + Inertia | Kandidat utama |
| Styling | Tailwind CSS dengan design tokens SINAU | Kandidat utama |
| API | REST dengan versioning eksplisit | Arah desain |
| Authentication | Session untuk web; evaluasi Sanctum untuk API/client pihak pertama | Belum final |
| Database | PostgreSQL 18 | **Accepted — ADR-006** |
| Queue/cache | Redis bila dibutuhkan; jangan menjadikannya prasyarat untuk seluruh proses MVP sebelum beban diukur | Belum final |
| File | Private S3-compatible object storage melalui abstraction | Belum final |
| CI | GitHub Actions untuk test, lint, static analysis, dan security checks | Kandidat utama |

Laravel 13 menjadi kandidat karena jadwal rilis dan masa dukungan resminya masih sesuai untuk proyek baru pada tanggal ADR ini. Laravel 13 mendukung PHP 8.3–8.5; versi runtime yang dipilih tetap harus diuji terhadap seluruh dependency dan image deployment. [Referensi: Laravel Release Notes](https://laravel.com/docs/releases).

Pemilihan PostgreSQL 18 sebagai database utama telah disetujui pemilik produk dan dicatat pada [ADR-006](ADR-006-POSTGRESQL-DATABASE.md). Validasi skema, isolasi tenant, performa, dan operasional PostgreSQL tetap wajib dilakukan melalui PoC sebelum migration domain produksi.

## Alasan rekomendasi

1. Laravel + Vue + Inertia memungkinkan tim membangun pengalaman web interaktif tanpa memecah backend dan frontend menjadi dua deployment sejak awal.
2. Modular monolith tetap dapat memisahkan domain, application service, policy, dan infrastruktur secara disiplin.
3. PostgreSQL 18 dipilih untuk fondasi integritas relasional, transaksi, query laporan, indexing, partitioning, serta opsi RLS sebagai defense-in-depth.
4. Stack tidak boleh mengurangi kontrol keamanan: semua request, job, file, export, dan query tetap membawa serta memvalidasi scope tenant/unit.

## Batas keputusan

ADR ini tidak mengesahkan versi patch dependency, library RBAC, queue backend, provider object storage, atau desain deployment. Keputusan tersebut memerlukan PoC dan/atau ADR tersendiri.

Tidak ada migration aplikasi yang boleh dibuat berdasarkan rekomendasi stack ini sebelum PoC PostgreSQL dan gerbang database pada ADR-006 terpenuhi.

## Kriteria penerimaan PoC stack

- Aplikasi dapat dibangun dan dijalankan dengan versi runtime yang didukung.
- Authentication, session, CSRF, validation, dan authorization dapat diuji.
- Vue/Inertia mendukung kebutuhan form, tabel, navigasi, dan tampilan responsif.
- Test suite berjalan konsisten di CI.
- Tidak ada dependency kritis yang tidak terpelihara atau tidak kompatibel.
- Deployment, konfigurasi secret, logging, dan health check dapat direproduksi.
- PoC dapat dijalankan tanpa menyentuh repository atau deployment SQLRadius.

## Keputusan akhir stack

Setelah hasil PoC ditinjau, pemilik produk menyetujui atau mengubah rekomendasi stack aplikasi. Perubahan status menjadi Accepted harus disertai versi runtime/framework yang dipatok dan alasan keputusan.
