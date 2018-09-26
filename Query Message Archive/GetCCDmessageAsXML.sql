use dbmDILMessagesArchive
select cast(messagetext as XML)
	from dbmdilmessagesarchive.dbo.ArchMessage with (nolock)
	where (BTSReceiveLocationName like '%CDA%') and (BTSInterchangeID = 'XXXX')
