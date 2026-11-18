# ADR-005: Rekomendasi Stack Aplikasi

- **Status:** Proposed — menunggu PoC dan persetujuan pemilik produk
- **Tanggal:** 2026-11-18
- **Area:** Backend, frontend, runtime, framework
- **Terkait:** SYSTEM-ARCHITECTURE.md, TECHNOLOGY-OPTIONS.md, IMPLEMENTATION-PLAN.md

## Konteks

SINAU membutuhkan fondasi yang dapat dipelihara sebagai modular monolith, mendukung UI web responsif, API ter-versioning, antrean pekerjaan, autentikasi, pengujian otomatis, dan isolasi tenant/unit. Stack harus dipilih berdasarkan kompatibilitas, keamanan, kemampuan tim, biaya operasional, serta hasil PoC — bukan hanya popularitas framework.

## Rekomendasi awal

| Lapisan | Rekomendasi untuk PoC | Status |
|---|---|---|
| Backend | Laravel 13 | Kandidat utama |
| Runtime | PHP 8.4 dan 8.5 diuji; pilih satu versi yang didukung penuh oleh dependency | Belum final |
| Frontend | Vue 3 + Inertia | Kandidat utama |
| Styling | Tailwind CSS dengan design tokens SINAU | Kandidat utama |
| API | REST dengan versioning eksplisit | Arah desain |
| Authentication | Session untuk web; evaluasi Sanctum untuk API/client pihak pertama | Belum final |
| Database | PostgreSQL 18 sebagai kandidat utama; MySQL 8.4 LTS sebagai pembanding | Menunggu ADR database |
| Queue/cache | Redis bila dibutuhkan; jangan menjadikannya prasyarat untuk seluruh proses MVP sebelum beban diukur | Belum final |
| File | Private S3-compatible object storage melalui abstraction | Belum final |
| CI | GitHub Actions untuk test, lint, static analysis, dan security checks | Kandidat utama |

Laravel 13 menjadi kandidat karena jadwal rilis dan masa dukungan resminya masih sesuai untuk proyek baru pada tanggal ADR ini. Laravel 13 mendukung PHP 8.3–8.5; versi runtime yang dipilih tetap harus diuji terhadap seluruh dependency dan image deployment. [Referensi: Laravel Release Notes](https://laravel.com/docs/releases).

PostgreSQL 18 menjadi kandidat database utama untuk PoC karena menyediakan constraint relasional yang kuat, partial indexes, serta Row-Level Security sebagai defense-in-depth opsional. RLS tidak menggantikan scope query dan authorization aplikasi. PostgreSQL 18 masih berada dalam periode dukungan resmi hingga November 2030. [Referensi: PostgreSQL Versioning Policy](https://www.postgresql.org/support/versioning/).

MySQL 8.4 LTS tetap menjadi pembanding yang sah. Pengujian wajib memakai InnoDB dan definisi foreign key eksplisit; jangan mengandalkan inline REFERENCES. Perhatikan juga keterbatasan foreign key pada tabel InnoDB yang dipartisi. [Referensi: MySQL 8.4 Reference Manual — ALTER TABLE](https://dev.mysql.com/doc/refman/8.4/en/alter-table.html).

## Alasan rekomendasi

1. Laravel + Vue + Inertia memungkinkan tim membangun pengalaman web interaktif tanpa memecah backend dan frontend menjadi dua deployment sejak awal.
2. Modular monolith tetap dapat memisahkan domain, application service, policy, dan infrastruktur secara disiplin.
3. PostgreSQL layak diuji pertama untuk kebutuhan constraint, query laporan, dan opsi RLS.
4. MySQL 8.4 LTS tetap diuji agar keputusan tidak mengabaikan kompetensi tim, pilihan hosting, dan biaya operasional.
5. Stack tidak boleh mengurangi kontrol keamanan: semua request, job, file, export, dan query tetap membawa serta memvalidasi scope tenant/unit.

## Batas keputusan

ADR ini **tidak mengesahkan database final**, versi patch dependency, library RBAC, queue backend, provider object storage, atau desain deployment. Keputusan tersebut memerlukan PoC dan/atau ADR tersendiri.

Tidak ada migration aplikasi yang boleh dibuat berdasarkan rekomendasi ini sebelum ADR database disetujui.

## Kriteria penerimaan PoC stack

- Aplikasi dapat dibangun dan dijalankan dengan versi runtime yang didukung.
- Authentication, session, CSRF, validation, dan authorization dapat diuji.
- Vue/Inertia mendukung kebutuhan form, tabel, navigasi, dan tampilan responsif.
- Test suite berjalan konsisten di CI.
- Tidak ada dependency kritis yang tidak terpelihara atau tidak kompatibel.
- Deployment, konfigurasi secret, logging, dan health check dapat direproduksi.
- PoC dapat dijalankan tanpa menyentuh repository atau deployment SQLRadius.

## Keputusan akhir

Setelah hasil PoC ditinjau, pemilik produk menyetujui atau mengubah rekomendasi ini. Perubahan status menjadi Accepted harus disertai versi runtime/framework yang dipatok dan alasan keputusan.
