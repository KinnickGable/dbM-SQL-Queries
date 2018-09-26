use dbmVCDRData
-- use dbmVCDRDataHistory -- uncomment for querying the history CDR

Declare @LabEventIdExt varchar(100)
Declare @LabEventID bigint
declare @PatIdRoot varchar(100) 
declare @PatIdExt varchar(100)
declare @PatRecId bigint
declare @PatientName varchar(100)

/* 
	*** Execution Steps ***
	1. Set the Value of the @LabEventIdExt (LaboratoryEvent Id Extension) parameter.
	2. Run the query - the query will return the selected Laboratory Event and Results details.
*/


--- *** Queries Parameters  *** ---
--Set @PatIdRoot='2.16.840.1.113883.3.57.1.3.11.11.1.8.2' 

Set @PatIdExt='00367801' 
Set @PatIdExt='Training_PatientV' 

--set @PatientName='Hiram' 
Set @LabEventIDExt='TrainingPatient_LabEvent007'

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
				and (pnp.Value=COALESCE(@PatientName,pnp.value)))
)

Select @PatRecId

--- Get LaboratoryEventId of the Laboraty Event ---
Set @LabEventID=(select top 1 le.LaboratoryEventId
			from [Laboratory].[LaboratoryEvent] le
			where le.id_extension=@LabEventIDExt)


Select 'LaboratoryEvent table'
SELECT distinct
	  main.dbmAvailabilityTime
		,pid.Extension as [Patient MRN]
	  ,main.[LaboratoryEventID]
      ,main.[Id_Root]
      ,main.[Id_Extension]
      ,CodeCSC.conceptcode as code ,CodeCD.designation as codeDes, CodeCS.CodeSystem, CodeDM.DomainCode
      ,main.[CodeDisplayName]
	  ,sm.CodeDisplayName specimen
      ,main.[EffectiveTime]
      ,StatusCSC.conceptcode as statusCode ,StatusCD.designation as statusDes, StatusCSC.CodeSystemId
      ,PriorityCSC.conceptcode as PriorityCode ,PriorityCD.designation as PriorityDes
      ,ClusterCSC.conceptcode as ClusterCode ,ClusterCD.designation as ClusterDes
      ,StructureCSC.conceptcode as StructureTypeCode ,StructureCD.designation as StructureTypeDes
	  ,org.Id_extension as PerformerOrgIdExt, org.Name as PerformerOrgName
	  ,msid.extension as PerformerMedicalStaffIdExt,ms.name as PerformerMedicalStaffName
      ,main.[Text]
      ,main.[dbmAvailabilityTime]
      ,main.[PatientRecordID]
	  ,msg.Id_extension as MessageId
  FROM [Laboratory].[LaboratoryEvent] main
	inner join PatientAdministration.PatientIdentifier pid 
		on main.PatientRecordId=pid.PatientRecordId and pid.isprimary=1
	left join dbmVCDRData.vocabulary.CodeSystemConcept StatusCSC
		on main.StatusCodeID=StatusCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation StatusCD 
		on main.StatusCodeID=StatusCD.cscid
	left join dbmVCDRData.vocabulary.CodeSystemConcept PriorityCSC 
		on main.[PriorityCodeID]=PriorityCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation PriorityCD 
		on main.[PriorityCodeID]=PriorityCD.cscid
	left join dbmVCDRData.vocabulary.CodeSystemConcept ClusterCSC 
		on main.[ClusterCodeID]=ClusterCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation ClusterCD 
		on main.[ClusterCodeID]=ClusterCD.cscid
	left join dbmVCDRData.vocabulary.CodeSystemConcept StructureCSC 
		on main.[StructureTypeCodeID]=StructureCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation StructureCD 
		on main.[StructureTypeCodeID]=StructureCD.cscid	
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
	left join Laboratory.SpecimenMaterial sm 
		on main.LaboratoryEventID=sm.LaboratoryEventID
	left join Common.Organization org 
		on main.OrganizationId=org.OrganizationId
	left join Common.MedicalStaff ms 
		on main.MedicalStaffId=ms.MedicalStaffId
	left join common.MedicalStaffIdentifier msid
		on ms.MedicalStaffId=msid.MedicalStaffId and msid.isprimary=1
	inner join dbmVCDRData.MessageWrapper.ControlAct ca
		on main.ControlActId=ca.ControlActId
	inner join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
Where main.PatientRecordId=@PatRecId -- main.LaboratoryEventId=@LabEventID
order by main.dbmAvailabilityTime desc

Select 'LaboratoryResult Table'
SELECT 
	  main.[LaboratoryEventId]
	  ,main.[LaboratoryResultId]
      ,main.[Id_Root]
      ,main.[Id_Extension]
      ,CodeCSC.conceptcode as code ,CodeCD.designation as codeDes
      ,main.[CodeDisplayName]
      ,main.[EffectiveTime]
	  ,main.value ,main.value_Conversion
      ,UnitCSC.conceptcode as UnitCode ,UnitCD.designation as UnitDes
 	  ,main.ReferenceRange_Low, main.ReferenceRange_High ,main.ReferenceRange_Conversion
	  ,lriCSC.conceptcode as LabInterpretationCode, lriCD.designation as LabInterpretationCodeDes
      ,StatusCSC.conceptcode as statusCode ,StatusCD.designation as statusDes
      ,PriorityCSC.conceptcode as PriorityCode ,PriorityCD.designation as PriorityDes
	  ,org.Id_extension as PerformerOrgIdExt, org.Name as PerformerOrgName
	  ,msid.extension as PerformerMedicalStaffIdExt,ms.name as PerformerMedicalStaffName
      ,lrt.content
      ,main.[dbmAvailabilityTime]
	  ,msg.Id_extension as MessageId
  FROM [Laboratory].[LaboratoryResult] main
	left join dbmVCDRData.vocabulary.CodeSystemConcept StatusCSC 
		on main.StatusCodeID=StatusCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation StatusCD 
		on main.StatusCodeID=StatusCD.cscid
	left join dbmVCDRData.vocabulary.CodeSystemConcept PriorityCSC 
		on main.[PriorityCodeID]=PriorityCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation PriorityCD 
		on main.[PriorityCodeID]=PriorityCD.cscid
	left join dbmVCDRData.vocabulary.CodeSystemConcept CodeCSC 
		on main.[CodeID]=CodeCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation CodeCD 
		on main.[CodeID]=CodeCD.cscid
	left join dbmVCDRData.vocabulary.CodeSystemConcept UnitCSC 
		on main.[Value_UnitID]=UnitCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation UnitCD 
		on main.[Value_UnitID]=UnitCD.cscid
	left join Laboratory.LaboratoryResultText lrt
		on main.LaboratoryResultId=lrt.LaboratoryResultId
	left join Laboratory.LaboratoryResultInterpretation lri
		on main.LaboratoryResultId=lri.LaboratoryResultId
	left join dbmVCDRData.vocabulary.CodeSystemConcept lriCSC 
		on lri.InterpretationCodeID=lriCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation lriCD 
		on lri.InterpretationCodeID=lriCD.cscid
	left join Common.Organization org 
		on main.OrganizationId=org.OrganizationId
	left join Common.MedicalStaff ms 
		on main.MedicalStaffId=ms.MedicalStaffId
	left join common.MedicalStaffIdentifier msid
		on ms.MedicalStaffId=msid.MedicalStaffId and msid.isprimary=1
	inner join dbmVCDRData.MessageWrapper.ControlAct ca
		on main.ControlActId=ca.ControlActId
	inner join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
WHERE     (main.LaboratoryEventID = @LabEventID)


