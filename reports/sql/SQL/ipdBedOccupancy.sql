Select (sum(TotalLengthOfStay.Lengthofstayindays) / (case when '#endDate#'='#startDate#' then 1 else datediff('#endDate#','#startDate#') END  * (Select count(1) from bed))) * 100 as 'Bed Occupancy Rate'
from (
            select case when date(bedpatmap.date_stopped)=date(bedpatmap.date_started) then 1 else
                sum(datediff(ifnull(bedpatmap.date_stopped,now()),bedpatmap.date_started)) end as 'Lengthofstayindays'
            from
              bed_patient_assignment_map bedpatmap
              inner join person_name pname
                on bedpatmap.patient_id = pname.person_id
              inner join person
                on pname.person_id = person.person_id
              inner join patient_identifier
                on pname.person_id = patient_identifier.patient_id
              left Join
              (
                Select person_attribute.person_id,cn.name
                from person_attribute
                  inner join person_attribute_type
                    on person_attribute_type.person_attribute_type_id=person_attribute.person_attribute_type_id
                       and person_attribute.person_attribute_type_id=(select person_attribute_type_id from person_attribute_type where name='NonResidentialBhutaneseType')
                  inner join concept_name cn
                    on cn.concept_id=person_attribute.value
              ) as NBStatus
                on NBStatus.person_id=person.person_id
              left join person_address
                on person.person_id = person_address.person_id
            where date(bedpatmap.date_started) BETWEEN '#startDate#' and '#endDate#'
            group by person.person_id,bedpatmap.date_started
) as TotalLengthOfStay;