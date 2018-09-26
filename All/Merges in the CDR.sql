
/**** tell me about merges  */
select * 
	from dbmVCDRData.PatientAdministration.PatientRelationship a
	join dbmVCDRData.MessageWrapper.ControlAct ca
	on a.ControlActID=ca.ControlActID
	join dbmVCDRData.MessageWrapper.Message m
	on ca.MessageID=m.MessageID
	join dbmDILMessagesArchive.dbo.ArchMessage am
		on m.InterchangeID=am.BTSInterchangeID
	where  ClassCodeID=1551


	