set sql_safe_updates = 0;

select encounter_type_id into @ncd_initial from encounter_type where uuid = 'ae06d311-1866-455b-8a64-126a9bd74171';
select encounter_type_id into @ncd_followup from encounter_type where uuid = '5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c';

drop temporary table if exists temp_ncd_encounters_meds_stage;
create temporary table temp_ncd_encounters_meds_stage
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
past_med1 varchar(255),
dose1 int,
unit1 varchar(15),
freq1 varchar(30),
still_taking_med1 varchar(11),
med1_start_date date,
med1_finish_date date,
past_med2 varchar(255),
dose2 int,
unit2 varchar(15),
freq2 varchar(30),
still_taking_med2 varchar(11),
med2_start_date date,
med2_finish_date date,
past_med3 varchar(255),
dose3 int,
unit3 varchar(15),
freq3 varchar(30),
still_taking_med3 varchar(11),
med3_start_date date,
med3_finish_date date,
past_med4 varchar(255),
dose4 int,
unit4 varchar(15),
freq4 varchar(30),
still_taking_med4 varchar(11),
med4_start_date date,
med4_finish_date date,
past_med5 varchar(255),
dose5 int,
unit5 varchar(15),
freq5 varchar(30),
still_taking_med5 varchar(11),
med5_start_date date,
med5_finish_date date
);

insert into temp_ncd_encounters_meds_stage (
person_id,
encounter_id,
encounter_datetime
) select patient_id, encounter_id, date(encounter_datetime) from encounter where voided = 0  and
encounter_type in (@ncd_initial, @ncd_followup) and voided = 0
and (date(encounter_datetime) >= date(@startDate))
and (date(encounter_datetime) <= date(@endDate));

update temp_ncd_encounters_meds_stage tn set offset1 = obs_id(tn.encounter_id, 'CIEL', '160741', 0);
update temp_ncd_encounters_meds_stage tn set offset2 = obs_id(tn.encounter_id, 'CIEL', '160741', 1);
update temp_ncd_encounters_meds_stage tn set offset3 = obs_id(tn.encounter_id, 'CIEL', '160741', 2);
update temp_ncd_encounters_meds_stage tn set offset4 = obs_id(tn.encounter_id, 'CIEL', '160741', 3);
update temp_ncd_encounters_meds_stage tn set offset5 = obs_id(tn.encounter_id, 'CIEL', '160741', 4);

update temp_ncd_encounters_meds_stage tn join obs o on o.voided = 0 and o.encounter_id = tn.encounter_id set 
past_med1 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'MEDICATION ORDERS') and obs_group_id = offset1),
past_med2 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'MEDICATION ORDERS') and obs_group_id = offset2),
past_med3 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'MEDICATION ORDERS') and obs_group_id = offset3),
past_med4 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'MEDICATION ORDERS') and obs_group_id = offset4),
past_med5 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'MEDICATION ORDERS') and obs_group_id = offset5);

update temp_ncd_encounters_meds_stage tn join obs o on o.voided = 0 and o.encounter_id = tn.encounter_id set 
dose1 = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '9073') and obs_group_id = offset1),
dose2 = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '9073') and obs_group_id = offset2),
dose3 = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '9073') and obs_group_id = offset3),
dose4 = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '9073') and obs_group_id = offset4),
dose5 = (select value_numeric from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '9073') and obs_group_id = offset5);

update temp_ncd_encounters_meds_stage tn join obs o on o.voided = 0 and o.encounter_id = tn.encounter_id set 
freq1 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '160855') and obs_group_id = offset1),
freq2 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '160855') and obs_group_id = offset2),
freq3 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '160855') and obs_group_id = offset3),
freq4 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '160855') and obs_group_id = offset4),
freq5 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('CIEL', '160855') and obs_group_id = offset5);


update temp_ncd_encounters_meds_stage tn join obs o on o.voided = 0 and o.encounter_id = tn.encounter_id set 
unit1 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'Dosing units coded') and obs_group_id = offset1),
unit2 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'Dosing units coded') and obs_group_id = offset2),
unit3 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'Dosing units coded') and obs_group_id = offset3),
unit4 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'Dosing units coded') and obs_group_id = offset4),
unit5 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', 'Dosing units coded') and obs_group_id = offset5);

update temp_ncd_encounters_meds_stage tn join obs o on o.voided = 0 and o.encounter_id = tn.encounter_id set 
still_taking_med1 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '6695') and obs_group_id = offset1),
still_taking_med2 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '6695') and obs_group_id = offset2),
still_taking_med3 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '6695') and obs_group_id = offset3),
still_taking_med4 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '6695') and obs_group_id = offset4),
still_taking_med5 = (select concept_name(value_coded, 'en') from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '6695') and obs_group_id = offset5);

update temp_ncd_encounters_meds_stage tn join obs o on o.voided = 0 and o.encounter_id = tn.encounter_id set 
med1_start_date = (select date(value_datetime)from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '1190') and obs_group_id = offset1),
med2_start_date = (select date(value_datetime)from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '1190') and obs_group_id = offset2),
med3_start_date = (select date(value_datetime)from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '1190') and obs_group_id = offset3),
med4_start_date = (select date(value_datetime)from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '1190') and obs_group_id = offset4),
med5_start_date = (select date(value_datetime)from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '1190') and obs_group_id = offset5);

update temp_ncd_encounters_meds_stage tn join obs o on o.voided = 0 and o.encounter_id = tn.encounter_id set 
med1_finish_date = (select date(value_datetime)from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '1191') and obs_group_id = offset1),
med2_finish_date = (select date(value_datetime)from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '1191') and obs_group_id = offset2),
med3_finish_date = (select date(value_datetime)from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '1191') and obs_group_id = offset3),
med4_finish_date = (select date(value_datetime)from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '1191') and obs_group_id = offset4),
med5_finish_date = (select date(value_datetime)from obs where voided = 0 and concept_id = concept_from_mapping('PIH', '1191') and obs_group_id = offset5);

UPDATE temp_ncd_encounters_meds_stage SET emr_id = PATIENT_IDENTIFIER(person_id, METADATA_UUID('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')); 

select * from temp_ncd_encounters_meds_stage;