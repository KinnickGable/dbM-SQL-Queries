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
--Set @PatIdRoot='NODE_A1' 
Set @PatIdExt='00367801' 
Set @PatIdExt='87654321' 
Set @PatIdExt='246317450' 
Set @PatIdExt='Training_Patient2' 

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

select @PatRecId

Select 'ClinicalDocument table'
SELECT distinct
	  pid.Extension as [Patient MRN]
	  ,main.[ClinicalDocumentID]
      ,main.[Id_Root]
      ,main.[Id_Extension]
      ,CodeCSC.conceptcode as code ,CodeCD.designation as codeDes, CodeCS.CodeSystem, CodeDM.DomainCode,CodeAttDm.DomainCode AttributeDomain
	  ,main.Reference
      ,main.[EffectiveTime]
      ,StatusCSC.conceptcode as statusCode ,StatusCD.designation as statusDes
      ,CompCSC.conceptcode as CompletionCode ,CompCD.designation as CompletionDes
	  ,MediaCSC.conceptcode as mediaTypeCode
      ,main.[SetId_Root]
      ,main.[SetId_Extension]
      ,main.[dbmAvailabilityTime]
      ,main.[PatientRecordID]
	  ,msg.Id_extension as MessageId
  FROM ClinicalDocument.ClinicalDocument main
	inner join PatientAdministration.PatientIdentifier pid 
		on main.PatientRecordId=pid.PatientRecordId and pid.isprimary=1
	left join dbmVCDRData.vocabulary.CodeSystemConcept StatusCSC
		on main.StatusCodeID=StatusCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation StatusCD 
		on main.StatusCodeID=StatusCD.cscid
	left join dbmVCDRData.vocabulary.CodeSystemConcept CompCSC
		on main.CompletionCodeID=CompCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation CompCD 
		on main.CompletionCodeID=CompCD.cscid
	left join dbmVCDRData.vocabulary.CodeSystemConcept MediaCSC
		on main.MediaTypeID=MediaCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation MediaCD 
		on main.MediaTypeID=MediaCD.cscid
	left join dbmVCDRData.vocabulary.CodeSystemConcept CodeCSC 
		on main.[CodeID]=CodeCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation CodeCD 
		on main.[CodeID]=CodeCD.cscid
	left join dbmVCDRData.vocabulary.CodeSystem CodeCS 
		on CodeCSC.CodeSystemId=CodeCS.CodeSystemId
	left join dbmVCDRData.vocabulary.DomainConcepts CodeDC
		on main.CodeID=CodeDC.cscid
	left join dbmVCDRData.vocabulary.Domain CodeDM
		on CodeDC.DomainId=CodeDM.DomainId
	left join dbmVCDRData.vocabulary.Domain CodeAttDM
		on CodeDM.RootId=CodeAttDM.DomainId
	inner join dbmVCDRData.MessageWrapper.ControlAct ca
		on main.ControlActId=ca.ControlActId
	inner join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
Where main.PatientRecordId=@PatRecId

