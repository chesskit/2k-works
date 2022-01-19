Select Visit,
  TotalPatient AS 'Count of patient'
FROM
  (/*Getting the no of visit for all the visit type*/
    Select CASE WHEN vt.name = 'OPD' THEN 0
           WHEN vt.name = 'Dental' THEN 1
           WHEN vt.name = 'NCD' THEN 2
           WHEN vt.name = 'Eye' THEN 3
           WHEN vt.name = 'ENT' THEN 4
           WHEN vt.name = 'Lab' THEN 5
           WHEN vt.name = 'Emergency' THEN 6
           WHEN vt.name = 'IPD' THEN 9
      ELSE 7
           END AS VisitDisplayOrder,
      CASE WHEN vt.name ='OPD' THEN 'General OPD' ELSE vt.name END AS Visit,
      COUNT(v.patient_id) 'TotalPatient'
    from visit v
    JOIN visit_type vt
      on v.visit_type_id=vt.visit_type_id
    where
      v.voided is FALSE
      and DATE (v.date_started)  BETWEEN '#startDate#' and '#endDate#'
    GROUP BY vt.name

    UNION ALL

/*Getting total of all the visit type except IPD*/
    Select 8 AS VisitDisplayOrder,
      'Total OPD'AS Visit,
      COUNT(v.patient_id) 'TotalPatient'
    from visit v
      JOIN visit_type vt
        on v.visit_type_id=vt.visit_type_id
    where
      v.voided is FALSE
      and vt.name<>'IPD'
      and DATE (v.date_started)  BETWEEN '#startDate#' and '#endDate#'
    ORDER BY VisitDisplayOrder
) VisitCount;