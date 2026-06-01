# Walmart Sales Analysis - SQL + Python Project

**Author:** Vicky Naishorua
**Tools:** Python (Jupyter Notebook) + PostgreSQL / PgAdmin
**Dataset:** `walmart_clean_data.csv` (sourced via Kaggle API)
**Date:** June 2026

---

## Table of Contents

1. [Problem Statement](#problem-statement)
2. [Data Description](#data-description)
3. [Project Pipeline](#project-pipeline)
4. [Python - Data Acquisition and Cleaning](#python---data-acquisition-and-cleaning)
5. [Methodology - SQL Analysis](#methodology---sql-analysis)
6. [Results and Screenshots](#results-and-screenshots)
7. [SQL Concepts Used](#sql-concepts-used)
8. [Key Insights and Recommendations](#key-insights-and-recommendations)
9. [Limitations and Future Work](#limitations-and-future-work)

---

## Problem Statement

Walmart operates hundreds of branches across multiple cities, serving millions of customers through varied product categories and payment channels. Despite the volume of transactions, raw sales data alone does not answer critical operational questions such as: *Which product categories drive the most profit? Which branches are losing revenue? When are stores busiest?*

This project follows a two-stage data pipeline. First, Python is used to acquire the raw dataset via the Kaggle API, explore it, clean it, and export a production-ready CSV. Second, the cleaned data is loaded into PostgreSQL where 9 structured SQL queries answer key business questions spanning payment behavior, customer satisfaction, profitability, and branch performance. The goal is to produce data-driven insights that can directly inform Walmart's operations, marketing, and financial strategy.

---

## Data Description

### Source
The raw dataset was downloaded programmatically from Kaggle using the Kaggle API. After cleaning in Python, the output file `walmart_clean_data.csv` contains transactional sales records from Walmart branches across Texas, USA.

### Dataset Overview

| Property | Value |
|---|---|
| Total Records | 9,969 transactions |
| Time Period | January 2019 to December 2023 |
| Number of Branches | 100 unique branches |
| Cities Covered | 98 cities across Texas |
| Total Revenue | $1,209,726.38 |
| Average Customer Rating | 5.83 / 10 |

### Column Descriptions

| Column | Data Type | Description |
|---|---|---|
| `invoice_id` | INT | Unique identifier for each transaction |
| `branch` | VARCHAR | Branch code (e.g., WALM003) |
| `city` | VARCHAR | City where the branch is located |
| `category` | VARCHAR | Product category sold |
| `unit_price` | DECIMAL | Price per unit of the product |
| `quantity` | DECIMAL | Number of items purchased |
| `date` | DATE | Transaction date |
| `time` | VARCHAR | Transaction time (HH:MM:SS) |
| `payment_method` | VARCHAR | Payment type: Ewallet, Cash, Credit card |
| `rating` | DECIMAL | Customer satisfaction rating (1 to 10) |
| `profit_margin` | DECIMAL | Profit margin as a decimal (e.g., 0.48) |
| `total` | DECIMAL | Total transaction value |

### Product Categories
- Health and Beauty
- Electronic Accessories
- Home and Lifestyle
- Sports and Travel
- Food and Beverages
- Fashion Accessories

### Payment Methods
- E-wallet
- Cash
- Credit Card

---

## Project Pipeline

The project follows a structured end-to-end pipeline:

```
Kaggle API
    |
    v
Raw Dataset Downloaded in Python
    |
    v
Exploratory Data Analysis (Python / Pandas)
    |
    v
Data Cleaning (Python / Pandas)
    |
    v
Export: walmart_clean_data.csv
    |
    v
Import into PostgreSQL via PgAdmin
    |
    v
SQL Analysis (9 Business Questions)
    |
    v
Insights and Recommendations
```

---

## Python - Data Acquisition and Cleaning

### Step 1 - Kaggle API Setup and Data Download

The dataset was pulled directly from Kaggle without manual downloading, using the Kaggle Python API. This ensures reproducibility and makes it easy to refresh the dataset in future runs.

```python
# Install Kaggle API if not already installed
# pip install kaggle

import kaggle

# Authenticate using kaggle.json credentials (~/.kaggle/kaggle.json)
# Then download the dataset
kaggle.api.dataset_download_files(
    'dataset-owner/walmart-sales-dataset',
    path='./data',
    unzip=True
)
```

> **Note:** To use the Kaggle API, you need a `kaggle.json` file containing your API credentials. Download it from your Kaggle account settings and place it in `~/.kaggle/`.

---

### Step 2 - Exploratory Data Analysis (EDA)

Before cleaning, the dataset was explored to understand its structure, identify issues, and guide cleaning decisions.

```python
import pandas as pd
import numpy as np

df = pd.read_csv('./data/walmart_raw.csv')

# Basic overview
print(df.shape)
print(df.dtypes)
print(df.head())

# Check for missing values
print(df.isnull().sum())

# Check for duplicates
print(f"Duplicate rows: {df.duplicated().sum()}")

# Summary statistics
print(df.describe())

```

Key findings from EDA:
- The `date` column was stored as a string, not a proper date type
- The `time` column was stored as a string
- Some columns had inconsistent casing
- Duplicate rows were present and needed removal
- Missing values were identified in several columns

---

### Step 3 - Data Cleaning

Based on the EDA findings, the following cleaning steps were applied:

```python
# Remove duplicate rows
df.drop_duplicates(inplace=True)

# Drop rows with missing values
df.dropna(inplace=True)

# Standardize column names to lowercase
df.columns = df.columns.str.lower().str.strip()

# Convert date column to datetime
df['date'] = pd.to_datetime(df['date'], dayfirst=True)

# Strip whitespace from string columns
string_cols = df.select_dtypes(include='object').columns
for col in string_cols:
    df[col] = df[col].str.strip()

# Validate numeric columns (remove any non-numeric entries)
numeric_cols = ['unit_price', 'quantity', 'rating', 'profit_margin', 'total']
for col in numeric_cols:
    df[col] = pd.to_numeric(df[col], errors='coerce')

df.dropna(subset=numeric_cols, inplace=True)

# Confirm final shape
print(f"Clean dataset shape: {df.shape}")
print(df.dtypes)
```

---

### Step 4 - Export Cleaned Dataset

Once the data was clean and validated, it was exported as a CSV file ready for import into PostgreSQL.

```python
df.to_csv('./data/walmart_clean_data.csv', index=False)
print("Cleaned dataset saved successfully.")
```

---

### Step 5 - Import into PostgreSQL via PgAdmin

The cleaned CSV was imported into a PostgreSQL database using PgAdmin's built-in Import/Export tool.

**Table creation:**

```sql
CREATE TABLE walmart (
    invoice_id       INT,
    branch           VARCHAR(20),
    city             VARCHAR(50),
    category         VARCHAR(50),
    unit_price       DECIMAL(8,2),
    quantity         DECIMAL(8,2),
    date             DATE,
    time             VARCHAR(10),
    payment_method   VARCHAR(20),
    rating           DECIMAL(3,1),
    profit_margin    DECIMAL(5,2),
    total            DECIMAL(10,2)
);
```

**Import steps in PgAdmin:**
1. Right-click the `walmart` table in the object browser
2. Select Import/Export
3. Choose the `walmart_clean_data.csv` file
4. Enable the Header toggle
5. Set delimiter to `,`
6. Click OK

---

## Methodology - SQL Analysis

With the clean data loaded into PostgreSQL, 9 analytical queries were written to address each business question.

---

### Question 1 - Analyze Payment Methods and Sales

**Business Question:** What are the different payment methods, and how many transactions and items were sold with each method?

**Purpose:** Understand customer payment preferences to optimize payment infrastructure.

```sql
SELECT 
    payment_method,
    COUNT(invoice_id) AS total_transactions,
    SUM(quantity)     AS total_items_sold
FROM walmart
GROUP BY payment_method
ORDER BY total_transactions DESC;
```

---

### Question 2 - Highest-Rated Category per Branch

**Business Question:** Which category received the highest average rating in each branch?

**Purpose:** Recognize top-performing categories per branch to guide branch-specific marketing.

```sql
WITH ranked_categories AS (
    SELECT 
        branch,
        category,
        AVG(rating) AS avg_rating,
        ROW_NUMBER() OVER (PARTITION BY branch ORDER BY AVG(rating) DESC) AS rank
    FROM walmart
    GROUP BY branch, category
)
SELECT 
    branch,
    category,
    ROUND(avg_rating, 2) AS highest_avg_rating
FROM ranked_categories
WHERE rank = 1;
```

---

### Question 3 - Busiest Day per Branch

**Business Question:** What is the busiest day of the week for each branch based on transaction volume?

**Purpose:** Optimize staffing and inventory management for peak days.

```sql
WITH branch_days AS (
    SELECT 
        branch,
        TO_CHAR(date, 'Day') AS day_of_week,
        COUNT(invoice_id) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY branch ORDER BY COUNT(invoice_id) DESC) AS rank
    FROM walmart
    GROUP BY branch, TO_CHAR(date, 'Day')
)
SELECT 
    branch,
    TRIM(day_of_week) AS busiest_day,
    transaction_count
FROM branch_days
WHERE rank = 1;
```

---

### Question 4 - Total Quantity Sold by Payment Method

**Business Question:** How many items were sold through each payment method?

**Purpose:** Track sales volume by payment type to understand purchasing habits.

```sql
SELECT 
    payment_method,
    SUM(quantity) AS total_quantity_sold
FROM walmart
GROUP BY payment_method
ORDER BY total_quantity_sold DESC;
```

---

### Question 5 - Category Ratings by City

**Business Question:** What are the average, minimum, and maximum ratings for each category in each city?

**Purpose:** Guide city-level promotions and address regional customer experience gaps.

```sql
SELECT 
    city,
    category,
    ROUND(AVG(rating), 2) AS avg_rating,
    MIN(rating)           AS min_rating,
    MAX(rating)           AS max_rating
FROM walmart
GROUP BY city, category
ORDER BY city, avg_rating DESC;
```

---

### Question 6 - Total Profit by Category

**Business Question:** What is the total profit for each category, ranked from highest to lowest?

**Purpose:** Identify high-profit categories to focus pricing and expansion strategies.

```sql
SELECT 
    category,
    ROUND(SUM(total * profit_margin), 2) AS total_profit
FROM walmart
GROUP BY category
ORDER BY total_profit DESC;
```

---

### Question 7 - Most Common Payment Method per Branch

**Business Question:** What is the most frequently used payment method in each branch?

**Purpose:** Understand branch-specific payment preferences to streamline processing systems.

```sql
WITH payment_counts AS (
    SELECT 
        branch,
        payment_method,
        COUNT(*) AS transaction_count,
        ROW_NUMBER() OVER (PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
    FROM walmart
    GROUP BY branch, payment_method
)
SELECT 
    branch,
    payment_method AS most_common_payment,
    transaction_count
FROM payment_counts
WHERE rank = 1;
```

---

### Question 8 - Sales by Shift (Morning / Afternoon / Evening)

**Business Question:** How many transactions occur in each shift across branches?

**Purpose:** Manage staff shifts and stock replenishment schedules during high-sales periods.

```sql
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
```

> **Note:** The `time` column is stored as `VARCHAR`, so `::TIME` casting is required before applying `EXTRACT()`.

---

### Question 9 - Branches with Highest Revenue Decline YoY

**Business Question:** Which branches experienced the largest revenue decrease compared to the previous year?

**Purpose:** Detect struggling branches early and create targeted recovery strategies.

```sql
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
        curr.total_revenue        AS current_year_revenue,
        prev.total_revenue        AS previous_year_revenue,
        ROUND(curr.total_revenue - prev.total_revenue, 2) AS revenue_change,
        ROUND(
            (curr.total_revenue - prev.total_revenue) / prev.total_revenue * 100
        , 2) AS pct_change
    FROM yearly_revenue curr
    JOIN yearly_revenue prev 
        ON curr.branch = prev.branch 
       AND curr.year   = prev.year + 1
)
SELECT *
FROM revenue_comparison
ORDER BY revenue_change ASC;
```

---

### Screenshot 1 - Total Profit by Category (Q6)

This is the most strategically important result. It directly shows which product lines generate the most value for Walmart and should drive shelf space and pricing decisions.

**How to capture:** Run Q6, screenshot the full results grid showing all 6 categories ranked by total profit.

```
screenshots/q6_profit_by_category.png
```

![Q6 - Profit by Category](https://i.postimg.cc/VsV0X7Yd/Q6-output.png)

---

### Screenshot 2 - Year-Over-Year Revenue Decline (Q9)

This is the most technically complex query and the most operationally critical result. It identifies which branches need urgent management attention based on revenue trends over time.

**How to capture:** Run Q9, screenshot the results sorted by `revenue_change ASC` so the worst-performing branches appear at the top.

```
screenshots/q9_revenue_decline_yoy.png
```

![Q9 - Revenue Decline YoY](https://i.postimg.cc/jjnR0XVY/Screenshot-2026-06-01-155236.png)

---

### Screenshot 3 - Sales by Shift Across Branches (Q8)

This result shows clear operational patterns across time of day, making it easy to see when stores are busiest and where staffing should be concentrated.

**How to capture:** Run Q8 and screenshot the results showing Morning, Afternoon, and Evening shifts per branch with their transaction counts.

```
screenshots/q8_sales_by_shift.png
```

![Q8 - Sales by Shift](https://i.postimg.cc/c1X2hnjK/Screenshot-2026-06-01-155411.png)

---

## SQL Concepts Used

| Concept | Where Applied |
|---|---|
| `GROUP BY` with Aggregate Functions (`COUNT`, `SUM`, `AVG`, `MIN`, `MAX`) | Q1, Q4, Q5, Q6 |
| Common Table Expressions (`WITH ... AS`) | Q2, Q3, Q7, Q9 |
| Window Functions (`ROW_NUMBER() OVER (PARTITION BY ...)`) | Q2, Q3, Q7 |
| `CASE WHEN` conditional logic | Q8 |
| `EXTRACT()` for date and time parts | Q8, Q9 |
| `TO_CHAR()` for date formatting | Q3 |
| `TRIM()` for string cleaning | Q3 |
| `ROUND()` for decimal formatting | Q2, Q5, Q6, Q9 |
| Type Casting (`::TIME`) | Q8 |
| Self `JOIN` on CTEs | Q9 |
| `ORDER BY` with `ASC` and `DESC` | All queries |

---

## Key Insights and Recommendations

### 1. Payment Methods
All three payment methods (E-wallet, Cash, Credit Card) are used relatively evenly, suggesting Walmart's customers do not have one single dominant preference. E-wallet transactions are slightly higher in volume, indicating a growing shift toward digital payments. Walmart should continue investing in reliable digital payment infrastructure across all branches.

### 2. Category Ratings
Customer ratings vary by both branch and city, meaning product satisfaction is highly localized. Walmart should empower branch managers to prioritize categories that perform well locally rather than applying a uniform national approach.

### 3. Peak Days and Shifts
Transaction volume is not evenly distributed across days or times. Afternoon shifts consistently record higher transaction volumes across most branches. Staffing rosters and stock replenishment schedules should be weighted toward afternoons, with leaner coverage during slower morning hours.

### 4. Profitability by Category
Not all categories are equally profitable. Walmart should prioritize shelf space, promotions, and supplier negotiations for the highest-margin categories. Categories with low profit relative to their sales volume warrant a pricing strategy review.

### 5. Year-Over-Year Revenue Decline
Several branches show measurable revenue decline year-over-year. These branches should be investigated for factors such as local competition, demographic shifts, or operational inefficiencies. Early detection through SQL analytics enables proactive intervention rather than reactive damage control.

### 6. Branch-Level Payment Preferences
Payment method preferences differ by branch, likely reflecting the demographics of the surrounding city. Branches with high cash usage should maintain adequate cash-handling capacity, while branches with high E-wallet usage should ensure payment terminal uptime and reliability.

---

## Limitations and Future Work

### Limitations

| Limitation | Impact |
|---|---|
| No customer demographic data | Cannot segment analysis by age, gender, or loyalty status |
| `time` column stored as VARCHAR | Required manual casting (`::TIME`), indicating upstream data pipeline quality issues |
| No product-level data | Analysis is limited to categories, not individual SKUs |
| No cost data beyond profit margin | Cannot calculate absolute cost or net income per transaction |
| Static dataset | No real-time integration; insights reflect historical patterns only |
| Texas-only data | Findings may not generalize to Walmart operations in other states or countries |

### Future Work

- **Dashboard Integration:** Connect the PostgreSQL database to a BI tool such as Power BI or Tableau to enable live, interactive dashboards for branch managers.
- **Customer Segmentation:** Incorporate loyalty card or demographic data to perform cohort-level analysis such as rating patterns by age group.
- **Predictive Modeling:** Use historical sales trends to forecast demand by category and branch, enabling proactive inventory management.
- **Anomaly Detection:** Build SQL-based or Python-based alerts to flag unusual transaction patterns such as sudden drops in a branch's daily revenue.
- **Geospatial Analysis:** Map branch performance data geographically to identify spatial clustering of high and low performers.
- **Automated Reporting:** Schedule recurring SQL reports using pg_cron or an external orchestration tool to generate weekly branch performance summaries automatically.
- **End-to-end Pipeline Automation:** Automate the full pipeline from Kaggle API download through Python cleaning and into PostgreSQL using a workflow tool such as Apache Airflow or a simple cron job, so the dataset can be refreshed without manual steps.


---

## Tools and Technologies

| Tool | Purpose |
|---|---|
| Python 3 / Jupyter Notebook | Data acquisition, EDA, and cleaning |
| Kaggle API | Programmatic dataset download |
| Pandas / NumPy | Data manipulation and cleaning |
| PostgreSQL 15+ | Relational database for SQL analysis |
| PgAdmin 4 | SQL IDE and data import |

---

*Project completed as part of a data analytics portfolio. All data is used for educational purposes only.*
