-- =====================================================================
-- 06_advanced_window_functions.sql
-- Purpose : Questions that need window functions: readmissions,
--           rankings, running totals and visit gaps.
-- Dialect : SQLite 3.25+ (DB Browser for SQLite 3.12+ includes it)
-- =====================================================================


-- Q1. 30-day hospital readmission rate.
--     For each inpatient stay, LEAD() finds the same patient's next
--     inpatient admission; a readmission is one that starts within
--     30 days of the previous discharge.
WITH stays AS (
    SELECT PATIENT,
           START,
           STOP,
           LEAD(START) OVER (PARTITION BY PATIENT ORDER BY START) AS next_admission
    FROM encounters
    WHERE ENCOUNTERCLASS = 'inpatient'
      AND STOP >= START
)
SELECT COUNT(*) AS discharges,
       SUM(CASE WHEN next_admission IS NOT NULL
                 AND JULIANDAY(SUBSTR(next_admission, 1, 19)) - JULIANDAY(SUBSTR(STOP, 1, 19)) BETWEEN 0 AND 30
                THEN 1 ELSE 0 END) AS readmitted_within_30_days,
       ROUND(100.0 * SUM(CASE WHEN next_admission IS NOT NULL
                 AND JULIANDAY(SUBSTR(next_admission, 1, 19)) - JULIANDAY(SUBSTR(STOP, 1, 19)) BETWEEN 0 AND 30
                THEN 1 ELSE 0 END) / COUNT(*), 1) AS readmission_rate_pct
FROM stays;


-- Q2. The 3 most expensive encounters within each encounter type
--     (ROW_NUMBER restarts at 1 for every type).
WITH ranked AS (
    SELECT ENCOUNTERCLASS, DESCRIPTION, START, TOTAL_CLAIM_COST,
           ROW_NUMBER() OVER (PARTITION BY ENCOUNTERCLASS
                              ORDER BY TOTAL_CLAIM_COST DESC) AS cost_rank
    FROM encounters
    WHERE TOTAL_CLAIM_COST >= 0
)
SELECT ENCOUNTERCLASS, cost_rank, DESCRIPTION, SUBSTR(START, 1, 10) AS visit_date,
       ROUND(TOTAL_CLAIM_COST, 2) AS claim_cost
FROM ranked
WHERE cost_rank <= 3
ORDER BY ENCOUNTERCLASS, cost_rank;


-- Q3. Running total of claim costs by year, and each year's change.
WITH yearly AS (
    SELECT SUBSTR(START, 1, 4)       AS year,
           SUM(TOTAL_CLAIM_COST)     AS total_cost
    FROM encounters
    WHERE TOTAL_CLAIM_COST >= 0
    GROUP BY year
)
SELECT year,
       ROUND(total_cost, 0)                                         AS total_cost,
       ROUND(SUM(total_cost) OVER (ORDER BY year), 0)               AS running_total,
       ROUND(100.0 * (total_cost - LAG(total_cost) OVER (ORDER BY year))
             / LAG(total_cost) OVER (ORDER BY year), 1)             AS pct_change_vs_prior_year
FROM yearly
ORDER BY year;


-- Q4. Rank payers by total billed within each year (DENSE_RANK).
WITH payer_year AS (
    SELECT SUBSTR(e.START, 1, 4) AS year,
           py.NAME               AS payer,
           SUM(e.TOTAL_CLAIM_COST) AS billed
    FROM encounters e
    JOIN payers py ON py.ID = e.PAYER
    WHERE e.TOTAL_CLAIM_COST >= 0
    GROUP BY year, py.NAME
)
SELECT year, payer, ROUND(billed, 0) AS billed,
       DENSE_RANK() OVER (PARTITION BY year ORDER BY billed DESC) AS rank_in_year
FROM payer_year
ORDER BY year, rank_in_year;


-- Q5. Average gap in days between a patient's consecutive visits, by
--     encounter type of the earlier visit (how soon do people come back?).
WITH visits AS (
    SELECT PATIENT, ENCOUNTERCLASS, START,
           LAG(START) OVER (PARTITION BY PATIENT ORDER BY START) AS previous_visit,
           LAG(ENCOUNTERCLASS) OVER (PARTITION BY PATIENT ORDER BY START) AS previous_type
    FROM encounters
)
SELECT previous_type AS after_visit_type,
       COUNT(*)      AS return_visits,
       ROUND(AVG(JULIANDAY(SUBSTR(START, 1, 19)) - JULIANDAY(SUBSTR(previous_visit, 1, 19))), 0) AS avg_days_until_next_visit
FROM visits
WHERE previous_visit IS NOT NULL
GROUP BY previous_type
ORDER BY avg_days_until_next_visit;
