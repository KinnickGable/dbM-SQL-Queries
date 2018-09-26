/*
Author: Alen
Creation Date: 2010-01-31
Description: Returns loading status between defined dates
*/

USE dbmDILMessagesArchive
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @EventMaxDate DATETIME,
		@EventMinDate DATETIME

SELECT  -->> (-1) parameter means from yesterday 
		@EventMaxDate = GETDATE(),
		@EventMinDate = '2010-05-26' --DATEADD(dd,-10,@EventMaxDate)

IF OBJECT_ID('tempdb..#lastStates') IS NOT NULL
DROP TABLE #lastStates

IF OBJECT_ID('tempdb..#ArchMessageState') IS NOT NULL
DROP TABLE #ArchMessageState

CREATE TABLE #lastStates
(
      BTSInterchangeID varchar(50),
      LastStateID bigint
)

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
SELECT	   lm.MessageType,
		   lm.MessageSourceSystem,
		   lm.MessageTriggerEvent,
		   MIN(lm.ArchTime) as FirstMsgDate,
		   MAX(lm.ArchTime) as LastMsgDate,
           SUM(CASE WHEN ams.LoadingState = 9 THEN 1 ELSE 0 END) as Loaded,
		   SUM(CASE WHEN ams.LoadingState not in(3,4,5,7,8,11,17,21,9) THEN 1 ELSE 0 END) as InProgress,
		   SUM(CASE WHEN ams.LoadingState in(3,4,5,7,8,11,17,21) THEN 1 ELSE 0 END) as Failed,		   
		   COUNT(MessageID) as Summary
FROM    #ArchMessageState ams
		LEFT JOIN [dbmDILMessagesArchive].[dbo].[ArchMessage] lm  WITH (NOLOCK)
			ON ams.BTSInterchangeID=lm.BTSInterchangeID
WHERE  lm.ReplacingMessageArchiveID IS NULL AND lm.MessageType <> 'Unknown'
GROUP BY lm.MessageType,
		   lm.MessageSourceSystem,
		   lm.MessageTriggerEvent
ORDER BY MAX(lm.ArchTime) desc



IF OBJECT_ID('tempdb..#ArchMessageState') IS NOT NULL
DROP TABLE #ArchMessageState

IF OBJECT_ID('tempdb..#lastStates') IS NOT NULL
DROP TABLE #lastStates