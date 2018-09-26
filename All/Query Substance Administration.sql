use dbmVCDRData
-- use dbmVCDRDataHistory -- uncomment for querying the history CDR

declare @PatIdRoot varchar(100) 
declare @PatIdExt varchar(100)
declare @PatRecId bigint
declare @EncIdExt varchar(100)
declare @EncId bigint
declare @PatientName varchar(100)

/* 

	*** Execution Steps ***
	1. Set the values of the following parameters: 
		@PatientName - set one of the patient parts. The query will return results for the first patient that satisfy the name.
			OR
		@PatIdExt (The patient MRN)
			And optional
		@PatIdRoot (The patient MRN Root) - if not provided then query will return results for the first patient that satisfy the extension.
	2. Comment the rest of the patient parameters (by adding '-- ' before the "Set" instruction)
	3. Run the query - the query will return the selected patient details.
*/


--- *** Queries Parameters  *** ---
--Set @PatIdRoot='2.16.840.1.113883.3.57.1.3.11.11.1.8.2' 
Set @PatIdExt='S4946244H'
-- set @PatientName='One' 


-- Retreives the internal PatientRecordId for the requrested patient
Set @PatRecId=
(
SELECT top 1
	    pi.PatientRecordId
		  FROM PatientAdministration.PatientRecord pr 
			left join PatientAdministration.PatientName pn 
				on pr.PatientRecordId=pn.PatientRecordId 
			left join [PatientAdministration].[PatientNamePart] pnp
				on pnp.PatientNameId=pn.PatientNameId
			left join dbmVCDRData.vocabulary.CodeSystemConcept gcsc
				on pr.AdministrativeGenderCodeID=gcsc.cscid
			left join PatientAdministration.PatientIdentifier pi
				on pr.PatientRecordId=pi.PatientRecordId
			
		where (pi.isprimary=1 and pi.extension=COALESCE(@PatIdExt,extension)
				and pi.root=COALESCE(@PatIdRoot,pi.root) 
				and pnp.Value=COALESCE(@PatientName,pnp.value))
)


select 
	sa.dbmAvailabilityTime
	,sa.ControlActId,sa.PatientRecordId
	,sa.dbmClassCodeId,sa.SubstanceAdministrationId,sa.id_root as med_id_root,sa.id_extension as med_id_ext
	,CodeCSC.ConceptCode as SA_Code
	,MedCS.ConceptCode as medCode,mat.codeDisplayName as medDisplayName, MedD.DomainCode
	,sa.LotNumberText, sa.Material_ExpirationTime, mat.ManufactureName
	,sa.doseQuantity_value, sa.doseQuantity_conversion,DoseUnitCSC.ConceptCode as doseQuantity_unit, FormCSC.ConceptCode as Form
	,sa.DispenseQuantity_Conversion
	--,sa.dispenseQuantity_value, DispenseUnitCSC.ConceptCode as DispenseQuantity_unit
	,sa.activityTime,sa.effectivetime_start,sa.effectivetime_end
	-- ,msp.ActivityTime as suppliedTime
	--,msp.Quantity_Conversion as suppliedValue
	,StatusCSC.cscid,StatusCSC.ConceptCode as [Status]
	,FreqCSC.ConceptCode as Frequency
	,RouteCSC.ConceptCode as [Route]
	,ReasonCSC.ConceptCode as Reason, ReasonCD.designation as ReasonDes
	  ,msid.extension as PerformerMedicalStaffIdExt,ms.name as Author
	  ,ppmsid.extension as PerformerMedicalStaffIdExt,ppms.name as PerformerMedicalStaffName,ppTypeCD.designation as performerType
	  ,Org.Id_Extension as OrgIdExt,Org.Id_Root as OrgIdRoot, Org.Name as OrgName
	--,mating.name as ingName,matr.Quantity_value as ingQunatity,IngCS.ConceptCode as ingCode,mating.codeDisplayName as ingDisplayName
	,sa.text
	--,matr.materialroleid,mating.materialid
	,ARtar.TargetActClassId, ARtar.TargetActId
	,ARsrc.SourceActClassId, ARsrc.SourceActId

from 
	medication.substanceadministration sa
	left join vocabulary.codesystemconcept CodeCSC
		on sa.codeid=CodeCSC.cscid
	left join common.material mat
		on sa.materialid=mat.materialid
	left join vocabulary.codesystemconcept MedCS
		on mat.codeid=MedCS.cscid
	left join vocabulary.domainconcepts MedDC
		on mat.codeid=MedDC.cscid
	left join vocabulary.domain MedD
		on MedDC.domainid=MedD.domainid
	--left join common.materialrole matr
	--	on mat.materialid=matr.materialid_scoper
	--left join common.material mating
	--	on mating.materialid=matr.materialid_player
	--left join vocabulary.codesystemconcept IngCS
	--	on mating.codeid=IngCS.cscid
	left join vocabulary.codesystemconcept DoseUnitCSC
		on sa.DoseQuantity_UnitCodeID=DoseUnitCSC.cscid
	left join vocabulary.conceptdesignation DoseUnitCD
		on sa.DoseQuantity_UnitCodeID=DoseUnitCD.cscid
	left join vocabulary.codesystemconcept DispenseUnitCSC
		on sa.DispenseQuantity_UnitCodeID=DispenseUnitCSC.cscid
	left join vocabulary.conceptdesignation DispenseUnitCD
		on sa.DispenseQuantity_UnitCodeID=DispenseUnitCD.cscid	
	left join vocabulary.codesystemconcept FormCSC
		on mat.FormCodeID=FormCSC.cscid
	left join vocabulary.conceptdesignation FormCD
		on mat.FormCodeID=FormCD.cscid
	left join vocabulary.codesystemconcept StatusCSC
		on sa.StatusCodeID=StatusCSC.cscid
	left join vocabulary.conceptdesignation StatusCD
		on sa.StatusCodeID=StatusCD.cscid
	left join vocabulary.codesystemconcept FreqCSC
		on sa.EffectiveTime_FrequencyCodeID=FreqCSC.cscid
	left join vocabulary.conceptdesignation FreqCD
		on sa.EffectiveTime_FrequencyCodeID=FreqCD.cscid
	left join vocabulary.codesystemconcept ReasonCSC
		on sa.ReasonCodeID=ReasonCSC.cscid
	left join vocabulary.conceptdesignation ReasonCD
		on sa.ReasonCodeID=ReasonCD.cscid
	left join vocabulary.codesystemconcept RouteCSC
		on sa.RouteCodeID=RouteCSC.cscid
	left join vocabulary.conceptdesignation RouteCD
		on sa.RouteCodeID=RouteCD.cscid
	left join Common.Organization Org
		on sa.OrganizationID=Org.OrganizationID
	left join Common.MedicalStaff ms 
		on sa.MedicalStaffId=ms.MedicalStaffId
	left join common.MedicalStaffIdentifier msid
		on ms.MedicalStaffId=msid.MedicalStaffId and msid.isprimary=1
	left join Medication.ParticipantPerson pp
		on sa.SubstanceAdministrationId=pp.SubstanceAdministrationId
	left join Vocabulary.conceptdesignation ppTypeCD
		on pp.TypeCodeId=ppTypeCD.cscid
	left join Common.MedicalStaff ppms 
		on pp.MedicalStaffId=ppms.MedicalStaffId
	left join common.MedicalStaffIdentifier ppmsid
		on ms.MedicalStaffId=ppmsid.MedicalStaffId and ppmsid.isprimary=1
	left join common.actrelationship ARtar
		on ARtar.SourceActId=sa.SubstanceAdministrationId
			and ARtar.SourceId_Root=sa.id_root
			and ARtar.SourceId_Extension=sa.id_extension
			and ARtar.SourceActClassId=sa.dbmClassCodeId
	left join common.actrelationship ARsrc
		-- on ARsrc.TargetActId=sa.SubstanceAdministrationId
			on ARsrc.TargetId_Root=sa.id_root
			and ARsrc.TargetId_Extension=sa.id_extension
			and ARsrc.TargetActClassId=sa.dbmClassCodeId
	left join Medication.MedicationSupply msp
		on ARtar.TargetActId=msp.MedicationSupplyId
			and ARtar.TargetId_root=msp.id_root
			and ARtar.TargetId_extension=msp.id_extension
			and ARtar.SourceActClassId=sa.dbmClassCodeId
where sa.PatientRecordId=@PatRecId
order by controlactid desc