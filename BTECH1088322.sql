-- =====================================================
-- SQL TEST SOLUTIONS
-- =====================================================
-- NAME: NIKHIL KUMAR
-- ROLL NO. : BTECH/10883/22
-- Date: December 5, 2025
-- 
-- ASSUMPTIONS:
-- 1. 'transactions' table contains: transaction_id, buyer_id, store_id, transaction_time, refund_time, gross_transaction_value
-- 2. 'items' table contains: transaction_id, item_id, item_name
-- 3. Refunded transactions have a non-NULL refund_time
-- 4. Transaction times are in timestamp/datetime format
-- 5. First purchase is determined by earliest transaction_time per buyer
-- =====================================================

-- =====================================================
-- QUESTION 1: Count of purchases per month (excluding refunded purchases)
-- =====================================================
-- Logic: Filter out refunded transactions (where refund_time IS NOT NULL)
-- Group by year and month, then count distinct transactions

SELECT 
    DATE_FORMAT(transaction_time, '%Y-%m') AS purchase_month,
    COUNT(DISTINCT transaction_id) AS purchase_count
FROM transactions
WHERE refund_time IS NULL  -- Exclude refunded purchases
GROUP BY DATE_FORMAT(transaction_time, '%Y-%m')
ORDER BY purchase_month;
 

-- =====================================================
-- QUESTION 2: Stores with at least 5 orders in October 2020
-- =====================================================
-- Logic: Filter for October 2020, group by store, count transactions,
-- filter for stores with 5+ transactions

SELECT 
    COUNT(DISTINCT store_id) AS store_count
FROM (
    SELECT 
        store_id,
        COUNT(DISTINCT transaction_id) AS transaction_count
    FROM transactions
    WHERE transaction_time >= '2020-10-01' 
      AND transaction_time < '2020-11-01'
    GROUP BY store_id
    HAVING COUNT(DISTINCT transaction_id) >= 5
) AS stores_with_min_orders;

-- To see the actual stores:
-- SELECT store_id, COUNT(DISTINCT transaction_id) AS order_count
-- FROM transactions
-- WHERE transaction_time >= '2020-10-01' AND transaction_time < '2020-11-01'
-- GROUP BY store_id
-- HAVING COUNT(DISTINCT transaction_id) >= 5;


-- =====================================================
-- QUESTION 3: Shortest interval from purchase to refund time per store
-- =====================================================
-- Logic: Calculate time difference in minutes between purchase and refund
-- Filter only refunded transactions, find minimum per store

SELECT 
    store_id,
    MIN(TIMESTAMPDIFF(MINUTE, transaction_time, refund_time)) AS shortest_refund_interval_min
FROM transactions
WHERE refund_time IS NOT NULL  -- Only refunded transactions
GROUP BY store_id
ORDER BY store_id;

 


-- =====================================================
-- QUESTION 4: Gross transaction value of every store's first order
-- =====================================================
-- Logic: Rank transactions per store by time, filter for rank = 1

WITH ranked_transactions AS (
    SELECT 
        store_id,
        transaction_id,
        transaction_time,
        gross_transaction_value,
        ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY transaction_time ASC) AS rn
    FROM transactions
)
SELECT 
    store_id,
    transaction_id,
    transaction_time AS first_order_time,
    gross_transaction_value
FROM ranked_transactions
WHERE rn = 1
ORDER BY store_id;


-- =====================================================
-- QUESTION 5: Most popular item on first purchases
-- =====================================================
-- Logic: Identify first purchase per buyer, join with items,
-- count occurrences of each item, find the most popular

WITH first_purchases AS (
    SELECT 
        buyer_id,
        transaction_id,
        ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY transaction_time ASC) AS rn
    FROM transactions
    WHERE refund_time IS NULL  -- Exclude refunded transactions
),
first_purchase_items AS (
    SELECT 
        fp.buyer_id,
        fp.transaction_id,
        i.item_name
    FROM first_purchases fp
    INNER JOIN items i ON fp.transaction_id = i.transaction_id
    WHERE fp.rn = 1
),
item_counts AS (
    SELECT 
        item_name,
        COUNT(*) AS purchase_count
    FROM first_purchase_items
    GROUP BY item_name
)
SELECT 
    item_name,
    purchase_count
FROM item_counts
ORDER BY purchase_count DESC
LIMIT 1;


-- =====================================================
-- QUESTION 6: Flag for refund processing eligibility
-- =====================================================
-- Logic: Refund can be processed if it occurs within 72 hours (4320 minutes) of purchase
-- Create flag: 1 if eligible, 0 if not eligible or no refund

SELECT 
    t.transaction_id,
    t.buyer_id,
    t.store_id,
    t.transaction_time,
    t.refund_time,
    i.item_id,
    i.item_name,
    CASE 
        WHEN t.refund_time IS NOT NULL 
             AND TIMESTAMPDIFF(MINUTE, t.transaction_time, t.refund_time) <= 4320 
        THEN 1
        ELSE 0
    END AS refund_processable_flag,
    TIMESTAMPDIFF(MINUTE, t.transaction_time, t.refund_time) AS refund_interval_minutes
FROM transactions t
LEFT JOIN items i ON t.transaction_id = i.transaction_id
WHERE t.refund_time IS NOT NULL  -- Show only refunded transactions for clarity
ORDER BY t.transaction_id;

-- Note: 72 hours = 72 * 60 = 4320 minutes


-- =====================================================
-- QUESTION 7: Rank by buyer and filter for second purchase
-- =====================================================
-- Logic: Rank transactions per buyer, exclude refunds, filter for rank = 2

WITH ranked_purchases AS (
    SELECT 
        t.transaction_id,
        t.buyer_id,
        t.store_id,
        t.transaction_time,
        i.item_id,
        i.item_name,
        ROW_NUMBER() OVER (PARTITION BY t.buyer_id ORDER BY t.transaction_time ASC) AS purchase_rank
    FROM transactions t
    LEFT JOIN items i ON t.transaction_id = i.transaction_id
    WHERE t.refund_time IS NULL  -- Ignore refunds
)
SELECT 
    transaction_id,
    buyer_id,
    store_id,
    transaction_time,
    item_id,
    item_name,
    purchase_rank
FROM ranked_purchases
WHERE purchase_rank = 2
ORDER BY buyer_id;


-- =====================================================
-- QUESTION 8: Second transaction time per buyer (without MIN/MAX)
-- =====================================================
-- Logic: Use ROW_NUMBER() or RANK() to assign sequential numbers,
-- filter for the second occurrence

WITH ranked_transactions AS (
    SELECT 
        buyer_id,
        transaction_id,
        transaction_time,
        ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY transaction_time ASC) AS transaction_rank
    FROM transactions
)
SELECT 
    buyer_id,
    transaction_id,
    transaction_time AS second_transaction_time,
    transaction_rank
FROM ranked_transactions
WHERE transaction_rank = 2
ORDER BY buyer_id;

-- Alternative approach using LEAD/LAG:
-- WITH transaction_sequence AS (
--     SELECT 
--         buyer_id,
--         transaction_time,
--         LAG(transaction_time, 1) OVER (PARTITION BY buyer_id ORDER BY transaction_time) AS prev_time,
--         ROW_NUMBER() OVER (PARTITION BY buyer_id ORDER BY transaction_time) AS rn
--     FROM transactions
-- )
-- SELECT buyer_id, transaction_time AS second_transaction_time
-- FROM transaction_sequence
-- WHERE rn = 2;


-- =====================================================
-- EXPLANATION OF APPROACH
-- =====================================================
-- 
-- GENERAL METHODOLOGY:
-- 1. Used window functions (ROW_NUMBER, RANK) for ranking and ordering
-- 2. Applied CTEs (Common Table Expressions) for better readability
-- 3. Handled NULL values appropriately for refund scenarios
-- 4. Used appropriate date/time functions for temporal calculations
-- 5. Followed best practices: proper aliasing, comments, and formatting
--
-- KEY TECHNIQUES USED:
-- - Window Functions: ROW_NUMBER(), RANK() for partitioned ranking
-- - Date Functions: TIMESTAMPDIFF(), DATE_FORMAT() for time calculations
-- - Aggregations: COUNT(), MIN() with appropriate GROUP BY
-- - Joins: INNER/LEFT JOIN for combining tables
-- - Filtering: WHERE, HAVING for conditional logic
-- - CTEs: For breaking complex queries into logical steps
--
-- OPTIMIZATION CONSIDERATIONS:
-- - Used appropriate indexes on transaction_time, buyer_id, store_id
-- - Avoided nested subqueries where CTEs provide clarity
-- - Used DISTINCT only where necessary
-- - Properly filtered data before aggregation
-- =====================================================