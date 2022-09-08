--------------------------------
--CASE STUDY #1: DANNY'S DINER--
--------------------------------

--Author: Arbaz Baig
--Tool used: MS SQL Server

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

SELECT *
FROM dbo.members;

SELECT *
FROM dbo.menu;

SELECT *
FROM dbo.sales;

------------------------
--CASE STUDY QUESTIONS--
------------------------

--1. What is the total amount each customer spent at the restaurant?

SELECT customer_id,SUM(price) as Total_Spent
FROM dbo.sales 
INNER JOIN menu
ON sales.product_id = menu.product_id
GROUP BY customer_id

/*
Steps:
Use SUM and GROUP BY to find out total_sales contributed by each customer.
Use JOIN to merge sales and menu tables as customer_id and price are from both tables.

Answer:
customer_id	total_sales
A		  76
B		  74
C		  36

Customer A spent $76.
Customer B spent $74.
Customer C spent $36.
*/

--2. How many days has each customer visited the restaurant?

SELECT customer_id,COUNT(DISTINCT(order_date)) as Number_of_Visits
FROM sales
GROUP BY customer_id

/*
Steps:
Use DISTINCT and wrap with COUNT to find out the visit_count for each customer.
If we do not use DISTINCT on order_date, the number of days may be repeated. For example, if Customer A visited the restaurant twice on '2021–01–07', then number of days is counted as 2 days instead of 1 day.

Answer:
customer_id	visit_count
	A 	 4
	B	 6
	C	 2

Customer A visited 4 times.
Customer B visited 6 times.
Customer C visited 2 times.
*/

--3. What was the first item from the menu purchased by each customer?

SELECT customer_id,order_date,product_name
FROM dbo.sales 
INNER JOIN menu
ON sales.product_id = menu.product_id
WHERE order_date = '2021-01-01'
GROUP by customer_id,product_name,order_date

/*
Steps:
 First, I joined tables sales and menu:
 Then, I organized by order date and customer_id:
 After finding out the first date, USED WHERE clause to make the results clearer:
 GROUP BY all columns to show rank = 1 only.

 Answer:
 customer_id	order_date	product_name
	A	2021-01-01	curry
	A	2021-01-01	sushi
	B	2021-01-01	curry
	C	2021-01-01	ramen

Customer A's first orders are curry and sushi.
Customer B's first order is curry.
Customer C's first order is ramen.
*/

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 product_name,count(sales.product_id) as most_purchased
FROM sales INNER JOIN menu
ON sales.product_id = menu.product_id
GROUP BY product_name
ORDER BY most_purchased DESC

/*
Steps:
COUNT number of product_id and ORDER BY most_purchased by descending order.
Then, use TOP 1 to filter highest number of purchased item.

Answer:
product_name	most_purchased
ramen		8

Most purchased item on the menu is ramen which is 8 times. 
*/

--5. Which item was the most popular for each customer?

WITH result as (
SELECT customer_id,product_name,COUNT(*) as order_count,
DENSE_RANK() OVER( PARTITION BY customer_id ORDER BY COUNT(*) desc)as [rank]
FROM sales 
INNER JOIN menu
on sales.product_id = menu.product_id
GROUP BY customer_id,product_name
)

SELECT customer_id,product_name,order_count
FROM result
WHERE [rank] = 1

/*
Steps:
Create a result and use DENSE_RANK to rank the order_count for each product by descending order for each customer.
Generate results where product rank = 1 only as the most popular product for each customer.

Answer:
customer_id	product_name	order_count
A		ramen		3
B		sushi		2
B		curry		2
B		ramen		2
C		ramen		3

Customer A and C's favourite item is ramen.
Customer B enjoys all items on the menu.
*/

--6. Which item was purchased first by the customer after they became a member?

WITH result as
(SELECT sales.customer_id,product_name,order_date,join_date,
DENSE_Rank() OVER(PARTITION BY sales.customer_id ORDER BY order_date) as row_id
FROM sales 
INNER JOIN members
ON sales.customer_id = members.customer_id
INNER JOIN menu
ON sales.product_id = menu.product_id
WHERE order_date >= join_date)

SELECT customer_id,product_name
FROM result
WHERE row_id =1

/*
Steps:
Create result by using windows function and partitioning customer_id by ascending order_date. Then, filter order_date to be on or after join_date.
Then, filter table by rank = 1 to show 1st item purchased by each customer.

Answer:
customer_id	  product_name
A		   curry
B		   sushi

Customer A's first order as member is curry.
Customer B's first order as member is sushi.
*/

--7. Which item was purchased just before the customer became a member?

WITH result as
(SELECT sales.customer_id,product_name,order_date,join_date,
DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY order_date) as row_id
FROM sales 
INNER JOIN members
ON sales.customer_id = members.customer_id
INNER JOIN menu
ON sales.product_id = menu.product_id
WHERE order_date < join_date)

SELECT customer_id,product_name
FROM result
WHERE row_id =1

/*
Steps:
Create a result to create new column rank by using Windows function and partitioning customer_id by descending order_date to find out the last order_date before customer becomes a member.
Filter order_date before join_date.

Answer:
customer_id	product_name
A		sushi
A		curry
B		sushi
Customer A’s last order before becoming a member is sushi and curry.
Whereas for Customer B, it's sushi.

*/

--8. What is the total items and amount spent for each member before they became a member?

SELECT sales.customer_id,COUNT(distinct sales.product_id) as Total_Items,SUM(price) as Amount_Spent
FROM sales 
INNER JOIN members
ON sales.customer_id = members.customer_id
INNER JOIN menu
ON sales.product_id = menu.product_id
WHERE order_date < join_date
GROUP BY sales.customer_id

/*
Filter order_date before join_date and perform a COUNT DISTINCT on product_id and SUM the total spent before becoming member.

Answer:
customer_id	Total_Items	Amount_Spent
A		2		25
B		2		40

Before becoming members,

Customer A spent $ 25 on 2 items.
Customer B spent $40 on 2 items.
*/

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?

SELECT customer_id,
SUM(
CASE
	WHEN PRODUCT_NAME = 'sushi' THEN price * 20
	ELSE price * 10
	END ) as Total_Points
FROM sales
INNER JOIN menu
ON sales.product_id = menu.product_id
GROUP BY customer_id

/*
Steps:
Let’s breakdown the question.

Each $1 spent = 10 points.
But, sushi (product_id 1) gets 2x points, meaning each $1 spent = 20 points So, we use CASE WHEN to create conditional statements
If product_id = 1, then every $1 price multiply by 20 points
All other product_id that is not 1, multiply $1 by 10 points Using price_points, SUM the points.

Answer:
customer_id	Total_Points
A		860
B		940
C		360

Total points for Customer A is 860.
Total points for Customer B is 940.
Total points for Customer C is 360.
*/

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi
--		— how many points do customer A and B have at the end of January?

SELECT
	sales.customer_id,
	SUM(
		CASE
  		WHEN .menu.product_name = 'sushi' THEN 20 * price
		WHEN order_date BETWEEN join_date AND DATEADD(DAY,6,join_date) THEN  20 * price
  		ELSE 10 * PRICE
		END
	) AS Points
	FROM sales
    	JOIN menu
    	ON sales.product_id = menu.product_id
    	JOIN .members
    	ON members.customer_id = sales.customer_id
	GROUP BY
	sales.customer_id
	ORDER BY
	sales.customer_id;
/*
In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
 Same query as the last question, using SUM with CASE function, but this time limiting the date:

On Day -X to Day 1 (customer becomes member on Day 1 join_date), each $1 spent is 10 points and for sushi, each $1 spent is 20 points.
On Day 1 join_date to Day 7 valid_date, each $1 spent for all items is 20 points.
On Day 8 to last_day of Jan 2021, each $1 spent is 10 points and sushi is 2x points.

Answer:
customer_id	Points
A	        1370
B			940
Total points for Customer A is 1,370.
Total points for Customer B is 820.
*/
