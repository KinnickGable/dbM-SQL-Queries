USE dbmDILMessagesArchive
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @EventMaxDate DATETIME,
		@EventMinDate DATETIME

SELECT  -->> (-1) parameter means from yesterday 
		@EventMaxDate = GETDATE(),
		@EventMinDate = '2010-01-25' --DATEADD(dd,-1,@EventMaxDate)

--SELECT MAXDate = @EventMaxDate, MINDate = @EventMinDate


CREATE TABLE #ArchMessageState
(
      [ArchMessageStateID] [bigint],
      [BTSInterchangeID] [varchar](50),
      [LoadingState] [tinyint] ,
      [LoadingStateDate] [datetime] ,
      [ErrorID] [varchar](255)
)

			
			INSERT INTO #ArchMessageState
			(     [ArchMessageStateID],
				  [BTSInterchangeID],
				  [LoadingState] ,
				  [LoadingStateDate],
				  [ErrorID]
				  )
			SELECT 
				  [ArchMessageStateID],
				  AMS.[BTSInterchangeID],
				  [LoadingState] ,
				  [LoadingStateDate],
				  [ErrorID]
			FROM [dbmDILMessagesArchive].[dbo].[ArchMessageState] AMS WITH (NOLOCK)
				 LEFT OUTER JOIN
                       (SELECT BTSInterchangeID,MAX([ArchMessageStateID]) MaxID
                        FROM [dbmDILMessagesArchive].[dbo].[ArchMessageState] AMS WITH (NOLOCK)
                        GROUP BY BTSInterchangeID) lastStates ON
						AMS.[ArchMessageStateID]=lastStates.MaxID
				 WHERE lastStates.MaxID IS NOT NULL

CREATE NONCLUSTERED INDEX [REX_BTSInterchangeID] ON #ArchMessageState (BTSInterchangeID) 



--Message state and count from one day
SELECT 'Message loading status from day one'

SELECT 
           LoadingStateName ,
		   COUNT(MessageID) as 'Message Count from day one'	

FROM [dbmDILMessagesArchive].[dbo].[ArchMessage] lm WITH (NOLOCK)
		INNER JOIN	#ArchMessageState ams ON
					lm.BTSInterchangeID=ams.BTSInterchangeID
        INNER JOIN	dbmDILMessagesArchive.dbo.luLoadingState st ON
					st.LoadingStateID=ams.LoadingState
WHERE  lm.ReplacingMessageArchiveID IS NULL 
GROUP BY LoadingStateName

--Message state and count from the last day
SELECT 'Message loading status from ' + CONVERT(varchar(16),@EventMinDate,120) + ' until ' + CONVERT(varchar(16),@EventMaxDate,120)

SELECT 
           LoadingStateName ,
		   COUNT(MessageID) as 'Message Count  for current time stamp'	
FROM [dbmDILMessagesArchive].[dbo].[ArchMessage] lm
		INNER JOIN	#ArchMessageState ams ON
					lm.BTSInterchangeID=ams.BTSInterchangeID
        INNER JOIN	dbmDILMessagesArchive.dbo.luLoadingState st ON
					st.LoadingStateID=ams.LoadingState
WHERE lm.ArchTime between @EventMinDate and @EventMaxDate
GROUP BY LoadingStateName

--Amount of failed messages per message type and trigger event
SELECT 'Failed messages (per type) from ' + CONVERT(varchar(16),@EventMinDate,120) + ' until ' + CONVERT(varchar(16),@EventMaxDate,120)

SELECT     lm.MessageType, 
		   lm.MessageTriggerEvent, 
		   COUNT(ArchMessageID) as 'Message Count',	
		   st.LoadingStateName
FROM	[dbmDILMessagesArchive].[dbo].[ArchMessage] lm
		INNER JOIN	#ArchMessageState ams ON
					lm.BTSInterchangeID=ams.BTSInterchangeID
        INNER JOIN	dbmDILMessagesArchive.dbo.luLoadingState st ON
					st.LoadingStateID=ams.LoadingState
	    INNER JOIN dbmVCDRStage.Common.DILEventDesignation EE ON 
					ams.ErrorID = EE.EventID
WHERE ams.LoadingState NOT IN (9,10,30)
		AND lm.ArchTime between @EventMinDate and @EventMaxDate
GROUP BY lm.MessageType, 
		 lm.MessageTriggerEvent, 
		 st.LoadingStateName


DROP TABLE #ArchMessageState


