

-- 1. Create a secure internal stage with Server-Side Encryption (Required for AI)
CREATE OR REPLACE STAGE MY_IMAGE_STAGE 
ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
DIRECTORY = (ENABLE = TRUE);


-- Create a table for AI testing
CREATE OR REPLACE TABLE CUSTOMER_INSIGHTS (
    ID INT,
    PRODUCT_NAME STRING,
    FEEDBACK_TEXT STRING,
    IMAGE_URL file -- Represents a staged file path for image examples
);

-- Insert sample data
INSERT INTO CUSTOMER_INSIGHTS (ID, PRODUCT_NAME, FEEDBACK_TEXT)
VALUES 
(1, 'SmartBulb X', 'The setup was easy but the brightness is low.'),
(2, 'SmartBulb X', 'Battery life is terrible. It died in two days.'),
(3, 'PowerHub Pro', 'Best charger I ever owned. Super fast!'),
(4, 'PowerHub Pro', 'Delivery was late. The box was damaged.'),
(5, 'SmartLock 2.0', 'The app crashes every time I try to unlock the door.');


SELECT * FROM CUSTOMER_INSIGHTS;

SELECT 
    PRODUCT_NAME, 
    AI_AGG(FEEDBACK_TEXT, 'Summarize the top 2 customer pain points into a short bulleted list') AS PRODUCT_SUMMARY
FROM CUSTOMER_INSIGHTS
GROUP BY PRODUCT_NAME;


SELECT 
    FEEDBACK_TEXT, 
    AI_CLASSIFY(FEEDBACK_TEXT, ['Technical Issue', 'Logistics', 'Positive Review']) AS CATEGORY_TAG
FROM CUSTOMER_INSIGHTS;


SELECT 
    PRODUCT_NAME,
    AI_COMPLETE('llama3.1-70b', 
        CONCAT('Rewrite this as a professional Jira ticket title: ', FEEDBACK_TEXT)
    ) AS JIRA_TICKET_TITLE
FROM CUSTOMER_INSIGHTS
WHERE ID = 5;


-- Note: Replace '@STAGED_FILES/box.png' with your actual stage path
SELECT AI_COMPLETE('claude-3-5-sonnet', 
    PROMPT('Describe the damage in this image: {0}', TO_FILE('@MY_IMAGE_STAGE', 'broken_box.png'))
) AS IMAGE_ANALYSIS;

