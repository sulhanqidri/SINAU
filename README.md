# SINAU

**Sistem Informasi dan Administrasi Pendidikan Terpadu**

SINAU adalah platform SaaS multi-tenant untuk mengelola operasional pendidikan di Indonesia. Platform dirancang untuk melayani sekolah umum dan madrasah dalam satu aplikasi, dengan konfigurasi yang menghormati perbedaan jenjang, jenis lembaga, kurikulum, dan ketentuan yang berlaku.

> **Prinsip produk:** Satu Platform, Seluruh Kebutuhan Pendidikan.

## Cakupan lembaga
- Sekolah umum: SD, SMP, SMA, SMK.
- Madrasah: MI, MTs, MA, MAK.
- RA dapat dipertimbangkan dalam tahap pengembangan berikutnya.

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

## Mulai membaca
- [Konstitusi Proyek](docs/00-governance/PROJECT-CONSTITUTION.md)
- [Aturan Pengembangan](docs/00-governance/DEVELOPMENT-RULES.md)
- [Pengendalian Perubahan](docs/00-governance/CHANGE-CONTROL.md)
- [Blueprint Utama](docs/01-blueprint/MASTER-BLUEPRINT.md)
- [Rencana Implementasi Fondasi](docs/01-blueprint/IMPLEMENTATION-PLAN.md)
- [Evaluasi Teknologi](docs/01-blueprint/TECHNOLOGY-OPTIONS.md)
- [Rencana PoC Database dan Isolasi Tenant](docs/01-blueprint/DATABASE-POC-PLAN.md)
- [ADR Strategi Isolasi Database Tenant](docs/09-decisions/ADR-002-DATABASE-ISOLATION-STRATEGY.md)
- [ADR Rekomendasi Stack Aplikasi](docs/09-decisions/ADR-005-APPLICATION-STACK-RECOMMENDATION.md)
- [ADR Pemilihan PostgreSQL](docs/09-decisions/ADR-006-POSTGRESQL-DATABASE.md)
- [Kebutuhan Produk](docs/02-requirements/PRODUCT-REQUIREMENTS.md)
- [Ruang Lingkup MVP](docs/02-requirements/MVP-SCOPE.md)
- [Model Domain dan Database](docs/03-database/DOMAIN-MODEL.md)
- [Design System](docs/03-design-system/README.md)
- [Dukungan Sekolah Umum](docs/04-education/GENERAL-SCHOOLS.md)
- [Dukungan Madrasah](docs/04-education/MADRASAH.md)
- [Strategi Pengujian](docs/07-testing/TEST-STRATEGY.md)
- [Catatan Keputusan Arsitektur](docs/10-decisions/README.md)

## Status proyek
**Tahap: Fondasi dan perencanaan.** PostgreSQL 18 telah dipilih. Stack aplikasi, skema database produksi, dan modul operasional masih harus divalidasi sebelum implementasi.

## Kontribusi dan perubahan
Baca [CONTRIBUTING.md](CONTRIBUTING.md) dan aturan di folder docs/00-governance/ sebelum membuat perubahan.
