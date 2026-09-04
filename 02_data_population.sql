USE support_analytics;

-- 1. Insert 15 Agents across shifts and tiers
INSERT INTO agents (agent_id, agent_name, tier, shift, hire_date) VALUES
(1, 'Aarav Sharma', 'Tier 1', 'Morning', '2024-01-15'),
(2, 'Priya Nair', 'Tier 2', 'Morning', '2023-08-10'),
(3, 'Rohan Verma', 'Tier 1', 'Evening', '2024-03-01'),
(4, 'Sneha Patel', 'Tier 1', 'Evening', '2023-11-20'),
(5, 'Vikram Singh', 'Tier 2', 'Night', '2023-05-12'),
(6, 'Neha Gupta', 'Tier 1', 'Night', '2024-02-01'),
(7, 'Amit Roy', 'Tier 3', 'Morning', '2022-10-05'),
(8, 'Kavita Pillai', 'Tier 2', 'Evening', '2023-04-18'),
(9, 'Rahul Dravid', 'Tier 1', 'Morning', '2024-07-22'),
(10, 'Ananya Das', 'Tier 1', 'Night', '2024-09-15'),
(11, 'Kunal Kapoor', 'Tier 2', 'Night', '2023-12-01'),
(12, 'Meera Sen', 'Tier 1', 'Evening', '2024-04-11'),
(13, 'Suresh Raina', 'Tier 3', 'Evening', '2022-06-30'),
(14, 'Divya Nair', 'Tier 1', 'Morning', '2024-08-01'),
(15, 'Harsh Vardhan', 'Tier 2', 'Morning', '2023-03-14');

-- 2. Generate 100 Customers using a Recursive CTE
INSERT INTO customers (customer_id, customer_name, email, account_tier, signup_date)
WITH RECURSIVE seq AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM seq WHERE n < 100
)
SELECT 
    100 + n AS customer_id,
    CONCAT('Customer_', 100 + n) AS customer_name,
    CONCAT('user', 100 + n, '@samplecorp.com') AS email,
    ELT(1 + FLOOR(RAND() * 3), 'Free', 'Pro', 'Enterprise') AS account_tier,
    DATE_SUB('2026-03-31', INTERVAL FLOOR(RAND() * 500) DAY) AS signup_date
FROM seq;

SET cte_max_recursion_depth = 2000;

INSERT INTO chat_interactions (
    customer_id,
    agent_id,
    chat_start_time,
    chat_end_time,
    wait_time_seconds,
    topic,
    resolution_status,
    csat_score
)
WITH RECURSIVE interaction_gen AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1 FROM interaction_gen WHERE n < 1200
)
SELECT 
    -- Customer distribution (picks from our 100 customers)
    101 + FLOOR(RAND() * 100) AS customer_id,
    
    -- Agent distribution (picks from our 15 agents)
    1 + FLOOR(RAND() * 15) AS agent_id,
    
    -- Start timestamp: Distributed randomly over March 2026
    @start_ts := TIMESTAMPADD(
        SECOND, 
        FLOOR(RAND() * 2592000), -- 30 days in seconds
        '2026-03-01 00:00:00'
    ) AS chat_start_time,
    
    -- End timestamp: Start time + random handle duration between 5 and 35 minutes
    TIMESTAMPADD(SECOND, FLOOR(300 + RAND() * 1800), @start_ts) AS chat_end_time,
    
    -- Wait time: Between 20 and 450 seconds
    FLOOR(20 + RAND() * 430) AS wait_time_seconds,
    
    -- Topics
    ELT(1 + FLOOR(RAND() * 5), 'Billing', 'Account Access', 'Bug Report', 'Subscription', 'Technical Issue') AS topic,
    
    -- Resolution status: ~70% Resolved, 18% Escalated, 12% Unresolved
    CASE 
        WHEN RAND() < 0.70 THEN 'Resolved'
        WHEN RAND() < 0.88 THEN 'Escalated'
        ELSE 'Unresolved'
    END AS resolution_status,
    
    -- CSAT: ~30% NULL (unrated), remaining scored 1 to 5
    CASE 
        WHEN RAND() < 0.30 THEN NULL
        WHEN RAND() < 0.45 THEN 1
        WHEN RAND() < 0.60 THEN 2
        WHEN RAND() < 0.75 THEN 3
        WHEN RAND() < 0.90 THEN 4
        ELSE 5
    END AS csat_score
FROM interaction_gen;
