Create database Zomato;
use zomato;
drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup (
    user_id INT,
    gold_signup_date DATE
);
Insert into goldusers_signup values(1,'2017-09-22'),(3,'2017-04-21');
drop table if exists users;
CREATE TABLE users (
    user_id INT,
    signup_date DATE
);
Insert into USERS values(1,'2014-09-02'),(2,'2015-01-15'),(3,'2014-04-11');
drop table if exists sales;
CREATE TABLE sales (
    user_id INT,
    created_date DATE,product_id int
);
INSERT INTO sales values(3,'2019-12-18',1),(2,'2020-07-20',3),(1,'2019-10-23',2),(1,'2018-03-19',3),(3,'2016-12-20',2),(1,'2016-11-09',1),(1,'2016-05-20',3),(2,'2017-09-24',1),(1,'2017-03-11',2),(1,'2016-03-11',1),(3,'2016-11-10',1),(3,'2017-12-07',2),(3,'2016-12-15',2),(2,'2017-11-08',2),(2,'2018-09-10',3);
drop table if exists product;
CREATE TABLE product (
    product_id INT,
   product_name varchar(255),price int
);
Insert into product values(1,'P1',980),(2,'P2',870),(3,'P3',330);
SELECT * FROM GOLDUSERS_SIGNUP;
SELECT * FROM PRODUCT;
SELECT * FROM SALES;
SELECT * FROM USERS;
# what is the total amount each customer spent on zomato
SELECT 
    s.user_id, SUM(p.price) AS total_price
FROM
    sales AS s
         JOIN
    product AS p ON s.product_id = p.product_id
GROUP BY s.user_id 
ORDER BY s.user_id;


# how many days each customer visited zomato?
SELECT 
    user_id, COUNT(DISTINCT (created_date))
FROM
    sales
GROUP BY user_id;


# what was the first product purchased by the each of the customer?
select * from (select s.product_id,s.user_id,s.created_date,rank() over(partition by user_id order by created_date asc) as ranking from product p join sales s on p.product_id = s.product_id)as a
where ranking = 1;


# what is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
    p.product_name,s.product_id, COUNT(s.product_id) AS number_of_purchase
FROM
    product p
         JOIN
    sales s ON p.product_id = s.product_id
    group by p.product_name,s.product_id
    order by COUNT(s.product_id) desc
    limit 1;
    
SELECT 
    user_id,count(product_id) as total_times
FROM
    sales
WHERE
    product_id = (SELECT 
            product_id
        FROM
            sales
        GROUP BY product_id
        ORDER BY COUNT(product_id) DESC
        LIMIT 1)
group by user_id ;

# which item was the most famous item for each of the customer?
select * from (select *, rank() over(partition by user_id order by cnt desc) rnk from (SELECT 
    user_id, product_id, COUNT(product_id) as cnt
FROM
    sales
GROUP BY user_id , product_id) as a ) as b
where rnk= 1 ;

# which item was purchased first by the customer after they became a member?
with cte as(SELECT 
    g.user_id, s.created_date, product_id,g.gold_signup_date, rank() over(partition by user_id order by created_date asc) as purchase
FROM
    goldusers_signup g
        LEFT JOIN
    sales s ON g.user_id = s.user_id
WHERE
    gold_signup_date <= created_date)
SELECT 
    user_id, created_date, product_id,gold_signup_date
FROM
    cte
WHERE
    purchase = 1;
    
    
# which item was purchased juct before the customer become a member
 with cte as(SELECT 
    g.user_id, s.created_date, product_id,g.gold_signup_date, rank() over(partition by user_id order by created_date desc) as purchase
FROM
    goldusers_signup g
        LEFT JOIN
    sales s ON g.user_id = s.user_id
WHERE
    gold_signup_date >= created_date)
SELECT 
    user_id, created_date, product_id,gold_signup_date
FROM
    cte
WHERE
    purchase = 1;
    
# what is the total orders and amount spent for each member before they became a member?
SELECT 
    g.user_id,count(s.created_date) as num_purchase,
    sum(p.price) as total_amount
FROM
    goldusers_signup g
        JOIN
    sales s ON g.user_id = s.user_id join product p on p.product_id = s.product_id
    WHERE
    gold_signup_date >= created_date
    group by g.user_id
    order by sum(p.price) desc;
    
    
# buying each product generates zomato points for each prouct i.e p1 = 5rs=1, p2 = 2rs=1, p3 5rs = 1
select *, rank() over(order by zomato_points desc) as rnk from(SELECT 
    product_name, SUM(points) as zomato_points
FROM
    (SELECT 
        a.*,
            CASE
                WHEN product_name = 'P1' THEN ROUND(amt / 5 * 1)
                WHEN product_name = 'P2' THEN ROUND(amt / 2 * 1)
                WHEN product_name = 'P3' THEN ROUND(amt / 5 * 1)
                ELSE 0
            END AS Points
    FROM
        (SELECT 
        s.user_id, p.product_name, SUM(p.price) AS amt
    FROM
        sales s
    JOIN product p ON p.product_id = s.product_id
    GROUP BY s.user_id , p.product_name
    ORDER BY s.user_id) a) b
GROUP BY product_name)c
limit 1;

# in the first one year after a customer joins the gold program(including their join date) irrespective of what the customer has purchased they
# earn 5 zomato points for every 10rs spent who earned more 1 or 3 and what was their points earnings in their first year?
SELECT 
    user_id, round(SUM(price)*0.5) as firstyear_points
FROM
    (SELECT 
        s.user_id,
            EXTRACT(YEAR FROM gold_signup_date) AS join_year,
            EXTRACT(YEAR FROM created_date) AS purchased_year,
            p.price
    FROM
        GOLDUSERS_SIGNUP g
    JOIN sales s ON g.user_id = s.user_id
    JOIN product p ON s.product_id = p.product_id) AS a
WHERE
    join_year = 2017
        AND purchased_year = 2017
GROUP BY user_id;

#rank all the transactions for each member whenever they are a zomato gold member for every non gold member transactionmark as na

select *, case when gold_signup_date IS NULL then 'NA' else rank() over(partition by user_id order by created_date desc) end as rnk from
 (SELECT 
    s.user_id,s.created_date,s.product_id,g.gold_signup_date
FROM
    sales s
        LEFT JOIN
    goldusers_signup g ON s.user_id = g.user_id and created_date >= gold_signup_date)a;