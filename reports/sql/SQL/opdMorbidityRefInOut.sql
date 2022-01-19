SELECT
  cv.concept_full_name Diagnosis,
  count(distinct refIn.person_id) 'Refer In',
  count(distinct refOut.person_id) 'Refer Out'
FROM obs AS diagnosis
  JOIN concept_view AS cv
    ON cv.concept_id = diagnosis.value_coded AND cv.concept_class_name = 'Diagnosis' AND
       diagnosis.voided IS FALSE
       AND diagnosis.obs_group_id IN (
    SELECT confirmed.obs_id
    FROM (
           SELECT parent.obs_id
           FROM obs AS parent
             JOIN concept_view pcv ON pcv.concept_id = parent.concept_id AND
                                      pcv.concept_full_name = 'Visit Diagnoses'
             LEFT JOIN obs AS child
               ON child.obs_group_id = parent.obs_id
                  AND child.voided IS FALSE
             JOIN concept_name AS confirmed
               ON confirmed.concept_id = child.value_coded AND confirmed.name = 'Confirmed' AND
                  confirmed.concept_name_type = 'FULLY_SPECIFIED'
           WHERE parent.voided IS FALSE ) AS confirmed
    WHERE confirmed.obs_id NOT IN (SELECT parent.obs_id
                                   FROM obs AS parent
                                     JOIN concept_view pcv2 ON pcv2.concept_id = parent.concept_id AND pcv2.concept_full_name = 'Visit Diagnoses'
                                     JOIN (
                                            SELECT obs_group_id
                                            FROM obs AS status
                                              JOIN concept_name ON concept_name.concept_id = status.value_coded AND
                                                                   concept_name.name = 'Ruled Out Diagnosis' AND
                                                                   concept_name.concept_name_type = 'FULLY_SPECIFIED' AND
                                                                   status.voided IS FALSE
                                            UNION
                                            SELECT obs_group_id
                                            FROM obs AS revised
                                              JOIN concept_name revised_concept
                                                ON revised_concept.concept_id = revised.concept_id AND
                                                   revised_concept.name = 'Bahmni Diagnosis Revised' AND
                                                   revised_concept.concept_name_type = 'FULLY_SPECIFIED' AND
                                                   revised.value_coded = (SELECT property_value FROM global_property WHERE property = 'concept.true') AND
                                                   revised.voided IS FALSE
                                          ) revised_and_ruled_out_diagnosis
                                       ON revised_and_ruled_out_diagnosis.obs_group_id = parent.obs_id
                                   WHERE parent.voided IS FALSE))

  JOIN encounter e
    ON diagnosis.encounter_id = e.encounter_id
  JOIN visit v
    ON e.visit_id = v.visit_id
  JOIN visit_type vt
    ON vt.visit_type_id = v.visit_type_id
       and vt.name='OPD'
  JOIN person p
    ON v.patient_id = p.person_id
  Left Join
  (
    Select refInO.person_id from obs refInO
    join encounter refInE on refInE.encounter_id=refInO.encounter_id
    join visit refInV on refInV.visit_id=refInE.visit_id
    JOIN visit_type refInVT ON refInVT.visit_type_id = refInV.visit_type_id
    where cast(refInO.obs_datetime AS DATE) BETWEEN '#startDate#' and '#endDate#'
        AND refInO.voided IS FALSE
        and refInVT.name='OPD'
        and  refInO.concept_id=(select concept_id from concept_name where name ='Refer In Details' and concept_name_type='FULLY_SPECIFIED')
  ) as refIn
  on refIn.person_id=diagnosis.person_id

  Left Join
  (
      Select refOutO.person_id from obs refOutO
      join encounter refOutE on refOutE.encounter_id=refOutO.encounter_id
      join visit refOutV on refOutV.visit_id=refOutE.visit_id
      JOIN visit_type refOutVT ON refOutVT.visit_type_id = refOutV.visit_type_id
      where cast(refOutO.obs_datetime AS DATE) BETWEEN '#startDate#' and '#endDate#'
          AND refOutO.voided IS FALSE
          and refOutVT.name='OPD'
          and  refOutO.concept_id=(select concept_id from concept_name where name ='Referral Form' and concept_name_type='FULLY_SPECIFIED')
    ) as refOut
    on refOut.person_id=diagnosis.person_id
where  cast(diagnosis.obs_datetime AS DATE) BETWEEN '#startDate#' and '#endDate#' AND diagnosis.voided IS FALSE
group by cv.concept_full_name;