USE dbmVCDRData
GO

DECLARE @MessagePatientIDRoot varchar(128),
            @MessagePatientIDExt varchar(255),
            @MessageID varchar(255),
            @MessageText varchar(max)

SELECT @MessageID = '14018024'

SELECT  @MessagePatientIDRoot = MessagePatientIDRoot,
            @MessagePatientIDExt = MessagePatientIDExt,
            @MessageText = MessageText
FROM (
SELECT  top 1 MessagePatientIDRoot,
            MessagePatientIDExt,
            MessageText
FROM dbmDILMessagesArchive.dbo.ArchMessage with(nolock)
WHERE MessageID = @MessageID --AND ReplacingMessageArchiveID IS NULL
ORDER BY ArchMessageID desc) as patient


SELECT  MRN.[Root] as PatientIDRoot,
            MRN.Extension as PatientIDExt,
            FirstName.[Value] as 'First Name from CDR',
            LastName.[Value] as 'Last Name from CDR',
            B.BirthTime as 'DOB from CDR',
            @MessageText
FROM PatientAdministration.PatientIdentifier MRN with(nolock)
      inner join PatientAdministration.PatientRecord B with(nolock)
            on MRN.PatientRecordID = B.PatientRecordID
      inner join PatientAdministration.PatientName PN with(nolock)
            on B.PatientRecordID = PN.PatientRecordID
      left join PatientAdministration.PatientNamePart FirstName with(nolock)
            on PN.PatientNameID = FirstName.PatientNameID
            and FirstName.PartTypeID = 2695
      left join PatientAdministration.PatientNamePart LastName with(nolock)
            on PN.PatientNameID = LastName.PatientNameID
            and LastName.PartTypeID = 2694
WHERE Extension = @MessagePatientIDExt
        and [Root] = @MessagePatientIDRoot
        and MRN.IsPrimary = 1
