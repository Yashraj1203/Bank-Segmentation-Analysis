-- ============================================================
-- 06 - CUSTOMER SEGMENTATION
-- Purpose: assign customer value, engagement, and product-depth
-- segments from the customer feature layer.
-- MySQL 8+
-- ============================================================

WITH customer_features AS (
    SELECT
        ca.customer_id,
        ca.name,
        ca.gender,
        ca.city,
        ca.account_count,
        ca.product_count,
        ca.relationship_balance,
        COALESCE(ct.transaction_count, 0) AS transaction_count,
        COALESCE(ct.total_credit, 0) AS total_credit,
        COALESCE(ct.total_debit, 0) AS total_debit,
        COALESCE(ct.avg_transaction_value, 0) AS avg_transaction_value,
        COALESCE(ct.active_months, 0) AS active_months,
        ct.last_transaction_date,
        COALESCE(ct.salary_transaction_count, 0) AS salary_transaction_count,
        COALESCE(ct.salary_credit_amount, 0) AS salary_credit_amount
    FROM (
        SELECT
            c.customer_id,
            c.name,
            c.gender,
            c.city,
            COUNT(DISTINCT a.account_id) AS account_count,
            COUNT(DISTINCT a.account_type) AS product_count,
            COALESCE(SUM(a.balance), 0) AS relationship_balance
        FROM customers c
        LEFT JOIN accounts a
            ON c.customer_id = a.customer_id
        GROUP BY
            c.customer_id,
            c.name,
            c.gender,
            c.city
    ) ca
    LEFT JOIN (
        SELECT
            c.customer_id,
            COUNT(t.transaction_id) AS transaction_count,
            COALESCE(SUM(CASE
                WHEN t.transaction_type = 'credit' THEN t.amount
                ELSE 0
            END), 0) AS total_credit,
            COALESCE(SUM(CASE
                WHEN t.transaction_type = 'debit' THEN t.amount
                ELSE 0
            END), 0) AS total_debit,
            COALESCE(AVG(t.amount), 0) AS avg_transaction_value,
            COUNT(DISTINCT DATE_FORMAT(t.transaction_date, '%Y-%m')) AS active_months,
            MAX(t.transaction_date) AS last_transaction_date,
            SUM(CASE
                WHEN t.transaction_type = 'credit'
                 AND LOWER(t.description) LIKE '%salary%'
                THEN 1
                ELSE 0
            END) AS salary_transaction_count,
            COALESCE(SUM(CASE
                WHEN t.transaction_type = 'credit'
                 AND LOWER(t.description) LIKE '%salary%'
                THEN t.amount
                ELSE 0
            END), 0) AS salary_credit_amount
        FROM customers c
        LEFT JOIN accounts a
            ON c.customer_id = a.customer_id
        LEFT JOIN transactions t
            ON a.account_id = t.account_id
        GROUP BY c.customer_id
    ) ct
        ON ca.customer_id = ct.customer_id
),

value_ranked AS (
    SELECT
        cf.*,
        NTILE(3) OVER (
            ORDER BY cf.total_credit
        ) AS value_tile
    FROM customer_features cf
)

SELECT
    customer_id,
    name,
    gender,
    city,
    account_count,
    product_count,
    relationship_balance,
    total_credit,
    total_debit,
    transaction_count,
    avg_transaction_value,
    active_months,
    last_transaction_date,
    salary_transaction_count,
    salary_credit_amount,

    CASE
        WHEN value_tile = 3 THEN 'High Value'
        WHEN value_tile = 2 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_segment,

    CASE
        WHEN last_transaction_date IS NULL THEN 'Dormant'
        WHEN last_transaction_date >= CURDATE() - INTERVAL 90 DAY
            THEN 'Active'
        WHEN last_transaction_date >= CURDATE() - INTERVAL 365 DAY
            THEN 'Low Activity'
        ELSE 'Dormant'
    END AS engagement_segment,

    CASE
        WHEN product_count > 1 THEN 'Multi Product'
        ELSE 'Single Product'
    END AS product_segment

FROM value_ranked
ORDER BY
    value_segment,
    engagement_segment,
    customer_id;
