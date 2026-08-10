set sql_safe_updates = 0;

select encounter_type_id into @ncd_followup from encounter_type where uuid = '5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c';

drop temporary table if exists temp_ncd_encounters_plans;
create temporary table temp_ncd_encounters_plans
(
person_id int,
emr_id varchar(15),
encounter_id int,
encounter_datetime date,
patient_took_meds_past_2_days varchar(20),
reason_for_poor_treatment_adherence varchar(50),
treatment_additonal_comments text,
side_effects varchar(20),
side_effects_comments text,
plan_comments text,
adherence_to_appt_day varchar(50),
hospitalization_since_last_visit varchar(10),
hospitalization_comments text,
return_visit_date date
);

insert into temp_ncd_encounters_plans (
person_id,
encounter_id,
encounter_datetime
) select patient_id, encounter_id, date(encounter_datetime) from encounter where voided = 0  and
encounter_type = @ncd_followup and voided = 0
and (date(encounter_datetime) >= date(@startDate))
and (date(encounter_datetime) <= date(@endDate))
;

update temp_ncd_encounters_plans tn set patient_took_meds_past_2_days = obs_value_coded_list(tn.encounter_id, 'PIH', '10555', 'en');
update temp_ncd_encounters_plans tn set reason_for_poor_treatment_adherence = obs_value_coded_list(tn.encounter_id, 'PIH', '3140', 'en');
update temp_ncd_encounters_plans tn set treatment_additonal_comments = obs_value_text(tn.encounter_id, 'PIH', '10637');
update temp_ncd_encounters_plans tn set side_effects = obs_value_coded_list(tn.encounter_id, 'PIH', '12352', 'en');
update temp_ncd_encounters_plans tn set side_effects_comments = obs_value_text(tn.encounter_id, 'PIH', '12351');
update temp_ncd_encounters_plans tn set plan_comments = obs_value_text(tn.encounter_id, 'PIH', '2881');

update temp_ncd_encounters_plans tn set adherence_to_appt_day = obs_value_coded_list(tn.encounter_id, 'PIH', '10552', 'en');
update temp_ncd_encounters_plans tn set hospitalization_since_last_visit = obs_value_coded_list(tn.encounter_id, 'PIH', '1715', 'en');
update temp_ncd_encounters_plans tn set hospitalization_comments = obs_value_text(tn.encounter_id, 'PIH', '11065');
update temp_ncd_encounters_plans tn set return_visit_date = date(obs_value_datetime(tn.encounter_id, 'PIH', '5096'));


UPDATE temp_ncd_encounters_plans SET emr_id = PATIENT_IDENTIFIER(person_id, METADATA_UUID('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')); 

select * from temp_ncd_encounters_plans;