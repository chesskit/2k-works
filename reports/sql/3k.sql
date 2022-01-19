Select                /* No. of Admitted and Referred Out Patients */
  1 as ordering,           
 cn2.name as 'Total New Clients',

               count(distinct obs_id) as 'Number of patients'
       from obs
         join concept_name cn on obs.concept_id=cn.concept_id
         join concept_name cn2 on obs.value_coded=cn2.concept_id
       where cn.name = 'Injuries and Adverse Effects' and cn.concept_name_type = 'FULLY_SPECIFIED'
             and obs.voided=0
             and cn2.name in  ('Road Traffic Accident') and cn2.concept_name_type = 'FULLY_SPECIFIED'
             and date(obs.obs_datetime) BETWEEN '#startDate#' and '#endDate#'
       group by obs.value_coded

union all

Select                /* No. of Admitted and Referred Out Patients */
    2 as ordering,     
    cn2.name as 'revisits',
               count(distinct obs_id) as 'Number of patients'
       from obs
         join concept_name cn on obs.concept_id=cn.concept_id
         join concept_name cn2 on obs.value_coded=cn2.concept_id
       where cn.name = 'Type Of Visit,1 = New Visit, 2 = Re-Visit' and cn.concept_name_type = 'FULLY_SPECIFIED'
             and obs.voided=0
             and cn2.name in  ('2 = Re-Visit') and cn2.concept_name_type = 'FULLY_SPECIFIED'
             and date(obs.obs_datetime) BETWEEN '#startDate#' and '#endDate#'
       group by obs.value_coded

union all

Select                /* No. of Admitted and Referred Out Patients */
    3 as ordering,     
    cn2.name as 'Total New Clients',
               count(distinct obs_id) as 'Number of patients'
       from obs
         join concept_name cn on obs.concept_id=cn.concept_id
         join concept_name cn2 on obs.value_coded=cn2.concept_id
       where cn.name = 'Weight categories: (1=Normal, 2=UW 3= SUW 4=OW 5=Obese)' and cn.concept_name_type = 'FULLY_SPECIFIED'
             and obs.voided=0
             and cn2.name in  ('2=UW') and cn2.concept_name_type = 'FULLY_SPECIFIED'
             and date(obs.obs_datetime) BETWEEN '#startDate#' and '#endDate#'
       group by obs.value_coded

union all

Select
4 as ordering,     
     cn2.name as 'Total New Clients',
               count(distinct obs_id) as 'Number of patients'
       from obs
         join concept_name cn on obs.concept_id=cn.concept_id
         join concept_name cn2 on obs.value_coded=cn2.concept_id
       where cn.name = 'Weight categories: (1=Normal, 2=UW 3= SUW 4=OW 5=Obese)' and cn.concept_name_type = 'FULLY_SPECIFIED'
             and obs.voided=0
             and cn2.name in  ('4=OW') and cn2.concept_name_type = 'FULLY_SPECIFIED'
             and date(obs.obs_datetime) BETWEEN '#startDate#' and '#endDate#'
       group by obs.value_coded

union all

Select
5 as ordering,     
     cn2.name as 'Total New Clients',
               count(distinct obs_id) as 'Number of patients'
       from obs
         join concept_name cn on obs.concept_id=cn.concept_id
         join concept_name cn2 on obs.value_coded=cn2.concept_id
       where cn.name = 'Height/length categories: (1= Normal 2=Stunted 3= Sev. Stunted)' and cn.concept_name_type = 'FULLY_SPECIFIED'
             and obs.voided=0
             and cn2.name in  ('2=Stunted') and cn2.concept_name_type = 'FULLY_SPECIFIED'
             and date(obs.obs_datetime) BETWEEN '#startDate#' and '#endDate#'
       group by obs.value_coded

union all

select
6 as ordering,     
    cn2.name as 'Total New Clients',
               count(distinct obs_id) as 'Number of patients'
       from obs
         join concept_name cn on obs.concept_id=cn.concept_id
         join concept_name cn2 on obs.value_coded=cn2.concept_id
       where cn.name = 'Exclusive Breastfeeding (Less than 6 Months)' and cn.concept_name_type = 'FULLY_SPECIFIED'
             and obs.voided=0
             and date(obs.obs_datetime) BETWEEN '#startDate#' and '#endDate#'
       group by obs.value_coded

