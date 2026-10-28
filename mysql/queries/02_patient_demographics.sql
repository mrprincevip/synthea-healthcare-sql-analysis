-- =====================================================================
-- 02_patient_demographics.sql
-- Purpose : Describe the patient population: age, gender, location,
--           mortality and income.
-- Dialect : MySQL 8.0+ (MySQL Workbench)
-- Note    : DISTINCT ID is used throughout because the quality checks
--           in 01 can find duplicate patient rows.
-- =====================================================================

USE synthea;   -- the database created by load_data_mysql.py


-- Q1. Living vs deceased patients.
SELECT CASE WHEN DEATHDATE IS NULL THEN 'Living' ELSE 'Deceased' END AS status,
       COUNT(DISTINCT ID) AS patients,
       ROUND(100.0 * COUNT(DISTINCT ID) / (SELECT COUNT(DISTINCT ID) FROM patients), 1) AS pct
FROM patients
GROUP BY status;


-- Q2. Living patients by age band and gender.
WITH living AS (
    SELECT DISTINCT ID, GENDER,
           TIMESTAMPDIFF(YEAR, BIRTHDATE, CURDATE()) AS age
    FROM patients
    WHERE DEATHDATE IS NULL
      AND BIRTHDATE <= CURDATE()          -- exclude invalid future birth dates
)
SELECT CASE
           WHEN age < 18 THEN '0-17'
           WHEN age < 35 THEN '18-34'
           WHEN age < 50 THEN '35-49'
           WHEN age < 65 THEN '50-64'
           ELSE '65+'
       END AS age_band,
       SUM(CASE WHEN GENDER = 'F' THEN 1 ELSE 0 END) AS female,
       SUM(CASE WHEN GENDER = 'M' THEN 1 ELSE 0 END) AS male,
       COUNT(*) AS total
FROM living
GROUP BY age_band
ORDER BY age_band;


-- Q3. Top 10 counties by number of patients.
SELECT COALESCE(NULLIF(TRIM(COUNTY), ''), 'Unknown') AS county,
       COUNT(DISTINCT ID) AS patients
FROM patients
GROUP BY county
ORDER BY patients DESC
LIMIT 10;


-- Q4. Average age at death, by gender.
SELECT GENDER,
       COUNT(DISTINCT ID) AS deaths,
       ROUND(AVG(DATEDIFF(DEATHDATE, BIRTHDATE) / 365.25), 1) AS avg_age_at_death
FROM patients
WHERE DEATHDATE IS NOT NULL
GROUP BY GENDER;


-- Q5. Lifetime healthcare expenses vs coverage, by income band.
--     Shows how much of their care each income group pays for themselves.
WITH banded AS (
    SELECT DISTINCT ID, HEALTHCARE_EXPENSES, HEALTHCARE_COVERAGE,
           CASE
               WHEN INCOME < 30000  THEN '1. Under $30k'
               WHEN INCOME < 60000  THEN '2. $30k-$60k'
               WHEN INCOME < 100000 THEN '3. $60k-$100k'
               ELSE                      '4. $100k+'
           END AS income_band
    FROM patients
    WHERE INCOME IS NOT NULL
)
SELECT income_band,
       COUNT(*) AS patients,
       ROUND(AVG(HEALTHCARE_EXPENSES), 0) AS avg_paid_by_patient,
       ROUND(AVG(HEALTHCARE_COVERAGE), 0) AS avg_paid_by_insurer,
       ROUND(100.0 * SUM(HEALTHCARE_EXPENSES)
             / NULLIF(SUM(HEALTHCARE_EXPENSES + HEALTHCARE_COVERAGE), 0), 1) AS pct_paid_by_patient
FROM banded
GROUP BY income_band
ORDER BY income_band;
