# SQL Challenge #1 (Week 1) - Danny's Diner
![image](https://user-images.githubusercontent.com/100246099/228079227-f93f5788-1852-41d9-878b-bdddf9b86a2b.png)

Note: All source material and respected credit is from: https://8weeksqlchallenge.com/

Online SQL instance used to test queries: https://www.db-fiddle.com/f/2rM8RAnq7h5LLDTzZiRWcd/138

## Introduction

Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business
## Problem Statement

Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!

Danny has shared with you 3 key datasets for this case study:

* sales
* menu
* members
## Data Structure

You can inspect the entity relationship diagram and example data below.
![image](https://user-images.githubusercontent.com/100246099/228077015-37bd2c3a-baa3-4805-9f6d-123d0b5e5c7a.png)

# Case Study Questions: 

## 1. What is the total amount each customer spent at the restaurant?

```sql
SELECT s.customer_id, SUM(price) AS total_sales
FROM dbo.sales AS s
JOIN dbo.menu AS m
   ON s.product_id = m.product_id
GROUP BY customer_id; 
````
## 2. How many days has each customer visited the restaurant?
````sql
SELECT customer_id, count(DISTINCT(order_date)) as visit_times
FROM dbo.sales
GROUP BY customer_id;
````
## 3. What was the first item from the menu purchased by each customer?
````sql
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
````
## 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
````sql
SELECT top 1 product_name, Count(s.product_id) AS most_purchased
FROM dbo.sales AS s
JOIN dbo.menu AS m
   ON s.product_id = m.product_id
GROUP BY product_name 
ORDER BY most_purchased DESC;
````

## 5. Which item was the most popular for each customer?
````sql
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
````

-- customer A prefer ramen, B bought equally between 3 items, and C favourite is ramen

## 6. Which item was purchased first by the customer after they became a member?

````sql
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
````
## 7. Which item was purchased just before the customer became a member?
````sql
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
````
## 8. What is the total items and amount spent for each member before they became a member?

````sql
SELECT s.customer_id, COUNT(s.product_id) as total_items, SUM(mn.price) as total_sales
FROM dbo.sales as s
JOIN dbo.menu as mn 
   ON s.product_id = mn.product_id
JOIN dbo.members as m 
   ON s.customer_id = m.customer_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id;
````
## 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
````sql
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
````
## 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
````sql    
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
````
 A: 860; B: 820. This case need to create the valid date as 6 days after joining program and the last date = end of Jan Then later do similar to the question 9 but joining temporary 'date' table for the when clause of order date within 6 days of first joined date. 

## Join All The Things - Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)
````sql
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
````

