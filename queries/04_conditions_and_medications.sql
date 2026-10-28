-- =====================================================================
-- 04_conditions_and_medications.sql
-- Purpose : Which conditions are most common, which are chronic, how
--           they cluster, and which medications cost the most.
-- Dialect : SQLite (DB Browser for SQLite)
-- Note    : A condition with an empty STOP date is still active.
-- =====================================================================


-- Q1. Top 10 conditions by number of patients affected.
SELECT DESCRIPTION                AS condition_name,
       COUNT(DISTINCT PATIENT)    AS patients,
       ROUND(100.0 * COUNT(DISTINCT PATIENT)
             / (SELECT COUNT(DISTINCT ID) FROM patients), 1) AS pct_of_patients
FROM conditions
GROUP BY DESCRIPTION
ORDER BY patients DESC
LIMIT 10;


-- Q2. Top 10 conditions that are still active (no STOP date): the
--     chronic disease burden of the population.
SELECT DESCRIPTION             AS condition_name,
       COUNT(DISTINCT PATIENT) AS patients_with_active_condition
FROM conditions
WHERE STOP IS NULL OR TRIM(STOP) = ''
GROUP BY DESCRIPTION
ORDER BY patients_with_active_condition DESC
LIMIT 10;


-- Q3. Prevalence of diabetes and hypertension by age band.
--     Prediabetes is excluded: LIKE '%diabetes%' would otherwise match it.
WITH patient_age AS (
    SELECT DISTINCT ID,
           CAST((JULIANDAY(COALESCE(DEATHDATE, DATE('now'))) - JULIANDAY(BIRTHDATE)) / 365.25 AS INTEGER) AS age
    FROM patients
    WHERE BIRTHDATE <= DATE('now')
),
flags AS (
    SELECT pa.ID,
           CASE
               WHEN pa.age < 35 THEN '1. Under 35'
               WHEN pa.age < 50 THEN '2. 35-49'
               WHEN pa.age < 65 THEN '3. 50-64'
               ELSE                  '4. 65+'
           END AS age_band,
           MAX(CASE WHEN c.DESCRIPTION LIKE '%diabetes%'
                     AND c.DESCRIPTION NOT LIKE '%prediabetes%' THEN 1 ELSE 0 END) AS has_diabetes,
           MAX(CASE WHEN c.DESCRIPTION LIKE '%hypertension%' THEN 1 ELSE 0 END) AS has_hypertension
    FROM patient_age pa
    LEFT JOIN conditions c ON c.PATIENT = pa.ID
    GROUP BY pa.ID, age_band
)
SELECT age_band,
       COUNT(*)                                    AS patients,
       ROUND(100.0 * SUM(has_diabetes)     / COUNT(*), 1) AS pct_diabetes,
       ROUND(100.0 * SUM(has_hypertension) / COUNT(*), 1) AS pct_hypertension
FROM flags
GROUP BY age_band
ORDER BY age_band;


-- Q4. Comorbidity: how many patients have BOTH diabetes and hypertension?
SELECT COUNT(*) AS patients_with_both
FROM (
    SELECT PATIENT
    FROM conditions
    GROUP BY PATIENT
    HAVING SUM(CASE WHEN DESCRIPTION LIKE '%diabetes%'
                    AND DESCRIPTION NOT LIKE '%prediabetes%' THEN 1 ELSE 0 END) > 0
       AND SUM(CASE WHEN DESCRIPTION LIKE '%hypertension%' THEN 1 ELSE 0 END) > 0
) AS both_conditions;


-- Q5. Top 10 medications by total cost, with the average cost per dispense.
SELECT DESCRIPTION                       AS medication,
       COUNT(DISTINCT PATIENT)           AS patients,
       SUM(DISPENSES)                    AS dispenses,
       ROUND(SUM(TOTALCOST), 0)          AS total_cost,
       ROUND(SUM(TOTALCOST) / NULLIF(SUM(DISPENSES), 0), 2) AS avg_cost_per_dispense
FROM medications
GROUP BY DESCRIPTION
ORDER BY total_cost DESC
LIMIT 10;
