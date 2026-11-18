# Rencana Implementasi Fondasi

## Tahap A — Validasi produk
- Wawancara operator sekolah umum dan madrasah.
- Validasi model yayasan/tenant/unit.
- Konfirmasi skenario MVP dan laporan wajib.
- Tandai requirement Approved/Deferred/Rejected.

## Tahap B — Keputusan teknis
- PoC Laravel + Vue/Inertia.
- Bandingkan PostgreSQL dengan MySQL/MariaDB untuk composite constraints dan query laporan.
- Uji autentikasi, authorization, tenant context, queue, file private.
- Terbitkan ADR.

## Tahap C — UX baseline
- Pilih arah brand visual.
- Buat prototipe dashboard, tabel siswa, form siswa, setup tahun ajaran, presensi.
- Review dengan pengguna desktop dan ponsel.
- Tetapkan tokens dan komponen dasar.

## Tahap D — Database dan test harness
- Finalisasi ERD dan dictionary.
- Bangun fixture dua tenant dan beberapa unit.
- Implementasikan tes isolasi tenant/unit sebelum fitur domain.
- Uji migration dan data integrity.

## Tahap E — Bootstrap aplikasi
Baru setelah A-D disetujui: buat struktur kode, CI, lint/static analysis, auth, tenant context, audit, dan shell UI.

## Gerbang
Jangan melompat ke modul akademik sebelum tenant isolation, membership, permission, dan test harness berjalan.
