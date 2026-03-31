create database coffee_shop_sales_db;
use coffee_shop_sales_db;

SELECT * 
FROM coffee_shop_sales;

-- change transaction_date column type
SET SQL_SAFE_UPDATES = 0;

UPDATE coffee_shop_sales
SET transaction_date = STR_TO_DATE(transaction_date,'%d-%m-%Y');

ALTER TABLE coffee_shop_sales
MODIFY COLUMN transaction_date DATE;

SET SQL_SAFE_UPDATES = 1;

-- change transaction_time column type
SET SQL_SAFE_UPDATES = 0;

UPDATE coffee_shop_sales
SET transaction_time = STR_TO_DATE(transaction_time,'%H:%i:%s');

ALTER TABLE coffee_shop_sales
MODIFY COLUMN transaction_time TIME;

-- change column name
ALTER TABLE coffee_shop_sales
CHANGE COLUMN `ï»¿transaction_id` transaction_id INT;

-- calculate the total sales for each perspective month
SELECT concat(round(sum(unit_price * transaction_qty))/1000,"K") as Total_Sales
from coffee_shop_sales
where month(transaction_date) = 3;

-- TOTAL SALES KPI - MOM DIFFERENCE AND MOM GROWTH
SELECT 
    MONTH(transaction_date) AS month,   -- number of month
    ROUND(SUM(unit_price * transaction_qty)) AS total_sales,  -- Total sales column
    (SUM(unit_price * transaction_qty) - LAG(SUM(unit_price * transaction_qty), 1) -- month sales difference
    OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(unit_price * transaction_qty), 1)  -- Division by Privious month
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage  -- percentage
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) IN (4, 5) -- for months of April and May
GROUP BY 
    MONTH(transaction_date)
ORDER BY 
    MONTH(transaction_date);

-- 2. Total order analysis
-- Calculate the total number of orders for each respective month.
SELECT count(transaction_id) as Total_orders
from coffee_shop_sales
where month(transaction_date) = 5; -- may

-- TOTAL ORDERS KPI - MOM DIFFERENCE AND MOM GROWTH
SELECT 
    MONTH(transaction_date) AS month,
    ROUND(COUNT(transaction_id)) AS total_orders,
    (COUNT(transaction_id) - LAG(COUNT(transaction_id), 1) 
    OVER (ORDER BY MONTH(transaction_date))) / LAG(COUNT(transaction_id), 1) 
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) IN (4, 5) -- for April and May
GROUP BY 
    MONTH(transaction_date)
ORDER BY 
    MONTH(transaction_date);

-- Total Quantity Sold Analysis
-- calculate the total Quantity sold for each respective month
SELECT sum(transaction_qty) as Total_Quantity_Sold
from coffee_shop_sales
where month(transaction_date) = 6; -- june

-- TOTAL QUANTITY SOLD KPI - MOM DIFFERENCE AND MOM GROWTH
SELECT 
    MONTH(transaction_date) AS month,
    ROUND(SUM(transaction_qty)) AS total_quantity_sold,
    (SUM(transaction_qty) - LAG(SUM(transaction_qty), 1) 
    OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(transaction_qty), 1) 
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) IN (4, 5)   -- for April and May
GROUP BY 
    MONTH(transaction_date)
ORDER BY 
    MONTH(transaction_date);
    
-- CHARTS REQUIREMENT
-- 1.Calender Heat Map
select concat(round(sum(unit_price * transaction_qty)/1000,1),"K") as Total_Sales,
       concat(round(count(transaction_id)/1000,1),"K") as Total_orders,
       concat(round(sum(transaction_qty)/1000,1), "K") as Total_Quantity_Sold
from coffee_shop_sales
where transaction_date = "2023-03-27";

-- Sales Analysis by Weekdays and Weekands
-- Weekands(sat & sun)  and Weekdays (mon to fri)

select 
      CASE WHEN dayofweek(transaction_date) IN (1,7) THEN "WEEKANDS"
      ELSE "WEEKDAY"
      END AS day_type,
      concat(ROUND(SUM(unit_price * transaction_qty)/1000,1),"K") as Total_Sales
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 2 -- Feb month
GROUP BY 
      CASE WHEN dayofweek(transaction_date) IN (1,7) THEN "weekands"
      ELSE "WEEKDAY"
      END	;
      
-- Sales Analysis by store location
select store_location,
       concat(round(sum(transaction_qty * unit_price)/1000,2),"K") as Total_Sales
from coffee_shop_sales
where month(transaction_date) = 6
group by store_location
order by Total_Sales Desc;


-- Daily sales Analysis With Avarage line
select 
      concat(round(avg(Total_Sales)/1000,1),"K") as Avg_Sales
from ( select sum(transaction_qty * unit_price) as Total_Sales
       from coffee_shop_sales
       where month(transaction_date) = 5
       group by transaction_date
       ) as Internal_query;
       
-- DAILY SALES FOR MONTH SELECTED
select 
      day(transaction_date) as day_of_month,
      sum(transaction_qty * unit_price) as Total_Sales
from coffee_shop_sales
where month(transaction_date) = 4
group by day_of_month
order by day_of_month;

-- COMPARING DAILY SALES WITH AVERAGE SALES – IF GREATER THAN “ABOVE AVERAGE” and LESSER THAN “BELOW AVERAGE”
SELECT 
    day_of_month,
    CASE 
        WHEN total_sales > avg_sales THEN 'Above Average'
        WHEN total_sales < avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS sales_status,
    total_sales
FROM (
    SELECT 
        DAY(transaction_date) AS day_of_month,
        SUM(unit_price * transaction_qty) AS total_sales,
        AVG(SUM(unit_price * transaction_qty)) OVER () AS avg_sales
    FROM 
        coffee_shop_sales
    WHERE 
        MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY 
        DAY(transaction_date)
) AS sales_data
ORDER BY 
    day_of_month;
    
-- Sales Analysis by product category
select 
	  product_category,
      SUM(unit_price * transaction_qty) AS total_sales
from coffee_shop_sales
where month(transaction_date) = 5
group by product_category
order by total_sales DESC;


-- Top 10 product by sales
select 
	  product_type,
      SUM(unit_price * transaction_qty) AS total_sales
from coffee_shop_sales
where month(transaction_date) = 5
group by product_type
order by total_sales DESC
limit 10;

-- Sales Analysis by Days and Hours
select 
      SUM(unit_price * transaction_qty) AS total_sales,
      sum(transaction_qty) as Total_qty_sold,
      count(*) as Total_orders
from coffee_shop_sales
where month(transaction_date) = 5 -- May
and dayofweek(transaction_date) = 1 -- Sun
and HOUR(transaction_time) = 14;

-- Total sales by hours
select 
	  HOUR(transaction_time) as Hours,
      SUM(unit_price * transaction_qty) AS total_sales
from coffee_shop_sales
where month(transaction_date) = 5
group by Hours
order by Hours;

-- TO GET SALES FROM MONDAY TO SUNDAY FOR MONTH OF MAY
SELECT 
    CASE 
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        ELSE 'Sunday'
    END AS Day_of_Week,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) = 5 -- Filter for May (month number 5)
GROUP BY 
    CASE 
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        ELSE 'Sunday'
    END;


describe coffee_shop_sales



