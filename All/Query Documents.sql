use dbmVCDRData
-- use dbmVCDRDataHistory -- uncomment for querying the history CDR

Declare @ClinicalDocumentID bigint
Declare @ClinicalDocIdExt varchar(100)

/* 

	*** Execution Steps ***
	1. Set the Value of the @ClinicalDocIdExt (Clinical Document Id Extension) parameter.
	2. Run the query - the query will return the selected clinical document details.

*/

--- *** Queries Parameters  *** ---
Set @ClinicalDocIdExt='3057261'

--- Get ClinicalDocumentID of the Clinical Document ---
Set @ClinicalDocumentID=(select top 1 cd.ClinicalDocumentId
			from ClinicalDocument.ClinicalDocument cd
			where cd.id_extension=@ClinicalDocIdExt)


Select 'ClinicalDocument table'
SELECT distinct
	  pid.Extension as [Patient MRN]
	  ,main.[ClinicalDocumentID]
      ,main.[Id_Root]
      ,main.[Id_Extension]
      ,CodeCSC.conceptcode as code ,CodeCD.designation as codeDes, CodeCS.CodeSystem, CodeDM.DomainCode
      ,main.[EffectiveTime]
      ,StatusCSC.conceptcode as statusCode ,StatusCD.designation as statusDes
      ,CompCSC.conceptcode as CompletionCode ,CompCD.designation as CompletionDes
	  ,main.Reference
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
Where main.ClinicalDocumentID=@ClinicalDocumentID


Select 'ParticipantOrganization table'
Select 
	po.ClinicalDocumentId
	,org.Id_extension as AssignedOrgIdExt, org.Name as AssignedOrgName
	,TypeCSC.ConceptCode as ParticipationTypeCode,TypeCD.designation as ParticipationTypeDes
	,msg.Id_extension as MessageId
	From ClinicalDocument.ParticipantOrganization po
	left join Common.Organization org 
		on po.OrganizationId=org.OrganizationId
	left join dbmVCDRData.vocabulary.CodeSystemConcept TypeCSC
		on po.TypeCodeId=TypeCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation TypeCD
		on po.TypeCodeId=TypeCD.cscid
	inner join dbmVCDRData.MessageWrapper.ControlAct ca
		on po.ControlActId=ca.ControlActId
	inner join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
Where po.ClinicalDocumentId=@ClinicalDocumentID


Select 'ParticipantPerson table' 
Select 
	pp.ClinicalDocumentId
	,pp.time
	,msid.extension as PerformerMedicalStaffIdExt,ms.name as PerformerMedicalStaffName
	,TypeCSC.ConceptCode as ParticipationTypeCode,TypeCD.designation as ParticipationTypeDes
    ,msg.Id_extension as MessageId
	From ClinicalDocument.ParticipantPerson pp
	left join Common.MedicalStaff ms 
		on pp.MedicalStaffId=ms.MedicalStaffId
	left join common.MedicalStaffIdentifier msid
		on ms.MedicalStaffId=msid.MedicalStaffId and msid.isprimary=1	
	left join dbmVCDRData.vocabulary.CodeSystemConcept TypeCSC
		on pp.TypeCodeId=TypeCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation TypeCD
		on pp.TypeCodeId=TypeCD.cscid
	inner join dbmVCDRData.MessageWrapper.ControlAct ca
		on pp.ControlActId=ca.ControlActId
	inner join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
Where pp.ClinicalDocumentId=@ClinicalDocumentID

Select 'ActRelationship Table'
Select 
	ar.TargetActId as ClinicalDocumentId
	,SourceClass.dbmClassCodeName as RelatedActName
	,ar.SourceId_Extension, ar.SourceId_Root
    ,msg.Id_extension as MessageId
From 
	Common.ActRelationship ar 
		inner join Common.luElementClass SourceClass
			on ar.SourceActClassId=SourceClass.dbmClassCodeId
		inner join dbmVCDRData.MessageWrapper.ControlAct ca
			on ar.ControlActId=ca.ControlActId
		inner join dbmVCDRData.MessageWrapper.Message msg
			on msg.MessageId=ca.MessageId

where ar.TargetActId=@ClinicalDocumentID and ar.TargetActClassId=4096