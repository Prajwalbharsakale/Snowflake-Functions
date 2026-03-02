--===========================================================
-- SNOWFLAKE SEMANTIC LAYER + AGG FUNCTION (BUSINESS METRICS)
--===========================================================
-- To provide a clear and run-ready example:
-- We first demonstrate Snowflake’s Semantic View and AGG() usage.
--
-- Important Concept:
-- AGG is NOT a normal aggregate function like SUM or COUNT.
-- It is a special keyword used ONLY to evaluate predefined
-- METRICS inside a Semantic View.
--
-- Why this matters:
--   • Ensures single source of truth for KPIs
--   • Prevents inconsistent metric calculations
--   • Centralizes business logic definition
--
-- In short:
-- Semantic View = Business Blueprint
-- AGG() = Secure Metric Evaluator
--===========================================================


--===========================================================
-- STEP 1: CREATE BASE SALES DATA
--===========================================================
-- This table simulates transactional sales data.
-- SALES_AMOUNT → Raw revenue
-- DISCOUNT_PCT → Discount percentage applied
--===========================================================

CREATE OR REPLACE TABLE SALES_DATA (
    REGION STRING,
    SALES_AMOUNT NUMBER(10,2),
    DISCOUNT_PCT NUMBER(3,2)
);

INSERT INTO SALES_DATA VALUES 
('North', 100.00, 0.10), ('North', 200.00, 0.05),
('South', 150.00, 0.00), ('South', 300.00, 0.20);



--===========================================================
-- STEP 2: CREATE SEMANTIC VIEW (BUSINESS BLUEPRINT)
--===========================================================
-- A Semantic View defines:
--   • Dimensions → Grouping attributes (like REGION)
--   • Metrics → Business KPIs with fixed calculation logic
--
-- Here we define:
--   total_revenue = SUM(SALES_AMOUNT * (1 - DISCOUNT_PCT))
--
-- This ensures EVERY query uses the same revenue formula.
--===========================================================

CREATE OR REPLACE SEMANTIC VIEW SALES_METRICS_VIEW
AS 
TABLES (
    sales AS SALES_DATA
)
DIMENSIONS (
    sales.REGION AS REGION
)
METRICS (
    -- Authoritative KPI definition
    total_revenue AS SUM(SALES_AMOUNT * (1 - DISCOUNT_PCT))
);



--===================================
-- AGG
--===================================
-- Description:
-- AGG evaluates a predefined metric inside a Semantic View.
--
-- Key Rule:
-- If querying a METRIC from a Semantic View,
-- it MUST be wrapped inside AGG().
--
-- Without AGG():
--   ❌ Snowflake will not compute the metric correctly.
--
-- With AGG():
--   ✅ Snowflake applies the authoritative metric definition.
--
-- Use Case:
--   • Enterprise KPI governance
--   • Finance dashboards
--   • Consistent BI reporting
--===================================

SELECT 
    REGION, 
    AGG(total_revenue) AS REVENUE
FROM SALES_METRICS_VIEW
GROUP BY REGION;



--===========================================================
-- STAGE CREATION FOR AI FILE PROCESSING
--===========================================================
-- Required for AI functions that process images or files.
-- Snowflake SSE encryption is mandatory for Cortex AI.
--===========================================================

CREATE OR REPLACE STAGE MY_IMAGE_STAGE 
ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
DIRECTORY = (ENABLE = TRUE);



--===========================================================
-- TABLE CREATION FOR AI TESTING
--===========================================================

CREATE OR REPLACE TABLE CUSTOMER_INSIGHTS (
    ID INT,
    PRODUCT_NAME STRING,
    FEEDBACK_TEXT STRING,
    IMAGE_URL file
);



--===========================================================
-- SAMPLE DATA INSERTION
--===========================================================

INSERT INTO CUSTOMER_INSIGHTS (ID, PRODUCT_NAME, FEEDBACK_TEXT)
VALUES 
(1, 'SmartBulb X', 'The setup was easy but the brightness is low.'),
(2, 'SmartBulb X', 'Battery life is terrible. It died in two days.'),
(3, 'PowerHub Pro', 'Best charger I ever owned. Super fast!'),
(4, 'PowerHub Pro', 'Delivery was late. The box was damaged.'),
(5, 'SmartLock 2.0', 'The app crashes every time I try to unlock the door.');



SELECT * FROM CUSTOMER_INSIGHTS;



--===================================
-- AI_AGG
--===================================
-- Reduces grouped text into AI-generated summary.
--===========================================================

SELECT 
    PRODUCT_NAME, 
    AI_AGG(FEEDBACK_TEXT, 'Summarize the top 2 customer pain points into a short bulleted list') AS PRODUCT_SUMMARY
FROM CUSTOMER_INSIGHTS
GROUP BY PRODUCT_NAME;



--===================================
-- AI_CLASSIFY
--===================================
-- Classifies text into predefined categories.
--===========================================================

SELECT 
    FEEDBACK_TEXT, 
    AI_CLASSIFY(FEEDBACK_TEXT, ['Technical Issue', 'Logistics', 'Positive Review']) AS CATEGORY_TAG
FROM CUSTOMER_INSIGHTS;



--===================================
-- AI_COMPLETE (Text Generation)
--===================================
-- Generates AI-based completion using specified model.
--===========================================================

SELECT 
    PRODUCT_NAME,
    AI_COMPLETE('llama3.1-70b', 
        CONCAT('Rewrite this as a professional Jira ticket title: ', FEEDBACK_TEXT)
    ) AS JIRA_TICKET_TITLE
FROM CUSTOMER_INSIGHTS
WHERE ID = 5;



--===================================
-- AI_COMPLETE (Image Processing)
--===================================
-- Uses multimodal model to analyze staged image file.
--===========================================================

SELECT AI_COMPLETE('claude-3-5-sonnet', 
    PROMPT('Describe the damage in this image: {0}', TO_FILE('@MY_IMAGE_STAGE', 'broken_box.png'))
) AS IMAGE_ANALYSIS;
