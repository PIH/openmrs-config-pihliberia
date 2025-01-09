-- set @startDate = '2016-01-01';
-- set @endDate = '2016-12-31';

select encounter_type_id  into @checkinEncTypeId from encounter_type where uuid = '55a0d3ea-a4d7-4e88-8f01-5aceb2d3c61b';

drop temporary table if exists temp_visits;
create temporary table temp_visits
(patient_id			int(11),
emr_id				varchar(50),
visit_id			int(11),
visit_date_started	datetime,
visit_date_stopped	datetime,
visit_date_entered	datetime,
visit_creator		int(11),
visit_user_entered	varchar(255),
visit_type_id		int(11),
visit_type			varchar(255),
checkin_encounter_id	int(11),	
visit_checkin		bit,
visit_reason		varchar(255),
location_id			int(11),
visit_location		varchar(255),
first_visit_this_year boolean,
number_of_encounters int);

insert into temp_visits(patient_id, visit_id, visit_date_started, visit_date_stopped, visit_date_entered, visit_type_id, visit_creator, location_id)
select patient_id, visit_id, date_started, date_stopped, date_created, visit_type_id, creator, location_id  
from visit v 
where v.voided = 0
AND ((date(v.date_started) >=@startDate) or @startDate is null)
AND ((date(v.date_started) <=@endDate)  or @endDate is null);

create index temp_visits_vi on temp_visits(visit_id);

-- emr_id
DROP TEMPORARY TABLE IF EXISTS temp_identifiers;
CREATE TEMPORARY TABLE temp_identifiers
(
patient_id						INT(11),
emr_id							VARCHAR(25)
);

INSERT INTO temp_identifiers(patient_id)
select distinct patient_id from temp_visits;

update temp_identifiers t set emr_id  = patient_identifier(patient_id, '0bc545e0-f401-11e4-b939-0800200c9a66');

CREATE INDEX temp_identifiers_p ON temp_identifiers (patient_id);

update temp_visits tv 
inner join temp_identifiers ti on ti.patient_id = tv.patient_id
set tv.emr_id = ti.emr_id;

-- visit type
update temp_visits t
inner join visit_type vt on vt.visit_type_id = t.visit_type_id
set t.visit_type = vt.name;

-- locations
DROP TEMPORARY TABLE IF EXISTS temp_locations;
CREATE TEMPORARY TABLE temp_locations
(
location_id						INT(11),
location_name					VARCHAR(255)
);

INSERT INTO temp_locations(location_id)
select distinct location_id from temp_visits;

update temp_locations t set location_name =  location_name(location_id);	

CREATE INDEX temp_locations_li ON temp_locations (location_id);

update temp_visits tv 
inner join temp_locations tl on tl.location_id = tv.location_id
set tv.visit_location = tl.location_name;

-- user entered
DROP TEMPORARY TABLE IF EXISTS temp_users;
CREATE TEMPORARY TABLE temp_users
(
creator						INT(11),
creator_name				VARCHAR(255)
);

INSERT INTO temp_users(creator)
select distinct visit_creator from temp_visits;

CREATE INDEX temp_users_c ON temp_users(creator);

update temp_users t set creator_name  = person_name_of_user(creator);	

update temp_visits tv 
inner join temp_users tu on tu.creator = tv.visit_creator
set tv.visit_user_entered = tu.creator_name;

-- check-in
update temp_visits v
set v.checkin_encounter_id =  
	(select max(e.encounter_id) from encounter e where e.visit_id = v.visit_id and e.encounter_type = @checkinEncTypeId and e.voided = 0);

update temp_visits tv 
set tv.first_visit_this_year = 1
where not EXISTS 
	(select 1 from visit v
	where v.patient_id = tv.patient_id
	and v.date_started < tv.visit_date_started
	and YEAR(v.date_started) = YEAR(tv.visit_date_started)
	and v.visit_id <> tv.visit_id);

update temp_visits tv 
set visit_reason = obs_value_coded_list(checkin_encounter_id, 'PIH','6189','en');

update temp_visits tv 
set number_of_encounters = 
	(select count(*) from encounter e where e.visit_id = tv.visit_id and e.voided = 0);

select 
emr_id,
visit_id,
patient_id,
visit_date_started,
visit_date_stopped,
visit_date_entered,
visit_user_entered,
visit_type,
if(checkin_encounter_id is null, null, 1) as visit_checkin,
visit_reason,
visit_location,
first_visit_this_year,
number_of_encounters
from temp_visits;
