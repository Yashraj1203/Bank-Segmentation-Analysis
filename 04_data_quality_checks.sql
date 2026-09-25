-- ============================================================
-- 04 - DATA QUALITY CHECKS
-- Purpose: validate the relational banking dataset before analysis.
-- MySQL 8+
-- ============================================================

-- 1. Row-count and relationship overview
SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers
UNION ALL
SELECT 'accounts', COUNT(*)
FROM accounts
UNION ALL
SELECT 'transactions', COUNT(*)
FROM transactions;

-- 2. Customer key completeness
SELECT
    COUNT(*) AS customer_rows,
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(name IS NULL OR TRIM(name) = '') AS missing_name,
    SUM(signup_date IS NULL) AS missing_signup_date,
    SUM(city IS NULL OR TRIM(city) = '') AS missing_city
FROM customers;

-- 3. Account key and attribute completeness
SELECT
    COUNT(*) AS account_rows,
    SUM(account_id IS NULL) AS missing_account_id,
    SUM(customer_id IS NULL) AS missing_customer_id,
    SUM(account_number IS NULL OR TRIM(account_number) = '') AS missing_account_number,
    SUM(account_type IS NULL) AS missing_account_type,
    SUM(open_date IS NULL) AS missing_open_date
FROM accounts;

-- 4. Transaction key and attribute completeness
SELECT
    COUNT(*) AS transaction_rows,
    SUM(transaction_id IS NULL) AS missing_transaction_id,
    SUM(account_id IS NULL) AS missing_account_id,
    SUM(transaction_date IS NULL) AS missing_transaction_date,
    SUM(amount IS NULL) AS missing_amount,
    SUM(transaction_type IS NULL OR TRIM(transaction_type) = '') AS missing_transaction_type
FROM transactions;

-- 5. Orphaned accounts: every account should reference a customer.
SELECT COUNT(*) AS orphaned_accounts
FROM accounts a
LEFT JOIN customers c
    ON a.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 6. Orphaned transactions: every transaction should reference an account.
SELECT COUNT(*) AS orphaned_transactions
FROM transactions t
LEFT JOIN accounts a
    ON t.account_id = a.account_id
WHERE a.account_id IS NULL;

-- 7. Duplicate account numbers.
SELECT
    account_number,
    COUNT(*) AS occurrences
FROM accounts
GROUP BY account_number
HAVING COUNT(*) > 1
ORDER BY occurrences DESC, account_number;

-- 8. Unexpected transaction types.
SELECT
    transaction_type,
    COUNT(*) AS transaction_count
FROM transactions
GROUP BY transaction_type
ORDER BY transaction_count DESC;

-- 9. Non-positive transaction amounts.
SELECT COUNT(*) AS non_positive_transactions
FROM transactions
WHERE amount <= 0;

-- 10. Future-dated transactions.
SELECT COUNT(*) AS future_transactions
FROM transactions
WHERE transaction_date > CURDATE();

-- 11. Negative account balances.
-- This is a validation flag rather than an automatic error because
-- negative balances can be legitimate in some account products.
SELECT COUNT(*) AS negative_balance_accounts
FROM accounts
WHERE balance < 0;

-- 12. Account-level transaction coverage.
SELECT
    COUNT(*) AS total_accounts,
    COUNT(DISTINCT t.account_id) AS accounts_with_transactions,
    COUNT(*) - COUNT(DISTINCT t.account_id) AS accounts_without_transactions
FROM accounts a
LEFT JOIN transactions t
    ON a.account_id = t.account_id;

-- 13. Customer-level transaction coverage.
SELECT
    COUNT(*) AS total_customers,
    COUNT(DISTINCT a.customer_id) AS customers_with_accounts,
    COUNT(DISTINCT CASE WHEN t.transaction_id IS NOT NULL THEN a.customer_id END)
        AS customers_with_transactions
FROM customers c
LEFT JOIN accounts a
    ON c.customer_id = a.customer_id
LEFT JOIN transactions t
    ON a.account_id = t.account_id;
