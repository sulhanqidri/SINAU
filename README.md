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
4. Sekolah umum dan madrasah didukung melalui konfigurasi dan modul yang sesuai, bukan asumsi bahwa aturan keduanya identik.
5. Konsistensi UI/UX dijaga melalui satu design system.
6. Keamanan, privasi data peserta didik, audit, dan integritas data adalah persyaratan inti.
7. Pengembangan dilakukan bertahap melalui pengujian dan preproduction sebelum production.
8. Perubahan ruang lingkup, arsitektur, skema data, dan desain harus didokumentasikan.

## Mulai membaca

- [Konstitusi Proyek](docs/00-governance/PROJECT-CONSTITUTION.md)
- [Aturan Pengembangan](docs/00-governance/DEVELOPMENT-RULES.md)
- [Pengendalian Perubahan](docs/00-governance/CHANGE-CONTROL.md)
- [Blueprint Utama](docs/01-blueprint/MASTER-BLUEPRINT.md)
- [Arsitektur Sistem](docs/01-blueprint/SYSTEM-ARCHITECTURE.md)
- [Arsitektur Multi-Tenant](docs/01-blueprint/MULTI-TENANT.md)
- [Design System](docs/03-design-system/DESIGN-GUIDELINES.md)
- [Dukungan Sekolah Umum](docs/04-education/GENERAL-SCHOOLS.md)
- [Dukungan Madrasah](docs/04-education/MADRASAH.md)
- [Roadmap](docs/01-blueprint/ROADMAP.md)
- [Catatan Keputusan Arsitektur](docs/10-decisions/README.md)

## Status proyek

**Tahap: Fondasi dan perencanaan.** Belum ada stack, skema database, maupun modul operasional yang dianggap final sebelum divalidasi dan dicatat pada dokumen keputusan terkait.

## Kontribusi dan perubahan

Baca [CONTRIBUTING.md](CONTRIBUTING.md) dan aturan di folder `docs/00-governance/` sebelum membuat perubahan.
