# Piscine Data Science – Module 00: Creation of a DB

This folder contains the solution of every exercise **and** a beginner-friendly
explanation of everything used. If you have never used a database before, read
this file from top to bottom.

```
piscine-datascience-00/
├── README.md              <- you are here (the documentation)
├── .gitignore             <- keeps the huge CSV files out of git
├── ex00/
│   ├── docker-compose.yml <- starts the PostgreSQL database
│   └── .env               <- login / password / database name
├── ex01/
│   └── docker-compose.yml <- (optional) pgAdmin, a website to look at the DB
├── ex02/
│   └── table.sql          <- creates the table data_2022_oct
├── ex03/
│   └── automatic_table.sh <- creates one table per CSV file, automatically
└── ex04/
    └── items_table.sql    <- creates the table items
```

---

## Table of contents

0. [The big picture – what are we doing?](#0-the-big-picture)
1. [Basic vocabulary](#1-basic-vocabulary)
2. [Getting the data](#2-getting-the-data)
3. [Exercise 00 – Create the Postgres database](#ex00)
4. [Exercise 01 – Show me your DB](#ex01)
5. [Exercise 02 – First table](#ex02)
6. [Exercise 03 – Automatic table](#ex03)
7. [Exercise 04 – Items table](#ex04)
8. [Everything in one go (quick run)](#quick-run)
9. [Troubleshooting](#troubleshooting)
10. [Questions you may get during the evaluation](#evaluation)

---

<a name="0-the-big-picture"></a>
## 0. The big picture

You work for an online shop. Your boss gives you **files** (CSV) containing every
action customers did on the website for 4 months (view a product, add it to the
cart, buy it…).

Files are not practical to analyse: they are big, slow to search, and nothing
checks that the data is correct. So the job of a **data engineer** (you) is to
put this data into a **database**, where it is organised, typed and fast to query.

The plan of this module:

| Step | Exercise | What you do |
|------|----------|-------------|
| 1 | ex00 | Start a database server (PostgreSQL) |
| 2 | ex01 | Install a tool to *see* the database |
| 3 | ex02 | Import **one** CSV file into a table, by hand |
| 4 | ex03 | Import **all** customer CSV files automatically |
| 5 | ex04 | Import the product list (items) |

---

<a name="1-basic-vocabulary"></a>
## 1. Basic vocabulary

| Word | Simple meaning |
|------|----------------|
| **Database (DB)** | A program that stores data in an organised way and lets you search it very fast. |
| **PostgreSQL** (or "Postgres") | A free, very popular database program. |
| **Server** | The Postgres program running in the background, waiting for requests. |
| **Client** | A program that talks to the server. `psql` (terminal) and pgAdmin (website) are clients. |
| **Table** | Like a spreadsheet sheet: rows and columns. |
| **Row** | One line of the table = one event (e.g. "user 42 bought product 7 at 10:03"). |
| **Column** | One kind of information (e.g. `price`). Every value in a column has the **same type**. |
| **Data type** | What kind of value a column holds: number, text, date… |
| **SQL** | The language used to talk to a database (`CREATE TABLE`, `SELECT`, …). |
| **CSV** | "Comma-Separated Values": a text file where each line is a row and values are separated by commas. |
| **Docker** | A tool that runs programs inside isolated "boxes" called **containers**, so you don't install them on your computer directly. |
| **Docker Compose** | A file (`docker-compose.yml`) that describes which containers to start and how. |
| **Volume** | A folder managed by Docker where a container saves its files, so they are not lost when the container stops. |

A CSV file looks like this:

```csv
event_time,event_type,product_id,price,user_id,user_session
2022-10-01 00:00:00 UTC,cart,5773203,2.62,463240011,26dd6e6e-4dac-4778-8d2c-92e149dab885
2022-10-01 00:00:03 UTC,view,5881589,2.38,566092002,
```

- The **first line** is the **header**: the names of the columns.
- Every other line is one row of data.
- An empty value (like the last one in the 3rd line) means "unknown". In a database
  an unknown value is called **NULL**.

---

<a name="2-getting-the-data"></a>
## 2. Getting the data

The CSV files are **not** in this repository (they are hundreds of MB and are
ignored by `.gitignore`). Download the module's dataset (`subject.zip`) from the
project page on the intra and unzip it and move its `customer/` and `item/` folders **into this folder**:

```bash
unzip data-subject.zip            # creates subject/customer and subject/item
mv subject/customer subject/item . && rmdir subject
```

You get:

```
piscine-datascience-00/
├── customer/
│   ├── data_2022_oct.csv
│   ├── data_2022_nov.csv
│   ├── data_2022_dec.csv
│   └── data_2023_jan.csv
├── item/
│   └── item.csv
├── ex00/ ex01/ ...
```

> **Important:** every command in this README must be run **from this folder**
> (`piscine-datascience-00/`), because the scripts look for `customer/` and
> `item/` relative to where you are.
>
> **Note on the folder name:** the subject's example shows a folder called
> `items/`, but the real `subject.zip` contains **`item/item.csv`** (singular).
> The scripts use the real name: `item/item.csv`.

---

<a name="ex00"></a>
## 3. Exercise 00 – Create the Postgres database

### What the subject asks

- A PostgreSQL database named **`piscineds`**
- The user must be **your login** (here `mmanouze`)
- The password must be **`mysecretpassword`**
- This command must work:
  `psql -U mmanouze -d piscineds -h localhost -W`

### The solution: `ex00/docker-compose.yml` + `ex00/.env`

Instead of installing Postgres on the computer, we run it in a Docker container.
The official `postgres` image does all the work: when the container starts the
first time, it reads 3 environment variables and creates the user and database
for us.

**`ex00/.env`** – the settings:

```env
POSTGRES_USER=mmanouze          # the user to create
POSTGRES_PASSWORD=mysecretpassword
POSTGRES_DB=piscineds           # the database to create
POSTGRES_PORT=5432              # the port on your computer
```

**`ex00/docker-compose.yml`** – line by line:

```yaml
services:
  postgres:                              # name of our service
    image: postgres:16.4-alpine          # which program: Postgres version 16.4 (small "alpine" version)
    container_name: piscineds_postgres   # a fixed, readable name for the container
    env_file: .env                       # give the variables of .env to the container
    ports:
      - "127.0.0.1:${POSTGRES_PORT:-5432}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - piscineds_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      ...
```

| Line | Why |
|------|-----|
| `image: postgres:16.4-alpine` | We **pin** a version. Never use `latest`: it could change one day and break your project (an Inception rule). |
| `env_file: .env` | The password is not written in the compose file. Secrets live in `.env` (good practice from Inception). |
| `ports: "127.0.0.1:5432:5432"` | Format is `computer_port:container_port`. Postgres listens on 5432 inside the container; we make it reachable on port 5432 of *your* computer, and only from your computer (`127.0.0.1`), not from the network. `${POSTGRES_PORT:-5432}` means "use the value of POSTGRES_PORT, or 5432 if it is not set". |
| `volumes:` | Postgres saves its data in `/var/lib/postgresql/data`. We map that to a Docker **volume** so your tables survive `docker compose down` / reboots. |
| `networks:` | A private network. ex01's pgAdmin joins it to reach the database by its name. |
| `restart: unless-stopped` | If the container crashes, Docker restarts it. |
| `healthcheck:` | Every 5 s Docker runs `pg_isready` to know if Postgres is ready to accept connections. (`$$` = a literal `$` in compose files, so the variable is read *inside* the container.) |

### How to run it

```bash
cd ex00
docker compose up -d          # -d = run in the background ("detached")
docker compose ps             # STATUS should become "healthy"
cd ..
```

Connect exactly like the subject says:

```bash
psql -U mmanouze -d piscineds -h localhost -W
Password: mysecretpassword
piscineds=#
```

`psql` options: `-U` user, `-d` database, `-h` host (the computer, here yours),
`-W` ask for the password. Type `\q` to quit.

> **No `psql` on your computer?** Use the one inside the container:
> `docker exec -it piscineds_postgres psql -U mmanouze -d piscineds`

Useful commands:

```bash
docker compose logs -f        # see what Postgres prints
docker compose down           # stop (data is KEPT)
docker compose down -v        # stop and DELETE all data (-v removes volumes)
```

> ⚠️ The user/password/DB are only created the **first** time (when the volume is
> empty). If you change `.env` later, run `docker compose down -v` then `up -d`.

---

<a name="ex01"></a>
## 4. Exercise 01 – Show me your DB

### What the subject asks

Use a graphical tool to *see* the database and browse/edit the data easily
(especially by record ID). Nothing to turn in — you just show it during the evaluation.

### The solution: pgAdmin (optional `ex01/docker-compose.yml`)

**pgAdmin** is the official web interface for PostgreSQL. We run it in Docker too:

```bash
cd ex01
docker compose up -d          # ex00 must already be running
cd ..
```

1. Open **http://localhost:8080** in your browser.
   (Login if asked: `admin@admin.com` / `admin`.)
2. Right-click **Servers → Register → Server…**
3. Tab **General** → Name: `piscineds` (any name).
4. Tab **Connection**:
   - Host: **`piscineds_postgres`** ← the container name. Both containers are on the
     same Docker network, so pgAdmin finds Postgres by its name (not `localhost`!
     inside the pgAdmin container, `localhost` is pgAdmin itself).
   - Port: `5432`
   - Username: `mmanouze`
   - Password: `mysecretpassword`
5. **Save**. Then open: `piscineds → Databases → piscineds → Schemas → public → Tables`.
6. Right-click a table → **View/Edit Data → All Rows** to see, sort, filter and
   edit rows. You can also use **Tools → Query Tool** to write SQL, e.g.
   `SELECT * FROM items WHERE product_id = 3762;`

**Alternatives** (also accepted): **DBeaver** (desktop app, `sudo snap install dbeaver-ce`),
Postico (macOS only). With a desktop app, the host is `localhost` and port `5432`
(because the app runs on your computer, not in Docker).

> The pgAdmin login is a local-only default (`127.0.0.1`), fine for a school
> exercise. Never use such passwords on a real server.

---

<a name="ex02"></a>
## 5. Exercise 02 – First table

### What the subject asks

- Create a table from `customer/data_2022_oct.csv`, named `data_2022_oct`.
- Column names = exactly the CSV header.
- Appropriate data types, **at least 6 different** ones.
- The **first column must be a date/time** column.

### Step 1 – Look at the data

```bash
head -3 customer/data_2022_oct.csv
```
```
event_time,event_type,product_id,price,user_id,user_session
2022-10-01 00:00:00 UTC,cart,5773203,2.62,463240011,26dd6e6e-4dac-4778-8d2c-92e149dab885
```

### Step 2 – Choose a type for each column

| Column | Example | Type chosen | Why |
|--------|---------|-------------|-----|
| `event_time` | `2022-10-01 00:00:00 UTC` | **`TIMESTAMPTZ`** | A date + time *with time zone* (the file says `UTC`). Postgres has no `DATETIME` type (that's MariaDB/MySQL) — `TIMESTAMP`/`TIMESTAMPTZ` is the equivalent. Being a real date lets you do things like "all events in November". |
| `event_type` | `cart` | **`VARCHAR(50)`** | Short text (max 50 characters). Values: `view`, `cart`, `remove_from_cart`, `purchase`. |
| `product_id` | `5773203` | **`INTEGER`** | Whole number, up to ~2.1 billion. 4 bytes. |
| `price` | `2.62` | **`NUMERIC(10,2)`** | **Exact** decimal number: 10 digits total, 2 after the dot. It also accepts negative values (the October file has 20 negative prices). For money never use `FLOAT` (it is approximate: `0.1 + 0.2 = 0.30000000000000004`). |
| `user_id` | `463240011` | **`BIGINT`** | Whole number up to ~9 quintillion. 8 bytes. User ids can grow beyond `INTEGER`'s limit, so we play safe. |
| `user_session` | `26dd6e6e-4dac-…` | **`UUID`** | A special type for "Universally Unique IDentifiers". Stored in 16 bytes instead of 36 characters of text, and Postgres checks the format is valid. |

That is **6 different types**: `TIMESTAMPTZ`, `VARCHAR`, `INTEGER`, `NUMERIC`,
`BIGINT`, `UUID`. ✅

### Step 3 – The script `ex02/table.sql`

```sql
DROP TABLE IF EXISTS data_2022_oct;
```
Deletes the table if it already exists, so you can run the script again and again
without the error "table already exists".

```sql
CREATE TABLE data_2022_oct (
    event_time   TIMESTAMPTZ  NOT NULL,
    event_type   VARCHAR(50)  NOT NULL,
    product_id   INTEGER      NOT NULL,
    price        NUMERIC(10,2),
    user_id      BIGINT       NOT NULL,
    user_session UUID
);
```
Creates the empty table. `NOT NULL` = this column must always have a value
(the import fails if a row is missing it — that's a free data check!).
`price` and `user_session` accept NULL because they can be empty in the file (the October file has 637 rows without a session).

```sql
\copy data_2022_oct FROM 'customer/data_2022_oct.csv' WITH (FORMAT csv, HEADER true)
```
Loads the whole file into the table in one shot (millions of rows in seconds —
much faster than millions of `INSERT`s).
- `FORMAT csv` → the file is comma-separated.
- `HEADER true` → skip the first line (it's the column names, not data).
- Empty values automatically become `NULL`.

> **`\copy` vs `COPY`** — `COPY` (no backslash) is SQL run *by the server*: it
> looks for the file **inside the container**, where it doesn't exist. `\copy`
> (with backslash) is a `psql` command: `psql` reads the file **on your computer**
> and streams it to the server. That's why we use `\copy`, and why the file must
> be run with `psql`.

```sql
SELECT COUNT(*) AS rows_imported FROM data_2022_oct;
```
Shows how many rows were imported, to check it worked.

### How to run it

```bash
psql -U mmanouze -d piscineds -h localhost -f ex02/table.sql
```
(`-f` = execute this file.) Check the result in psql:

```sql
\d data_2022_oct                 -- describe the table (columns + types)
SELECT * FROM data_2022_oct LIMIT 5;
```

---

<a name="ex03"></a>
## 6. Exercise 03 – Automatic table

### What the subject asks

Find **all** CSV files in `customer/` and create one table per file, named after
the file (without `.csv`). Doing it by hand for 4 files is OK; for 400 it isn't —
so we write a script.

### The solution: `ex03/automatic_table.sh` (a Bash script)

It only needs `bash` and `psql` (already required by ex00), nothing to install.
Here is what it does, block by block:

```bash
set -euo pipefail
```
Safety switches: stop the script at the first error (`-e`), error on unknown
variables (`-u`), and detect errors inside pipes (`pipefail`).

```bash
DB_USER="${DB_USER:-mmanouze}"
DB_PORT="${DB_PORT:-5432}"
export PGPASSWORD="${PGPASSWORD:-mysecretpassword}"
CUSTOMER_DIR="${1:-customer}"
```
Settings with default values. `${X:-default}` = "use X if set, else default".
`PGPASSWORD` is a variable that `psql` reads automatically, so it doesn't ask for
the password for each file. `$1` is the first argument of the script (optional
folder path).

```bash
run_psql() {
    psql -U "$DB_USER" -d "$DB_NAME" -h "$DB_HOST" -p "$DB_PORT" -v ON_ERROR_STOP=1 -q "$@"
}
```
A small **function** so we don't repeat the connection options.
`ON_ERROR_STOP=1` makes `psql` stop and return an error if any SQL fails
(by default `psql` just continues!). `-q` = quiet.

```bash
shopt -s nullglob
csv_files=("$CUSTOMER_DIR"/*.csv)
```
Builds a list of every `.csv` file in the folder. `nullglob` makes the list empty
when there is no match (instead of containing the literal text `*.csv`).

```bash
for csv in "${csv_files[@]}"; do
    table="$(basename "$csv" .csv)"
```
Loop over the files. `basename customer/data_2022_oct.csv .csv` → `data_2022_oct`.

```bash
    if [[ ! "$table" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then ... continue; fi
```
Safety check: the name goes directly into SQL, so we accept only letters, digits
and `_` (a file called `my file;DROP….csv` is skipped instead of breaking the DB).

```bash
    run_psql <<SQL
DROP TABLE IF EXISTS $table;
CREATE TABLE $table ( ...same columns as ex02... );
\copy $table FROM '$csv' WITH (FORMAT csv, HEADER true)
SQL
```
A **heredoc** (`<<SQL … SQL`): everything between the two markers is sent to
`psql` as input, with `$table` and `$csv` replaced by their values. It's exactly
the ex02 script, but with the name filled in automatically. All the customer files
have the same columns, so they share the same structure.

```bash
    count="$(run_psql -t -A -c "SELECT COUNT(*) FROM $table;")"
```
Counts the imported rows. `-t` = no header, `-A` = no alignment → we get just the number.

### How to run it

```bash
./ex03/automatic_table.sh
```
Expected output:
```
-> customer/data_2022_dec.csv  =>  table data_2022_dec
   3533286 rows imported
-> customer/data_2022_nov.csv  =>  table data_2022_nov
   4635837 rows imported
-> customer/data_2022_oct.csv  =>  table data_2022_oct
   4102283 rows imported
-> customer/data_2023_jan.csv  =>  table data_2023_jan
   4264752 rows imported
Done: 4 table(s) created.
```
Other port or folder? `DB_PORT=5433 ./ex03/automatic_table.sh path/to/customer`

> Add a fake `customer/data_2023_feb.csv` (copy of another file) and run it again:
> a new table appears automatically — a good demo for the evaluation.

---

<a name="ex04"></a>
## 7. Exercise 04 – Items table

### What the subject asks

Create a table named **`items`** with the columns of `item/item.csv`, using at least
**3 different data types**.

### Step 1 – Look at the data

```bash
head -4 item/item.csv
```
```
product_id,category_id,category_code,brand
5712790,1487580005268456192,,f.o.x
5764655,1487580005411062528,,cnd
4958,1487580009471148032,,runail
```
Observations:
- Lots of **empty values** → those columns must accept `NULL`.
- `category_id` is **huge** (19 digits) → too big for `INTEGER`.
- The **same `product_id` appears several times** → we can't make it a
  `PRIMARY KEY` (a primary key must be unique, the import would fail).
  In the real file: **109,579 rows but only 54,043 different products**.
  Cleaning these duplicates is the job of the next module.

### Step 2 – Types

| Column | Type | Why |
|--------|------|-----|
| `product_id` | **`INTEGER`** | Same type as `product_id` in the customer tables, so we can later join the two tables. |
| `category_id` | **`BIGINT`** | 19-digit numbers need 8 bytes. |
| `category_code` | **`TEXT`** | Text of any length (`appliances.environment.vacuum`). |
| `brand` | **`VARCHAR(255)`** | A brand name, max 255 characters. |

4 different types (`INTEGER`, `BIGINT`, `TEXT`, `VARCHAR`) ≥ 3. ✅

> `TEXT` vs `VARCHAR(n)`: in Postgres they're stored the same way and are equally
> fast. `VARCHAR(n)` just adds a maximum length check.

### Step 3 – Run it

```bash
psql -U mmanouze -d piscineds -h localhost -f ex04/items_table.sql
```
The script follows the same pattern as ex02: `DROP TABLE IF EXISTS` →
`CREATE TABLE` → `\copy` → `SELECT COUNT(*)`.

---

<a name="quick-run"></a>
## 8. Everything in one go (quick run)

```bash
# from piscine-datascience-00/, with customer/ and item/ unzipped here
export PGPASSWORD=mysecretpassword          # so psql doesn't ask each time

(cd ex00 && docker compose up -d --wait)    # ex00: start the DB
(cd ex01 && docker compose up -d)           # ex01: pgAdmin on http://localhost:8080

psql -U mmanouze -d piscineds -h localhost -f ex02/table.sql        # ex02
./ex03/automatic_table.sh                                            # ex03
psql -U mmanouze -d piscineds -h localhost -f ex04/items_table.sql   # ex04

psql -U mmanouze -d piscineds -h localhost -c '\dt'   # list all tables
```

Expected result (tested with the real `subject.zip`, about 1 minute in total):

| Table | Rows |
|-------|------|
| `data_2022_oct` | 4,102,283 |
| `data_2022_nov` | 4,635,837 |
| `data_2022_dec` | 3,533,286 |
| `data_2023_jan` | 4,264,752 |
| `items` | 109,579 |

(Each number is the line count of the CSV minus 1 for the header, so no row was lost.)

Handy `psql` commands:

| Command | Meaning |
|---------|---------|
| `\l` | list databases |
| `\dt` | list tables |
| `\d table_name` | describe a table (columns + types) |
| `\x` | toggle vertical display (nice for wide rows) |
| `\q` | quit |

---

<a name="troubleshooting"></a>
## 9. Troubleshooting

| Problem | Cause & fix |
|---------|-------------|
| `Bind for 127.0.0.1:5432 failed: port is already allocated` / `address already in use` | Another Postgres already uses port 5432 on your computer (**this is the case on this machine**: a local Postgres listens on 5432). Either stop it (`sudo systemctl stop postgresql`) or set `POSTGRES_PORT=5433` in `ex00/.env` and add `-p 5433` to your `psql` commands (and `DB_PORT=5433` for ex03). |
| `password authentication failed for user "mmanouze"` | You probably connected to the *other* Postgres (see above), or you changed `.env` after the first start → `docker compose down -v` then `up -d`. |
| `could not open file "customer/data_2022_oct.csv"` | You're not in the right folder. `cd` into `piscine-datascience-00/` (where `customer/` is). |
| `permission denied while trying to connect to the Docker daemon` | Your user isn't in the `docker` group: `sudo usermod -aG docker $USER`, then log out/in. |
| `psql: command not found` | `sudo apt install postgresql-client`, or use `docker exec -it piscineds_postgres psql -U mmanouze -d piscineds`. |
| `invalid input syntax for type …` during `\copy` | A value doesn't match its column type. Read the line number in the error, look at that line in the CSV (`sed -n 'NUMBERp' file.csv`) and adapt the type. |
| `network piscineds_network declared as external, but could not be found` | Start ex00 before ex01. |

---