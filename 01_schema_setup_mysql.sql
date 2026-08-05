CREATE TABLE customers (
 customer_id INT AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(100) NOT NULL,
 gender CHAR(1),
 dob DATE,
 signup_date DATE NOT NULL,
 city VARCHAR(100)
);

CREATE TABLE accounts (
 account_id INT AUTO_INCREMENT PRIMARY KEY,
 customer_id INT,
 account_type ENUM('savings','current','loan'),
 open_date DATE NOT NULL,
 balance DECIMAL(12,2) DEFAULT 0,
 account_number VARCHAR(30),
 FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE transactions (
 transaction_id INT AUTO_INCREMENT PRIMARY KEY,
 account_id INT,
 transaction_date DATE NOT NULL,
 amount DECIMAL(12,2) NOT NULL,
 transaction_type VARCHAR(20),
 description VARCHAR(50),
 FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);
