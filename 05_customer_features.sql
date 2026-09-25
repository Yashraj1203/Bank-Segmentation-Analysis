-- ============================================================
-- 05 - CUSTOMER FEATURE ENGINEERING
-- Purpose: create one reusable analytical row per customer.
-- MySQL 8+
-- ============================================================

WITH customer_accounts AS (
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
),

customer_transactions AS (
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
)

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
    COALESCE(ct.salary_credit_amount, 0) AS salary_credit_amount,
    ROUND(
        COALESCE(
            ct.total_credit / NULLIF(ct.total_debit, 0),
            0
        ),
        2
    ) AS credit_debit_ratio
FROM customer_accounts ca
LEFT JOIN customer_transactions ct
    ON ca.customer_id = ct.customer_id
ORDER BY ca.customer_id;
