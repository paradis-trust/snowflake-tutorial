{{
  config(
    materialized='incremental',
    incremental_strategy='merge',
    unique_key='order_id',
    on_schema_change='sync_all_columns'
  )
}}

WITH SOURCE_ORDERS AS (
  SELECT *
  FROM {{ ref('int_orders_deduplicated') }}

  {% if is_incremental() %}
    WHERE BRONZE_LOADED_AT >= (
      SELECT COALESCE(MAX(BRONZE_LOADED_AT), '1900-01-01'::TIMESTAMP_LTZ)
      FROM {{ this }}
    )
  {% endif %}
)

SELECT
  ORDER_ID,
  CUSTOMER_ID,
  ORDER_DATE,
  STATUS,
  SALES_CHANNEL,
  CURRENCY,
  ORDER_TOTAL,
  DISCOUNT_AMOUNT,
  NET_ORDER_TOTAL,
  SHIPPING_CITY,
  SHIPPING_COUNTRY,
  IS_COMPLETED,
  BRONZE_LOADED_AT,
  CURRENT_TIMESTAMP() AS DBT_MODELED_AT
FROM SOURCE_ORDERS
