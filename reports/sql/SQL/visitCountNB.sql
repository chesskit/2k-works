Select VisitType as 'Visit Type',/*Getting the sum of mulitple rows of same visit type*/
sum(NB1) as NB1,
sum(NB2) as NB2,
sum(NB3) as NB3
from (/*Pivoting the table row to column*/
		select
			NbVisitCount.VisitType,
			case when NonBhutaneseCode = "NB1" then NoOfVisits end as NB1,
			case when NonBhutaneseCode = "NB2" then NoOfVisits end as NB2,
			case when NonBhutaneseCode = "NB3" then NoOfVisits end as NB3
			from (/*Getting the count on visit type and NonResidentialBhutaneseType*/
					Select vt.name VisitType,cn.name NonBhutaneseCode,Count(1) NoOfVisits from visit v
					join visit_type vt on vt.visit_type_id=v.visit_type_id
					join person_attribute pa on pa.person_id=v.patient_id
					join person_attribute_type pat on pat.person_attribute_type_id=pa.person_attribute_type_id
					join concept_name cn on cn.concept_id=pa.value
					where pat.name='NonResidentialBhutaneseType'
					and cn.concept_name_type='FULLY_SPECIFIED'
                    and cast(v.date_started AS DATE) BETWEEN '#startDate#' and '#endDate#'
                    and v.voided is false
					group by vt.name,cn.name
				 ) as NbVisitCount
) as NbVisitCount1 Group by VisitType;