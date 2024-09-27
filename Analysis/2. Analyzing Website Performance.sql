-- Set the search path to use the newly created schema
SET search_path TO mavenfuzzyfactory;

-------------------------------------------------- 2. ANALYZING WEBSITE PERFORMANCE --------------------------------------------------
-- Website content analysis is all about which pages have seen most number of users.
-- This helps in identifying where to focus on improving business.
-- Ex: A, B and C pages got 550. 1750 and 625 session respectively. Therefore, it makes most sense to improve page B as it has most landed 
-- users.
-- USE CASES: Identifying most common entry pages to your website-basically the first thing the user sees.
-- 		-- 	Futher understnading how those pages perform for business objectives.
-- 		-- Gives an introduction and first impression of your business.

-- Temporary table allows to create a dataset stored as a table for current running session in SQL

-- Look at the pages where most of the traffic leads to (not landing page)
SELECT 
	pageview_url,
	COUNT(DISTINCT website_pageview_id) AS pvs,
	ROUND(100*COUNT(DISTINCT website_pageview_id)/SUM(COUNT(DISTINCT website_pageview_id)) OVER()::decimal, 2) AS "% of total"
FROM website_pageviews
GROUP BY 1
ORDER BY pvs DESC;

-- It seems that '/products' page followed by '/the-original-mr-fuzzy' and '/home' would need most customisations later as
-- they are ones bulk of the volume leads to


-- ENTRY PAGE ANALYSIS: we want to look at the first page which is viewed during any website session


SELECT 
	pageview_url AS landing_page,
	COUNT(DISTINCT wp.website_session_id) AS sessions_hitting_this_lander,
	ROUND(100*COUNT(DISTINCT wp.website_session_id)/ SUM(COUNT(DISTINCT wp.website_session_id)) OVER()::decimal, 2) AS "% of total",
	DENSE_RANK() OVER(ORDER BY COUNT(DISTINCT wp.website_session_id) DESC) AS landing_page_rank
	
FROM (
	SELECT 
		website_session_id,
		MIN(website_pageview_id) AS min_pv_id
	FROM website_pageviews
	GROUP BY 1
) AS wp
LEFT JOIN website_pageviews AS wp1
ON wp.min_pv_id = wp1.website_pageview_id
GROUP BY 1
ORDER BY sessions_hitting_this_lander DESC;

-- Hence, majority of website sessions are either on '/home' or '/lander-2' page (top entry pages)
-- Homepage must be optimsed as best for great user experience. But to check if homepage is performing good, we need to define some
-- metrics to check its performance. Let us do that.



-- LANDING PAGE PERFORMANCE & TESTING

-- This helps in understanding the performance of our key landing pages and then testing it to improve the results.
-- Ex: Let us landing page A where 70% customers going on (30% abandoning) to next step where again 15% people move on to next (85% abandon)
-- And this keeps following. And at each step we check Conversion Rate to next page. In this way, we can check which page needs modification
-- to improve Convertion Rate (make it higher) by making new landing pages and performing A/B Testing on them to see if Converstion rates
-- or bounce rates can be improved


-- To do this, we will find first pageview for website_sessions and associate them with pageview after it (next page seen after landing page)
-- this would help in observing whether landing page for that website session lead to additional pages or not
-- Basically, sessions with no additonal pageviews are called bounce sessions, goal is to reduce them

-- Step 1: Find first website_pageview_id for a website_session

SELECT * FROM website_pageviews;

SELECT 
	website_session_id,
	MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews
GROUP BY 1;

CREATE TEMP TABLE first_pageviews AS                -- Creating a temporary table for above
SELECT 
	website_session_id,
	MIN(website_pageview_id) AS min_pageview_id
FROM website_pageviews
GROUP BY 1;


-- Step 2: Get the pageview url also (landing page) for each session using previous result

SELECT 
	first_pageviews.website_session_id,
	pageview_url AS landing_page
FROM first_pageviews
LEFT JOIN website_pageviews AS wp
ON first_pageviews.min_pageview_id = wp.website_pageview_id;


CREATE TEMP TABLE sessions_with_landing_page AS    -- Creating a temp table for above
SELECT 
	first_pageviews.website_session_id,
	pageview_url AS landing_page
FROM first_pageviews
LEFT JOIN website_pageviews AS wp
ON first_pageviews.min_pageview_id = wp.website_pageview_id;


-- Step 3: Counting pageviews for each session and landing page

SELECT
	sessions_with_landing_page.website_session_id,
	sessions_with_landing_page.landing_page,
	COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM sessions_with_landing_page
LEFT JOIN website_pageviews
	USING (website_session_id)
	
GROUP BY 1, 2;

-- Step 4: Next, look at all website_session, landing page where count of pageviews was only 1 (bounced sessions)

CREATE TEMP TABLE bounced_sessions_only AS 
SELECT
	sessions_with_landing_page.website_session_id,
	sessions_with_landing_page.landing_page,
	COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
FROM sessions_with_landing_page
LEFT JOIN website_pageviews
	USING (website_session_id)
	
GROUP BY 1, 2
HAVING COUNT(website_pageviews.website_pageview_id) = 1

-- Step 5: Return all website_session_id alongwith alongwith landing page and indicate bounced website_session_id too

SELECT 
	sessions_with_landing_page.landing_page,
	sessions_with_landing_page.website_session_id,
	bounced_sessions_only.website_session_id AS bounced_website_session_id
FROM sessions_with_landing_page
LEFT JOIN bounced_sessions_only
USING (website_session_id)
ORDER BY sessions_with_landing_page.website_session_id;

-- Check bouncing rate for each landing page using the above

SELECT 
	sessions_with_landing_page.landing_page,
	COUNT(DISTINCT sessions_with_landing_page.website_session_id) AS sessions,
	COUNT(DISTINCT bounced_sessions_only.website_session_id) AS bounced_sessions,
	ROUND(100*COUNT(DISTINCT bounced_sessions_only.website_session_id)/COUNT(DISTINCT sessions_with_landing_page.website_session_id)::decimal, 2) AS bounce_rate
FROM sessions_with_landing_page
LEFT JOIN bounced_sessions_only
USING (website_session_id)
GROUP BY 1
ORDER BY bounce_rate DESC;

-- '/lander-1' followed by '/lander-2', '/lander-3' and '/lander-4' have the highest bounce rates.
-- We will have to look deeper into these.

-- ASSIGNMENT (A/B test)
-- So, company has launched a new page called '/lander-1' against '/home' page, we need to check the bounce rates
-- for gsearch (utm source) and nonbrand (utm campaign) 
-- time frame: For this we need to find first instancce of /lander-1 and till July 28, 2012


SELECT * FROM website_pageviews;

-- Step 1: Finding first instance of '/lander-1', the date on which it was initiated.

SELECT MIN(created_at) AS first_created_at, MIN(website_pageview_id) AS first_pageview_id
FROM website_pageviews
WHERE pageview_url = '/lander-1';

-- Step 2: Selecting website_session_id and min_pageview_id as we are testing for landing page

CREATE TEMP TABLE first_test_pageviews AS
SELECT 
	wp.website_session_id,
	MIN(wp.website_pageview_id) AS min_pageview_id
FROM website_pageviews AS wp
INNER JOIN website_sessions AS ws
	ON wp.website_session_id = ws.website_session_id
	AND ws.created_at < '2012-07-28'                   -- Date when assignment was prescribed
	AND wp.website_pageview_id > 23504                 -- min_pageview_id where '/lander-1' was started
	AND utm_source = 'gsearch'           
	AND utm_campaign = 'nonbrand'
GROUP BY 1;

SELECT *
FROM first_test_pageviews;

-- Step 3: Get the landing page information for website_sessions_ids obtained above

CREATE TEMP TABLE nonbrand_test_sessions_w_landing_page AS
SELECT 
	first_test_pageviews.website_session_id,
	website_pageviews.pageview_url AS landing_page
FROM first_test_pageviews
LEFT JOIN website_pageviews
ON website_pageviews.website_pageview_id = first_test_pageviews.min_pageview_id
WHERE website_pageviews.pageview_url IN ('/home', '/lander-1');  -- we only care about these two pages

SELECT * FROM nonbrand_test_sessions_w_landing_page;

-- Step 4: Now, let have a look at coount of pageviews per website session and then limit it to just bounced sessions

CREATE TEMP TABLE nonbrand_test_bounced_sessions AS 
SELECT 
	nonbrand_test_sessions_w_landing_page.website_session_id,
	nonbrand_test_sessions_w_landing_page.landing_page,
	COUNT(website_pageviews.website_pageview_id) AS count_of_pages_viewed
	
FROM nonbrand_test_sessions_w_landing_page
	LEFT JOIN website_pageviews
	ON nonbrand_test_sessions_w_landing_page.website_session_id = website_pageviews.website_session_id

GROUP BY 1, 2
HAVING COUNT(website_pageviews.website_pageview_id) = 1;

SELECT * FROM nonbrand_test_bounced_sessions;


-- Step 5: Looking at all website_sessions which bounced

SELECT 
	nonbrand_test_sessions_w_landing_page.landing_page,
	nonbrand_test_sessions_w_landing_page.website_session_id,
	nonbrand_test_bounced_sessions.website_session_id AS bounced_website_session_id
FROM nonbrand_test_sessions_w_landing_page
	LEFT JOIN nonbrand_test_bounced_sessions
	USING (website_session_id)
ORDER BY nonbrand_test_sessions_w_landing_page.website_session_id;

-- Step 6: Give the bounce rate for both landing pages

SELECT 
	nonbrand_test_sessions_w_landing_page.landing_page,
	COUNT(DISTINCT nonbrand_test_sessions_w_landing_page.website_session_id) AS sessions,
	COUNT(DISTINCT nonbrand_test_bounced_sessions.website_session_id) AS bounced_sessions,
	ROUND(100*COUNT(DISTINCT nonbrand_test_bounced_sessions.website_session_id)/COUNT(DISTINCT nonbrand_test_sessions_w_landing_page.website_session_id)::decimal, 2) AS bounce_rate
FROM nonbrand_test_sessions_w_landing_page
	LEFT JOIN nonbrand_test_bounced_sessions
	USING (website_session_id)
GROUP BY 1
ORDER BY bounce_rate DESC;


-- Hence, number of sessions has increased as well as bounced sessions have decreased to overall 5%.





-- ASSIGNMENT: AS we confirmed earlier that the '/lander-1' is has improved bounce rate session comparing to '/home'.
-- All paid nonbrand traffic has been routed to '/lander-1'. From '2012-06-01'
-- REQUIREMNT: Confirm this and pull volumne of paid search nonbrand traffic weekly on 'home' and 'lander-1' to confirm this.
-- Additonally, pull overall paid search bounce rate trended weekly to make sure that lander has improved bounce rate. (uptill '2012-08-31')



-- Step 1: Get website_session_id with view_count of each landing_page_id for given timeframe and gsearch, nonbrand.

CREATE TEMP TABLE sessions_w_min_pv_id_and_view_count AS

SELECT ws.website_session_id,
	MIN(wp.website_pageview_id) AS first_pageview_id,
	COUNT(wp.website_pageview_id) AS count_pageviews
	
FROM website_sessions AS ws
LEFT JOIN website_pageviews AS wp
USING (website_session_id)

WHERE ws.created_at > '2012-06-01' AND ws.created_at < '2012-08-31'
AND ws.utm_source = 'gsearch'
AND ws.utm_campaign = 'nonbrand'

GROUP BY 1;

SELECT * FROM sessions_w_min_pv_id_and_view_count;

-- Step 2: Join the previous result to get landing page information (name) and time of its creation

CREATE TEMP TABLE sessions_w_lander_and_created_at AS
SELECT abc.website_session_id,
	abc.first_pageview_id,
	abc.count_pageviews,
	wp.pageview_url AS landing_page,
	wp.created_at AS sessions_created_at
FROM sessions_w_min_pv_id_and_view_count AS abc
LEFT JOIN website_pageviews AS wp
ON abc.first_pageview_id = wp.website_pageview_id;

SELECT * FROM sessions_w_lander_and_created_at;


-- Step 3: Return the total home sessions and lander session (on a weekly basis) alongwith bounce rate for home and lander (weekly)

SELECT EXTRACT(WEEK FROM sessions_created_at) AS week_number,
	MIN(DATE(sessions_created_at)) AS week_start_date,
	--COUNT(DISTINCT website_session_id) AS total_sessions,
	--COUNT(DISTINCT CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END) AS bounced_sessions,
	ROUND(100*COUNT(DISTINCT CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)::decimal, 2) AS bounce_rate,
	COUNT(DISTINCT CASE WHEN landing_page = '/home' THEN website_session_id ELSE NULL END) AS home_sessions,
	COUNT(DISTINCT CASE WHEN landing_page = '/lander-1' THEN website_session_id ELSE NULL END) AS lander_sessions
	
FROM sessions_w_lander_and_created_at
GROUP BY 1;

-- Clearly bounce rate has decreased from ~61% to ~50%, which means '/lander-1' is giving great results
















