# Rencana Implementasi Fondasi

## Tahap A — Validasi produk
- Wawancara operator sekolah umum dan madrasah.
- Validasi model yayasan/tenant/unit.
- Konfirmasi skenario MVP dan laporan wajib.
- Tandai requirement Approved/Deferred/Rejected.

## Tahap B — Keputusan teknis
- PoC Laravel + Vue/Inertia.
- Bandingkan PostgreSQL dengan MySQL/MariaDB untuk composite constraints, transaction behavior, dan query laporan.
- PoC shared database/shared schema dengan tenant_id + unit_id dan composite FK.
- Uji authentication, membership resolver, authorization policy, tenant/unit context, queue, private file, cache, dan export.
- Evaluasi RLS bila engine mendukung; jangan jadikan satu-satunya kontrol.
- Terbitkan ADR untuk engine, session/token, RBAC, dan storage.

## Tahap C — UX baseline
- Pilih arah brand visual.
- Buat prototipe dashboard, tabel siswa, form siswa, setup tahun ajaran, presensi, dan pemilih tenant/unit.
- Review dengan pengguna desktop dan ponsel.
- Tetapkan tokens dan komponen dasar.
- Tampilkan konteks tenant dan unit aktif secara jelas agar pengguna tidak salah mengelola data.

## Tahap D — Database dan test harness
- Finalisasi ERD dan dictionary.
- Bangun fixture sintetis: foundation dengan beberapa unit (termasuk sekolah umum dan madrasah), serta tenant mandiri.
- Implementasikan TenantContext, UnitContext, membership, authorization, audit, dan tes isolasi sebelum fitur domain.
- Uji composite unique/FK pada engine database target.
- Uji IDOR, raw SQL, bulk, file, export, cache, search, queue, scheduler, dan membership revocation.
- Uji backup/restore dan rencana pemulihan.

## Tahap E — Bootstrap aplikasi
Baru setelah A-D disetujui: buat struktur kode, CI, lint/static analysis, authentication, tenant/unit context, audit, private storage, dan shell UI.

## Gerbang
Jangan melompat ke modul akademik sebelum tenant isolation, membership, permission, database constraints, dan test harness berjalan. Tidak ada migration produksi sebelum ADR engine database dan PoC integritas disetujui.
