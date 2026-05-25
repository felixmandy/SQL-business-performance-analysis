/*=================================================================================================
   PRODUCT REPORT
 ==================================================================================================

Purpose: THis report consolidates key product metrics and behaviours*/

-- 1} Analyze the yearly performance of products by comparing thier sales to both 
--    the average sales performance of the product and the previous year's sales.

WITH yearly_product_sales AS (
SELECT 
YEAR(f.order_date) AS order_year,
p.product_name,
SUM(f.sales_amount) AS current_sales
FROM gold.fact_sales f
LEFT JOIN  gold.dim_products p
ON f.product_key =  p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY
YEAR(f.order_date),
p.product_name
)
SELECT
order_year,
product_name,
current_sales,
AVG(current_sales) OVER (PARTITION BY product_name) avg_sales,
current_sales - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,
CASE 
WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
ELSE 'Avg'
END avg_change,
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) py_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_py,
CASE
WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'increase'
WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'decrease'
ELSE 'No Change'
END PY_change 
FROM yearly_product_sales
ORDER BY product_name, order_year;

-- 2} Find the total products by category
SELECT 
category,
COUNT(product_name) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC

-- 3} What is the average cost in each category?
SELECT
category,
AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC

-- 4} What is the total revenue generated for each category?
SELECT
p.category,
SUM(f.sales_amount) AS total_revenue
FROM gold.dim_products p
LEFT JOIN gold.fact_sales f
ON p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_revenue DESC

-- 5} Which categories contribute the most to overall sales?
WITH category_sales AS (
SELECT
category,
SUM(sales_amount) total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY category)

SELECT category,
total_sales,
SUM(total_sales) OVER () overall_sales,
CONCAT(ROUND((CAST(total_sales AS FLOAT) / SUM(total_sales) OVER())*100, 2), '%') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;

/*
-- 6} Highlights:
   a).Gathers essential fields such as product name, category, subcategory, and cost.
   b).Segments products by revenue to identify High-Performers, Mid-Range. or Low-Performers.
   c).Aggregates customer_level metrics:
     - total_orders
     - total sales
     - total quantity sold
     - total customers (unique)
     - lifespan (in months)
   d).Calcultes valuable KPIs:
     - renency (months since last sale)
     - average order value (AOR)
     - average monthly spend
*/
WITH base_query AS(
SELECT
p.product_key,
p.product_number,
p.product_name,
p.category,
p.subcategory,
p.cost,
f.sales_amount,
f.quantity,
f.order_number,
f.order_date
FROM gold.dim_products p
LEFT JOIN gold.fact_sales f
ON p.product_key = f.product_key
WHERE order_date IS NOT NULL
)
, all_time_total AS (
SELECT
product_key,
category,
subcategory,
product_number,
Product_name,
SUM(cost) AS cost,
SUM(quantity) AS total_quantity,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT order_number) AS total_orders,
MAX(order_date) AS last_order_date,
DATEDIFF (month, MIN(order_date), MAX(order_date)) AS lifespan,
AVG(sales_amount / quantity) AS avg_selling_price
FROM base_query
GROUP BY
product_key,
category,
subcategory,
product_number,
Product_name
)

SELECT
product_key,
category,
subcategory,
product_number,
Product_name,
cost,
total_quantity,
total_sales,
CASE WHEN total_sales > 50000 THEN 'High-Performer'
WHEN total_sales >= 10000 THEN 'Mid-Range'
ELSE 'Low-Performer'
END AS product_segment,
total_orders,
--Compute average order value(AVO)
CASE WHEN total_sales = 0 THEN 0
ELSE total_sales / total_orders
END AS avg_order_value,
last_order_date,
lifespan,
DATEDIFF (MONTH, last_order_date, GETDATE()) AS recency,
avg_selling_price,
--Compuate average monthly spend
CASE WHEN lifespan = 0 THEN total_sales
ELSE total_sales / lifespan
END AS avg_monthly_spend
FROM all_time_total
 
