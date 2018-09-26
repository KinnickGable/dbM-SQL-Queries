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
IF OBJECT_ID('tempdb..#EventLog') IS NOT NULL
DROP TABLE #EventLog
IF OBJECT_ID('tempdb..#ExtendedProperties') IS NOT NULL
DROP TABLE #ExtendedProperties
IF OBJECT_ID('tempdb..#DILEvent') IS NOT NULL
DROP TABLE #DILEvent	

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


SELECT A.ArchMessageStateID, A.BTSInterchangeID, LoadingState, LoadingStateDate, ErrorID, TrailMessageInterchangeID
INTO #ArchMessageState
FROM dbo.ArchMessageState AS A WITH(NOLOCK)
	 INNER JOIN #lastStates 
		ON	A.[ArchMessageStateID]=#lastStates.LastStateID
WHERE A.ErrorID IS NOT NULL


--------------------------------- INDEXES DEFINITION
IF NOT EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE [name] = N'PK_#ArchMessageState_ArchMessageStateID' AND [type] = 'PK' and [parent_object_id] = OBJECT_ID('tempdb..#ArchMessageState'))
		ALTER TABLE #ArchMessageState ADD 
			CONSTRAINT [PK_#ArchMessageState_ArchMessageStateID] PRIMARY KEY CLUSTERED 
			(
				[ArchMessageStateID]
			) ON [PRIMARY];

IF NOT EXISTS(SELECT 1 FROM tempdb.sys.indexes WITH(NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb..#ArchMessageState') AND [name] = N'IX_#ArchMessageState_BTSInterchangeID')
CREATE INDEX IX_#ArchMessageState_BTSInterchangeID ON #ArchMessageState(BTSInterchangeID)

--IF NOT EXISTS(SELECT 1 FROM sys.indexes WITH(NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb..#ArchMessageState') AND [name] = N'PK_#ArchMessageState_LoadingStateDate')
--CREATE INDEX PK_#ArchMessageState_LoadingStateDate ON #ArchMessageState(LoadingStateDate)

IF NOT EXISTS(SELECT 1 FROM tempdb.sys.indexes WITH(NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb..#ArchMessageState') AND [name] = N'PK_#ArchMessageState_LoadingState')
CREATE INDEX PK_#ArchMessageState_LoadingState ON #ArchMessageState(LoadingState)

----------------------------- Events\Extended properties definition
		--							 All relevant events types from DIL
		SELECT		EventID
		INTO		#DILEvent
		FROM       dbmVCDRStage.Common.DILEvent
		WHERE     (LogLevelID IN (1, 2, 4))

		--							All relevant Events from dbmSTLRepository database
		SELECT Event_ID, EventDefID, OccurrenceTime, LogLevel, [Message], EventGroup, EventCategory, EventType, SourceType, SourcePublicKeyToken, SourceProcessUserName, SourceProcessName, SourceProcessID, SourceMethodName, SourceVersion, SourceAssemblyName, SourcedbMApplicationName, SourceDbmNode, SourceComputerName, UserTokenID, UserName, UserID, CoordinationID, CoordinationParentID, CoordinationRootID, CoordinationOperations, CoordinationName, CoordinationInitiator
		INTO #EventLog
		FROM #DILEvent AS DL 
		INNER JOIN dbmSTLRepository.STLData.EventLog AS EL WITH(NOLOCK)
				ON DL.EventID = EL.EventDefID
		WHERE OccurrenceTime BETWEEN @EventMinDate AND @EventMaxDate
			AND LogLevel = 'Error'

		--							All relevant Events from dbmSTLRepositoryArchive database
		INSERT INTO #EventLog(Event_ID, EventDefID, OccurrenceTime, LogLevel, [Message], EventGroup, EventCategory, EventType, SourceType, SourcePublicKeyToken, SourceProcessUserName, SourceProcessName, SourceProcessID, SourceMethodName, SourceVersion, SourceAssemblyName, SourcedbMApplicationName, SourceDbmNode, SourceComputerName, UserTokenID, UserName, UserID, CoordinationID, CoordinationParentID, CoordinationRootID, CoordinationOperations, CoordinationName, CoordinationInitiator)
		SELECT Event_ID, EventDefID, OccurrenceTime, LogLevel, [Message], EventGroup, EventCategory, EventType, SourceType, SourcePublicKeyToken, SourceProcessUserName, SourceProcessName, SourceProcessID, SourceMethodName, SourceVersion, SourceAssemblyName, SourcedbMApplicationName, SourceDbmNode, SourceComputerName, UserTokenID, UserName, UserID, CoordinationID, CoordinationParentID, CoordinationRootID, CoordinationOperations, CoordinationName, CoordinationInitiator
		FROM #DILEvent AS DL 
		INNER JOIN dbmSTLRepositoryArchive.dbo.EventLog AS EL WITH(NOLOCK)
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
		SELECT B.Event_ID, B.Name, B.Type, LTRIM(RTRIM(B.[Value])) AS [Value]
		INTO #ExtendedProperties
		FROM #EventLog AS C
		INNER JOIN dbmSTLRepository.STLData.ExtendedProperties AS B WITH(NOLOCK)
				ON C.Event_ID = B.Event_ID
		
		--							All relevant Extended Properties for Events selected below from dbmSTLRepositoryArchive
		INSERT INTO #ExtendedProperties(Event_ID, [Name], [Type], [Value])
		SELECT B.Event_ID, B.Name, B.Type, LTRIM(RTRIM(B.[Value]))
		FROM #EventLog AS C
		INNER JOIN dbmSTLRepositoryArchive.dbo.ExtendedProperties AS B WITH(NOLOCK)
				ON C.Event_ID = B.Event_ID

		--							Index on #ExtendedProperties.[Event_ID] Field
		IF NOT EXISTS(SELECT 1 FROM tempdb.sys.indexes WITH(NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb..#ExtendedProperties') AND [name] = N'CX_#ExtendedProperties_Event_ID')
		CREATE CLUSTERED INDEX CX_#ExtendedProperties_Event_ID ON #ExtendedProperties(Event_ID)

--		IF NOT EXISTS(SELECT 1 FROM tempdb.sys.indexes WITH(NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb..#ExtendedProperties') AND [name] = N'IX_#ExtendedProperties_Type')
--		CREATE INDEX IX_#ExtendedProperties_Type ON #ExtendedProperties(Type)

SELECT	K.MessageID,
		A.BTSInterchangeID,
		K.ArchTime,
		MIN(C.OccurrenceTime )AS 'OccurrenceTime In EventLog',
		A.LoadingStateDate AS 'LoadingStateDate In ArchMessageState',
		K.MessageType,
		K.MessageSourceSystem,
		K.MessageTriggerEvent,
		S.LoadingStateName,
		K.MessagePatientIDRoot as 'PatientIDRoot',
		K.MessagePatientIDExt as 'PatientIDExt',
		A.ErrorID AS 'Error ID in ArchMessageState',
		MIN(B.Event_ID) AS 'Event ID in ExtendedProperties',
		C.LogLevel,
		E.Description as 'Error Description',
		MIN(C.[Message]) AS 'Error Message in EventLog',
		MIN(D.[Value]) AS 'InternalErrorMessage',
		LEFT(MessageText, 20230) AS 'Message text from archive'
FROM #ArchMessageState AS A
LEFT OUTER JOIN dbo.ArchMessage AS K WITH(NOLOCK)
		ON A.BTSInterchangeID = K.BTSInterchangeID
INNER JOIN dbo.luLoadingState As S WITH(NOLOCK)
		ON A.LoadingState = S.LoadingStateID
LEFT OUTER JOIN #ExtendedProperties AS B
		ON A.BTSInterchangeID = B.[Value]
		AND Name = 'InterchangeId'
LEFT JOIN #EventLog AS C
		ON B.Event_ID = C.Event_ID
LEFT OUTER JOIN #ExtendedProperties AS D
		ON D.Event_ID = C.Event_ID
		AND D.Name = 'InternalErrorMessage'
LEFT JOIN dbmSTLEventsConfig.dbo.luEvents E with(nolock)
		ON A.ErrorID = E.EventDefID
WHERE K.ReplacingMessageArchiveID IS NULL
GROUP BY K.MessageID,
		A.BTSInterchangeID,
		K.ArchTime,
		A.LoadingStateDate,
		K.MessageType,
		K.MessageSourceSystem,
		K.MessageTriggerEvent,
		S.LoadingStateName,
		K.MessagePatientIDRoot,
		K.MessagePatientIDExt,
		A.ErrorID,
		C.LogLevel,
		E.Description,
		LEFT(MessageText, 20230)
ORDER BY K.MessageID


IF OBJECT_ID('tempdb..#lastStates') IS NOT NULL
DROP TABLE #lastStates
IF OBJECT_ID('tempdb..#ArchMessageState') IS NOT NULL
DROP TABLE #ArchMessageState
IF OBJECT_ID('tempdb..#EventLog') IS NOT NULL
DROP TABLE #EventLog
IF OBJECT_ID('tempdb..#ExtendedProperties') IS NOT NULL
DROP TABLE #ExtendedProperties
IF OBJECT_ID('tempdb..#DILEvent') IS NOT NULL
DROP TABLE #DILEvent




