/*NOTE:
 * This is a cloned version of the diagnoses script that is in PIH EMR config
 * It was moved into Liberia with the following changes:
 *  - added service columns
 *  - added index_asc, index_desc
 * 
 * When the Liberia Data Warehouse is built, we probably want to use version in PH EMR 
 * (and maybe add service and change the address columns?)
 */
SET @locale =   if(@startDate is null, 'en', GLOBAL_PROPERTY_VALUE('default_locale', 'en'));

DROP TEMPORARY TABLE IF EXISTS temp_diagnoses;
CREATE TEMPORARY TABLE temp_diagnoses
(
 patient_id         int(11),      
 encounter_id       int(11),      
 obs_id             int(11),      
 obs_datetime       datetime,     
 diagnosis_entered  text,         
 dx_order           varchar(255), 
 certainty          varchar(255), 
 coded              varchar(255), 
 diagnosis_concept  int(11),      
 diagnosis_coded_en varchar(255), 
 age_at_encounter   double,
 encounter_location varchar(255),
 date_created       datetime,
 entered_by         varchar(255),
 provider           varchar(255),
 birthdate_estimated boolean,
 encounter_type     varchar(255),
 service            varchar(255),
 visit_id           int(11),
 index_asc          int,
 index_desc         int
 );

insert into temp_diagnoses 
(
patient_id,
encounter_id,
obs_id,
obs_datetime,
date_created 
)
select 
o.person_id,
o.encounter_id,
o.obs_id,
o.obs_datetime,
o.date_created 
from obs o 
where concept_id = concept_from_mapping('PIH','Visit Diagnoses')
AND o.voided = 0
AND ((date(o.obs_datetime) >=@startDate) or @startDate is null)
AND ((date(o.obs_datetime) <=@endDate)  or @endDate is null)
;

create index temp_diagnoses_e on temp_diagnoses(encounter_id);
create index temp_diagnoses_p on temp_diagnoses(patient_id);

-- encounter level information
DROP TEMPORARY TABLE IF EXISTS temp_dx_encounter;
CREATE TEMPORARY TABLE temp_dx_encounter
(
 patient_id          int(11),      
 encounter_id        int(11),   
 encounter_location_id int(11),
 encounter_location  varchar(255),
 encounter_type_id   int(11),
 encounter_type      varchar(255),
 service             varchar(255),
 age_at_encounter    int(3),
 entered_by_user_id  int(11),
 entered_by          varchar(255), 
 provider            varchar(255), 
 date_created        datetime,     
 visit_id            int(11),      
 birthdate           datetime,     
 birthdate_estimated boolean     
);

insert into temp_dx_encounter(encounter_id)
select distinct encounter_id from temp_diagnoses;

create index temp_dx_encounter_ei on temp_dx_encounter(encounter_id);  

update temp_dx_encounter t
inner join encounter e on e.encounter_id  = t.encounter_id
set t.entered_by_user_id = e.creator,
	t.visit_id = e.visit_id,
	t.encounter_type_id = e.encounter_type,
	t.patient_id = e.patient_id,
	t.encounter_location_id = e.location_id,
	t.date_created = e.date_created;

select encounter_type_id into @MHIntake from encounter_type et where uuid = 'fccd53c2-f802-439b-a7a2-2d680bd8b81b';
select encounter_type_id into @MHConsult from encounter_type et where uuid = 'a8584ab8-cc2a-11e5-9956-625662870761';
select encounter_type_id into @MHEpilepsyFollowup from encounter_type et where uuid = '74e06462-243e-4fad-8d7c-0bb3921322f1';
select encounter_type_id into @MHEpilepsyIntake from encounter_type et where uuid = '7336a05e-4bd1-4e52-81c1-207697afc868';

select encounter_type_id into @ANCFollowup from encounter_type et where uuid = '00e5e946-90ec-11e8-9eb6-529269fb1459';
select encounter_type_id into @Delivery from encounter_type et where uuid = '00e5ebb2-90ec-11e8-9eb6-529269fb1459';
select encounter_type_id into @ANCIntake from encounter_type et where uuid = '00e5e810-90ec-11e8-9eb6-529269fb1459';
select encounter_type_id into @PEDS from encounter_type et where uuid = 'fac9d9a2-d0bc-11ea-9995-3c6aa7c392cc';

select encounter_type_id into @NCDInitial from encounter_type et where uuid = 'ae06d311-1866-455b-8a64-126a9bd74171';
select encounter_type_id into @NCDFollowup from encounter_type et where uuid = '5cbfd6a2-92d9-4ad0-b526-9d29bfe1d10c';

select encounter_type_id into @Consult from encounter_type et where uuid = '92fd09b4-5335-4f7e-9f63-b2a663fd09a6';
update temp_dx_encounter
set service = 
case 
	when encounter_type_id in (@MHIntake, @MHConsult, @MHEpilepsyFollowup,  @MHEpilepsyIntake) then 'Mental Health'
	when encounter_type_id in (@ANCFollowup, @Delivery, @ANCIntake,  @PEDS) then 'MCH'
	when encounter_type_id in (@NCDInitial, @NCDFollowup) then 'NCD'
	when encounter_type_id in (@Consult) then 'OPD'	
end;	

update temp_dx_encounter set encounter_location = location_name(encounter_location_id);
update temp_dx_encounter set entered_by = person_name_of_user(entered_by_user_id);
update temp_dx_encounter set encounter_type = encounter_type_name_from_id(encounter_type_id);

update temp_dx_encounter set provider = provider(encounter_id);
update temp_dx_encounter set age_at_encounter = age_at_enc(patient_id, encounter_id);

update temp_diagnoses td
inner join temp_dx_encounter tde on tde.patient_id = td.patient_id
set td.encounter_location= tde.encounter_location,
td.encounter_type= tde.encounter_type,
td.service= tde.service,
td.age_at_encounter= tde.age_at_encounter,
td.entered_by= tde.entered_by,
td.provider= tde.provider,
td.date_created= tde.date_created,
td.visit_id= tde.visit_id;


-- delete rows that do not match the service, if one was passed in
delete from temp_diagnoses
where @service is not NULL
and service <> @service;

-- patient level info
DROP TEMPORARY TABLE IF EXISTS temp_dx_patient;
CREATE TEMPORARY TABLE temp_dx_patient
(
patient_id               int(11),      
patient_primary_id       varchar(50),  
loc_registered           varchar(255), 
unknown_patient          varchar(50),  
gender                   varchar(50),  
county                   varchar(255), 
district                 varchar(255),
settlement               varchar(255), 
address                  varchar(255), 
street_landmark          varchar(255), 
birthdate                datetime,     
birthdate_estimated      boolean      
);
   
insert into temp_dx_patient(patient_id)
select distinct patient_id from temp_diagnoses;

create index temp_dx_patient_pi on temp_dx_patient(patient_id);

update temp_dx_patient set patient_primary_id = patient_identifier(patient_id, metadata_uuid('org.openmrs.module.emrapi', 'emr.primaryIdentifierType'));
update temp_dx_patient set loc_registered = loc_registered(patient_id);
update temp_dx_patient set unknown_patient = unknown_patient(patient_id);
update temp_dx_patient set gender = gender(patient_id);

update temp_dx_patient t
inner join person p on p.person_id  = t.patient_id
set t.birthdate = p.birthdate,
	t.birthdate_estimated = t.birthdate_estimated;

update temp_dx_patient set county = person_address_state_province(patient_id);
update temp_dx_patient set district = person_address_county_district(patient_id);
update temp_dx_patient set settlement = person_address_city_village(patient_id);
update temp_dx_patient set address = person_address_one(patient_id);

 -- diagnosis info
DROP TEMPORARY TABLE IF EXISTS temp_obs;
create temporary table temp_obs 
select o.obs_id, o.voided ,o.obs_group_id , o.encounter_id, o.person_id, o.concept_id, o.value_coded, o.value_numeric, o.value_text,o.value_datetime, o.value_coded_name_id ,o.comments 
from obs o
inner join temp_diagnoses t on t.obs_id = o.obs_group_id
where o.voided = 0;

create index temp_obs_concept_id on temp_obs(concept_id);
create index temp_obs_ogi on temp_obs(obs_group_id);
create index temp_obs_ci1 on temp_obs(obs_group_id, concept_id);

       
 update temp_diagnoses t
 left outer join temp_obs o on o.obs_group_id = t.obs_id and o.concept_id = concept_from_mapping('PIH','DIAGNOSIS')
 left outer join obs o_non on o_non.obs_group_id = t.obs_id and o_non.concept_id = concept_from_mapping('PIH','Diagnosis or problem, non-coded') 
 left outer join concept_name cn on cn.concept_name_id  = o.value_coded_name_id 
 set t.diagnosis_entered = IFNULL(cn.name,IFNULL( concept_name(o.value_coded,'en'),o_non.value_text)), 
 	 t.diagnosis_concept = o.value_coded,
     t.diagnosis_coded_en = concept_name(o.value_coded,'en'),
     t.coded = IF(o.value_coded is null, 0,1);

update temp_diagnoses t
inner join temp_obs o on o.obs_group_id = t.obs_id and o.concept_id = concept_from_mapping( 'PIH','7537')
set t.dx_order = concept_name(o.value_coded, @locale);

update temp_diagnoses t
inner join temp_obs o on o.obs_group_id = t.obs_id and o.concept_id = concept_from_mapping( 'PIH','1379')
set t.certainty = concept_name(o.value_coded, @locale);

-- diagnosis concept-level info
DROP TEMPORARY TABLE IF EXISTS temp_dx_concept;
CREATE TEMPORARY TABLE temp_dx_concept
(
 diagnosis_concept int(11),       
 icd10_code        varchar(255), 
 notifiable        int(1),       
 urgent            int(1),       
 santeFamn         int(1),       
 psychological     int(1),       
 pediatric         int(1),       
 outpatient        int(1),       
 ncd               int(1),       
 non_diagnosis     int(1),        
 ed                int(1),        
 age_restricted    int(1),       
 oncology          int(1)        
);
   
insert into temp_dx_concept(diagnosis_concept)
select distinct diagnosis_concept from temp_diagnoses;

create index temp_dx_patient_dc on temp_dx_concept(diagnosis_concept);

update temp_dx_concept set icd10_code = retrieveICD10(diagnosis_concept);
    
select concept_id into @non_diagnoses from concept where uuid = 'a2d2124b-fc2e-4aa2-ac87-792d4205dd8d';    
update temp_dx_concept set notifiable = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','8612'));
update temp_dx_concept set santeFamn = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7957'));
update temp_dx_concept set urgent = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7679'));
update temp_dx_concept set psychological = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7942'));
update temp_dx_concept set pediatric = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7933'));
update temp_dx_concept set outpatient = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7936'));
update temp_dx_concept set ncd = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7935'));
update temp_dx_concept set non_diagnosis = concept_in_set(diagnosis_concept, @non_diagnoses);
update temp_dx_concept set ed = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7934'));
update temp_dx_concept set age_restricted = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','7677'));
update temp_dx_concept set oncology = concept_in_set(diagnosis_concept, concept_from_mapping('PIH','8934'));

-- The ascending/descending indexes are calculated ordering on the dispense date
-- new temp tables are used to build them and then joined into the main temp table.
### index ascending
drop temporary table if exists temp_visit_index_asc;
CREATE TEMPORARY TABLE temp_visit_index_asc
(
    SELECT
            patient_id,
            obs_datetime,
            obs_id,
            index_asc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_asc,
            obs_datetime,
            obs_id,
            patient_id,
            @u:= patient_id
      FROM temp_diagnoses,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, obs_datetime ASC, obs_id ASC
        ) index_ascending );
       
CREATE INDEX tvia_e ON temp_visit_index_asc(obs_id);
update temp_diagnoses t
inner join temp_visit_index_asc tvia on tvia.obs_id = t.obs_id
set t.index_asc = tvia.index_asc;

drop temporary table if exists temp_visit_index_desc;
CREATE TEMPORARY TABLE temp_visit_index_desc
(
    SELECT
            patient_id,
            obs_datetime,
            obs_id,
            index_desc
FROM (SELECT
            @r:= IF(@u = patient_id, @r + 1,1) index_desc,
            obs_datetime,
            obs_id,
            patient_id,
            @u:= patient_id
      FROM temp_diagnoses,
                    (SELECT @r:= 1) AS r,
                    (SELECT @u:= 0) AS u
            ORDER BY patient_id, obs_datetime DESC, obs_id DESC
        ) index_descending );
       
CREATE INDEX tvid_e ON temp_visit_index_desc(obs_id);
update temp_diagnoses t
inner join temp_visit_index_desc tvia on tvia.obs_id = t.obs_id
set t.index_desc = tvia.index_desc;

-- select final output
select 
p.patient_id,
p.patient_primary_id "emr_id",
p.loc_registered,
p.unknown_patient,
p.gender,
d.age_at_encounter,
p.county,
p.district,
p.settlement,
p.address,
d.encounter_id,
d.encounter_location,
d.obs_id,
d.obs_datetime,
d.entered_by,
d.provider,
d.diagnosis_entered,
d.dx_order,
d.certainty,
d.coded,
d.diagnosis_concept,
d.diagnosis_coded_en,
dc.icd10_code,
dc.notifiable,
dc.urgent,
dc.santeFamn,
dc.psychological,
dc.pediatric,
dc.outpatient,
dc.ncd,
dc.non_diagnosis,
dc.ed,
dc.age_restricted,
dc.oncology,
d.date_created,
IF(TIME_TO_SEC(d.date_created) - TIME_TO_SEC(d.obs_datetime) > 1800,1,0) "retrospective",
d.visit_id,
p.birthdate,
p.birthdate_estimated,
d.encounter_type,
d.service,
d.index_asc,
d.index_desc
from temp_diagnoses d
inner join temp_dx_patient p on p.patient_id = d.patient_id
left outer join temp_dx_concept dc on dc.diagnosis_concept = d.diagnosis_concept
;
