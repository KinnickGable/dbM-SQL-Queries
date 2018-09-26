USE dbmVCDRData

SELECT     PatientAdministration.PatientIdentifier.Extension AS [Scoper ID], PatientAdministration.PatientRelationship.PatientRecordID_Player, 
                      PatientAdministration.PatientRelationship.PatientRecordID_Scoper, PatientIdentifier_1.Extension AS [Player ID]
FROM         PatientAdministration.PatientRelationship WITH (NOLOCK) INNER JOIN
                      PatientAdministration.PatientIdentifier ON 
                      PatientAdministration.PatientRelationship.PatientRecordID_Scoper = PatientAdministration.PatientIdentifier.PatientRecordID INNER JOIN
                      PatientAdministration.PatientIdentifier AS PatientIdentifier_1 WITH (NOLOCK) ON 
                      PatientAdministration.PatientRelationship.PatientRecordID_Player = PatientIdentifier_1.PatientRecordID
WHERE     (PatientAdministration.PatientIdentifier.Extension = 'enter an identifier here')