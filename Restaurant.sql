SELECT * 
FROM dbo.members;
SELECT * 
FROM dbo.menu;
SELECT * 
FROM dbo.sales;

-- ======================--CASE STUDY QUESTIONS--===============================

-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(price) AS total_sales
FROM dbo.sales AS s
JOIN dbo.menu AS m
   ON s.product_id = m.product_id
GROUP BY customer_id; 

-- A = 76, B = 74, C = 36
-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, count(DISTINCT(order_date)) as visit_times
FROM dbo.sales
GROUP BY customer_id;

-- A = 4, B - 6, C = 2

-- 3. What was the first item from the menu purchased by each customer?
WITH TEMP 
AS
(SELECT s.customer_id, s.order_date, m.product_name,
        DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date ASC) as rank
FROM dbo.sales as s
JOIN dbo.menu as m 
    ON s.product_id = m.product_id
)
SELECT customer_id, order_date, product_name, rank
FROM TEMP
WHERE rank = 1 
GROUP BY customer_id, order_date, product_name, rank;

-- merge sale with menu then rank the date as first date = 1 for each customer, create temporary table for it. select only rank 1 as the first date so we can see the first item. 

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT top 1 product_name, Count(s.product_id) AS most_purchased
FROM dbo.sales AS s
JOIN dbo.menu AS m
   ON s.product_id = m.product_id
GROUP BY product_name 
ORDER BY most_purchased DESC;

-- most purchase is ramen = 8 

-- 5. Which item was the most popular for each customer?
WITH temp 
AS
(SELECT s.customer_id, m.product_name, count(m.product_id) as order_count,
        DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(m.product_id) DESC) as rank
FROM dbo.sales as s
JOIN dbo.menu as m 
    ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name
)

SELECT customer_id, product_name 
FROM temp 
WHERE rank = 1;

-- customer A prefer ramen, B bought equally between 3 items, and C favourite is ramen

-- 6. Which item was purchased first by the customer after they became a member?

WITH temp
AS
(SELECT s.customer_id, s.order_date, m.join_date, s.product_id, mn.product_name,
      DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as rank
FROM dbo.sales AS s
JOIN dbo.menu as mn 
   ON s.product_id = mn.product_id
JOIN dbo.members AS m
   ON s.customer_id = m.customer_id
WHERE s.order_date > m.join_date
)

SELECT customer_id, product_id, product_name
FROM temp
WHERE rank = 1;

-- 7. Which item was purchased just before the customer became a member?

WITH temp
AS
(SELECT s.customer_id, s.order_date, m.join_date, s.product_id, mn.product_name,
      DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as rank
FROM dbo.sales AS s
JOIN dbo.menu as mn 
   ON s.product_id = mn.product_id
JOIN dbo.members AS m
   ON s.customer_id = m.customer_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id, s.order_date,m.join_date, s.product_id, mn.product_name
)

SELECT customer_id, product_id, product_name
FROM temp
WHERE rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(s.product_id) as total_items, SUM(mn.price) as total_sales
FROM dbo.sales as s
JOIN dbo.menu as mn 
   ON s.product_id = mn.product_id
JOIN dbo.members as m 
   ON s.customer_id = m.customer_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH price_points AS
(
   SELECT *, 
      CASE
         WHEN product_id = 1 THEN price * 10 * 2
         ELSE price * 10
      END AS points
   FROM menu
)

SELECT s.customer_id, SUM(p.points) AS total_points
FROM price_points AS p
JOIN sales AS s
   ON p.product_id = s.product_id
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
    
WITH Date AS 
(
   SELECT *,
      DATEADD(day, 6, join_date) AS valid_date,
      EOMONTH('2021-01-31') AS last_date
   FROM dbo.members)

SELECT s.customer_id, 
     SUM(
         CASE
         WHEN m.product_id = 1 THEN m.price * 10 * 2
         WHEN s.order_date BETWEEN d.valid_date AND d.join_date THEN m.price *10*2 
         ELSE m.price * 10
      END) AS points
   FROM Date as d
   JOIN dbo.sales as s 
      ON d.customer_id = s.customer_id
   JOIN dbo.menu as m 
      ON s.product_id = m.product_id
   WHERE s.order_date < d.last_date
   GROUP BY s.customer_id;

-- A: 860; B: 820. This case need to create the valid date as 6 days after joining program and the last date = end of Jan
-- Then later do similar to the question 9 but joining temporary 'date' table for the when clause of order date within 6 days of first joined date. 

-- Join All The Things - Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)

SELECT s.customer_id, s.order_date, mn.product_name, mn.price,
   CASE
      WHEN m.join_date > s.order_date THEN 'N'
      WHEN m.join_date <= s.order_date THEN 'Y'
      ELSE 'N'
      END AS member
FROM sales AS s
LEFT JOIN menu AS mn
   ON s.product_id = mn.product_id
LEFT JOIN members AS m
   ON s.customer_id = m.customer_id;

-- Joining 3 table first by using
-- select * 
-- FROM dbo.sales as s
-- JOIN dbo.menu as mn ON s.product_id = mn.product_id 
-- JOIN dbo.members as m ON s.customer_id = m.customer_id
