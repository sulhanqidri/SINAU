# Runbook Bootstrap Aplikasi SINAU

- **Status:** siap dijalankan setelah pemeriksaan host
- **Tanggal:** 2026-11-19
- **Stack:** Laravel 13, PHP 8.4, official Vue starter kit, Inertia 3, Vue 3, TypeScript, Tailwind 4, Fortify, PostgreSQL 18.
- **Keputusan:** ADR-005 dan ADR-008.

## 1. Prinsip resource dan keselamatan

- Tidak perlu server/VPS baru. Gunakan host yang tersedia hanya bila pemeriksaan resource dan runtime lulus.
- Jangan memasang PgBouncer, PgCat, Odyssey, Redis, atau service tambahan untuk bootstrap.
- Jangan menjalankan perintah di /var/www/sqlradius atau mengubah konfigurasi SQLRadius.
- Jangan gunakan database sinau_design_poc sebagai database aplikasi. Database tersebut khusus fixture dan tes RLS/context.
- Database aplikasi awal harus terpisah (nama usulan sinau_app_poc) pada PostgreSQL server yang sama. Pembuatan database/role menunggu preflight dan instruksi tahap berikutnya.
- Jangan jalankan migration terhadap database produksi sinau atau gunakan role produksi sinau_app.
- Jangan commit .env, APP_KEY, password, session cookie, mail credential, atau signing key.
- Tahap ini hanya membuat application scaffold dan smoke test framework/auth. Belum membuat migration domain tenant, unit, membership, role, permission, atau akademik.

## 2. Pemeriksaan host read-only

Sebelum mengunduh dependency, periksa PHP, extension PostgreSQL, Composer, Node, npm, Git, storage, dan memory. Tidak ada perintah instalasi pada tahap ini.

Skrip pemeriksaan: scripts/check-sinau-bootstrap-host.sh.

Jalankan di Bash server:

```bash
cd ~/sinau-poc || exit 1

curl -fsSL \
  https://raw.githubusercontent.com/sulhanqidri/SINAU/feature/phase-0-requirements-blueprint/scripts/check-sinau-bootstrap-host.sh \
  -o /tmp/check-sinau-bootstrap-host.sh

bash /tmp/check-sinau-bootstrap-host.sh
```

Kirim seluruh output sebelum instalasi. Hentikan bila PHP bukan 8.4.x, pdo_pgsql tidak aktif, Composer/Node/npm tidak tersedia, atau disk/memory tidak memadai. Jangan otomatis mengganti runtime global karena host dapat menjalankan layanan lain.

## 3. Pasang Node.js untuk user sinauadmin

Preflight menemukan Node/npm belum tersedia. Jangan memasang paket Node global melalui APT atau mengubah service sistem. Gunakan NVM pada home user `sinauadmin`, sehingga Node/npm hanya berlaku untuk user tersebut.

Node.js 24.22.3 adalah rilis LTS yang tersedia pada tanggal runbook ini dan memenuhi rentang Node yang didukung Vite+ 1.x (Node 24.11.0 atau lebih baru). Gunakan NVM v0.41.0.

Jalankan di Bash sebagai `sinauadmin`, tanpa `sudo`:

```bash
cd ~/sinau-poc || exit 1

curl -fsSL \
  https://raw.githubusercontent.com/nvm-sh/nvm/v0.41.0/install.sh \
  -o /tmp/nvm-install.sh

bash /tmp/nvm-install.sh

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

nvm install 24.22.3
nvm alias default 24.22.3
nvm use default

echo "===== NODE / NPM ====="
node --version
npm --version
command -v node
command -v npm
```

Output yang diharapkan: Node `v24.22.3`; npm mengikuti distribusi Node 24.22.3 (rilis tersebut membundel npm 11.19.1). NVM menambahkan pemuatan versi user ke shell profile; tidak memasang service daemon atau mengubah PHP/PostgreSQL. Jika shell SSH baru belum menemukan Node, muat `~/.bashrc` atau jalankan blok `export NVM_DIR... source nvm.sh` di atas.

Jangan jalankan `sudo npm install -g`. Dependency aplikasi harus dipasang dari direktori checkout SINAU dan dicatat dalam lockfile.

## 3. Siapkan checkout repository

Gunakan checkout terpisah dari direktori PoC dan SQLRadius:

```bash
git clone --branch feature/phase-0-requirements-blueprint \
  https://github.com/sulhanqidri/SINAU.git \
  "$HOME/SINAU"
```

Jika direktori $HOME/SINAU sudah ada, jangan menimpanya. Periksa branch, status, dan perubahan lokal terlebih dahulu.

## 4. Generate scaffold resmi (setelah preflight disetujui)

Laravel 13 menyediakan official starter kit Vue melalui Laravel installer. Perintah resmi pemasangan installer bila belum tersedia:

```bash
composer global require laravel/installer

export PATH="$HOME/.composer/vendor/bin:$HOME/.config/composer/vendor/bin:$PATH"
command -v laravel
```

Setelah installer tersedia, buat scaffold di direktori sementara. Gunakan opsi eksplisit agar tidak muncul pertanyaan yang ambigu:

```bash
laravel new "$HOME/sinau-laravel-bootstrap" \
  --vue \
  --pest \
  --no-boost \
  --no-node
```

Arti opsi:
- `--vue`: official Vue starter kit, dengan built-in Laravel authentication karena WorkOS tidak dipilih.
- `--pest`: gunakan Pest.
- `--no-boost`: jangan menambah package Laravel Boost pada host terbatas.
- `--no-node`: jangan menjalankan npm otomatis sebelum scaffold direview.
- Jangan gunakan `--teams`, `--workos`, atau `--no-authentication`.

Untuk starter kit, Laravel installer memakai SQLite sementara secara default dan hook starter kit menjalankan migration framework pada file SQLite di dalam scaffold. Itu hanya database sementara untuk menghasilkan shell; bukan database aplikasi SINAU. Setelah scaffold digabung, buang file SQLite dari tracked source bila ikut masuk, dan jangan gunakan database itu untuk data SINAU. Database aplikasi tetap PostgreSQL terpisah `sinau_app_poc`, yang belum dibuat. Konfigurasi PostgreSQL dan migration hanya dilakukan setelah role/database PoC aplikasi disiapkan secara eksplisit.


## 5. Gabungkan scaffold ke checkout SINAU

Pastikan $HOME/SINAU adalah checkout branch yang benar dan tidak punya perubahan lokal yang belum diamankan. Gabungkan file starter kit tanpa menyalin runtime dependencies atau file secret:

```bash
cd "$HOME/SINAU" || exit 1

git branch --show-current
git status --short

rsync -a --ignore-existing \
  --exclude='.env' \
  --exclude='.env.*.local' \
  --exclude='vendor/' \
  --exclude='node_modules/' \
  --exclude='storage/logs/*' \
  --exclude='database/database.sqlite' \
  --exclude='storage/framework/cache/*' \
  --exclude='storage/framework/sessions/*' \
  --exclude='storage/framework/views/*' \
  --exclude='bootstrap/cache/*.php' \
  "$HOME/sinau-laravel-bootstrap/" "$HOME/SINAU/"
```

Opsi --ignore-existing mempertahankan dokumentasi/root files yang sudah ada. Review konflik secara manual. Jangan menimpa README.md proyek dengan README starter kit.

Sebelum commit hasil merge, tambahkan `/database/database.sqlite` ke root `.gitignore` agar file SQLite sementara tidak dapat masuk Git. Pertahankan pengecualian `bootstrap/cache/*.php`, `storage/logs/*`, `vendor/`, dan `node_modules/`; jangan commit cache provider/runtime.

Sebelum commit:
- pastikan .env tidak berada dalam Git index;
- pastikan vendor/ dan node_modules/ diabaikan;
- periksa .env.example agar tidak berisi secret;
- ubah koneksi contoh menjadi PostgreSQL (`DB_CONNECTION=pgsql`, `DB_HOST=127.0.0.1`, `DB_PORT=5432`, `DB_DATABASE=sinau_app_poc`) dan gunakan `SESSION_CONNECTION=pgsql`; nilai username/password tetap placeholder sampai role aplikasi dibuat;
- pastikan session database connection menggunakan koneksi PostgreSQL aplikasi yang sama;
- nonaktifkan Teams dan pastikan action registrasi hanya membuat global user sesuai ADR-008.

## 6. CI bootstrap isolation

Workflow GitHub Actions dari starter kit menjalankan `composer setup`, yang menjalankan migrasi dan npm build. Ini hanya boleh berjalan pada runner GitHub yang disposable dan harus dipaksa memakai SQLite lokal di runner, bukan database PostgreSQL aplikasi/produksi. Atur job environment secara eksplisit:

```yaml
env:
  APP_ENV: testing
  DB_CONNECTION: sqlite
  DB_DATABASE: ${{ github.workspace }}/database/database.sqlite
  SESSION_CONNECTION: sqlite
```

Di langkah sebelum `composer setup`, buat file database sementara:

```yaml
- name: Prepare isolated SQLite database
  run: touch "$DB_DATABASE"
```

Setup PHP harus menyediakan ekstensi `pdo_sqlite` dan `sqlite3`; tetap sediakan `pdo_pgsql` untuk mendeteksi kompatibilitas runtime target PostgreSQL. Gunakan Node 24.22.3 agar CI sejalan dengan runtime host. Variabel environment pada job harus tetap mengalahkan nilai `.env.example` yang nanti diubah menjadi PostgreSQL; khususnya `SESSION_CONNECTION=sqlite` agar session test memakai file SQLite runner, bukan koneksi PostgreSQL contoh. Jangan menambahkan credential database produksi ke Actions.

Vite+ 1.4.0 secara resmi menerima Node `^22.18.0 || ^24.11.0 || >=26.0.0`; Node 22 tidak otomatis tidak kompatibel, tetapi Node 24.22.3 dipilih di workflow agar versi CI sama dengan host. `npm install` dari script `composer setup` mengikuti `.npmrc` yang memiliki `ignore-scripts=true`; jangan melonggarkan kebijakan ini tanpa review. Setelah build dependency pertama dilakukan, commit lockfile npm agar instalasi CI dapat dibuat reproducible.

Jangan menjalankan workflow setup script di host aplikasi bila belum tersedia database PoC aplikasi. Migrasi di CI diizinkan hanya pada file SQLite ephemeral runner.

## 7. Instal dependency dan verifikasi lokal

Jalankan setelah file scaffold digabung dan konfigurasi database PoC aplikasi tersedia. **Jangan menjalankan `composer run setup`** pada tahap bootstrap ini: script tersebut menjalankan `php artisan migrate --force` dan `npm install` sekaligus. Gunakan langkah terpisah dan eksplisit agar migration hanya dapat dijalankan setelah database `sinau_app_poc` dan role aplikasi disiapkan serta diverifikasi.

```bash
cd "$HOME/SINAU" || exit 1

composer install
npm install
npm run build
php artisan route:list
php artisan test
```

Jangan menjalankan php artisan migrate sampai database sinau_app_poc dan role PoC aplikasi dibuat secara eksplisit. Jangan gunakan sinau_design_poc, sinau, atau sinau_app.

## 7. Penyesuaian auth wajib sebelum route onboarding

Ikuti ADR-008:
- global user account dibuat sendiri; jangan buat tenant/unit/role saat action Fortify membuat user;
- aktifkan email verification untuk penyelesaian onboarding;
- public registration membuat global identity saja;
- jangan menambahkan tenant_id/unit_id pada users;
- jangan aktifkan Laravel Teams;
- gunakan database session, cookie HttpOnly + SameSite=Lax, Secure pada HTTPS;
- login rate limit, CSRF, logout/session invalidation, dan flow TOTP 2FA opsional harus diuji;
- jangan aktifkan Passkeys pada bootstrap awal; keputusan passkey dan recovery tetap terbuka di ADR-008 sampai ada desain dan pengujian tersendiri;
- API bearer token/Sanctum tidak diaktifkan pada bootstrap web;
- context RLS token tidak pernah dikirim ke browser.

## 8. Fitur Passkeys ditunda pada bootstrap awal

ADR-008 belum menerima Passkeys sebagai fitur bootstrap. Setelah scaffold dibuat, nonaktifkan seluruh integrasi aplikasi, bukan hanya menghapus deklarasi fitur Fortify:

- Hapus hanya deklarasi `Features::passkeys([...])` dari `config/fortify.php`; pertahankan registration, reset password, email verification, dan TOTP.
- Panggil `Laravel\\Passkeys\\Passkeys::ignoreRoutes()` pada `AppServiceProvider::register()`, supaya provider paket tidak mendaftarkan endpoint Passkeys saat boot.
- Hapus juga blok starter-kit bertanda `@chisel-passkeys` di `routes/settings.php` (route `/.well-known/passkey-endpoints`); ini adalah dokumen discovery W3C yang mengiklankan dukungan Passkeys dan bukan endpoint login paket.
- Hapus interface/trait Passkeys dari model User, rate limiter Passkeys, props/query Passkeys pada SecurityController, dan komponen Passkeys dari halaman Login, Confirm Password, serta Security.
- Hapus migration Passkeys yang dihasilkan starter kit karena fitur belum dipakai, dan regenerasi Wayfinder setelah endpoint dimatikan.
- Hapus dependency frontend `@laravel/passkeys` hanya setelah seluruh import Vue-nya dihilangkan. Jangan hapus dependency PHP `laravel/passkeys`: Laravel Fortify versi yang digunakan mewajibkannya sebagai dependency transitive.
- Bersihkan artefak UI yang tidak lagi direferensikan seperti `PasskeyItem.vue`; hapus hanya tipe `Passkey` dari `resources/js/types/auth.ts` setelah memeriksa apakah file tersebut memuat tipe lain yang masih dipakai.
- Pastikan tidak ada route dengan path/nama Passkeys yang terdaftar, sementara route dan komponen TOTP tetap tersedia.

Jangan menjalankan migration saat membersihkan scaffold. Database aplikasi masih belum dibuat.

## 10. Gerbang selesai bootstrap

Bootstrap dinyatakan lulus hanya bila:
1. scaffold Laravel 13/Vue starter kit berhasil dibuat;
2. Composer install dan npm production build berhasil;
3. route:list menunjukkan route auth yang diharapkan;
4. test suite awal lulus;
5. database aplikasi terpisah dari database RLS PoC dan database SQLRadius;
6. tidak ada secret/runtime artifacts yang masuk Git;
7. auth registration tidak membuat tenant/role otomatis;
8. CI minimal untuk backend/frontend build sudah ditambahkan.

Setelah itu baru lanjut ke migration identity/membership PoC yang disetujui dan integrasi trusted context issuer sesuai ADR-007/008.
