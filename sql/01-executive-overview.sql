/*
===============================================================================
EXECUTIVE OVERVIEW - MONTHLY BUSINESS PERFORMANCE
===============================================================================

PURPOSE:
    Provide leadership with a high-level view of business health including
    revenue trends, order volume, and growth rates.

BUSINESS QUESTIONS ANSWERED:
    1. How is revenue trending month-over-month?
    2. Are we growing or shrinking? (growth rates)
    3. How many orders are we processing?
    4. Is average order value increasing?
    5. Which months had exceptional or concerning performance?

METRICS DEFINED:
    - orders: Total number of delivered orders
    - revenue: Sum of all payments for delivered orders
    - avg_order_value: revenue ÷ orders (average spent per order)
    - revenue_growth: % change from previous month
    - orders_growth: % change from previous month

DATA SOURCES:
    - orders: For order dates and status
    - payments: For payment values

FILTERS APPLIED:
    - Only delivered orders (cancelled/incomplete excluded)
    - Grouped by month

CREATED: 2024-02-19
LAST MODIFIED: 2024-02-21
AUTHOR: difrag
===============================================================================
*/

with monthly_metrics as (
	select 
		date_trunc('month',o.order_purchase_timestamp) as month,
		count(distinct o.order_id) as orders,
		round(sum(p.payment_value)::numeric, 2) as revenue,
		---Add Average Order Value
		round(sum(p.payment_value) / count(distinct o.order_id)::numeric, 2) as avg_order_value
	from orders o
	join payments p on o.order_id = p.order_id
	---Filter Only Delivered Orders
	where o.order_status = 'delivered'
	group by month
)
select
	to_char(month, 'YYYY-MM') as month,-- Format as "2024-01" instead of date
	orders,
	revenue,
	avg_order_value,
	-- Format growth with + sign
	CASE 
        WHEN revenue_growth > 0 THEN '+' || revenue_growth::text
        ELSE revenue_growth::text
    END AS revenue_growth,
    CASE 
        WHEN orders_growth > 0 THEN '+' || orders_growth::text
        ELSE orders_growth::text
    END AS orders_growth
	
    
FROM (
-- Step 3: Calculate the actual growth numbers
	SELECT 
        month,
        orders,
        revenue,
        avg_order_value,
        ROUND(((revenue - LAG(revenue) OVER (ORDER BY month)) / LAG(revenue) OVER (ORDER BY month) * 100)::numeric, 1) AS revenue_growth,
        ROUND(((orders - LAG(orders) OVER (ORDER BY month)) / LAG(orders) OVER (ORDER BY month) * 100)::numeric, 1) AS orders_growth
    FROM monthly_metrics
) subquery
ORDER BY month DESC;  -- Show newest first

