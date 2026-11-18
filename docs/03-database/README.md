# Database SINAU

- DOMAIN-MODEL.md — batas domain dan entitas.
- DOMAIN-OWNERSHIP-MATRIX.md — pemilik data, scope, consumer, dan kontrak lintas domain.
- ERD-CONCEPTUAL.md — relasi konseptual.
- LOGICAL-ERD-MVP.md — kandidat tabel, kolom, key, FK, dan constraint untuk MVP (draft, belum migration).
- DATA-DICTIONARY-MVP.md — kamus rinci kandidat atribut, tipe, nullability, klasifikasi, validasi, dan historisasi (Draft v0.1.0).
- DATA-DICTIONARY-BASELINE.md — ringkasan inventaris entitas terdahulu; referensikan kamus MVP untuk detail.
- DATA-INTEGRITY.md — aturan integritas.
- LOGICAL-DESIGN-CONSISTENCY-AUDIT.md — audit konsistensi MVP Scope, process specs, ownership, logical ERD, data dictionary, dan integritas (AUD-LD-001 v0.2.0; remediation proposal didokumentasikan, approval dan PoC masih pending).

Dokumen ini belum menjadi migration final. Semua pilihan tipe ID, engine, normalisasi, index, constraint, tenancy strategy, dan naming convention harus disahkan melalui ADR sebelum implementasi.
