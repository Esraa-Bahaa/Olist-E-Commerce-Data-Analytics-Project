use olist_db ;

-- Verify LOCAL INFILE server setting
SHOW VARIABLES LIKE 'local_infile';

-- Create Fact_Orders table
CREATE TABLE IF NOT EXISTS Fact_Orders (
    order_id VARCHAR(32) NOT NULL,
    customer_id VARCHAR(32) NOT NULL,
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATE,
    `Order Date` DATE,
    PRIMARY KEY (order_id)
);

-- Import Fact_Orders data from CSV
LOAD DATA LOCAL INFILE 'C:/Users/asd/Downloads/Olist_SQL/Fact_Orders.csv'
INTO TABLE Fact_Orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    order_id,
    customer_id,
    order_status,
    @order_purchase_timestamp,
    @order_approved_at,
    @order_delivered_carrier_date,
    @order_delivered_customer_date,
    @order_estimated_delivery_date,
    @Order_Date
)
SET
    order_purchase_timestamp = STR_TO_DATE(NULLIF(@order_purchase_timestamp, ''), '%m/%e/%Y %H:%i'),
    order_approved_at = STR_TO_DATE(NULLIF(@order_approved_at, ''), '%m/%e/%Y %H:%i'),
    order_delivered_carrier_date = STR_TO_DATE(NULLIF(@order_delivered_carrier_date, ''), '%m/%e/%Y %H:%i'),
    order_delivered_customer_date = STR_TO_DATE(NULLIF(@order_delivered_customer_date, ''), '%m/%e/%Y %H:%i'),
    order_estimated_delivery_date = STR_TO_DATE(NULLIF(@order_estimated_delivery_date, ''), '%m/%e/%Y'),
    `Order Date` = STR_TO_DATE(NULLIF(@Order_Date, ''), '%m/%e/%Y');
    
    -- Validate Fact_Orders row count
SELECT COUNT(*) AS total_orders
FROM Fact_Orders;

-- Create Fact_OrderItems table
CREATE TABLE IF NOT EXISTS Fact_OrderItems (
    order_id VARCHAR(32) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(32),
    seller_id VARCHAR(32),
    shipping_limit_date DATETIME,
    price DECIMAL(12,2),
    freight_value DECIMAL(12,2),
    PRIMARY KEY (order_id, order_item_id)
);

-- Import Fact_OrderItems data from CSV
LOAD DATA LOCAL INFILE 'C:/Users/asd/Downloads/Olist_SQL/Fact_OrderItems.csv'
INTO TABLE Fact_OrderItems
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    order_id,
    order_item_id,
    product_id,
    seller_id,
    @shipping_limit_date,
    @price,
    @freight_value
)
SET
    shipping_limit_date = STR_TO_DATE(NULLIF(@shipping_limit_date, ''), '%m/%e/%Y %H:%i'),
    price = NULLIF(@price, ''),
    freight_value = NULLIF(@freight_value, '');
    
    -- Validate Fact_OrderItems row count
SELECT COUNT(*) AS total_order_items
FROM Fact_OrderItems;

-- Validate Fact_OrderItems unique item keys
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '-', order_item_id)) AS unique_items
FROM Fact_OrderItems;

-- Create Fact_Payments table
CREATE TABLE IF NOT EXISTS Fact_Payments (
    order_id VARCHAR(32) NOT NULL,
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(12,2)
);

-- Import Fact_Payments data from CSV
LOAD DATA LOCAL INFILE 'C:/Users/asd/Downloads/Olist_SQL/Fact_Payments.csv'
INTO TABLE Fact_Payments
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    @payment_value
)
SET
    payment_value = NULLIF(@payment_value, '');
    
    -- Validate Fact_Payments row count
SELECT COUNT(*) AS total_payments
FROM Fact_Payments;

-- Validate payment values
SELECT
    COUNT(*) AS total_rows,
    COUNT(payment_value) AS non_null_payment_values
FROM Fact_Payments;

-- Create Fact_Reviews table
CREATE TABLE Fact_Reviews (
    review_id VARCHAR(32),
    order_id VARCHAR(32),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

-- Import Fact_Reviews data with correct column mapping
LOAD DATA LOCAL INFILE 'C:/Users/asd/Downloads/Olist_SQL/Fact_Reviews.csv'
INTO TABLE Fact_Reviews
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    @review_creation_date,
    @review_answer_timestamp
)
SET
    review_creation_date = STR_TO_DATE(NULLIF(@review_creation_date, ''), '%Y-%m-%d %H:%i:%s'),
    review_answer_timestamp = STR_TO_DATE(NULLIF(@review_answer_timestamp, ''), '%Y-%m-%d %H:%i:%s');

-- Validate Fact_Reviews row count and score range
SELECT
    COUNT(*) AS total_reviews,
    MIN(review_score) AS minimum_score,
    MAX(review_score) AS maximum_score
FROM Fact_Reviews;

-- Create Dim_Customers table
CREATE TABLE IF NOT EXISTS Dim_Customers (
    customer_id VARCHAR(32) NOT NULL,
    customer_unique_id VARCHAR(32),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state VARCHAR(5)
);

-- Import Dim_Customers data from CSV
LOAD DATA LOCAL INFILE 'C:/Users/asd/Downloads/Olist_SQL/Dim_Customers.csv'
INTO TABLE Dim_Customers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    customer_id,
    customer_unique_id,
    @customer_zip_code_prefix,
    customer_city,
    customer_state
)
SET
    customer_zip_code_prefix = NULLIF(@customer_zip_code_prefix, '');
    
    -- Validate unique customer IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM Dim_Customers;

-- Create Dim_Products table
CREATE TABLE IF NOT EXISTS Dim_Products (
    product_id VARCHAR(32) NOT NULL,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT,
    product_category_name_english VARCHAR(100)
);

-- Import Dim_Products data from CSV
LOAD DATA LOCAL INFILE 'C:/Users/asd/Downloads/Olist_SQL/Dim_Products.csv'
INTO TABLE Dim_Products
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    product_id,
    product_category_name,
    @product_name_lenght,
    @product_description_lenght,
    @product_photos_qty,
    @product_weight_g,
    @product_length_cm,
    @product_height_cm,
    @product_width_cm,
    product_category_name_english
)
SET
    product_name_lenght = NULLIF(@product_name_lenght, ''),
    product_description_lenght = NULLIF(@product_description_lenght, ''),
    product_photos_qty = NULLIF(@product_photos_qty, ''),
    product_weight_g = NULLIF(@product_weight_g, ''),
    product_length_cm = NULLIF(@product_length_cm, ''),
    product_height_cm = NULLIF(@product_height_cm, ''),
    product_width_cm = NULLIF(@product_width_cm, '');
    
    -- Validate unique product IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_product_ids
FROM Dim_Products;

-- Create Dim_Sellers table
CREATE TABLE IF NOT EXISTS Dim_Sellers (
    seller_id VARCHAR(32) NOT NULL,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state VARCHAR(5)
);

-- Import Dim_Sellers data from CSV
LOAD DATA LOCAL INFILE 'C:/Users/asd/Downloads/Olist_SQL/Dim_Sellers.csv'
INTO TABLE Dim_Sellers
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    seller_id,
    @seller_zip_code_prefix,
    seller_city,
    seller_state
)
SET
    seller_zip_code_prefix = NULLIF(@seller_zip_code_prefix, '');
    
    -- Validate unique seller IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_id) AS unique_seller_ids
FROM Dim_Sellers;

-- Create Dim_Geolocation table
CREATE TABLE IF NOT EXISTS Dim_Geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(12,8),
    geolocation_lng DECIMAL(12,8),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(5)
);

-- Import Dim_Geolocation data from CSV
LOAD DATA LOCAL INFILE 'C:/Users/asd/Downloads/Olist_SQL/Dim_Geolocation.csv'
INTO TABLE Dim_Geolocation
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    @geolocation_zip_code_prefix,
    @geolocation_lat,
    @geolocation_lng,
    geolocation_city,
    geolocation_state
)
SET
    geolocation_zip_code_prefix = NULLIF(@geolocation_zip_code_prefix, ''),
    geolocation_lat = NULLIF(@geolocation_lat, ''),
    geolocation_lng = NULLIF(@geolocation_lng, '');
    
    -- Validate geolocation data
SELECT
    COUNT(*) AS total_rows,
    COUNT(geolocation_lat) AS non_null_latitude,
    COUNT(geolocation_lng) AS non_null_longitude
FROM Dim_Geolocation;

-- Create Dim_Calendar table
CREATE TABLE IF NOT EXISTS Dim_Calendar (
    `Date` DATE,
    `Year` INT,
    `Quarter` VARCHAR(10),
    `MonthNum` INT,
    `MonthName` VARCHAR(20),
    `YearMonth` VARCHAR(10),
    `DayOfWeek` VARCHAR(20),
    `WeekdayNum` INT
);

-- Import Dim_Calendar data from CSV
LOAD DATA LOCAL INFILE 'C:/Users/asd/Downloads/Olist_SQL/Dim_Calendar.csv'
INTO TABLE Dim_Calendar
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    @Date,
    @Year,
    @Quarter,
    @MonthNum,
    @MonthName,
    @YearMonth,
    @DayOfWeek,
    @WeekdayNum
)
SET
    `Date` = STR_TO_DATE(NULLIF(@Date, ''), '%Y-%m-%d'),
    `Year` = NULLIF(@Year, ''),
    `Quarter` = @Quarter,
    `MonthNum` = NULLIF(@MonthNum, ''),
    `MonthName` = @MonthName,
    `YearMonth` = @YearMonth,
    `DayOfWeek` = @DayOfWeek,
    `WeekdayNum` = NULLIF(@WeekdayNum, '');
    
    -- Validate Dim_Calendar date range
SELECT
    MIN(`Date`) AS first_date,
    MAX(`Date`) AS last_date
FROM Dim_Calendar;

-- Validate all imported table row counts
SELECT 'Fact_Orders' AS table_name, COUNT(*) AS row_count FROM Fact_Orders
UNION ALL
SELECT 'Fact_OrderItems', COUNT(*) FROM Fact_OrderItems
UNION ALL
SELECT 'Fact_Payments', COUNT(*) FROM Fact_Payments
UNION ALL
SELECT 'Fact_Reviews', COUNT(*) FROM Fact_Reviews
UNION ALL
SELECT 'Dim_Customers', COUNT(*) FROM Dim_Customers
UNION ALL
SELECT 'Dim_Products', COUNT(*) FROM Dim_Products
UNION ALL
SELECT 'Dim_Sellers', COUNT(*) FROM Dim_Sellers
UNION ALL
SELECT 'Dim_Geolocation', COUNT(*) FROM Dim_Geolocation
UNION ALL
SELECT 'Dim_Calendar', COUNT(*) FROM Dim_Calendar;



-- Analysis:

-- Calculate monthly revenue trend
SELECT
    YEAR(o.order_purchase_timestamp) AS order_year,
    MONTH(o.order_purchase_timestamp) AS order_month,
    ROUND(SUM(oi.price + oi.freight_value), 2) AS monthly_revenue
FROM Fact_Orders o
JOIN Fact_OrderItems oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp < '2018-09-01'
GROUP BY
    YEAR(o.order_purchase_timestamp),
    MONTH(o.order_purchase_timestamp)
ORDER BY
    order_year,
    order_month;
    
    -- Check the actual purchase date range
SELECT
    MIN(order_purchase_timestamp) AS first_purchase_date,
    MAX(order_purchase_timestamp) AS last_purchase_date,
    COUNT(order_purchase_timestamp) AS non_null_dates
FROM Fact_Orders;

-- Check available order statuses
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM Fact_Orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Check sample purchase dates
SELECT
    order_id,
    order_status,
    order_purchase_timestamp
FROM Fact_Orders
LIMIT 10;

-- Recreate Fact_Orders with correct date types
DROP TABLE Fact_Orders;

-- Recreate Fact_Orders table
CREATE TABLE Fact_Orders (
    order_id VARCHAR(32) NOT NULL,
    customer_id VARCHAR(32) NOT NULL,
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATE,
    `Order Date` DATE
);

-- Reload Fact_Orders with correct date conversion
LOAD DATA LOCAL INFILE 'C:/Users/asd/Downloads/Olist_SQL/Fact_Orders.csv'
INTO TABLE Fact_Orders
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    order_id,
    customer_id,
    order_status,
    @order_purchase_timestamp,
    @order_approved_at,
    @order_delivered_carrier_date,
    @order_delivered_customer_date,
    @order_estimated_delivery_date,
    @Order_Date
)
SET
    order_purchase_timestamp =
        STR_TO_DATE(NULLIF(@order_purchase_timestamp, ''), '%m/%d/%Y %H:%i'),

    order_approved_at =
        STR_TO_DATE(NULLIF(@order_approved_at, ''), '%m/%d/%Y %H:%i'),

    order_delivered_carrier_date =
        STR_TO_DATE(NULLIF(@order_delivered_carrier_date, ''), '%m/%d/%Y %H:%i'),

    order_delivered_customer_date =
        STR_TO_DATE(NULLIF(@order_delivered_customer_date, ''), '%m/%d/%Y %H:%i'),

    order_estimated_delivery_date =
        STR_TO_DATE(NULLIF(@order_estimated_delivery_date, ''), '%m/%d/%Y'),

    `Order Date` =
        STR_TO_DATE(NULLIF(@Order_Date, ''), '%m/%d/%Y');

-- Validate Fact_Orders dates after reload
SELECT
    COUNT(*) AS total_orders,
    COUNT(order_purchase_timestamp) AS valid_purchase_dates,
    MIN(order_purchase_timestamp) AS first_purchase_date,
    MAX(order_purchase_timestamp) AS last_purchase_date
FROM Fact_Orders;

-- Check why date values failed during import
SHOW WARNINGS LIMIT 20;

-- Create temporary staging table to inspect raw CSV values
CREATE TEMPORARY TABLE temp_orders_raw (
    order_id VARCHAR(100),
    customer_id VARCHAR(100),
    order_status VARCHAR(50),
    order_purchase_timestamp VARCHAR(100),
    order_approved_at VARCHAR(100),
    order_delivered_carrier_date VARCHAR(100),
    order_delivered_customer_date VARCHAR(100),
    order_estimated_delivery_date VARCHAR(100),
    Order_Date VARCHAR(100)
);

-- Load raw Fact_Orders CSV values for inspection
LOAD DATA LOCAL INFILE 'C:/Users/asd/Downloads/Olist_SQL/Fact_Orders.csv'
INTO TABLE temp_orders_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- Inspect the raw date values from Fact_Orders CSV
SELECT
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    Order_Date
FROM temp_orders_raw
LIMIT 10;

-- Reload Fact_Orders with correctly converted date fields
TRUNCATE TABLE Fact_Orders;

INSERT INTO Fact_Orders (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    `Order Date`
)
SELECT
    order_id,
    customer_id,
    order_status,

    STR_TO_DATE(
        NULLIF(order_purchase_timestamp, ''),
        '%Y-%m-%d %H:%i:%s'
    ),

    STR_TO_DATE(
        NULLIF(order_approved_at, ''),
        '%Y-%m-%d %H:%i:%s'
    ),

    STR_TO_DATE(
        NULLIF(order_delivered_carrier_date, ''),
        '%Y-%m-%d %H:%i:%s'
    ),

    STR_TO_DATE(
        NULLIF(order_delivered_customer_date, ''),
        '%Y-%m-%d %H:%i:%s'
    ),

    STR_TO_DATE(
        NULLIF(order_estimated_delivery_date, ''),
        '%Y-%m-%d %H:%i:%s'
    ),

    STR_TO_DATE(
        NULLIF(`Order Date`, ''),
        '%c/%e/%Y'
    )

FROM temp_orders_raw;

-- Reload Fact_Orders without the problematic Order Date column
TRUNCATE TABLE Fact_Orders;

INSERT INTO Fact_Orders (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
)
SELECT
    order_id,
    customer_id,
    order_status,

    STR_TO_DATE(
        NULLIF(order_purchase_timestamp, ''),
        '%Y-%m-%d %H:%i:%s'
    ),

    STR_TO_DATE(
        NULLIF(order_approved_at, ''),
        '%Y-%m-%d %H:%i:%s'
    ),

    STR_TO_DATE(
        NULLIF(order_delivered_carrier_date, ''),
        '%Y-%m-%d %H:%i:%s'
    ),

    STR_TO_DATE(
        NULLIF(order_delivered_customer_date, ''),
        '%Y-%m-%d %H:%i:%s'
    ),

    STR_TO_DATE(
        NULLIF(order_estimated_delivery_date, ''),
        '%Y-%m-%d %H:%i:%s'
    )

FROM temp_orders_raw;

-- Validate Fact_Orders row count and purchase dates
SELECT
    COUNT(*) AS total_orders,
    COUNT(order_purchase_timestamp) AS valid_purchase_dates,
    MIN(order_purchase_timestamp) AS first_purchase_date,
    MAX(order_purchase_timestamp) AS last_purchase_date
FROM Fact_Orders;


-- Rebegine Analysis:


-- Analysis 1: Total Revenue
SELECT
    ROUND(SUM(price + freight_value), 2) AS total_revenue
FROM Fact_OrderItems;

-- Analysis 2: Order Status Distribution
SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM Fact_Orders),
        2
    ) AS order_percentage
FROM Fact_Orders
GROUP BY order_status
ORDER BY total_orders DESC;


-- Analysis 3: Monthly Revenue Trend
SELECT
    YEAR(o.order_purchase_timestamp) AS order_year,
    MONTH(o.order_purchase_timestamp) AS order_month,
    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS monthly_revenue
FROM Fact_Orders o
JOIN Fact_OrderItems oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY
    YEAR(o.order_purchase_timestamp),
    MONTH(o.order_purchase_timestamp)
ORDER BY
    order_year,
    order_month;
    
-- Analysis 4: Revenue by Product Category
SELECT
    COALESCE(
        p.product_category_name_english,
        'Unknown'
    ) AS product_category,
    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS category_revenue,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM Fact_OrderItems oi
JOIN Fact_Orders o
    ON oi.order_id = o.order_id
JOIN Dim_Products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY
    COALESCE(
        p.product_category_name_english,
        'Unknown'
    )
ORDER BY
    category_revenue DESC;    
    
    
-- Analysis 5: Top 10 Products by Revenue
SELECT
    oi.product_id,
    COALESCE(
        p.product_category_name_english,
        'Unknown'
    ) AS product_category,
    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS product_revenue,
    COUNT(*) AS items_sold
FROM Fact_OrderItems oi
JOIN Fact_Orders o
    ON oi.order_id = o.order_id
JOIN Dim_Products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY
    oi.product_id,
    COALESCE(
        p.product_category_name_english,
        'Unknown'
    )
ORDER BY
    product_revenue DESC
LIMIT 10;


-- Analysis 6: Average Product Price by Category
SELECT
    COALESCE(
        p.product_category_name_english,
        'Unknown'
    ) AS product_category,
    COUNT(*) AS items_sold,
    ROUND(
        AVG(oi.price),
        2
    ) AS average_product_price
FROM Fact_OrderItems oi
JOIN Fact_Orders o
    ON oi.order_id = o.order_id
JOIN Dim_Products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY
    COALESCE(
        p.product_category_name_english,
        'Unknown'
    )
HAVING COUNT(*) >= 100
ORDER BY
    average_product_price DESC;
    
    
    -- Analysis 7: Customer Distribution by State
SELECT
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    ROUND(
        COUNT(DISTINCT customer_unique_id) * 100.0 /
        (SELECT COUNT(DISTINCT customer_unique_id) FROM Dim_Customers),
        2
    ) AS customer_percentage
FROM Dim_Customers
GROUP BY customer_state
ORDER BY unique_customers DESC;


-- Analysis 8: Revenue by Customer State
SELECT
    c.customer_state,
    ROUND(
        SUM(oi.price + oi.freight_value),
        2
    ) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS unique_customers
FROM Fact_Orders o
JOIN Fact_OrderItems oi
    ON o.order_id = oi.order_id
JOIN Dim_Customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC;


-- Analysis 9: Top Sellers by Revenue
SELECT
    r.seller_id,
    s.seller_state,
    r.seller_revenue,
    r.total_orders,
    r.items_sold
FROM (
    SELECT
        oi.seller_id,
        ROUND(
            SUM(oi.price + oi.freight_value),
            2
        ) AS seller_revenue,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        COUNT(*) AS items_sold
    FROM Fact_OrderItems oi
    INNER JOIN Fact_Orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
) AS r
INNER JOIN Dim_Sellers s
    ON r.seller_id = s.seller_id
ORDER BY r.seller_revenue DESC
LIMIT 10;


-- Analysis 10: Repeat Customers
SELECT
    CASE
        WHEN customer_order_count = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,
    COUNT(*) AS total_customers,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage
FROM (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS customer_order_count
    FROM Dim_Customers c
    INNER JOIN Fact_Orders o
        ON c.customer_id = o.customer_id
    GROUP BY c.customer_unique_id
) AS customer_orders
GROUP BY
    CASE
        WHEN customer_order_count = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
        END
    
ORDER BY total_customers DESC;



-- Analysis 11: Seller Order Volume
SELECT
    r.seller_id,
    s.seller_state,
    r.total_orders,
    r.items_sold,
    r.average_item_price
FROM (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        COUNT(*) AS items_sold,
        ROUND(AVG(oi.price), 2) AS average_item_price
    FROM Fact_OrderItems oi
    INNER JOIN Fact_Orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
) AS r
INNER JOIN Dim_Sellers s
    ON r.seller_id = s.seller_id
ORDER BY r.total_orders DESC
LIMIT 10;


-- Analysis 12: Payment Type Distribution
SELECT
    payment_type,
    COUNT(*) AS total_payment_records,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM Fact_Payments),
        2
    ) AS payment_percentage
FROM Fact_Payments
GROUP BY payment_type
ORDER BY total_payment_records DESC;


-- Analysis 13: Orders by Day of Week
SELECT
    DAYNAME(order_purchase_timestamp) AS day_of_week,
    COUNT(*) AS total_orders
FROM Fact_Orders
GROUP BY
    DAYOFWEEK(order_purchase_timestamp),
    DAYNAME(order_purchase_timestamp)
ORDER BY
    total_orders desc ;
    

-- Analysis 14: Orders by Hour
SELECT
    HOUR(order_purchase_timestamp) AS purchase_hour,
    COUNT(*) AS total_orders
FROM Fact_Orders
GROUP BY
    HOUR(order_purchase_timestamp)
ORDER BY
    total_orders desc ;    
    
    
-- Analysis 15: Average Order Value by Payment Type
SELECT
    payment_type,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(
        AVG(payment_value),
        2
    ) AS average_order_value
FROM Fact_Payments
GROUP BY
    payment_type
ORDER BY
    average_order_value DESC;    
    
    
-- Analysis 16: Average Order Value
SELECT
    ROUND(AVG(order_total), 2) AS average_order_value
FROM (
    SELECT
        oi.order_id,
        SUM(oi.price + oi.freight_value) AS order_total
    FROM Fact_OrderItems oi
    GROUP BY oi.order_id
) AS order_values;


-- Analysis 17: Orders by Customer State
SELECT
    c.customer_state,
    COUNT(*) AS total_orders
FROM Fact_Orders o
INNER JOIN Dim_Customers c
    ON o.customer_id = c.customer_id
GROUP BY
    c.customer_state
ORDER BY
    total_orders DESC;
    
    
-- Analysis 18: Orders by Customer City
SELECT
    c.customer_city,
    c.customer_state,
    COUNT(*) AS total_orders
FROM Fact_Orders o
INNER JOIN Dim_Customers c
    ON o.customer_id = c.customer_id
GROUP BY
    c.customer_city,
    c.customer_state
ORDER BY
    total_orders DESC
LIMIT 10;


-- Analysis 19: Items per Order
SELECT
    ROUND(AVG(items_per_order), 2) AS average_items_per_order
FROM (
    SELECT
        order_id,
        COUNT(*) AS items_per_order
    FROM Fact_OrderItems
    GROUP BY order_id
) AS order_items;


-- Analysis 20: Payment Installments Distribution
SELECT
    payment_installments,
    COUNT(*) AS total_payment_records,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM Fact_Payments),
        2
    ) AS payment_percentage
FROM Fact_Payments
GROUP BY
    payment_installments
ORDER BY
    payment_installments;
    
    
-- Analysis 21: Average Payment Value by Installments
SELECT
    payment_installments,
    COUNT(*) AS total_payment_records,
    ROUND(
        AVG(payment_value),
        2
    ) AS average_payment_value
FROM Fact_Payments
GROUP BY
    payment_installments
HAVING COUNT(*) >= 100
ORDER BY
    payment_installments;
    
    
-- Analysis 22: Average Delivery Time by Customer State
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(
        AVG(
            DATEDIFF(
                o.order_delivered_customer_date,
                o.order_purchase_timestamp
            )
        ),
        2
    ) AS average_delivery_days
FROM Fact_Orders o
INNER JOIN Dim_Customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 100
ORDER BY average_delivery_days DESC;
    
    
-- Analysis 23: Product Sales Volume by Category
SELECT
    COALESCE(
        p.product_category_name_english,
        'Unknown'
    ) AS product_category,
    COUNT(*) AS items_sold,
    COUNT(DISTINCT oi.order_id) AS total_orders
FROM Fact_OrderItems oi
INNER JOIN Fact_Orders o
    ON oi.order_id = o.order_id
INNER JOIN Dim_Products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
GROUP BY
    COALESCE(
        p.product_category_name_english,
        'Unknown'
    )
ORDER BY
    items_sold DESC;
    
    

-- Analysis 24: Product Dimensions and Sales Volume
SELECT
    CASE
        WHEN (product_length_cm * product_height_cm * product_width_cm) < 5000
            THEN 'Small'
        WHEN (product_length_cm * product_height_cm * product_width_cm) < 20000
            THEN 'Medium'
        ELSE 'Large'
    END AS product_size,
    COUNT(*) AS items_sold,
    COUNT(DISTINCT oi.product_id) AS unique_products
FROM Fact_OrderItems oi
INNER JOIN Fact_Orders o
    ON oi.order_id = o.order_id
INNER JOIN Dim_Products p
    ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
  AND p.product_length_cm IS NOT NULL
  AND p.product_height_cm IS NOT NULL
  AND p.product_width_cm IS NOT NULL
GROUP BY
    CASE
        WHEN (product_length_cm * product_height_cm * product_width_cm) < 5000
            THEN 'Small'
        WHEN (product_length_cm * product_height_cm * product_width_cm) < 20000
            THEN 'Medium'
        ELSE 'Large'
        END
ORDER BY
    items_sold DESC;    
    
    
-- Analysis 25: On-Time vs Late Delivery
SELECT
    CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date
            THEN 'On Time'
        WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Late'
        ELSE 'Unknown'
    END AS delivery_status,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM Fact_Orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL
GROUP BY
    CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date
            THEN 'On Time'
        WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 'Late'
        ELSE 'Unknown'
    END
ORDER BY total_orders DESC;


-- Analysis 26: Overall Customer Review Score
SELECT
    COUNT(*) AS total_reviews,
    ROUND(
        AVG(review_score),
        2
    ) AS average_review_score,
    ROUND(
        SUM(
            CASE
                WHEN review_score >= 4 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS positive_review_rate
FROM Fact_Reviews;

