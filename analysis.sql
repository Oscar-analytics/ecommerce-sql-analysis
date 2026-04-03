-- =========================================
-- E-COMMERCE SQL ANALYSIS PROJECT
-- =========================================

-- 1. TOTAL REVENUE
SELECT 
    SUM(oi.quantity * p.price) AS total_revenue
FROM order_items oi
JOIN products p 
ON oi.product_id = p.product_id;


-- 2. TOP 3 PRODUCT CATEGORIES BY REVENUE
SELECT 
    p.category,
    SUM(oi.quantity * p.price) AS total_revenue
FROM order_items oi
JOIN products p 
ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC 
LIMIT 3;


-- 3. TOP 5 CUSTOMERS BY SPENDING
SELECT 
    c.customer_id,
    c.customer_name,
    SUM(oi.quantity * p.price) AS total_spending
FROM orders o 
JOIN customers c ON o.customer_id = c.customer_id 
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spending DESC 
LIMIT 5;


-- 4. CUSTOMERS ABOVE AVERAGE SPENDING
WITH customer_spending AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity * p.price) AS total_spending
    FROM orders o 
    JOIN customers c ON o.customer_id = c.customer_id 
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT *
FROM customer_spending
WHERE total_spending > (
    SELECT AVG(total_spending) FROM customer_spending
);


-- 5. TOP CUSTOMER PER REGION
WITH customer_spending AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        o.region,
        SUM(oi.quantity * p.price) AS total_spending
    FROM orders o 
    JOIN customers c ON o.customer_id = c.customer_id 
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY c.customer_id, c.customer_name, o.region
),
ranked_customers AS (
    SELECT *,
        DENSE_RANK() OVER (
            PARTITION BY region 
            ORDER BY total_spending DESC
        ) AS rn
    FROM customer_spending
)
SELECT *
FROM ranked_customers
WHERE rn = 1;


-- 6. PARETO ANALYSIS (TOP 80% REVENUE CUSTOMERS)
WITH customer_spending AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        SUM(oi.quantity * p.price) AS total_spending
    FROM orders o 
    JOIN customers c ON o.customer_id = c.customer_id 
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY c.customer_id, c.customer_name
),
ranked_spending AS (
    SELECT *,
        SUM(total_spending) OVER (ORDER BY total_spending DESC) AS cumulative_spending,
        SUM(total_spending) OVER () AS total_revenue
    FROM customer_spending
)
SELECT 
    customer_id,
    customer_name,
    total_spending,
    ROUND((cumulative_spending / total_revenue) * 100, 2) AS cumulative_percentage
FROM ranked_spending
WHERE (cumulative_spending / total_revenue) <= 0.8;


-- 7. MONTHLY REVENUE + GROWTH
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(o.order_date, '%Y-%m') AS month,
        SUM(oi.quantity * p.price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    GROUP BY month
),
revenue_growth AS (
    SELECT 
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS previous_month,
        ROUND(
            ((revenue - LAG(revenue) OVER (ORDER BY month)) 
            / LAG(revenue) OVER (ORDER BY month)) * 100, 2
        ) AS growth_percentage
    FROM monthly_revenue
)
SELECT *
FROM revenue_growth;
