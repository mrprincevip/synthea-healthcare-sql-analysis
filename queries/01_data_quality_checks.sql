-- =====================================================================
-- 01_data_quality_checks.sql
-- Purpose : Audit the data before analysing it. Each check returns a
--           count of rows that break a rule; 0 means the check passed.
-- Dialect : SQLite (DB Browser for SQLite)
-- Quality dimensions covered: completeness, uniqueness, validity,
--           consistency and referential integrity.
-- =====================================================================


-- Q1. How many rows does each table hold? (baseline for every other check)
SELECT 'patients'   AS table_name, COUNT(*) AS row_count FROM patients
UNION ALL SELECT 'encounters',  COUNT(*) FROM encounters
UNION ALL SELECT 'conditions',  COUNT(*) FROM conditions
UNION ALL SELECT 'medications', COUNT(*) FROM medications
UNION ALL SELECT 'payers',      COUNT(*) FROM payers;


-- Q2. Data quality scorecard: one row per rule, with the number of failing rows.
SELECT 'Completeness' AS dimension,
       'Patient missing birth date' AS rule,
       COUNT(*) AS failing_rows
FROM patients
WHERE BIRTHDATE IS NULL OR TRIM(BIRTHDATE) = ''

UNION ALL
SELECT 'Completeness', 'Patient missing gender',
       COUNT(*) FROM patients
WHERE GENDER IS NULL OR TRIM(GENDER) = ''

UNION ALL
SELECT 'Completeness', 'Patient missing county',
       COUNT(*) FROM patients
WHERE COUNTY IS NULL OR TRIM(COUNTY) = ''

UNION ALL
SELECT 'Completeness', 'Encounter missing payer',
       COUNT(*) FROM encounters
WHERE PAYER IS NULL OR TRIM(PAYER) = ''

UNION ALL
SELECT 'Uniqueness', 'Duplicate patient IDs (extra copies)',
       COALESCE(SUM(copies - 1), 0)
FROM (SELECT ID, COUNT(*) AS copies FROM patients GROUP BY ID HAVING COUNT(*) > 1) AS dup_patients

UNION ALL
SELECT 'Uniqueness', 'Duplicate encounter IDs (extra copies)',
       COALESCE(SUM(copies - 1), 0)
FROM (SELECT ID, COUNT(*) AS copies FROM encounters GROUP BY ID HAVING COUNT(*) > 1) AS dup_encounters

UNION ALL
SELECT 'Validity', 'Birth date in the future',
       COUNT(*) FROM patients
WHERE BIRTHDATE > DATE('now')

UNION ALL
SELECT 'Validity', 'Negative claim cost',
       COUNT(*) FROM encounters
WHERE TOTAL_CLAIM_COST < 0

UNION ALL
SELECT 'Consistency', 'Encounter ends before it starts',
       COUNT(*) FROM encounters
WHERE STOP < START

UNION ALL
SELECT 'Consistency', 'Payer paid more than the claim cost',
       COUNT(*) FROM encounters
WHERE PAYER_COVERAGE > TOTAL_CLAIM_COST

UNION ALL
SELECT 'Consistency', 'Encounter after patient''s death date',
       COUNT(*) FROM encounters e
JOIN patients p ON p.ID = e.PATIENT
WHERE p.DEATHDATE IS NOT NULL
  AND SUBSTR(e.START, 1, 10) > p.DEATHDATE

UNION ALL
SELECT 'Referential integrity', 'Encounter with no matching patient',
       COUNT(*) FROM encounters e
LEFT JOIN patients p ON p.ID = e.PATIENT
WHERE p.ID IS NULL

UNION ALL
SELECT 'Referential integrity', 'Condition with no matching encounter',
       COUNT(*) FROM conditions c
LEFT JOIN encounters e ON e.ID = c.ENCOUNTER
WHERE e.ID IS NULL;


-- Q3. Show the actual failing encounter records so they can be investigated.
SELECT e.ID, e.PATIENT, e.START, e.STOP, e.TOTAL_CLAIM_COST, e.PAYER_COVERAGE,
       CASE
           WHEN e.STOP < e.START                       THEN 'Ends before it starts'
           WHEN e.TOTAL_CLAIM_COST < 0                 THEN 'Negative claim cost'
           WHEN e.PAYER_COVERAGE > e.TOTAL_CLAIM_COST  THEN 'Coverage exceeds cost'
       END AS issue
FROM encounters e
WHERE e.STOP < e.START
   OR e.TOTAL_CLAIM_COST < 0
   OR e.PAYER_COVERAGE > e.TOTAL_CLAIM_COST;


-- Q4. Overall completeness of key patient fields, as a percentage filled in.
SELECT COUNT(*) AS patients,
       ROUND(100.0 * COUNT(NULLIF(TRIM(GENDER), ''))    / COUNT(*), 1) AS pct_gender,
       ROUND(100.0 * COUNT(NULLIF(TRIM(BIRTHDATE), '')) / COUNT(*), 1) AS pct_birthdate,
       ROUND(100.0 * COUNT(NULLIF(TRIM(COUNTY), ''))    / COUNT(*), 1) AS pct_county,
       ROUND(100.0 * COUNT(NULLIF(TRIM(MARITAL), ''))   / COUNT(*), 1) AS pct_marital_status,
       ROUND(100.0 * COUNT(INCOME)                      / COUNT(*), 1) AS pct_income
FROM patients;
