CREATE TABLE sales (
	order_id INT PRIMARY KEY,
	customer_id VARCHAR(15),
	order_date DATE,
	region VARCHAR(5),
	product_category VARCHAR(20),
	customer_segment VARCHAR(15),
	quantity INT,
	unit_price NUMERIC(12, 2),
	discount_rate NUMERIC(5, 4),
	revenue NUMERIC(12, 2),
	cost NUMERIC(12, 2),
	profit NUMERIC(12, 2),
	payment_method VARCHAR(20)
);

\copy sales 
FROM 'C:\Users\mvsan\Documents\porfolio\retail_sales\Business_Analytics_Dataset_10000_Rows.csv' 
DELIMITER ','
CSV HEADER;

SELECT
	COUNT(*)
FROM sales;