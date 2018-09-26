USE dbmVCDRData
GO

DECLARE @MessagePatientIDRoot varchar(128),
            @MessagePatientIDExt varchar(255)

--Both parameters below you can find in the result of "FailedMessages" query 
SELECT @MessagePatientIDRoot = '2.16.840.1.113883.4.12', 
      @MessagePatientIDExt = '101450592'


SELECT  MRN.[Root] as PatientIDRoot,
            MRN.Extension as PatientIDExt,
            FirstName.[Value] as 'First Name',
            LastName.[Value] as 'Last Name',
            B.BirthTime as DOB
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
