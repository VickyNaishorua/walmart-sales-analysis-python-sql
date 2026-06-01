-- 1. Analyze Payment Methods and Sales
/*  
What are the different payment methods, and how many transactions and items were sold with each method?
*/

-- Count the number of transactions and total items sold for each payment method to understand customer payment preferences.

SELECT 
    payment_method,
    COUNT(invoice_id) AS total_transactions,
    SUM(quantity) AS total_items_sold
FROM walmart
GROUP BY payment_method
ORDER BY total_transactions DESC;

-- 2. Identify the Highest-Rated Category in Each Branch
/* Which category received the highest average rating in each branch? */

-- Find which product category has the best average customer rating in each branch. We use a subquery to rank and then pick the top one per branch.

WITH ranked_categories AS (
    SELECT 
        branch,
        category,
        AVG(rating) AS avg_rating,
        ROW_NUMBER() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) as rank
    FROM walmart
    GROUP BY branch, category
)
SELECT 
    branch,
    category,
    ROUND(avg_rating, 2) AS highest_avg_rating
FROM ranked_categories
WHERE rank = 1;

-- 3.Determine the Busiest Day for Each Branch
/* What is the busiest day of the week for each branch based on transaction volume? */

--  Identify which day of the week sees the most transactions at each branch
WITH branch_days AS (
    SELECT 
        branch,
        TO_CHAR(date, 'Day') AS day_of_week,
        COUNT(invoice_id) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY branch ORDER BY COUNT(invoice_id) DESC) as rank
    FROM walmart
    GROUP BY branch, TO_CHAR(date, 'Day')
)
SELECT 
    branch,
    TRIM(day_of_week) AS busiest_day,
    transaction_count
FROM branch_days
WHERE rank = 1;

-- 4. Calculate Total Quantity Sold by Payment Method
/* How many items were sold through each payment method? */

-- identifying total items sold through each payment method 

SELECT 
    payment_method,
    SUM(quantity) AS total_quantity_sold
FROM walmart
GROUP BY payment_method
ORDER BY total_quantity_sold DESC;

--5. Analyze Category Ratings by City
/* What are the average, minimum, and maximum ratings for each category in each city? */

--  This helps spot regional preferences and underperforming areas.

SELECT 
    city,
    category,
    ROUND(AVG(rating), 2) AS avg_rating,
    MIN(rating)           AS min_rating,
    MAX(rating)           AS max_rating
FROM walmart
GROUP BY city, category
ORDER BY city, avg_rating DESC;

-- 6. Calculate Total Profit by Category
/* What is the total profit for each category, ranked from highest to lowest? */

-- Calculate total profit per category. Profit = total × profit_margin
SELECT 
    category,
    ROUND(SUM(total * profit_margin), 2) AS total_profit
FROM walmart
GROUP BY category
ORDER BY total_profit DESC;

-- 7. Determine the Most Common Payment Method per Branch
/* What is the most frequently used payment method in each branch? */

-- Determine each branch's preferred payment method

WITH payment_counts AS (
    SELECT 
        branch,
        payment_method,
        COUNT(*) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) as rank
    FROM walmart
    GROUP BY branch, payment_method
)
SELECT 
    branch,
    payment_method AS most_common_payment,
    transaction_count
FROM payment_counts
WHERE rank = 1;

-- 8. Analyze Sales Shifts Throughout the Day
/* How many transactions occur in each shift (Morning, Afternoon, Evening) across branches? */

-- Categorize each transaction into a time shift using the time column, then count transactions per shift per branch. Helps plan staff rosters.

SELECT 
    branch,
    CASE 
        WHEN EXTRACT(HOUR FROM time::TIME) < 12 THEN 'Morning'
        WHEN EXTRACT(HOUR FROM time::TIME) < 17 THEN 'Afternoon'
        ELSE 'Evening'
    END AS shift,
    COUNT(*) AS total_transactions
FROM walmart
GROUP BY branch, shift
ORDER BY branch, total_transactions DESC;

-- 9. Identify Branches with Highest Revenue Decline Year-Over-Year
/* Which branches experienced the largest decrease in revenue compared to the previous year? */

--  Compare each branch's revenue in 2019 vs 2018. Branches with the biggest drop are flagged for investigation.

WITH yearly_revenue AS (
    SELECT 
        branch,
        EXTRACT(YEAR FROM date) AS year,
        SUM(total) AS total_revenue
    FROM walmart
    GROUP BY branch, EXTRACT(YEAR FROM date)
),
revenue_comparison AS (
    SELECT 
        curr.branch,
        curr.total_revenue AS current_year_revenue,
        prev.total_revenue AS previous_year_revenue,
        ROUND(curr.total_revenue - prev.total_revenue, 2) AS revenue_change,
        ROUND(
            (curr.total_revenue - prev.total_revenue) / prev.total_revenue * 100
        , 2) AS pct_change
    FROM yearly_revenue curr
    JOIN yearly_revenue prev 
        ON curr.branch = prev.branch 
       AND curr.year = prev.year + 1
)
SELECT *
FROM revenue_comparison
ORDER BY revenue_change ASC;
