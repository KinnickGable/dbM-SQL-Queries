

-- This query returns Service ( SCV ) file /message loading - Vocabulary, Medical staff, Organizations, Labs Hierarchy that have been attempted to be loaded
-- 1/2012 bobh  
--1/21/2013 bobh - added xml for Labs Hierarchy  


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
      
      ,case when am.MessageFormat='xml' then   cast (messagetext as xml)else null end
      
  FROM [dbmDILMessagesArchive].[dbo].[ArchMessage]am
   left outer join (select BTSInterchangeID,Max(loadingState)MaxLoadingState from dbmDILMessagesArchive.dbo.ArchMessageState group by BTSInterchangeID) sams
	 ON am.btsinterchangeid=sams.BTSInterchangeID
	 
   left outer join dbmDILMessagesArchive.dbo.luLoadingState lu
    on sams.MaxLoadingState=lu.LoadingStateID
 Where MessageSourceSystem='Scv file'
 order by ArchTime desc