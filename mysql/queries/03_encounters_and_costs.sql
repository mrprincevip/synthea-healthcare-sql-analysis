-- =====================================================================
-- 03_encounters_and_costs.sql
-- Purpose : Utilization and cost: what kinds of visits happen, how
--           often, what they cost, and how that changes over time.
-- Dialect : MySQL 8.0+ (MySQL Workbench)
-- Note    : Encounter START/STOP are DATETIME columns (converted by
--           load_data_mysql.py), so YEAR(START) gives the year.
--           Rows flagged as invalid in 01 are excluded with the
--           clean_encounters CTE.
-- =====================================================================

USE synthea;   -- the database created by load_data_mysql.py


-- Q1. Visits and cost by encounter type (wellness, emergency, inpatient...).
WITH clean_encounters AS (
    SELECT * FROM encounters
    WHERE TOTAL_CLAIM_COST >= 0 AND STOP >= START
)
SELECT ENCOUNTERCLASS AS encounter_type,
       COUNT(*)                          AS encounters,
       ROUND(AVG(TOTAL_CLAIM_COST), 2)   AS avg_claim_cost,
       ROUND(SUM(TOTAL_CLAIM_COST), 0)   AS total_claim_cost,
       ROUND(100.0 * SUM(TOTAL_CLAIM_COST)
             / (SELECT SUM(TOTAL_CLAIM_COST) FROM clean_encounters), 1) AS pct_of_all_cost
FROM clean_encounters
GROUP BY ENCOUNTERCLASS
ORDER BY total_claim_cost DESC;


-- Q2. Yearly trend: encounters, unique patients seen and total cost.
SELECT YEAR(START)              AS year,
       COUNT(*)                         AS encounters,
       COUNT(DISTINCT PATIENT)          AS patients_seen,
       ROUND(SUM(TOTAL_CLAIM_COST), 0)  AS total_claim_cost
FROM encounters
WHERE TOTAL_CLAIM_COST >= 0 AND STOP >= START
GROUP BY year
ORDER BY year;


-- Q3. Top 10 most expensive encounter descriptions (min. 20 visits so
--     one-off outliers don't dominate).
SELECT DESCRIPTION,
       COUNT(*)                        AS encounters,
       ROUND(AVG(TOTAL_CLAIM_COST), 2) AS avg_claim_cost
FROM encounters
WHERE TOTAL_CLAIM_COST >= 0
GROUP BY DESCRIPTION
HAVING COUNT(*) >= 20
ORDER BY avg_claim_cost DESC
LIMIT 10;


-- Q4. Average length of stay for hospital (inpatient) admissions, by year.
SELECT YEAR(START) AS year,
       COUNT(*)            AS admissions,
       ROUND(AVG(TIMESTAMPDIFF(SECOND, START, STOP) / 86400), 1) AS avg_length_of_stay_days
FROM encounters
WHERE ENCOUNTERCLASS = 'inpatient'
  AND STOP >= START
GROUP BY year
ORDER BY year;


-- Q5. Emergency visits by month of the year (seasonality).
SELECT MONTH(START) AS month,
       COUNT(*)            AS emergency_visits
FROM encounters
WHERE ENCOUNTERCLASS = 'emergency'
GROUP BY month
ORDER BY month;


-- Q6. Busiest healthcare organizations by encounters and revenue.
SELECT o.NAME                           AS organization,
       o.CITY,
       COUNT(e.ID)                      AS encounters,
       COUNT(DISTINCT e.PATIENT)        AS patients,
       ROUND(SUM(e.TOTAL_CLAIM_COST), 0) AS total_claim_cost
FROM encounters e
JOIN organizations o ON o.ID = e.ORGANIZATION
WHERE e.TOTAL_CLAIM_COST >= 0
GROUP BY o.ID, o.NAME, o.CITY
ORDER BY encounters DESC
LIMIT 10;
