
SELECT encounter_type_id  INTO @disp_enc_type FROM encounter_type et WHERE uuid='8ff50dea-18a1-4609-b4c9-3f8f2d611b84';

DROP TABLE IF EXISTS all_medication_dispensing;
CREATE TEMPORARY TABLE all_medication_dispensing
(
patient_id int,
obs_group_id int,
form varchar(10),
emr_id varchar(50),
encounter_id int,
encounter_datetime date,
encounter_location varchar(100),
type_of_prescription VARCHAR(50),
location_of_prescription VARCHAR(50),
title VARCHAR(50),
license VARCHAR(100),
prescriber VARCHAR(255),
date_entered date,
user_entered varchar(30),
encounter_provider varchar(30),
drug_id int(11),
drug_name varchar(500),
drug_openboxes_code int,
duration int,
duration_unit varchar(20),
quantity_per_dose double,
dose_unit text,
frequency varchar(50),
quantity_dispensed int,
route varchar(20),
instructions text
);

-- add a row for every dispensing obs group construct
insert into all_medication_dispensing
(patient_id,
encounter_id,
obs_group_id,
form
)
select 
o.person_id,
o.encounter_id,
o.obs_id,
'Old'
from obs o 
where concept_id = concept_from_mapping('PIH','9070')
AND o.voided = 0;

create index med_encounter_id on all_medication_dispensing(encounter_id);
create index med_obs_group on all_medication_dispensing(obs_group_id);

-- copy all distinct encounters to a row-per-encounter table to update the encounter-level columns
DROP TABLE IF EXISTS temp_encounter;
CREATE TEMPORARY TABLE temp_encounter
(
encounter_id 			int(11),
encounter_datetime		datetime,
encounter_location_id   int(11),	
encounter_location      varchar(255),
date_entered 			date,
creator					int(11),
user_entered            varchar(255),
encounter_provider 		varchar(255)
);

insert into temp_encounter (encounter_id)
select distinct encounter_id from all_medication_dispensing;

create index temp_encounter_encounter_id on temp_encounter(encounter_id);

update temp_encounter 
set encounter_provider = provider(encounter_id);

update temp_encounter t
inner join encounter e on t.encounter_id = e.encounter_id 
set t.encounter_datetime = e.encounter_datetime,
	t.encounter_location_id = e.location_id,
	t.date_entered = e.date_created ,
	t.creator = e.creator ;

update temp_encounter 
set encounter_location = location_name(encounter_location_id);

update temp_encounter 
set user_entered =  person_name_of_user(creator);

update all_medication_dispensing md
inner join temp_encounter t on md.encounter_id = t.encounter_id
set md.encounter_datetime = t.encounter_datetime,
	md.encounter_location = t.encounter_location,
	md.date_entered = t.date_entered,
	md.user_entered = t.user_entered,
	md.encounter_provider = t.encounter_provider;

-- update emr ids 
-- copy all distinct patients to a row-per-encounter table
DROP TABLE IF EXISTS temp_emr_ids;
CREATE TEMPORARY TABLE temp_emr_ids
(patient_id int(11),
emr_id		varchar(50)
);

insert into temp_emr_ids (patient_id)
select distinct patient_id from all_medication_dispensing;

create index temp_emr_ids_patient_id on temp_emr_ids(patient_id);

UPDATE temp_emr_ids
SET emr_id=PATIENT_IDENTIFIER(patient_id, METADATA_UUID('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')); 

update all_medication_dispensing md
inner join temp_emr_ids ei on ei.patient_id = md.patient_id
set md.emr_id = ei.emr_id;

-- create a reduced obs table with only rows for the dispensing obs groups for all of the obs-level columns
drop temporary table if exists temp_obs;
create temporary table temp_obs 
select o.obs_group_id ,o.concept_id, o.value_coded, o.value_numeric, o.value_text,  o.value_drug  
from obs o
inner join all_medication_dispensing t on t.obs_group_id = o.obs_group_id 
where o.voided = 0;

create index temp_obs_obs_ci on temp_obs(obs_group_id, concept_id);

set @duration = concept_from_mapping('PIH','9075');
UPDATE all_medication_dispensing tgt 
INNER JOIN temp_obs o ON o.obs_group_id=tgt.obs_group_id
AND o.concept_id= @duration 
SET duration= value_numeric;

set @duration_unit = concept_from_mapping('PIH','6412');
UPDATE all_medication_dispensing tgt 
INNER JOIN temp_obs o ON o.obs_group_id=tgt.obs_group_id
AND o.concept_id= @duration_unit 
SET duration_unit= concept_name(value_coded,@locale);

set @dose = concept_from_mapping('PIH','9073');
UPDATE all_medication_dispensing tgt 
INNER JOIN temp_obs o ON o.obs_group_id=tgt.obs_group_id
AND o.concept_id=@dose
SET quantity_per_dose= value_numeric;

set @route = concept_from_mapping('PIH','12651');
UPDATE all_medication_dispensing tgt 
INNER JOIN temp_obs o ON o.obs_group_id=tgt.obs_group_id
AND o.concept_id=@dose
SET route= CONCEPT_NAME(value_coded, 'en') ;


set @doseUnit = concept_from_mapping('PIH','9074');
UPDATE all_medication_dispensing tgt 
INNER JOIN temp_obs o ON o.obs_group_id=tgt.obs_group_id
AND o.concept_id=@doseUnit
SET dose_unit= value_text;

set @frequency = concept_from_mapping('PIH','9363');
UPDATE all_medication_dispensing tgt 
INNER JOIN temp_obs o ON o.obs_group_id=tgt.obs_group_id
AND o.concept_id= @frequency 
SET frequency= concept_name(value_coded,@locale);

set @quantity = concept_from_mapping('PIH','9071');
UPDATE all_medication_dispensing tgt 
INNER JOIN temp_obs o ON o.obs_group_id=tgt.obs_group_id
AND o.concept_id=@quantity
SET quantity_dispensed= value_numeric;

set @drug = concept_from_mapping('PIH','1282');
UPDATE all_medication_dispensing tgt 
INNER JOIN temp_obs o ON o.obs_group_id=tgt.obs_group_id
AND o.concept_id=@drug
SET drug_id= value_drug;

set @inxs = concept_from_mapping('PIH','9072');
UPDATE all_medication_dispensing tgt 
INNER JOIN temp_obs o ON o.obs_group_id=tgt.obs_group_id
AND o.concept_id=@inxs
SET instructions= value_text;

-- -- copy all distinct drugs to a row-per-drug table to update the drug level columns
DROP TABLE IF EXISTS temp_drug_ids;
CREATE TEMPORARY TABLE temp_drug_ids
(drug_id            int(11),
drug_name           varchar(255),
drug_openboxes_code int
);

insert into temp_drug_ids (drug_id)
select distinct drug_id from all_medication_dispensing;

create index temp_drug_id_dr on temp_drug_ids(drug_id);

UPDATE temp_drug_ids tgt 
SET drug_name= drugName(drug_id);

UPDATE temp_drug_ids tgt 
SET drug_openboxes_code= openboxesCode (drug_id);

update all_medication_dispensing tgt
inner join temp_drug_ids t on t.drug_id = tgt.drug_id
set tgt.drug_name = t.drug_name,
	tgt.drug_openboxes_code = t.drug_openboxes_code;

UPDATE all_medication_dispensing t SET type_of_prescription = OBS_VALUE_CODED_LIST(t.encounter_id, 'PIH', '9292', 'en');
UPDATE all_medication_dispensing t SET location_of_prescription = LOCATION_NAME(OBS_VALUE_TEXT(t.encounter_id, 'PIH', '9293'));
UPDATE all_medication_dispensing t SET title =  OBS_VALUE_CODED_LIST(t.encounter_id, 'CIEL', '163556', 'en');
-- license
UPDATE all_medication_dispensing t SET license = OBS_VALUE_NUMERIC(t.encounter_id, 'PIH', '13962');
-- Prescribe
UPDATE all_medication_dispensing t SET prescriber = OBS_VALUE_TEXT(t.encounter_id, 'PIH', '6592');

-- final select of the data
SELECT 
encounter_id,
emr_id,
patient_id, 
encounter_location AS location_name,
CAST(encounter_datetime AS date) AS encounter_date,
type_of_prescription,
location_of_prescription,
title,
license,
prescriber,
drug_name AS medication_name,
duration,
duration_unit AS durationUnit,
quantity_per_dose AS dose,
dose_unit AS doseInput,
frequency,
quantity_dispensed AS amount,
instructions
FROM all_medication_dispensing;