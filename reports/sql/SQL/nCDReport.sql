Select 
ifnull(TotalDiaPat,0) as 'Total number of patients suffering from Diabetes',
ifnull(TotalHTNPat,0) as 'Total number of patients suffering from Hypertension',
ifnull(TotalNewCaseDiaPat,0) as 'Total number of new cases in Diabetes',
ifnull(TotalewCaseHTNPat,0) as 'Total number of new cases in Hypertension',
ifnull(DiaFollowUpMale,0) as 'Total number of Diabetes follow up Male',
ifnull(DiaFollowUpFemale,0) as 'Total number of Diabetes follow up Female',
ifnull(HTNFollowUpMale,0) as 'Total number of Hypertension follow up Male',
ifnull(HTNFollowUpFemale,0) as 'Total number of Hypertension follow up Female',
ifnull(TotalFollowUpForHtnDia,0) as 'Total number of Diabetes and Hypertension follow up patients',
ifnull(TotalNoOfPatVisitedNcd,0) as 'Total number of DM and HTN consultations in NCD department'
from
(          /*Total number of DM and HTN consultations in NCD department*/
	select 
	'NCD' as 'Department',
	ifnull(totalDiabPatients.TotalnumberofDiabetesPatientsinNCD,0)+ifnull(totalHyperPatients.TotalnumberofHypertensionPatientsinNCD,0) as 'TotalNoOfPatVisitedNcd'
	from 
	(
	select 'NCD' as 'Program',
							count(1)+(
										select
										Count(1) as 'TotalnumberofnewDiabetespatients'
										from patient_program pp
										join program prog on prog.program_id = pp.program_id 
										where (date(pp.date_enrolled) BETWEEN date('#startDate#') AND date('#endDate#'))
											AND pp.voided = 0 
											AND prog.name in ('Diabetes')
									 ) as'TotalnumberofDiabetesPatientsinNCD'
							from program
								join patient_program ON patient_program.program_id = program.program_id
								join episode_patient_program ON episode_patient_program.patient_program_id = patient_program.patient_program_id
								join episode_encounter ON episode_encounter.episode_id = episode_patient_program.episode_id
								join obs ON obs.encounter_id = episode_encounter.encounter_id
								join concept_name ON concept_name.concept_id = obs.concept_id 
								join person ON person.person_id = obs.person_id
								where concept_name.name = 'Diabetes follow up form' 
								AND concept_name.concept_name_type='FULLY_SPECIFIED'
								AND date(obs.obs_datetime) BETWEEN date('#startDate#') AND date('#endDate#')
								AND patient_program.voided = 0 
								AND person.gender IN ('M','F')
	)
	AS totalDiabPatients
	JOIN
	(
	select 'NCD' as 'Program',
							count(1)+(
										select
										Count(1) as 'TotalnumberofnewHypertensionpatients'
										from patient_program pp
										join program prog on prog.program_id = pp.program_id 
										where (date(pp.date_enrolled) BETWEEN date('#startDate#') AND date('#endDate#'))
											AND pp.voided = 0 
											AND prog.name in ('Hypertension')
									 ) as'TotalnumberofHypertensionPatientsinNCD'
							from program
								join patient_program ON patient_program.program_id = program.program_id
								join episode_patient_program ON episode_patient_program.patient_program_id = patient_program.patient_program_id
								join episode_encounter ON episode_encounter.episode_id = episode_patient_program.episode_id
								join obs ON obs.encounter_id = episode_encounter.encounter_id
								join concept_name ON concept_name.concept_id = obs.concept_id 
								join person ON person.person_id = obs.person_id
								where concept_name.name = 'Hypertension Form' 
								AND concept_name.concept_name_type='FULLY_SPECIFIED'
								AND date(obs.obs_datetime) BETWEEN date('#startDate#') AND date('#endDate#')
								AND patient_program.voided = 0 
								AND person.gender IN ('M','F')
							
	)

	AS totalHyperPatients on totalHyperPatients.Program=totalDiabPatients.Program
) as TotalNoOfPatVisitedNcd

left join 

(							/*Total number of patients suffering from Diabetes and Hypertension*/
	Select 'NCD' as 'Department',sum(ifnull(HypertensionTotalnoofpatient,0)) as'TotalHTNPat',
	sum(ifnull(DiabetesTotalnoofpatient,0)) as 'TotalDiaPat' from
	(
		Select 'A' as 'Program',case when Programname = 'Diabetes' then Totalnoofpatients end as 'DiabetesTotalnoofpatient',
		case when Programname = 'Hypertension' then Totalnoofpatients end as 'HypertensionTotalnoofpatient' from 
		(
				select 
				prog.name as 'Programname',
				Count(1) as 'Totalnoofpatients'
				from patient_program pp
				join program prog on pp.program_id = prog.program_id
				where ((date(pp.date_completed) BETWEEN date('#startDate#') AND date('#endDate#'))
					OR ((pp.date_completed IS NULL ))) 
					AND date(pp.date_enrolled) <= date('#endDate#')
					AND pp.voided = 0 
					AND prog.name in ('Diabetes','Hypertension')
					group by prog.name
		) as InnerTotalTable
	) as OuterTotalTable group by Program
) as TotalNoOfPatDiaHtn
on TotalNoOfPatVisitedNcd.Department=TotalNoOfPatDiaHtn.Department

left Join

(                          /*Total number of new cases in Diabetes and Hypertension*/
	Select 'NCD' as 'Department',sum(ifnull(HypertensionTotalNewpatient,0)) as'TotalewCaseHTNPat',
	sum(ifnull(DiabetesTotalNewpatient,0)) as 'TotalNewCaseDiaPat' from
	(
		Select 'A' as 'Program',case when Programname = 'Diabetes' then Totalnumberofnewpat end as 'DiabetesTotalNewpatient',
		case when Programname = 'Hypertension' then Totalnumberofnewpat end as 'HypertensionTotalNewpatient' from 
		(
			select
			prog.name as 'Programname',
			Count(1) as 'Totalnumberofnewpat'
			from patient_program pp
			join program prog on prog.program_id = pp.program_id 
			where (date(pp.date_enrolled) BETWEEN date('#startDate#') AND date('#endDate#'))
				AND pp.voided = 0 
				AND prog.name in ('Diabetes','Hypertension')
			group by prog.name
		) as InnerTotalTable
	) as OuterTotalTable group by Program
) as TotalNewCaseDiaHtn
on TotalNoOfPatVisitedNcd.Department=TotalNewCaseDiaHtn.Department

left Join

(                             /*Total number of Hypertension followup patients*/
	Select 'NCD' as 'Department',
	Sum(male) as 'HTNFollowUpMale',
	Sum(female) as 'HTNFollowUpFemale' from 
	(
							select 'Hypertension' as 'Program',
							case when person.gender='M' then count(1)  end as 'Male',
							case when person.gender='F' then count(1)  end as 'Female'
							from program
								join patient_program ON patient_program.program_id = program.program_id
								join episode_patient_program ON episode_patient_program.patient_program_id = patient_program.patient_program_id
								join episode_encounter ON episode_encounter.episode_id = episode_patient_program.episode_id
								join obs ON obs.encounter_id = episode_encounter.encounter_id
								join concept_name ON concept_name.concept_id = obs.concept_id 
								join person ON person.person_id = obs.person_id
							where concept_name.name = 'Hypertension Form' 
								AND concept_name.concept_name_type='FULLY_SPECIFIED'
								AND date(obs.obs_datetime) BETWEEN date('#startDate#') AND date('#endDate#')
								AND patient_program.voided = 0 
								AND person.gender IN ('M','F')
							group by person.gender
	)as HypertensionFollowUpCountGenderWise
	group by HypertensionFollowUpCountGenderWise.Program
) as HypertensionFollowUpCountGenderWise
on TotalNoOfPatVisitedNcd.Department=HypertensionFollowUpCountGenderWise.Department

left Join

(                                  /*Total number of Diabetes followup patients*/
	Select 'NCD' as 'Department',
	Sum(male) as 'DiaFollowUpMale',
	Sum(female) as 'DiaFollowUpFemale' from 
	(
							select 'Diabetes' as 'Program',
							case when person.gender='M' then count(1)  end as 'Male',
							case when person.gender='F' then count(1)  end as 'Female'
							from program
								join patient_program ON patient_program.program_id = program.program_id
								join episode_patient_program ON episode_patient_program.patient_program_id = patient_program.patient_program_id
								join episode_encounter ON episode_encounter.episode_id = episode_patient_program.episode_id
								join obs ON obs.encounter_id = episode_encounter.encounter_id
								join concept_name ON concept_name.concept_id = obs.concept_id 
								join person ON person.person_id = obs.person_id
							where concept_name.name = 'Diabetes follow up form'
								AND concept_name.concept_name_type='FULLY_SPECIFIED'
								AND date(obs.obs_datetime) BETWEEN date('#startDate#') AND date('#endDate#')
								AND patient_program.voided = 0 
								AND person.gender IN ('M','F')
							group by person.gender
	)as DiabetesFollowUpCountGenderWise
	group by DiabetesFollowUpCountGenderWise.Program
) as DiabetesFollowUpCountGenderWise
on TotalNoOfPatVisitedNcd.Department=DiabetesFollowUpCountGenderWise.Department

left Join

(    /*Total no. of  Hypertension and Diabetes followup patients*/
    Select 'NCD' as 'Department',
       count(1) as 'TotalFollowUpForHtnDia'
from program
  join patient_program ON patient_program.program_id = program.program_id
  join episode_patient_program ON episode_patient_program.patient_program_id = patient_program.patient_program_id
  join episode_encounter ON episode_encounter.episode_id = episode_patient_program.episode_id
  join obs ON obs.encounter_id = episode_encounter.encounter_id
  join concept_name ON concept_name.concept_id = obs.concept_id
  join person ON person.person_id = obs.person_id
where concept_name.name = 'Hypertension Form'
      AND concept_name.concept_name_type='FULLY_SPECIFIED'
      AND date(obs.obs_datetime) BETWEEN date('#startDate#') AND date('#endDate#')
      AND patient_program.voided = 0
      AND person.gender IN ('M','F')
      AND person.person_id IN (
                                select patient_id
                                from program
                                  join patient_program ON patient_program.program_id = program.program_id
                                  join episode_patient_program ON episode_patient_program.patient_program_id = patient_program.patient_program_id
                                  join episode_encounter ON episode_encounter.episode_id = episode_patient_program.episode_id
                                  join obs ON obs.encounter_id = episode_encounter.encounter_id
                                  join concept_name ON concept_name.concept_id = obs.concept_id
                                  join person ON person.person_id = obs.person_id
                                where concept_name.name = 'Diabetes follow up form'
                                      AND concept_name.concept_name_type='FULLY_SPECIFIED'
                                      AND date(obs.obs_datetime) BETWEEN date('#startDate#') AND date('#endDate#')
                                      AND patient_program.voided = 0
                                      AND person.gender IN ('M','F')
                              )
) as TotalFollowUpForHtnDia
on TotalNoOfPatVisitedNcd.Department=TotalFollowUpForHtnDia.Department;