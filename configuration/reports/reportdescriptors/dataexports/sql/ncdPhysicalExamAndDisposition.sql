set sql_safe_updates = 0;

select encounter_type_id into @ncd_initial from encounter_type where uuid = 'ae06d311-1866-455b-8a64-126a9bd74171';
select encounter_type_id into @ncd_followup from encounter_type where uuid = '5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c';

drop temporary table if exists temp_ncd_encounters_physical;
create temporary table temp_ncd_encounters_physical
(
person_id int,
emr_id varchar(255),
encounter_id int,
encounter_datetime date,
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
other_heart_exam text, 
normal_abdomen_exam varchar(255),
abnormal_abdomen_exam varchar(255),
other_abdomen_exam text,
normal_neuro_exam varchar(255),
abnormal_neuro_exam varchar(255),
other_neuro_exam text,
normal_extremities_exam varchar(255),
abnormal_extremities_exam varchar(255),
other_extremities_exam text,
social_welfare varchar(255),
disposition varchar(255),
disposition_comments text,
chw varchar(255),
chw_to_visit int,
chw_to_visit_freq varchar(255)
);

insert into temp_ncd_encounters_physical (
person_id,
encounter_id,
encounter_datetime
) select patient_id, encounter_id, date(encounter_datetime) from encounter where voided = 0 and
encounter_type in (@ncd_initial, @ncd_followup) 
and (date(encounter_datetime) >= date(@startDate))
and (date(encounter_datetime) <= date(@endDate));

UPDATE temp_ncd_encounters_physical SET emr_id = PATIENT_IDENTIFIER(person_id, METADATA_UUID('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')); 

-- physical exams
update temp_ncd_encounters_physical tn set normal_general_exam = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in 
(concept_from_mapping('PIH','WELL APPEARING'), concept_from_mapping('CIEL', '160282')) and concept_id = concept_from_mapping('PIH', 'GENERAL EXAM FINDINGS'));

update temp_ncd_encounters_physical tn set abnormal_general_exam = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in (concept_from_mapping('PIH','CACHECTIC'), 
concept_from_mapping('PIH', 'CONFUSION'), concept_from_mapping('PIH', 'Obesity')) and concept_id = concept_from_mapping('PIH', 'GENERAL EXAM FINDINGS'));
 
update temp_ncd_encounters_physical tn set other_general_exam = ( select value_text from obs o where tn.encounter_id = o.encounter_id and voided = 0 and concept_id = 
concept_from_mapping('PIH', 'GENERAL FREE TEXT') and obs_group_id in (select obs_id from obs o2 where o2.voided = 0 and o.encounter_id = o2.encounter_id and o2.concept_id =
concept_from_mapping('PIH', 'GENERAL EXAM FINDINGS')));

update temp_ncd_encounters_physical tn set normal_heent_exam = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in 
(concept_from_mapping('PIH','3757'), concept_from_mapping('PIH', '117'), concept_from_mapping('PIH', '12617')) and concept_id = concept_from_mapping('PIH', 'HEENT EXAM FINDINGS'));

update temp_ncd_encounters_physical tn set abnormal_heent_exam = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in (concept_from_mapping('PIH','PALE CONJUNCTIVA'), 
concept_from_mapping('CIEL', '127918'), concept_from_mapping('PIH', 'JAUNDICE'), concept_from_mapping('CIEL', '162941'), concept_from_mapping('PIH', 'GOITER')) and concept_id = concept_from_mapping('PIH', 'HEENT EXAM FINDINGS'));
 
update temp_ncd_encounters_physical tn set other_heent_exam = ( select value_text from obs o where tn.encounter_id = o.encounter_id and voided = 0 and concept_id = 
concept_from_mapping('PIH', 'GENERAL FREE TEXT') and obs_group_id in (select obs_id from obs o2 where o2.voided = 0 and o.encounter_id = o2.encounter_id and o2.concept_id =
concept_from_mapping('PIH', 'HEENT EXAM FINDINGS')));

update temp_ncd_encounters_physical tn set normal_lungs_exam = (select concept_name(value_coded, 'en') from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded = 
concept_from_mapping('PIH', '1115') and concept_id = concept_from_mapping('PIH', 'CHEST EXAM FINDINGS'));

update temp_ncd_encounters_physical tn set abnormal_lungs_exam = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in (concept_from_mapping('CIEL','122863'), 
concept_from_mapping('CIEL', '127640'), concept_from_mapping('CIEL', '125061'))
 and concept_id = concept_from_mapping('PIH', 'CHEST EXAM FINDINGS'));
 
update temp_ncd_encounters_physical tn set other_lungs_exam = ( select value_text from obs o where tn.encounter_id = o.encounter_id and voided = 0 and concept_id = 
concept_from_mapping('PIH', 'GENERAL FREE TEXT') and obs_group_id in (select obs_id from obs o2 where o2.voided = 0 and o.encounter_id = o2.encounter_id and o2.concept_id =
concept_from_mapping('PIH', 'CHEST EXAM FINDINGS')));

update temp_ncd_encounters_physical tn set normal_heart_exam = (select group_concat(concept_name(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and 
value_coded in (concept_from_mapping('PIH', 'REGULAR RHYTHM'), concept_from_mapping('PIH', 'NO CARDIAC MURMURS'), concept_from_mapping('PIH', 'PMI NOT DISPLACED'), 
concept_from_mapping('PIH', 'S1 AND S2 NORMAL') ) and concept_id = concept_from_mapping('PIH', 'CARDIAC EXAM FINDINGS'));

update temp_ncd_encounters_physical tn set abnormal_heart_exam  = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in (concept_from_mapping('PIH','BRADYCARDIA'), 
concept_from_mapping('PIH', 'TACHYCARDIA'), concept_from_mapping('PIH', 'ATRIAL FIBRILLATION'), concept_from_mapping('PIH', 'DISPLACED POINT OF MAXIMAL IMPULSE'),
concept_from_mapping('PIH', 'S3 GALLOP'), concept_from_mapping('PIH', 'S4 GALLOP'))
 and concept_id = concept_from_mapping('PIH', 'CARDIAC EXAM FINDINGS'));
 
update temp_ncd_encounters_physical tn set other_heart_exam = (select value_text from obs o where tn.encounter_id = o.encounter_id and voided = 0 and concept_id = 
concept_from_mapping('PIH', 'GENERAL FREE TEXT') and obs_group_id in (select obs_id from obs o2 where o2.voided = 0 and o.encounter_id = o2.encounter_id and o2.concept_id =
concept_from_mapping('PIH', 'CARDIAC EXAM FINDINGS')));

update temp_ncd_encounters_physical tn set normal_abdomen_exam = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in (concept_from_mapping('PIH','SOFT ABDOMEN'), 
concept_from_mapping('PIH', 'NO ABDOMINAL TENDERNESS'), concept_from_mapping('PIH', 'NO PRESENCE OF ASCITES'), concept_from_mapping('PIH', 'NO PRESENCE OF HEPATOMEGALY'),
concept_from_mapping('PIH', 'NO PRESENCE OF SPLENOMEGALY'))
 and concept_id = concept_from_mapping('PIH', 'ABDOMINAL EXAM FINDINGS'));
 
update temp_ncd_encounters_physical tn set abnormal_abdomen_exam = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in (concept_from_mapping('PIH','HEPATOMEGALY'), 
concept_from_mapping('PIH', 'ASCITES'), concept_from_mapping('PIH', 'SPLENOMEGALY'), concept_from_mapping('PIH', 'ABDOMINAL TENDERNESS'))
 and concept_id = concept_from_mapping('PIH', 'ABDOMINAL EXAM FINDINGS'));

update temp_ncd_encounters_physical tn set other_abdomen_exam = (select value_text from obs o where tn.encounter_id = o.encounter_id and voided = 0 and concept_id = 
concept_from_mapping('PIH', 'GENERAL FREE TEXT') and obs_group_id in (select obs_id from obs o2 where o2.voided = 0 and o.encounter_id = o2.encounter_id and o2.concept_id =
concept_from_mapping('PIH', 'ABDOMINAL EXAM FINDINGS')));

update temp_ncd_encounters_physical tn set normal_neuro_exam = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded = concept_from_mapping('PIH','NORMAL')
and concept_id = concept_from_mapping('PIH', 'NEUROLOGIC EXAM FINDINGS'));
 
update temp_ncd_encounters_physical tn set abnormal_neuro_exam = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in (concept_from_mapping('PIH','FOCAL NEUROLOGICAL DEFICIT'), 
concept_from_mapping('CIEL', '165588'), concept_from_mapping('CIEL', '165589'))
 and concept_id = concept_from_mapping('PIH', 'NEUROLOGIC EXAM FINDINGS'));

update temp_ncd_encounters_physical tn set other_neuro_exam = (select value_text from obs o where tn.encounter_id = o.encounter_id and voided = 0 and concept_id = 
concept_from_mapping('PIH', 'GENERAL FREE TEXT') and obs_group_id in (select obs_id from obs o2 where o2.voided = 0 and o.encounter_id = o2.encounter_id and o2.concept_id =
concept_from_mapping('PIH', 'NEUROLOGIC EXAM FINDINGS')));

update temp_ncd_encounters_physical tn set normal_extremities_exam = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in (concept_from_mapping('PIH','Normal, without peripheral edema'),
concept_from_mapping('PIH','12623'))
and concept_id = concept_from_mapping('PIH', 'EXTREMITY EXAM FINDINGS'));
 
update temp_ncd_encounters_physical tn set abnormal_extremities_exam = (select group_concat(concept_name
(value_coded, 'en') separator " | ") from obs o where tn.encounter_id = o.encounter_id and voided = 0 and value_coded in (concept_from_mapping('CIEL','130428'), 
concept_from_mapping('CIEL', '130166'), concept_from_mapping('CIEL', '136522'),
concept_from_mapping('CIEL','124823'), 
concept_from_mapping('CIEL', '123919'), concept_from_mapping('CIEL', '588'), concept_from_mapping('PIH','CYANOSIS')
) and concept_id = concept_from_mapping('PIH', 'EXTREMITY EXAM FINDINGS'));

update temp_ncd_encounters_physical tn set other_extremities_exam = (select value_text from obs o where tn.encounter_id = o.encounter_id and voided = 0 and concept_id = 
concept_from_mapping('PIH', 'GENERAL FREE TEXT') and obs_group_id in (select obs_id from obs o2 where o2.voided = 0 and o.encounter_id = o2.encounter_id and o2.concept_id =
concept_from_mapping('PIH', 'EXTREMITY EXAM FINDINGS')));


-- disposition
update temp_ncd_encounters_physical tn set social_welfare = obs_value_coded_list(tn.encounter_id, 'PIH','SOCIO-ECONOMIC ASSISTANCE RECOMMENDED', 'en');
update temp_ncd_encounters_physical tn set disposition = obs_value_coded_list(tn.encounter_id, 'PIH','HUM Disposition categories', 'en');
update temp_ncd_encounters_physical tn set disposition_comments = obs_value_text(tn.encounter_id,'PIH', 'DISPOSITION COMMENTS');

update temp_ncd_encounters_physical tn set chw  = (select concat(given_name, " ", family_name) from person_name where voided = 0 and person_id = 
(select person_id from provider where retired = 0 and provider_id = obs_value_text(tn.encounter_id, 'CIEL','164141')));
update temp_ncd_encounters_physical tn set chw_to_visit = obs_value_numeric(tn.encounter_id, 'PIH','3451');
update temp_ncd_encounters_physical tn left join obs o on o.voided = 0 and tn.encounter_id = o.encounter_id and concept_id = concept_from_mapping('PIH','TIME UNITS')
and obs_group_id in (select obs_id from obs where voided = 0 and concept_id = concept_from_mapping('PIH','12625'))
set chw_to_visit_freq = concept_name(value_coded, 'en');

select * from temp_ncd_encounters_physical;