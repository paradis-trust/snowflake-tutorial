-- Module 4: Transformation and Serving
-- Create the schemas used to transform bronze data and serve curated results.
-- Run the data-loading module first.

CREATE DATABASE IF NOT EXISTS LOAD_TRANSFORM_SERVE;
CREATE SCHEMA IF NOT EXISTS LOAD_TRANSFORM_SERVE.SILVER;
CREATE SCHEMA IF NOT EXISTS LOAD_TRANSFORM_SERVE.GOLD;

USE DATABASE LOAD_TRANSFORM_SERVE;

-- BRONZE: source-aligned data loaded from files.
-- SILVER: cleaned, typed, and conformed data.
-- GOLD: business-facing aggregates and views.
SHOW SCHEMAS IN DATABASE LOAD_TRANSFORM_SERVE;
