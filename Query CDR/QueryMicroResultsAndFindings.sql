use dbmVCDRData
-- use dbmVCDRDataHistory -- uncomment for querying the history CDR

Declare @LabEventIdExt varchar(100)
Declare @LabEventID bigint
declare @PatIdRoot varchar(100) 
declare @PatIdExt varchar(100)
declare @PatRecId bigint
declare @PatientName varchar(100)
Declare @LaboratoryResultID bigint
Declare @MicrobiologyFindingID bigint

/* 
	*** Execution Steps ***
	1. Set the Value of the @LabEventIdExt (LaboratoryEvent Id Extension) parameter.
	2. Run the query - the query will return the selected Laboratory Event and Results details.
*/


--- *** Queries Parameters  *** ---
--Set @PatIdRoot='2.16.840.1.113883.3.57.1.3.11.11.1.8.2' 
Set @PatIdExt='12345678' 
--set @PatientName='Hiram' 
Set @LabEventIDExt='12345678_LabEvent001'
Set @LaboratoryResultID=312
Set @MicrobiologyFindingID=37

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

--- Get LaboratoryEventId of the Laboraty Event ---
Set @LabEventID=(select top 1 le.LaboratoryEventId
			from [Laboratory].[LaboratoryEvent] le
			where le.id_extension=@LabEventIDExt)



SELECT main.[LaboratoryEventID]
      ,main.[Id_Root]
      ,main.[Id_Extension]
      ,main.[CodeID],csccode.conceptcode as code
      ,main.[CodeDisplayName]
      ,main.[CodeOriginalText]
	  ,sm.CodeDisplayName specimen
      ,main.[EffectiveTime]
      ,main.[StatusCodeID],cscstatus.conceptcode as statusCode
      ,main.[PriorityCodeID],cscpriority.conceptcode as PriorityCode
      ,main.[ClusterCodeID],csccluster.conceptcode as ClusterCode
      ,main.[StructureTypeCodeID],cscStructure.conceptcode as StructureTypeCode
      ,main.[Text]
      ,main.[dbmAvailabilityTime]
      ,main.[MedicalStaffID]
      ,main.[OrganizationID]
      ,main.[PatientRecordID]
  FROM [dbmVCDRData].[Laboratory].[LaboratoryEvent] main
	left join [dbmVCDRData].Vocabulary.CodeSystemConcept cscstatus on
		main.StatusCodeID=cscstatus.cscid
	left join [dbmVCDRData].Vocabulary.CodeSystemConcept cscpriority on
		main.[PriorityCodeID]=cscpriority.cscid
	left join [dbmVCDRData].Vocabulary.CodeSystemConcept csccluster on
		main.[ClusterCodeID]=csccluster.cscid
	left join [dbmVCDRData].Vocabulary.CodeSystemConcept cscStructure on
		main.[StructureTypeCodeID]=cscStructure.cscid
	left join Vocabulary.CodeSystemConcept cscCode on
		main.[CodeID]=cscCode.cscid
	left join [dbmVCDRData].Laboratory.SpecimenMaterial sm on
		main.LaboratoryEventID=sm.LaboratoryEventID
Where main.[LaboratoryEventID]=@LabEventID
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
--  FROM [dbmVCDRData].[MessageWrapper].[Message] as msg inner join
--	[dbmVCDRData].[MessageWrapper].ControlAct ca on
--		msg.messageid=ca.messageid
--where msg.[Id_Extension]=@MessageId) msg on
--	main.ControlActId=msg.ControlActId
--inner join
--		(SELECT 
--	    pi.PatientRecordId
--		,pi.extension
--		,pi.AssigningAuthorityName
--		,pr.BirthTime
--		,gcsc.conceptcode
--		,pnp.[Value]
--		,[PartTypeID]
--		  FROM [dbmVCDRData].[PatientAdministration].[PatientNamePart] pnp
--			inner join PatientAdministration.PatientName pn 
--				on pnp.PatientNameId=pn.PatientNameId
--			inner join PatientAdministration.PatientRecord pr
--				on pr.PatientRecordId=pn.PatientRecordId 
--			inner join Vocabulary.CodeSystemConcept gcsc
--				on pr.AdministrativeGenderCodeID=gcsc.cscid
--			inner join PatientAdministration.PatientIdentifier pi
--				on pr.PatientRecordId=pi.PatientRecordId
--			
--		where pi.isprimary=1 and pnp.Value =@PatientName) pat
--on main.PatientRecordId=pat.PatientRecordId

SELECT     LaboratoryResultID, Id_Root, Id_Extension, EffectiveTime, Value, Value_Conversion, Value_UnitID, CodeID, CodeDisplayName, CodeOriginalText, 
                      ReferenceRange_Low, ReferenceRange_High, ReferenceRange_Conversion, dbmAvailabilityTime, StatusCodeID, PriorityCodeID, MedicalStaffID, 
                      OrganizationID
FROM         Laboratory.LaboratoryResult
WHERE     (LaboratoryEventID = @LabEventID)

SELECT     Laboratory.MicrobiologyFinding.LaboratoryResultID, Laboratory.MicrobiologyFinding.MicrobiologyFindingID, 
                      Laboratory.MicrobiologyFinding.EffectiveTime, Laboratory.MicrobiologyFinding.Text, Common.Microorganism.CodeID, 
                      Common.Microorganism.CodeDisplayName, Common.Microorganism.CodeOriginalText
FROM         Laboratory.MicrobiologyFinding LEFT OUTER JOIN
                      Common.Microorganism ON Laboratory.MicrobiologyFinding.MicroorganismID = Common.Microorganism.MicroorganismID
WHERE     (LaboratoryResultID = @LaboratoryResultID)

SELECT     Laboratory.MicrobiologyFindingSusceptibility.MicrobiologyFindingID,Laboratory.MicrobiologyFindingSusceptibility.MicrobiologyFindingSusceptibilityID, Laboratory.MicrobiologyFindingSusceptibility.Value, 
                      Laboratory.MicrobiologyFindingSusceptibility.Text, Laboratory.MicrobiologyFindingSusceptibility.InterpretationCodeID, 
                      Common.Material.CodeID, Common.Material.CodeDisplayName, 
                      Common.Material.Name
FROM         Common.Material INNER JOIN
                      Laboratory.MicrobiologyFindingSusceptibility ON Common.Material.MaterialID = Laboratory.MicrobiologyFindingSusceptibility.MaterialID
Where MicrobiologyFindingID=@MicrobiologyFindingID

