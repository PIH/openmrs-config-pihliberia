set sql_safe_updates = 0;

select encounter_type_id into @ncd_followup from encounter_type where uuid = '5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c';

drop temporary table if exists temp_ncd_encounters_clinical_impressions_2;
create temporary table temp_ncd_encounters_clinical_impressions_2
(
person_id int,
emr_id varchar(25),
encounter_id int,
encounter_datetime date,

-- Added new fields
echocardiogram varchar(100), -- can't find function
echo_date date,
echo_impression_comments varchar(255),
ultrasound varchar(100), -- can't find function
ultrasound_date date,
ultrasound_impreesion_comments varchar(225),
ekg_results_date date,
ekg_results_impression varchar(100),
ekg_comments varchar(225),
htn_diagnosis varchar(100),
htn_stage varchar(100),
diabetes_diagnosis varchar(100),
night_per_week_of_symptom int,
days_per_week_of_symptom int,
cld_class varchar(100),
beta_agonist_used varchar (25),
conjunctiva varchar(100),
types_of_body_edema varchar(100),
ckd_stage varchar(100),
diet_recs varchar (10),
hep_b_sAg_test_date date,
hep_b_sAg_test_result varchar(100),
hcv_spot_test_date date,
hcv_spot_test_result varchar(100),
hep_c_ab_test_date date,
hep_c_ab_test_result varchar(100),
received_hep_b_vaccine varchar(100),
presumed_etiology varchar(225), -- Pls do
volumn_status varchar(100),
nyha_stage varchar(100),
heart_failure_diagnosis varchar(100)
);

insert into temp_ncd_encounters_clinical_impressions_2 (
person_id,
encounter_id,
encounter_datetime
) select patient_id, encounter_id, date(encounter_datetime) from encounter where voided = 0 and
encounter_type = @ncd_followup
and (date(encounter_datetime) >= date(@startDate))
and (date(encounter_datetime) <= date(@endDate));

UPDATE temp_ncd_encounters_clinical_impressions_2 SET emr_id = PATIENT_IDENTIFIER(person_id, METADATA_UUID('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')); 

drop temporary table if exists temp_ncd_sign_symptoms;
create temporary table temp_ncd_sign_symptoms
(
person_id int,
encounter_id int,
obs_group_id int,
concept_id int,
value_coded int,
signs_symptoms text,
signs_available varchar(100)
);

insert into temp_ncd_sign_symptoms (person_id, encounter_id, obs_group_id, concept_id, value_coded,  signs_symptoms) 
select person_id, encounter_id, obs_group_id, concept_id, value_coded, concept_name(value_coded, 'en') from obs o where o.voided = 0 
and o.concept_id = concept_from_mapping('PIH','11119')
and obs_group_id in (select obs_id from obs where voided = 0 and concept_id = concept_from_mapping('PIH','12389'));

-- Added field updates 

-- Echo date
update temp_ncd_encounters_clinical_impressions_2 tn set echo_date = obs_value_datetime(tn.encounter_id, 'PIH', '12847');

-- Echo impression comment
update temp_ncd_encounters_clinical_impressions_2 tn set echo_impression_comments = obs_value_text(tn.encounter_id,'PIH', 'Radiology report comments');

-- Ultrasound date
update temp_ncd_encounters_clinical_impressions_2 tn set ultrasound_date = obs_value_datetime(tn.encounter_id, 'PIH', '12847');

-- Ultrasound impreesion comments
update temp_ncd_encounters_clinical_impressions_2 tn set ultrasound_impreesion_comments = obs_value_text(tn.encounter_id,'PIH', 'Radiology report comments');

-- EKG results date
update temp_ncd_encounters_clinical_impressions_2 tn set ekg_results_date = obs_value_datetime(tn.encounter_id, 'PIH', '12847');

-- EKG results impression
update temp_ncd_encounters_clinical_impressions_2 tn set ekg_results_impression = obs_value_coded_list(tn.encounter_id, 'CIEL','159565', 'en');

-- EKG results comments
update temp_ncd_encounters_clinical_impressions_2 tn set ekg_comments = obs_value_text(tn.encounter_id,'CIEL', '159395');

-- Hypertension diagnosis
update temp_ncd_encounters_clinical_impressions_2 tn set htn_diagnosis = obs_value_coded_list(tn.encounter_id, 'PIH','Type of hypertension diagnosis', 'en');

-- Hypertension stage
update temp_ncd_encounters_clinical_impressions_2 tn set htn_stage = obs_value_coded_list(tn.encounter_id, 'PIH','12699', 'en');

-- Diabetes diagnosis
update temp_ncd_encounters_clinical_impressions_2 tn set diabetes_diagnosis = obs_value_coded_list(tn.encounter_id, 'PIH','Type of Diabetes Diagnosis', 'en');

-- Night per week of symptom
update temp_ncd_encounters_clinical_impressions_2 tn set night_per_week_of_symptom = obs_value_numeric(tn.encounter_id, 'PIH','14352');

-- Days per week of symptom
update temp_ncd_encounters_clinical_impressions_2 tn set days_per_week_of_symptom = obs_value_numeric(tn.encounter_id, 'PIH','14347');

-- CLD class
update temp_ncd_encounters_clinical_impressions_2 tn set cld_class = obs_value_coded_list(tn.encounter_id, 'PIH','7405', 'en');

-- Beta-agonist used
update temp_ncd_encounters_clinical_impressions_2 tn set beta_agonist_used = obs_value_coded_list(tn.encounter_id, 'PIH','11991', 'en');

-- Conjunctiva
update temp_ncd_encounters_clinical_impressions_2 tn set conjunctiva = obs_value_coded_list(tn.encounter_id, 'PIH','CONJUNCTIVA', 'en');

-- Types of body edema
update temp_ncd_encounters_clinical_impressions_2 tn set types_of_body_edema = obs_value_coded_list(tn.encounter_id, 'PIH','12636', 'en');

-- CKD stage
update temp_ncd_encounters_clinical_impressions_2 tn set ckd_stage = obs_value_coded_list(tn.encounter_id, 'CIEL','165570', 'en');

-- Diet recs
update temp_ncd_encounters_clinical_impressions_2 tn set diet_recs = obs_value_coded_list(tn.encounter_id, 'PIH','12657', 'en');

-- Hep b sag test date
update temp_ncd_encounters_clinical_impressions_2 tn set hep_b_sAg_test_date = obs_value_datetime(tn.encounter_id, 'PIH', '12847');

-- hep b sag test result
update temp_ncd_encounters_clinical_impressions_2 tn set hep_b_sAg_test_result = obs_value_coded_list(tn.encounter_id, 'CIEL','161472', 'en');

-- hcv spot test date
update temp_ncd_encounters_clinical_impressions_2 tn set hcv_spot_test_date = obs_value_datetime(tn.encounter_id, 'PIH', '12847');

-- HCV spot test result
update temp_ncd_encounters_clinical_impressions_2 tn set hcv_spot_test_result = obs_value_coded_list(tn.encounter_id, 'PIH','11457', 'en');

-- Hep c ab test date
update temp_ncd_encounters_clinical_impressions_2 tn set hep_c_ab_test_date = obs_value_datetime(tn.encounter_id, 'PIH', '12847');

-- Hep c ab test result
update temp_ncd_encounters_clinical_impressions_2 tn set hep_c_ab_test_result = obs_value_coded_list(tn.encounter_id, 'CIEL','1325', 'en');

-- received hep b vaccine
update temp_ncd_encounters_clinical_impressions_2 tn set received_hep_b_vaccine = obs_value_coded_list(tn.encounter_id, 'PIH','14348', 'en');

-- Volumn status 
update temp_ncd_encounters_clinical_impressions_2 tn set volumn_status = obs_value_coded_list(tn.encounter_id, 'PIH','PATIENTS FLUID MANAGEMENT', 'en');

-- NYHA stage varchar
update temp_ncd_encounters_clinical_impressions_2 tn set nyha_stage = obs_value_coded_list(tn.encounter_id, 'PIH','NYHA CLASS', 'en');

-- Heart failure diagnosis
update temp_ncd_encounters_clinical_impressions_2 tn set heart_failure_diagnosis = obs_value_coded_list(tn.encounter_id, 'PIH','14323', 'en');

-- final query
select *
from temp_ncd_encounters_clinical_impressions_2;
