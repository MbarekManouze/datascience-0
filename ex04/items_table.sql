-- Exercise 04 - Create the table "items" from item/item.csv
--
-- Run it from the folder that CONTAINS the "item" directory:
--   psql -U mmanouze -d piscineds -h localhost -f ex04/items_table.sql

DROP TABLE IF EXISTS items;

-- Column names are exactly the CSV header:
--   product_id,category_id,category_code,brand
-- 4 different data types: INTEGER, BIGINT, TEXT, VARCHAR
-- No PRIMARY KEY on product_id: the file contains the same product several times.
CREATE TABLE items (
    product_id    INTEGER      NOT NULL,  -- same type as product_id in the customer tables
    category_id   BIGINT,                 -- very large number (e.g. 2053013555631882655)
    category_code TEXT,                   -- text of any length (e.g. "appliances.environment.vacuum")
    brand         VARCHAR(255)            -- brand name, often empty -> NULL
);

-- Empty fields in the CSV become NULL automatically.
\copy items FROM '../item/item.csv' WITH (FORMAT csv, HEADER true)

SELECT COUNT(*) AS rows_imported FROM items;
