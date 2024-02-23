select encounter_type_id into @MH_Consult from encounter_type et2 where uuid = 'a8584ab8-cc2a-11e5-9956-625662870761';
select encounter_type_id into @MH_Intake from encounter_type et2 where uuid = 'fccd53c2-f802-439b-a7a2-2d680bd8b81b';
set @identifier_type ='0bc545e0-f401-11e4-b939-0800200c9a66';

drop temporary table if exists temp_mh_visits;
create temporary table temp_mh_visits (
	visits_id int auto_increment primary key, -- new field introduced to join the indexes with the main table
	patient_id int,
    emr_id varchar(50),
    encounter_id int,
    encounter_date datetime,
    encounter_type varchar(50),
    provider varchar(50),
    suicidal_ideation text,
    homicidal_ideation text,
    suicidality_screening int(11),
    result_of_suicide_risk_evaluation varchar(50),
    ms_appearance_posture varchar(50),
    ms_speech varchar(50),
    ms_mood varchar(50),
    ms_affect varchar(50),
    ms_thought_process varchar(50),
    ms_thought_perceptual_content varchar(50),
    cf_consciousness_orient varchar(50),
    cf_concentration varchar(50),
    cf_memory varchar(50),
    cf_judgement varchar(50),
    cf_insight varchar(50),
    alcohol_use varchar(50),
    illicit_drugs_use varchar(50),
    tobacco varchar(50),
    tsq_score double,
    gad_7_score double,
    phq_9_score double,
    cage_score double,
    cgi double,
    whodas_score int,
    date_entered datetime,
    user_entered varchar(50),
    counselling_plan text,
    index_asc int,
    index_desc int,
    return_visit_date date
);

DROP TABLE IF EXISTS temp_encounter;
CREATE TEMPORARY TABLE temp_encounter AS
SELECT patient_id, encounter_id, encounter_datetime, creator, encounter_type
FROM encounter e
WHERE e.encounter_type in (@mh_consult, @MH_Intake)
AND e.voided =0;

insert into temp_mh_visits (patient_id, emr_id, encounter_type, encounter_id, encounter_date)
select
e.patient_id,
patient_identifier(patient_id, @identifier_type),
encounter_type_name_from_id(e.encounter_type),
e.encounter_id,
e.encounter_datetime
from temp_encounter e;

create index temp_encounter_ci1 on temp_encounter(encounter_id);

DROP TABLE IF EXISTS temp_obs;
CREATE TEMPORARY TABLE temp_obs AS
SELECT o.encounter_id, o.obs_id , o.obs_group_id , o.obs_datetime ,o.date_created , o.person_id, o.value_coded, o.concept_id, o.value_numeric , o.value_datetime , o.value_text , o.voided
FROM temp_encounter te
INNER JOIN  obs o ON te.encounter_id=o.encounter_id
WHERE o.voided =0;

update temp_mh_visits tmhv set emr_id = patient_identifier(patient_id, @identifier_type);

UPDATE temp_mh_visits tmhv
INNER JOIN temp_obs o ON tmhv.encounter_id = o.encounter_id
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', '2546')
SET tmhv.illicit_drugs_use = CONCEPT_NAME(value_coded, 'en');

UPDATE temp_mh_visits tmhv
INNER JOIN temp_obs o ON tmhv.encounter_id = o.encounter_id
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', '1552')
SET tmhv.alcohol_use = CONCEPT_NAME(value_coded, 'en');

UPDATE temp_mh_visits tmhv
INNER JOIN temp_obs o ON tmhv.encounter_id = o.encounter_id
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', '2545')
SET tmhv.tobacco = CONCEPT_NAME(value_coded, 'en');

UPDATE temp_mh_visits tmhv
SET tmhv.tsq_score = obs_value_numeric_from_temp(encounter_id,'PIH', '14668');

UPDATE temp_mh_visits tmhv
SET tmhv.gad_7_score = obs_value_numeric_from_temp(encounter_id,'PIH', '11733');

UPDATE temp_mh_visits tmhv
SET tmhv.phq_9_score = obs_value_numeric_from_temp(encounter_id,'PIH', '11586');

UPDATE temp_mh_visits tmhv
SET tmhv.cage_score = obs_value_numeric_from_temp(encounter_id,'PIH', '14641');

UPDATE temp_mh_visits tmhv
SET tmhv.cgi = obs_value_numeric_from_temp(encounter_id,'PIH', '14670');

UPDATE temp_mh_visits tmhv
INNER JOIN temp_obs o ON tmhv.encounter_id = o.encounter_id
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', '10633')
SET tmhv.suicidal_ideation = CONCEPT_NAME(o.value_coded, 'en');

UPDATE temp_mh_visits tmhv
INNER JOIN temp_obs o ON tmhv.encounter_id = o.encounter_id
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', '14108')
SET tmhv.homicidal_ideation = CONCEPT_NAME(o.value_coded, 'en');

update temp_mh_visits set provider = provider(encounter_id);
update temp_mh_visits set user_entered = encounter_creator(encounter_id);

UPDATE temp_mh_visits tmhv
INNER JOIN temp_obs o ON tmhv.encounter_id = o.encounter_id
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', '14271')
SET tmhv.cf_concentration = CONCEPT_NAME(o.value_coded, 'en');

UPDATE temp_mh_visits tmhv
INNER JOIN temp_obs o ON tmhv.encounter_id = o.encounter_id
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', '10589')
SET tmhv.whodas_score = o.value_numeric;

UPDATE temp_mh_visits tmhv
INNER JOIN temp_obs o ON tmhv.encounter_id = o.encounter_id
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', '14272')
SET tmhv.cf_memory = CONCEPT_NAME(o.value_coded, 'en');

UPDATE temp_mh_visits tmhv
INNER JOIN temp_obs o ON tmhv.encounter_id = o.encounter_id
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', '14110')
SET tmhv.cf_judgement = CONCEPT_NAME(o.value_coded, 'en');

UPDATE temp_mh_visits tmhv
INNER JOIN temp_obs o ON tmhv.encounter_id = o.encounter_id
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', '14109')
SET tmhv.cf_insight = CONCEPT_NAME(o.value_coded, 'en');

UPDATE temp_mh_visits tmhv
INNER JOIN temp_obs o ON tmhv.encounter_id = o.encounter_id
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', '10648')
SET tmhv.suicidality_screening = value_coded_as_boolean(o.obs_id);


UPDATE temp_mh_visits tmhv
INNER JOIN temp_obs o ON tmhv.encounter_id = o.encounter_id
AND o.concept_id = CONCEPT_FROM_MAPPING('PIH', '12376')
SET tmhv.result_of_suicide_risk_evaluation = CONCEPT_NAME(o.value_coded, 'en');

UPDATE temp_mh_visits tmhv
SET tmhv.counselling_plan = obs_value_text_from_temp(encounter_id, 'PIH', '14479');

drop temporary table if exists temp_mh_visits_index_asc;
CREATE TEMPORARY TABLE temp_mh_visits_index_asc
(
    SELECT
            visits_id,
            patient_id,
            encounter_id,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            encounter_id,
            visits_id,
            patient_id,
            @u:= patient_id
      FROM temp_mh_visits tm,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, encounter_id, visits_id ASC
        ) index_ascending );

CREATE INDEX tvia_e ON temp_mh_visits_index_asc(encounter_id);
update temp_mh_visits tmhv
inner join temp_mh_visits_index_asc tvia on tmhv.visits_id = tvia.visits_id
set tmhv.index_asc = tvia.index_asc;

drop temporary table if exists temp_mh_visits_index_desc;
CREATE TEMPORARY TABLE temp_mh_visits_index_desc
(
    SELECT
            visits_id,
            patient_id,
            encounter_id,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_desc,

            encounter_id,
            patient_id,
            visits_id,
            @u:= patient_id
      FROM temp_mh_visits,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id DESC,  encounter_id desc, visits_id DESC
        ) index_descending );

CREATE INDEX tvid_e ON temp_mh_visits_index_desc(encounter_id);

update temp_mh_visits tmhv
inner join temp_mh_visits_index_desc tvid on tmhv.visits_id = tvid.visits_id
set tmhv.index_desc = tvid.index_desc;

update temp_mh_visits tmhv
set tmhv.ms_mood = obs_value_coded_list_from_temp(encounter_id, 'PIH','14131','en');

update temp_mh_visits tmhv
set tmhv.ms_appearance_posture = obs_value_coded_list_from_temp(encounter_id, 'PIH','14126','en');

update temp_mh_visits tmhv
set tmhv.ms_speech = obs_value_coded_list_from_temp(encounter_id,'PIH','14286', 'en');

update temp_mh_visits tmhv
set tmhv.ms_affect = obs_value_coded_list_from_temp(encounter_id, 'PIH','14155','en');

update temp_mh_visits tmhv
set tmhv.ms_thought_process = obs_value_coded_list_from_temp(encounter_id, 'PIH','14156','en');

update temp_mh_visits tmhv
set tmhv.ms_thought_perceptual_content = obs_value_coded_list_from_temp(encounter_id, 'PIH','14259','en');

update temp_mh_visits tmhv
set tmhv.cf_consciousness_orient = obs_value_coded_list_from_temp(encounter_id, 'PIH','14107','en');

update temp_mh_visits tmhv
set tmhv.date_entered = encounter_date_created(encounter_id);

UPDATE temp_mh_visits tmhv SET tmhv.return_visit_date=obs_value_datetime_from_temp(encounter_id, 'PIH','5096');


select * from temp_mh_visits;