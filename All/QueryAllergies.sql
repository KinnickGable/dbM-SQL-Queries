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
Set @PatIdExt='00367801' 
Set @PatIdExt='87654321' 
Set @PatIdExt='970020107' 
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

SELECT distinct
	  class.dbmClassCodeName
      ,main.[Id_Root]
      ,main.[Id_Extension]
      ,main.[EffectiveTime_Start]
      ,main.[EffectiveTime_End]
      ,cscstatus.conceptcode as statusCode
      ,csccode.conceptcode as code
      ,main.[CodeDisplayName] 
	  ,cscvalue.ConceptCode as value ,main.ValueDisplayName, valuedes.Designation,csvalue.CodeSystemName,main.ValueOriginalText, ValueDM.DomainCode
      ,main.[Text]
	  ,msid.extension as PerformerMedicalStaffIdExt,ms.name as PerformerMedicalStaffName
	  ,Org.Id_Extension as OrgIdExt, Org.Name as OrgName
	  ,msg.Id_extension as MessageId
	  ,rel_trg_class.dbmClassCodeName as RelatedTrgClass, ar.TargetId_Extension as RelatedTrgId
      ,main.[dbmAvailabilityTime]
  FROM Allergy.AllergyIntolerance main
	left join Common.luElementClass class on
		class.dbmClassCodeID=main.dbmClassCodeID
	left join Vocabulary.CodeSystemConcept cscstatus on
		main.StatusCodeID=cscstatus.cscid
	left join Vocabulary.CodeSystemConcept cscvalue on
		main.[ValueID]=cscvalue.cscid
	left join Vocabulary.ConceptDesignation valuedes on
		main.[ValueID]=valuedes.cscid
	left join Vocabulary.CodeSystem csvalue on
		cscvalue.CodeSystemId=csvalue.CodeSystemId
	left join dbmVCDRData.vocabulary.DomainConcepts ValueDC
		on main.ValueID=ValueDC.cscid
	left join dbmVCDRData.vocabulary.Domain ValueDM
		on ValueDC.DomainId=ValueDM.DomainId
	left join dbmVCDRData.vocabulary.Domain ValueAttDM
		on ValueDM.RootId=ValueAttDM.DomainId

	left join Vocabulary.CodeSystemConcept cscCode on
		main.[CodeID]=cscCode.cscid
	left join Common.Organization Org
		on main.OrganizationID=Org.OrganizationID
	left join Common.MedicalStaff ms 
		on main.MedicalStaffId=ms.MedicalStaffId
	left join common.MedicalStaffIdentifier msid
		on ms.MedicalStaffId=msid.MedicalStaffId and msid.isprimary=1
	left join Common.ActRelationship ar on
		ar.SourceId_Root=main.id_root and ar.SourceId_Extension=main.id_extension and ar.SourceActClassID=main.dbmClassCodeID
	left join Common.luElementClass rel_trg_class on
		rel_trg_class.dbmClassCodeID=ar.TargetActClassID
	inner join dbmVCDRData.MessageWrapper.ControlAct ca
		on main.ControlActId=ca.ControlActId
	inner join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
	left join dbmDILMessagesArchive.dbo.ArchMessage arc
		on msg.InterchangeId=arc.BTSInterchangeID

--	inner join
--		(SELECT msg.[MessageID]
--      ,msg.[Id_Root]
--      ,msg.[Id_Extension]
--      ,msg.[CreationTime]
--      ,msg.[TypeId_Extension]
--      ,msg.[InteractionId_Extension]
--      ,msg.[InterchangeID]
--      ,msg.[EndTime]
--	  ,ControlActId
--  FROM [MessageWrapper].[Message] as msg inner join
--	[MessageWrapper].ControlAct ca on
--		msg.messageid=ca.messageid
--where msg.[Id_Extension]=@MessageId) msg on
--	main.ControlActId=msg.ControlActId
where main.PatientRecordId=@PatRecId