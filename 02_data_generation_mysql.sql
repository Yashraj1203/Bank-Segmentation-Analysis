-- ============================================================
-- PART 1 - DATA GENERATION - Creates:
-- 1. Helper Tables
-- 2. Random Customers (200)
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS first_names;
DROP TABLE IF EXISTS last_names;
DROP TABLE IF EXISTS cities;

SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE first_names(
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(40)
);

INSERT INTO first_names(name) VALUES
('Chinedu'),('Aisha'),('Tunde'),('Ngozi'),('Bola'),('Obinna'),('Fatima'),('Yakubu'),
('Emeka'),('Zainab'),('Ifeanyi'),('Uche'),('Abubakar'),('Lilian'),('Segun'),('Halima'),
('Adesuwa'),('Kehinde'),('Mercy'),('Emmanuel');


CREATE TABLE last_names(
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(40)
);

INSERT INTO last_names(name) VALUES
('Okonkwo'),('Balogun'),('Adegoke'),('Nwachukwu'),('Danjuma'),('Adelaja'),('Ibrahim'),
('Umeh'),('Ogunleye'),('Abiola'),('Mohammed'),('Eze'),('Lawal'),('Obi'),('Ahmed'),('Onyeka'),
('Nwabueze'),('Ajibade'),('Suleman'),('Johnson');


CREATE TABLE cities(
    id INT AUTO_INCREMENT PRIMARY KEY,
    city VARCHAR(40)
);

INSERT INTO cities(city) VALUES
('Lagos'),('Abuja'),('Port Harcourt'),('Enugu'),('Kano'),('Ibadan'),('Jos'),('Abeokuta'),
('Calabar'),('Owerri'),('Benin City'),('Kaduna');


DELIMITER $$

DROP PROCEDURE IF EXISTS generate_customers $$

CREATE PROCEDURE generate_customers()
BEGIN

DECLARE i INT DEFAULT 1;   

WHILE i <= 200 DO

INSERT INTO customers
(
    name,
    gender,
    dob,
    signup_date,
    city
)
VALUES
(
    CONCAT(
        (SELECT name FROM first_names ORDER BY RAND() LIMIT 1),
        ' ',
        (SELECT name FROM last_names ORDER BY RAND() LIMIT 1)
    ),

    IF(RAND()<0.5,'M','F'),

    DATE_ADD('1970-01-01', INTERVAL FLOOR(RAND()*10000) DAY),

    DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND()*1095) DAY),

    (SELECT city FROM cities ORDER BY RAND() LIMIT 1)
);

SET i = i + 1;

END WHILE;

END$$

DELIMITER ;

CALL generate_customers();

DROP PROCEDURE generate_customers;


SELECT COUNT(*) AS total_customers FROM customers;

SELECT * FROM customers LIMIT 10;


-- ============================================================
-- PART 2 - ACCOUNT GENERATION
-- Generates 1-3 accounts per customer
-- ============================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS generate_accounts $$

CREATE PROCEDURE generate_accounts()
BEGIN

    DECLARE done INT DEFAULT FALSE;
    DECLARE v_customer INT;

    DECLARE account_count INT;
    DECLARE i INT;

    DECLARE acc_type VARCHAR(30);
    DECLARE opening DATE;
    DECLARE bal DECIMAL(12,2);

    DECLARE cur CURSOR FOR
        SELECT customer_id FROM customers;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET done = TRUE;

    OPEN cur;

    customer_loop: LOOP

        FETCH cur INTO v_customer;

        IF done THEN
            LEAVE customer_loop;
        END IF;

        SET account_count = FLOOR(RAND()*3)+1;

        SET i = 1;

        WHILE i <= account_count DO

            SET acc_type =
            CASE FLOOR(RAND()*3)
                WHEN 0 THEN 'savings'
                WHEN 1 THEN 'current'
                ELSE 'loan'
            END;

            SET opening =
                DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND()*1460) DAY);

            IF acc_type='savings' THEN
                SET bal = ROUND(5000 + RAND()*495000,2);

            ELSEIF acc_type='current' THEN
                SET bal = ROUND(10000 + RAND()*990000,2);

            ELSE
                SET bal = ROUND(50000 + RAND()*4950000,2);
            END IF;

            INSERT INTO accounts
            (
                customer_id,
                account_number,
                account_type,
                open_date,
                balance
            )
            VALUES
            (
                v_customer,
                CONCAT(FLOOR(1000000000 + RAND()*9000000000)),
                acc_type,
                opening,
                bal
            );

            SET i = i + 1;

        END WHILE;

    END LOOP;

    CLOSE cur;

END$$

DELIMITER ;

CALL generate_accounts();

DROP PROCEDURE generate_accounts;


SELECT COUNT(*) AS TotalAccounts FROM accounts;

SELECT account_type, COUNT(*) AS NumberOfAccounts
FROM accounts
GROUP BY account_type;

SELECT * FROM accounts LIMIT 20;

-- ============================================================
-- PART 3 - TRANSACTION GENERATION
-- Generates 2,000 realistic banking transactions
-- ============================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS generate_transactions $$

CREATE PROCEDURE generate_transactions()
BEGIN

DECLARE i INT DEFAULT 1;
DECLARE total_accounts INT;
DECLARE rand_account INT;
DECLARE rand_amount DECIMAL(12,2);
DECLARE rand_type VARCHAR(20);
DECLARE rand_desc VARCHAR(50);
DECLARE rand_date DATE;

SELECT COUNT(*) INTO total_accounts FROM accounts;

WHILE i<=2000 DO

SET rand_account = (SELECT account_id FROM accounts ORDER BY RAND() LIMIT 1);

IF RAND()<0.45 THEN

    SET rand_type='credit';

    CASE FLOOR(RAND()*4)
        WHEN 0 THEN SET rand_desc='Salary credited';   -- FIX: matches Query 2's LIKE filter
        WHEN 1 THEN SET rand_desc='Cash Deposit';
        WHEN 2 THEN SET rand_desc='Transfer In';
        ELSE SET rand_desc='Interest';
    END CASE;

    SET rand_amount = ROUND(10000+(RAND()*490000),2);

ELSE

    SET rand_type='debit';

    CASE FLOOR(RAND()*8)
        WHEN 0 THEN SET rand_desc='POS Purchase';
        WHEN 1 THEN SET rand_desc='ATM Withdrawal';
        WHEN 2 THEN SET rand_desc='Transfer';
        WHEN 3 THEN SET rand_desc='Utility Bill';
        WHEN 4 THEN SET rand_desc='Airtime';
        WHEN 5 THEN SET rand_desc='Online Shopping';
        WHEN 6 THEN SET rand_desc='Loan Payment';
        ELSE SET rand_desc='Restaurant';
    END CASE;

    SET rand_amount = ROUND(100+(RAND()*150000),2);

END IF;

SET rand_date = DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND()*1095) DAY);

INSERT INTO transactions
(
    account_id,
    transaction_date,
    amount,
    transaction_type,
    description
)
VALUES
(
    rand_account,
    rand_date,
    rand_amount,
    rand_type,
    rand_desc
);

UPDATE accounts
SET balance =
CASE
    WHEN rand_type='credit' THEN balance+rand_amount
    ELSE balance-rand_amount
END
WHERE account_id=rand_account;

SET i=i+1;

END WHILE;

END$$

DELIMITER ;

CALL generate_transactions();

DROP PROCEDURE generate_transactions;



SELECT COUNT(*) AS TotalTransactions FROM transactions;

SELECT transaction_type, COUNT(*) AS NumberOfTransactions, SUM(amount) AS TotalAmount
FROM transactions
GROUP BY transaction_type;

SELECT description, COUNT(*) AS Frequency
FROM transactions
GROUP BY description
ORDER BY Frequency DESC;

SELECT * FROM transactions LIMIT 20;

