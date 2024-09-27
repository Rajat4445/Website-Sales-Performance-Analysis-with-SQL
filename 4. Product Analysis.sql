-- Set the search path to use the newly created schema
SET search_path TO mavenfuzzyfactory;

------------------------------------- PRODUCT SALES ANALYSIS -------------------------------------------
-- Helps in understanding how each product contributes to overall business and how product launches impact overall portfolio
-- USE CASES: Analyzing Sales and revenue by product
-- 			  Monitoring the impact of adding a new product to your product portfolio
--			  Watching product sales trends to udnerstand the overall health of your business

-- Key Business Terms: Orders: Number of Orders placed by Customers (COUNT(order_id))
--                     Revenue: Money the business brings in from orders (SUM(price_usd))
--					   Margin: Revenue less the cost of good sold     (SUM(price_usd - cogs_usd))  (SP-CP)
--					   AOV: Average Revenue generated per order       (AVG(price_usd)) OR (SUM(price_usd))/(COUNT(order_id))

-- Margin is more important than revenue, as if the revenue is high but the margin is low, those categoreis are less profitable

SELECT * FROM orders;

-- Query all products alongwith their total orders, revenue, margin and AOV on yearly basis

-- 2012

WITH cte AS (
SELECT primary_product_id,
	COUNT(order_id) AS orders,
	SUM(price_usd) AS revenue,
	SUM(price_usd - cogs_usd) AS margin,
	ROUND(AVG(price_usd), 2) AS aov
FROM orders
WHERE EXTRACT(YEAR FROM created_at) = 2012
GROUP BY 1
ORDER BY orders DESC)


SELECT product_name, orders, revenue, margin,ROUND(margin/revenue*100) AS "margin(%)", aov        -- Fetching product name from products table
FROM cte
LEFT JOIN products
ON cte.primary_product_id = products.product_id;

-- 2013

WITH cte AS (
SELECT primary_product_id,
	COUNT(order_id) AS orders,
	SUM(price_usd) AS revenue,
	SUM(price_usd - cogs_usd) AS margin,
	ROUND(AVG(price_usd), 2) AS aov
FROM orders
WHERE EXTRACT(YEAR FROM created_at) = 2013
GROUP BY 1
ORDER BY orders DESC)


SELECT product_name, orders, revenue, margin, ROUND(margin/revenue*100) AS "margin(%)", aov                -- Fetching product name from products table
FROM cte
LEFT JOIN products
ON cte.primary_product_id = products.product_id;

-- 2014

WITH cte AS (
SELECT primary_product_id,
	COUNT(order_id) AS orders,
	SUM(price_usd) AS revenue,
	SUM(price_usd - cogs_usd) AS margin,
	ROUND(AVG(price_usd), 2) AS aov
FROM orders
WHERE EXTRACT(YEAR FROM created_at) = 2014
GROUP BY 1
ORDER BY orders DESC)


SELECT product_name, orders, revenue, margin, ROUND(margin/revenue*100) AS "margin(%)", aov                -- Fetching product name from products table
FROM cte
LEFT JOIN products
ON cte.primary_product_id = products.product_id;

-- ASSIGNMENT: Pull monthly trends to date (till Jan 04, 2013) for number of sales, total revenue and total margin

SELECT EXTRACT(YEAR FROM created_at) AS yr,
	EXTRACT(MONTH FROM created_at) AS month,
	COUNT(order_id) AS number_of_sales,
	SUM(price_usd) AS total_revenue,
	SUM(price_usd - cogs_usd) AS total_margin
FROM orders
WHERE created_at < '2013-01-04'
GROUP BY 1, 2
ORDER BY month ASC

-- ASSIGNMENT: Analyzing Product Launches - Second product was launched on Jan 6, 2013. 
--	Pull together: Monthly order volumne, overall conversion rates, revenue per session and breakdown of sales by product
-- Timeframe: '2012-04-01'  to '2013-04-01' 


SELECT * FROM orders;                 -- Tables being used
SELECT * FROM website_sessions;

SELECT EXTRACT(YEAR FROM ws.created_at) AS yr,
	EXTRACT(MONTH FROM ws.created_at) AS mon,
	COUNT(DISTINCT ws.website_session_id) AS sessions,
	COUNT(DISTINCT o.order_id) AS orders,
	ROUND(100*COUNT(DISTINCT o.order_id)/COUNT(DISTINCT ws.website_session_id)::decimal, 2) AS conv_rate_percent, -- conversion rate
	ROUND(SUM(o.price_usd)/COUNT(DISTINCT ws.website_session_id), 2) AS revenue_per_session,
	SUM(CASE WHEN o.primary_product_id = 1 THEN 1 ELSE 0 END) AS product_one_orders,
	SUM(CASE WHEN o.primary_product_id = 2 THEN 1 ELSE 0 END) AS product_two_orders
FROM website_sessions AS ws
LEFT JOIN orders AS o
USING (website_session_id)
WHERE ws.created_at > '2012-04-01' AND ws.created_at < '2013-04-01' 
GROUP BY 1, 2;

-- Clearly, monthly conversion rates have improved over months (similar is true for revenue per sessions)
-- In 2013, February, order for product two were high but decreased significantly next month, so it is difficult to know
-- if the product launch was a success or not.


------------------------------------- PRODUCT LEVEL WEBSITE ANALYSIS -------------------------------------------
-- It is all about learning how customers interact with each of your products and how well each product converts customers.
-- Let us assume, there are five products obviously all of them would have different conversion rates.
-- USE CASES:  - Understanding which products generate most interest on multi product showcase pages
-- 			   - Analyzing impact on website conversion rate when you add a new product
-- 			   - Building product specific conversion funnels to understnad whether certain products convert better than others.

-- Method: We will be using website_pageviews and view users who looked at '/products' page and then went to next page
-- to identify which products they looked at after getting to products page.
-- From specific prodct pages, we will look into view-to-order conversion rates and create multi-step conversion funnel


SELECT * FROM website_pageviews;


SELECT --website_session_id,
	pageview_url,
	COUNT(DISTINCT website_session_id) AS sessions,
	ROUND(100*COUNT(DISTINCT website_session_id)/ SUM(COUNT(DISTINCT website_session_id)) OVER()::decimal, 2) AS percent_of_total_sessions
FROM website_pageviews
WHERE pageview_url IN ('/the-birthday-sugar-panda', '/the-forever-love-bear', '/the-hudson-river-mini-bear',
					'/the-original-mr-fuzzy')     -- products
GROUP BY 1
ORDER BY percent_of_total_sessions DESC;

-- So, it seems that maximum sessions are to 'original mr fuzzy' seems to be having most sessions
-- But let us see if it has the highest converstion rate

SELECT --website_session_id,
	pageview_url,
	COUNT(DISTINCT website_session_id) AS sessions,
	ROUND(100*COUNT(DISTINCT website_session_id)/ SUM(COUNT(DISTINCT website_session_id)) OVER()::decimal, 2) AS percent_of_total_sessions,
	COUNT(DISTINCT orders.order_id) AS orders,
	ROUND(100*COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_session_id)::decimal, 2) AS conversion_rate
FROM website_pageviews
LEFT JOIN orders
USING (website_session_id)
WHERE pageview_url IN ('/the-birthday-sugar-panda', '/the-forever-love-bear', '/the-hudson-river-mini-bear',
					'/the-original-mr-fuzzy')     -- products
GROUP BY 1
ORDER BY percent_of_total_sessions DESC;

-- Although '/the-original-mr-fuzzy' gets the highest sessions and number of orders but its conversion rate is the lowest amongst
-- all products.



-- ASSIGNMENT: Product Pathing Analysis

-- Step 1: Find the releveant/products pageviews with website_session_id
-- Step 2: Find the next pageview_id that occurs AFTER the product pageview
-- Step 3: Find the pageview_url assocaited with any applicable next pageview id
-- Step 4: Sumamrise the data and analyze the pre vs post periods

-- Step 1: Finding the products pageviews we care about

CREATE TEMP TABLE products_pageviews AS
SELECT website_session_id,
	website_pageview_id,
	created_at,
	CASE	
		WHEN created_at < '2013-01-06' THEN 'A. Pre_Product_2'     -- before product 2 was launched
		WHEN created_at >= '2013-01-06' THEN 'B. Post_Product_2'     -- after product 2 was launched
		ELSE '...check logic'
	END AS time_period
FROM website_pageviews
WHERE created_at < '2013-04-06'      -- date of request
AND created_at > '2012-10-06'      -- start of 3 month before product 2 launch
AND pageview_url = '/products';


-- Step 2: Find the next pageview_id that occurs AFTER the product pageview

CREATE TEMP TABLE sessions_w_next_pageview_id AS 
SELECT products_pageviews.time_period,
	products_pageviews.website_session_id,
	MIN(website_pageviews.website_pageview_id) AS min_next_pageview_id
FROM products_pageviews
	LEFT JOIN website_pageviews
		ON products_pageviews.website_session_id = website_pageviews.website_session_id
		AND website_pageviews.website_pageview_id > products_pageviews.website_pageview_id
GROUP BY 1, 2;

-- Step 3: Find the pageview_url associated with any applicable next pageview_id

CREATE TEMP TABLE sessions_w_next_pageview_url AS 
SELECT sessions_w_next_pageview_id.time_period,
	sessions_w_next_pageview_id.website_session_id,
	website_pageviews.pageview_url AS next_pageview_url
FROM sessions_w_next_pageview_id
	LEFT JOIN website_pageviews
		ON website_pageviews.website_pageview_id = sessions_w_next_pageview_id.min_next_pageview_id;


-- Step 4: Summarise the data and analyze pre vs post periods

SELECT time_period,
	COUNT(DISTINCT website_session_id) AS sessions,
	COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS with_next_pg,
	ROUND(100*COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)::decimal, 2) AS pct_with_next_pg,
	COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
	ROUND(100*COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)::decimal, 2) AS pct_to_mrfuzzy,
	COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS to_lovebear,
	ROUND(100*COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)::decimal, 2) AS pct_to_loverbear
FROM sessions_w_next_pageview_url
GROUP BY 1


-- Clearly, the percent of product pageviews that clicked to Mr. Fuxxy has gone down since the launch of Love Bear, but
-- overall clickthrough rate has gone up (by 4%) so, it seems that seems to be generating additional product interest overall.
-- Hence, the net impact was good.



-------------------------------------- PRODUCT LEVEL CONVERSION FUNNEL --------------------------------------------

-- For each product make product funnel, from product page to billing page



-- Select all pageviews for relevant sessions
-- Figure out which pageview urls to look for
-- Pull all pageviews and identify the funnel steps
-- Create session level conversion funnel view
-- Aggregate the data to assess funnel performance


-- Step 1

CREATE TEMP TABLE sessions_seeing_product_pages AS
SELECT website_session_id,
	website_pageview_id,
	pageview_url AS product_page_seen
FROM website_pageviews
WHERE EXTRACT(YEAR FROM created_at) = 2014      -- toggle between years to see results for each year
AND pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear',
'/the-birthday-sugar-panda',             -- all products
'/the-hudson-river-mini-bear');

SELECT * FROM website_pageviews;
-- Step 2 Finding the right pageview_urls to build funnels

SELECT DISTINCT website_pageviews.pageview_url
FROM sessions_seeing_product_pages
LEFT JOIN website_pageviews
ON sessions_seeing_product_pages.website_session_id = website_pageviews.website_session_id
	AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id    -- all pageviews seen by the customer after looking at the product

SELECT * FROM website_pageviews


-- Step 3:

SELECT sessions_seeing_product_pages.website_session_id,        -- We will using the above as subquery
	sessions_seeing_product_pages.product_page_seen,
	CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
	CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
	CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
	CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_seeing_product_pages
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id = sessions_seeing_product_pages.website_session_id
AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id
ORDER BY sessions_seeing_product_pages.website_session_id,
	website_pageviews.created_at;


CREATE TEMP TABLE session_product_level_made_it_flags AS
SELECT website_session_id,            
	CASE WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
	WHEN product_page_seen = '/the-forever-love-bear' THEN 'lovebear'
	WHEN product_page_seen = '/the-hudson-river-mini-bear' THEN 'hudsonbear'
	WHEN product_page_seen = '/the-birthday-sugar-panda' THEN 'sugarpanda'
	ELSE 'uh oh...check logic'
	END AS product_seen,
	MAX(cart_page) AS cart_made_it,            -- for every session there is a single record
	MAX(shipping_page) AS shipping_made_it,
	MAX(billing_page) AS billing_made_it,
	MAX(thankyou_page) AS thankyou_made_it
FROM (
SELECT sessions_seeing_product_pages.website_session_id,        -- We will using the above as subquery
	sessions_seeing_product_pages.product_page_seen,
	CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
	CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
	CASE WHEN pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
	CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM sessions_seeing_product_pages
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id = sessions_seeing_product_pages.website_session_id
AND website_pageviews.website_pageview_id > sessions_seeing_product_pages.website_pageview_id
ORDER BY sessions_seeing_product_pages.website_session_id,
	website_pageviews.created_at
) AS pageview_level
GROUP BY website_session_id,
	CASE WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
	WHEN product_page_seen = '/the-forever-love-bear' THEN 'lovebear'
	WHEN product_page_seen = '/the-hudson-river-mini-bear' THEN 'hudsonbear'
	WHEN product_page_seen = '/the-birthday-sugar-panda' THEN 'sugarpanda'
	ELSE 'uh oh...check logic'
	END


-- Step 4: Performing aggregations

SELECT product_seen,
	COUNT(DISTINCT website_session_id) AS sessions,
	COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
	COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
	COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
	COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_product_level_made_it_flags
GROUP BY product_seen;


-- Converting to rates
SELECT product_seen,
	ROUND(100*COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)::numeric, 2) AS product_page_ctr,
	ROUND(100*COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)::numeric, 2) AS cart_ctr,
	ROUND(100*COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)::numeric, 2) AS shipping_ctr,
	ROUND(100*COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)::numeric, 2) AS billing_ctr
FROM session_product_level_made_it_flags
GROUP BY product_seen;


--------------------------------------- CROSS SELLING ANALYSIS ----------------------------------------------------
-- Cross sell Analysis is about understanding which products users are most likely to purchase together
-- and offering smart product recommendations

-- USE CASES: Understanding which products are often purchased together
--			  Testing and optimising the way cross sell products on your website
--			  Understanding the conversion rate impact and the overall revenue impact of trying to cross sell products.

SELECT orders.primary_product_id,
	COUNT(DISTINCT orders.order_id) AS orders,
	COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN orders.order_id ELSE NULL END) AS x_sell_prod1,
	COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN orders.order_id ELSE NULL END) AS x_sell_prod2,
	COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN orders.order_id ELSE NULL END) AS x_sell_prod3,
	COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN orders.order_id ELSE NULL END) AS x_sell_prod4,
-- cross sell rates
	ROUND(100*COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN orders.order_id ELSE NULL END)/COUNT(DISTINCT orders.order_id)::numeric, 2) AS x_sell_prod1_rt,
	ROUND(100*COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN orders.order_id ELSE NULL END)/COUNT(DISTINCT orders.order_id)::numeric, 2) AS x_sell_prod2_rt,
	ROUND(100*COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN orders.order_id ELSE NULL END)/COUNT(DISTINCT orders.order_id)::numeric, 2) AS x_sell_prod3_rt,
	ROUND(100*COUNT(DISTINCT CASE WHEN order_items.product_id = 4 THEN orders.order_id ELSE NULL END)/COUNT(DISTINCT orders.order_id)::numeric, 2) AS x_sell_prod4_rt
FROM (SELECT * FROM orders WHERE EXTRACT(YEAR FROM created_at) = 2015) AS orders       -- change the year to check yearwise
LEFT JOIN order_items
ON orders.order_id = order_items.order_id
AND order_items.is_primary_item = 0             -- Cross sell only
GROUP BY 1;     




----------------------------------------------- PRODUCT REFUND ANALYSIS ------------------------------------------
-- Analyzing product refund rates is about controlling for quality
--and understanding where we might have problems to address

-- USE CASES: Monitoring products from different suppliers
--			  Understanding refund rates for products at different price points
--			  Taking product refund rates and associated costs into account when assessing overall performance of business.

SELECT order_items.order_id,                 -- all orders where amount was refunded
	order_items.order_item_id,
	order_items.price_usd AS price_paid_usd,
	order_items.created_at,
	order_item_refunds.order_item_refund_id,
	order_item_refunds.refund_amount_usd,
	order_item_refunds.created_at

FROM order_items
	LEFT JOIN order_item_refunds
		USING (order_item_id)  
WHERE order_item_refunds.order_item_refund_id IS NOT NULL;


-- Look at yearwise monthly refund rates for all prodcuts

CREATE TEMP TABLE year_month_refunds AS 
SELECT 
    EXTRACT(YEAR FROM order_items.created_at) AS yr,
    EXTRACT(MONTH FROM order_items.created_at) AS mon,
    
    -- p1 orders and refund rate
    COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_item_id ELSE NULL END) AS p1_orders,
    COALESCE(
        ROUND(
            100 * COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_item_refunds.order_item_id ELSE NULL END) / 
            NULLIF(COUNT(DISTINCT CASE WHEN product_id = 1 THEN order_items.order_item_id ELSE NULL END), 0)::numeric, 
            2
        ), 
        0
    ) AS p1_refund_rate,
    
    -- p2 orders and refund rate
    COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_items.order_item_id ELSE NULL END) AS p2_orders,
    COALESCE(
        ROUND(
            100 * COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_item_refunds.order_item_id ELSE NULL END) / 
            NULLIF(COUNT(DISTINCT CASE WHEN product_id = 2 THEN order_items.order_item_id ELSE NULL END), 0)::numeric, 
            2
        ), 
        0
    ) AS p2_refund_rate,
    
    -- p3 orders and refund rate
    COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_item_id ELSE NULL END) AS p3_orders,
    COALESCE(
        ROUND(
            100 * COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_item_refunds.order_item_id ELSE NULL END) / 
            NULLIF(COUNT(DISTINCT CASE WHEN product_id = 3 THEN order_items.order_item_id ELSE NULL END), 0)::numeric, 
            2
        ), 
        0
    ) AS p3_refund_rate,
    
    -- p4 orders and refund rate
    COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_item_id ELSE NULL END) AS p4_orders,
    COALESCE(
        ROUND(
            100 * COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_item_refunds.order_item_id ELSE NULL END) / 
            NULLIF(COUNT(DISTINCT CASE WHEN product_id = 4 THEN order_items.order_item_id ELSE NULL END), 0)::numeric, 
            2
        ), 
        0
    ) AS p4_refund_rate
    
FROM 
    order_items
LEFT JOIN 
    order_item_refunds USING (order_item_id)
GROUP BY 
    1, 2;
----------------- TEMP table code finished ---------------------------------------

SELECT * FROM year_month_refunds
WHERE yr = 2014                   -- change the year as per requirement



























