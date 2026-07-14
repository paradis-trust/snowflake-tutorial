-- Chapter 2: TABLE() and table functions
--
-- A table function produces rows and columns, so it can be used in FROM.
-- TABLE(...) turns a table-function call into a table source for a query.
-- This file uses two built-in table functions: FLATTEN and SPLIT_TO_TABLE.

USE DATABASE SQL_IN_SNOWFLAKE;
USE SCHEMA TPCH;

-- 1. FLATTEN turns the elements of an array into individual rows.
-- VALUE is a VARIANT value, so cast it to VARCHAR for a text result.
SELECT
  F.INDEX AS position,
  F.VALUE::VARCHAR AS topic
FROM TABLE(
  FLATTEN(INPUT => PARSE_JSON('["Snowflake", "SQL", "analytics"]'))
) AS F
ORDER BY position;

-- 2. SPLIT_TO_TABLE turns a delimiter-separated string into rows.
-- INDEX starts at 1; VALUE contains one piece of the original string.
SELECT
  S.INDEX AS position,
  S.VALUE AS topic
FROM TABLE(SPLIT_TO_TABLE('Snowflake|SQL|analytics', '|')) AS S
ORDER BY position;

-- 3. LATERAL applies a table function once per input row.
-- Each input string is expanded while the original row's columns remain usable.
WITH learning_paths AS (
  SELECT 1 AS path_id, 'SQL|joins|window functions' AS topics
  UNION ALL
  SELECT 2 AS path_id, 'loading data|stages|COPY INTO' AS topics
)
SELECT
  P.path_id,
  S.INDEX AS topic_position,
  S.VALUE AS topic
FROM learning_paths AS P,
LATERAL SPLIT_TO_TABLE(P.topics, '|') AS S
ORDER BY P.path_id, topic_position;

-- 4. FLATTEN can also expand an array stored in each input row.
WITH examples AS (
  SELECT 1 AS example_id, PARSE_JSON('["small", "fast"]') AS labels
  UNION ALL
  SELECT 2 AS example_id, PARSE_JSON('["shared", "read-only"]') AS labels
)
SELECT
  E.example_id,
  F.INDEX AS label_position,
  F.VALUE::VARCHAR AS label
FROM examples AS E,
LATERAL FLATTEN(INPUT => E.labels) AS F
ORDER BY E.example_id, label_position;

-- TABLE(GENERATOR(...)) is another table-function call. See 07_generator.sql
-- for dedicated examples of generating rows.
