set sql_safe_updates = 0;

select encounter_type_id into @ncd_initial from encounter_type where uuid = 'ae06d311-1866-455b-8a64-126a9bd74171';
select encounter_type_id into @ncd_followup from encounter_type where uuid = '5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c';

drop temporary table if exists temp_ncd_encounters_clinical_impressions;
create temporary table temp_ncd_encounters_clinical_impressions
(
person_id int,
emr_id varchar(255),
encounter_id int,
encounter_datetime date,
waist_cm double,
hip_cm double,
clinical_condition varchar(255),
clinical_status varchar(255),
clinical_comments text,
consult_note_since_lastvisit text,
signs_symptoms text,
drink_alcohol varchar(10),
smoke_tobacco varchar(10),
poor_diet_adherence varchar(10),
poor_physical_activity varchar(10),
shortness_of_breadth varchar(10),
taking_meds varchar(10),
hypoglycemia varchar(10),			
headache varchar(10),
chest_pain varchar(10),
dizziness varchar(10),
vision_changes varchar(10),
neuropathy varchar(10),
ulcers varchar(10),
used_traditional_herbs varchar(10),
took_nsaids varchar(10),
urinary_retention varchar(10),
fatigue varchar(10),
nausea varchar(10),
pruritis varchar(10),
confusion varchar(10),
facial_edema varchar(10),
body_edema varchar(10),
regular_diet varchar(10),
doe varchar(10),
asthma_exacerbation varchar(10),
respiratory_distress varchar(10),
cyanosis varchar(10),
cough varchar(10),
smoke varchar(10),
tb_related varchar(10),
wheezing varchar(10),
resp_action_plan varchar(10),
pwd varchar(10),
depression varchar(10),
crackles varchar(10),
jvd_elevated varchar(10),
orthopnea varchar(10),
pcm varchar(10),
dyspnea varchar(10),
ascites varchar(10),
asterixis varchar(10),
pain varchar(10),
fever varchar(10),
meds_side_effects varchar(10),
icteric_sclera varchar(10),              
spleen_palpable varchar(10)
);

insert into temp_ncd_encounters_clinical_impressions (
person_id,
encounter_id,
encounter_datetime
) select patient_id, encounter_id, date(encounter_datetime) from encounter where voided = 0 and
encounter_type in (@ncd_initial, @ncd_followup) 
and (date(encounter_datetime) >= date(@startDate))
and (date(encounter_datetime) <= date(@endDate));

UPDATE temp_ncd_encounters_clinical_impressions SET emr_id = PATIENT_IDENTIFIER(person_id, METADATA_UUID('org.openmrs.module.emrapi', 'emr.primaryIdentifierType')); 

update temp_ncd_encounters_clinical_impressions tn set waist_cm = obs_value_numeric(tn.encounter_id, 'CIEL','163080');
update temp_ncd_encounters_clinical_impressions tn set hip_cm = obs_value_numeric(tn.encounter_id, 'CIEL','163081');
update temp_ncd_encounters_clinical_impressions tn set consult_note_since_lastvisit = obs_value_coded_list(tn.encounter_id, 'PIH','Disease requiring hospitalization since last visit', 'en');
update temp_ncd_encounters_clinical_impressions tn set signs_symptoms = obs_value_coded_list(tn.encounter_id, 'PIH','11119', 'en');

-- Clinical Impression
update temp_ncd_encounters_clinical_impressions tn set clinical_condition = (select concept_name(condition_coded, 'en') from conditions cs where cs.voided  = 0 and 
cs.patient_id = tn.person_id and cs.encounter_id = tn.encounter_id
);

update temp_ncd_encounters_clinical_impressions tn set clinical_status = (select clinical_status from conditions cs where cs.voided  = 0 and 
cs.patient_id = tn.person_id and cs.encounter_id = tn.encounter_id
);

update temp_ncd_encounters_clinical_impressions tn set clinical_comments =  obs_value_text(tn.encounter_id, 'PIH', 'CLINICAL IMPRESSION COMMENTS');

drop temporary table if exists temp_ncd_sign_symptoms;
create temporary table temp_ncd_sign_symptoms
(
person_id int,
encounter_id int,
obs_group_id int,
concept_id int,
value_coded int,
signs_symptoms text,
signs_available varchar(10)
);

insert into temp_ncd_sign_symptoms (person_id, encounter_id, obs_group_id, concept_id, value_coded,  signs_symptoms) 
select person_id, encounter_id, obs_group_id, concept_id, value_coded, concept_name(value_coded, 'en') from obs o where o.voided = 0 
and o.concept_id = concept_from_mapping('PIH','11119')
and obs_group_id in (select obs_id from obs where voided = 0 and concept_id = concept_from_mapping('PIH','12389'));

update temp_ncd_sign_symptoms tn set signs_available = (select concept_name(value_coded, 'en') from obs o where voided = 0 and tn.encounter_id = o.encounter_id and tn.obs_group_id = 
o.obs_group_id and o.concept_id = concept_from_mapping('CIEL', '1729'));

update temp_ncd_encounters_clinical_impressions t set drink_alcohol = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("CIEL", "70468"));

update temp_ncd_encounters_clinical_impressions t set smoke_tobacco = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "2545"));

update temp_ncd_encounters_clinical_impressions t set poor_diet_adherence = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("CIEL", "165585"));

update temp_ncd_encounters_clinical_impressions t set poor_physical_activity = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("CIEL", "165569"));

update temp_ncd_encounters_clinical_impressions t set shortness_of_breadth = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "SHORTNESS OF BREATH WITH EXERTION"));

update temp_ncd_encounters_clinical_impressions t set taking_meds = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "Currently taking medication"));

update temp_ncd_encounters_clinical_impressions t set hypoglycemia = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "HYPOGLYCEMIA"));

update temp_ncd_encounters_clinical_impressions t set headache = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "HEADACHE"));

update temp_ncd_encounters_clinical_impressions t set chest_pain = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "CHEST PAIN"));


update temp_ncd_encounters_clinical_impressions t set dizziness = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "DIZZINESS"));

update temp_ncd_encounters_clinical_impressions t set vision_changes = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "Vision problem"));


update temp_ncd_encounters_clinical_impressions t set neuropathy = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "PERIPHERAL NEUROPATHY"));

update temp_ncd_encounters_clinical_impressions t set ulcers = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "Ulcers (generic)"));

update temp_ncd_encounters_clinical_impressions t set used_traditional_herbs = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "HERBAL TRADITIONAL MEDICATIONS"));

update temp_ncd_encounters_clinical_impressions t set took_nsaids = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("CIEL", "162306"));

update temp_ncd_encounters_clinical_impressions t set fatigue = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "FATIGUE"));

update temp_ncd_encounters_clinical_impressions t set nausea = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "NAUSEA"));

update temp_ncd_encounters_clinical_impressions t set pruritis = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "PRURITIS"));

update temp_ncd_encounters_clinical_impressions t set confusion = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("CIEL", "119866"));

update temp_ncd_encounters_clinical_impressions t set facial_edema = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("CIEL", "165193"));

update temp_ncd_encounters_clinical_impressions t set body_edema = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("CIEL", "460"));

update temp_ncd_encounters_clinical_impressions t set regular_diet = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("CIEL", "159596"));

update temp_ncd_encounters_clinical_impressions t set doe = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("CIEL", "141599"));

update temp_ncd_encounters_clinical_impressions t set asthma_exacerbation = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "ASTHMA EXACERBATION"));

update temp_ncd_encounters_clinical_impressions t set respiratory_distress = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("CIEL", "127639"));

update temp_ncd_encounters_clinical_impressions t set cyanosis = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "CYANOSIS"));

update temp_ncd_encounters_clinical_impressions t set cough = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "COUGH"));

update temp_ncd_encounters_clinical_impressions t set smoke = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "1551"));

update temp_ncd_encounters_clinical_impressions t set tb_related = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "1583"));

update temp_ncd_encounters_clinical_impressions t set wheezing = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "WHEEZE"));
update temp_ncd_encounters_clinical_impressions t set resp_action_plan = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "Respiratory emergency action plan"));
update temp_ncd_encounters_clinical_impressions t set pwd = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("CIEL", "130783"));
update temp_ncd_encounters_clinical_impressions t set depression = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "DEPRESSION"));

update temp_ncd_encounters_clinical_impressions t set crackles = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "CRACKLES"));

update temp_ncd_encounters_clinical_impressions t set jvd_elevated = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("CIEL", "140147"));

update temp_ncd_encounters_clinical_impressions t set orthopnea = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "3486"));

update temp_ncd_encounters_clinical_impressions t set pcm = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "Paracetamol"));

update temp_ncd_encounters_clinical_impressions t set dyspnea = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "5960"));

update temp_ncd_encounters_clinical_impressions t set ascites = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "ASCITES"));


update temp_ncd_encounters_clinical_impressions t set asterixis = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("CIEL", "148276"));

update temp_ncd_encounters_clinical_impressions t set pain = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "Pain"));

update temp_ncd_encounters_clinical_impressions t set fever = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "FEVER"));

update temp_ncd_encounters_clinical_impressions t set meds_side_effects = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("CIEL", "164377"));

update temp_ncd_encounters_clinical_impressions t set icteric_sclera = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("PIH", "ICTERIC SCLERA"));

update temp_ncd_encounters_clinical_impressions t set spleen_palpable = (select signs_available from temp_ncd_sign_symptoms tn where tn.encounter_id = t.encounter_id and 
tn.value_coded = concept_from_mapping("CIEL", "112804"));

-- final query
select *
from temp_ncd_encounters_clinical_impressions;

