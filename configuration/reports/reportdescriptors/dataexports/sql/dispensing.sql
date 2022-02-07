SET sql_safe_updates = 0;

SET @pharmacy_encounter = ENCOUNTER_TYPE('8ff50dea-18a1-4609-b4c9-3f8f2d611b84');
SET @pihliberia_emrid = (SELECT patient_identifier_type_id FROM patient_identifier_type WHERE retired = 0 AND uuid = '0bc545e0-f401-11e4-b939-0800200c9a66');

DROP TEMPORARY TABLE IF EXISTS temp_pharmacy_encounters;
CREATE TEMPORARY TABLE temp_pharmacy_encounters
(
encounter_id INT,
patient_id INT,
emr_id VARCHAR(25),
location_id INT,
location_name VARCHAR(50),   
encounter_date DATE,
type_of_prescription VARCHAR(50),
location_of_prescription VARCHAR(50),
title VARCHAR(50),
license VARCHAR(100),
prescriber VARCHAR(255),
medication_name1 TEXT,
dose1  DOUBLE,
doseInput1 VARCHAR(20),
frequency1 VARCHAR(255),
duration1 DOUBLE,
durationUnit1 VARCHAR(20),
route1 VARCHAR(20),
amount1 DOUBLE,
instructions1 TEXT,
medication_name2 TEXT,
dose2  DOUBLE,
doseInput2 VARCHAR(20),
frequency2 VARCHAR(255),
duration2 DOUBLE,
durationUnit2 VARCHAR(20),
route2 VARCHAR(20),
amount2 DOUBLE,
instructions2 TEXT,
medication_name3 TEXT,
dose3  DOUBLE,
doseInput3 VARCHAR(20),
frequency3 VARCHAR(255),
duration3 DOUBLE,
durationUnit3 VARCHAR(20),
route3 VARCHAR(20),
amount3 DOUBLE,
instructions3 TEXT,
medication_name4 TEXT,
dose4  DOUBLE,
doseInput4 VARCHAR(20),
frequency4 VARCHAR(255),
duration4 DOUBLE,
durationUnit4 VARCHAR(20),
route4 VARCHAR(20),
amount4 DOUBLE,
instructions4 TEXT,
medication_name5 TEXT,
dose5  DOUBLE,
doseInput5 VARCHAR(20),
frequency5 VARCHAR(255),
duration5 DOUBLE,
durationUnit5 VARCHAR(20),
route5 VARCHAR(20),
amount5 DOUBLE,
instructions5 TEXT,
medication_name6 TEXT,
dose6  DOUBLE,
doseInput6 VARCHAR(20),
frequency6 VARCHAR(255),
duration6 DOUBLE,
durationUnit6 VARCHAR(20),
route6 VARCHAR(20),
amount6 DOUBLE,
instructions6 TEXT,
medication_name7 TEXT,
dose7  DOUBLE,
doseInput7 VARCHAR(20),
frequency7 VARCHAR(255),
duration7 DOUBLE,
durationUnit7 VARCHAR(20),
route7 VARCHAR(20),
amount7 DOUBLE,
instructions7 TEXT
);

INSERT INTO temp_pharmacy_encounters(encounter_id, patient_id, location_id, encounter_date)
SELECT encounter_id, patient_id, location_id, DATE(encounter_datetime) FROM encounter e WHERE voided = 0 AND encounter_type = @pharmacy_encounter
AND DATE(e.encounter_datetime) >= @startDate AND DATE(e.encounter_datetime) <= @endDate;
 
UPDATE temp_pharmacy_encounters t SET type_of_prescription = OBS_VALUE_CODED_LIST(t.encounter_id, 'PIH', '9292', 'en');
UPDATE temp_pharmacy_encounters t SET t.location_name = LOCATION_NAME(t.location_id);

UPDATE temp_pharmacy_encounters t JOIN patient_identifier p ON p.voided = 0 AND p.patient_id = t.patient_id AND identifier_type = @pihliberia_emrid
SET emr_id = p.identifier;
 
-- Location of prescription
UPDATE temp_pharmacy_encounters t SET location_of_prescription = LOCATION_NAME(OBS_VALUE_TEXT(t.encounter_id, 'PIH', '9293'));

-- title
UPDATE temp_pharmacy_encounters t SET title =  OBS_VALUE_CODED_LIST(t.encounter_id, 'CIEL', '163556', 'en');

-- license
UPDATE temp_pharmacy_encounters t SET license = OBS_VALUE_NUMERIC(t.encounter_id, 'PIH', '13962');

-- Prescribe
UPDATE temp_pharmacy_encounters t SET prescriber = OBS_VALUE_TEXT(t.encounter_id, 'PIH', '6592');

-- Medications
DROP TEMPORARY TABLE IF EXISTS temp_pharmacy_dispensing_meds_obs_gid0;
CREATE TEMPORARY TABLE temp_pharmacy_dispensing_meds_obs_gid0(
encounter_id INT, 
obs_parent_id INT
);
INSERT INTO temp_pharmacy_dispensing_meds_obs_gid0(encounter_id, obs_parent_id) 
SELECT encounter_id, OBS_ID(encounter_id, 'PIH', 9070, 0) FROM temp_pharmacy_encounters;

UPDATE temp_pharmacy_encounters t SET medication_name1 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1282') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid0));

UPDATE temp_pharmacy_encounters t SET dose1 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160856') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid0));

UPDATE temp_pharmacy_encounters t SET doseInput1 = (SELECT value_text FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9074') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid0));

UPDATE temp_pharmacy_encounters t SET frequency1 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160855') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid0));

UPDATE temp_pharmacy_encounters t SET duration1 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '159368') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid0));

UPDATE temp_pharmacy_encounters t SET durationUnit1 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '6412') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid0));

UPDATE temp_pharmacy_encounters t SET route1 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '12651') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid0));

UPDATE temp_pharmacy_encounters t SET amount1 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1443') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid0));

UPDATE temp_pharmacy_encounters t SET instructions1 = (SELECT value_text FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9072') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid0));

DROP TEMPORARY TABLE IF EXISTS temp_pharmacy_dispensing_meds_obs_gid1;
CREATE TEMPORARY TABLE temp_pharmacy_dispensing_meds_obs_gid1(
encounter_id INT, 
obs_parent_id INT
);
INSERT INTO temp_pharmacy_dispensing_meds_obs_gid1(encounter_id, obs_parent_id) 
SELECT encounter_id, OBS_ID(encounter_id, 'PIH', 9070, 1) FROM temp_pharmacy_encounters;

UPDATE temp_pharmacy_encounters t SET medication_name2 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1282') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid1));

UPDATE temp_pharmacy_encounters t SET dose2 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160856') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid1));

UPDATE temp_pharmacy_encounters t SET doseInput2 = (SELECT value_text FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9074') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid1));

UPDATE temp_pharmacy_encounters t SET frequency2 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160855') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid1));

UPDATE temp_pharmacy_encounters t SET duration2 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '159368') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid1));

UPDATE temp_pharmacy_encounters t SET durationUnit2 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '6412') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid1));

UPDATE temp_pharmacy_encounters t SET route2 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '12651') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid1));

UPDATE temp_pharmacy_encounters t SET amount2 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1443') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid1));

UPDATE temp_pharmacy_encounters t SET instructions2 = (SELECT value_text FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9072') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid1));

DROP TEMPORARY TABLE IF EXISTS temp_pharmacy_dispensing_meds_obs_gid2;
CREATE TEMPORARY TABLE temp_pharmacy_dispensing_meds_obs_gid2(
encounter_id INT, 
obs_parent_id INT
);
INSERT INTO temp_pharmacy_dispensing_meds_obs_gid2(encounter_id, obs_parent_id) 
SELECT encounter_id, OBS_ID(encounter_id, 'PIH', 9070, 2) FROM temp_pharmacy_encounters;

UPDATE temp_pharmacy_encounters t SET medication_name3 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1282') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid2));

UPDATE temp_pharmacy_encounters t SET dose3 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160856') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid2));

UPDATE temp_pharmacy_encounters t SET doseInput3 = (SELECT value_text FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9074') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid2));

UPDATE temp_pharmacy_encounters t SET frequency3 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160855') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid2));

UPDATE temp_pharmacy_encounters t SET duration3 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '159368') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid2));

UPDATE temp_pharmacy_encounters t SET durationUnit3 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '6412') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid2));

UPDATE temp_pharmacy_encounters t SET route3 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '12651') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid2));

UPDATE temp_pharmacy_encounters t SET amount3 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1443') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid2));

UPDATE temp_pharmacy_encounters t SET instructions3 = (SELECT value_text FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9072') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid2));

DROP TEMPORARY TABLE IF EXISTS temp_pharmacy_dispensing_meds_obs_gid3;
CREATE TEMPORARY TABLE temp_pharmacy_dispensing_meds_obs_gid3(
encounter_id INT, 
obs_parent_id INT
);
INSERT INTO temp_pharmacy_dispensing_meds_obs_gid3(encounter_id, obs_parent_id) 
SELECT encounter_id, OBS_ID(encounter_id, 'PIH', 9070, 3) FROM temp_pharmacy_encounters;

UPDATE temp_pharmacy_encounters t SET medication_name4 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1282') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid3));

UPDATE temp_pharmacy_encounters t SET dose4 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160856') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid3));

UPDATE temp_pharmacy_encounters t SET doseInput4 = (SELECT value_text FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9074') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid3));

UPDATE temp_pharmacy_encounters t SET frequency4 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160855') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid3));

UPDATE temp_pharmacy_encounters t SET duration4 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '159368') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid3));

UPDATE temp_pharmacy_encounters t SET durationUnit4 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '6412') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid3));

UPDATE temp_pharmacy_encounters t SET route4 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '12651') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid3));

UPDATE temp_pharmacy_encounters t SET amount4 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1443') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid3));

UPDATE temp_pharmacy_encounters t SET instructions4 = (SELECT value_text FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9072') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid3));

DROP TEMPORARY TABLE IF EXISTS temp_pharmacy_dispensing_meds_obs_gid4;
CREATE TEMPORARY TABLE temp_pharmacy_dispensing_meds_obs_gid4(
encounter_id INT, 
obs_parent_id INT
);
INSERT INTO temp_pharmacy_dispensing_meds_obs_gid4(encounter_id, obs_parent_id) 
SELECT encounter_id, OBS_ID(encounter_id, 'PIH', 9070, 4) FROM temp_pharmacy_encounters;

UPDATE temp_pharmacy_encounters t SET medication_name5 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1282') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid4));

UPDATE temp_pharmacy_encounters t SET dose5 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160856') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid4));

UPDATE temp_pharmacy_encounters t SET doseInput5 = (SELECT value_text FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9074') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid4));

UPDATE temp_pharmacy_encounters t SET frequency5 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160855') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid4));

UPDATE temp_pharmacy_encounters t SET duration5 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '159368') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid4));

UPDATE temp_pharmacy_encounters t SET durationUnit5 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '6412') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid4));

UPDATE temp_pharmacy_encounters t SET route5 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '12651') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid4));

UPDATE temp_pharmacy_encounters t SET amount5 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1443') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid4));

UPDATE temp_pharmacy_encounters t SET instructions5 = (SELECT value_text FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9072') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid4));

DROP TEMPORARY TABLE IF EXISTS temp_pharmacy_dispensing_meds_obs_gid5;
CREATE TEMPORARY TABLE temp_pharmacy_dispensing_meds_obs_gid5(
encounter_id INT, 
obs_parent_id INT
);
INSERT INTO temp_pharmacy_dispensing_meds_obs_gid5(encounter_id, obs_parent_id) 
SELECT encounter_id, OBS_ID(encounter_id, 'PIH', 9070, 5) FROM temp_pharmacy_encounters;

UPDATE temp_pharmacy_encounters t SET medication_name6 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1282') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

UPDATE temp_pharmacy_encounters t SET dose6 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160856') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

UPDATE temp_pharmacy_encounters t SET doseInput6 = (SELECT value_text FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9074') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

UPDATE temp_pharmacy_encounters t SET frequency6 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160855') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

UPDATE temp_pharmacy_encounters t SET duration6 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '159368') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

UPDATE temp_pharmacy_encounters t SET durationUnit6 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '6412') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

UPDATE temp_pharmacy_encounters t SET route6 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '12651') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

UPDATE temp_pharmacy_encounters t SET amount6 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1443') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

UPDATE temp_pharmacy_encounters t SET instructions6 = (SELECT value_text FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9072') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

DROP TEMPORARY TABLE IF EXISTS temp_pharmacy_dispensing_meds_obs_gid5;
CREATE TEMPORARY TABLE temp_pharmacy_dispensing_meds_obs_gid5(
encounter_id INT, 
obs_parent_id INT
);
INSERT INTO temp_pharmacy_dispensing_meds_obs_gid5(encounter_id, obs_parent_id) 
SELECT encounter_id, OBS_ID(encounter_id, 'PIH', 9070, 6) FROM temp_pharmacy_encounters;

UPDATE temp_pharmacy_encounters t SET medication_name7 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1282') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

UPDATE temp_pharmacy_encounters t SET dose7 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160856') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

UPDATE temp_pharmacy_encounters t SET doseInput7 = (SELECT value_text FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9074') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

UPDATE temp_pharmacy_encounters t SET frequency7 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160855') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

UPDATE temp_pharmacy_encounters t SET duration7 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '159368') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

UPDATE temp_pharmacy_encounters t SET durationUnit7 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '6412') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

UPDATE temp_pharmacy_encounters t SET route7 = (SELECT CONCEPT_NAME(value_coded, 'en') FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '12651') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

UPDATE temp_pharmacy_encounters t SET amount7 = (SELECT value_numeric FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1443') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

UPDATE temp_pharmacy_encounters t SET instructions7 = (SELECT value_text FROM obs i WHERE i.encounter_id 
= t.encounter_id AND i.voided = 0 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9072') AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds_obs_gid5));

#final query
SELECT * FROM temp_pharmacy_encounters;