SELECT COUNT(customer_id) AS customers_count
FROM customers;

-- топ 10 продавцов по выручке
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    COUNT(*) AS operations,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM
    employees AS e
INNER JOIN sales AS s
    ON e.employee_id = s.sales_person_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    seller
ORDER BY
    SUM(s.quantity * p.price) DESC
LIMIT 10;

-- продавцы с наименьшим средним чеком
WITH avg_sellers AS (
    SELECT
        e.first_name || ' ' || e.last_name AS seller,
        FLOOR(AVG(s.quantity * p.price)) AS average_income,
        AVG(AVG(s.quantity * p.price)) OVER () AS avg_average_income
    FROM
        employees AS e
    INNER JOIN sales AS s
        ON e.employee_id = s.sales_person_id
    INNER JOIN products AS p
        ON s.product_id = p.product_id
    GROUP BY
        e.employee_id,
        seller
    ORDER BY
        average_income
)

SELECT
    seller,
    average_income
FROM
    avg_sellers
WHERE
    average_income < avg_average_income;

-- продажи продавцов по дням недели
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    TRIM(TO_CHAR(s.sale_date, 'day')) AS day_of_week,
    FLOOR(SUM(p.price * s.quantity)) AS income
FROM
    employees AS e
INNER JOIN sales AS s
    ON e.employee_id = s.sales_person_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    e.employee_id,
    seller,
    day_of_week,
    EXTRACT(ISODOW FROM s.sale_date)
ORDER BY
    EXTRACT(ISODOW FROM s.sale_date),
    seller;

-- разбиение покупателей на группы 
-- по возрастам
SELECT
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
        ELSE 'Другое'
    END AS age_category,
    COUNT(*) AS age_count
FROM
    customers
WHERE
    age IS NOT NULL
    AND age >= 16 -- исключаем младше 16, если нужно
GROUP BY
    CASE
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
        ELSE 'Другое'
    END
ORDER BY
    age_category;

-- уникальные покупатели и 
-- выручка по месяцам
SELECT
    TO_CHAR(s.sale_date, 'yyyy-mm') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM
    sales AS s
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    TO_CHAR(s.sale_date, 'yyyy-mm')
ORDER BY
    selling_month;

-- первая покупка по акции для покупателя
WITH tab AS (
    SELECT
        s.customer_id,
        s.sale_date,
        p.price,
        c.first_name || ' ' || c.last_name AS customer,
        e.first_name || ' ' || e.last_name AS seller,
        ROW_NUMBER() OVER (
            PARTITION BY c.first_name || ' ' || c.last_name
            ORDER BY s.sale_date
        ) AS rn
    FROM
        sales AS s
    INNER JOIN customers AS c
        ON s.customer_id = c.customer_id
    INNER JOIN employees AS e
        ON s.sales_person_id = e.employee_id
    INNER JOIN products AS p
        ON s.product_id = p.product_id
    WHERE
        p.price = 0
    ORDER BY
        s.customer_id
)

SELECT
    customer,
    sale_date,
    seller
FROM
    tab
WHERE
    rn = 1;
