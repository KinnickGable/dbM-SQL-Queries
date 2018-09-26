/*
Author: Alen
Creation Date: 2010-01-31
Description: Returns loading status between defined dates
*/

/*
changed by Alex T
added temp table #ArchMessage in order to restrict selected  data by clustered index
*/

USE dbmDILMessagesArchive
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON


DECLARE @EventMaxDate DATETIME,
		@EventMinDate DATETIME


declare @minArchMessageID bigint
declare @maxArchMessageID bigint


set @EventMaxDate = '2010-03-02'
set @EventMinDate = DATEADD(dd,-1,@EventMaxDate)-->> (-1) parameter means from yesterday 


select 
	@minArchMessageID = MIN(ArchMessageID),
	@maxArchMessageID = MAX(ArchMessageID)
from dbo.ArchMessage 
where ArchTime >= @EventMinDate
and ArchTime < @EventMaxDate

--select @minArchMessageID,@maxArchMessageID


IF OBJECT_ID('tempdb..#lastStates') IS NOT NULL
DROP TABLE #lastStates

IF OBJECT_ID('tempdb..#ArchMessageState') IS NOT NULL
DROP TABLE #ArchMessageState

IF OBJECT_ID('tempdb..#ArchMessage') IS NOT NULL
DROP TABLE #ArchMessage


CREATE TABLE #ArchMessage
(
	ArchMessageID bigint ,
	BTSInterchangeID varchar(50) ,
	BTSReceiveLocationName varchar(255) ,
	BTSReceivePortName varchar(255) ,
	BTSSize bigint ,
	ArchFileName varchar(255) ,
	ArchTime datetime ,
	MessageID varchar(255) ,
	MessageSourceSystem varchar(255) ,
	MessageType varchar(50) ,
	MessageTriggerEvent varchar(50) ,
	MessageText varchar(max) ,
	MessageFormat varchar(50) ,
	MessagePatientIDRoot varchar(128) ,
	MessagePatientIDExt varchar(255) ,
	MessageCreationTime datetime ,
	ReplacingMessageArchiveID bigint ,
	RemovedFromCDR bit 
)

CREATE TABLE #lastStates
(
      BTSInterchangeID varchar(50),
      LastStateID bigint
)


INSERT INTO #ArchMessage 
(
ArchMessageID, BTSInterchangeID, BTSReceiveLocationName, BTSReceivePortName, BTSSize, ArchFileName, ArchTime, MessageID, MessageSourceSystem, MessageType, MessageTriggerEvent, MessageText, MessageFormat, MessagePatientIDRoot, MessagePatientIDExt, MessageCreationTime, ReplacingMessageArchiveID, RemovedFromCDR
)
SELECT [ArchMessageID]
      ,[BTSInterchangeID]
      ,[BTSReceiveLocationName]
      ,[BTSReceivePortName]
      ,[BTSSize]
      ,[ArchFileName]
      ,[ArchTime]
      ,[MessageID]
      ,[MessageSourceSystem]
      ,[MessageType]
      ,[MessageTriggerEvent]
      ,[MessageText]
      ,[MessageFormat]
      ,[MessagePatientIDRoot]
      ,[MessagePatientIDExt]
      ,[MessageCreationTime]
      ,[ReplacingMessageArchiveID]
      ,[RemovedFromCDR]
FROM [dbmDILMessagesArchive].[dbo].[ArchMessage]
WHERE ArchMessageID  >= @minArchMessageID
AND ArchMessageID <= @maxArchMessageID

CREATE CLUSTERED INDEX [IX_CL_BTSInterchangeID] ON #ArchMessage
(
	[BTSInterchangeID] ASC
) --INCLUDE ( ArchMessageID,MessageCreationTime) 



INSERT INTO #lastStates(BTSInterchangeID, LastStateID )
SELECT BTSInterchangeID, MAX(ArchMessageStateID)
FROM dbmDILMessagesArchive.dbo.ArchMessageState WITH (NOLOCK)
WHERE  LoadingStateDate > @EventMinDate
		AND LoadingStateDate < @EventMaxDate
GROUP BY BTSInterchangeID


CREATE CLUSTERED INDEX [REX_LastStateID] ON #lastStates(LastStateID)


CREATE TABLE #ArchMessageState
(
      [BTSInterchangeID] [varchar](50),
      [LoadingState] [tinyint]
)

INSERT INTO #ArchMessageState
		(
		[BTSInterchangeID], 
		[LoadingState]
		)
SELECT 
	  AMS.[BTSInterchangeID],
	  AMS.[LoadingState]
FROM [dbmDILMessagesArchive].[dbo].[ArchMessageState] AMS WITH (NOLOCK)
	 INNER JOIN #lastStates 
		ON	AMS.[ArchMessageStateID]=#lastStates.LastStateID


CREATE NONCLUSTERED INDEX [REX_BTSInterchangeID] ON #ArchMessageState (BTSInterchangeID) 


--Message state and count from one day
SELECT 
	--ams.[BTSInterchangeID],	   
	lm.MessageType,
	lm.MessageSourceSystem,
	lm.MessageTriggerEvent,
	MIN(lm.ArchTime) as FirstMsgDate,
	MAX(lm.ArchTime) as LastMsgDate,
	SUM(CASE WHEN ams.LoadingState = 9 THEN 1 ELSE 0 END) as Loaded,
	SUM(CASE WHEN ams.LoadingState not in(3,4,5,7,8,11,17,21,9) THEN 1 ELSE 0 END) as InProgress,
	SUM(CASE WHEN ams.LoadingState in(3,4,5,7,8,11,17,21) THEN 1 ELSE 0 END) as Failed,		   
	COUNT(MessageID) as Summary
FROM    #ArchMessageState ams WITH (NOLOCK)
		LEFT JOIN #ArchMessage  lm 
			ON ArchMessageID  >= @minArchMessageID
			AND ArchMessageID <= @maxArchMessageID
			AND ams.BTSInterchangeID=lm.BTSInterchangeID
		
WHERE  lm.ReplacingMessageArchiveID IS NULL 
AND lm.MessageType <> 'Unknown'
GROUP BY 
	--ams.[BTSInterchangeID],
	lm.MessageType,
	lm.MessageSourceSystem,
	lm.MessageTriggerEvent
ORDER BY MAX(lm.ArchTime) desc



IF OBJECT_ID('tempdb..#ArchMessageState') IS NOT NULL
DROP TABLE #ArchMessageState

IF OBJECT_ID('tempdb..#lastStates') IS NOT NULL
DROP TABLE #lastStates

IF OBJECT_ID('tempdb..#ArchMessage') IS NOT NULL
DROP TABLE #ArchMessage

GO
