#!/usr/bin/env bash
# Read-only preflight for the SINAU Laravel 13/Vue starter bootstrap.
# This script does not install packages, alter services, create databases,
# write .env files, or touch SQLRadius.

set -u

printf '%s\n' "===== SINAU APP BOOTSTRAP HOST PREFLIGHT (READ ONLY) ====="

check_command() {
    local name="$1"
    if command -v "$name" >/dev/null 2>&1; then
        printf '%-12s %s\n' "$name" "$(command -v "$name")"
    else
        printf '%-12s %s\n' "$name" "NOT FOUND"
    fi
}

printf '\n%s\n' "===== 1. REQUIRED COMMANDS ====="
for command_name in php composer node npm git curl rsync; do
    check_command "$command_name"
done

printf '\n%s\n' "===== 2. PHP RUNTIME ====="
if command -v php >/dev/null 2>&1; then
    php -v | head -n 2
    php -r '
        $required = [
            "bcmath", "ctype", "curl", "dom", "fileinfo", "filter",
            "hash", "mbstring", "openssl", "pcre", "pdo", "pdo_pgsql",
            "session", "tokenizer", "xml"
        ];
        $missing = array_values(array_filter(
            $required,
            static fn ($extension) => ! extension_loaded($extension)
        ));
        echo "PHP_VERSION=" . PHP_VERSION . PHP_EOL;
        echo "PDO_PGSQL=" . (extension_loaded("pdo_pgsql") ? "OK" : "MISSING") . PHP_EOL;
        echo "REQUIRED_EXTENSIONS=" . (empty($missing) ? "OK" : "MISSING: " . implode(", ", $missing)) . PHP_EOL;
        echo "PHP_8_4_BASELINE=" . (PHP_VERSION_ID >= 80400 && PHP_VERSION_ID < 80500 ? "OK" : "CHECK REQUIRED (target 8.4.x)") . PHP_EOL;
    '
else
    echo "PHP belum tersedia."
fi

printf '\n%s\n' "===== 3. COMPOSER ====="
if command -v composer >/dev/null 2>&1; then
    composer --version
else
    echo "Composer belum tersedia."
fi

printf '\n%s\n' "===== 4. NODE / NPM ====="
if command -v node >/dev/null 2>&1; then
    node --version
else
    echo "Node belum tersedia."
fi
if command -v npm >/dev/null 2>&1; then
    npm --version
else
    echo "npm belum tersedia."
fi

printf '\n%s\n' "===== 5. GIT ====="
if command -v git >/dev/null 2>&1; then
    git --version
else
    echo "Git belum tersedia."
fi

printf '\n%s\n' "===== 6. POSTGRESQL CLIENT ====="
if command -v psql >/dev/null 2>&1; then
    psql --version
else
    echo "psql client tidak ditemukan."
fi

printf '\n%s\n' "===== 7. STORAGE AND MEMORY ====="
df -h "$HOME" /tmp 2>/dev/null || true
if command -v free >/dev/null 2>&1; then
    free -h
fi

printf '\n%s\n' "===== 8. SAFETY PATH CHECK ====="
printf 'HOME=%s\n' "$HOME"
if [ -d /var/www/sqlradius ]; then
    echo "SQLRADIUS_PATH_PRESENT=yes (must not be modified)"
else
    echo "SQLRADIUS_PATH_PRESENT=no"
fi
if [ -e "$HOME/SINAU" ]; then
    echo "SINAU_CHECKOUT_PRESENT=yes (inspect before cloning; do not overwrite)"
else
    echo "SINAU_CHECKOUT_PRESENT=no"
fi
if [ -e "$HOME/sinau-laravel-bootstrap" ]; then
    echo "BOOTSTRAP_TARGET_PRESENT=yes (inspect before generating; do not overwrite)"
else
    echo "BOOTSTRAP_TARGET_PRESENT=no"
fi

printf '\n%s\n' "PREFLIGHT COMPLETE — NO PACKAGES OR SERVICES WERE CHANGED."
