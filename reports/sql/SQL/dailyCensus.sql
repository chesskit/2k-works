Select
  PreviousAdmittedPatients.PreviousDayAdmissionCount AS 'Previous Patient',
  TodayAdmissionCount.TodayAdmissionCount AS 'Admission',
  TodayReferInCount.TodayReferInCount AS 'Refer In',
  TodayDischargeCount.TodayDischargeCount AS 'Discharge',
  TodayReferOutCount.TodayReferOutCount AS 'Refer Out',
  TodayDeadCount.TodayDeadCount AS 'Death',
  (
  (PreviousAdmittedPatients.PreviousDayAdmissionCount+TodayAdmissionCount.TodayAdmissionCount)
  -(TodayDischargeCount.TodayDischargeCount)
  ) 'Total Patient'
from
  (
    /*Previous patients: Patient count - All the patients who are admitted till previous day of start date.*/
   Select 'IPD' as IPD,count(vOut.patient_id) as 'PreviousDayAdmissionCount'
    from visit vOut
      join encounter eOut on  eOut.visit_id=vOut.visit_id
      JOIN encounter_type et on eOut.encounter_type=et.encounter_type_id
    where
      cast(eOut.encounter_datetime  AS DATE) < '#startDate#'
      and vOut.voided is FALSE
      and et.name in ('ADMISSION')
      and eOut.voided is FALSE
      and vOut.patient_id not in(/*Ignoring the patients who were dischanged*/
        SELECT v.patient_id
        from visit v
          join encounter e on  e.visit_id=v.visit_id
          JOIN encounter_type et on e.encounter_type=et.encounter_type_id
        where
          cast(e.encounter_datetime  AS DATE) < '#startDate#'
          and v.voided is FALSE
          and et.name in ('DISCHARGE')
          and e.voided is FALSE
          and v.patient_id=vOut.patient_id
          and e.encounter_datetime > eOut.encounter_datetime
      )
  ) as PreviousAdmittedPatients

LEFT JOIN

  (
    /*Admission: The count of the admitted patients during that day.*/
    SELECT
      'IPD'               AS IPD,
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
                                ) AS 'TodayAdmissionCount'
    FROM visit v
      JOIN person_name pn ON v.patient_id = pn.person_id
      JOIN encounter e ON e.visit_id = v.visit_id
      JOIN encounter_type et ON e.encounter_type = et.encounter_type_id
    WHERE
      cast(e.encounter_datetime AS DATE) BETWEEN '#startDate#' and '#endDate#'
      AND v.voided IS FALSE
      AND et.name IN ('ADMISSION')
      AND e.voided IS FALSE
  ) as TodayAdmissionCount
  on PreviousAdmittedPatients.IPD=TodayAdmissionCount.IPD

LEFT JOIN

  (
    /*Refer In: Total number of refer in patients on that day.*/
    SELECT
      'IPD'               AS IPD,
      count(DISTINCT o.obs_id) AS 'TodayReferInCount'
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
  ) as TodayReferInCount
  on PreviousAdmittedPatients.IPD=TodayReferInCount.IPD

LEFT JOIN

  (
    /*Discharge: Total number of discharge patients on that day.*/
    SELECT
      'IPD'               AS IPD,
      count(v.patient_id) AS 'TodayDischargeCount'
    FROM visit v
      JOIN person_name pn ON v.patient_id = pn.person_id
      JOIN encounter e ON e.visit_id = v.visit_id
      JOIN encounter_type et ON e.encounter_type = et.encounter_type_id
    WHERE
      cast(e.encounter_datetime AS DATE) BETWEEN '#startDate#' and '#endDate#'
      AND v.voided IS FALSE
      AND et.name IN ('DISCHARGE')
      AND (e.voided = FALSE OR e.void_reason = 'Undo Discharge')
  ) as TodayDischargeCount
  on PreviousAdmittedPatients.IPD=TodayDischargeCount.IPD

LEFT JOIN

  (
    /*Refer out: Total number of refer out patients on that day.*/
    SELECT
      'IPD'                        AS IPD,
      count(DISTINCT o.obs_id) AS 'TodayReferOutCount'
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
  ) as TodayReferOutCount
  on PreviousAdmittedPatients.IPD=TodayReferOutCount.IPD

LEFT JOIN

  (
    /*Dead: Total number of dead patients on that day.*/
    SELECT
      'IPD' AS                     IPD,
      count(DISTINCT v.patient_id) 'TodayDeadCount'
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
  ) AS TodayDeadCount
  on PreviousAdmittedPatients.IPD=TodayDeadCount.IPD;