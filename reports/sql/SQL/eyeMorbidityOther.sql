
select
  `Purpose of Visit`,
  `Number of patients`
from (
       select                                   /* New and Followup Patients */
         1 as ordering,
         cn2.name as 'Purpose of Visit',
         case when cn2.name='Followup' then count(DISTINCT obs.obs_id) +
                                            (/*Patients for whom PMT form is filled*/
                                              Select count(DISTINCT o.obs_id) from obs o
                                                join concept_name cn
                                                  on o.concept_id = cn.concept_id
                                              where cn.name='Eye PMT/Acceptance form' and cn.concept_name_type = 'FULLY_SPECIFIED'
                                            ) else count(obs.person_id) End as 'Number of patients'
       from obs
         join concept_name cn on obs.concept_id=cn.concept_id
         join concept_name cn2 on obs.value_coded=cn2.concept_id
         join person  on obs.person_id=person.person_id
       where cn.name='Eye Form, Purpose of Visit'
             and obs.value_coded IN (select concept_id from concept_name where name IN ('New','Followup'))
             and obs.voided = 0
             and date(obs.obs_datetime) BETWEEN '#startDate#' and '#endDate#'
       Group by obs.value_coded


       Union all


       Select 2 as ordering,                  /* Total cases examined in OPD */
              'Total Cases Examined in OPD' as 'Purpose of Visit',
         IFNULL(sum(Numberofpatients),0) as 'Number of patients'
from(
     select cn2.name as 'Purpose of Visit',
            case when cn2.name='Followup' then count(DISTINCT obs.obs_id) +
                                               (/*Patients for whom PMT form is filled*/
                                                 Select count(DISTINCT o.obs_id) from obs o
                                                   join concept_name cn
                                                     on o.concept_id = cn.concept_id
                                                 where cn.name='Eye PMT/Acceptance form' and cn.concept_name_type = 'FULLY_SPECIFIED'
                                               ) else count(obs.person_id) End as 'Numberofpatients'
     from obs
       join concept_name cn on obs.concept_id=cn.concept_id
       join concept_name cn2 on obs.value_coded=cn2.concept_id
       join person  on obs.person_id=person.person_id
     where cn.name='Eye Form, Purpose of Visit'
           and obs.value_coded IN (select concept_id from concept_name where name IN ('Followup','New','Medical certificate'))
           and obs.voided = 0
           and date(obs.obs_datetime) BETWEEN '#startDate#' and '#endDate#'
     Group by obs.value_coded) EyeCasesInOPD

       Union all

       Select 3 as ordering,               /* No. of Admitted and Referred Out Patients */
              cn2.name as 'Admitted/Referred Out',
               count(distinct obs_id) as 'Number of patients'
       from obs
         join concept_name cn on obs.concept_id=cn.concept_id
         join concept_name cn2 on obs.value_coded=cn2.concept_id
       where cn.name = 'Eye, Admitted/Referred Out' and cn.concept_name_type = 'FULLY_SPECIFIED'
             and obs.voided=0
             and cn2.name in  ('Admitted','Referred Out') and cn2.concept_name_type = 'FULLY_SPECIFIED'
             and date(obs.obs_datetime) BETWEEN '#startDate#' and '#endDate#'
       group by obs.value_coded

       Union all

       Select 4 as ordering,             /* Total no. of Minor Surgeries */
              'Total no. of Minor Surgeries' as 'Purpose of Visit',
              count(DISTINCT obs.obs_id) as 'Number of patients'
       from obs
         join concept_name cn on obs.concept_id=cn.concept_id
       where cn.name = 'Eye, Minor Surgeries' and cn.concept_name_type='FULLY_SPECIFIED'
             and obs.voided = 0
             AND date(obs.obs_datetime) BETWEEN '#startDate#' and '#endDate#'

       Union all

       select 5 as ordering,            /* Total no. of all disease patients */
              'Total number of all disease patients' as 'Purpose of Visit',
              COUNT(DISTINCT obs.obs_id) AS 'Number of patients'
       from
         obs
       where
         value_coded IN
         ( /*Getting all the eye diagnosis codes*/
           Select cs.concept_id from concept_set cs
             join concept_name cn
               on cs.concept_set=cn.concept_id
           where cn.name='Diseases of the Eye'
                 and cn.concept_name_type = 'FULLY_SPECIFIED'
                 and cn.voided IS FALSE
         )
         AND DATE(obs_datetime) BETWEEN '#startDate#' and '#endDate#'
         AND voided IS FALSE

     ) Temp
order by ordering;
