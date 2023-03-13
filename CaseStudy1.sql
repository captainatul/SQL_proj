create schema db
use db 
drop table  sales
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
 
 drop table menu
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
  
  drop table members
CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

  select * from sales
  select * from menu
  select * from members


 -- 1. What is the total amount each customer spent at the restaurant?

 SELECT s.customer_id , SUM(price) as total_amount_spend 
 from sales s join menu m on s.product_id=m.product_id
 group by s.customer_id

 -- 2. How many days has each customer visited the restaurant?

 select customer_id , COUNT(distinct order_date) AS no_of_distinct_days FROM sales 
 group by customer_id

 -- 3. What was the first item from the menu purchased by each customer?
 
 with cte as ( 
 select * , dense_rank () over (PARTITION by customer_id order by order_date) as dr from sales ) 

 select c.customer_id , m.product_name from cte c left join menu m on c.product_id = m.product_id
 where dr = 1
 group by c.customer_id , m.product_name
 
 -- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
 
 select top 1 product_id , COUNT(product_id) from sales
 group by product_id 
 order by product_id desc 
 
 -- 5. Which item was the most popular for each customer?
 
 with cte as (
 select s.customer_id, m.product_name , COUNT(m.product_id) as fav_items ,
 DENSE_RANK() over (partition by customer_id order by count(m.product_id)) as dr 
 from menu m  join sales s on m.product_id = s.product_id
GROUP BY s.customer_id, m.product_name
 )
 select * from cte 
 where dr=1

 -- 6. Which item was purchased first by the customer after they became a member?
 
 select * from sales
  select * from menu 
  select * from members

  with max_order as (
  select m.join_date,s.*,ROW_NUMBER()over(partition by s.customer_id order by order_date)  as rn
  from members m left join sales s on  s.order_date >= m.join_date and s.customer_id=m.customer_id ) 
  select customer_id,product_id from max_order 
  where rn = 1	

  -- 7. Which item was purchased just before the customer became a member?

  with just_before as (
  select m.join_date,s.*,dense_rank()over(partition by s.customer_id order by order_date desc)  as rn
  from members m left join sales s on   s.customer_id=m.customer_id  where s.order_date < m.join_date ) 
  select customer_id,product_id from just_before 
  where rn = 1	

  -- 8. What is the total items and amount spent for each member before they became a member?

  with total_items as (
		select  m.join_date,s.*
  from members m left join sales s on   s.customer_id=m.customer_id  where s.order_date < m.join_date ) ,
  rate as (
  select t.customer_id,   u.product_name, sum(u.price) as amount_spend from total_items t left join menu u on t.product_id=u.product_id 
  group by t.customer_id, u.product_name)

  select customer_id,COUNT(distinct product_name) as no_of_items ,sum(amount_spend) as total_amount_spend from rate
  group by customer_id

  -- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

  with cte as (
  select customer_id ,m.product_name, m.price , case when m.product_name = 'sushi' then 2*10*price else 10*price end as reward_point
  from sales s join  menu m on s.product_id=m.product_id )

  select customer_id , SUM(reward_point) as total_points from cte 
  group by customer_id
  
  -- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
         --not just sushi - how many points do customer A and B have at the end of January?

   WITH dates_cte AS 
 (
 SELECT *, 
  DATEADD(DAY, 6, join_date) AS valid_date, 
  EOMONTH('2021-01-31') AS last_date
 FROM members
 )
 /*,
 rates as (
 select s.customer_id ,s.order_date, u.product_name, u.price , 10*price as reward_ini
 from sales s join menu u on s.product_id = u.product_id 
 )
 select customer_id , case when order_date 
 */

 SELECT d.customer_id, s.order_date, d.join_date, 
 d.valid_date, d.last_date, m.product_name, m.price,
 SUM(CASE
  WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
  WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
  ELSE 10 * m.price
  END) AS points
FROM dates_cte AS d
JOIN sales AS s
 ON d.customer_id = s.customer_id
JOIN menu AS m
 ON s.product_id = m.product_id
WHERE s.order_date < d.last_date
GROUP BY d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date, m.product_name, m.price


