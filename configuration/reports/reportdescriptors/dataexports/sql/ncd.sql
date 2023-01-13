set sql_safe_updates = 0;

select encounter_type_id into @ncd_initial from encounter_type where uuid = 'ae06d311-1866-455b-8a64-126a9bd74171';
select encounter_type_id into @ncd_followup from encounter_type where uuid = '5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c';

drop temporary table if exists temp_ncd_encounters;
create temporary table temp_ncd_encounters
(
person_id int,
encounter_id int,
encounter_datetime date,
reason_for_referral  text,
internal_patient_referral varchar(255),
external_patient_referral varchar(255),
other_internal_site varchar(255),
other_external_site varchar(255),
other_external_non_pih_site varchar(255),
normal_general_exam varchar(255),
abnormal_general_exam varchar(255),
other_general_exam text,
normal_heent_exam varchar(255),
abnormal_heent_exam varchar(255),
other_heent_exam text,
normal_lungs_exam varchar(255),
abnormal_lungs_exam varchar(255),
loc_crackles text,
other_lungs_exam text,
normal_heart_exam varchar(255),
abnormal_heart_exam varchar(255),
other_heart_exam text
);

insert into temp_ncd_encounters (
person_id,
encounter_id,
encounter_datetime
) select patient_id, encounter_id, date(encounter_datetime) from encounter where voided = 0 and
encounter_type in (@ncd_initial, @ncd_followup);

-- Reason for Referral
update temp_ncd_encounters tn set reason_for_referral = obs_value_text(tn.encounter_id,'CIEL', '160531');

-- Internal institution
update temp_ncd_encounters tn set
internal_patient_referral = (select group_concat(concept_name(value_coded, 'en') separator ' | ') from obs o where o.encounter_id = tn.encounter_id and 
voided = 0 and concept_id = concept_from_mapping('PIH', 'Type of referring service') and
value_coded in (
concept_from_mapping('CIEL', '160542'),
concept_from_mapping('CIEL', '160473'),
concept_from_mapping('CIEL', '160448'),
concept_from_mapping('CIEL', '165048'),
concept_from_mapping('PIH', 'MATERNITY WARD'),
concept_from_mapping('PIH', 'OTHER')));

-- External Institution
update temp_ncd_encounters tn set
external_patient_referral = (select group_concat(concept_name(value_coded, 'en') separator ' | ') from obs o where o.encounter_id = tn.encounter_id and 
voided = 0 and concept_id = concept_from_mapping('PIH', 'Type of referring service') and
value_coded in (
concept_from_mapping('PIH','Non-ZL supported site'),
concept_from_mapping('PIH','11956')));

-- Other institutions
update temp_ncd_encounters tn set other_internal_site =
obs_comments(tn.encounter_id, 'PIH', 'Type of referring service', 'PIH', 'OTHER');
update temp_ncd_encounters tn set other_external_site =
obs_comments(tn.encounter_id, 'PIH', 'Type of referring service', 'PIH','11956');
update temp_ncd_encounters tn set other_external_non_pih_site =
obs_comments(tn.encounter_id, 'PIH', 'Type of referring service', 'PIH', 'Non-ZL supported site');

-- physical exams
update temp_ncd_encounters tn set normal_general_exam = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in 
(concept_from_mapping('PIH','WELL APPEARING'), concept_from_mapping('CIEL', '160282')) and concept_id = concept_from_mapping('PIH', 'GENERAL EXAM FINDINGS'));

update temp_ncd_encounters tn set abnormal_general_exam = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in (concept_from_mapping('PIH','CACHECTIC'), 
concept_from_mapping('PIH', 'CONFUSION'), concept_from_mapping('PIH', 'Obesity')) and concept_id = concept_from_mapping('PIH', 'GENERAL EXAM FINDINGS'));
 
update temp_ncd_encounters tn set other_general_exam = ( select value_text from obs o where tn.encounter_id = o.encounter_id and voided = 0 and concept_id = 
concept_from_mapping('PIH', 'GENERAL FREE TEXT') and obs_group_id in (select obs_id from obs o2 where o2.voided = 0 and o.encounter_id = o2.encounter_id and o2.concept_id =
concept_from_mapping('PIH', 'GENERAL EXAM FINDINGS')));

update temp_ncd_encounters tn set normal_heent_exam = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in 
(concept_from_mapping('PIH','3757'), concept_from_mapping('PIH', '117'), concept_from_mapping('PIH', '12617')) and concept_id = concept_from_mapping('PIH', 'HEENT EXAM FINDINGS'));

update temp_ncd_encounters tn set abnormal_heent_exam = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in (concept_from_mapping('PIH','PALE CONJUNCTIVA'), 
concept_from_mapping('CIEL', '127918'), concept_from_mapping('PIH', 'JAUNDICE'), concept_from_mapping('CIEL', '162941'), concept_from_mapping('PIH', 'GOITER')) and concept_id = concept_from_mapping('PIH', 'HEENT EXAM FINDINGS'));
 
update temp_ncd_encounters tn set other_heent_exam = ( select value_text from obs o where tn.encounter_id = o.encounter_id and voided = 0 and concept_id = 
concept_from_mapping('PIH', 'GENERAL FREE TEXT') and obs_group_id in (select obs_id from obs o2 where o2.voided = 0 and o.encounter_id = o2.encounter_id and o2.concept_id =
concept_from_mapping('PIH', 'HEENT EXAM FINDINGS')));

update temp_ncd_encounters tn set normal_lungs_exam = (select concept_name(value_coded, 'en') from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded = 
concept_from_mapping('PIH', '1115') and concept_id = concept_from_mapping('PIH', 'CHEST EXAM FINDINGS'));

update temp_ncd_encounters tn set abnormal_lungs_exam = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in (concept_from_mapping('CIEL','122863'), 
concept_from_mapping('CIEL', '127640'), concept_from_mapping('CIEL', '125061'))
 and concept_id = concept_from_mapping('PIH', 'CHEST EXAM FINDINGS'));
 
update temp_ncd_encounters tn set other_lungs_exam = ( select value_text from obs o where tn.encounter_id = o.encounter_id and voided = 0 and concept_id = 
concept_from_mapping('PIH', 'GENERAL FREE TEXT') and obs_group_id in (select obs_id from obs o2 where o2.voided = 0 and o.encounter_id = o2.encounter_id and o2.concept_id =
concept_from_mapping('PIH', 'CHEST EXAM FINDINGS')));

update temp_ncd_encounters tn set normal_heart_exam = (select group_concat(concept_name(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and 
value_coded in (concept_from_mapping('PIH', 'REGULAR RHYTHM'), concept_from_mapping('PIH', 'NO CARDIAC MURMURS'), concept_from_mapping('PIH', 'PMI NOT DISPLACED'), 
concept_from_mapping('PIH', 'S1 AND S2 NORMAL') ) and concept_id = concept_from_mapping('PIH', 'CARDIAC EXAM FINDINGS'));

update temp_ncd_encounters tn set abnormal_heart_exam  = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in (concept_from_mapping('PIH','BRADYCARDIA'), 
concept_from_mapping('PIH', 'TACHYCARDIA'), concept_from_mapping('PIH', 'ATRIAL FIBRILLATION'), concept_from_mapping('PIH', 'DISPLACED POINT OF MAXIMAL IMPULSE'),
concept_from_mapping('PIH', 'S3 GALLOP'), concept_from_mapping('PIH', 'S4 GALLOP'))
 and concept_id = concept_from_mapping('PIH', 'CARDIAC EXAM FINDINGS'));
 
update temp_ncd_encounters tn set other_heart_exam = ( select value_text from obs o where tn.encounter_id = o.encounter_id and voided = 0 and concept_id = 
concept_from_mapping('PIH', 'GENERAL FREE TEXT') and obs_group_id in (select obs_id from obs o2 where o2.voided = 0 and o.encounter_id = o2.encounter_id and o2.concept_id =
concept_from_mapping('PIH', 'CARDIAC EXAM FINDINGS')));


select * from temp_ncd_encounters where person_id = 352;

