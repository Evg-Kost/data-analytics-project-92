select COUNT(customer_id) as customers_count from customers; --подсчет покупателей
--топ 10 продавцов по выручке
select 
	e.first_name || ' ' || e.last_name as seller,
	COUNT(*) as operation,
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
select 
	e.first_name || ' ' || e.last_name as seller,
	TO_CHAR(s.sale_date, 'day') as day_of_week,
	floor(SUM(p.price * s.quantity)) as income
from employees e
inner join sales s on
	e.employee_id  = s.sales_person_id
inner join products p on
	s.product_id = p.product_id 
group by e.employee_id, seller, day_of_week, EXTRACT(ISODOW from s.sale_date)
order by seller, EXTRACT(ISODOW from s.sale_date);