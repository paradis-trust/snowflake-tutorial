CREATE TABLE customers (
  customer_id NUMBER,
  customer_name VARCHAR
);

CREATE TABLE products (
  product_id NUMBER,
  product_name VARCHAR,
  price NUMBER(10,2)
);

CREATE TABLE orders (
  order_id NUMBER,
  customer_id NUMBER,
  product_id NUMBER,
  quantity NUMBER
);

PUT file://<absolute_folder_path>/customers_raw.csv @TUTO_DB.PUBLIC.%customers;
PUT file://<absolute_folder_path>/products_raw.csv @TUTO_DB.PUBLIC.%products;
PUT file://<absolute_folder_path>/orders_raw.csv @TUTO_DB.PUBLIC.%orders;

CREATE FILE FORMAT tuto_csv_format
  TYPE = CSV
  SKIP_HEADER = 1 -- because we have 1 line of headers
  RECORD_DELIMITER = '\n' -- (optional) it is already the default
  FIELD_DELIMITER = ',' -- (optional) it is already the default
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'; -- not used in our case but handy option for enclosed strings

COPY INTO customers FROM @TUTO_DB.PUBLIC.%customers
  FILES = ('customers_raw.csv.gz')
  FILE_FORMAT = 'tuto_csv_format';

COPY INTO orders FROM @TUTO_DB.PUBLIC.%orders
  FILES = ('orders_raw.csv.gz')
  FILE_FORMAT = 'tuto_csv_format';

COPY INTO products FROM @TUTO_DB.PUBLIC.%products
  FILES = ('products_raw.csv.gz')
  FILE_FORMAT = 'tuto_csv_format';

CREATE VIEW customer_orders AS
  SELECT
    c.customer_name,
    p.product_name,
    p.price,
    o.quantity
  FROM orders o
  LEFT JOIN customers c
    ON o.customer_id = c.customer_id
  LEFT JOIN products p
    ON o.product_id = p.product_id;

SELECT * FROM customer_orders;
