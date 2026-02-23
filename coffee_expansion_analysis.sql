use zero_analyst;
select * from city;
select * from customers;
select * from products;
select * from sales;

-- Easy to Medium Questions
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?
select
	city_name,
	round((population * 0.25 / 100000), 2) As coffee_consumed_by_lakh,
    city_rank
from city
order by coffee_consumed_by_lakh desc;

-- What is the total revenue generated from coffee sales all cities in the last qtr of 2023?
select
	ci.city_name,
    sum(s.total) As revenue,
	extract(year from sale_date) As year,
    extract(quarter from sale_date) As qrt
from sales s 
join customers c 
on s.customer_id = c.customer_id
join city ci
on c.city_id = ci.city_id
where extract(year from sale_date) = 2023 and extract(quarter from sale_date) = 4
group by ci.city_name, year, qrt;
    
select
	ci.city_name,
    sum(s.total) As revenue,
    year(sale_date) As year,
    quarter(sale_date) As qrt
from sales s
join customers c 
on s.customer_id = c.customer_id
join city ci
on c.city_id = ci.city_id
where year(sale_date) = 2023 and quarter(sale_date) = 4
group by ci.city_name, year, qrt;

-- Sales Count for Each Product
select
	p.product_name,
    count(s.customer_id) As sales_count_customer_id,
    count(s.sale_id) As total_order,
    sum(s.total) As revenue
from products p
join sales s
on p.product_id = s.product_id
group by p.product_name
order by total_order desc;


-- Average Sales Amount per City
select 
    ci.city_name,
    round(avg(s.total),2) As avg_sales_amount,
    round(sum(s.total),2) As revenue
from customers c 
join city ci 
on c.city_id = ci.city_id
join sales s
on c.customer_id = s.customer_id
group by ci.city_name
order by avg_sales_amount desc;

-- What is the average sales amount per customer in each city?
select 
    ci.city_name,
    round(sum(s.total),2) As sales_amount,
    count(distinct c.customer_id) As customer,
    round(sum(s.total) / count(distinct c.customer_id), 2) As avg_sales_per_customer
from customers c 
join city ci 
on c.city_id = ci.city_id
join sales s
on c.customer_id = s.customer_id
group by ci.city_name
order by sales_amount desc;

-- Provide a list of cities along with their populations and estimated coffee consumers.
select
	c.city_name,
	round((c.population * 0.25 / 100000), 2) As coffee_consumer_by_lakh,
    round(sum(s.total),2) As sales_amount,
    count(distinct cu.customer_id) As customers
from city c 
JOIN customers cu
ON c.city_id = cu.city_id
JOIN sales s
ON cu.customer_id = s.customer_id
GROUP BY
    c.city_name,
    c.population,
    c.city_rank
order by coffee_consumer_by_lakh desc;

-- Medium Hard Questions
-- What are the top 3 selling products in each city, ranked by sales volume?
select 
	* 
from 
(select
	c.city_name,
    p.product_name,
    count(s.sale_id) As total_orders,
    dense_rank() over( partition by c.city_name order by count(s.sale_id) desc) As rankk
from city c
join customers cu
on c.city_id = cu.city_id
join sales s
on cu.customer_id = s.customer_id
join products p 
on s.product_id = p.product_id
group by c.city_name, p.product_name
-- order by c.city_name, total_orders desc;
) As rank_table
where rankk <= 3;

-- How many unique customers in each city have purchased coffee products?
select 
	c.city_name,
    count( distinct s.customer_id) As unique_customer
from city c
join customers cu
on c.city_id = cu.city_id
join sales s
on cu.customer_id = s.customer_id
join products p 
on s.product_id = p.product_id
where p.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by c.city_name
order by unique_customer desc;


-- Find each city and their average sale per customer and avg rent per customer
select 
	c.city_name,
    c.estimated_rent,
    sum(s.total) As revenue,
    count(distinct cu.customer_id) As total_customer,
    round(sum(s.total) / count(DISTINCT s.customer_id),2) As avg_sale_per_customer,
    round(c.estimated_rent / count(distinct cu.customer_id),2 ) As avg_rent_per_customer
from city c
join customers cu
on c.city_id = cu.city_id
join sales s
on cu.customer_id = s.customer_id
join products p 
on s.product_id = p.product_id
group by c.city_name, c.estimated_rent
order by avg_sale_per_customer desc;


-- Advanced Questions & Analysis
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).
WITH monthly_sales AS (
    SELECT 
        ci.city_name,
        EXTRACT(MONTH FROM s.sale_date) AS month,
        EXTRACT(YEAR FROM s.sale_date) AS year,
        SUM(s.total) AS total_sale
    FROM sales s
    JOIN customers c ON c.customer_id = s.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name, year, month
    ORDER BY ci.city_name, year, month
),
growth_ratio AS (
    SELECT
        city_name,
        month,
        year,
        total_sale AS cr_month_sale,
        LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) AS last_month_sale
    FROM monthly_sales
)
SELECT
    city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND(
        (cr_month_sale - last_month_sale) / last_month_sale * 100, 2
    ) AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL;


-- Identify the top 3 cities based on the highest sales, return city name, total sales, total rent, total customers, and estimated coffee consumer
WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_pr_cx
    FROM sales s
    JOIN customers c ON s.customer_id = c.customer_id
    JOIN city ci ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name,
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 3) AS estimated_coffee_consumer_in_millions
    FROM city
)
SELECT 
    cr.city_name,
    ct.total_revenue,
    cr.estimated_rent AS total_rent,
    ct.total_cx,
    cr.estimated_coffee_consumer_in_millions,
    ct.avg_sale_pr_cx,
    ROUND(cr.estimated_rent / ct.total_cx, 2) AS avg_rent_per_cx
FROM city_rent cr
JOIN city_table ct
    ON cr.city_name = ct.city_name
ORDER BY ct.total_revenue DESC
LIMIT 3;