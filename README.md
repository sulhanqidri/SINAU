# SINAU

**Sistem Informasi dan Administrasi Pendidikan Terpadu**

SINAU adalah platform SaaS multi-tenant untuk mengelola operasional pendidikan di Indonesia. Platform dirancang untuk melayani sekolah umum dan madrasah dalam satu aplikasi, dengan konfigurasi yang menghormati perbedaan jenjang, jenis lembaga, kurikulum, dan ketentuan yang berlaku.

> **Prinsip produk:** Satu Platform, Seluruh Kebutuhan Pendidikan.

## Cakupan lembaga
- Sekolah umum: SD, SMP, SMA, SMK.
- Madrasah: MI, MTs, MA, MAK.
- RA dapat dipertimbangkan dalam tahap pengembangan berikutnya, setelah discovery dan persetujuan scope.

## Prinsip pengembangan
1. Dokumentasi proyek adalah acuan utama sebelum implementasi.
2. Modular monolith sebagai arsitektur awal.
3. SaaS multi-tenant dengan isolasi data yang ketat.
4. PostgreSQL 18 ditetapkan sebagai database utama; schema dan operasional tetap melalui PoC sebelum migration produksi.
5. Sekolah umum dan madrasah didukung melalui konfigurasi dan modul yang sesuai, bukan asumsi bahwa aturan keduanya identik.
6. Konsistensi UI/UX dijaga melalui satu design system.
7. Keamanan, privasi data peserta didik, audit, dan integritas data adalah persyaratan inti.
8. Pengembangan dilakukan bertahap melalui pengujian dan preproduction sebelum production.
9. Perubahan ruang lingkup, arsitektur, skema data, dan desain harus didokumentasikan.
10. Status pekerjaan dan sesi lanjutan wajib dicatat di Project Progress Tracker.

## Mulai membaca — urutan wajib
1. [Project Progress & Handoff Tracker](docs/00-governance/PROJECT-PROGRESS.md) — posisi pekerjaan, status, checkpoint, dan next action.
2. [Konstitusi Proyek](docs/00-governance/PROJECT-CONSTITUTION.md)
3. [Aturan Pengembangan](docs/00-governance/DEVELOPMENT-RULES.md)
4. [Pengendalian Perubahan](docs/00-governance/CHANGE-CONTROL.md)
5. [Blueprint Utama](docs/01-blueprint/MASTER-BLUEPRINT.md)
6. [Katalog Kelengkapan Blueprint](docs/01-blueprint/BLUEPRINT-CATALOG.md) — daftar semua blueprint yang wajib disiapkan.
7. [Rencana Implementasi Fondasi](docs/01-blueprint/IMPLEMENTATION-PLAN.md)
8. [Rencana PoC Database dan Isolasi Tenant](docs/01-blueprint/DATABASE-POC-PLAN.md)

## Kebutuhan dan domain
- [Kebutuhan Produk](docs/02-requirements/PRODUCT-REQUIREMENTS.md)
- [Ruang Lingkup MVP](docs/02-requirements/MVP-SCOPE.md)
- [Peta Proses Bisnis End-to-End](docs/02-requirements/BUSINESS-PROCESS-MAP.md)
- [Model Domain dan Database](docs/03-database/DOMAIN-MODEL.md)
- [ERD Konseptual](docs/03-database/ERD-CONCEPTUAL.md)
- [Design System](docs/03-design-system/README.md)
- [Dukungan Sekolah Umum](docs/04-education/GENERAL-SCHOOLS.md)
- [Dukungan Madrasah](docs/04-education/MADRASAH.md)
- [Strategi Pengujian](docs/07-testing/TEST-STRATEGY.md)

## Keputusan arsitektur
- [ADR Model Tenant/Pelanggan](docs/09-decisions/ADR-001-TENANT-CUSTOMER-MODEL.md)
- [ADR Strategi Isolasi Database Tenant](docs/09-decisions/ADR-002-DATABASE-ISOLATION-STRATEGY.md)
- [ADR Authorization Scope](docs/09-decisions/ADR-003-AUTHORIZATION-SCOPE.md)
- [ADR Onboarding dan Entitlement Unit](docs/09-decisions/ADR-004-ONBOARDING-VERIFICATION-AND-UNIT-ENTITLEMENTS.md)
- [ADR Rekomendasi Stack Aplikasi](docs/09-decisions/ADR-005-APPLICATION-STACK-RECOMMENDATION.md)
- [ADR Pemilihan PostgreSQL](docs/09-decisions/ADR-006-POSTGRESQL-DATABASE.md)
- [ADR Trusted Context Issuer](docs/09-decisions/ADR-007-TRUSTED-CONTEXT-ISSUER.md)
- [ADR Authentication dan Session](docs/09-decisions/ADR-008-AUTHENTICATION-AND-SESSION.md)
- [Panduan Bootstrap Aplikasi](docs/00-governance/APP-BOOTSTRAP-RUNBOOK.md)
- [Catatan Keputusan Arsitektur](docs/09-decisions/DECISION-LOG.md)

## Status proyek
**Tahap: bootstrap shell aplikasi.** PostgreSQL 18 dan stack bootstrap web (Laravel 13 + PHP 8.4 + Vue 3/Inertia 3 + Tailwind 4) telah disetujui. Baseline autentikasi web Fortify/session juga sudah dicatat. Scaffold aplikasi belum dibuat: langkah pertama adalah preflight read-only host, lalu generate official Vue starter kit pada checkout SINAU terpisah. Migration domain dan modul akademik tetap menunggu gerbang PoC database/authorization. Lihat [Project Progress Tracker](docs/00-governance/PROJECT-PROGRESS.md).

## Kontribusi dan perubahan
Baca [CONTRIBUTING.md](CONTRIBUTING.md) dan aturan di folder `docs/00-governance/` sebelum membuat perubahan.
