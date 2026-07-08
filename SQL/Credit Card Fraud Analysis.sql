CREATE DATABASE fraud_detection;
USE fraud_detection;

CREATE TABLE fraud_train (
    Column1 INT,
    trans_date_trans_time VARCHAR(50),
    cc_num BIGINT,
    merchant VARCHAR(255),
    category VARCHAR(100),
    amt DECIMAL(12,2),
    first VARCHAR(100),
    last VARCHAR(100),
    gender VARCHAR(10),
    street VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(10),
    zip INT,
    lat DECIMAL(10,6),
    long_val DECIMAL(10,6),
    city_pop INT,
    job VARCHAR(255),
    dob VARCHAR(50),
    trans_num VARCHAR(100),
    unix_time BIGINT,
    merch_lat DECIMAL(10,6),
    merch_long DECIMAL(10,6),
    is_fraud INT,
    Fraud_status VARCHAR(20),
    Amount_category VARCHAR(20),
    Year INT,
    Month VARCHAR(20),
    Day_name VARCHAR(20),
    Hour INT
);

SELECT COUNT(*) AS total_rows
from fraud_train;
-----------------------------------------------------------------------------------------------------------------------------------------------------------
/*QUERY 1 - What % of transactions are fraudulent, and how severe is the fraud problem in the business?*/

SELECT COUNT(*) AS Total_transactions, 
SUM(is_fraud) as Fraud_transactions, 
ROUND(SUM(is_fraud)*100/COUNT(*), 2) AS Fraud_Rate
FROM Fraud_train;

/*
Business Insight:

Out of 100,000 transactions, only 990 transactions were identified as fraudulent, resulting in a fraud rate of approximately 0.99%. 
This indicates that fraudulent activities represent a very small portion of overall transactions, making fraud detection a highly imbalanced classification
problem where identifying rare fraud cases is critical for reducing financial losses.
*/
-----------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Query 2 - Which transaction amount category (Low, Medium, High) experiences the highest fraud rate?*/

SELECT
    Amount_category,
    COUNT(*) AS Total_Transactions,
    SUM(is_fraud) AS Fraud_Transactions,
    ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2) AS Fraud_Rate
FROM fraud_train
GROUP BY Amount_category
ORDER BY Fraud_Rate DESC;

/*
Business Insight:

High-value transactions show a significantly higher fraud risk with a fraud rate of 14.73%, compared to 0.42% for low-value transactions and only 0.06% for
medium-value transactions. Although high-value transactions account for only 5,066 transactions, they contribute to nearly 75% of all fraud cases (746 out of 990 frauds).

This suggests that fraudsters preferentially target larger transaction amounts to maximize potential financial gain. Therefore, high-value transactions
should be prioritized for enhanced fraud monitoring, real-time alerts, and additional verification checks.
*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Query 3 - Which merchant categories contribute the highest number of fraud transactions, and what percentage of total fraud do they represent?*/

WITH Fraud_By_Category AS (
    SELECT category,
	COUNT(*) AS Fraud_Transactions
    FROM fraud_train
    WHERE is_fraud = 1
    GROUP BY category),
Total_Fraud AS (
    SELECT COUNT(*) AS Total_Fraud_Transactions
    FROM fraud_train
    WHERE is_fraud = 1)
SELECT
    f.category,
    f.Fraud_Transactions,
    ROUND(f.Fraud_Transactions * 100.0 /t.Total_Fraud_Transactions, 2) AS Fraud_Contribution_Percentage,
    DENSE_RANK() OVER (
        ORDER BY f.Fraud_Transactions DESC) AS Fraud_Rank
FROM Fraud_By_Category f
CROSS JOIN Total_Fraud t
ORDER BY Fraud_Transactions DESC;

/* 
Business Insight:

The Grocery POS category emerged as the highest-risk merchant segment, accounting for 246 fraud cases and 24.85% of all fraudulent transactions.
Shopping Net followed closely with 218 fraud cases, contributing 22.02% of total fraud.

Together, Grocery POS and Shopping Net account for nearly 47% of all fraud incidents, indicating that card-present grocery purchases and online shopping
transactions are the primary fraud exposure areas.

These findings suggest that risk management efforts should prioritize transaction monitoring, fraud scoring models, and customer verification controls
within these merchant categories.
*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Query 4 - Which states have the highest fraud rate after accounting for transaction volume? */

WITH State_Fraud_Analysis AS
(SELECT
	state, COUNT(*) AS Total_Transactions,
        SUM(is_fraud) AS Fraud_Transactions,
        ROUND(SUM(is_fraud) * 100.0 / COUNT(*),
            2) AS Fraud_Rate
    FROM fraud_train
    GROUP BY state
),
Ranked_States AS
(SELECT *,
	DENSE_RANK() OVER(
	ORDER BY Fraud_Rate DESC) AS Fraud_Rank
    FROM State_Fraud_Analysis
    WHERE Total_Transactions >= 100)
SELECT *
FROM Ranked_States
ORDER BY Fraud_Rank;

/*
Business Insight:

Alaska (AK) recorded the highest fraud rate at 8.47%, followed by Washington DC (3.13%) and Maine (2.74%).

Although New York generated the highest volume of fraudulent transactions (108 fraud cases), its fraud rate was only 1.66%, indicating that transaction
volume alone does not determine fraud risk.

This suggests that certain regions experience disproportionately higher fraud exposure and should be prioritized for enhanced fraud monitoring and risk-control measures.
*/
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Query 5 - Which age groups are most vulnerable to fraudulent transactions?*/

SELECT
    CASE
        WHEN YEAR(STR_TO_DATE(dob,'%m/%d/%Y')) >= 1997 THEN '18-29'
        WHEN YEAR(STR_TO_DATE(dob,'%m/%d/%Y')) BETWEEN 1987 AND 1996 THEN '30-39'
        WHEN YEAR(STR_TO_DATE(dob,'%m/%d/%Y')) BETWEEN 1977 AND 1986 THEN '40-49'
        WHEN YEAR(STR_TO_DATE(dob,'%m/%d/%Y')) BETWEEN 1967 AND 1976 THEN '50-59'
ELSE '60+'
END AS Age_Group,

COUNT(*) AS Total_Transactions,
SUM(is_fraud) AS Fraud_Transactions,
ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2) AS Fraud_Rate
FROM fraud_train
GROUP BY Age_Group
ORDER BY Fraud_Rate DESC;

/*
Business Insight:

Customers aged 18-29 exhibit the highest fraud rate at 1.57%, despite representing the smallest customer segment in the dataset.

Customers aged 60+ generated the highest number of fraudulent transactions (362), however their fraud rate remained lower at 1.16% due to a significantly
larger transaction volume.

The findings suggest that younger customers are relatively more vulnerable to fraudulent activities, while older customers contribute more fraud cases due 
to higher overall transaction activity.

These insights can help financial institutions design age-specific fraud awareness campaigns and targeted risk monitoring strategies.
*/
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Query 6 - At what hour of the day does fraud occur most frequently?*/

SELECT
    Hour,
    COUNT(*) AS Total_Transactions,
    SUM(is_fraud) AS Fraud_Transactions,
    ROUND(
        SUM(is_fraud) * 100.0 / COUNT(*),
        2
    ) AS Fraud_Rate
FROM fraud_train
GROUP BY Hour
ORDER BY Fraud_Rate DESC;

/*
Business Insight:

Fraud activity is heavily concentrated during late-night and early-morning hours.

The highest fraud rates were observed at 11 PM (4.82%) and 10 PM (4.58%), followed by 1 AM (2.89%) and 12 AM (2.59%).

In contrast, daytime hours generally recorded fraud rates below 0.50%.

This pattern suggests that fraudsters are more active during off-business hours when customer monitoring and manual intervention are typically lower.

Financial institutions should consider implementing additional fraud controls, transaction alerts, and risk-based authentication during late-night periods.
*/
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Query 7 - Which combination of State and Merchant Category generates the highest number of fraud transactions?*/

SELECT
state, category, COUNT(*) AS Fraud_Transactions
FROM fraud_train
WHERE is_fraud = 1
GROUP BY state, category
ORDER BY Fraud_Transactions DESC
LIMIT 15;

/*
Business Insight:

New York and Texas recorded the highest number of fraudulent Grocery POS transactions, with 24 and 23 fraud cases respectively.

Shopping Net transactions also emerged as a major fraud hotspot, particularly in New York and Pennsylvania, each recording 23 fraud cases.

The findings indicate that fraud is not uniformly distributed across regions and merchant categories. Instead, specific State–Category combinations act as
fraud hotspots and should be prioritized for enhanced monitoring and risk-control measures.
*/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Query 8 - Which occupations have the highest fraud rates among customers?*/

SELECT job, 
COUNT(*) AS Total_Transactions,
SUM(is_fraud) AS Fraud_Transactions,
ROUND(SUM(is_fraud) * 100.0 / COUNT(*), 2) AS Fraud_Rate
FROM fraud_train
GROUP BY job
HAVING COUNT(*) >= 100
ORDER BY Fraud_Rate DESC
LIMIT 15;

/*
Business Insight:

Among occupations with at least 100 transactions, Set Designers recorded the highest fraud rate at 14.96%, followed by Medical Technical Officers
(10.68%) and Engineers - Building Services (10.00%).

While occupation alone should not be considered a direct indicator of fraudulent behavior, the analysis suggests that certain customer segments experience
higher fraud exposure than others.

These insights can support customer risk segmentation, fraud awareness initiatives, and targeted monitoring strategies for high-risk customer groups.
*/
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Query 9 - Which states generate the highest fraud losses in High-Value transactions?*/

SELECT state,
COUNT(*) AS Fraud_Transactions,
ROUND(SUM(amt),2) AS Total_Fraud_Amount
FROM fraud_train
WHERE is_fraud = 1
  AND Amount_category = 'High'
GROUP BY state
HAVING COUNT(*) >= 5
ORDER BY Total_Fraud_Amount DESC
LIMIT 15;
/*
Business Insight:

New York generated the highest fraud losses in high-value transactions, with 84 fraudulent transactions totaling $56,047.25.

Pennsylvania ranked second with $44,392.57 in fraudulent transaction value, followed by Ohio with $33,132.45.

These findings indicate that fraud risk should not only be measured by fraud volume but also by the financial impact of fraudulent transactions.

States with high fraud losses should be prioritized for enhanced transaction monitoring, real-time fraud alerts, and stricter verification controls for high-value purchases.
*/
----------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*Query 10 -What are the key fraud KPIs that management should monitor on a daily basis?*/

SELECT
    COUNT(*) AS Total_Transactions,
    SUM(is_fraud) AS Fraud_Transactions,
    ROUND(SUM(is_fraud)*100.0/COUNT(*),2) AS Fraud_Rate,
    ROUND(SUM(amt),2) AS Total_Transaction_Value,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amt ELSE 0 END),2) AS Total_Fraud_Value,
    ROUND(AVG(amt),2) AS Avg_Transaction_Value
FROM fraud_train;

/*
Executive Summary:

The dataset contains 100,000 transactions with a total transaction value of $7.19 million.

Among these transactions, 990 were identified as fraudulent, resulting in an overall fraud rate of 0.99%.

Fraudulent transactions accounted for approximately $520,749.84 in financial exposure, highlighting the significant monetary impact of a relatively small
number of fraudulent activities.

The average transaction value across all transactions was $71.91, indicating that fraud prevention efforts should focus not only on transaction volume but also
on the financial value at risk
*/