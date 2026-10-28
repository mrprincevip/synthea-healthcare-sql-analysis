-- =====================================================================
-- 00_create_and_load_uploads.sql
-- Purpose : Same as 00_create_and_load.sql, but reads the CSVs from
--           MySQL's own Uploads folder, so no LOCAL loading setting is
--           needed (avoids Error 2068 in MySQL Workbench).
-- Dialect : MySQL 8.0+ (MySQL Workbench)
--
-- BEFORE YOU RUN THIS:
--   1. Run:  SHOW VARIABLES LIKE 'secure_file_priv';
--      The Value column is the folder MySQL may read from, usually
--      C:\ProgramData\MySQL\MySQL Server 8.0\Uploads\
--   2. Copy the 7 Synthea CSV files into that folder. (ProgramData is
--      hidden: paste the path into File Explorer's address bar.)
--   3. If your folder differs, Find & Replace the path below with yours,
--      using forward slashes /.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS synthea;
USE synthea;


-- ---------------------------------------------------------------- patients
DROP TABLE IF EXISTS patients;
CREATE TABLE patients (
    `ID`                      VARCHAR(64),
    `BIRTHDATE`               DATE,
    `DEATHDATE`               DATE,
    `SSN`                     VARCHAR(20),
    `DRIVERS`                 VARCHAR(20),
    `PASSPORT`                VARCHAR(20),
    `PREFIX`                  VARCHAR(10),
    `FIRST`                   VARCHAR(100),
    `MIDDLE`                  VARCHAR(100),
    `LAST`                    VARCHAR(100),
    `SUFFIX`                  VARCHAR(10),
    `MAIDEN`                  VARCHAR(100),
    `MARITAL`                 VARCHAR(5),
    `RACE`                    VARCHAR(30),
    `ETHNICITY`               VARCHAR(30),
    `GENDER`                  VARCHAR(5),
    `BIRTHPLACE`              VARCHAR(255),
    `ADDRESS`                 VARCHAR(255),
    `CITY`                    VARCHAR(100),
    `STATE`                   VARCHAR(50),
    `COUNTY`                  VARCHAR(100),
    `FIPS`                    VARCHAR(10),
    `ZIP`                     VARCHAR(10),
    `LAT`                     DOUBLE,
    `LON`                     DOUBLE,
    `HEALTHCARE_EXPENSES`     DECIMAL(14,2),
    `HEALTHCARE_COVERAGE`     DECIMAL(14,2),
    `INCOME`                  INT
);

-- Expected CSV header:
-- Id,BIRTHDATE,DEATHDATE,SSN,DRIVERS,PASSPORT,PREFIX,FIRST,MIDDLE,LAST,SUFFIX,MAIDEN,MARITAL,RACE,ETHNICITY,GENDER,BIRTHPLACE,ADDRESS,CITY,STATE,COUNTY,FIPS,ZIP,LAT,LON,HEALTHCARE_EXPENSES,HEALTHCARE_COVERAGE,INCOME
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/patients.csv'
INTO TABLE patients
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@id, @birthdate, @deathdate, @ssn, @drivers, @passport, @prefix, @first, @middle, @last, @suffix, @maiden, @marital, @race, @ethnicity, @gender, @birthplace, @address, @city, @state, @county, @fips, @zip, @lat, @lon, @healthcare_expenses, @healthcare_coverage, @income)
SET `ID` = NULLIF(@id, ''),
    `BIRTHDATE` = NULLIF(@birthdate, ''),
    `DEATHDATE` = NULLIF(@deathdate, ''),
    `SSN` = NULLIF(@ssn, ''),
    `DRIVERS` = NULLIF(@drivers, ''),
    `PASSPORT` = NULLIF(@passport, ''),
    `PREFIX` = NULLIF(@prefix, ''),
    `FIRST` = NULLIF(@first, ''),
    `MIDDLE` = NULLIF(@middle, ''),
    `LAST` = NULLIF(@last, ''),
    `SUFFIX` = NULLIF(@suffix, ''),
    `MAIDEN` = NULLIF(@maiden, ''),
    `MARITAL` = NULLIF(@marital, ''),
    `RACE` = NULLIF(@race, ''),
    `ETHNICITY` = NULLIF(@ethnicity, ''),
    `GENDER` = NULLIF(@gender, ''),
    `BIRTHPLACE` = NULLIF(@birthplace, ''),
    `ADDRESS` = NULLIF(@address, ''),
    `CITY` = NULLIF(@city, ''),
    `STATE` = NULLIF(@state, ''),
    `COUNTY` = NULLIF(@county, ''),
    `FIPS` = NULLIF(@fips, ''),
    `ZIP` = NULLIF(@zip, ''),
    `LAT` = NULLIF(@lat, ''),
    `LON` = NULLIF(@lon, ''),
    `HEALTHCARE_EXPENSES` = NULLIF(@healthcare_expenses, ''),
    `HEALTHCARE_COVERAGE` = NULLIF(@healthcare_coverage, ''),
    `INCOME` = NULLIF(TRIM(TRAILING '\r' FROM @income), '');
CREATE INDEX idx_patients_id ON patients (`ID`);

-- ---------------------------------------------------------------- encounters
DROP TABLE IF EXISTS encounters;
CREATE TABLE encounters (
    `ID`                      VARCHAR(64),
    `START`                   DATETIME,
    `STOP`                    DATETIME,
    `PATIENT`                 VARCHAR(64),
    `ORGANIZATION`            VARCHAR(64),
    `PROVIDER`                VARCHAR(64),
    `PAYER`                   VARCHAR(64),
    `ENCOUNTERCLASS`          VARCHAR(30),
    `CODE`                    VARCHAR(30),
    `DESCRIPTION`             TEXT,
    `BASE_ENCOUNTER_COST`     DECIMAL(14,2),
    `TOTAL_CLAIM_COST`        DECIMAL(14,2),
    `PAYER_COVERAGE`          DECIMAL(14,2),
    `REASONCODE`              VARCHAR(30),
    `REASONDESCRIPTION`       TEXT
);

-- Expected CSV header:
-- Id,START,STOP,PATIENT,ORGANIZATION,PROVIDER,PAYER,ENCOUNTERCLASS,CODE,DESCRIPTION,BASE_ENCOUNTER_COST,TOTAL_CLAIM_COST,PAYER_COVERAGE,REASONCODE,REASONDESCRIPTION
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/encounters.csv'
INTO TABLE encounters
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@id, @start, @stop, @patient, @organization, @provider, @payer, @encounterclass, @code, @description, @base_encounter_cost, @total_claim_cost, @payer_coverage, @reasoncode, @reasondescription)
SET `ID` = NULLIF(@id, ''),
    `START` = CAST(REPLACE(REPLACE(NULLIF(@start, ''), 'T', ' '), 'Z', '') AS DATETIME),
    `STOP` = CAST(REPLACE(REPLACE(NULLIF(@stop, ''), 'T', ' '), 'Z', '') AS DATETIME),
    `PATIENT` = NULLIF(@patient, ''),
    `ORGANIZATION` = NULLIF(@organization, ''),
    `PROVIDER` = NULLIF(@provider, ''),
    `PAYER` = NULLIF(@payer, ''),
    `ENCOUNTERCLASS` = NULLIF(@encounterclass, ''),
    `CODE` = NULLIF(@code, ''),
    `DESCRIPTION` = NULLIF(@description, ''),
    `BASE_ENCOUNTER_COST` = NULLIF(@base_encounter_cost, ''),
    `TOTAL_CLAIM_COST` = NULLIF(@total_claim_cost, ''),
    `PAYER_COVERAGE` = NULLIF(@payer_coverage, ''),
    `REASONCODE` = NULLIF(@reasoncode, ''),
    `REASONDESCRIPTION` = NULLIF(TRIM(TRAILING '\r' FROM @reasondescription), '');
CREATE INDEX idx_encounters_id ON encounters (`ID`);
CREATE INDEX idx_encounters_patient ON encounters (`PATIENT`);
CREATE INDEX idx_encounters_payer ON encounters (`PAYER`);
CREATE INDEX idx_encounters_organization ON encounters (`ORGANIZATION`);

-- ---------------------------------------------------------------- conditions
DROP TABLE IF EXISTS conditions;
CREATE TABLE conditions (
    `START`                   DATE,
    `STOP`                    DATE,
    `PATIENT`                 VARCHAR(64),
    `ENCOUNTER`               VARCHAR(64),
    `SYSTEM`                  VARCHAR(100),
    `CODE`                    VARCHAR(30),
    `DESCRIPTION`             TEXT
);

-- Expected CSV header:
-- START,STOP,PATIENT,ENCOUNTER,SYSTEM,CODE,DESCRIPTION
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/conditions.csv'
INTO TABLE conditions
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@start, @stop, @patient, @encounter, @system, @code, @description)
SET `START` = NULLIF(@start, ''),
    `STOP` = NULLIF(@stop, ''),
    `PATIENT` = NULLIF(@patient, ''),
    `ENCOUNTER` = NULLIF(@encounter, ''),
    `SYSTEM` = NULLIF(@system, ''),
    `CODE` = NULLIF(@code, ''),
    `DESCRIPTION` = NULLIF(TRIM(TRAILING '\r' FROM @description), '');
CREATE INDEX idx_conditions_patient ON conditions (`PATIENT`);
CREATE INDEX idx_conditions_encounter ON conditions (`ENCOUNTER`);

-- ---------------------------------------------------------------- medications
DROP TABLE IF EXISTS medications;
CREATE TABLE medications (
    `START`                   DATETIME,
    `STOP`                    DATETIME,
    `PATIENT`                 VARCHAR(64),
    `PAYER`                   VARCHAR(64),
    `ENCOUNTER`               VARCHAR(64),
    `CODE`                    VARCHAR(30),
    `DESCRIPTION`             TEXT,
    `BASE_COST`               DECIMAL(14,2),
    `PAYER_COVERAGE`          DECIMAL(14,2),
    `DISPENSES`               INT,
    `TOTALCOST`               DECIMAL(14,2),
    `REASONCODE`              VARCHAR(30),
    `REASONDESCRIPTION`       TEXT
);

-- Expected CSV header:
-- START,STOP,PATIENT,PAYER,ENCOUNTER,CODE,DESCRIPTION,BASE_COST,PAYER_COVERAGE,DISPENSES,TOTALCOST,REASONCODE,REASONDESCRIPTION
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/medications.csv'
INTO TABLE medications
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@start, @stop, @patient, @payer, @encounter, @code, @description, @base_cost, @payer_coverage, @dispenses, @totalcost, @reasoncode, @reasondescription)
SET `START` = CAST(REPLACE(REPLACE(NULLIF(@start, ''), 'T', ' '), 'Z', '') AS DATETIME),
    `STOP` = CAST(REPLACE(REPLACE(NULLIF(@stop, ''), 'T', ' '), 'Z', '') AS DATETIME),
    `PATIENT` = NULLIF(@patient, ''),
    `PAYER` = NULLIF(@payer, ''),
    `ENCOUNTER` = NULLIF(@encounter, ''),
    `CODE` = NULLIF(@code, ''),
    `DESCRIPTION` = NULLIF(@description, ''),
    `BASE_COST` = NULLIF(@base_cost, ''),
    `PAYER_COVERAGE` = NULLIF(@payer_coverage, ''),
    `DISPENSES` = NULLIF(@dispenses, ''),
    `TOTALCOST` = NULLIF(@totalcost, ''),
    `REASONCODE` = NULLIF(@reasoncode, ''),
    `REASONDESCRIPTION` = NULLIF(TRIM(TRAILING '\r' FROM @reasondescription), '');
CREATE INDEX idx_medications_patient ON medications (`PATIENT`);
CREATE INDEX idx_medications_encounter ON medications (`ENCOUNTER`);

-- ---------------------------------------------------------------- payers
DROP TABLE IF EXISTS payers;
CREATE TABLE payers (
    `ID`                      VARCHAR(64),
    `NAME`                    VARCHAR(255),
    `OWNERSHIP`               VARCHAR(50),
    `ADDRESS`                 VARCHAR(255),
    `CITY`                    VARCHAR(100),
    `STATE_HEADQUARTERED`     VARCHAR(50),
    `ZIP`                     VARCHAR(10),
    `PHONE`                   VARCHAR(30),
    `AMOUNT_COVERED`          DECIMAL(14,2),
    `AMOUNT_UNCOVERED`        DECIMAL(14,2),
    `REVENUE`                 DECIMAL(14,2),
    `COVERED_ENCOUNTERS`      INT,
    `UNCOVERED_ENCOUNTERS`    INT,
    `COVERED_MEDICATIONS`     INT,
    `UNCOVERED_MEDICATIONS`   INT,
    `COVERED_PROCEDURES`      INT,
    `UNCOVERED_PROCEDURES`    INT,
    `COVERED_IMMUNIZATIONS`   INT,
    `UNCOVERED_IMMUNIZATIONS` INT,
    `UNIQUE_CUSTOMERS`        INT,
    `QOLS_AVG`                DOUBLE,
    `MEMBER_MONTHS`           INT
);

-- Expected CSV header:
-- Id,NAME,OWNERSHIP,ADDRESS,CITY,STATE_HEADQUARTERED,ZIP,PHONE,AMOUNT_COVERED,AMOUNT_UNCOVERED,REVENUE,COVERED_ENCOUNTERS,UNCOVERED_ENCOUNTERS,COVERED_MEDICATIONS,UNCOVERED_MEDICATIONS,COVERED_PROCEDURES,UNCOVERED_PROCEDURES,COVERED_IMMUNIZATIONS,UNCOVERED_IMMUNIZATIONS,UNIQUE_CUSTOMERS,QOLS_AVG,MEMBER_MONTHS
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/payers.csv'
INTO TABLE payers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@id, @name, @ownership, @address, @city, @state_headquartered, @zip, @phone, @amount_covered, @amount_uncovered, @revenue, @covered_encounters, @uncovered_encounters, @covered_medications, @uncovered_medications, @covered_procedures, @uncovered_procedures, @covered_immunizations, @uncovered_immunizations, @unique_customers, @qols_avg, @member_months)
SET `ID` = NULLIF(@id, ''),
    `NAME` = NULLIF(@name, ''),
    `OWNERSHIP` = NULLIF(@ownership, ''),
    `ADDRESS` = NULLIF(@address, ''),
    `CITY` = NULLIF(@city, ''),
    `STATE_HEADQUARTERED` = NULLIF(@state_headquartered, ''),
    `ZIP` = NULLIF(@zip, ''),
    `PHONE` = NULLIF(@phone, ''),
    `AMOUNT_COVERED` = NULLIF(@amount_covered, ''),
    `AMOUNT_UNCOVERED` = NULLIF(@amount_uncovered, ''),
    `REVENUE` = NULLIF(@revenue, ''),
    `COVERED_ENCOUNTERS` = NULLIF(@covered_encounters, ''),
    `UNCOVERED_ENCOUNTERS` = NULLIF(@uncovered_encounters, ''),
    `COVERED_MEDICATIONS` = NULLIF(@covered_medications, ''),
    `UNCOVERED_MEDICATIONS` = NULLIF(@uncovered_medications, ''),
    `COVERED_PROCEDURES` = NULLIF(@covered_procedures, ''),
    `UNCOVERED_PROCEDURES` = NULLIF(@uncovered_procedures, ''),
    `COVERED_IMMUNIZATIONS` = NULLIF(@covered_immunizations, ''),
    `UNCOVERED_IMMUNIZATIONS` = NULLIF(@uncovered_immunizations, ''),
    `UNIQUE_CUSTOMERS` = NULLIF(@unique_customers, ''),
    `QOLS_AVG` = NULLIF(@qols_avg, ''),
    `MEMBER_MONTHS` = NULLIF(TRIM(TRAILING '\r' FROM @member_months), '');
CREATE INDEX idx_payers_id ON payers (`ID`);

-- ---------------------------------------------------------------- organizations
DROP TABLE IF EXISTS organizations;
CREATE TABLE organizations (
    `ID`                      VARCHAR(64),
    `NAME`                    VARCHAR(255),
    `ADDRESS`                 VARCHAR(255),
    `CITY`                    VARCHAR(100),
    `STATE`                   VARCHAR(50),
    `ZIP`                     VARCHAR(10),
    `LAT`                     DOUBLE,
    `LON`                     DOUBLE,
    `PHONE`                   VARCHAR(30),
    `REVENUE`                 DECIMAL(14,2),
    `UTILIZATION`             INT
);

-- Expected CSV header:
-- Id,NAME,ADDRESS,CITY,STATE,ZIP,LAT,LON,PHONE,REVENUE,UTILIZATION
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/organizations.csv'
INTO TABLE organizations
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@id, @name, @address, @city, @state, @zip, @lat, @lon, @phone, @revenue, @utilization)
SET `ID` = NULLIF(@id, ''),
    `NAME` = NULLIF(@name, ''),
    `ADDRESS` = NULLIF(@address, ''),
    `CITY` = NULLIF(@city, ''),
    `STATE` = NULLIF(@state, ''),
    `ZIP` = NULLIF(@zip, ''),
    `LAT` = NULLIF(@lat, ''),
    `LON` = NULLIF(@lon, ''),
    `PHONE` = NULLIF(@phone, ''),
    `REVENUE` = NULLIF(@revenue, ''),
    `UTILIZATION` = NULLIF(TRIM(TRAILING '\r' FROM @utilization), '');
CREATE INDEX idx_organizations_id ON organizations (`ID`);

-- ---------------------------------------------------------------- providers
DROP TABLE IF EXISTS providers;
CREATE TABLE providers (
    `ID`                      VARCHAR(64),
    `ORGANIZATION`            VARCHAR(64),
    `NAME`                    VARCHAR(255),
    `GENDER`                  VARCHAR(5),
    `SPECIALITY`              VARCHAR(100),
    `ADDRESS`                 VARCHAR(255),
    `CITY`                    VARCHAR(100),
    `STATE`                   VARCHAR(50),
    `ZIP`                     VARCHAR(10),
    `LAT`                     DOUBLE,
    `LON`                     DOUBLE,
    `ENCOUNTERS`              INT,
    `PROCEDURES`              INT
);

-- Expected CSV header:
-- Id,ORGANIZATION,NAME,GENDER,SPECIALITY,ADDRESS,CITY,STATE,ZIP,LAT,LON,ENCOUNTERS,PROCEDURES
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/providers.csv'
INTO TABLE providers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@id, @organization, @name, @gender, @speciality, @address, @city, @state, @zip, @lat, @lon, @encounters, @procedures)
SET `ID` = NULLIF(@id, ''),
    `ORGANIZATION` = NULLIF(@organization, ''),
    `NAME` = NULLIF(@name, ''),
    `GENDER` = NULLIF(@gender, ''),
    `SPECIALITY` = NULLIF(@speciality, ''),
    `ADDRESS` = NULLIF(@address, ''),
    `CITY` = NULLIF(@city, ''),
    `STATE` = NULLIF(@state, ''),
    `ZIP` = NULLIF(@zip, ''),
    `LAT` = NULLIF(@lat, ''),
    `LON` = NULLIF(@lon, ''),
    `ENCOUNTERS` = NULLIF(@encounters, ''),
    `PROCEDURES` = NULLIF(TRIM(TRAILING '\r' FROM @procedures), '');
CREATE INDEX idx_providers_id ON providers (`ID`);

-- ---------------------------------------------------------------- check
-- Row counts: every table should have rows. If one shows 0, check its
-- file name and header line.
SELECT 'patients' AS table_name, COUNT(*) AS row_count FROM patients
UNION ALL SELECT 'encounters',    COUNT(*) FROM encounters
UNION ALL SELECT 'conditions',    COUNT(*) FROM conditions
UNION ALL SELECT 'medications',   COUNT(*) FROM medications
UNION ALL SELECT 'payers',        COUNT(*) FROM payers
UNION ALL SELECT 'organizations', COUNT(*) FROM organizations
UNION ALL SELECT 'providers',     COUNT(*) FROM providers;

