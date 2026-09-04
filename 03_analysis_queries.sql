/* 
Task 1: Shift Performance & Efficiency Overview
Business Goal:
Operations leadership wants a high-level summary comparing the three shifts (Morning, Evening, Night) to understand workload and customer experience.

What to return:

Shift name (shift).
Total number of chats handled.
Average wait time in seconds (avg_wait_seconds), rounded to 1 decimal place.
Average handle time in minutes (avg_handle_minutes), rounded to 1 decimal place.
Average CSAT score (avg_csat), rounded to 2 decimal places.

Order the results by total chat volume in descending order.
*/

SELECT
	a.shift,
    COUNT(i.chat_id) AS total_chats,
    ROUND(AVG(i.wait_time_seconds),1) AS avg_wait_time,
    ROUND(AVG(i.csat_score), 2) AS avg_csat_score,
    ROUND(AVG(TIMESTAMPDIFF(SECOND, i.chat_start_time, i.chat_end_time)) / 60.0, 1) AS avg_handing_time
FROM chat_interactions i
LEFT JOIN agents a
ON a.agent_id = i.agent_id
GROUP BY a.shift
ORDER BY total_chats DESC;

/*
Task 2: First-Contact Resolution (FCR) & Escalation Rate by Topic
Business Goal:
The support lead wants to identify which contact topics are causing the most friction and repeat work.

What to return:

Topic name (topic).
Total chats for that topic.
Total number of resolved chats.
Resolution rate (resolution_rate_pct) as a percentage rounded to 1 decimal place (e.g., 80.0 for 80%).
Total number of escalated chats.

Constraint:
Use conditional aggregation (COUNT(CASE ...) or SUM(CASE ...)) to compute the resolved and escalated counts.
*/

WITH CTE AS (
SELECT
	topic,
    COUNT(chat_id) total_chats,
    SUM(CASE 
		WHEN resolution_status = 'Resolved' THEN 1
		ELSE 0 END) AS total_resolved,
	SUM(CASE 
		WHEN resolution_status = 'Escalated' THEN 1
		ELSE 0 END) AS total_escalated
FROM chat_interactions
GROUP BY
topic
)
SELECT
*,
ROUND(total_resolved/NULLIF(total_chats, 0) * 100, 1) AS resolution_rate_pct
FROM CTE;

/*
Task 3: Agent Performance Ranking & CSAT Distribution
Business Goal:

Workforce management wants a scorecard for each agent to see their volume, their average rating, and how they rank against their peers within the same shift.

What to return:

agent_name (Agent's name)
shift (Shift: Morning, Evening, Night)
chats_handled (Total chats handled by the agent)
avg_csat (Average CSAT score, rounded to 2 decimal places)
shift_csat_rank (Agent's rank within their own shift based on avg_csat in descending order, where highest CSAT gets Rank 1)
*/

SELECT
	a.agent_id,
	a.agent_name,
	a.shift,
    COUNT(i.chat_id) AS total_chats_handled,
    ROUND(AVG(i.csat_score), 2) AS avg_csat,
    ROW_NUMBER() OVER(PARTITION BY a.shift ORDER BY ROUND(AVG(i.csat_score), 2) DESC) AS shift_csat_rank
FROM agents a
LEFT JOIN chat_interactions i
ON a.agent_id = i.agent_id
GROUP BY
	a.agent_id,
	a.agent_name,
	a.shift;
    
/*
Task 4
Business Goal:

Repeat contacts often point to unresolved issues from prior sessions. Operations wants to flag every chat where the same customer initiated a new chat within 24 hours of their previous chat ending.

What to return:

customer_id
chat_id (current chat)
chat_start_time (current chat start)
previous_chat_end_time (when their previous chat ended)
hours_since_last_chat (hours elapsed between previous end time and current start time, rounded to 1 decimal place)
*/


WITH CTE AS (
SELECT
	chat_id,
	customer_id,
    chat_start_time AS current_chat_start_time,
    LAG(chat_end_time) OVER(PARTITION BY customer_id ORDER BY chat_start_time) AS last_chat_end_time,
    ROUND(TIMESTAMPDIFF(MINUTE, LAG(chat_end_time) OVER(PARTITION BY customer_id ORDER BY chat_start_time), chat_start_time)/60.0, 1) AS hours_since_last_chat
FROM chat_interactions
)
SELECT
*
FROM CTE
WHERE last_chat_end_time IS NOT NULL
AND hours_since_last_chat <= 24;

/*
Task 5: SLA Breach Analysis & Customer Tier Impact
Business Goal:

The leadership team has established a Service Level Agreement (SLA) target: queue wait times must be under 120 seconds (2 minutes). They want to see which customer account tiers are suffering the highest SLA breach rates to ensure high-value accounts aren't being neglected.

What to return:

Customer Account Tier (account_tier from customers).
Total chats handled.
Number of breached chats (wait_time_seconds > 120).
Breach rate percentage (breach_rate_pct), rounded to 1 decimal place.
Average wait time in seconds for that tier (avg_wait_seconds), rounded to whole seconds.

Order the results by breach rate percentage descending.
*/

WITH CTE AS (
SELECT
	c.account_tier,
    COUNT(i.chat_id) total_chats,
    SUM(CASE
		WHEN wait_time_seconds > 120 THEN 1
        ELSE 0 END) AS breached_chats, -- count chats that exceed SLA
	ROUND(AVG(wait_time_seconds), 0) AS avg_wait_time
FROM chat_interactions i
LEFT JOIN customers c
ON i.customer_id = c.customer_id
GROUP BY c.account_tier
)
SELECT
	*,
    ROUND(breached_chats/total_chats * 100, 1) AS breached_rate_pct
FROM CTE
ORDER BY breached_rate_pct DESC;

/*
Task 6: Hourly Volume Heatmap & Peak Hours (Final Analysis Task)
Business Goal:

Workforce management needs visibility into arrival volume throughout the day to plan shift staffing and reduce long queues.

What to return:

chat_hour (the hour of day from 0 to 23 when the chat arrived).
total_chats (total volume arriving during that hour).
avg_wait_seconds (average wait time for chats in that hour, rounded to whole number).
volume_category (a text label based on chat volume):
	'Peak' if total_chats > 55
	'Moderate' if total_chats >= 35
	'Low' if total_chats < 35

Ordering:
Order the results by chat_hour ascending (from 0 to 23).
*/

SELECT
	HOUR(chat_start_time) AS chat_hour,
    COUNT(chat_id) AS total_chats,
    ROUND(AVG(wait_time_seconds), 0) AS avg_wait_seconds,
    CASE
		WHEN COUNT(chat_id) > 55 THEN 'Peak'
        WHEN COUNT(chat_id) >= 35 THEN 'Moderate'
        ELSE 'Low' END AS volume_category
FROM chat_interactions
GROUP BY HOUR(chat_start_time)
ORDER BY HOUR(chat_start_time)
