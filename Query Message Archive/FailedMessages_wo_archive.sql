USE dbmDILMessagesArchive
GO
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
------------------------- DECLARATION AREA
DECLARE @EventMaxDate DATETIME,
		@EventMinDate DATETIME,
		@ExtendedPropertiesType VARCHAR(255)

IF OBJECT_ID('tempdb..#ArchMessageState') IS NOT NULL
DROP TABLE #ArchMessageState
IF OBJECT_ID('tempdb..#EventLog') IS NOT NULL
DROP TABLE #EventLog
IF OBJECT_ID('tempdb..#ExtendedProperties') IS NOT NULL
DROP TABLE #ExtendedProperties
IF OBJECT_ID('tempdb..#DILEvent') IS NOT NULL
DROP TABLE #DILEvent

-------------------------- INITIAL AREA
SELECT  -->> (-1) parameter means from yesterday 
		@EventMaxDate = GETDATE(),
		@EventMinDate = DATEADD(dd,-1,GETDATE()),
		@ExtendedPropertiesType = 'InterchangeId'

SELECT ArchMessageStateID, BTSInterchangeID, LoadingState, LoadingStateDate, ErrorID, DE.ErrorMessage
INTO #ArchMessageState
FROM dbmDILMessagesArchive.dbo.ArchMessageState AS A WITH(NOLOCK)
	inner join dbmVCDRStage.Common.DILEventDesignation AS DE  WITH(NOLOCK)
		on A.ErrorID=DE.EventID
WHERE	LoadingStateDate BETWEEN @EventMinDate AND @EventMaxDate
		AND ErrorID IS NOT NULL

--------------------------------- INDEXES DEFINITION

IF NOT EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE [name] = N'PK_#ArchMessageState_ArchMessageStateID' AND [type] = 'PK' and [parent_object_id] = OBJECT_ID('tempdb..#ArchMessageState'))
		ALTER TABLE #ArchMessageState ADD 
			CONSTRAINT [PK_#ArchMessageState_ArchMessageStateID] PRIMARY KEY CLUSTERED 
			(
				[ArchMessageStateID]
			) ON [PRIMARY];

IF NOT EXISTS(SELECT 1 FROM tempdb.sys.indexes WITH(NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb..#ArchMessageState') AND [name] = N'IX_#ArchMessageState_BTSInterchangeID')
CREATE INDEX IX_#ArchMessageState_BTSInterchangeID ON #ArchMessageState(BTSInterchangeID)


IF NOT EXISTS(SELECT 1 FROM tempdb.sys.indexes WITH(NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb..#ArchMessageState') AND [name] = N'PK_#ArchMessageState_LoadingState')
CREATE INDEX PK_#ArchMessageState_LoadingState ON #ArchMessageState(LoadingState)

----------------------------- Events\Extended properties definition
		--							 All relevant events types from DIL
		SELECT		EventID
		INTO		#DILEvent
		FROM       dbmVCDRStage.Common.DILEvent
		WHERE     (LogLevelID IN (1, 2, 4))

		--							All relevant Events from dbmSTLRepository database
		SELECT Event_ID, OccurrenceTime, LogLevel, [Message]
		INTO #EventLog
		FROM #DILEvent AS DL 
		INNER JOIN dbmSTLRepository.STLData.EventLog AS EL WITH(NOLOCK)
				ON DL.EventID = EL.EventDefID
		WHERE OccurrenceTime BETWEEN @EventMinDate AND @EventMaxDate
			AND LogLevel = 'Error'


		--							Index on #EventLog.[Event_ID] Field
		IF NOT EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE [name] = N'PK_#EventLog_Event_ID' AND [type] = 'PK' and [parent_object_id] = OBJECT_ID('tempdb..#EventLog'))
				ALTER TABLE #EventLog ADD 
					CONSTRAINT [PK_#EventLog_Event_ID] PRIMARY KEY CLUSTERED 
					(
						[Event_ID]
					) ON [PRIMARY]; 
			
		--							All relevant Extended Properties for Events selected below from dbmSTLRepository
		SELECT B.Event_ID, B.[Name], LTRIM(RTRIM(B.[Value])) AS [Value]
		INTO #ExtendedProperties
		FROM #EventLog AS C
		INNER JOIN dbmSTLRepository.STLData.ExtendedProperties AS B WITH(NOLOCK)
				ON C.Event_ID = B.Event_ID
		

		--							Index on #ExtendedProperties.[Event_ID] Field
		IF NOT EXISTS(SELECT 1 FROM tempdb.sys.indexes WITH(NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb..#ExtendedProperties') AND [name] = N'CX_#ExtendedProperties_Event_ID')
		CREATE CLUSTERED INDEX CX_#ExtendedProperties_Event_ID ON #ExtendedProperties(Event_ID)


SELECT	K.MessageSourceSystem,
		K.MessageType + '^' + K.MessageTriggerEvent as MessageType,
		K.MessageID,
		K.ArchTime,		
		S.LoadingStateName,
		A.ErrorMessage,
		C.[Message] AS 'Error Message in EventLog',
		D.[Value] AS 'InternalErrorMessage',
		LEFT(MessageText, 20230) AS 'Message text from archive',
		A.LoadingStateDate AS 'LoadingStateDate In ArchMessageState',
		C.OccurrenceTime AS 'OccurrenceTime In EventLog',
		A.BTSInterchangeID,
		A.ErrorID AS 'Error ID in ArchMessageState',
		B.Event_ID AS 'Event ID in ExtendedProperties',
		C.LogLevel
FROM #ArchMessageState AS A
LEFT OUTER JOIN dbmDILMessagesArchive.dbo.ArchMessage AS K WITH(NOLOCK)
		ON A.BTSInterchangeID = K.BTSInterchangeID
INNER JOIN dbmDILMessagesArchive.dbo.luLoadingState As S WITH(NOLOCK)
		ON A.LoadingState = S.LoadingStateID
LEFT OUTER JOIN #ExtendedProperties AS B
		ON A.BTSInterchangeID = B.[Value]
		AND [Name] = @ExtendedPropertiesType
LEFT JOIN #EventLog AS C
		ON B.Event_ID = C.Event_ID
LEFT OUTER JOIN #ExtendedProperties AS D
		ON D.Event_ID = C.Event_ID
		AND D.Name IN ('InnerErrorMessage','InternalErrorID','InternalErrorMessage')
ORDER BY K.MessageID,ArchMessageStateID,C.OccurrenceTime


IF OBJECT_ID('tempdb..#ArchMessageState') IS NOT NULL
DROP TABLE #ArchMessageState
IF OBJECT_ID('tempdb..#EventLog') IS NOT NULL
DROP TABLE #EventLog
IF OBJECT_ID('tempdb..#ExtendedProperties') IS NOT NULL
DROP TABLE #ExtendedProperties
IF OBJECT_ID('tempdb..#DILEvent') IS NOT NULL
DROP TABLE #DILEvent