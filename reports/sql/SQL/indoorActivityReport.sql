/*Admission: The count of the admitted patients*/
SELECT
   1 AS 'SrNo',
  'No. Of Indoor Admissions'               AS 'Details',
  count(v.patient_id)+ (SELECT/* Adding the undo discharge cases to the admission count*/
                          count(v.patient_id)
                        FROM visit v
                          JOIN person_name pn ON v.patient_id = pn.person_id
                          JOIN encounter e ON e.visit_id = v.visit_id
                          JOIN encounter_type et ON e.encounter_type = et.encounter_type_id
                        WHERE
                          cast(e.date_voided AS DATE) BETWEEN '#startDate#' and '#endDate#'
                          AND v.voided IS FALSE
                          AND et.name IN ('DISCHARGE')
                          AND e.void_reason = 'Undo Discharge'
  ) AS 'Counts'
FROM visit v
  JOIN person_name pn ON v.patient_id = pn.person_id
  JOIN encounter e ON e.visit_id = v.visit_id
  JOIN encounter_type et ON e.encounter_type = et.encounter_type_id
WHERE
  cast(e.encounter_datetime AS DATE) BETWEEN '#startDate#' and '#endDate#'
  AND v.voided IS FALSE
  AND et.name IN ('ADMISSION')
  AND e.voided IS FALSE

UNION All

/*Refer In: Total number of refer in patients*/
SELECT
   2 AS 'SrNo',
  'No. Of Referred In Cases'               AS 'Details',
  count(DISTINCT o.obs_id) AS 'Counts'
FROM visit v
  JOIN person_name pn ON v.patient_id = pn.person_id
  JOIN encounter e ON e.visit_id = v.visit_id
  JOIN encounter_type et ON e.encounter_type = et.encounter_type_id
  JOIN obs o ON o.person_id = v.patient_id
  JOIN concept_name cn ON o.concept_id = cn.concept_id
WHERE
  cast(o.obs_datetime AS DATE) BETWEEN '#startDate#' and '#endDate#'
  AND v.voided IS FALSE
  AND et.name IN ('ADMISSION')
  AND e.voided IS FALSE
  AND cn.name = 'Refer In Details' AND cn.concept_name_type = 'FULLY_SPECIFIED'
  AND o.voided = FALSE

UNION All

/*Refer out: Total number of refer out patients on that day.*/
SELECT
   3 AS 'SrNo',
  'No. Of Referred Out Cases'                        AS 'Details',
  count(DISTINCT o.obs_id) AS 'Counts'
FROM visit v
  JOIN person_name pn ON v.patient_id = pn.person_id
  JOIN encounter e ON e.visit_id = v.visit_id
  JOIN encounter_type et ON e.encounter_type = et.encounter_type_id
  JOIN obs o ON o.person_id = v.patient_id
  JOIN concept_name cn ON o.concept_id = cn.concept_id
WHERE
  cast(o.obs_datetime AS DATE) BETWEEN '#startDate#' and '#endDate#'
  AND v.voided IS FALSE
  AND et.name IN ('ADMISSION', 'DISCHARGE')
  AND e.voided IS FALSE
  AND cn.name = 'Referral Form' AND cn.concept_name_type = 'FULLY_SPECIFIED'
  AND o.voided = FALSE

UNION All

/*Number of deliveries*/
SELECT
   4 AS 'SrNo',
  'No. Of Deliveries' AS 'Details',
  count(obs_id)                 AS 'Counts'
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

UNION All

/*Dead: Total number of dead patients on that day.*/
SELECT
   5 AS 'SrNo',
  'No. Of Death' AS 'Details',
  count(DISTINCT v.patient_id) 'Counts'
FROM visit v
  JOIN person_name pn ON v.patient_id = pn.person_id
  JOIN person p ON p.person_id = pn.person_id
  JOIN encounter e ON e.visit_id = v.visit_id
  JOIN encounter_type et ON e.encounter_type = et.encounter_type_id
WHERE
  cast(p.death_date AS DATE) BETWEEN '#startDate#' and '#endDate#'
  AND v.voided IS FALSE
  AND et.name IN ('ADMISSION', 'DISCHARGE')
  AND e.voided IS FALSE
  AND p.dead IS TRUE

UNION All

/*Emergency cases seen in ward*/
Select
   6 AS 'SrNo',
  'No. Of Emergency Cases Seen In Ward' AS 'Details',
  count(DISTINCT v.visit_id) 'Counts'
from visit v
JOIN visit_type vt
on v.visit_type_id=vt.visit_type_id
where
  vt.name='Emergency'
  and v.voided is FALSE
  and date(v.date_started)  BETWEEN '#startDate#' and '#endDate#'

UNION All

/*Number of obstetric admissions*/
Select
   7 AS 'SrNo',
  'No. Of Obs Admissions' AS 'Details',
  count(DISTINCT o.person_id,e.visit_id) 'Counts'
from obs o
  JOIN encounter e
  on o.encounter_id = e.encounter_id
where o.value_coded in (/*Filtering on the diagnosis for Obstetric*/
                        Select cs.concept_id from concept_name cn
                        join concept_set cs
                          on cn.concept_id=cs.concept_set
                      where cn.name = 'Pregnancy, Childbirth & the Puerperium'
                            and cn.concept_name_type='FULLY_SPECIFIED'
)/*Ignoring the inactive diagnosis*/
  and o.obs_group_id not in (Select obs_group_id from obs where concept_id=51 and voided is TRUE )
      and o.obs_group_id not in (Select obs_group_id from obs where concept_id=49 and value_coded =48 and voided is FALSE )
and e.visit_id in (/*Checking if the patient is admitted*/
                   SELECT
                     v.visit_id
                   FROM visit v
                     JOIN person_name pn ON v.patient_id = pn.person_id
                     JOIN encounter e ON e.visit_id = v.visit_id
                     JOIN encounter_type et ON e.encounter_type = et.encounter_type_id
                   WHERE
                     date(e.encounter_datetime) BETWEEN '#startDate#' and '#endDate#'
                     AND v.voided IS FALSE
                     AND et.name IN ('ADMISSION')
                     AND e.voided IS FALSE
)
and date(o.obs_datetime) BETWEEN '#startDate#' and '#endDate#'
and o.voided is FALSE

UNION All

/*No of INJ TT*/

Select
   8 AS 'SrNo',
  'No. Of Inj TT' AS 'Details',
  count(DISTINCT o.person_id,e.visit_id) 'Counts'/*Count distinct patient and visit to handle multiple admission in the date range*/
from obs o
  JOIN encounter e
    on o.encounter_id = e.encounter_id
  JOIN concept_name cn
  on cn.concept_id=o.concept_id
where
  cn.concept_name_type='FULLY_SPECIFIED'
  and cn.name='Consultation Note'
  and UPPER(o.value_text) LIKE '%INJ. TD%' OR UPPER(o.value_text) LIKE '%INJ TD%'
      and e.visit_id in (/*Checking if the patient is admitted*/
                          SELECT
                            v.visit_id
                          FROM visit v
                            JOIN person_name pn ON v.patient_id = pn.person_id
                            JOIN encounter e ON e.visit_id = v.visit_id
                            JOIN encounter_type et ON e.encounter_type = et.encounter_type_id
                          WHERE
                            date(e.encounter_datetime) BETWEEN '#startDate#' and '#endDate#'
                            AND v.voided IS FALSE
                            AND et.name IN ('ADMISSION')
                            AND e.voided IS FALSE
)
and date(o.obs_datetime) BETWEEN '#startDate#' and '#endDate#'
and o.voided is FALSE

UNION All

/*Total Patient Days*/
SELECT
   9 AS 'SrNo',
  'Patient Days'AS 'Details',
  sum(`Length of stay in days`) as 'Counts'
FROM (
  SELECT
    bedpatmap.patient_id,
    date_stopped,
    date_started,
    CASE WHEN date(bedpatmap.date_stopped) = date(bedpatmap.date_started)
      THEN 1
    ELSE
      sum(datediff(ifnull(bedpatmap.date_stopped, now()), bedpatmap.date_started)) END AS 'Length of stay in days'
  FROM
    bed_patient_assignment_map bedpatmap
  WHERE date(bedpatmap.date_started) BETWEEN '#startDate#' and '#endDate#'
  GROUP BY bedpatmap.patient_id, bedpatmap.date_started
)patienDays

UNION All

/*No of Surgeries*/
Select
   10 AS 'SrNo',
  'No. Of Surgeries' AS 'Details',
  count(obs_id) AS 'Counts'
FROM obs o
JOIN concept_name cn
on cn.concept_id = o.concept_id
where cn.concept_name_type='FULLY_SPECIFIED'
      and cn.name='SF, Date of surgery'
and o.voided is FALSE
and date(o.value_datetime) BETWEEN '#startDate#' and '#endDate#'

UNION All

/*No Of Abortions*/

Select
   11 AS 'SrNo',
  'No. Of Abortions' AS 'Details',
  count(DISTINCT o.person_id,e.visit_id) 'Counts'
from obs o
  JOIN encounter e
    on o.encounter_id = e.encounter_id
  join concept_name cn
    on cn.concept_id = o.value_coded
where
      cn.name = 'O00 Abortions'
      and cn.concept_name_type='FULLY_SPECIFIED'
  /*Ignoring the inactive diagnosis*/
      and o.obs_group_id not in (Select obs_group_id from obs where concept_id=51 and voided is TRUE )
      and o.obs_group_id not in (Select obs_group_id from obs where concept_id=49 and value_coded =48 and voided is FALSE )
      and e.visit_id in (
  /*Checking if the patient is admitted*/
  SELECT
    v.visit_id
  FROM visit v
    JOIN person_name pn ON v.patient_id = pn.person_id
    JOIN encounter e ON e.visit_id = v.visit_id
    JOIN encounter_type et ON e.encounter_type = et.encounter_type_id
  WHERE
    date(e.encounter_datetime) BETWEEN '#startDate#' and '#endDate#'
    AND v.voided IS FALSE
    AND et.name IN ('ADMISSION')
    AND e.voided IS FALSE
)
      and date(o.obs_datetime) BETWEEN '#startDate#' and '#endDate#'
      and o.voided is FALSE

UNION All

/*No Of Absconded patients*/
Select
   12 AS 'SrNo',
  'No. Of Patients Absconded' AS 'Details',
  count(obs_id) AS 'Counts'
FROM obs o
  JOIN concept_name cn
    on cn.concept_id = o.concept_id
where cn.concept_name_type='FULLY_SPECIFIED'
      and cn.name='Absconded date and time'
      and o.voided is FALSE
      and (date(o.value_datetime) BETWEEN '#startDate#' and '#endDate#'
                                OR
           date(o.obs_datetime) BETWEEN '#startDate#' and '#endDate#'
      )
ORDER BY SrNo;