-- Set the search path to use the newly created schema
SET search_path TO mavenfuzzyfactory;

--------------------------------- 2. ANALYZING SEASONALITY & BUSINESS PATTERNS --------------------------------------------------
-- It is about generating insights to help in maximising efficiency and anticipate future trends
-- USE CASES: Day Parting Analysis: To understand how much support staff is needed during different times of day.
-- Helpful in identifying upcoming spikes or slowdowns in demand.

-- 2012, was a great year, we haave been asked to show the monthly and weekly sales for 2012

SELECT * FROM website_sessions;
SELECT * FROM orders;

-- Below query gives monthly sessions and orders for year 2012
SELECT EXTRACT(YEAR FROM ws.created_at) AS yr,
	EXTRACT(MONTH FROM ws.created_at) AS mon,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
	COUNT(DISTINCT o.order_id) AS orders
FROM website_sessions AS ws
LEFT JOIN orders AS o
USING (website_session_id)
WHERE ws.created_at < '2013-01-01'
GROUP BY 1, 2


-- Clearly, the number of sessions increase by month and maximises in November and then decrease.
-- Highest: November, Lowest: March
-- Orders follow a similar pattern, Highest: November, Lowest: March

-- 2013

SELECT EXTRACT(YEAR FROM ws.created_at) AS yr,
	EXTRACT(MONTH FROM ws.created_at) AS mon,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
	COUNT(DISTINCT o.order_id) AS orders
FROM website_sessions AS ws
LEFT JOIN orders AS o
USING (website_session_id)
WHERE ws.created_at BETWEEN '2013-01-01' AND '2013-12-31'
GROUP BY 1, 2


-- 2014
SELECT EXTRACT(YEAR FROM ws.created_at) AS yr,
	EXTRACT(MONTH FROM ws.created_at) AS mon,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
	COUNT(DISTINCT o.order_id) AS orders
FROM website_sessions AS ws
LEFT JOIN orders AS o
USING (website_session_id)
WHERE ws.created_at BETWEEN '2014-01-01' AND '2014-12-31'
GROUP BY 1, 2



-- Since, we have only 3 months data for year 2015, we are not touching it




SELECT ROUND(CORR(sessions, orders)::decimal, 2) AS corr_sessions_orders
FROM (
    SELECT 
        EXTRACT(YEAR FROM ws.created_at) AS yr,
        EXTRACT(MONTH FROM ws.created_at) AS mon,
        COUNT(DISTINCT ws.website_session_id) AS sessions,
        COUNT(DISTINCT o.order_id) AS orders
    FROM website_sessions AS ws
    LEFT JOIN orders AS o USING (website_session_id)
    WHERE ws.created_at < '2013-01-01'
    GROUP BY 1, 2
) AS sub;

-- There is a high correlation between sessions and orders (higher sessions imply higher orders)

-- Below query gives weekly sessions and orders for year 2012

SELECT EXTRACT(WEEK FROM ws.created_at) AS wk_number,
	MIN(DATE(ws.created_at)) AS week_start,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
	COUNT(DISTINCT o.order_id) AS orders
FROM website_sessions AS ws
LEFT JOIN orders AS o
USING (website_session_id)
WHERE ws.created_at < '2013-01-01'
GROUP BY 1
ORDER BY wk_number 

-- Similar to monthly trend in sessions and orders, weekly trend has similar pattern which is obvious as weekly trends is just a 
-- more granular version of monthly trends.

-- 46-49, week has highest number of sessions, similar is true for orders.

-- Since, this data is based out of US, this explains spike in sessions and orders in November (between 47-49 week) as 
-- these are holiday months with Black Friday and Cyber Monday Sales.
-- This analysis would help company to be ready for the next year around these months (or weeks)
	

-- ASSIGNMENT: Company is planning to add a live chat support system to improve customer experience.
-- Analyze average website session volume by hour of day and day of week. (for year 2012)
-- Focus on holiday time period, i.e., between Sep 15, 2012 and Nov 15, 2012
-- Give the output as a grid between hour_of_day (rows) and day_of_week (column)

CREATE TEMP TABLE daily_hourly_sessions AS 
SELECT DATE(created_at),
	EXTRACT(DOW FROM created_at) AS weekday,    -- 0 = Sunday, 					2012
	EXTRACT(HOUR FROM created_at) AS hour_of_day,
	COUNT(DISTINCT website_session_id) AS website_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'       -- September to November
GROUP BY 1, 2, 3;

SELECT * FROM daily_hourly_sessions;

SELECT hour_of_day,
--	ROUND(AVG(website_sessions), 1) AS avg_sessions,
	ROUND(AVG(CASE WHEN weekday = 1 THEN website_sessions ELSE NULL END), 1) AS mon,
	ROUND(AVG(CASE WHEN weekday = 2 THEN website_sessions ELSE NULL END), 1) AS tues,
	ROUND(AVG(CASE WHEN weekday = 3 THEN website_sessions ELSE NULL END), 1) AS wed,
	ROUND(AVG(CASE WHEN weekday = 4 THEN website_sessions ELSE NULL END), 1) AS thurs,
	ROUND(AVG(CASE WHEN weekday = 5 THEN website_sessions ELSE NULL END), 1) AS fri,
	ROUND(AVG(CASE WHEN weekday = 6 THEN website_sessions ELSE NULL END), 1) AS sat,
	ROUND(AVG(CASE WHEN weekday = 0 THEN website_sessions ELSE NULL END), 1) AS sun
FROM daily_hourly_sessions
GROUP BY 1
ORDER BY hour_of_day


-- Clearly, there is a high avg session from 8 (hour of day, around 8 AM) to 17 (hour of day, around 5 PM) from Monday to Friday
-- It seems ~10 sessions per hour per employee is a reasonable number to be staffed.
-- Thus, it is advisable to assign 2 staff members from 8AM to 5PM from Monday to Friday
-- Also, on other days (excluding above time frame), one staff member is enough (including weekends)


-- 2013

CREATE TEMP TABLE daily_hourly_sessions_2013 AS 
SELECT DATE(created_at),
	EXTRACT(DOW FROM created_at) AS weekday,    -- 0 = Sunday
	EXTRACT(HOUR FROM created_at) AS hour_of_day,
	COUNT(DISTINCT website_session_id) AS website_sessions
FROM website_sessions
WHERE created_at BETWEEN '2013-09-01' AND '2013-12-31'       -- September to December for 2013
GROUP BY 1, 2, 3;

SELECT * FROM daily_hourly_sessions;

SELECT hour_of_day,
--	ROUND(AVG(website_sessions), 1) AS avg_sessions,
	ROUND(AVG(CASE WHEN weekday = 1 THEN website_sessions ELSE NULL END), 1) AS mon,
	ROUND(AVG(CASE WHEN weekday = 2 THEN website_sessions ELSE NULL END), 1) AS tues,
	ROUND(AVG(CASE WHEN weekday = 3 THEN website_sessions ELSE NULL END), 1) AS wed,
	ROUND(AVG(CASE WHEN weekday = 4 THEN website_sessions ELSE NULL END), 1) AS thurs,
	ROUND(AVG(CASE WHEN weekday = 5 THEN website_sessions ELSE NULL END), 1) AS fri,
	ROUND(AVG(CASE WHEN weekday = 6 THEN website_sessions ELSE NULL END), 1) AS sat,
	ROUND(AVG(CASE WHEN weekday = 0 THEN website_sessions ELSE NULL END), 1) AS sun
FROM daily_hourly_sessions_2013
GROUP BY 1
ORDER BY hour_of_day


-- 2014


CREATE TEMP TABLE daily_hourly_sessions_2014 AS 
SELECT DATE(created_at),
	EXTRACT(DOW FROM created_at) AS weekday,    -- 0 = Sunday
	EXTRACT(HOUR FROM created_at) AS hour_of_day,
	COUNT(DISTINCT website_session_id) AS website_sessions
FROM website_sessions
WHERE created_at BETWEEN '2014-09-01' AND '2014-12-31'       -- September to December for 2014
GROUP BY 1, 2, 3;

SELECT * FROM daily_hourly_sessions;

SELECT hour_of_day,
--	ROUND(AVG(website_sessions), 1) AS avg_sessions,
	ROUND(AVG(CASE WHEN weekday = 1 THEN website_sessions ELSE NULL END), 1) AS mon,
	ROUND(AVG(CASE WHEN weekday = 2 THEN website_sessions ELSE NULL END), 1) AS tues,
	ROUND(AVG(CASE WHEN weekday = 3 THEN website_sessions ELSE NULL END), 1) AS wed,
	ROUND(AVG(CASE WHEN weekday = 4 THEN website_sessions ELSE NULL END), 1) AS thurs,
	ROUND(AVG(CASE WHEN weekday = 5 THEN website_sessions ELSE NULL END), 1) AS fri,
	ROUND(AVG(CASE WHEN weekday = 6 THEN website_sessions ELSE NULL END), 1) AS sat,
	ROUND(AVG(CASE WHEN weekday = 0 THEN website_sessions ELSE NULL END), 1) AS sun
FROM daily_hourly_sessions_2014
GROUP BY 1
ORDER BY hour_of_day



-- This has been repeated for over years to confirm the ideal time for higher support staff.

-- Advanced Analysis: One idea can be to replace avg website session with Conversion rate to analyse what time of day has highest CVR

















