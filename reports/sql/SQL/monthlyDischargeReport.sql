Select
DischargedBefore11AM.DischargeCountBefore11AM as 'No. of patients discharged before 11 AM',
DischargedAfter11AM.DischargeCountAfter11AM as 'No. of patients discharged after 11 AM'
FROM
  (/*No. of patients discharged after 11 AM*/
    SELECT
      'IPD'               AS IPD,
      count(v.patient_id) AS 'DischargeCountAfter11AM'
    FROM visit v
      JOIN person_name pn ON v.patient_id = pn.person_id
      JOIN encounter e ON e.visit_id = v.visit_id
      JOIN encounter_type et ON e.encounter_type = et.encounter_type_id
    WHERE
      cast(e.encounter_datetime AS DATE) BETWEEN '#startDate#' and '#endDate#'
      AND time(e.encounter_datetime) > '11:00:00'
      AND v.voided IS FALSE
      AND et.name IN ('DISCHARGE')
      AND (e.voided = FALSE OR e.void_reason = 'Undo Discharge')
  ) DischargedAfter11AM

LEFT JOIN

  (/*No. of patients discharged before 11 AM*/
    SELECT
      'IPD'               AS IPD,
      count(v.patient_id) AS 'DischargeCountBefore11AM'
    FROM visit v
      JOIN person_name pn ON v.patient_id = pn.person_id
      JOIN encounter e ON e.visit_id = v.visit_id
      JOIN encounter_type et ON e.encounter_type = et.encounter_type_id
    WHERE
      cast(e.encounter_datetime AS DATE) BETWEEN '#startDate#' and '#endDate#'
      AND time(e.encounter_datetime) < '11:00:00'
      AND v.voided IS FALSE
      AND et.name IN ('DISCHARGE')
      AND (e.voided = FALSE OR e.void_reason = 'Undo Discharge')
  ) DischargedBefore11AM
  on DischargedAfter11AM.IPD=DischargedBefore11AM.IPD;