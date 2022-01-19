
SELECT 


DATE_FORMAT(e.encounter_datetime, '%d/%m/%Y') as 'Date(DD:MM:YYYY)',


 GROUP_CONCAT(DISTINCT(IF(pat.name = 'CHILD UNIQUE NUMBER (CWC)', pa.value, NULL))) AS 'CHILD UNIQUE NUMBER (CWC)',
GROUP_CONCAT(DISTINCT (IF(obs_fscn.name = 'Type Of Visit,1 = New Visit, 2 = Re-Visit' AND latest_encounter.person_id IS NOT NULL, COALESCE(coded_fscn.name, coded_scn.name), NULL)) ORDER BY o.obs_id ASC) AS 'Type Of Visit,1=New Visit, 2=Re-Visit',
GROUP_CONCAT(DISTINCT(IF(pat.name = 'BIRTH NOTIFICATION  (NUMBER)', pa.value, NULL))) AS 'BIRTH NOTIFICATION  (NUMBER)',

  concat(pn.given_name, " ",pn.middle_name, " ",pn.family_name) AS "Full Names(Three Names)",
TIMESTAMPDIFF(YEAR, p.birthdate, CURDATE()) AS `Age`,
  p.gender                    AS "Sex",
  paddress.address3 AS 'County/Sub County',
  paddress.address2 AS 'Village/Estate/Landmark',
  GROUP_CONCAT(DISTINCT(IF(pat.name = 'Phone Number', pa.value, NULL))) AS 'Telephone Number',
GROUP_CONCAT(DISTINCT (IF(obs_fscn.name = 'Weight in Kgs' AND latest_encounter.person_id IS NOT NULL, COALESCE(coded_fscn.name, o.value_numeric), NULL)) ORDER BY o.obs_id ASC) AS 'Weight in Kgs',
  GROUP_CONCAT(DISTINCT (IF(obs_fscn.name = 'Weight categories: (1=Normal, 2=UW 3= SUW 4=OW 5=Obese)' AND latest_encounter.person_id IS NOT NULL, COALESCE(coded_fscn.name, coded_scn.name), NULL)) ORDER BY o.obs_id ASC)                    AS 'Weight categories: (1=Normal, 2=UW 3= SUW 4=OW 5=Obese)',
GROUP_CONCAT(DISTINCT (IF(obs_fscn.name = 'Height / Length in cm' AND latest_encounter.person_id IS NOT NULL, COALESCE(coded_fscn.name, o.value_numeric), NULL)) ORDER BY o.obs_id ASC) AS 'Height / Length in cm',
  GROUP_CONCAT(DISTINCT (IF(obs_fscn.name = 'Height/length categories: (1= Normal 2=Stunted 3= Sev. Stunted)' AND latest_encounter.person_id IS NOT NULL, COALESCE(coded_fscn.name, coded_scn.name), NULL)) ORDER BY o.obs_id ASC) AS 'Height/length categories: (1= Normal 2=Stunted 3= Sev. Stunted)',
  GROUP_CONCAT(DISTINCT (IF(obs_fscn.name = 'MUAC (1=green 2= Yellow 3=Red)' AND latest_encounter.person_id IS NOT NULL, COALESCE(coded_fscn.name, coded_scn.name), NULL)) ORDER BY o.obs_id ASC) AS 'MUAC (1=green 2= Yellow 3=Red)',
GROUP_CONCAT(DISTINCT (IF(obs_fscn.name = 'Exclusive Breastfeeding (Less than 6 Months)' AND latest_encounter.person_id IS NOT NULL, COALESCE(coded_fscn.name, coded_scn.name), NULL)) ORDER BY o.obs_id ASC) AS 'Exclusive Breastfeeding (Less than 6 Months)',
GROUP_CONCAT(DISTINCT (IF(obs_fscn.name = 'Vit A Supplementation: (6-59 months): 1=6-11months, 2=12-59months. 3=Not Supplemented' AND latest_encounter.person_id IS NOT NULL, COALESCE(coded_fscn.name, coded_scn.name), NULL)) ORDER BY o.obs_id ASC) AS 'Vit A Supplementation: (6-59 months): 1=6-11months, 2=12-59months. 3=Not Supplemented',
GROUP_CONCAT(DISTINCT (IF(obs_fscn.name = 'Dewormed' AND latest_encounter.person_id IS NOT NULL, COALESCE(coded_fscn.name, coded_scn.name), NULL)) ORDER BY o.obs_id ASC) AS 'Dewormed',
GROUP_CONCAT(DISTINCT (IF(obs_fscn.name = 'MNPs Supplementation(6-23 children)' AND latest_encounter.person_id IS NOT NULL, COALESCE(coded_fscn.name, coded_scn.name), NULL)) ORDER BY o.obs_id ASC) AS 'MNPs Supplementation(6-23 children)'
FROM obs o 
  JOIN person p ON p.person_id = o.person_id AND p.voided is false
  JOIN patient_identifier pi ON p.person_id = pi.patient_id AND pi.voided is false
  JOIN patient_identifier_type pit ON pi.identifier_type = pit.patient_identifier_type_id AND pit.retired is false
  JOIN person_name pn ON pn.person_id = p.person_id AND pn.voided is false
  LEFT OUTER JOIN person_attribute pa ON p.person_id = pa.person_id AND pa.voided is false
  LEFT OUTER JOIN person_attribute_type pat ON pa.person_attribute_type_id = pat.person_attribute_type_id AND pat.retired is false
  LEFT OUTER JOIN concept_name scn ON pat.format = "org.openmrs.Concept" AND pa.value = scn.concept_id AND scn.concept_name_type = "SHORT" AND scn.voided is false
  LEFT OUTER JOIN concept_name fscn ON pat.format = "org.openmrs.Concept" AND pa.value = fscn.concept_id AND fscn.concept_name_type = "FULLY_SPECIFIED" AND fscn.voided is false
  LEFT OUTER JOIN person_address paddress ON p.person_id = paddress.person_id AND paddress.voided is false
  JOIN encounter e ON o.encounter_id = e.encounter_id AND o.voided IS FALSE AND e.voided IS FALSE
  JOIN concept c ON o.concept_id = c.concept_id AND c.retired IS FALSE
  JOIN concept_name obs_fscn
    ON c.concept_id = obs_fscn.concept_id AND
       obs_fscn.name IN ('Type Of Visit,1 = New Visit, 2 = Re-Visit','Weight in Kgs','Height / Length in cm','Weight categories: (1=Normal, 2=UW 3= SUW 4=OW 5=Obese)','Height/length categories: (1= Normal 2=Stunted 3= Sev. Stunted)','MUAC (1=green 2= Yellow 3=Red)','Exclusive Breastfeeding (Less than 6 Months)','Vit A Supplementation: (6-59 months): 1=6-11months, 2=12-59months. 3=Not Supplemented','Dewormed','MNPs Supplementation(6-23 children)'      
       ) AND
       obs_fscn.voided IS FALSE
  JOIN concept_name obs_scn ON o.concept_id = obs_scn.concept_id AND obs_scn.concept_name_type = "SHORT" AND obs_scn.voided IS FALSE
  LEFT JOIN concept_name coded_fscn on coded_fscn.concept_id = o.value_coded AND coded_fscn.concept_name_type="FULLY_SPECIFIED" AND coded_fscn.voided is false
  LEFT JOIN concept_name coded_scn on coded_scn.concept_id = o.value_coded AND coded_fscn.concept_name_type="SHORT" AND coded_scn.voided is false
  JOIN (SELECT
          person_id,
          obs.concept_id,
          max(encounter_datetime) AS max_encounter_datetime
        FROM obs
          JOIN encounter ON obs.encounter_id = encounter.encounter_id AND obs.voided = FALSE
                            AND encounter.visit_id IN (SELECT v.visit_id FROM
            visit v
            JOIN  (SELECT patient_id AS patient_id, max(date_started) AS date_started
                   FROM visit WHERE visit.voided IS FALSE GROUP BY patient_id) latest_visit
              ON v.date_started = latest_visit.date_started AND v.patient_id = latest_visit.patient_id AND v.voided IS FALSE )
        GROUP BY obs.person_id, obs.concept_id) latest_encounter
    ON o.person_id = latest_encounter.person_id AND o.concept_id = latest_encounter.concept_id AND
       e.encounter_datetime = latest_encounter.max_encounter_datetime
  LEFT JOIN (SELECT
               obs.person_id,
               encounter.encounter_id,
               c_name AS name,
               GROUP_CONCAT(DISTINCT (IF(c_name = 'FSTG, Specialty determined by MLO', COALESCE(coded_fscn.name, coded_scn.name), NULL))) AS 'Specialty',
               GROUP_CONCAT(DISTINCT (IF(c_name = 'MH, Name of MLO', COALESCE(coded_fscn.name, coded_scn.name), NULL))) AS 'MLO',
               GROUP_CONCAT(DISTINCT (IF(c_name = 'MH, Network Area', COALESCE(coded_fscn.name, coded_scn.name), NULL))) AS 'Network Area',
               GROUP_CONCAT(DISTINCT (IF(c_name = 'Weight in Kgs', obs.value_text, NULL))) AS 'Referred by'
             FROM (SELECT
                     cn.name                 AS c_name,
                     obs.person_id,
                     obs.encounter_id,
                     max(encounter_datetime) AS max_encounter_datetime,
                     obs.concept_id
                   FROM obs
                     JOIN encounter ON obs.encounter_id = encounter.encounter_id AND obs.voided IS FALSE AND encounter.voided IS FALSE
                     JOIN concept_name cn ON cn.name IN ('MH, Name of MLO', 'FSTG, Specialty determined by MLO', 'MH, Network Area', 'Weight in Kgs')
                                             AND cn.concept_id = obs.concept_id
                   GROUP BY person_id, concept_id) result
               JOIN encounter ON result.max_encounter_datetime = encounter.encounter_datetime AND encounter.voided IS FALSE
               JOIN obs ON encounter.encounter_id = obs.encounter_id AND obs.concept_id = result.concept_id AND obs.voided IS FALSE
               LEFT JOIN concept_name coded_fscn ON coded_fscn.concept_id = obs.value_coded
                                                    AND coded_fscn.concept_name_type = "FULLY_SPECIFIED"
                                                    AND coded_fscn.voided IS FALSE
               LEFT JOIN concept_name coded_scn ON coded_scn.concept_id = obs.value_coded
                                                   AND coded_fscn.concept_name_type = "SHORT"
                                                   AND coded_scn.voided IS FALSE
             GROUP BY obs.person_id
            ) obs_across_visits ON p.person_id = obs_across_visits.person_id


GROUP BY o.person_id;

