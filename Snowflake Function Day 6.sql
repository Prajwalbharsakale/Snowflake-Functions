--===========================================================
-- SNOWFLAKE PLATFORM ANALYTICS & APPROXIMATE FUNCTIONS
--===========================================================
-- This section demonstrates advanced Snowflake capabilities:
--
--   • Application configuration monitoring
--   • Application notifications
--   • High-performance approximate analytics
--   • Percentile estimation for large datasets
--
-- Key Concepts:
--   APPROX_COUNT_DISTINCT  → Fast cardinality estimation
--   APPROX_PERCENTILE      → Fast percentile estimation
--   APPLICATION_JSON       → Structured alert payload generation
--   INFORMATION_SCHEMA     → Platform metadata & monitoring
--===========================================================



--===========================================================
-- APPLICATION CONFIGURATION HISTORY
--===========================================================
-- Retrieves historical configuration changes
-- for a Snowflake Native Application.
--
-- Useful for:
--   • Governance auditing
--   • Debugging configuration changes
--   • Monitoring application upgrades
--===========================================================

USE SNOWFLAKE;

SELECT 
    -- APPLICATION_NAME,
    -- PARAMETER_NAME,
    -- VALUE,
    -- PREVIOUS_VALUE,
    -- UPDATED_BY,
    -- UPDATED_ON
    *
FROM TABLE(
    INFORMATION_SCHEMA.APPLICATION_CONFIGURATION_VALUE_HISTORY(
        APPLICATION_NAME => 'SNOWFLAKE'
        -- START_TIME => DATEADD('day', -7, CURRENT_TIMESTAMP()),
        -- END_TIME => CURRENT_TIMESTAMP(),
        -- RESULT_LIMIT => 100
    )
);



--===========================================================
-- LIST ALL INSTALLED APPLICATIONS
--===========================================================
-- Displays Native Apps installed in your account.
--===========================================================

SHOW APPLICATIONS;



--===========================================================
-- SNOWFLAKE NOTIFICATION MESSAGE FORMAT
--===========================================================
-- APPLICATION_JSON converts a JSON string into
-- a structured notification payload.
--
-- This format is commonly used in:
--   • Alert notifications
--   • Pipeline monitoring
--   • Event messaging
--===========================================================


--===========================================================
-- EXAMPLE 1 – PIPELINE FAILURE ALERT
--===========================================================

SELECT SNOWFLAKE.NOTIFICATION.APPLICATION_JSON(
'{
  "alert_type": "PIPE_FAILURE",
  "owner": "DATA_ENGINEERING",
  "pipeline": "CLAIMS_ETL",
  "severity": "CRITICAL",
  "timestamp": "2026-03-05 20:41:57.256 -0800"
}'
) AS ALERT_MESSAGE;



-- IMPORTANT NOTE
-- APPLICATION_JSON expects a JSON STRING.
-- Passing OBJECT_CONSTRUCT will cause an error.

-- WRONG EXAMPLE
-- SELECT SNOWFLAKE.NOTIFICATION.APPLICATION_JSON(
-- OBJECT_CONSTRUCT(
--     'alert_type','PIPE_FAILURE',
--     'pipeline','CLAIMS_ETL',
--     'severity','CRITICAL',
--     'timestamp',CURRENT_TIMESTAMP(),
--     'owner','DATA_ENGINEERING'
-- )
-- );



--===========================================================
-- EXAMPLE 2 – SIMPLE APPLICATION MESSAGE
--===========================================================

SELECT SNOWFLAKE.NOTIFICATION.APPLICATION_JSON('{"data": "hello world"}');



--===========================================================
-- APPLICATION SPECIFICATION STATUS HISTORY
--===========================================================
-- Retrieves lifecycle history of a Snowflake Native App.
--
-- Tracks:
--   • Installation status
--   • Updates
--   • Package changes
--===========================================================

SELECT 
TABLE(
 INFORMATION_SCHEMA.APPLICATION_SPECIFICATION_STATUS_HISTORY(
      APPLICATION_NAME => '<app_name>',
      START_TIME => <timestamp>,
      END_TIME => <timestamp>,
      RESULT_LIMIT => <number>
 )
);



--===========================================================
-- LARGE SCALE ANALYTICS TEST DATA
--===========================================================
-- Simulate a large web log dataset to demonstrate
-- approximate analytics performance.
--===========================================================

USE DATABASE SNOWFLAKE_LEARNING_DB;
USE SCHEMA PUBLIC;

CREATE OR REPLACE TABLE WEB_LOGS
(
USER_ID INT,
SESSION_ID STRING
);

INSERT INTO WEB_LOGS
SELECT
UNIFORM(1,1000000,RANDOM()),
UUID_STRING()
FROM TABLE(GENERATOR(ROWCOUNT => 10000000));



--===========================================================
-- APPROX_COUNT_DISTINCT
--===========================================================
-- Estimates the number of unique values.
--
-- Advantages:
--   • Much faster than COUNT(DISTINCT)
--   • Uses probabilistic algorithms
--   • Ideal for very large datasets
--
-- Tradeoff:
--   Slight estimation error (~1–2%)
--===========================================================

SELECT
APPROX_COUNT_DISTINCT(USER_ID) AS ESTIMATED_USERS
FROM WEB_LOGS;



-- Compare Exact vs Approximate Count

SELECT
COUNT(DISTINCT USER_ID) EXACT_USERS,
APPROX_COUNT_DISTINCT(USER_ID) ESTIMATED_USERS
FROM WEB_LOGS;



SELECT COUNT(*) FROM WEB_LOGS;



-- Daily unique user estimate

SELECT
DATE_TRUNC('DAY',CURRENT_TIMESTAMP()) AS LOG_DAY,
APPROX_COUNT_DISTINCT(USER_ID)
FROM WEB_LOGS
GROUP BY 1;



--===========================================================
-- PERFORMANCE TEST USING SNOWFLAKE SAMPLE DATA
--===========================================================
-- Demonstrates performance difference between:
--   COUNT(DISTINCT)
--   APPROX_COUNT_DISTINCT
--===========================================================

USE DATABASE SNOWFLAKE_SAMPLE_DATA;
USE SCHEMA TPCH_SF1000;



SELECT
  COUNT(DISTINCT L_SHIPDATE) AS exact_count_date
FROM
  LINEITEM;

-- Example Result
-- COUNT: 2526
-- Execution Time: ~34 seconds



SELECT
  APPROX_COUNT_DISTINCT(L_SHIPDATE) AS approx_count_date
FROM
  LINEITEM;

-- Example Result
-- COUNT: 2551
-- Execution Time: ~10 seconds



SELECT
  COUNT(DISTINCT L_ORDERKEY) AS exact_count_order
FROM
  LINEITEM;



SELECT
  APPROX_COUNT_DISTINCT(DISTINCT L_ORDERKEY) AS approx_count_order
FROM
  LINEITEM;



--===========================================================
-- APPROX_PERCENTILE
--===========================================================
-- Estimates percentile values efficiently.
--
-- Useful for:
--   • Performance monitoring
--   • Latency analysis
--   • Big data statistics
--===========================================================



-- Finding the 95th percentile query execution time

SELECT APPROX_PERCENTILE(EXECUTION_TIME, 0.95) 
FROM INFORMATION_SCHEMA.QUERY_HISTORY();



--===========================================================
-- PERFORMANCE ANALYTICS EXAMPLE
--===========================================================

USE DATABASE SNOWFLAKE_LEARNING_DB;
USE SCHEMA PUBLIC;


CREATE OR REPLACE TABLE MASSIVE_LOGS 
(
USER_ID INT, 
LATENCY_MS FLOAT
);

INSERT INTO MASSIVE_LOGS
SELECT SEQ4(), UNIFORM(1, 500, RANDOM())
FROM TABLE(GENERATOR(ROWCOUNT => 100000));



SELECT 
    APPROX_COUNT_DISTINCT(USER_ID) AS ESTIMATED_UNIQUE_USERS,
    APPROX_PERCENTILE(LATENCY_MS, 0.90) AS P90_LATENCY
FROM MASSIVE_LOGS;



--===========================================================
-- PERCENTILE DEMONSTRATION DATA
--===========================================================

CREATE TABLE testtable (c1 INTEGER);

INSERT INTO testtable (c1) VALUES
  (0),(1),(2),(3),(4),(5),(6),(7),(8),(9),(10);



-- 10th Percentile

SELECT APPROX_PERCENTILE(c1, 0.1)
FROM testtable;



-- 50th Percentile (Median Approximation)

SELECT APPROX_PERCENTILE(c1, 0.5)
FROM testtable;



-- Extreme percentile example

SELECT APPROX_PERCENTILE(c1, 0.999)
FROM testtable;



-- Note:
-- Returned values may exceed the actual dataset values
-- because approximation algorithms interpolate results.
