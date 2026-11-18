# Changelog

Perubahan penting SINAU dicatat di sini dengan tanggal YYYY-MM-DD.

## [Unreleased]
### Added
- ADR-006 yang menetapkan PostgreSQL 18 sebagai database utama SINAU.
- Rencana PoC PostgreSQL 18 untuk validasi schema, tenant isolation, concurrency, performa, backup, dan restore.
- Konstitusi proyek, aturan pengembangan, dan pengendalian perubahan.
- Blueprint produk, arsitektur, multi-tenant, dan roadmap.
- Kebutuhan produk, ruang lingkup MVP, matriks role, dan acceptance criteria.
- Model domain, ERD konseptual, kamus data, dan aturan integritas data.
- Pedoman design system, UX, aksesibilitas, dan inventaris layar.
- Evaluasi opsi teknologi dan rencana implementasi fondasi.

### Changed
- ADR-002, ADR-005, evaluasi teknologi, dan rencana implementasi diselaraskan dengan keputusan PostgreSQL 18.
- PoC resmi difokuskan pada PostgreSQL; draft MySQL 8.4 dipertahankan sebagai artefak historis dan bukan target MVP.

### Notes
- PostgreSQL 18 telah dipilih oleh pemilik produk, tetapi PoC teknis belum dijalankan.
- Belum ada migration database domain produksi.
- Dokumen kebutuhan produk lainnya tetap memerlukan validasi calon pengguna.
