-- Exercise 02 - Create the table data_2022_oct from customer/data_2022_oct.csv
--
-- Run it from the folder that CONTAINS the "customer" directory:
--   psql -U mmanouze -d piscineds -h localhost -f ex02/table.sql

-- Start clean so the script can be run many times.
DROP TABLE IF EXISTS data_2022_oct;

-- Column names are exactly the CSV header:
--   event_time,event_type,product_id,price,user_id,user_session
-- 6 different data types are used:
--   TIMESTAMPTZ, VARCHAR, INTEGER, NUMERIC, BIGINT, UUID
CREATE TABLE data_2022_oct (
    event_time   TIMESTAMPTZ  NOT NULL,  -- 1st column: date + time ("2022-10-01 00:00:00 UTC")
    event_type   VARCHAR(50)  NOT NULL,  -- short text: view / cart / remove_from_cart / purchase
    product_id   INTEGER      NOT NULL,  -- whole number (fits in 4 bytes)
    price        NUMERIC(10,2),          -- exact decimal number for money (2 digits after the dot)
    user_id      BIGINT       NOT NULL,  -- big whole number
    user_session UUID                    -- unique id like 26dd6e6e-4dac-4778-8d2c-92e149dab885
);

-- \copy reads the file from YOUR computer and sends it to the server.
-- CSV HEADER = the file is comma separated and the first line is the header.
\copy data_2022_oct FROM '../customer/data_2022_oct.csv' WITH (FORMAT csv, HEADER true)

-- Quick check
SELECT COUNT(*) AS rows_imported FROM data_2022_oct;
