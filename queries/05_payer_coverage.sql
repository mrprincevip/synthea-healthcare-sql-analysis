-- =====================================================================
-- 05_payer_coverage.sql
-- Purpose : Who pays for care? Coverage rates by insurer, the
--           uninsured gap, and patients' out-of-pocket burden.
-- Dialect : SQLite (DB Browser for SQLite)
-- Note    : out-of-pocket = TOTAL_CLAIM_COST - PAYER_COVERAGE.
--           Synthea names the uninsured "payer" NO_INSURANCE.
-- =====================================================================


-- Q1. Coverage by payer: how much of the billed cost each insurer paid.
SELECT py.NAME                                 AS payer,
       COUNT(e.ID)                             AS encounters,
       COUNT(DISTINCT e.PATIENT)               AS patients,
       ROUND(SUM(e.TOTAL_CLAIM_COST), 0)       AS total_billed,
       ROUND(SUM(e.PAYER_COVERAGE), 0)         AS total_paid_by_payer,
       ROUND(100.0 * SUM(e.PAYER_COVERAGE) / NULLIF(SUM(e.TOTAL_CLAIM_COST), 0), 1) AS coverage_rate_pct
FROM encounters e
JOIN payers py ON py.ID = e.PAYER
WHERE e.TOTAL_CLAIM_COST >= 0
  AND e.PAYER_COVERAGE <= e.TOTAL_CLAIM_COST
GROUP BY py.ID, py.NAME
ORDER BY total_billed DESC;


-- Q2. Government vs private vs uninsured, using the payer's ownership type.
SELECT COALESCE(py.OWNERSHIP, 'Unknown')       AS ownership,
       COUNT(e.ID)                             AS encounters,
       ROUND(AVG(e.TOTAL_CLAIM_COST - e.PAYER_COVERAGE), 2) AS avg_out_of_pocket_per_visit
FROM encounters e
JOIN payers py ON py.ID = e.PAYER
WHERE e.TOTAL_CLAIM_COST >= 0
  AND e.PAYER_COVERAGE <= e.TOTAL_CLAIM_COST
GROUP BY ownership
ORDER BY avg_out_of_pocket_per_visit DESC;


-- Q3. Emergency visits by uninsured vs insured patients: average bill
--     and out-of-pocket cost.
SELECT CASE WHEN py.NAME = 'NO_INSURANCE' THEN 'Uninsured' ELSE 'Insured' END AS insurance_status,
       COUNT(*)                                             AS emergency_visits,
       ROUND(AVG(e.TOTAL_CLAIM_COST), 2)                    AS avg_bill,
       ROUND(AVG(e.TOTAL_CLAIM_COST - e.PAYER_COVERAGE), 2) AS avg_out_of_pocket
FROM encounters e
JOIN payers py ON py.ID = e.PAYER
WHERE e.ENCOUNTERCLASS = 'emergency'
  AND e.TOTAL_CLAIM_COST >= 0
  AND e.PAYER_COVERAGE <= e.TOTAL_CLAIM_COST
GROUP BY insurance_status;


-- Q4. Top 10 patients by out-of-pocket cost (IDs only; Synthea data is
--     synthetic, but real analyses should never expose patient names).
SELECT e.PATIENT,
       COUNT(*)                                             AS encounters,
       ROUND(SUM(e.TOTAL_CLAIM_COST), 0)                    AS total_billed,
       ROUND(SUM(e.TOTAL_CLAIM_COST - e.PAYER_COVERAGE), 0) AS total_out_of_pocket
FROM encounters e
WHERE e.TOTAL_CLAIM_COST >= 0
  AND e.PAYER_COVERAGE <= e.TOTAL_CLAIM_COST
GROUP BY e.PATIENT
ORDER BY total_out_of_pocket DESC
LIMIT 10;
