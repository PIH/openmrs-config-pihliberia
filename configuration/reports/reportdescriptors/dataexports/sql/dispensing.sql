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
frequency1 VARCHAR(20),
duration1 DOUBLE,
durationUnit1 VARCHAR(20),
route1 VARCHAR(20),
amount1 DOUBLE,
instructions1 TEXT,
medication_name2 TEXT,
dose2  DOUBLE,
doseInput2 VARCHAR(20),
frequency2 VARCHAR(20),
duration2 DOUBLE,
durationUnit2 VARCHAR(20),
route2 VARCHAR(20),
amount2 DOUBLE,
instructions2 TEXT,
medication_name3 TEXT,
dose3  DOUBLE,
doseInput3 VARCHAR(20),
frequency3 VARCHAR(20),
duration3 DOUBLE,
durationUnit3 VARCHAR(20),
route3 VARCHAR(20),
amount3 DOUBLE,
instructions3 TEXT,
medication_name4 TEXT,
dose4  DOUBLE,
doseInput4 VARCHAR(20),
frequency4 VARCHAR(20),
duration4 DOUBLE,
durationUnit4 VARCHAR(20),
route4 VARCHAR(20),
amount4 DOUBLE,
instructions4 TEXT,
medication_name5 TEXT,
dose5  DOUBLE,
doseInput5 VARCHAR(20),
frequency5 VARCHAR(20),
duration5 DOUBLE,
durationUnit5 VARCHAR(20),
route5 VARCHAR(20),
amount5 DOUBLE,
instructions5 TEXT,
medication_name6 TEXT,
dose6  DOUBLE,
doseInput6 VARCHAR(20),
frequency6 VARCHAR(20),
duration6 DOUBLE,
durationUnit6 VARCHAR(20),
route6 VARCHAR(20),
amount6 DOUBLE,
instructions6 TEXT,
medication_name7 TEXT,
dose7  DOUBLE,
doseInput7 VARCHAR(20),
frequency7 VARCHAR(20),
duration7 DOUBLE,
durationUnit7 VARCHAR(20),
route7 VARCHAR(20),
amount7 DOUBLE,
instructions7 TEXT
);

INSERT INTO temp_pharmacy_encounters(encounter_id, patient_id, location_id, encounter_date)
SELECT encounter_id, patient_id, location_id, DATE(encounter_datetime) FROM encounter WHERE voided = 0 AND encounter_type = @pharmacy_encounter;

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
DROP TEMPORARY TABLE IF EXISTS temp_pharmacy_dispensing_meds;
CREATE TEMPORARY TABLE temp_pharmacy_dispensing_meds(
obs_child_id INT,
encounter_id INT, 
obs_parent_id INT
);
INSERT INTO temp_pharmacy_dispensing_meds(encounter_id, obs_parent_id)
SELECT encounter_id, obs_id FROM obs WHERE voided = 0 AND concept_id = CONCEPT_FROM_MAPPING('PIH', '9070');

DROP TEMPORARY TABLE IF EXISTS temp_pharmacy_dispensing_meds_answers;
CREATE TEMPORARY TABLE temp_pharmacy_dispensing_meds_answers
AS
(
SELECT person_id, encounter_id, obs_id, obs_group_id, concept_id, value_coded, value_numeric, value_text, comments 
FROM obs WHERE voided = 0 AND obs_group_id IN (SELECT obs_parent_id FROM temp_pharmacy_dispensing_meds)
);

DROP TEMPORARY TABLE IF EXISTS temp_temp_pharmacy_dispensing_meds_counts;
CREATE TEMPORARY TABLE temp_temp_pharmacy_dispensing_meds_counts
(
    SELECT
            person_id, encounter_id, obs_id, obs_group_id, concept_id, CONCEPT_NAME(concept_id, 'en') cn, 
            value_coded, CONCEPT_NAME(value_coded, 'en') vc, value_numeric, value_text, comments, count
FROM (SELECT
			(CASE WHEN @u <> obs_group_id AND @p = encounter_id THEN @r := @r +1 ELSE @r END) count,
            person_id, 
            encounter_id, 
            obs_id, 
            obs_group_id, 
            concept_id,
            value_coded,
            CONCEPT_NAME(value_coded, 'en'),
            value_numeric, 
            value_text, 
            comments,
            @u:= obs_group_id,
            @p:= encounter_id
      FROM temp_pharmacy_dispensing_meds_answers,
        (SELECT @r:= 1) AS r,
        (SELECT @p:= 0) AS p,
		(SELECT @u:= 0) AS u
      ORDER BY person_id,  obs_group_id DESC
        ) index_ascending );

UPDATE temp_pharmacy_encounters t SET medication_name1 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 1 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1282'));
UPDATE temp_pharmacy_encounters t SET dose1 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 1 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160856'));
UPDATE temp_pharmacy_encounters t SET doseInput1 = (SELECT value_text FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 1 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9074'));
UPDATE temp_pharmacy_encounters t SET frequency1 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 1 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160855'));
UPDATE temp_pharmacy_encounters t SET duration1 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 1 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '159368'));
UPDATE temp_pharmacy_encounters t SET durationUnit1 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 1 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '6412'));
UPDATE temp_pharmacy_encounters t SET route1 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 1 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '12651'));
UPDATE temp_pharmacy_encounters t SET amount1 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 1 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1443'));
UPDATE temp_pharmacy_encounters t SET instructions1 = (SELECT value_text FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 1 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9072'));

UPDATE temp_pharmacy_encounters t SET medication_name2 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 2 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1282'));
UPDATE temp_pharmacy_encounters t SET dose2 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 2 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160856'));
UPDATE temp_pharmacy_encounters t SET doseInput2 = (SELECT value_text FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 2 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9074'));
UPDATE temp_pharmacy_encounters t SET frequency2 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 2 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160855'));
UPDATE temp_pharmacy_encounters t SET duration2 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 2 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '159368'));
UPDATE temp_pharmacy_encounters t SET durationUnit2 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 2 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '6412'));
UPDATE temp_pharmacy_encounters t SET route2 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 2 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '12651'));
UPDATE temp_pharmacy_encounters t SET amount2 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 2 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1443'));
UPDATE temp_pharmacy_encounters t SET instructions2 = (SELECT value_text FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 2 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9072'));


UPDATE temp_pharmacy_encounters t SET medication_name3 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 3 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1282'));
UPDATE temp_pharmacy_encounters t SET dose3 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 3 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160856'));
UPDATE temp_pharmacy_encounters t SET doseInput3 = (SELECT value_text FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 3 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9074'));
UPDATE temp_pharmacy_encounters t SET frequency3 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 3 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160855'));
UPDATE temp_pharmacy_encounters t SET duration3 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 3 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '159368'));
UPDATE temp_pharmacy_encounters t SET durationUnit3 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 3 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '6412'));
UPDATE temp_pharmacy_encounters t SET route3 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 3 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '12651'));
UPDATE temp_pharmacy_encounters t SET amount3 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 3 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1443'));
UPDATE temp_pharmacy_encounters t SET instructions3 = (SELECT value_text FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 3 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9072'));

UPDATE temp_pharmacy_encounters t SET medication_name4 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 4 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1282'));
UPDATE temp_pharmacy_encounters t SET dose4 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 4 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160856'));
UPDATE temp_pharmacy_encounters t SET doseInput4 = (SELECT value_text FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 4 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9074'));
UPDATE temp_pharmacy_encounters t SET frequency4 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 4 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160855'));
UPDATE temp_pharmacy_encounters t SET duration4 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 4 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '159368'));
UPDATE temp_pharmacy_encounters t SET durationUnit4 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 4 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '6412'));
UPDATE temp_pharmacy_encounters t SET route4 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 4 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '12651'));
UPDATE temp_pharmacy_encounters t SET amount4 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 4 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1443'));
UPDATE temp_pharmacy_encounters t SET instructions4 = (SELECT value_text FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 4 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9072'));

UPDATE temp_pharmacy_encounters t SET medication_name5 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 5 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1282'));
UPDATE temp_pharmacy_encounters t SET dose5 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 5 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160856'));
UPDATE temp_pharmacy_encounters t SET doseInput5 = (SELECT value_text FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 5 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9074'));
UPDATE temp_pharmacy_encounters t SET frequency5 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 5 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160855'));
UPDATE temp_pharmacy_encounters t SET duration5 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 5 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '159368'));
UPDATE temp_pharmacy_encounters t SET durationUnit5 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 5 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '6412'));
UPDATE temp_pharmacy_encounters t SET route5 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 5 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '12651'));
UPDATE temp_pharmacy_encounters t SET amount5 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 5 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1443'));
UPDATE temp_pharmacy_encounters t SET instructions5 = (SELECT value_text FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 5 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9072'));

UPDATE temp_pharmacy_encounters t SET medication_name6 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 6 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1282'));
UPDATE temp_pharmacy_encounters t SET dose6 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 6 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160856'));
UPDATE temp_pharmacy_encounters t SET doseInput6 = (SELECT value_text FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 6 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9074'));
UPDATE temp_pharmacy_encounters t SET frequency6 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 6 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160855'));
UPDATE temp_pharmacy_encounters t SET duration6 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 6 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '159368'));
UPDATE temp_pharmacy_encounters t SET durationUnit6 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 6 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '6412'));
UPDATE temp_pharmacy_encounters t SET route6 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 6 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '12651'));
UPDATE temp_pharmacy_encounters t SET amount6 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 6 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1443'));
UPDATE temp_pharmacy_encounters t SET instructions6 = (SELECT value_text FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 6 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9072'));

UPDATE temp_pharmacy_encounters t SET medication_name7 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 7 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1282'));
UPDATE temp_pharmacy_encounters t SET dose7 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 7 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160856'));
UPDATE temp_pharmacy_encounters t SET doseInput7 = (SELECT value_text FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 7 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9074'));
UPDATE temp_pharmacy_encounters t SET frequency7 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 7 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '160855'));
UPDATE temp_pharmacy_encounters t SET duration7 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 7 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '159368'));
UPDATE temp_pharmacy_encounters t SET durationUnit7 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 7 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '6412'));
UPDATE temp_pharmacy_encounters t SET route7 = (SELECT vc FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 7 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '12651'));
UPDATE temp_pharmacy_encounters t SET amount7 = (SELECT value_numeric FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 7 AND concept_id = CONCEPT_FROM_MAPPING ('CIEL', '1443'));
UPDATE temp_pharmacy_encounters t SET instructions7 = (SELECT value_text FROM temp_temp_pharmacy_dispensing_meds_counts i WHERE i.encounter_id 
= t.encounter_id AND count = 7 AND concept_id = CONCEPT_FROM_MAPPING ('PIH', '9072'));

SELECT * FROM temp_pharmacy_encounters;