# Decision Log

| Tanggal | Keputusan | Status | Referensi |
|---|---|---|---|
| 2026-11-18 | Nama proyek/repository SINAU | Confirmed | README.md |
| 2026-11-18 | Target sekolah umum dan madrasah | Confirmed | PROJECT-CONSTITUTION.md |
| 2026-11-18 | Dokumentasi menjadi acuan pengembangan | Confirmed | docs/00-governance/ |
| 2026-11-18 | Modular monolith sebagai arah awal | Proposed baseline | SYSTEM-ARCHITECTURE.md |
| 2026-11-18 | Stack aplikasi: Laravel 13, Vue 3, Inertia, Tailwind; detail runtime/dependency tetap menunggu PoC | Proposed recommendation; PoC required | ADR-005-APPLICATION-STACK-RECOMMENDATION.md |
| 2026-11-18 | PostgreSQL 18 sebagai database utama SINAU | Accepted — keputusan pemilik produk; PoC teknis wajib sebelum migration produksi | ADR-006-POSTGRESQL-DATABASE.md |
| 2026-11-18 | Shared database/shared schema sebagai baseline MVP dengan tenant_id, unit_id, composite FK, dan jalur evolusi ke sharding | Accepted baseline; PoC integritas dan keamanan wajib | ADR-002-DATABASE-ISOLATION-STRATEGY.md; DATABASE-POC-PLAN.md |
| 2026-11-18 | Tenant mendukung yayasan multi-unit dan sekolah/madrasah mandiri | Accepted product decision | ADR-001-TENANT-CUSTOMER-MODEL.md |
| 2026-11-18 | Identitas global, tenant/unit membership terpisah, default deny | Proposed authorization baseline | ADR-003-AUTHORIZATION-SCOPE.md |
| 2026-11-18 | Dokumen legal/NPSN/NSM dapat dilengkapi saat verifikasi; tenggat verifikasi 7 hari kalender lalu suspend bila persyaratan belum diserahkan; multi-unit mengikuti entitlement; verifikasi terpisah dari subscription | Accepted product decision | ADR-004-ONBOARDING-VERIFICATION-AND-UNIT-ENTITLEMENTS.md |

Accepted berarti keputusan telah disepakati. Implementasi database produksi tetap menunggu PoC teknis, pengujian isolasi, dan persetujuan gerbang migration. Proposed baseline menjadi arah desain yang harus divalidasi sebelum implementasi sensitif.
