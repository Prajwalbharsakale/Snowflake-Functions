--===========================================================
-- DAY 4 – SNOWFLAKE CORTEX AI (DATA INTELLIGENCE FUNCTIONS)
--===========================================================
-- This section demonstrates advanced AI capabilities used in
-- enterprise data platforms:
--
--   • AI_REDACT        → Automatically mask sensitive data (PII)
--   • AI_SENTIMENT     → Detect emotional tone in text
--   • AI_SIMILARITY    → Measure semantic similarity
--   • AI_SUMMARIZE_AGG → Summarize grouped text data
--   • AI_PARSE_DOCUMENT→ Convert documents (PDF/DOCX) into JSON
--
-- These functions enable:
--   • Data privacy compliance (GDPR / HIPAA)
--   • Customer sentiment analysis
--   • Semantic search
--   • Automated document processing
--===========================================================



--===========================================================
-- STEP 1: SETUP TEST DATA
--===========================================================
-- Create a sandbox table for Day 4 AI functions.
-- The dataset contains:
--   • Customer feedback text
--   • Comparison sentences for similarity analysis
--   • Categories for aggregation examples
--===========================================================

USE DATABASE SNOWFLAKE_LEARNING_DB;
USE SCHEMA PUBLIC;

CREATE OR REPLACE TABLE AI_DAY4_TEST (
    ID INT,
    CATEGORY STRING,
    RAW_TEXT STRING,
    COMPARE_TEXT STRING
);

INSERT INTO AI_DAY4_TEST (ID, CATEGORY, RAW_TEXT, COMPARE_TEXT)
VALUES 
(1, 'Support', 'Customer John Doe (ID: 555-0199) is very happy with the fast shipping!', 'The delivery was quick.'),
(2, 'Support', 'User Jane Smith is frustrated because the app keeps crashing on her iPhone.', 'The mobile application is unstable.'),
(3, 'Sales', 'The pricing for the Pro plan is too high for small businesses.', 'The subscription cost is expensive.');



--===================================
-- AI_REDACT
--===================================
-- Description:
-- Automatically detects and masks Personally Identifiable
-- Information (PII) from text.
--
-- Supported entities include:
--   • PERSON_NAME
--   • PHONE_NUMBER
--   • EMAIL
--   • CREDIT_CARD
--   • ADDRESS
--
-- Output:
-- Sensitive data replaced with placeholders.
--
-- Example Result:
-- "Customer [NAME] (ID: [PHONE_NUMBER])..."
--
-- Use Case:
--   • Data privacy compliance
--   • Secure logging
--   • Preparing data for AI processing
--===================================

SELECT 
    AI_REDACT(RAW_TEXT, ['NAME', 'PHONE_NUMBER']) AS SAFE_TEXT
FROM AI_DAY4_TEST;



--===================================
-- AI_SENTIMENT
--===================================
-- Description:
-- Detects emotional tone in text.
--
-- Output Format:
-- Returns a JSON/VARIANT object containing:
--   • label → Positive / Negative / Neutral
--   • score → Confidence score
--
-- Use Case:
--   • Customer experience monitoring
--   • Social media sentiment analysis
--   • Product feedback evaluation
--===================================

SELECT 
    RAW_TEXT,
    AI_SENTIMENT(RAW_TEXT) AS SENTIMENT_SCORE
FROM AI_DAY4_TEST;



--===================================
-- AI_SIMILARITY
--===================================
-- Description:
-- Measures semantic similarity between two texts.
--
-- Unlike keyword matching, this compares meaning.
--
-- Output:
-- FLOAT value between 0 and 1
--
-- Interpretation:
--   1.0  → identical meaning
--   0.8+ → highly similar
--   0.5  → moderately similar
--   <0.3 → unrelated
--
-- Use Case:
--   • Duplicate ticket detection
--   • Knowledge base matching
--   • Semantic search
--===================================

SELECT 
    RAW_TEXT, 
    COMPARE_TEXT,
    AI_SIMILARITY(RAW_TEXT, COMPARE_TEXT) AS MATCH_SCORE
FROM AI_DAY4_TEST;



--===================================
-- AI_SUMMARIZE_AGG
--===================================
-- Description:
-- Aggregates and summarizes multiple rows of text
-- into a concise summary.
--
-- This is similar to AI_AGG but optimized specifically
-- for summarization tasks.
--
-- Use Case:
--   • Customer feedback summaries
--   • Support ticket overview
--   • Product review consolidation
--===================================

SELECT 
    RAW_TEXT,
    CATEGORY, 
    AI_SUMMARIZE_AGG(RAW_TEXT) AS CATEGORY_SUMMARY
FROM AI_DAY4_TEST
GROUP BY CATEGORY, RAW_TEXT;



--===================================
-- AI_PARSE_DOCUMENT
--===================================
-- Description:
-- Converts documents (PDF, DOCX, TXT) into structured JSON.
--
-- Extracts:
--   • Text content
--   • Tables
--   • Document layout
--   • Metadata
--
-- Requirement:
--   Document must be stored in a Snowflake stage
--   with Server-Side Encryption enabled.
--
-- Output:
-- JSON object representing document structure.
--
-- Use Case:
--   • Invoice processing
--   • Contract analysis
--   • Document intelligence pipelines
--===================================

-- Ensure stage metadata is refreshed
ALTER STAGE MY_IMAGE_STAGE REFRESH;

SELECT 
    AI_PARSE_DOCUMENT(TO_FILE('@MY_IMAGE_STAGE', 'invoice_legacy.pdf')) AS DOC_JSON
FROM DUAL;



--===================================
-- DOCUMENT INTELLIGENCE PIPELINE
--===================================
-- This example demonstrates a full pipeline:
--
-- Step 1 → Read document from stage
-- Step 2 → Convert document to JSON structure
-- Step 3 → Extract key fields using AI_EXTRACT
--
-- Result:
-- Fully structured business data from a raw document.
--===================================

SELECT 
    TO_FILE('@MY_IMAGE_STAGE', 'invoice_legacy.pdf') AS RAW_DATA,

    AI_PARSE_DOCUMENT(
        TO_FILE('@MY_IMAGE_STAGE', 'invoice_legacy.pdf')
    ) AS DOC_JSON,

    AI_EXTRACT(
        AI_PARSE_DOCUMENT(
            TO_FILE('@MY_IMAGE_STAGE', 'invoice_legacy.pdf')
        ):content,
        ['invoice_number', 'vendor', 'total_amount_due']
    ) AS FINAL_STRUCTURED_DATA;
