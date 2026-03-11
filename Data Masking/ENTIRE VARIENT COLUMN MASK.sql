--===========================================================
-- SNOWFLAKE MASKING POLICY ON VARIANT COLUMN
--===========================================================
-- Goal:
-- Demonstrate how to apply a masking policy to a VARIANT column
-- that contains semi-structured JSON / XML data.
--
-- Key Concept:
-- Instead of masking specific JSON attributes, this example
-- masks the entire VARIANT payload depending on the user's role.
--
-- Authorized Roles:
--   ACCOUNTADMIN
--   SECURITYADMIN
--
-- All other roles will receive a masked JSON object.
--===========================================================



--===========================================================
-- STEP 1: CREATE DATABASE & SCHEMA
--===========================================================

USE DATABASE SNOWFLAKE_LEARNING_DB;

CREATE OR REPLACE SCHEMA MASK_TEST;



--===========================================================
-- STEP 2: CREATE TABLE WITH VARIANT COLUMN
--===========================================================
-- VARIANT allows storage of semi-structured data such as:
--   • JSON
--   • XML
--   • Avro
--   • Parquet
--===========================================================

CREATE OR REPLACE TABLE raw_data_table 
(
    id NUMBER,
    payload VARIANT
);



--===========================================================
-- STEP 3: INSERT SAMPLE JSON DATA
--===========================================================
-- Example contains nested JSON objects representing:
--   • User information
--   • Account metadata
--   • Permission structures
--===========================================================

INSERT INTO raw_data_table (id, payload)
SELECT 
1,
PARSE_JSON('{
 "user": {
   "id": 1001,
   "name": "John Doe",
   "email": "john@example.com",
   "phone": "+1-987654321"
 },
 "account": {
   "role": "admin",
   "status": "active",
   "last_login": "2026-03-01T10:45:00Z"
 },
 "permissions": [
   {"module": "billing", "access": "write"},
   {"module": "reports", "access": "read"}
 ],
 "metadata": {
   "created_by": "system",
   "created_at": "2026-02-25"
 }
}');


INSERT INTO raw_data_table (id, payload)
SELECT 
2,
PARSE_JSON('{
 "user": {
   "id": 1002,
   "name": "Jane Smith",
   "email": "jane@example.com",
   "phone": "+1-123456789"
 },
 "account": {
   "role": "user",
   "status": "inactive",
   "last_login": "2026-02-15T09:30:00Z"
 },
 "permissions": [
   {"module": "billing", "access": "read"},
   {"module": "analytics", "access": "read"}
 ],
 "metadata": {
   "created_by": "admin",
   "created_at": "2026-02-20"
 }
}');



--===========================================================
-- VERIFY INSERTED DATA
--===========================================================

SELECT * FROM raw_data_table;



--===================================
-- MASKING POLICY : mask_entire_variant
--===================================
-- Description:
-- This masking policy protects sensitive semi-structured data.
--
-- Logic:
--   If role is ACCOUNTADMIN or SECURITYADMIN
--       → Return original JSON payload
--
--   Otherwise
--       → Return masked JSON response
--
-- Masked Response Example:
-- {
--   "status": "MASKED_BY_POLICY",
--   "reason": "Unauthorized Role",
--   "message": "Sensitive JSON hidden"
-- }
--
-- Use Case:
--   • Protect sensitive JSON data
--   • Secure API payloads
--   • Control access to PII stored in VARIANT
--===================================

CREATE OR REPLACE MASKING POLICY mask_entire_variant
AS (val VARIANT)
RETURNS VARIANT ->
CASE
    WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN','SECURITYADMIN')
        THEN val
    ELSE
        PARSE_JSON('{
            "status":"MASKED_BY_POLICY",
            "reason":"Unauthorized Role",
            "message":"Sensitive JSON hidden"
        }')
END;



--===========================================================
-- APPLY MASKING POLICY TO VARIANT COLUMN
--===========================================================

ALTER TABLE raw_data_table
MODIFY COLUMN payload
SET MASKING POLICY mask_entire_variant;



--===========================================================
-- TEST ACCESS WITH ADMIN ROLE
--===========================================================

USE ROLE ACCOUNTADMIN;

SELECT * FROM raw_data_table;



--===========================================================
-- TEST ACCESS WITH NON-PRIVILEGED ROLE
--===========================================================

USE ROLE PUBLIC;

SELECT * FROM raw_data_table;





--===========================================================
-- VARIOUS TYPES OF VARIANT DATA.
--===========================================================




--===========================================================
-- XML DATA EXAMPLE (VARIANT SUPPORT)
--===========================================================
-- Snowflake can store XML inside VARIANT as JSON format.
--
-- Steps:
--   1. Parse XML using PARSE_XML
--   2. Convert XML to JSON using TO_JSON
--   3. Store result inside VARIANT column
--===========================================================

INSERT INTO raw_data_table
SELECT 
3,
PARSE_JSON(
    TO_JSON(
        PARSE_XML('
            <employee>
                <id>20
                01</id>
                <name>Alice Brown</name>
                <email>alice@example.com</email>
                <department>Finance</department>
            </employee>
        ')
    )
);

--===========================================================
-- TEST ACCESS WITH NON-PRIVILEGED ROLE
--===========================================================

USE ROLE PUBLIC;

SELECT * FROM raw_data_table;












--===========================================================
-- SNOWFLAKE MASKING POLICY FOR SEMI-STRUCTURED DATA
-- JSON | XML | AVRO | PARQUET
--
-- Demonstrates:
-- 1. Masking JSON PII fields
-- 2. Masking XML attributes
-- 3. Masking AVRO data fields
-- 4. Masking PARQUET data fields
--
-- Key Concept:
-- Snowflake masking policies operate at the column level.
-- For VARIANT data we modify the JSON object using:
--
-- OBJECT_INSERT()
-- OBJECT_DELETE()
-- OBJECT_CONSTRUCT()
--
-- Author: Demo Script
--===========================================================



--===========================================================
-- 3️⃣ AVRO MASKING EXAMPLE
--===========================================================
-- AVRO data usually arrives from external files
-- and is loaded through a stage.
--===========================================================

CREATE OR REPLACE STAGE avro_stage;


CREATE OR REPLACE TABLE avro_data_table
(
record VARIANT
);


-- Load AVRO file
-- (Example requires AVRO files inside the stage)

COPY INTO avro_data_table
FROM @avro_stage
FILE_FORMAT=(TYPE=AVRO);


-- Example AVRO record structure
/*
{
 "user_id":2001,
 "name":"Robert",
 "email":"robert@example.com",
 "credit_card":"4111-XXXX-XXXX-1111"
}
*/


-- AVRO Masking Policy
CREATE OR REPLACE MASKING POLICY mask_avro_creditcard
AS (val VARIANT)
RETURNS VARIANT ->
CASE
WHEN CURRENT_ROLE()='ACCOUNTADMIN'
THEN val
ELSE OBJECT_INSERT(val,'credit_card','****MASKED****')
END;


ALTER TABLE avro_data_table
MODIFY COLUMN record
SET MASKING POLICY mask_avro_creditcard;



--===========================================================
-- 4️⃣ PARQUET MASKING EXAMPLE
--===========================================================
-- Parquet files are commonly used in data lakes.
--===========================================================

CREATE OR REPLACE STAGE parquet_stage;


CREATE OR REPLACE TABLE parquet_data_table
(
data VARIANT
);


COPY INTO parquet_data_table
FROM @parquet_stage
FILE_FORMAT=(TYPE=PARQUET);


-- Example Parquet record structure
/*
{
 "customer_id":3001,
 "name":"Michael",
 "email":"michael@example.com",
 "salary":120000
}
*/


-- Parquet Masking Policy
CREATE OR REPLACE MASKING POLICY mask_parquet_salary
AS (val VARIANT)
RETURNS VARIANT ->
CASE
WHEN CURRENT_ROLE() IN ('ACCOUNTADMIN')
THEN val
ELSE OBJECT_INSERT(val,'salary','REDACTED')
END;


ALTER TABLE parquet_data_table
MODIFY COLUMN data
SET MASKING POLICY mask_parquet_salary;



--===========================================================
-- 5️⃣ ROLE TESTING
--===========================================================
-- Test how different roles see the masked data
--===========================================================

-- Admin role sees full data
USE ROLE ACCOUNTADMIN;
SELECT * FROM json_data_table;


-- Public role sees masked data
USE ROLE PUBLIC;
SELECT * FROM json_data_table;



--===========================================================
-- END OF SCRIPT
--
-- This demo shows masking for:
-- JSON
-- XML
-- AVRO
-- PARQUET
--
-- All handled through VARIANT columns
-- and Snowflake dynamic masking policies.
--===========================================================
