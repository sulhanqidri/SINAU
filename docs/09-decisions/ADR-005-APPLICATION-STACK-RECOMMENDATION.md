# ADR-005: Stack Aplikasi SINAU

- **Status:** Accepted untuk bootstrap aplikasi web awal — keputusan ini tidak mengizinkan migration domain/production deployment.
- **Tanggal keputusan:** 2026-11-19
- **Area:** Backend, frontend, runtime, framework, deployment awal
- **Disetujui pemilik produk:** persetujuan untuk melanjutkan bootstrap setelah rekomendasi stack disampaikan.
- **Terkait:** SYSTEM-ARCHITECTURE.md, IMPLEMENTATION-PLAN.md, ADR-006, ADR-007, ADR-008.

## Konteks

SINAU membutuhkan fondasi modular monolith yang dapat dipelihara, UI web responsif, autentikasi server-side, API ter-versioning di fase berikutnya, antrean pekerjaan, test automation, dan tenant/unit isolation. Resource infrastruktur terbatas; bootstrap harus memakai server PostgreSQL yang tersedia dan tidak menambah VPS atau service wajib.

## Keputusan stack untuk bootstrap

| Lapisan | Keputusan | Batas |
|---|---|---|
| Backend | Laravel 13 | Modular monolith; bukan microservices |
| Runtime | PHP 8.4 sebagai baseline bootstrap | Laravel 13 mendukung PHP 8.3–8.5; host harus lulus preflight extensions dan dependency |
| Frontend | Official Laravel Vue starter kit | Vue 3 Composition API + TypeScript |
| SPA/navigation | Inertia 3 | Same-origin server session; bukan SPA API terpisah |
| Styling | Tailwind CSS 4 + shadcn-vue | Design tokens SINAU akan ditambahkan setelah shell siap |
| Authentication web | Laravel Fortify melalui official starter kit | Detail session dan onboarding di ADR-008 |
| Database | PostgreSQL 18 | **Accepted — ADR-006** |
| Database connection | Koneksi PostgreSQL langsung | Tidak memasang PgBouncer/PgCat/Odyssey pada tahap ini |
| Queue/cache | Database-backed terlebih dahulu bila diperlukan | Redis bukan prasyarat bootstrap |
| Session store | Laravel database session | Tidak membutuhkan Redis; session table global/non-tenant |
| File | Local private storage sebagai baseline awal | Object storage S3-compatible ditunda sampai kebutuhan/host ditetapkan |
| API | REST versioned sebagai arah arsitektur | API authentication/Sanctum belum diaktifkan pada bootstrap web |
| CI | GitHub Actions | Composer checks, frontend build, tests, static/security checks bertahap |

Laravel 13 saat ini mendukung PHP 8.3–8.5. Baseline proyek memilih PHP 8.4 agar runtime awal tunggal dan dependency dapat dipatok secara konsisten; server harus diperiksa sebelum instalasi. [Laravel Release Notes](https://laravel.com/framework/docs/13.x/releases).

Official Vue starter kit menyediakan Vue 3 Composition API, TypeScript, Inertia, Tailwind, dan shadcn-vue. Starter kits menggunakan Laravel Fortify untuk alur autentikasi. SINAU menggunakan starter kit Vue dengan Laravel built-in authentication; tidak memilih WorkOS pada bootstrap. [Laravel Starter Kits](https://laravel.com/framework/docs/13.x/starter-kits).

## Keputusan implementasi awal

1. Gunakan official Laravel Vue starter kit, tanpa fitur Teams. Teams bawaan tidak menggantikan model Tenant + Education Unit SINAU.
2. Pertahankan global `users` terpisah dari tenant/unit membership. Action registrasi hanya membuat global identity; tenant/unit dan membership dibuat oleh onboarding flow setelah email terverifikasi.
3. Gunakan Fortify/session untuk web. Tidak ada API bearer token atau Personal Access Token pada bootstrap awal.
4. Ikuti ADR-008 untuk cookie/session lifecycle, registration boundary, email verification, login rate limit, dan 2FA.
5. Gunakan database PostgreSQL terpisah untuk application PoC setelah dibuat secara eksplisit. Jangan memakai `sinau_design_poc` sebagai database aplikasi; DB tersebut khusus script uji RLS/context.
6. Tidak ada service Redis atau pooler baru. Koneksi langsung ke PostgreSQL pada host yang tersedia untuk fase awal.
7. Jangan mengubah atau menggunakan deployment/repository SQLRadius sebagai tempat aplikasi SINAU. Repository dan direktori aplikasi harus terpisah.
8. Jangan menambahkan domain migration siswa/akademik sebelum database design/PoC, ownership matrix, permission, dan test harness disetujui.

## Alasan

- Laravel + Inertia + Vue memungkinkan backend dan UI berada dalam satu modular monolith tanpa menambah deployment API/frontend terpisah.
- Official starter kit menyediakan auth scaffolding yang dapat disesuaikan dan mengurangi boilerplate.
- PostgreSQL 18 sudah dipilih melalui ADR-006 dan PoC database/RLS telah menyediakan baseline teknis.
- Session/queue/cache database menghindari service tambahan pada kapasitas infrastruktur sekarang.
- Tenant/unit scope tetap berada pada domain SINAU, bukan dipetakan ke Teams starter kit.
- Pengembangan dilakukan pada direktori/repository SINAU yang terpisah; tidak menyentuh SQLRadius.

## Batas keputusan

ADR ini menyetujui stack untuk bootstrap web awal, bukan semua pilihan produksi. Hal berikut tetap terbuka:
- patch version Laravel/PHP dan dependency lock yang akan dihasilkan oleh installer pada hari bootstrap;
- API/mobile authentication dan Sanctum;
- queue/cache backend jangka panjang dan kebutuhan Redis;
- pooler dan connection topology jika ada pengukuran kebutuhan kapasitas;
- S3-compatible storage provider;
- deployment/reverse proxy/observability/backup;
- RBAC library dan permission catalog final;
- final schema identity/membership dan production migration gates.

## Kriteria penerimaan bootstrap

- Laravel 13 application scaffold terbuat dari official Vue starter kit.
- PHP runtime memenuhi requirements dan extension PostgreSQL tersedia.
- Composer dependency install dan npm production build berhasil.
- Login, logout, password reset, email verification, CSRF, session rotation, rate limit, dan 2FA flow dapat dites.
- Public registration hanya membuat global user; tidak memberikan tenant, unit, role, atau platform privilege.
- Database aplikasi terpisah dari `sinau_design_poc` dan dari database SQLRadius.
- Tidak ada `.env`, APP_KEY, password, session secret, signing key, atau credential yang masuk Git.
- CI berjalan dan application smoke tests lulus.
- PoC dapat dijalankan pada resource host yang tersedia tanpa menambah server/pooler/Redis.

## Keputusan database

PostgreSQL 18 sebagai database utama tetap Accepted melalui [ADR-006](ADR-006-POSTGRESQL-DATABASE.md). Skema application bootstrap hanya mencakup kebutuhan framework/auth. Migration domain SINAU tetap menunggu gerbang PoC, authorization, backup/restore, dan persetujuan pemilik produk.

