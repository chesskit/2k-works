select distinct
          e.date_created       as  "Date(DD:MM:YYYY)",
      CONCAT('MAX(IF(person_attribute_type.name = \'', CHILD UNIQUE NUMBER (CWC), '\', IFNULL(concept_name.name, person_attribute.value), NULL)) as \'', name, '\''))

          concat(pn.given_name," ", pn.middle_name," ",ifnull(pn.family_name,'')) as "Full Names", 
          DATE_FORMAT(v.date_started, "%W-%d-%b-%Y %r") AS 'Visit Date',
          DATE_FORMAT(en.encounter_datetime, "%d-%b-%Y")  AS 'Registration Ddate',  
          p.gender              AS Sex,
          pi.identifier       AS "Patient ID",
          person_attribute_type.name
          concat("",p.uuid) as uuid,
          concat("",v.uuid) as activeVisitUuid,
   
