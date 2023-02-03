set sql_safe_updates = 0;

select encounter_type_id into @ncd_followup from encounter_type where uuid = '5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c';

drop temporary table if exists temp_ncd_encounters_meds_followup_stage;
create temporary table temp_ncd_encounters_meds_followup_stage
(
person_id int,
emr_id varchar(15),
encounter_id int,
encounter_datetime date,
offset1 int,
offset2 int,
offset3 int,
offset4 int,
offset5 int,
offset6 int,
offset7 int,
med1 varchar(255),
dose1 int,
unit1 varchar(15),
route1 varchar(30),
freq1 varchar(30),
med1_duration int,
med1_duration_unit varchar(20),
med2 varchar(255),
dose2 int,
unit2 varchar(15),
route2 varchar(30),
freq2 varchar(30),
med2_duration int,
med2_duration_unit varchar(20),
med3 varchar(255),
dose3 int,
unit3 varchar(15),
route3 varchar(30),
freq3 varchar(30),
med3_duration int,
med3_duration_unit varchar(20),
med4 varchar(255),
dose4 int,
unit4 varchar(15),
route4 varchar(30),
freq4 varchar(30),
med4_duration int,
med4_duration_unit varchar(20),
med5 varchar(255),
dose5 int,
unit5 varchar(15),
route5 varchar(30),
freq5 varchar(30),
med5_duration int,
med5_duration_unit varchar(20),
med6 varchar(255),
dose6 int,
unit6 varchar(15),
route6 varchar(30),
freq6 varchar(30),
med6_duration int,
med6_duration_unit varchar(20),
med7 varchar(255),
dose7 int,
unit7 varchar(15),
route7 varchar(30),
freq7 varchar(30),
med7_duration int,
med7_duration_unit varchar(20)
);

insert into temp_ncd_encounters_meds_followup_stage (
person_id,
encounter_id,
encounter_datetime
) select patient_id, encounter_id, date(encounter_datetime) from encounter where voided = 0  and
encounter_type = @ncd_followup and voided = 0
-- and (date(encounter_datetime) >= date(@startDate))
-- and (date(encounter_datetime) <= date(@endDate))
;

update temp_ncd_encounters_meds_followup_stage tn set offset1 = obs_id(tn.encounter_id, 'PIH', 'Prescription construct', 0);
update temp_ncd_encounters_meds_followup_stage tn set offset2 = obs_id(tn.encounter_id, 'PIH', 'Prescription construct', 1);
update temp_ncd_encounters_meds_followup_stage tn set offset3 = obs_id(tn.encounter_id, 'PIH', 'Prescription construct', 2);
update temp_ncd_encounters_meds_followup_stage tn set offset4 = obs_id(tn.encounter_id, 'PIH', 'Prescription construct', 3);
update temp_ncd_encounters_meds_followup_stage tn set offset5 = obs_id(tn.encounter_id, 'PIH', 'Prescription construct', 4);
update temp_ncd_encounters_meds_followup_stage tn set offset6 = obs_id(tn.encounter_id, 'PIH', 'Prescription construct', 5);
update temp_ncd_encounters_meds_followup_stage tn set offset7 = obs_id(tn.encounter_id, 'PIH', 'Prescription construct', 6);

update temp_ncd_encounters_meds_followup_stage  tn join obs o on o.voided = 0 and o.encounter_id = tn.encounter_id set 
med1 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'MEDICATION ORDERS') and obs_group_id = offset1),
med2 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'MEDICATION ORDERS') and obs_group_id = offset2),
med3 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'MEDICATION ORDERS') and obs_group_id = offset3),
med4 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'MEDICATION ORDERS') and obs_group_id = offset4),
med5 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'MEDICATION ORDERS') and obs_group_id = offset5),
med6 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'MEDICATION ORDERS') and obs_group_id = offset6),
med7 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'MEDICATION ORDERS') and obs_group_id = offset7);

update temp_ncd_encounters_meds_followup_stage tn join obs o on o.voided = 0 and o.encounter_id = tn.encounter_id set 
dose1 = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '9073') and obs_group_id = offset1),
dose2 = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '9073') and obs_group_id = offset2),
dose3 = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '9073') and obs_group_id = offset3),
dose4 = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '9073') and obs_group_id = offset4),
dose5 = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '9073') and obs_group_id = offset5),
dose6 = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '9073') and obs_group_id = offset6),
dose7 = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '9073') and obs_group_id = offset7);

update temp_ncd_encounters_meds_followup_stage tn join obs o on o.voided = 0 and o.encounter_id = tn.encounter_id set 
unit1 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'Dosing units coded') and obs_group_id = offset1),
unit2 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'Dosing units coded') and obs_group_id = offset2),
unit3 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'Dosing units coded') and obs_group_id = offset3),
unit4 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'Dosing units coded') and obs_group_id = offset4),
unit5 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'Dosing units coded') and obs_group_id = offset5),
unit6 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'Dosing units coded') and obs_group_id = offset6),
unit7 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'Dosing units coded') and obs_group_id = offset7);

update temp_ncd_encounters_meds_followup_stage tn join obs o on o.voided = 0 and o.encounter_id = tn.encounter_id set 
route1 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '12651') and obs_group_id = offset1),
route2 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '12651') and obs_group_id = offset2),
route3 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '12651') and obs_group_id = offset3),
route4 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '12651') and obs_group_id = offset4),
route5 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '12651') and obs_group_id = offset5),
route6 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '12651') and obs_group_id = offset6),
route7 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '12651') and obs_group_id = offset7);

update temp_ncd_encounters_meds_followup_stage tn join obs o on o.voided = 0 and o.encounter_id = tn.encounter_id set 
freq1 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '160855') and obs_group_id = offset1),
freq2 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '160855') and obs_group_id = offset2),
freq3 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '160855') and obs_group_id = offset3),
freq4 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '160855') and obs_group_id = offset4),
freq5 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '160855') and obs_group_id = offset5),
freq6 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '160855') and obs_group_id = offset6),
freq7 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '160855') and obs_group_id = offset7);

update temp_ncd_encounters_meds_followup_stage tn join obs o on o.voided = 0 and o.encounter_id = tn.encounter_id set 
med1_duration = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '159368') and obs_group_id = offset1),
med2_duration = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '159368') and obs_group_id = offset2),
med3_duration = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '159368') and obs_group_id = offset3),
med4_duration = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '159368') and obs_group_id = offset4),
med5_duration = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '159368') and obs_group_id = offset5),
med6_duration = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '159368') and obs_group_id = offset6),
med7_duration = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '159368') and obs_group_id = offset7);

update temp_ncd_encounters_meds_followup_stage tn join obs o on o.voided = 0 and o.encounter_id = tn.encounter_id set 
med1_duration_unit = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'TIME UNITS') and obs_group_id = offset1),
med2_duration_unit = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'TIME UNITS') and obs_group_id = offset2),
med3_duration_unit = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'TIME UNITS') and obs_group_id = offset3),
med4_duration_unit = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'TIME UNITS') and obs_group_id = offset4),
med5_duration_unit = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'TIME UNITS') and obs_group_id = offset5),
med6_duration_unit = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'TIME UNITS') and obs_group_id = offset6),
med7_duration_unit = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'TIME UNITS') and obs_group_id = offset7);

UPDATE temp_ncd_encounters_meds_followup_stage SET emr_id = PATIENT_IDENTIFIER(person_id, METADATA_UUID('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')); 

select 
person_id,
emr_id,
encounter_id,
encounter_datetime,
med1,
dose1,
unit1,
route1,
freq1,
med1_duration,
med1_duration_unit,
med2,
dose2,
unit2,
route2,
freq2,
med2_duration,
med2_duration_unit,
med3,
dose3,
unit3,
route3,
freq3,
med3_duration,
med3_duration_unit,
med4,
dose4,
unit4,
route4,
freq4,
med4_duration,
med4_duration_unit,
med5,
dose5,
unit5,
route5,
freq5,
med5_duration,
med5_duration_unit,
med6,
dose6,
unit6,
route6,
freq6,
med6_duration,
med6_duration_unit,
med7,
dose7,
unit7,
route7,
freq7,
med7_duration,
med7_duration_unit
from temp_ncd_encounters_meds_followup_stage;