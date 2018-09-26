USE dbmDILMessagesArchive
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @EventMaxDate DATETIME,
		@EventMinDate DATETIME

SELECT  -->> (-1) parameter means from yesterday 
		@EventMaxDate = GETDATE(),
		@EventMinDate = DATEADD(dd,-1,@EventMaxDate)

IF OBJECT_ID('tempdb..#lastStates') IS NOT NULL
DROP TABLE #lastStates

IF OBJECT_ID('tempdb..#ArchMessageState') IS NOT NULL
DROP TABLE #ArchMessageState

IF OBJECT_ID('tempdb..#States') IS NOT NULL
DROP TABLE #States		

CREATE TABLE #lastStates
(
      BTSInterchangeID varchar(50),
      LastStateID bigint
)

INSERT INTO #lastStates(BTSInterchangeID, LastStateID )
SELECT BTSInterchangeID, MAX(ArchMessageStateID)
FROM dbo.ArchMessageState WITH (NOLOCK)
WHERE  LoadingStateDate > @EventMinDate
		AND LoadingStateDate < @EventMaxDate
GROUP BY BTSInterchangeID


CREATE CLUSTERED INDEX [REX_LastStateID] ON #lastStates(LastStateID)


CREATE TABLE #ArchMessageState
(
      [BTSInterchangeID] [varchar](50),
      [LoadingState] [tinyint],
	  [LoadingStateDate] [datetime]
)

INSERT INTO #ArchMessageState
		(
		[BTSInterchangeID], 
		[LoadingState],
		[LoadingStateDate]
		)
SELECT 
	  AMS.[BTSInterchangeID],
	  AMS.[LoadingState],
	  AMS.[LoadingStateDate]
FROM [dbo].[ArchMessageState] AMS WITH (NOLOCK)
	 INNER JOIN #lastStates 
		ON	AMS.[ArchMessageStateID]=#lastStates.LastStateID


CREATE NONCLUSTERED INDEX [REX_BTSInterchangeID] ON #ArchMessageState (BTSInterchangeID)



CREATE TABLE #States(
LoadingStateID tinyint,
LoadingStateName varchar(50),
LoadingStatus varchar(50)
)

INSERT INTO #States
SELECT 
LoadingStateID,
LoadingStateName,
LoadingStatus = CASE 
				WHEN LoadingStateID IN(3, 4, 5, 7, 8, 11, 17, 21)
					THEN 'Failed'
				WHEN LoadingStateID IN(1, 2, 6, 16)
					THEN 'In Progress'
				WHEN LoadingStateID IN(9, 30)
					THEN 'Completed CDR'
				WHEN LoadingStateID = 14
					THEN 'For Replay/Replayed'
				WHEN LoadingStateID = 20
					THEN 'For Removal/Removed'
				END
FROM dbo.luLoadingState with(nolock)

CREATE NONCLUSTERED INDEX [REX_LoadingStateID] ON #States (LoadingStateID)


--Message state and count from one day

SELECT	   lm.MessageType,
		   lm.MessageSourceSystem,
		   lm.MessageTriggerEvent,
		   MIN(ams.LoadingStateDate) as FirstMsgDate,
		   MAX(ams.LoadingStateDate) as LastMsgDate,
           SUM(CASE WHEN s.LoadingStatus = 'Completed CDR' THEN 1 ELSE 0 END) as 'Completed CDR',
		   SUM(CASE WHEN s.LoadingStatus = 'In Progress' THEN 1 ELSE 0 END) as 'In Progress',
		   SUM(CASE WHEN s.LoadingStatus = 'Failed' THEN 1 ELSE 0 END) as 'Failed',
		   COUNT(*) as Summary
FROM    #ArchMessageState ams
		LEFT JOIN [dbo].[ArchMessage] lm  WITH(NOLOCK)
			ON ams.BTSInterchangeID=lm.BTSInterchangeID
		LEFT JOIN #States s
			ON ams.[LoadingState] = s.LoadingStateID
WHERE lm.ReplacingMessageArchiveID IS NULL
----messages with IS a replay indicator BUT no loading states called “FOR REPLAY” or “FOR REMOVAL” 
OR (lm.ReplacingMessageArchiveID IS NOT NULL 
AND NOT EXISTS (SELECT TOP(1) 1  FROM dbo.ArchMessageState  ams_REP WITH (NOLOCK)
					WHERE  ams_REP.BTSInterchangeID = lm.BTSInterchangeID
							AND ams_REP.LoadingState in (14,20))
) 
GROUP BY lm.MessageType,
		   lm.MessageSourceSystem,
		   lm.MessageTriggerEvent
ORDER BY MAX(ams.LoadingStateDate) desc



IF OBJECT_ID('tempdb..#ArchMessageState') IS NOT NULL
DROP TABLE #ArchMessageState

IF OBJECT_ID('tempdb..#lastStates') IS NOT NULL
DROP TABLE #lastStates

IF OBJECT_ID('tempdb..#States') IS NOT NULL
DROP TABLE #States	