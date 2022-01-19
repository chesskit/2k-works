SELECT /*Pivoting the table*/
  AgeGroup '-',
  ifnull(SUM(`15-19 Yrs`),0) AS '15-19 Yrs',
  ifnull(SUM(`20-24 Yrs`),0) AS '20-24 Yrs',
  ifnull(SUM(`25-49 Yrs`),0) AS '25-49 Yrs'
from (/*Grouping and counting the patients*/
       SELECT
         'Number of deliveries'                  AS 'AgeGroup',
         CASE WHEN AgeGroup = '15-19 Yrs'
           THEN count(DISTINCT PatientCount) END AS '15-19 Yrs',
         CASE WHEN AgeGroup = '20-24 Yrs'
           THEN count(DISTINCT PatientCount) END AS '20-24 Yrs',
         CASE WHEN AgeGroup = '25-49 Yrs'
           THEN count(DISTINCT PatientCount) END AS '25-49 Yrs'
       FROM
         (/*Getting the age group with the obs id*/
           SELECT
             CASE WHEN datediff(o.obs_datetime, p.birthdate) BETWEEN 5114 AND 6940
               THEN '15-19 Yrs'
             WHEN datediff(o.obs_datetime, p.birthdate) BETWEEN 6941 AND 8766
               THEN '20-24 Yrs'
             WHEN datediff(o.obs_datetime, p.birthdate) BETWEEN 8767 AND 17897
               THEN '25-49 Yrs' END AS 'AgeGroup',
             obs_id                 AS 'PatientCount'
           FROM obs o
             JOIN concept_name cn
               ON cn.concept_id = o.concept_id
             JOIN person p
               ON p.person_id = o.person_id
           WHERE cn.name = 'Immediate post partum record'
                 AND cn.concept_name_type = 'FULLY_SPECIFIED'
                 AND o.voided IS FALSE
                 AND datediff(o.obs_datetime, p.birthdate) < 17898/*Age is less than 49 years*/
                 AND p.gender = 'F'/*Considering only Female patients*/
                 AND DATE(o.obs_datetime) BETWEEN '#startDate#' and '#endDate#'
         ) ObsWithAgeGroup
       GROUP BY AgeGroup
     ) as CountingObsOnAgeGroup
GROUP BY AgeGroup;
