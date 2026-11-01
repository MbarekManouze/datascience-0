# Reset & Start Again

This guide deletes the database and rebuilds it from zero, one exercise at a time.
For the full explanation of each exercise, see [README.md](README.md).

> Run every command from the project folder: `piscine-datascience-00/`

## ⚡ Quick way: one script

```bash
./reset.sh        # asks "Continue? [y/N]" first
./reset.sh -y     # no question
```

It does **all the steps below** automatically (about 1 minute) and prints the row
count of every table at the end. If port 5432 is busy, it stops the local
PostgreSQL for you (it asks for your sudo password).

The rest of this file is the same thing done **by hand**, step by step, so you
understand what the script does.

---

## 1. Delete everything

```bash
(cd ex01 && docker compose down -v)   # remove pgAdmin + its saved settings
(cd ex00 && docker compose down -v)   # remove Postgres + ALL tables (the volume)
```

`down` stops and removes the containers. `-v` also deletes the **volumes**,
which is where the tables are stored. Without `-v` the data would be kept.

Check that nothing is left:

```bash
docker ps -a --filter name=piscineds      # should print nothing
docker volume ls | grep piscineds         # should print nothing
```

**What is NOT deleted:** your files (`ex00`–`ex04`, `customer/`, `item/`, README).
Only the database is wiped.

---

## 2. Free port 5432

The PostgreSQL installed on this computer (`postgresql@18-main`) also uses port
5432, so the Docker container can't start while it is running. Stop it (needed
again after each reboot):

```bash
sudo systemctl stop postgresql@18-main
```

> If you see `address already in use` when starting ex00, you skipped this step.

---

## 3. Rebuild, step by step

Save the password once so `psql` doesn't ask for it every time:

```bash
export PGPASSWORD=mysecretpassword
```

### ex00 – Start the database

```bash
(cd ex00 && docker compose up -d --wait)
psql -U mmanouze -d piscineds -h localhost -W     # test the login, then type \q
```

### ex01 – Start pgAdmin (the viewer)

```bash
(cd ex01 && docker compose up -d)
```

1. Open **http://localhost:8080**
2. **Register → Server**
   - Host: `piscineds_postgres` (the container name, **not** `localhost`)
   - Port: `5432`
   - User: `mmanouze`
   - Password: `mysecretpassword`
3. Go to `Databases → piscineds → Schemas → public → Tables`.
   It is **empty**. That's normal, because no data has been loaded yet.

> ex02, ex03 and ex04 run **from inside their own folder** (`cd ex02 && …`),
> because their CSV paths start with `../` (e.g. `../customer/data_2022_oct.csv`).
> The `( … )` brackets run the command in a sub-shell, so you are back in the
> project folder afterwards.

### ex02 – First table

```bash
(cd ex02 && psql -U mmanouze -d piscineds -h localhost -f table.sql)
```

In pgAdmin, right-click **Tables → Refresh** and `data_2022_oct` appears.

### ex03 – All customer tables

```bash
(cd ex03 && ./automatic_table.sh)
```

Refresh pgAdmin and you'll see the 4 `data_*` tables.

### ex04 – Items table

```bash
(cd ex04 && psql -U mmanouze -d piscineds -h localhost -f items_table.sql)
```

Refresh pgAdmin and `items` appears.

---

## 4. Check the result

```bash
psql -U mmanouze -d piscineds -h localhost -c '\dt'
```

You should get 5 tables with these row counts:

| Table | Rows |
|-------|------|
| `data_2022_oct` | 4,102,283 |
| `data_2022_nov` | 4,635,837 |
| `data_2022_dec` | 3,533,286 |
| `data_2023_jan` | 4,264,752 |
| `items` | 109,579 |

To count one table:

```bash
psql -U mmanouze -d piscineds -h localhost -c 'SELECT COUNT(*) FROM items;'
```

---

## Why this order matters

```
ex00  Postgres container   → the storage (empty at first)
ex01  pgAdmin              → only a viewer, it adds no data
ex02  \copy oct CSV        ┐
ex03  \copy all customer   ├→ these put the CSV rows into Postgres
ex04  \copy item CSV       ┘
```

pgAdmin shows whatever ex02–ex04 have loaded so far. Refreshing it after each
step lets you watch the tables appear one by one.
