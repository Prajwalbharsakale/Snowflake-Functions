--===========================================================
-- DAY 5 – SNOWFLAKE CORTEX + PLATFORM INTELLIGENCE
--===========================================================
-- This section demonstrates additional capabilities available
-- in Snowflake that combine AI, language processing, monitoring,
-- and performance optimization.
--
-- Functions & Features Covered:
--
--   • AI_TRANSCRIBE  → Convert audio/video speech into text
--   • AI_TRANSLATE   → Translate text between languages
--   • ALERT_HISTORY  → Monitor Snowflake alerts
--   • ALL_USER_NAMES → Retrieve users in Snowflake account
--   • ANY_VALUE      → Performance optimized aggregation
--
-- These features enable:
--   • Speech-to-text pipelines
--   • Global multilingual applications
--   • Operational monitoring
--   • Metadata exploration
--   • Query optimization
--===========================================================



USE DATABASE SNOWFLAKE_LEARNING_DB;
USE SCHEMA PUBLIC;



--===========================================================
-- STEP 1: CREATE SAMPLE GLOBAL SUPPORT DATA
--===========================================================
-- This table simulates multilingual support tickets.
--
-- Columns:
--   TICKET_ID      → Unique support request identifier
--   ORIGINAL_TEXT  → Customer message in native language
--   USER_ID        → User submitting the ticket
--
-- Example languages included:
--   • Spanish
--   • German
--===========================================================

CREATE OR REPLACE TABLE GLOBAL_SUPPORT (
    TICKET_ID INT,
    ORIGINAL_TEXT STRING,
    USER_ID STRING
);

INSERT INTO GLOBAL_SUPPORT VALUES 
(101, 'El sistema está caído y necesito ayuda urgente.', 'USER_A'),
(102, 'Ich kann mich nicht einloggen.', 'USER_B');



--===================================
-- AI_TRANSCRIBE
--===================================
-- Description:
-- Converts speech from audio or video files into text.
--
-- Input:
--   • Audio/video file stored in a Snowflake stage
--   • Optional configuration parameters
--
-- Output:
-- Returns a JSON structure containing:
--   • text → full transcript
--   • segments → timestamped segments
--   • speaker_id → detected speakers
--   • audio_duration → total length of recording
--
-- Supported File Formats
--
-- Audio:
--   FLAC, MP3, MP4, OGG, WAV, WEBM
--
-- Video:
--   MKV, MP4, OGV, WEBM
--
-- Use Cases:
--   • Call center analytics
--   • Meeting transcription
--   • Voice assistant processing
--   • Podcast transcription
--===================================

SELECT 
    AI_TRANSCRIBE(
        TO_FILE('@MY_IMAGE_STAGE', 'Boney M - Rasputin (Lyrics) - 7clouds.mp3'),
        {'timestamp_granularity': 'word'}
    ) AS FULL_TRANSCRIPT;



-- Example Output Structure
-- {
--   "audio_duration": 220.8,
--   "segments": [],
--   "text": ""
-- }



--===================================
-- AI_TRANSLATE
--===================================
-- Description:
-- Translates text from one language to another.
--
-- Syntax:
--   AI_TRANSLATE(text, source_language, target_language)
--
-- Example:
--   English → French
--
-- Use Cases:
--   • Global customer support
--   • Multilingual chatbots
--   • Content localization
--===================================

SELECT 
    AI_TRANSLATE('Welcome to the Data Cloud', 'en','fr');

-- Example Result
-- English → Welcome to the Data Cloud
-- French  → Bienvenue dans le Cloud de données



--===========================================================
-- SUPPORTED LANGUAGE CODES
--===========================================================

-- Arabic       → 'ar'
-- Chinese      → 'zh'
-- Croatian     → 'hr'
-- Czech        → 'cs'
-- Dutch        → 'nl'
-- English      → 'en'
-- Finnish      → 'fi'
-- French       → 'fr'
-- German       → 'de'
-- Greek        → 'el'
-- Hebrew       → 'he'
-- Hindi        → 'hi'
-- Italian      → 'it'
-- Japanese     → 'ja'
-- Korean       → 'ko'
-- Norwegian    → 'no'
-- Polish       → 'pl'
-- Portuguese   → 'pt'
-- Romanian     → 'ro'
-- Russian      → 'ru'
-- Spanish      → 'es'
-- Swedish      → 'sv'
-- Turkish      → 'tr'



--===================================
-- ALERT_HISTORY
--===================================
-- Description:
-- Retrieves history of Snowflake alerts.
--
-- Alerts are automated triggers used for:
--   • Data quality checks
--   • Monitoring pipelines
--   • Sending notifications
--
-- This query checks alerts executed within
-- the last 24 hours.
--===================================

SELECT *
FROM TABLE(INFORMATION_SCHEMA.ALERT_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('hour', -24, CURRENT_TIMESTAMP()),
    SCHEDULED_TIME_RANGE_END => CURRENT_TIMESTAMP()
));

-- Example Output:
-- No rows returned if no alerts executed.



--===================================
-- ALL_USER_NAMES
--===================================
-- Description:
-- Returns a list of all user names in the
-- current Snowflake account.
--
-- Output Format:
-- JSON array containing usernames.
--
-- Use Cases:
--   • Metadata analysis
--   • Governance automation
--   • Security audits
--===================================

SELECT ALL_USER_NAMES();

-- Example Output
-- ["ADMIN_USER", "DATA_SCIENTIST_1", "REPORTING_BOT"]



--===================================
-- ANY_VALUE
--===================================
-- Description:
-- ANY_VALUE returns an arbitrary value from
-- a group of rows.
--
-- Unlike MIN() or MAX(), it does not perform
-- ordering or comparison, making it faster.
--
-- Use Case:
-- When you only need a representative value
-- from a group but don't care which one.
--
-- Example Scenario:
-- Each store belongs to one region, but the
-- region is repeated across rows.
--===================================

WITH store_sales AS (
    SELECT 'Store_A' AS store, 'North' AS region, 500 AS sales UNION ALL
    SELECT 'Store_A' AS store, 'North' AS region, 700 AS sales
)

SELECT 
    store, 
    ANY_VALUE(region) AS region_sample, 
    SUM(sales) AS total_sales
FROM store_sales
GROUP BY store;



-- Example Output
--
-- STORE    REGION_SAMPLE    TOTAL_SALES
-- Store_A  North            1200
