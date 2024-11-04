
-- create basic invoice table
CREATE TABLE invoice (
    id SERIAL PRIMARY KEY,
    product_id INT,
    price DECIMAL(10, 2)
);

-- insert values into it
INSERT INTO invoice (product_id, price) VALUES
(1, 95),
(2, 86),
(3, 77),
(4, 65),
(1, 96),
(2, 88),
(3, 69),
(4, 62);

-- check the table
select * from invoice;

-- basic usage of cte 

WITH average_price AS ( /* snytax key of cte */
/* we create temporary table which includes data view
that is desired result in order to use it directly within
select * from code block*/
    SELECT round(AVG(price),2) AS avg_price
    FROM invoice
) /* the end of temporary table expression*/
SELECT * FROM average_price; /* new data call code block 
where we use this table as if it really exists*/

-- create product table to demonstrate join 

CREATE TABLE product (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100)
);

-- insert values into it
INSERT INTO product (name) VALUES
('alfa'),
('beta'),
('zeta'),
('teta');

select * from product;

--breaking Down Complex Queries
WITH invoicedata AS (
    SELECT product_id, SUM(price) AS total_invoice
    FROM invoice
    GROUP BY 1
)
SELECT p.name as product, ivd.total_invoice
FROM product p
JOIN invoicedata ivd ON p.id = ivd.product_id;

-- alternative query

SELECT 
p.name as product,
SUM(iv.price) as total_invoice
FROM product p
JOIN invoice iv ON iv.product_id = p.id
GROUP BY 1

-- to explain well recalculation part
INSERT INTO product (name) VALUES
('meta')

-- add category column 

ALTER TABLE product
ADD category VARCHAR(50);

UPDATE product
SET category = 'A_cat'
WHERE id IN (1, 2);

UPDATE product
SET category = 'B_cat'
WHERE id IN (3, 4, 5);


-- basic usage of cte with aggregation
WITH invoicedata AS (
    SELECT i.product_id, p.category, SUM(i.price) AS total_invoice
    FROM invoice i
    LEFT JOIN product p ON p.id = i.product_id
    GROUP BY 1,2
)
SELECT 
    ivd.category,
    AVG(ivd.total_invoice) AS average_invoice_per_category,
    MAX(ivd.total_invoice) AS highest_invoice
FROM invoicedata ivd
GROUP BY ivd.category;

select i.*,p.category from invoice i
left join product p on p.id=i.product_id



-- same result without using cte
SELECT 
    category,
    AVG(total_invoice) AS average_invoice_per_category,
    MAX(total_invoice) AS highest_invoice
FROM (
    SELECT 
        i.product_id, 
        p.category, 
        SUM(i.price) AS total_invoice
    FROM 
        invoice i
    LEFT JOIN 
        product p ON p.id = i.product_id
    GROUP BY 
        i.product_id, p.category
) AS invoice_data
GROUP BY 
    1;

-- re-usability example of cte
WITH invoicedata AS (
    SELECT i.product_id, p.category, SUM(i.price) AS total_invoice
    FROM invoice i
    LEFT JOIN product p ON p.id = i.product_id
    GROUP BY i.product_id, p.category
)
SELECT 
    ivd.category,
    AVG(ivd.total_invoice) AS average_invoice_per_category,
    MAX(ivd.total_invoice) AS highest_invoice,
    COUNT(ivd.product_id) AS product_count  
FROM invoicedata ivd
GROUP BY ivd.category;

-- same result wihout using cte and non-reusable performance
SELECT 
    iv.category,
    AVG(iv.total_invoice) AS average_invoice_per_category,
    MAX(iv.total_invoice) AS highest_invoice,
    (SELECT COUNT(DISTINCT i.product_id) 
     FROM invoice i 
     LEFT JOIN product p ON p.id = i.product_id 
     WHERE p.category = iv.category) AS product_count 
FROM (
    SELECT 
        i.product_id, 
        p.category, 
        SUM(i.price) AS total_invoice
    FROM 
        invoice i
    LEFT JOIN 
        product p ON p.id = i.product_id
    GROUP BY 
        i.product_id, p.category
) AS iv
GROUP BY 
    iv.category;

-- advanced window function example 

-- create new tables first

-- Create the sales table
CREATE TABLE sales (
    order_id INT PRIMARY KEY,
    product_id INT,
    sale_date DATE,
    sale_amount DECIMAL(10, 2)
);

-- Insert data into the sales table
INSERT INTO sales (order_id, product_id, sale_date, sale_amount) VALUES
(1, 101, '2024-01-01', 150.00),
(2, 102, '2024-01-02', 200.00),
(3, 101, '2024-01-03', 100.00),
(4, 103, '2024-01-04', 300.00),
(5, 102, '2024-01-05', 250.00),
(6, 103, '2024-01-06', 400.00);

UPDATE sales
SET sale_amount = 300
WHERE order_id = 6;


-- Create the products_2 table
CREATE TABLE products_2 (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50),
    category VARCHAR(50)
);

-- Insert data into the products table
INSERT INTO products_2 (product_id, product_name, category) VALUES
(101, 'Product A', 'Category 1'),
(102, 'Product B', 'Category 1'),
(103, 'Product C', 'Category 2');

WITH CategorySales AS (
    -- category based total sales
    SELECT 
        p.category,
        SUM(s.sale_amount) AS total_sales
    FROM 
        sales s
    JOIN 
        products_2 p ON s.product_id = p.product_id
    GROUP BY 
        p.category
),

ProductSales AS (
    -- product base sales and ratio within category
    SELECT 
        p.category,
        p.product_name,
        SUM(s.sale_amount) AS product_total_sales
    FROM 
        sales s
    JOIN 
        products_2 p ON s.product_id = p.product_id
    GROUP BY 
        p.category, p.product_name
),

CategoryRank AS (
    -- most valuable product within category
    SELECT 
        ps.category,
        ps.product_name,
        ps.product_total_sales,
        (ps.product_total_sales * 100.0 / cs.total_sales) AS percentage_of_category_sales
    FROM 
        ProductSales ps
    JOIN 
        CategorySales cs ON ps.category = cs.category
    WHERE 
        ps.product_total_sales = (
            SELECT MAX(product_total_sales)
            FROM ProductSales
            WHERE category = ps.category
        )
)

SELECT 
    cr.category,
    cr.product_name AS top_selling_product,
    cr.product_total_sales AS total_sales_of_top_product,
    cr.percentage_of_category_sales AS percentage_of_total_sales,
    cs.total_sales AS category_total_sales,
    (SELECT COUNT(*)
     FROM sales s
     JOIN products_2 p ON s.product_id = p.product_id
     WHERE p.category = cr.category) AS sales_count
FROM 
    CategoryRank cr
JOIN 
    CategorySales cs ON cr.category = cs.category
ORDER BY 
    cr.category;



select * from sales s
inner join products_2 pt on pt.product_id=s.product_id



-- without using cte 

SELECT 
    ps.category,
    ps.product_name AS top_selling_product,
    ps.product_total_sales AS total_sales_of_top_product,
    (ps.product_total_sales * 100.0 / cs.total_sales) AS percentage_of_category_sales,
    cs.total_sales AS category_total_sales,
    (SELECT COUNT(*)
     FROM sales s
     JOIN products_2 p ON s.product_id = p.product_id
     WHERE p.category = ps.category) AS sales_count
FROM 
    (
        -- Product base sales and ratio within category
        SELECT 
            p.category,
            p.product_name,
            SUM(s.sale_amount) AS product_total_sales
        FROM 
            sales s
        JOIN 
            products_2 p ON s.product_id = p.product_id
        GROUP BY 
            p.category, p.product_name
    ) ps
JOIN 
    (
        -- Category based total sales
        SELECT 
            p.category,
            SUM(s.sale_amount) AS total_sales
        FROM 
            sales s
        JOIN 
            products_2 p ON s.product_id = p.product_id
        GROUP BY 
            p.category
    ) cs ON ps.category = cs.category
WHERE 
    ps.product_total_sales = (
        SELECT MAX(product_total_sales)
        FROM (
            SELECT 
                p.category,
                SUM(s.sale_amount) AS product_total_sales
            FROM 
                sales s
            JOIN 
                products_2 p ON s.product_id = p.product_id
            GROUP BY 
                p.category, p.product_name
        ) sub
        WHERE sub.category = ps.category
    )
ORDER BY 
    ps.category;





