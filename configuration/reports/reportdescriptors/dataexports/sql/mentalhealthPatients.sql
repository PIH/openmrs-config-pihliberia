set @program_id = program('Mental Health');
SELECT encounter_type_id INTO @mh_intake_enc FROM encounter_type WHERE uuid = 'fccd53c2-f802-439b-a7a2-2d680bd8b81b';
set @identifier_type ='0bc545e0-f401-11e4-b939-0800200c9a66';

DROP TABLE IF EXISTS temp_mh_patients;
create temporary table temp_mh_patients
(
patient_id int,
program_id int,
encounter_id int,
emr_id varchar(255),
mh_mrn varchar(255),
dob date,
community varchar(255),
district varchar(255),
county varchar(255),
gender varchar(255),
referred_by varchar(255),
referred_from varchar(255),
date_enrolled date,
counseling_plan text,
outcome_date date,
program_outcome varchar(255)
);

INSERT INTO temp_mh_patients (patient_id, program_id, date_enrolled, outcome_date, program_outcome)
SELECT
    patient_id,
    program_id,
    date_enrolled,
    date_completed,
	concept_name(outcome_concept_id, 'en')
FROM patient_program
WHERE program_id = @program_id AND voided = 0;


set @mh_identifier = '23507d1e-4f22-11ea-9717-645d86728797'; -- mental health patient assign number

update temp_mh_patients set emr_id = patient_identifier(patient_id, @identifier_type);
UPDATE temp_mh_patients SET mh_mrn = PATIENT_IDENTIFIER(patient_id, @mh_identifier);
UPDATE temp_mh_patients SET community = PERSON_ADDRESS_ONE(patient_id);
UPDATE temp_mh_patients SET district= person_address_city_village(patient_id);
UPDATE temp_mh_patients SET county = person_address_state_province(patient_id);



DROP TABLE IF EXISTS temp_encounter;
CREATE TEMPORARY TABLE temp_encounter AS
SELECT patient_id, encounter_id, encounter_datetime, encounter_type
FROM encounter e
WHERE e.encounter_type = @mh_intake_enc
AND e.voided =0;

CREATE INDEX t_enc_patient_id ON temp_encounter (patient_id);

DROP TABLE IF EXISTS temp_obs;
CREATE TEMPORARY TABLE temp_obs AS
SELECT o.person_id, o.obs_id , o.obs_group_id , o.obs_datetime ,o.date_created , o.encounter_id, o.value_coded, o.concept_id, o.value_numeric , o.value_datetime , o.value_text , o.voided
FROM temp_encounter te  INNER JOIN  obs o ON te.encounter_id=o.encounter_id
WHERE o.voided =0;

UPDATE temp_mh_patients tmh
SET
	tmh.gender = GENDER(tmh.patient_id),
	tmh.dob = BIRTHDATE(tmh.patient_id);

UPDATE temp_mh_patients tmh
INNER JOIN temp_obs o ON tmh.patient_id = o.person_id
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', '10647')
SET tmh.referred_by = CONCEPT_NAME(value_coded, 'en');

UPDATE temp_mh_patients tmh
INNER JOIN temp_obs o ON tmh.patient_id = o.person_id
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', '1272')
SET tmh.referred_from = CONCEPT_NAME(value_coded, 'en');

UPDATE temp_mh_patients tmh
INNER JOIN temp_obs o ON tmh.patient_id = o.person_id
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', '14479')
SET tmh.counseling_plan = o.value_text
WHERE o.value_text = 0;


SELECT
    emr_id,
    mh_mrn,
    dob,
    gender,
    community,
    district,
    county,
    referred_by,
    referred_from,
    date_enrolled,
    outcome_date,
    counseling_plan,
    program_outcome
FROM
    temp_mh_patients;