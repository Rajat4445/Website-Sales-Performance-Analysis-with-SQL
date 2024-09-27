-- Ecommerce Database Analyst in Maven Fuzzy Factory, an online retailer which has just launched their first product.
-- Will be analysing and optimising marketing channels, measure and test website conversion performance and use
-- data to understnad the impact of new product launches.



-- Set the search path to use the newly created schema
SET search_path TO mavenfuzzyfactory;



---------------------------------------	 1. ANALYZING TRAFFIC SOURCES ----------------------------------------	

-- We will understand where our customers are coming from and which channel are driving the highest quality traffic
-- Channels include Email, Social Media, Search, Direct traffic
-- Metric Conversion Rate (CVR): Indicates what percentage of sessions which lead to sales or the revenue
-- Use Case: Analyzing search data and shifting budget towards the engines, campaigns or keywords driving strongest CVR
-- 			 Comparing user behaviour patterns across traffic sources to inform creative and messaging strategy
--           Identifying opportunites to eliminate wasted spend or scale high-converting traffic

SELECT * FROM website_sessions WHERE website_session_id = 1059;
-- utm_source and utm_campaign are using for marketing (used by Google Analytics)

SELECT * FROM website_pageviews WHERE website_session_id = 1059;
-- shows what webpages a session_id has landed

SELECT * FROM orders WHERE website_session_id = 1059;
-- shows order in the sesion 1059, here cogs_usd is "Cost of Goods sold" in USD

-- Let us understand PAID MARKETING CAMPAIGNS: UTM TRACING PARAMETERS better
-- Business rum paid marketing campaigns and are obsessed over performance and measure everything, how much they spend, 
-- how well traffic converts sales etc
-- Hence, Paid traffic is tagged with a UTM which is appended at the end of a URL and helps us in tieing a website
-- activity back to specific traffic sources and campaigns
-- ex: ww.abs.com?utm_scource=traffic_source&utm_campaign=campaignName (look at utm_source and utm_campaign)

SELECT DISTINCT utm_source, utm_campaign
FROM website_sessions;

-- So, we are going to use utm parameter in database to identify paid website sessions then
-- From website session data, we will link to our order data to understand how much revenue our paid campaigns drive

												
SELECT 
    COALESCE(utm_source, 'Direct') AS source, 
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    ROUND(100.0 * COUNT(DISTINCT ws.website_session_id) / SUM(COUNT(DISTINCT ws.website_session_id)) OVER (), 2) AS "% of total (sessions)",
	COUNT(DISTINCT o.order_id) AS orders,
	ROUND(100.0 * COUNT(DISTINCT o.order_id)/ SUM(COUNT(DISTINCT o.order_id)) OVER(), 2) AS "% of total (orders)",
	ROUND(100.0*COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id)::decimal, 2) AS "session_to_order_cvr (%)"
FROM 
    website_sessions AS ws
	LEFT JOIN orders AS o
		USING (website_session_id)
GROUP BY 
    utm_source
ORDER BY 
    sessions DESC;
	
	
-- Where are bulk of website sessions are coming from? Give a breakdown by utm_source, utm_campaign and refering domain before 'April 12, 2012'?
-- Also, look at the conversion rates of sessions, if lower than 4%, we might have to reduce bids.

SELECT
	utm_source,
	utm_campaign, 
	http_referer,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
	ROUND(100.0*COUNT(DISTINCT ws.website_session_id)/ SUM(COUNT(DISTINCT ws.website_session_id)) OVER(), 2) AS "% of total (sessions)",
	COUNT(DISTINCT o.order_id) AS orders,
	ROUND(100.0*COUNT(DISTINCT o.order_id)/ SUM(COUNT(DISTINCT o.order_id)) OVER(), 2) AS "% of total (orders)",
	ROUND(100*COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id)::decimal, 4) AS "session_to_order_cvr (%)"
	
FROM website_sessions AS ws
	LEFT JOIN orders AS o
	USING (website_session_id)
WHERE ws.created_at < '2012-04-12'
GROUP BY 1, 2, 3
ORDER BY sessions DESC;
							
-- 'gsearch' is utm_source where highest bulk sessions(roughly 97%) are coming from.
-- Let us look at sessions, where utm_source = 'gsearch' and utm_campign = 'non_brand' as of '14-04-2012'

SELECT 
	COUNT(DISTINCT ws.website_session_id) AS sessions,
	COUNT(DISTINCT o.order_id) AS orders,
	ROUND(100*COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id)::decimal, 3) AS "session_to_order_cvr(%)"
	FROM website_sessions AS ws
		LEFT JOIN orders AS o
		ON ws.website_session_id = o.website_session_id 
		WHERE ws.created_at < '2012-04-14' AND utm_source = 'gsearch' AND utm_campaign = 'nonbrand';
		
-- As conversion rate is lower than 4%, it seems a little bid optimization is required


------------------------------------------------------- 1.1 BID OPTIMIZATION ------------------------------------------------------
	
-- Analyzing for bid optimisation is about understnad the value of various segments of paid traffic to optimise marketing budget
-- ex: there are segment A, B, C with 10%, 3% and 17% CVR, so you would like to bid up A and C, bid down C.

-- USE CASES: -- Using CVR and revenue per click analyses and figures out how much one should spend per click to aquire new customers
-- 			-- Understanding how website performs for various subsegments of traddic (i.e., mobile vs desktop) to optimise within channels
-- 			-- Analyzing impact of bid changes have on ranking in auctions and volume of customers drive to our website

SELECT 
	EXTRACT(YEAR FROM created_at) AS year,
	EXTRACT(WEEK FROM created_at) AS week,
	MIN(DATE(created_at)) AS week_start,
	COUNT(DISTINCT website_session_id) AS sessions

FROM website_sessions
GROUP BY 1, 2;


-- So, based on Conversion Rate Analysis, company bid down gsearch nonbrand on 2012-04-15
-- Pull gsearch nonbrand trended session volumne by week, to see if bid changes have caused volume to drop at all (as of May 10, 2012)?


SELECT
	EXTRACT(YEAR FROM created_at) AS yr,
	EXTRACT(WEEK FROM created_at) AS week_number,
	MIN(DATE(created_at)) AS week_start,
	COUNT(DISTINCT website_session_id) AS sessions
FROM website_sessions
WHERE utm_source = 'gsearch' AND utm_campaign = 'nonbrand' AND created_at < '2012-05-10'
GROUP BY 1, 2
ORDER BY week_number ASC;

-- So, to check this, we look at everything before '2012-05-10' to have an idea of how many sessions
-- we were having before bid down. As bid was brought down on '2012-04-15', it can be observed that on week 16, sessions have decreased
-- significantly and over further weeks as of May 10, 2012, sessions have decreased by roughly 66 % comparing to 2 months back
-- Hence, bid down has lead to a significant decrease in the volume of the sessions

-- CONCLUSION: gsearch nonbrand seems to be fairly sesnitive to bid changes but we want maximum volumne without having to spend more
--				than what we can afford.
-- Further, think how we could make campaigns more efficient to increase the volume.

-- To solve this let us look into CVR from session to order by device type, so if desktop performance (CVR) is better than mobile,
-- then it would make more sense to bid up for desktop to increase the volume (for gsearch nonbrand)
-- because right now company bids same for mobile and same for desktop, it would make more sense to bid down for one with lower CVR.


SELECT
	ws.device_type,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
	ROUND(100.0*COUNT(DISTINCT ws.website_session_id)/ SUM(COUNT(DISTINCT ws.website_session_id)) OVER(), 2) AS "% of total (sessions)",
	COUNT(DISTINCT o.order_id) AS orders,
	ROUND(100.0*COUNT(DISTINCT o.order_id)/ SUM(COUNT(DISTINCT o.order_id)) OVER(), 2) AS "% of total (orders)",
	ROUND(100*COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id)::decimal, 4) AS "session_to_order_cvr (%)"
	
FROM website_sessions AS ws
	LEFT JOIN orders AS o
	USING (website_session_id)
WHERE ws.created_at < '2012-05-11' AND utm_source = 'gsearch' AND utm_campaign = 'nonbrand'
GROUP BY 1
ORDER BY sessions DESC;

-- Majority of sessions (roughly 60%) come from desktop and surprisingly 86% of orders are from desktop, only 15% from mobile
-- Next, based on this, company is going to increase bids for desktop and decreasing for mobile to boost the overall sales

-- NEXT STEPS: As the bids get changed, we need to look into changes in CVR and continue looking for ways to optimse campaigns

-- So, bids for gsearch nonbrand were made up on '2012-05-19', pull weekly trends for both mobile and dasktop, to see impact on volume
-- using '2012-04-15' as baseline (show results after this date) before the date '2012-06-09' (date of reporting to marketing director)

WITH cte AS (
	
	SELECT
	EXTRACT(YEAR FROM created_at) AS yr,
	EXTRACT(WEEK FROM created_at) AS week_number,
	MIN(DATE(created_at)) AS start_of_week,
	SUM(CASE WHEN device_type = 'desktop' THEN 1 ELSE 0 END) AS dtop_sessions,
	SUM(CASE WHEN device_type = 'mobile' THEN 1 ELSE 0 END) AS mob_sessions,
	COUNT(DISTINCT website_session_id) AS total_sessions,
	ROUND(100.0*SUM(CASE WHEN device_type = 'desktop' THEN 1 ELSE 0 END)/COUNT(DISTINCT website_session_id)::decimal, 4) AS "% of total(desktop)",
	ROUND(100.0*SUM(CASE WHEN device_type = 'mobile' THEN 1 ELSE 0 END)/COUNT(DISTINCT website_session_id)::decimal, 4) AS "% of total(mobile)"
	
FROM website_sessions 
WHERE utm_source = 'gsearch' AND utm_campaign = 'nonbrand' AND (created_at BETWEEN '2012-04-15' AND '2012-06-09')
GROUP BY 1, 2

)

SELECT * FROM cte;


-- Clearly, desktop sessions have increased 60% in week 17 to roughly 80% in week 23
-- Bid changes has led to increase in sessions to the website.

-- Earlier, we observed that 86% of orders were delivered by desktop sessions, while only 14% by mobile.
-- Let us look if these sessions increment also led to orders increase

-- Let us use the results from the previous table but first save it as a cte

SELECT
	ws.device_type,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
	ROUND(100.0*COUNT(DISTINCT ws.website_session_id)/ SUM(COUNT(DISTINCT ws.website_session_id)) OVER(), 2) AS "% of total (sessions)",
	COUNT(DISTINCT o.order_id) AS orders,
	ROUND(100.0*COUNT(DISTINCT o.order_id)/ SUM(COUNT(DISTINCT o.order_id)) OVER(), 2) AS "% of total (orders)",
	ROUND(100*COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id)::decimal, 4) AS "session_to_order_cvr (%)"
	
FROM website_sessions AS ws
	LEFT JOIN orders AS o
	USING (website_session_id)
WHERE (ws.created_at BETWEEN '2012-05-19' AND '2012-12-31') AND utm_source = 'gsearch' AND utm_campaign = 'nonbrand'
GROUP BY 1
ORDER BY sessions DESC;

-- Looking at desktop vs mobile after bid optimisation on 19 May 2012 and to the end of year, we observed that
-- from previous 86% of orders, now 92% orders are from Desktop with imrpoved CVR from 3.73% to 4.89%.
-- Thus, Bid optimsation was impactful.




SELECT * FROM website_sessions


SELECT
	ws.device_type,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
	ROUND(100.0*COUNT(DISTINCT ws.website_session_id)/ SUM(COUNT(DISTINCT ws.website_session_id)) OVER(), 2) AS "% of total (sessions)",
	COUNT(DISTINCT o.order_id) AS orders,
	ROUND(100.0*COUNT(DISTINCT o.order_id)/ SUM(COUNT(DISTINCT o.order_id)) OVER(), 2) AS "% of total (orders)",
	ROUND(100*COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id)::decimal, 4) AS "session_to_order_cvr (%)"
	
FROM website_sessions AS ws
	LEFT JOIN orders AS o
	USING (website_session_id)
WHERE (ws.created_at BETWEEN '2012-04-15' AND '2012-06-09') AND utm_source = 'gsearch' AND utm_campaign = 'nonbrand'
GROUP BY 1
ORDER BY sessions DESC;









	







