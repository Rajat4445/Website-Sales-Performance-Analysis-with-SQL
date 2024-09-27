-- Set the search path to use the newly created schema
SET search_path TO mavenfuzzyfactory;

---------------------------------------------------- USER ANALYSIS ------------------------------------------------------------

------------------------------------------------- ANALYZE REPEAT BEHAVIOUR ----------------------------------------------------

-- This helps in understanding the user behaviour and identifying most valuable customers.
-- USE CASES: Analyzing repeat activity to see how often customers are coming back to visit your site.
		--	Understanding the channel they are using to come back and whether or not, you are paying for them again through paid channels
	    -- Using repeat visit activity to build a better understanding of the value of customer to optimise marketing channels

-- How this tracking is done?

-- Businesses use browser cookies to do this.
-- These cookies have unique IDs assocaited with them, which allows them to recognise the user when they come back.

SELECT * FROM website_sessions;

-- is_repeat_session indicates whether the customer is coming for the first time or not.

-- DATEDIFF(), allows to know the number of days between two days, AGE() is alternative for postgresql

-- ASSIGNMENT: Identifying Repeat Customers (for all years)   -------------------------------------

SELECT * FROM website_sessions;

-------------------------------- 2012 --------------------------------
WITH cte AS (
    -- Step 1: For each user, calculate the number of repeat sessions
    SELECT user_id, 
        SUM(is_repeat_session) AS repeat_sessions
    FROM website_sessions
    WHERE EXTRACT(YEAR FROM created_at) = 2012       -- 2012
    GROUP BY user_id
),
total_users AS (
    -- Step 2: Calculate the total number of distinct users
    SELECT COUNT(DISTINCT user_id) AS total_user_count
    FROM cte
)

-- Step 3: Calculate the number of users for each repeat session count and the proportion of total users
SELECT 
    cte.repeat_sessions, 
    COUNT(DISTINCT cte.user_id) AS users,
    ROUND((COUNT(DISTINCT cte.user_id)::numeric / total_users.total_user_count) * 100, 2) AS proportion_of_total_users_pct
FROM cte, total_users
GROUP BY cte.repeat_sessions, total_users.total_user_count
ORDER BY repeat_sessions;


---------------------------------- 2013 --------------------------------
WITH cte AS (
    -- Step 1: For each user, calculate the number of repeat sessions
    SELECT user_id, 
        SUM(is_repeat_session) AS repeat_sessions
    FROM website_sessions
    WHERE EXTRACT(YEAR FROM created_at) = 2013       -- 2013
    GROUP BY user_id
),
total_users AS (
    -- Step 2: Calculate the total number of distinct users
    SELECT COUNT(DISTINCT user_id) AS total_user_count
    FROM cte
)

-- Step 3: Calculate the number of users for each repeat session count and the proportion of total users
SELECT 
    cte.repeat_sessions, 
    COUNT(DISTINCT cte.user_id) AS users,
    ROUND((COUNT(DISTINCT cte.user_id)::numeric / total_users.total_user_count) * 100, 2) AS proportion_of_total_users_pct
FROM cte, total_users
GROUP BY cte.repeat_sessions, total_users.total_user_count
ORDER BY repeat_sessions;


---------------------------------- 2014 --------------------------------

WITH cte AS (
    -- Step 1: For each user, calculate the number of repeat sessions
    SELECT user_id, 
        SUM(is_repeat_session) AS repeat_sessions
    FROM website_sessions
    WHERE EXTRACT(YEAR FROM created_at) = 2014       -- 2014
    GROUP BY user_id
),
total_users AS (
    -- Step 2: Calculate the total number of distinct users
    SELECT COUNT(DISTINCT user_id) AS total_user_count
    FROM cte
)

-- Step 3: Calculate the number of users for each repeat session count and the proportion of total users
SELECT 
    cte.repeat_sessions, 
    COUNT(DISTINCT cte.user_id) AS users,
    ROUND((COUNT(DISTINCT cte.user_id)::numeric / total_users.total_user_count) * 100, 2) AS proportion_of_total_users_pct
FROM cte, total_users
GROUP BY cte.repeat_sessions, total_users.total_user_count
ORDER BY repeat_sessions;

--------------------------------------------------------------------------------------------------------------------------------
-- So, majority of customers do not repeat, but a fairly good number of customers visit once more.


-- ASSIGNMENT: Now, pull minimum, maximum and average time for the customers to come back (till 03 Nov, 2014)
-- from first to second sessions for customers who come back--------------

-- Step 1: Identify relevant new sessions
-- Step 2: Use the user_id values from step 1 to find repeat sessions those uesrs had
-- Step 3: Find the created_at times for first and second sessions
-- Step 4: Find the differences between first and second sessions at a user level
-- Step 5: Aggregate user level data to find the average, min and max

-- Step 1: Identify relevant new sessions

-- gives user_id, their first_session, its time, their repeated session and their time
-- basically it contains all information regarding all user_id and their respective repeated website session IDs

------------------------------------------------ 2012 ------------------------------------------------
CREATE TEMP TABLE sessions_w_repeats_for_time_diff_2012 AS    -- understand overall query
SELECT ns.user_id,
	ns.website_session_id AS new_session_id,
	ns.created_at AS new_session_created_at,
	ws.website_session_id AS repeat_session_id,
	ws.created_at AS repeat_session_created_at
FROM (
	SELECT user_id,
	website_session_id,
	created_at
	FROM website_sessions
	WHERE EXTRACT(YEAR FROM created_at) = 2012
	AND is_repeat_session = 0
) AS ns
LEFT JOIN website_sessions AS ws
ON ns.user_id = ws.user_id
AND ws.is_repeat_session = 1   -- was repeat session (redundant but good to illustrate)
AND ws.website_session_id > ns.website_session_id      -- session was later than new session
AND EXTRACT(YEAR FROM ws.created_at) = 2012;    -- date of assignment


-- Step 2: Finding user_id with difference between its first session and first repeated session

CREATE TEMP TABLE users_first_to_second_2012 AS 
SELECT user_id,
	second_session_created_at::date - new_session_created_at::date AS days_first_to_second_session
FROM (
	SELECT user_id,               -- Intuitive if you understand step 1 query
		new_session_id,
		new_session_created_at,
		MIN(repeat_session_id) AS second_session_id,
		MIN(repeat_session_created_at) AS second_session_created_at
	FROM sessions_w_repeats_for_time_diff_2012
	WHERE repeat_session_id IS NOT NULL
	GROUP BY 1, 2, 3
) AS first_second

-- Step 3: Summarising final output

SELECT ROUND(AVG(days_first_to_second_session)) AS avg_days_first_to_second,
	MIN(days_first_to_second_session) AS min_days_first_to_second,
	MAX(days_first_to_second_session) AS max_days_first_to_second
FROM users_first_to_second_2012;

------------------------------------------------ 2013 ------------------------------------------------
CREATE TEMP TABLE sessions_w_repeats_for_time_diff_2013 AS    -- understand overall query
SELECT ns.user_id,
	ns.website_session_id AS new_session_id,
	ns.created_at AS new_session_created_at,
	ws.website_session_id AS repeat_session_id,
	ws.created_at AS repeat_session_created_at
FROM (
	SELECT user_id,
	website_session_id,
	created_at
	FROM website_sessions
	WHERE EXTRACT(YEAR FROM created_at) = 2013
	AND is_repeat_session = 0
) AS ns
LEFT JOIN website_sessions AS ws
ON ns.user_id = ws.user_id
AND ws.is_repeat_session = 1   -- was repeat session (redundant but good to illustrate)
AND ws.website_session_id > ns.website_session_id      -- session was later than new session
AND EXTRACT(YEAR FROM ws.created_at) = 2013;    -- date of assignment


-- Step 2: Finding user_id with difference between its first session and first repeated session

CREATE TEMP TABLE users_first_to_second_2013 AS 
SELECT user_id,
	second_session_created_at::date - new_session_created_at::date AS days_first_to_second_session
FROM (
	SELECT user_id,               -- Intuitive if you understand step 1 query
		new_session_id,
		new_session_created_at,
		MIN(repeat_session_id) AS second_session_id,
		MIN(repeat_session_created_at) AS second_session_created_at
	FROM sessions_w_repeats_for_time_diff_2013
	WHERE repeat_session_id IS NOT NULL
	GROUP BY 1, 2, 3
) AS first_second

-- Step 3: Summarising final output

SELECT ROUND(AVG(days_first_to_second_session)) AS avg_days_first_to_second,
	MIN(days_first_to_second_session) AS min_days_first_to_second,
	MAX(days_first_to_second_session) AS max_days_first_to_second
FROM users_first_to_second_2013;



------------------------------------------------ 2014 ------------------------------------------------
CREATE TEMP TABLE sessions_w_repeats_for_time_diff_2014 AS    -- understand overall query
SELECT ns.user_id,
	ns.website_session_id AS new_session_id,
	ns.created_at AS new_session_created_at,
	ws.website_session_id AS repeat_session_id,
	ws.created_at AS repeat_session_created_at
FROM (
	SELECT user_id,
	website_session_id,
	created_at
	FROM website_sessions
	WHERE EXTRACT(YEAR FROM created_at) = 2014
	AND is_repeat_session = 0
) AS ns
LEFT JOIN website_sessions AS ws
ON ns.user_id = ws.user_id
AND ws.is_repeat_session = 1   -- was repeat session (redundant but good to illustrate)
AND ws.website_session_id > ns.website_session_id      -- session was later than new session
AND EXTRACT(YEAR FROM ws.created_at) = 2014;    -- date of assignment


-- Step 2: Finding user_id with difference between its first session and first repeated session

CREATE TEMP TABLE users_first_to_second_2014 AS 
SELECT user_id,
	second_session_created_at::date - new_session_created_at::date AS days_first_to_second_session
FROM (
	SELECT user_id,               -- Intuitive if you understand step 1 query
		new_session_id,
		new_session_created_at,
		MIN(repeat_session_id) AS second_session_id,
		MIN(repeat_session_created_at) AS second_session_created_at
	FROM sessions_w_repeats_for_time_diff_2014
	WHERE repeat_session_id IS NOT NULL
	GROUP BY 1, 2, 3
) AS first_second

-- Step 3: Summarising final output

SELECT ROUND(AVG(days_first_to_second_session)) AS avg_days_first_to_second,
	MIN(days_first_to_second_session) AS min_days_first_to_second,
	MAX(days_first_to_second_session) AS max_days_first_to_second
FROM users_first_to_second_2014;



-- On an average, a person repeats coming to website after a month. Maximum is around 69 days

-- Now, we have been asked to look at the new customer and repeated customers via channel of arrival

-- ASSIGNMENT: Analyzing repeat Customers Channel Behaviour, which channels do the customers coming from

-- Give all the session report, self-explanatory

------------------------------------------------------ 2012 -----------------------------------------------------------
SELECT utm_source,
	utm_campaign,
	http_referer,
	COUNT(CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions,
	COUNT(CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_sessions
FROM website_sessions
WHERE EXTRACT(YEAR FROM created_at) = 2012  -- timeframe
GROUP BY 1, 2, 3
ORDER BY repeat_sessions DESC;

-- Let us make the results more interpretable as we have too many categories

SELECT CASE
			WHEN utm_source IS NULL AND http_referer IN ('https://www.bsearch.com', 'https://www.gsearch.com') THEN 'organic_search'
			WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
			WHEN utm_campaign = 'brand' THEN 'paid_brand'
			WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
			WHEN utm_source = 'socialbook' THEN 'paid_social'
		END AS channel_group,
		COUNT(CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions,
	COUNT(CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_sessions
FROM website_sessions
WHERE EXTRACT(YEAR FROM created_at) = 2012  -- timeframe
GROUP BY 1
ORDER BY repeat_sessions DESC;

------------------------------------------------------ 2013 -----------------------------------------------------------
SELECT utm_source,
	utm_campaign,
	http_referer,
	COUNT(CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions,
	COUNT(CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_sessions
FROM website_sessions
WHERE EXTRACT(YEAR FROM created_at) = 2013  -- timeframe
GROUP BY 1, 2, 3
ORDER BY repeat_sessions DESC;

-- Let us make the results more interpretable as we have too many categories

SELECT CASE
			WHEN utm_source IS NULL AND http_referer IN ('https://www.bsearch.com', 'https://www.gsearch.com') THEN 'organic_search'
			WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
			WHEN utm_campaign = 'brand' THEN 'paid_brand'
			WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
			WHEN utm_source = 'socialbook' THEN 'paid_social'
		END AS channel_group,
		COUNT(CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions,
	COUNT(CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_sessions
FROM website_sessions
WHERE EXTRACT(YEAR FROM created_at) = 2013  -- timeframe
GROUP BY 1
ORDER BY repeat_sessions DESC;

------------------------------------------------------ 2014 -----------------------------------------------------------
SELECT utm_source,
	utm_campaign,
	http_referer,
	COUNT(CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions,
	COUNT(CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_sessions
FROM website_sessions
WHERE EXTRACT(YEAR FROM created_at) = 2014  -- timeframe
GROUP BY 1, 2, 3
ORDER BY repeat_sessions DESC;

-- Let us make the results more interpretable as we have too many categories

SELECT CASE
			WHEN utm_source IS NULL AND http_referer IN ('https://www.bsearch.com', 'https://www.gsearch.com') THEN 'organic_search'
			WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
			WHEN utm_campaign = 'brand' THEN 'paid_brand'
			WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
			WHEN utm_source = 'socialbook' THEN 'paid_social'
		END AS channel_group,
		COUNT(CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_sessions,
	COUNT(CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_sessions
FROM website_sessions
WHERE EXTRACT(YEAR FROM created_at) = 2014  -- timeframe
GROUP BY 1
ORDER BY repeat_sessions DESC;


-- Hence, there are maximum repeated sessions from organic_search or direct_type_in
-- Also, paid_brand is bringing good repeat_sessions which is a good thing.
-- As paid_nonbrand and paid_social brings new_sessions but no repeated sessions, it might be a problem.



-- ASSIGNMENT: Analyze coversion rate and revenue per session for repeat sessions and new sessions

SELECT * FROM website_sessions;
SELECT * FROM orders;

---------------------------------------------------- 2012 -----------------------------------------------------------
SELECT is_repeat_session,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
	COUNT(DISTINCT order_id) AS orders,
	SUM(price_usd) AS total_revenue,
	ROUND(100*COUNT(DISTINCT order_id)/COUNT(DISTINCT ws.website_session_id)::decimal, 2) AS conv_rate,     -- Conversion Rate 
	ROUND(SUM(price_usd)/COUNT(DISTINCT ws.website_session_id), 2) AS AOV -- Revenue per session
FROM website_sessions AS ws

	LEFT JOIN orders
		USING(website_session_id)
WHERE EXTRACT(YEAR FROM ws.created_at) = 2012
GROUP BY 1;


---------------------------------------------------- 2013 -----------------------------------------------------------
SELECT is_repeat_session,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
	COUNT(DISTINCT order_id) AS orders,
	SUM(price_usd) AS total_revenue,
	ROUND(100*COUNT(DISTINCT order_id)/COUNT(DISTINCT ws.website_session_id)::decimal, 2) AS conv_rate,     -- Conversion Rate 
	ROUND(SUM(price_usd)/COUNT(DISTINCT ws.website_session_id), 2) AS AOV -- Revenue per session
FROM website_sessions AS ws

	LEFT JOIN orders
		USING(website_session_id)
WHERE EXTRACT(YEAR FROM ws.created_at) = 2013
GROUP BY 1;

---------------------------------------------------- 2014 -----------------------------------------------------------
SELECT is_repeat_session,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
	COUNT(DISTINCT order_id) AS orders,
	SUM(price_usd) AS total_revenue,
	ROUND(100*COUNT(DISTINCT order_id)/COUNT(DISTINCT ws.website_session_id)::decimal, 2) AS conv_rate,     -- Conversion Rate 
	ROUND(SUM(price_usd)/COUNT(DISTINCT ws.website_session_id), 2) AS AOV -- Revenue per session
FROM website_sessions AS ws

	LEFT JOIN orders
		USING(website_session_id)
WHERE EXTRACT(YEAR FROM ws.created_at) = 2014
GROUP BY 1;



-- Repeated sessions have a little higher conversion rate than normal sessions. But is it statistically significant.
-- WE can perform hypothesis testing for this.



		





























































































