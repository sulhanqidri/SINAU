#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
COMPOSE_FILE="$ROOT/poc/database-isolation/postgresql/compose.yaml"
SQL_DIR="$ROOT/poc/database-isolation/postgresql"

command -v docker >/dev/null 2>&1 || {
  echo "ERROR: Docker CLI tidak ditemukan. Instal Docker Desktop/Engine dan Docker Compose v2." >&2
  exit 1
}
docker compose version >/dev/null

cd "$ROOT"
docker compose -f "$COMPOSE_FILE" up -d --wait

export PGPASSWORD="${PGPASSWORD:-sinau_poc_local_only}"
PGHOST="${PGHOST:-127.0.0.1}"
PGPORT="${PGPORT:-55432}"
PGUSER="${PGUSER:-sinau_poc}"
PGDATABASE="${PGDATABASE:-sinau_poc}"
export PGHOST PGPORT PGUSER PGDATABASE

echo "== PostgreSQL version =="
psql -X -v ON_ERROR_STOP=1 -c "SELECT version();"

echo "== Create schema and synthetic fixtures =="
psql -X -v ON_ERROR_STOP=1 -f "$SQL_DIR/schema-and-fixtures.sql"

echo "== Automated integrity checks =="
psql -X -v ON_ERROR_STOP=1 -f "$SQL_DIR/verify-constraints.sql"

if [[ "${RUN_BENCHMARK:-0}" == "1" ]]; then
  echo "== Optional 1,000,000-row benchmark =="
  psql -X -v ON_ERROR_STOP=1 -f "$SQL_DIR/benchmark-million.sql"
else
  echo "Benchmark dilewati. Jalankan ulang dengan RUN_BENCHMARK=1 untuk menambah 1 juta baris sintetis."
fi

echo "PoC dasar selesai. Database hanya untuk eksperimen; jangan gunakan sebagai database aplikasi."
