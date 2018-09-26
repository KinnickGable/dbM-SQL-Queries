SELECT [ArchMessageID]
      ,am.[BTSInterchangeID]
      ,[BTSReceiveLocationName]
      ,[BTSReceivePortName]
      ,[BTSSize]
      ,[ArchFileName]
      ,[MessageID]
      ,[MessageSourceSystem]
      ,[MessageType]
      ,[MessageTriggerEvent]
      ,[MessageText]
      ,[MessageFormat]
      ,[MessagePatientIDRoot]
      ,[MessagePatientIDExt]
      ,[ReplacingMessageArchiveID]
      ,[RemovedFromCDR]
      ,[ArchTime]
      ,[MessageCreationTime]
      ,sams.*
      ,lu.*
  FROM [dbmDILMessagesArchive].[dbo].[ArchMessage]am
   left outer join (select BTSInterchangeID,Max(loadingState)MaxLoadingState from dbmDILMessagesArchive.dbo.ArchMessageState group by BTSInterchangeID) sams
	 ON am.btsinterchangeid=sams.BTSInterchangeID
	 
   left outer join dbmDILMessagesArchive.dbo.luLoadingState lu
    on sams.MaxLoadingState=lu.LoadingStateID
Where  BTSReceivePortName='File'
 order by ArchTime desc