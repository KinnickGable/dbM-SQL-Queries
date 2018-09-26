USE dbmVCDRData
GO

set transaction isolation level read uncommitted

SELECT  
            I.[Root],
            I.Extension,
            I.[AssigningAuthorityName],
            F.[Value] as [First Name],
            M.[Value] as [Middle Name],
            L.[Value] as [Last Name],
            D.Designation as [Gender],
            PR.BirthTime,
            PR.dbmAvailabilityTime
FROM PatientAdministration.PatientRecord PR with(nolock)
       inner join PatientAdministration.PatientIdentifier I with(nolock)
            ON PR.PatientRecordID = I.PatientRecordID
       inner join PatientAdministration.PatientName PN with(nolock)
            ON PR.PatientRecordID = PN.PatientRecordID
       left join PatientAdministration.PatientNamePart F with(nolock)
            ON PN.PatientNameID = F.PatientNameID
            AND F.PartTypeID = 2695
       left join PatientAdministration.PatientNamePart M with(nolock)
            ON PN.PatientNameID = M.PatientNameID
            AND M.PartTypeID = 44
       left join PatientAdministration.PatientNamePart L with(nolock)
            ON PN.PatientNameID = L.PatientNameID
            AND L.PartTypeID = 2694
       left join Vocabulary.ConceptDesignation D with(nolock)
            ON PR.AdministrativeGenderCodeID = D.CSCID      
WHERE I.IsPrimary = 1
