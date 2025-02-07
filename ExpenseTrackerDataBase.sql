CREATE DATABASE IF NOT EXISTS ExpenseTracker;
USE ExpenseTracker;

-- User Table
CREATE TABLE User (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone_number VARCHAR(15) NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('user', 'admin') DEFAULT 'user',
    password_reset_token VARCHAR(255) NULL,
    token_expiry TIMESTAMP NULL
);

-- Category Table
CREATE TABLE Category (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(100) NULL
);

-- Bank Table
CREATE TABLE Bank (
    bank_id INT PRIMARY KEY AUTO_INCREMENT,
    bank_name ENUM('Al Rajhi Bank', 'Saudi National Bank', 'Riyad Bank', 'Bank Albilad', 'Alinma Bank', 'Banque Saudi Fransi', 'Arab National Bank') NOT NULL UNIQUE,
    bank_url VARCHAR(255) NOT NULL
);

-- Linked Account Table
CREATE TABLE LinkedAccount (
    linked_account_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    bank_id INT NOT NULL,
    link_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES User(user_id),
    FOREIGN KEY (bank_id) REFERENCES Bank(bank_id)
);

-- Budget Table
CREATE TABLE Budget (
    budget_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    amount DECIMAL(10,2) NOT NULL,
    current_balance DECIMAL(10,2) NOT NULL,
    period_type ENUM('WEEKLY', 'MONTHLY', 'CUSTOM') NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status ENUM('active', 'expired', 'archived') DEFAULT 'active',
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

-- Expense Table
CREATE TABLE Expense (
    expense_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    category_id INT,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'SAR',
    exchange_rate DECIMAL(10,4) DEFAULT 1.0,
    payment_method ENUM('cash', 'credit', 'debit', 'other') DEFAULT 'cash',
    date DATE NOT NULL,
    notes VARCHAR(250) NULL,
    FOREIGN KEY (user_id) REFERENCES User(user_id),
    FOREIGN KEY (category_id) REFERENCES Category(category_id)
);

-- Income Table
CREATE TABLE Income (
    income_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    source VARCHAR(50) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'SAR',
    exchange_rate DECIMAL(10,4) DEFAULT 1.0,
    date DATE NOT NULL,
    notes VARCHAR(250),
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);

-- Notifications Table
CREATE TABLE Notifications (
    notification_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    type ENUM('warning', 'info', 'reminder') DEFAULT 'info',
    message VARCHAR(250) NOT NULL,
    status ENUM('unread', 'read') DEFAULT 'unread',
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES User(user_id)
);
DELIMITER //
-- Trigger to Update Budget Balance After Expense Insertion
CREATE TRIGGER after_expense_insert
AFTER INSERT ON Expense
FOR EACH ROW
BEGIN
    DECLARE new_balance DECIMAL(10,2);

    -- Lock the Budget row for the user to avoid concurrent updates (Row-level lock)
    SELECT current_balance
    INTO new_balance
    FROM Budget
    WHERE user_id = NEW.user_id AND status = 'active' AND CURDATE() BETWEEN start_date AND end_date
    FOR UPDATE;

    -- Deduct expense from current balance
    UPDATE Budget
    SET current_balance = current_balance - (NEW.amount * NEW.exchange_rate)
    WHERE user_id = NEW.user_id AND status = 'active' AND CURDATE() BETWEEN start_date AND end_date;

    -- Retrieve the updated balance
    SELECT current_balance INTO new_balance
    FROM Budget
    WHERE user_id = NEW.user_id AND status = 'active' AND CURDATE() BETWEEN start_date AND end_date;

    -- Trigger a notification if balance is negative
    IF new_balance < 0 THEN
        INSERT INTO Notifications (user_id, type, message, status, date)
        VALUES (NEW.user_id, 'warning', 'Warning: Amount exceeds budget', 'unread', NOW());
    END IF;
END //


DELIMITER ;

DELIMITER //
-- Trigger to Update Budget Balance After Income Insertion
CREATE TRIGGER after_income_insert
AFTER INSERT ON Income
FOR EACH ROW
BEGIN
    -- Lock the Budget row for the user to avoid concurrent updates (Row-level lock)
    UPDATE Budget
    SET current_balance = current_balance + (NEW.amount * NEW.exchange_rate)
    WHERE user_id = NEW.user_id AND status = 'active' AND CURDATE() BETWEEN start_date AND end_date;
END //



DELIMITER ;
-- Insert Saudi Banks and URLs
INSERT INTO Bank (bank_name, bank_url) VALUES
    ('Al Rajhi Bank', 'https://www.alrajhibank.com.sa'),
    ('Saudi National Bank', 'https://www.alahli.com'),
    ('Riyad Bank', 'https://www.riyadbank.com'),
    ('Bank Albilad', 'https://www.bankalbilad.com'),
    ('Alinma Bank', 'https://www.alinma.com'),
    ('Banque Saudi Fransi', 'https://www.alfransi.com.sa'),
    ('Arab National Bank', 'https://www.anb.com.sa');

-- Insert Users into User Table
INSERT INTO User (first_name, last_name, email, phone_number, password, role) VALUES
('Ahmed', 'Al-Fahad', 'ahmed.fahad@example.com', '+966500000001', 'password123', 'user'),
('Fatimah', 'Al-Saud', 'fatimah.saud@example.com', '+966500000002', 'password123', 'user'),
('Sami', 'Al-Mutairi', 'sami.mutairi@example.com', '+966500000003', 'password123', 'user'),
('Rashid', 'Al-Harbi', 'rashid.harbi@example.com', '+966500000004', 'password123', 'admin');

-- Insert Categories into Category Table
INSERT INTO Category (name, description) VALUES
('Food', 'Expenses related to food and dining'),
('Transportation', 'Expenses for transportation services such as taxis, fuel, etc.'),
('Entertainment', 'Expenses related to leisure activities, movies, etc.'),
('Bills', 'Utilities and other essential bills like water, electricity, etc.'),
('Healthcare', 'Medical and health-related expenses');

-- Insert Expenses into Expense Table
INSERT INTO Expense (user_id, category_id, amount, currency, exchange_rate, payment_method, date, notes) VALUES
(1, 1, 150.00, 'SAR', 1.0, 'debit', '2024-12-05', 'Dinner at a restaurant'),
(1, 2, 60.00, 'SAR', 1.0, 'credit', '2024-12-06', 'Fuel for car'),
(2, 3, 120.00, 'SAR', 1.0, 'cash', '2024-12-05', 'Movie tickets'),
(3, 4, 200.00, 'SAR', 1.0, 'debit', '2024-12-06', 'Electricity bill');

-- Insert Income into Income Table
INSERT INTO Income (user_id, source, amount, currency, exchange_rate, date, notes) VALUES
(1, 'Salary', 4000.00, 'SAR', 1.0, '2024-12-01', 'Monthly salary'),
(2, 'Freelance', 2500.00, 'SAR', 1.0, '2024-12-03', 'Freelance project payment'),
(3, 'Salary', 3500.00, 'SAR', 1.0, '2024-12-01', 'Monthly salary');

-- Insert Notifications into Notifications Table
INSERT INTO Notifications (user_id, type, message, status) VALUES
(1, 'warning', 'Warning: Amount exceeds budget', 'unread'),
(2, 'info', 'Your budget is still under the limit', 'read'),
(3, 'reminder', 'Reminder: Your next bill is due soon', 'unread');

-- Insert Linked Accounts into LinkedAccount Table
INSERT INTO LinkedAccount (user_id, bank_id) VALUES
(1, 1), -- User 1 linked to Al Rajhi Bank
(2, 3), -- User 2 linked to Riyad Bank
(3, 5); -- User 3 linked to Alinma Bank;

-- Sample Queries for Verification
SELECT * FROM User;
SELECT * FROM Category;
SELECT * FROM Bank;
SELECT * FROM LinkedAccount;
SELECT * FROM Budget;
SELECT * FROM Expense;
SELECT * FROM Income;
SELECT * FROM Notifications;


INSERT INTO Expense (user_id, category_id, amount, currency, exchange_rate, payment_method, date, notes) 
VALUES (1, 1, 150.00, 'SAR', 1.0, 'debit', STR_TO_DATE('2024-12-05', '%Y-%m-%d'), 'Dinner at a restaurant');

DELIMITER //

CREATE TRIGGER before_insert_expense
BEFORE INSERT ON Expense
FOR EACH ROW
BEGIN
    -- Ensure the date is in 'YYYY-MM-DD' format before inserting
    SET NEW.date = STR_TO_DATE(NEW.date, '%Y-%m-%d');
END //

DELIMITER ;


DELIMITER //

CREATE TRIGGER before_update_expense
BEFORE UPDATE ON Expense
FOR EACH ROW
BEGIN
    -- Ensure the date is in 'YYYY-MM-DD' format before updating
    SET NEW.date = STR_TO_DATE(NEW.date, '%Y-%m-%d');
END //

DELIMITER ;




SELECT * FROM Expense WHERE user_id = 1;




