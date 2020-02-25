/* 
Welcome! This document was created for my article 
"Answering Business Questions with SQL"
that you can find on my Medium profile: https://medium.com/@lmmfrederico

All the tables for this queries are available through the link below:
https://github.com/olist/work-at-olist-data/tree/master/datasets

Have fun!
*/
-- Question 1: top customers by State
 SELECT	customer, state, total_amount
 FROM (
	SELECT	
		c.customer_id AS customer,
		c.customer_state AS state,
		SUM(oi.price) AS total_amount,
		-- The line below creates the rank of top amount grouped by state
		ROW_NUMBER() OVER (PARTITION BY c.customer_state
			ORDER BY SUM(oi.price) DESC) AS row_order
	FROM customers AS c
	INNER JOIN orders AS o
		ON c.customer_id = o.customer_id
	INNER JOIN order_items AS oi
		ON o.order_id = oi.order_id
	GROUP BY c.customer_state, c.customer_id) AS sq
-- The Where statement makes sure we are selecting just the top buyer
WHERE row_order = 1 
ORDER BY total_amount DESC;

-- Question 2: average price by sentiment
-- The Common Table Expression will act like a temporary table 
WITH cte AS (
		SELECT	oi.price AS order_price,
		-- CASE WHEN will classify the score according to the criteria
		-- we have definied
		CASE WHEN review_score > 3 THEN 'positive'
		ELSE 'negative' END AS sentiment
	FROM orders AS o
	INNER JOIN order_items AS oi
		ON o.order_id = oi.order_id
	INNER JOIN order_reviews AS r
		ON o.order_id = r.order_id
	)
-- Now we just need to select the average price and group by the sentiment
SELECT ROUND(AVG(order_price), 2) as avg_price, 
	sentiment
FROM cte 
GROUP BY sentiment;

-- Question 3: Sales performance over months in 2017
WITH cte AS (
SELECT 
	MONTH(order_purchase_timestamp) AS month_,
	-- Actual month
	ROUND(
		SUM(oi.price), 2) AS month_sales,
	-- Previous Month
	ROUND(
		LAG(SUM(oi.price), 1) OVER(ORDER BY MONTH(order_purchase_timestamp)), 
		2) AS previous_month
FROM orders AS o
INNER JOIN order_items AS oi
	ON o.order_id = oi.order_id
WHERE YEAR(order_purchase_timestamp) = 2017
GROUP BY MONTH(order_purchase_timestamp)
)
SELECT
	month_,
	month_sales,
	previous_month,
	-- Format 'P' gives us the numbers with the "%" sign, rounded to 2 decimals
	FORMAT((month_sales - previous_month)  / previous_month, 'P') vs_previous_month 
FROM cte;
