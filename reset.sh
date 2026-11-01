#!/usr/bin/env bash
# reset.sh - Delete the database and rebuild everything (ex00 -> ex04).
#
# Usage (from piscine-datascience-00/):
#   ./reset.sh        # asks for confirmation first
#   ./reset.sh -y     # no question
#
# Same steps as RESET.md, done automatically.
# Each exercise runs from inside its own folder (paths in the scripts use ../).

set -euo pipefail

cd "$(dirname "$0")"                    # always run from the project folder

PORT="${POSTGRES_PORT:-5432}"
export PGPASSWORD=mysecretpassword
PSQL=(psql -U mmanouze -d piscineds -h localhost -p "$PORT" -v ON_ERROR_STOP=1 -q)

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
ok()   { printf '\033[1;32m    ok:\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31m    error:\033[0m %s\n' "$*" >&2; exit 1; }

# ---------- 0. Safety checks ----------
[ -d customer ] || fail "folder 'customer/' not found (unzip data-subject.zip first)"
[ -f item/item.csv ] || fail "file 'item/item.csv' not found (unzip data-subject.zip first)"

if [ "${1:-}" != "-y" ]; then
    read -r -p "This DELETES all tables and rebuilds them. Continue? [y/N] " answer
    [[ "$answer" =~ ^[yY]$ ]] || { echo "Cancelled."; exit 0; }
fi

# ---------- 1. Delete everything ----------
step "1. Deleting containers and volumes"
(cd ex01 && docker compose down -v 2>/dev/null) || true
(cd ex00 && docker compose down -v 2>/dev/null) || true
ok "database wiped"

# ---------- 2. Free the port ----------
step "2. Checking that port $PORT is free"
if ss -ltn "sport = :$PORT" | grep -q LISTEN; then
    echo "    port $PORT is used by another program, trying to stop the local PostgreSQL (needs sudo)"
    sudo systemctl stop 'postgresql@*' || true
    sleep 1
    ss -ltn "sport = :$PORT" | grep -q LISTEN \
        && fail "port $PORT is still busy. Find the program with: sudo ss -ltnp 'sport = :$PORT'"
fi
ok "port $PORT is free"

# ---------- 3. ex00: start the database ----------
step "3. ex00 - starting PostgreSQL"
(cd ex00 && POSTGRES_PORT="$PORT" docker compose up -d --wait)
"${PSQL[@]}" -c "SELECT 1;" >/dev/null && ok "connected to piscineds as mmanouze"

# ---------- 4. ex01: start pgAdmin ----------
step "4. ex01 - starting pgAdmin"
(cd ex01 && docker compose up -d)
ok "pgAdmin on http://localhost:8080 (Host: piscineds_postgres, Port: 5432)"

# ---------- 5. ex02 ----------
step "5. ex02 - table data_2022_oct"
(cd ex02 && "${PSQL[@]}" -f table.sql) 2>&1 | grep -v NOTICE || true

# ---------- 6. ex03 ----------
step "6. ex03 - all customer tables"
(cd ex03 && DB_PORT="$PORT" ./automatic_table.sh) 2>&1 | grep -v NOTICE

# ---------- 7. ex04 ----------
step "7. ex04 - table items"
(cd ex04 && "${PSQL[@]}" -f items_table.sql) 2>&1 | grep -v NOTICE || true

# ---------- 8. Final check ----------
step "8. Result"
"${PSQL[@]}" <<'SQL'
SELECT 'data_2022_oct' AS table_name, COUNT(*) AS rows FROM data_2022_oct
UNION ALL SELECT 'data_2022_nov', COUNT(*) FROM data_2022_nov
UNION ALL SELECT 'data_2022_dec', COUNT(*) FROM data_2022_dec
UNION ALL SELECT 'data_2023_jan', COUNT(*) FROM data_2023_jan
UNION ALL SELECT 'items',         COUNT(*) FROM items;
SQL

printf '\n\033[1;32mAll done.\033[0m Connect with: psql -U mmanouze -d piscineds -h localhost -W\n'
