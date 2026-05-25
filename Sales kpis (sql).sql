/*
==============================================================================
SALES REPORT:
==============================================================================
*/

-- 1} Find the Total sales
SELECT SUM(sales_amount) AS total_sales FROM gold.fact_sales

--i}Calculate the total sales per month
SELECT
DATETRUNC(MONTH, order_date) AS order_date,
SUM(sales_amount)AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(MONTH, order_date)
ORDER BY order_date

--ii}Calculate the total sales per year
SELECT
DATENAME(YEAR, order_date) AS order_date,
SUM(sales_amount)AS total_sales
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATENAME(YEAR, order_date)
ORDER BY DATENAME(YEAR, order_date)

-- 2} Find the Total sales: i}Monthy ii]Yearly.
SELECT SUM(sales_amount) AS total_sales FROM gold.fact_sales

-- 3} Find how many items are sold.
SELECT SUM(quantity) as total_quantity FROM gold.fact_sales

-- 4} Find the average selling price
SELECT AVG(price) as avg_price FROM gold.fact_sales

-- 5} Find the Total numbers of Orders
SELECT COUNT(order_number) AS total_orders FROM gold.fact_sales
--OR
SELECT COUNT(DISTINCT order_number) AS total_orders FROM gold.fact_sales

-- 6} Generate a report that show all key metrics of the business
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL 
SELECT 'Total Quantity', SUM(quantity) FROM gold.fact_sales
UNION ALL
SELECT 'Average Price', AVG(price) FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr Orders',  COUNT(DISTINCT order_number) FROM gold.fact_sales
UNION ALL
SELECT 'Total Nr products', COUNT(product_name) FROM gold.dim_products
UNION ALL
SELECT  'Total_customers', COUNT(customer_key) FROM gold.dim_customers

-- 7} Calculate the running total of sales over time
SELECT 
order_date,
total_sales,
SUM(total_sales) OVER (PARTITION BY order_date ORDER BY order_date) AS running_total_sales,
AVG(avg_price) OVER (PARTITION BY order_date ORDER BY order_date) AS moving_average_price
FROM
(
SELECT
DATETRUNC(YEAR, order_date) AS order_date,
SUM(sales_amount)AS total_sales,
AVG(price) AS avg_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(YEAR, order_date)
)t;