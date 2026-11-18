# Lingkungan Pengembangan dan Rilis

## Lingkungan
- **Local/development:** pengembangan fitur; gunakan data sintetis.
- **CI:** test otomatis, static checks, dependency/security checks.
- **Preproduction:** konfigurasi mendekati production untuk acceptance, migration rehearsal, dan smoke test.
- **Production:** lingkungan pengguna; perubahan melalui proses rilis yang disetujui.

## Aturan
- Jangan menguji dengan data pribadi nyata kecuali ada dasar, izin, minimisasi, dan perlindungan yang disetujui.
- Pisahkan kredensial dan secret setiap lingkungan.
- Jangan menyalin database production ke development tanpa sanitasi dan otorisasi.
- Migration harus direhearsal di preproduction.
- Deployment harus memiliki prosedur rollback atau forward-fix.
- Backup dan pemulihan diuji berkala.
- Rilis dicatat dengan versi, commit, perubahan database, dan hasil smoke test.
