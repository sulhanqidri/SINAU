# Evaluasi Opsi Teknologi SINAU

**Status:** Rekomendasi awal, belum Accepted.

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
| Backend | Laravel + PHP | Selaras dengan pengalaman tim; cek kompatibilitas versi dan dependency |
| Frontend | Vue 3 + Inertia | SPA-like UX tanpa memisahkan backend/frontend sejak awal |
| UI styling | Tailwind CSS + design tokens | Konsistensi komponen; versi final ditetapkan saat bootstrap |
| Database | PostgreSQL atau MySQL/MariaDB | Bandingkan constraint, JSON, tooling, hosting, dan keahlian tim |
| Cache/queue | Redis | Gunakan hanya untuk kebutuhan yang terukur; job tenant-aware |
| API | REST dengan versioning | Kontrak jelas untuk integrasi dan aplikasi mobile di masa depan |
| Auth API | Sanctum atau mekanisme setara | Pilih sesuai web/mobile client dan threat model |
| File | S3-compatible private object storage | File privat, signed access, lifecycle dan backup |
| Web server | Nginx | Operasional umum dan mudah diotomasi |
| Runtime | Linux LTS | Pin versi runtime dan patch secara terencana |
| CI | GitHub Actions | Test, lint, static/security checks |

## Rekomendasi awal
Evaluasi pertama yang disarankan: Laravel + Vue 3 + Inertia + Tailwind, dengan PostgreSQL dan MySQL/MariaDB dibandingkan melalui proof-of-concept singkat. Jangan mengunci versi dependency atau database sebelum menguji constraint multi-tenant, migration, backup/restore, dan kebutuhan laporan.

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
