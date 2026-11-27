# Database SINAU

- DOMAIN-MODEL.md — batas domain dan entitas.
- DOMAIN-OWNERSHIP-MATRIX.md — pemilik data, scope, consumer, dan kontrak lintas domain.
- ERD-CONCEPTUAL.md — relasi konseptual.
- LOGICAL-ERD-MVP.md — kandidat tabel, kolom, key, FK, dan constraint untuk MVP (draft, belum migration).
- DATA-DICTIONARY-MVP.md — kamus rinci kandidat atribut, tipe, nullability, klasifikasi, validasi, dan historisasi (proposal v0.2.0; menunggu review).
- DATA-DICTIONARY-BASELINE.md — ringkasan inventaris entitas terdahulu; referensikan kamus MVP untuk detail.
- DATA-INTEGRITY.md — aturan integritas.
- LOGICAL-DESIGN-CONSISTENCY-AUDIT.md — audit konsistensi MVP Scope, process specs, ownership, logical ERD, data dictionary, dan integritas (AUD-LD-001 v0.2.0; remediation proposal didokumentasikan, approval dan PoC masih pending).

Dokumen ini belum menjadi migration final. Semua pilihan tipe ID, engine, normalisasi, index, constraint, tenancy strategy, dan naming convention harus disahkan melalui ADR sebelum implementasi.

- `poc/README.md` — panduan PoC PostgreSQL 18 terisolasi; `poc/001-schema.sql` dan `poc/002-tests.sql` adalah eksperimen desain, bukan migration produksi. Eksekusi dan bukti hasil masih pending.
