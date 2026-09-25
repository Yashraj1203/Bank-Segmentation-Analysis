-- ============================================================
-- 03 - BANKING CUSTOMER & TRANSACTION ANALYSIS
-- MySQL 8+
-- ============================================================

-- 1. Total Debit Spend Per Customer
SELECT
    c.customer_id,
    c.name,
    SUM(t.amount) AS total_spent
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
JOIN transactions t
    ON a.account_id = t.account_id
WHERE t.transaction_type = 'debit'
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC;

-- 2. Salary Credit Trend — Last 12 Months
SELECT
    DATE_FORMAT(t.transaction_date, '%Y-%m') AS month,
    SUM(t.amount) AS total_salary_credited
FROM transactions t
WHERE t.transaction_type = 'credit'
  AND LOWER(t.description) LIKE '%salary%'
  AND t.transaction_date >= CURDATE() - INTERVAL 12 MONTH
GROUP BY month
ORDER BY month;

-- 3. Most Active Accounts by Transaction Count
SELECT
    t.account_id,
    c.name,
    COUNT(*) AS transaction_count
FROM transactions t
JOIN accounts a
    ON t.account_id = a.account_id
JOIN customers c
    ON a.customer_id = c.customer_id
GROUP BY t.account_id, c.name
ORDER BY transaction_count DESC
LIMIT 10;

-- 4. Most Active Accounts by Transaction Volume
SELECT
    t.account_id,
    c.name,
    a.account_number,
    COUNT(*) AS transaction_count,
    SUM(t.amount) AS total_transaction_volume,
    ROUND(AVG(t.amount), 2) AS avg_transaction_size,
    SUM(CASE WHEN t.transaction_type = 'debit' THEN 1 ELSE 0 END) AS debit_count,
    SUM(CASE WHEN t.transaction_type = 'credit' THEN 1 ELSE 0 END) AS credit_count,
    SUM(CASE WHEN t.transaction_type = 'debit' THEN t.amount ELSE 0 END) AS total_debit_volume,
    SUM(CASE WHEN t.transaction_type = 'credit' THEN t.amount ELSE 0 END) AS total_credit_volume
FROM transactions t
JOIN accounts a
    ON t.account_id = a.account_id
JOIN customers c
    ON a.customer_id = c.customer_id
GROUP BY t.account_id, c.name, a.account_number
ORDER BY total_transaction_volume DESC
LIMIT 10;

-- 5. Monthly Transaction Breakdown
SELECT
    DATE_FORMAT(t.transaction_date, '%Y-%m') AS month,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN t.transaction_type = 'debit' THEN 1 ELSE 0 END) AS debit_count,
    SUM(CASE WHEN t.transaction_type = 'credit' THEN 1 ELSE 0 END) AS credit_count,
    SUM(CASE WHEN t.transaction_type = 'debit' THEN t.amount ELSE 0 END) AS total_debit_volume,
    SUM(CASE WHEN t.transaction_type = 'credit' THEN t.amount ELSE 0 END) AS total_credit_volume,
    SUM(t.amount) AS total_transaction_volume,
    ROUND(AVG(t.amount), 2) AS avg_transaction_size
FROM transactions t
GROUP BY DATE_FORMAT(t.transaction_date, '%Y-%m')
ORDER BY month;

-- 6. Yearly Transaction Breakdown
SELECT
    YEAR(t.transaction_date) AS year,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN t.transaction_type = 'debit' THEN 1 ELSE 0 END) AS debit_count,
    SUM(CASE WHEN t.transaction_type = 'credit' THEN 1 ELSE 0 END) AS credit_count,
    SUM(CASE WHEN t.transaction_type = 'debit' THEN t.amount ELSE 0 END) AS total_debit_volume,
    SUM(CASE WHEN t.transaction_type = 'credit' THEN t.amount ELSE 0 END) AS total_credit_volume,
    SUM(t.amount) AS total_transaction_volume,
    ROUND(AVG(t.amount), 2) AS avg_transaction_size
FROM transactions t
GROUP BY YEAR(t.transaction_date)
ORDER BY year;

-- 7. Top 20 Customers by Total Credit Inflows
SELECT
    c.customer_id,
    c.name,
    c.gender,
    c.city,
    COUNT(t.transaction_id) AS credit_transaction_count,
    SUM(t.amount) AS total_credits
FROM transactions t
JOIN accounts a
    ON t.account_id = a.account_id
JOIN customers c
    ON a.customer_id = c.customer_id
WHERE t.transaction_type = 'credit'
GROUP BY c.customer_id, c.name, c.gender, c.city
ORDER BY total_credits DESC
LIMIT 20;

-- 8. Dormant Customers — No Transaction in the Last 12 Months
WITH customer_activity AS (
    SELECT
        c.customer_id,
        c.name,
        c.gender,
        c.city,
        MAX(t.transaction_date) AS last_transaction_date
    FROM customers c
    LEFT JOIN accounts a
        ON c.customer_id = a.customer_id
    LEFT JOIN transactions t
        ON a.account_id = t.account_id
    GROUP BY c.customer_id, c.name, c.gender, c.city
)
SELECT
    customer_id,
    name,
    gender,
    city,
    last_transaction_date
FROM customer_activity
WHERE last_transaction_date IS NULL
   OR last_transaction_date < CURDATE() - INTERVAL 12 MONTH
ORDER BY last_transaction_date;

-- 9. Single-Product Customers
-- Product depth is based on distinct account types, not raw account rows.
SELECT
    c.customer_id,
    c.name,
    COUNT(DISTINCT a.account_type) AS product_count,
    COUNT(a.account_id) AS account_count
FROM customers c
JOIN accounts a
    ON c.customer_id = a.customer_id
GROUP BY c.customer_id, c.name
HAVING COUNT(DISTINCT a.account_type) = 1
ORDER BY c.customer_id;

-- 10. Most Used Transaction Services
SELECT
    description,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_amount
FROM transactions
GROUP BY description
ORDER BY transaction_count DESC;

-- 11. City-Level Customer and Transaction Performance
SELECT
    c.city,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT a.account_id) AS total_accounts,
    COUNT(t.transaction_id) AS total_transactions,
    COALESCE(SUM(t.amount), 0) AS total_transaction_amount,
    ROUND(AVG(t.amount), 2) AS avg_transaction_amount
FROM customers c
LEFT JOIN accounts a
    ON c.customer_id = a.customer_id
LEFT JOIN transactions t
    ON a.account_id = t.account_id
GROUP BY c.city
ORDER BY total_transactions DESC;

-- 12. Account Engagement by City
-- First classify each account using its latest transaction, then aggregate.
WITH account_activity AS (
    SELECT
        a.account_id,
        a.customer_id,
        MAX(t.transaction_date) AS last_transaction_date
    FROM accounts a
    LEFT JOIN transactions t
        ON a.account_id = t.account_id
    GROUP BY a.account_id, a.customer_id
)
SELECT
    c.city,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(aa.account_id) AS total_accounts,
    SUM(CASE
        WHEN aa.last_transaction_date >= CURDATE() - INTERVAL 12 MONTH
        THEN 1 ELSE 0
    END) AS active_accounts,
    SUM(CASE
        WHEN aa.last_transaction_date IS NULL
          OR aa.last_transaction_date < CURDATE() - INTERVAL 12 MONTH
        THEN 1 ELSE 0
    END) AS dormant_accounts
FROM customers c
LEFT JOIN account_activity aa
    ON c.customer_id = aa.customer_id
GROUP BY c.city
ORDER BY total_customers DESC;

-- 13. Highest Spender by City
WITH customer_spending AS (
    SELECT
        c.customer_id,
        c.name,
        c.city,
        SUM(t.amount) AS total_spent
    FROM customers c
    JOIN accounts a
        ON c.customer_id = a.customer_id
    JOIN transactions t
        ON a.account_id = t.account_id
    WHERE t.transaction_type = 'debit'
    GROUP BY c.customer_id, c.name, c.city
),
ranked_spending AS (
    SELECT
        city,
        name,
        total_spent,
        ROW_NUMBER() OVER (
            PARTITION BY city
            ORDER BY total_spent DESC
        ) AS rn
    FROM customer_spending
)
SELECT
    city,
    name,
    total_spent
FROM ranked_spending
WHERE rn = 1
ORDER BY city;
