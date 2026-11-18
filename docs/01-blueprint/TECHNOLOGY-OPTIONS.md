# Evaluasi Opsi Teknologi SINAU

**Status:** Rekomendasi awal; lihat ADR-005. Belum Accepted sampai PoC dan persetujuan pemilik produk.

## Kebutuhan
- Tim dapat memelihara aplikasi jangka panjang.
- Mendukung modular monolith dan API.
- Aman untuk multi-tenant.
- UI interaktif dan responsif.
- Ekosistem matang untuk autentikasi, queue, testing, dan integrasi.
- Operasional terjangkau pada tahap awal dan dapat diskalakan.

## Opsi baseline yang layak dievaluasi
| Lapisan | Opsi awal | Catatan evaluasi |
|---|---|---|
| Backend | Laravel 13 + PHP 8.3–8.5 | Kandidat utama; uji dependency dan runtime sebelum pin versi |
| Frontend | Vue 3 + Inertia | SPA-like UX tanpa memisahkan backend/frontend sejak awal |
| UI styling | Tailwind CSS + design tokens | Konsistensi komponen; versi final ditetapkan saat bootstrap |
| Database | PostgreSQL 18 vs MySQL 8.4 LTS | Kandidat utama PostgreSQL; MySQL pembanding melalui PoC yang sama |
| Cache/queue | Redis | Gunakan hanya untuk kebutuhan yang terukur; job tenant-aware |
| API | REST dengan versioning | Kontrak jelas untuk integrasi dan aplikasi mobile di masa depan |
| Auth API | Sanctum atau mekanisme setara | Pilih sesuai web/mobile client dan threat model |
| File | S3-compatible private object storage | File privat, signed access, lifecycle dan backup |
| Web server | Nginx | Operasional umum dan mudah diotomasi |
| Runtime | Linux LTS | Pin versi runtime dan patch secara terencana |
| CI | GitHub Actions | Test, lint, static/security checks |

## Rekomendasi awal
Rekomendasi stack untuk PoC adalah Laravel 13 + Vue 3 + Inertia + Tailwind. PostgreSQL 18 menjadi kandidat utama database, sedangkan MySQL 8.4 LTS menjadi pembanding. Rekomendasi ini belum menjadi keputusan final. Jalankan skenario identik pada kedua engine sesuai [DATABASE-POC-PLAN.md](DATABASE-POC-PLAN.md). Jangan mengunci versi dependency atau database sebelum menguji constraint multi-tenant, transaksi concurrency, migration, backup/restore, dan kebutuhan laporan.

Detail rekomendasi stack dan batas keputusan tercatat pada [ADR-005](../09-decisions/ADR-005-APPLICATION-STACK-RECOMMENDATION.md).

## Kriteria keputusan
1. Keamanan dan kemampuan menegakkan tenant/unit integrity.
2. Kematangan ekosistem dan masa dukungan.
3. Kompetensi tim dan biaya operasional.
4. Performa untuk daftar, laporan, dan import.
5. Kemudahan migration, backup, restore, dan monitoring.
6. Integrasi dengan kebutuhan pendidikan Indonesia.
7. Portabilitas dan risiko vendor lock-in.

## Output yang wajib sebelum coding
ADR untuk backend/frontend, database, auth, queue/cache, storage, deployment, dan observability. Catat hasil PoC dan alasan pemilihan.
