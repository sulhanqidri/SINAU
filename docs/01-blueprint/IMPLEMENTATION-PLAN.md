# Rencana Implementasi Fondasi

## Tahap A — Validasi produk
- Wawancara operator sekolah umum dan madrasah.
- Validasi model yayasan/tenant/unit.
- Konfirmasi skenario MVP dan laporan wajib.
- Tandai requirement Approved/Deferred/Rejected.

## Tahap B — Keputusan teknis
- Gunakan ADR-005 sebagai rekomendasi stack aplikasi: Laravel 13 + Vue 3 + Inertia + Tailwind; runtime PHP 8.4/8.5 diuji sebelum dipatok.
- PostgreSQL 18 telah dipilih sebagai database utama melalui ADR-006.
- Jalankan [DATABASE-POC-PLAN.md](DATABASE-POC-PLAN.md) pada PostgreSQL 18 untuk memvalidasi shared database/shared schema, tenant_id + unit_id, composite FK, transaksi concurrency, raw SQL, dan opsi RLS.
- Uji authentication, membership resolver, authorization policy, tenant/unit context, queue, private file, cache, dan export.
- Evaluasi RLS sebagai defense-in-depth; jangan jadikan satu-satunya kontrol.
- Terbitkan ADR terpisah untuk session/token, RBAC, queue/cache, storage, deployment, dan observability.

## Gerbang Tahap B
- Engine database target sudah ditetapkan: PostgreSQL 18.
- Semua tes integritas dan authorization tenant/unit harus lulus; satu bypass lintas tenant adalah blocker.
- Pemilik produk meninjau hasil PoC PostgreSQL sebelum migration domain.
- Tidak ada migration produksi sebelum gerbang PoC integritas, backup/restore, dan kesiapan operasional terpenuhi.

## Tahap C — UX baseline
- Pilih arah brand visual.
- Buat prototipe dashboard, tabel siswa, form siswa, setup tahun ajaran, presensi, dan pemilih tenant/unit.
- Review dengan pengguna desktop dan ponsel.
- Tetapkan tokens dan komponen dasar.
- Tampilkan konteks tenant dan unit aktif secara jelas agar pengguna tidak salah mengelola data.

## Tahap D — Database dan test harness
- Finalisasi ERD dan dictionary dengan PostgreSQL sebagai target.
- Bangun fixture sintetis: foundation dengan beberapa unit (termasuk sekolah umum dan madrasah), serta tenant mandiri.
- Implementasikan TenantContext, UnitContext, membership, authorization, audit, dan tes isolasi sebelum fitur domain.
- Uji composite unique/FK pada PostgreSQL 18.
- Uji IDOR, raw SQL, bulk, file, export, cache, search, queue, scheduler, dan membership revocation.
- Uji backup/restore dan rencana pemulihan.

## Tahap E — Bootstrap aplikasi
Baru setelah A-D disetujui: buat struktur kode, CI, lint/static analysis, authentication, tenant/unit context, audit, private storage, dan shell UI.

## Gerbang
Jangan melompat ke modul akademik sebelum tenant isolation, membership, permission, database constraints, dan test harness berjalan. Tidak ada migration produksi sebelum PoC PostgreSQL dan kesiapan operasional disetujui.
