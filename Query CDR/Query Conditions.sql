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
set @PatIdRoot='Node_A1' 
Set @PatIdExt='S4546590F' 
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
	main.ControlActId,main.PatientRecordId
	,main.ConditionId,main.id_root as cond_id_root,main.id_extension as cond_id_ext
	,CodeCSC.ConceptCode as Cond_Code
	,ValueCS.ConceptCode as valueCode,main.valueDisplayName as valueDisplayName, valueD.DomainCode, valueOriginalText
	,main.effectivetime_start,main.effectivetime_end
	,StatusCSC.ConceptCode as [Status]
	  ,msid.extension as PerformerMedicalStaffIdExt,ms.name as PerformerMedicalStaffName
	  ,Org.Id_Extension as OrgIdExt, Org.Name as OrgName
	--,mating.name as ingName,matr.Quantity_value as ingQunatity,IngCS.ConceptCode as ingCode,mating.codeDisplayName as ingDisplayName
	,main.text
	--,matr.materialroleid,mating.materialid
	,ARtar.TargetActClassId, ARtar.TargetActId
	,ARsrc.SourceActClassId, ARsrc.SourceActId

from 
	Condition.Condition main
	left join vocabulary.codesystemconcept CodeCSC
		on main.codeid=CodeCSC.cscid
	left join vocabulary.codesystemconcept ValueCS
		on main.valueid=ValueCS.cscid
	left join vocabulary.domainconcepts ValueDC
		on main.valueid=ValueDC.cscid
	left join vocabulary.domain ValueD
		on ValueDC.domainid=ValueD.domainid
	left join vocabulary.codesystemconcept StatusCSC
		on main.StatusCodeID=StatusCSC.cscid
	left join vocabulary.conceptdesignation StatusCD
		on main.StatusCodeID=StatusCD.cscid
	left join Common.Organization Org
		on main.OrganizationID=Org.OrganizationID
	left join Common.MedicalStaff ms 
		on main.MedicalStaffId=ms.MedicalStaffId
	left join common.MedicalStaffIdentifier msid
		on ms.MedicalStaffId=msid.MedicalStaffId and msid.isprimary=1
	left join common.actrelationship ARtar
		on ARtar.SourceActId=main.ConditionId
			and ARtar.SourceId_Root=main.id_root
			and ARtar.SourceId_Extension=main.id_extension
	left join common.actrelationship ARsrc
		on ARsrc.TargetActId=main.ConditionId
			and ARsrc.TargetId_Root=main.id_root
			and ARsrc.TargetId_Extension=main.id_extension
where main.PatientRecordId=@PatRecId
order by controlactid desc