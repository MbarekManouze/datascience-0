#!/usr/bin/env bash
# Exercise 03 - Create one table per CSV file found in the "customer" folder.
#
# Usage (from the folder that contains "customer"):
#   PGPASSWORD=mysecretpassword ./ex03/automatic_table.sh [customer_folder]

set -euo pipefail   # stop at the first error

# ---- Settings (can be overridden with environment variables) ----
DB_USER="${DB_USER:-mmanouze}"
DB_NAME="${DB_NAME:-piscineds}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
export PGPASSWORD="${PGPASSWORD:-mysecretpassword}"
CUSTOMER_DIR="${1:-../customer}"

# Small helper: run psql with our connection settings.
# ON_ERROR_STOP=1 makes psql fail (exit code != 0) if a SQL command fails.
run_psql() {
    psql -U "$DB_USER" -d "$DB_NAME" -h "$DB_HOST" -p "$DB_PORT" \
         -v ON_ERROR_STOP=1 -q "$@"
}

if [ ! -d "$CUSTOMER_DIR" ]; then
    echo "Error: folder '$CUSTOMER_DIR' not found." >&2
    exit 1
fi

shopt -s nullglob                 # if no file matches, the list is empty
csv_files=("$CUSTOMER_DIR"/*.csv)

if [ ${#csv_files[@]} -eq 0 ]; then
    echo "Error: no .csv file in '$CUSTOMER_DIR'." >&2
    exit 1
fi

for csv in "${csv_files[@]}"; do
    # "customer/data_2022_oct.csv" -> "data_2022_oct"
    table="$(basename "$csv" .csv)"

    # A table name must be a safe identifier (letters, digits, _).
    if [[ ! "$table" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "Skipping '$csv': invalid table name '$table'." >&2
        continue
    fi

    echo "-> $csv  =>  table $table"

    run_psql <<SQL
DROP TABLE IF EXISTS $table;
CREATE TABLE $table (
    event_time   TIMESTAMPTZ  NOT NULL,
    event_type   VARCHAR(50)  NOT NULL,
    product_id   INTEGER      NOT NULL,
    price        NUMERIC(10,2),
    user_id      BIGINT       NOT NULL,
    user_session UUID
);
\copy $table FROM '$csv' WITH (FORMAT csv, HEADER true)
SQL

    count="$(run_psql -t -A -c "SELECT COUNT(*) FROM $table;")"
    echo "   $count rows imported"
done

echo "Done: ${#csv_files[@]} table(s) created."
