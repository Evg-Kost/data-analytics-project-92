select COUNT(customer_id) as customers_count from customers; --подсчет покупателей
--топ 10 продавцов по выручке
select 
	e.first_name || ' ' || e.last_name as seller,
	COUNT(*) as operations,
	floor(SUM(s.quantity * p.price)) as income
from employees e
inner join sales s on
	e.employee_id  = s.sales_person_id
inner join products p on
	s.product_id = p.product_id 
group by seller
order by SUM(s.quantity * p.price) desc
limit 10
;

--продавцы с наименьшим средним чеком 
with avg_sellers as(select 
	e.first_name || ' ' || e.last_name as seller,
	floor(AVG(s.quantity * p.price)) as average_income,
	AVG(AVG(s.quantity * p.price)) OVER() avg_average_income
from employees e
inner join sales s on
	e.employee_id  = s.sales_person_id
inner join products p on
	s.product_id = p.product_id 
group by e.employee_id, seller
order by average_income)
select 
	seller,
	average_income 
from avg_sellers 
where average_income < avg_average_income 
;

--продажи продавцов по дням недели

	e.first_name || ' ' || e.last_name as seller,
	TRIM(TO_CHAR(s.sale_date, 'day')) as day_of_week,
	floor(SUM(p.price * s.quantity)) as income
from employees e
inner join sales s on
	e.employee_id  = s.sales_person_id
inner join products p on
	s.product_id = p.product_id 
group by e.employee_id, seller, day_of_week, EXTRACT(ISODOW from s.sale_date)
order by EXTRACT(ISODOW from s.sale_date), seller;

--разбиение покупателей на группы по возрастам
SELECT 
    CASE 
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
        ELSE 'Другое'
    END as age_category,
    COUNT(*) as age_count
FROM customers
WHERE age IS NOT NULL 
    AND age >= 16  -- исключаем младше 16, если нужно
GROUP BY 
    CASE 
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
        ELSE 'Другое'
    END
order by age_category;

--уникальные покупатели и выручка по месяцам
select
	to_char(sale_date, 'yyyy-mm') as selling_month,
	count(distinct customer_id) as total_customers,
	floor(sum(quantity * price)) as income
from sales
inner join products on
	sales.product_id = products.product_id
group by to_char(sale_date, 'yyyy-mm')
order by selling_month;
--первая покупка по акции для покупателя
with tab as (select
	c.first_name || ' ' || c.last_name as customer,
	s.customer_id,
	s.sale_date as sale_date,
	e.first_name || ' ' || e.last_name as seller,
	p.price,
	row_number() over(partition by c.first_name || ' ' || c.last_name order by s.sale_date) as rn
from sales s
inner join customers c on
s.customer_id = c.customer_id
inner join employees e on
s.sales_person_id = e.employee_id
inner join products p on 
s.product_id = p.product_id 
where p.price = 0
order by s.customer_id)
select 
	customer,
	sale_date,
	seller
from tab
where rn = 1
