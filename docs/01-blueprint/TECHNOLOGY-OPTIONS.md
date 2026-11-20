# Evaluasi Opsi Teknologi SINAU

**Status:** PostgreSQL 18 dipilih sebagai database utama melalui ADR-006. Stack aplikasi lainnya masih dalam tahap evaluasi.

## Kebutuhan
- Tim dapat memelihara aplikasi jangka panjang.
- Mendukung modular monolith dan API.
- Aman untuk multi-tenant.
- UI interaktif dan responsif.
- Ekosistem matang untuk autentikasi, queue, testing, dan integrasi.
- Operasional terjangkau pada tahap awal dan dapat diskalakan.

## Baseline teknologi
| Lapisan | Opsi | Catatan evaluasi |
|---|---|---|
| Backend | Laravel 13 + PHP 8.3–8.5 | Kandidat utama; uji dependency dan runtime sebelum pin versi |
| Frontend | Vue 3 + Inertia | SPA-like UX tanpa memisahkan backend/frontend sejak awal |
| UI styling | Tailwind CSS + design tokens | Konsistensi komponen; versi final ditetapkan saat bootstrap |
| Database | PostgreSQL 18 | **Dipilih — ADR-006; PoC skema dan operasional tetap wajib** |
| Cache/queue | Redis | Gunakan hanya untuk kebutuhan yang terukur; job tenant-aware |
| API | REST dengan versioning | Kontrak jelas untuk integrasi dan aplikasi mobile di masa depan |
| Auth API | Sanctum atau mekanisme setara | Pilih sesuai web/mobile client dan threat model |
| File | S3-compatible private object storage | File privat, signed access, lifecycle dan backup |
| Web server | Nginx | Operasional umum dan mudah diotomasi |
| Runtime | Linux LTS | Pin versi runtime dan patch secara terencana |
| CI | GitHub Actions | Test, lint, static/security checks |

## Rekomendasi stack aplikasi
Rekomendasi stack aplikasi untuk PoC adalah Laravel 13 + Vue 3 + Inertia + Tailwind. PostgreSQL 18 telah dipilih sebagai database utama berdasarkan [ADR-006](../09-decisions/ADR-006-POSTGRESQL-DATABASE.md). Pengujian berikutnya berfokus pada validasi schema, tenant isolation, transaksi concurrency, migration, backup/restore, performa, dan kebutuhan laporan pada PostgreSQL 18. Tidak ada kewajiban membandingkan MySQL sebelum implementasi.

## Kriteria keputusan komponen lain
1. Keamanan dan kemampuan menegakkan tenant/unit integrity.
2. Kematangan ekosistem dan masa dukungan.
3. Kompetensi tim dan biaya operasional.
4. Performa untuk daftar, laporan, dan import.
5. Kemudahan migration, backup, restore, dan monitoring.
6. Integrasi dengan kebutuhan pendidikan Indonesia.
7. Portabilitas dan risiko vendor lock-in.

## Output yang wajib sebelum coding
ADR untuk backend/frontend, auth, queue/cache, storage, deployment, dan observability. Catat hasil PoC PostgreSQL dan alasan keputusan komponen lainnya.
