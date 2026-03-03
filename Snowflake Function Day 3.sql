--===========================================================
-- DAY 3 – SNOWFLAKE CORTEX AI TOOLKIT (ADVANCED FUNCTIONS)
--===========================================================
-- This section demonstrates advanced AI utility functions:
--
--   • AI_COUNT_TOKENS → Estimate token usage (Cost Control)
--   • AI_EXTRACT      → Convert unstructured text into structured JSON
--   • AI_FILTER       → Content moderation & policy validation
--   • AI_EMBED        → Generate vector embeddings for search/RAG
--
-- These functions are critical for:
--   • Cost management
--   • Data extraction automation
--   • Content governance
--   • Vector-based semantic search
--===========================================================


USE DATABASE SNOWFLAKE_LEARNING_DB;
USE SCHEMA PUBLIC;



--===========================================================
-- STEP 1: CREATE SAMPLE UNSTRUCTURED DATA
--===========================================================
-- This simulates:
--   • Invoice email
--   • Payment reminder
--   • Informal + potentially toxic language
--===========================================================

CREATE OR REPLACE TABLE AI_DAY3_TEST (
    UNSTRUCTURED_NOTE STRING
);

INSERT INTO AI_DAY3_TEST VALUES 
('Urgent: Invoice 998 for $1,200.00 is overdue as of March 1st. Please pay immediately you lazy person!');



--===================================
-- AI_COUNT_TOKENS
--===================================
-- Description:
-- Estimates the number of tokens a prompt will consume
-- for a specific AI function + model.
--
-- Why Important?
--   • Controls LLM cost
--   • Avoids context window overflow
--   • Essential for production governance
--
-- Rule:
-- You MUST specify:
--   1. Target AI function
--   2. Model name
--   3. Prompt text
--===================================

-- ❌ Incorrect Syntax Example (Missing model & proper parameters)
SELECT 
    AI_COUNT_TOKENS('AI_ANALYSE', UNSTRUCTURED_NOTE) AS TOKEN_COUNT 
FROM AI_DAY3_TEST;


-- ✅ Correct Syntax
SELECT 
    UNSTRUCTURED_NOTE AS TOKEN_STRING,
    AI_COUNT_TOKENS('ai_complete', 'llama3.1-70b', UNSTRUCTURED_NOTE) AS TOKEN_COUNT 
FROM AI_DAY3_TEST;



--===================================
-- AI_EXTRACT (Text Extraction)
--===================================
-- Description:
-- Extracts structured data from unstructured text.
--
-- Output:
--   Returns JSON object with requested fields.
--
-- Use Case:
--   • Invoice parsing
--   • Email processing
--   • NLP-based ETL automation
--===================================

SELECT 
    UNSTRUCTURED_NOTE AS ORIGINAL_NOTE, 
    AI_EXTRACT(UNSTRUCTURED_NOTE, ['invoice_id', 'amount']) AS EXTRACTED_NOTE 
FROM AI_DAY3_TEST;



--===================================
-- AI_FILTER
--===================================
-- Description:
-- Moderates or validates content against policy rules.
--
-- Use Case:
--   • Detect insults
--   • Detect policy violations
--   • Governance enforcement
--
-- Important:
-- PROMPT() must wrap dynamic text.
-- Otherwise Snowflake treats it incorrectly
-- and throws compilation errors.
--===================================

-- ❌ Error Scenario
-- SQL compilation error:
-- argument RETURN_ERROR_DETAILS must be constant

SELECT AI_FILTER('Does this contain personal insults?',UNSTRUCTURED_NOTE) 
AS HAS_INSULTS 
FROM AI_DAY3_TEST;


-- ✅ Correct Implementation
SELECT 
    UNSTRUCTURED_NOTE, AI_FILTER( PROMPT( 'Does the following text contain any personal insults? {0}', UNSTRUCTURED_NOTE)) AS HAS_INSULTS 
FROM AI_DAY3_TEST;



--===================================
-- AI_EMBED
--===================================
-- Description:
-- Generates vector embeddings from text.
--
-- Model Used:
--   snowflake-arctic-embed-m
--
-- Output:
--   Returns high-dimensional vector
--
-- Use Case:
--   • Semantic search
--   • RAG (Retrieval-Augmented Generation)
--   • Similarity matching
--   • Recommendation systems
--===================================

SELECT 
    AI_EMBED('snowflake-arctic-embed-m', UNSTRUCTURED_NOTE) AS VECTOR_DATA
FROM AI_DAY3_TEST;



--===================================
-- AI_EXTRACT (Legacy Document File Example)
--===================================
-- Description:
-- AI_EXTRACT can also process document files
-- stored inside a secure Snowflake stage.
--
-- Supported:
--   • PDF
--   • DOCX
--   • TXT
--
-- Requirement:
--   • File must be inside encrypted internal stage
--   • Use TO_FILE() to convert staged file reference
--
-- Use Case:
--   • Invoice PDF parsing
--   • Resume screening
--   • Contract metadata extraction
--===================================

SELECT 
    AI_EXTRACT(
        TO_FILE('@MY_IMAGE_STAGE', 'broken_box.png'),
        ['invoice_id', 'invoice_date', 'total_amount', 'Is it really broken', 'broken_box', 'Can you tell how much percentage it broken'
        ,'What kind of material it is']
    ) AS EXTRACTED_DOCUMENT_DATA;
