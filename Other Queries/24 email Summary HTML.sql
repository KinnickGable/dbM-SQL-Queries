/* dbMotion  Email monitor Scirpt */
/* rjh 2012-12-07  */
/* initial version based on 4.2 release */

declare @esubject varchar(255)
declare @body nvarchar(max)
declare @node varchar(25)
declare @recipients nvarchar(1024)
declare @profile_name varchar(255)
Declare @SendCareEventInfo varchar(1)
Declare @IncludeSafeCEEndpoints varchar(1)
declare @SendMessageErrorSummry varchar(1)
declare @SendMessageErrorDetail varchar(1)
declare @processStart datetime
declare @processEnd datetime
select @processStart=GETDATE()
/*=============================================*/
Set @eSubject='dbMotion 24 hour Loading Report  '
set @node=' Environment'
set @recipients='bob.harrington@dbmotion.com;
select top 1 @profile_name = name from msdb.dbo.sysmail_profile
Set @SendCareEventInfo='Y'
Set @IncludeSafeCEEndpoints='Y'
set @SendMessageErrorSummry ='Y'
set @SendMessageErrorDetail ='N'
/*=============================================*/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NoCount on
set ANSI_Warnings OFF
Set concat_null_yields_null off
DECLARE @EventMaxDate DATETIME,
		@EventMinDate DATETIME

SELECT  -->> (-1) parameter means from yesterday 
		@EventMaxDate = GETDATE(),
		@EventMinDate = GETDATE()-1

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
	
IF OBJECT_ID('tempdb..#lastStates2') IS NOT NULL
DROP TABLE #lastStates2
IF OBJECT_ID('tempdb..#ArchMessageState2') IS NOT NULL
DROP TABLE #ArchMessageState2
IF OBJECT_ID('tempdb..#EventLog2') IS NOT NULL
DROP TABLE #EventLog2
IF OBJECT_ID('tempdb..#ExtendedProperties2') IS NOT NULL
DROP TABLE #ExtendedProperties2
IF OBJECT_ID('tempdb..#DILEvent2') IS NOT NULL
DROP TABLE #DILEvent2	
IF OBJECT_ID('tempdb..#SummaryErrors2') IS NOT NULL
DROP TABLE #SummaryErrors2	
IF OBJECT_ID('tempdb..#CareEventErrorDetail') IS NOT NULL
DROP TABLE #CareEventErrorDetail	



CREATE TABLE #lastStates
(
      BTSInterchangeID varchar(50),
      LastStateID bigint
)


INSERT INTO #lastStates(BTSInterchangeID, LastStateID )
SELECT BTSInterchangeID
, MAX(ArchMessageStateID)
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
--Message Period statement

select @body='<H2> Message Summary Period from '
		   +cast(@EventMinDate as varchar(24)) 
		  + ' TO '
		 + cast(@EventMaxDate as varchar(24))+ '</H2>' 
      
select @body=@body +CHAR(10)+CHAR(13)
select @body=@body +CHAR(10)+CHAR(13)
    /************************************************************************************************************/  
    /* Simple Message Totals */
select @body=@body+
	N'<H2> Message Summary </H2>' +   N'<table border="1">' +    N'<tr><th> Loaded </th><th>In Progress</th><th>Failed</th><th>Total</th>' +
    CAST ( (
				--Message state and count from one day
				SELECT	--  td=cast(@node as varchar(9)) ,  '',
						--  td= cast(lm.MessageType as varchar(7)),  '',
						--td=	cast(lm.MessageSourceSystem as varchar(35)),  '',
						--td=	cast(lm.MessageTriggerEvent as varchar(7)) ,  '',
						-- td=  cast(MIN(lm.ArchTime)as varchar(24))  as [FirstMsgDate],  '',
						-- td=  cast(MAX(lm.ArchTime)as varchar(24))  as [LastMsgDate],  '',
						td=   cast(SUM(CASE WHEN ams.LoadingState = 9 THEN 1 ELSE 0 END)as varchar(6)),  '',
						td=   cast(SUM(CASE WHEN ams.LoadingState not in(3,4,5,7,8,11,17,21,9) THEN 1 ELSE 0 END)as varchar(6)) ,  '',
						td=   cast(SUM(CASE WHEN ams.LoadingState in(3,4,5,7,8,11,17,21) THEN 1 ELSE 0 END)as varchar(6)),  '',		   
						td=   cast(COUNT(MessageID)as varchar(9))  , ''
				FROM    #ArchMessageState ams
						LEFT JOIN [dbmDILMessagesArchive].[dbo].[ArchMessage] lm  WITH (NOLOCK)
							ON ams.BTSInterchangeID=lm.BTSInterchangeID
				WHERE lm.MessageType <> 'Unknown' AND  (lm.ReplacingMessageArchiveID IS NULL 

				----messages with IS a replay indicator BUT no loading states called “FOR REPLAY” or “FOR REMOVAL” 
				OR (lm.ReplacingMessageArchiveID IS NOT NULL 
				AND NOT EXISTS (SELECT TOP(1) 1  FROM dbmDILMessagesArchive.dbo.ArchMessageState  ams_REP WITH (NOLOCK)
									WHERE  ams_REP.LoadingStateDate > @EventMinDate
											AND ams_REP.LoadingStateDate < @EventMaxDate
											AND ams_REP.BTSInterchangeID = lm.BTSInterchangeID
											AND ams_REP.LoadingState in (14,20)))
				)
									  
									  
		--		GROUP BY   lm.MessageType is not null,
						
			--	ORDER BY  lm.MessageTriggerEvent
        FOR XML PATH('tr'), TYPE   ) AS NVARCHAR(MAX) ) +  N'</table>' ;
  /************************************************************************************************************/ 
  /* Current Status of FIFO */	
select @body=@body +CHAR(10)+CHAR(13)+'<H4>' 
select @body=@body +'FIFO COUNT '+Cast(COUNT(InterchangeID) as varchar(5)) from dbmDILFIFOQueue.dbo.FIFOQueue with (nolock)
select @body=@body +CHAR(10)+CHAR(13)
select @body=@body +'FIFO WAIT '+Cast(COUNT(HandleID) as  varchar(5))  from dbmDILFIFOQueue.dbo.FIFOWait_SendHandle with (nolock)
select @body=@body +CHAR(10)+CHAR(13)+'</H4>' 
    /************************************************************************************************************/ 
    /************************************************************************************************************/ 
    /* Message Counts by source , source, triggers and state  */		
select @body=@body +CHAR(10)+CHAR(13)

select @body=@body+
    N'<H2> Message Group Totals </H2>' +   N'<table border="1">' +
    N'<tr><th> Node </th><th>Message Type</th><th> Message Source System </th><th>Message Trigger Event</th><th> Loaded </th><th>In Progress</th><th>Failed</th><th>Total</th>' +
    CAST ( (
				--Message state and count from one day
				SELECT	  td=cast(@node as varchar(9)) ,  '',
						  td= cast(lm.MessageType as varchar(7)),  '',
						td=	cast(lm.MessageSourceSystem as varchar(35)),  '',
						td=	cast(lm.MessageTriggerEvent as varchar(7)) ,  '',
						-- td=  cast(MIN(lm.ArchTime)as varchar(24))  as [FirstMsgDate],  '',
						-- td=  cast(MAX(lm.ArchTime)as varchar(24))  as [LastMsgDate],  '',
						td=   cast(SUM(CASE WHEN ams.LoadingState = 9 THEN 1 ELSE 0 END)as varchar(6)),  '',
						td=   cast(SUM(CASE WHEN ams.LoadingState not in(3,4,5,7,8,11,17,21,9) THEN 1 ELSE 0 END)as varchar(6)) ,  '',
						td=   cast(SUM(CASE WHEN ams.LoadingState in(3,4,5,7,8,11,17,21) THEN 1 ELSE 0 END)as varchar(6)),  '',		   
						td=   cast(COUNT(MessageID)as varchar(9))  , ''
				FROM    #ArchMessageState ams
						LEFT JOIN [dbmDILMessagesArchive].[dbo].[ArchMessage] lm  WITH (NOLOCK)
							ON ams.BTSInterchangeID=lm.BTSInterchangeID
				WHERE lm.MessageType <> 'Unknown' AND  (lm.ReplacingMessageArchiveID IS NULL 

				----messages with IS a replay indicator BUT no loading states called “FOR REPLAY” or “FOR REMOVAL” 
				OR (lm.ReplacingMessageArchiveID IS NOT NULL 
				AND NOT EXISTS (SELECT TOP(1) 1  FROM dbmDILMessagesArchive.dbo.ArchMessageState  ams_REP WITH (NOLOCK)
									WHERE  ams_REP.LoadingStateDate > @EventMinDate
											AND ams_REP.LoadingStateDate < @EventMaxDate
											AND ams_REP.BTSInterchangeID = lm.BTSInterchangeID
											AND ams_REP.LoadingState in (14,20)))
				)
									  
									  
				GROUP BY lm.MessageType,
						   lm.MessageSourceSystem,
						   lm.MessageTriggerEvent
				ORDER BY  lm.MessageTriggerEvent
        FOR XML PATH('tr'), TYPE     ) AS NVARCHAR(MAX) ) +   N'</table>' ;

/**********************************************************************************/
If @SendCareEventInfo='Y' and @IncludeSafeCEEndpoints='Y'
Begin
			select @body=@body +CHAR(10)+CHAR(13)
			select @body=@body+
		    N'<H2> CareEvent Summary </H2>' +
			N'<table border="1">' +
			N'<tr><th>CareEvent Results</th><th>Count</th>' +
			CAST( (
			SELECT      
			td=(case when cedw.TrackingErrorId is not null then 'Not Delivered' else 'Delivered' end ),'', 
			td=	count(MessageId) ,''
     
			            
			FROM         dbmInternalData.Tracking.CareEventDataWrapper cedw with (nolock)
			 join dbmInternalData.Common.LuCareEventType lucet with (nolock)
			 on cedw.CareEventTypeId=lucet.CareEventTypeId
		     left outer join dbmInternalData.Tracking.LuTrackingError lute with (nolock)
		     on cedw.TrackingErrorId=lute.TrackingErrorId
			 
			 Where StatusUpdateDate>=@EventMinDate  and StatusUpdateDate<=@EventMaxDate 
			
			group by   ( case when cedw.TrackingErrorId is not null then 'Not Delivered' else 'Delivered' end )
			
			 FOR XML PATH('tr'), TYPE  ) AS NVARCHAR(MAX) ) +	 N'</table>'
			select @body=@body+
			 N'<H2> CareEvent Group Total </H2>' +
				N'<table border="1">' +
				N'<tr><th> CareEventTypeID </th><th>CareEventType Code</th><th> Tracking Error ID </th><th> TrackingError/Result </th><th>Occurrences</th>' +
				CAST ( (
				
			SELECT     -- cedw.TrackingMessageID,
					--	BatchID, 
						td=cedw.CareEventTypeId,  '',
						td=cast(Max(lucet.CareEventTypeCode)as varchar(15)) ,  '',
					--	ContentTypeId, 
					--	ContentProviderId,
					--	dbmAvailabilityTime, 
					--	BodyRemovalDate,
					--	IsReplay, 
					--	StatusUpdateDate, 
					--  TrackingStatusId, 
						td=isnull(cast(cedw.TrackingErrorId as varchar(20)),'0'),  '',
						td=isnull(cast(max(lute.TrackingError)as varchar(20)),'CareEvent Delivered'),  '',
						td=count(*) ,  ''
					--  RefId_Root,
					--  RefId_Extension
			            
			            
			FROM         dbmInternalData.Tracking.CareEventDataWrapper cedw with (nolock)
			 join dbmInternalData.Common.LuCareEventType lucet with (nolock)
			 on cedw.CareEventTypeId=lucet.CareEventTypeId
			left outer join dbmInternalData.Tracking.LuTrackingError lute with (nolock)
			 on cedw.TrackingErrorId=lute.TrackingErrorId
			 
			 Where StatusUpdateDate>=@EventMinDate  and StatusUpdateDate<=@EventMaxDate 
			
			group by cedw.CareEventTypeID,cedw.TrackingErrorid
			order by  cedw.CareEventTypeID,cedw.TrackingErrorid
				
				
					FOR XML PATH('tr'), TYPE 
				) AS NVARCHAR(MAX) ) +
				N'</table>'+
			 N'<H6> Customer actionable errors: UnknownPatientId </H6>'+
			 N'<H6> Acceptable End State	  : CareEvent Delivered, UnknownRecipients </H6>' +
			 N'<H6> All others dbMotion investigation		 </H6>' ;
			 	----Message Wrappers to CareEvent Processing counts.	
		select @body=@body +CHAR(10)+CHAR(13)
    
    /**** CareEvent Message Wraper Total in period */
		 
	select @body=@body+
		    N'<H2> CareEvent Message Wrapper Summary </H2>' +
			N'<table border="1">' +
			N'<tr><th>Wrapper Trigger Type</th><th>Count</th>' +
			CAST ( (
						--Wrappers touched state and count in time period
						Select 
						td=CareEventWrapperTrigger,'',
						td=[Count],''
						from  
						 (select   'New CareEvent Data Wrappers' as CareEventWrapperTrigger, COUNT(*) as [Count]
							from dbmInternalData.Tracking.CareEventDataWrapper
							where  (dbmAvailabilityTime >= @EventMinDate and dbmAvailabilityTime <= @EventMaxDate)
							union	
							select 'Updated CareEvent Data Wrappers'as CareEventWrapperTrigger,COUNT(*) as [Count]
							from dbmInternalData.Tracking.CareEventDataWrapper	
							 where 
								( StatusUpdateDate >= @EventMinDate and StatusUpdateDate <= @EventMaxDate)
							   and StatusUpdateDate<>dbmAvailabilityTime
						  ) a	
			 FOR XML PATH('tr'), TYPE  ) AS NVARCHAR(MAX) ) +	 N'</table>' ;
					
	END
/****************************************************************************************************************/
/**********************************************************************************/
If @SendCareEventInfo='Y' and @IncludeSafeCEEndpoints='N'
Begin
			select @body=@body +CHAR(10)+CHAR(13)
			select @body=@body+
		    N'<H2> CareEvent Summary </H2>' +
			N'<table border="1">' +
			N'<tr><th>CareEvent Results</th><th>Count</th>' +
			CAST( (
			SELECT      
			td=(case when cedw.TrackingErrorId is not null then 'Not Delivered' else 'Delivered' end ),'', 
			td=	count(MessageId) ,''
     
			            
			FROM         dbmInternalData.Tracking.CareEventDataWrapper cedw with (nolock)
			 join dbmInternalData.Common.LuCareEventType lucet with (nolock)
			 on cedw.CareEventTypeId=lucet.CareEventTypeId
		     left outer join dbmInternalData.Tracking.LuTrackingError lute with (nolock)
		     on cedw.TrackingErrorId=lute.TrackingErrorId
			 
			 Where StatusUpdateDate>=@EventMinDate  and StatusUpdateDate<=@EventMaxDate 
			
			group by   ( case when cedw.TrackingErrorId is not null then 'Not Delivered' else 'Delivered' end )
			
			 FOR XML PATH('tr'), TYPE  ) AS NVARCHAR(MAX) ) +	 N'</table>'
			select @body=@body+
			 N'<H2> CareEvent Group Total </H2>' +
				N'<table border="1">' +
				N'<tr><th> CareEventTypeID </th><th>CareEventType Code</th><th> Tracking Error ID </th><th> TrackingError/Result </th><th>Occurrences</th>' +
				CAST ( (
				
			SELECT     -- cedw.TrackingMessageID,
					--	BatchID, 
						td=cedw.CareEventTypeId,  '',
						td=cast(Max(lucet.CareEventTypeCode)as varchar(15)) ,  '',
					--	ContentTypeId, 
					--	ContentProviderId,
					--	dbmAvailabilityTime, 
					--	BodyRemovalDate,
					--	IsReplay, 
					--	StatusUpdateDate, 
					--  TrackingStatusId, 
						td=isnull(cast(cedw.TrackingErrorId as varchar(20)),'0'),  '',
						td=isnull(cast(max(lute.TrackingError)as varchar(20)),'CareEvent Delivered'),  '',
						td=count(*) ,  ''
					--  RefId_Root,
					--  RefId_Extension
			            
			            
			FROM         dbmInternalData.Tracking.CareEventDataWrapper cedw with (nolock)
			 join dbmInternalData.Common.LuCareEventType lucet with (nolock)
			 on cedw.CareEventTypeId=lucet.CareEventTypeId
			left outer join dbmInternalData.Tracking.LuTrackingError lute with (nolock)
			 on cedw.TrackingErrorId=lute.TrackingErrorId
			 
			 Where StatusUpdateDate>=@EventMinDate  and StatusUpdateDate<=@EventMaxDate
				and cedw.TrackingErrorId not IN (null,5) 
			
			group by cedw.CareEventTypeID,cedw.TrackingErrorid
			order by  cedw.CareEventTypeID,cedw.TrackingErrorid
				
				
					FOR XML PATH('tr'), TYPE 
				) AS NVARCHAR(MAX) ) +
				N'</table>'+
			 N'<H5> Customer actionable errors:UnknownPatientId </H5>'+
			 N'<H5> Acceptable End State	  :CareEvent Delivered,UnknownRecipients </H5>' +
			 N'<H5> All others dbMotion invesitgation		 </H5>' ;
			
	END
/****************************************************************************************************************/			
			/*** begin Error Summary Portion */
			--USE dbmDILMessagesArchive
If @SendMessageErrorSummry='Y'
begin
	IF OBJECT_ID('tempdb..#lastStates2') IS NOT NULL
				drop TABLE #lastStates2
	IF OBJECT_ID('tempdb..#ArchMessageState2') IS NOT NULL
				drop TABLE #ArchMessageState2  
	IF OBJECT_ID('tempdb..#DILEvent2') IS NOT NULL
				drop TABLE #DILEvent3    
	IF OBJECT_ID('tempdb..#SummaryErrors2') IS NOT NULL
				drop TABLE #SummaryErrors2 
	IF OBJECT_ID('tempdb..#EventLog2') IS NOT NULL
				drop TABLE #EventLog2 
	IF OBJECT_ID('tempdb..#ExtendedProperties2') IS NOT NULL
				drop TABLE #ExtendedProperties2   
				 	
	CREATE TABLE #lastStates2
			(
				  BTSInterchangeID varchar(50),
				  LastStateID bigint
			)


			INSERT INTO #lastStates2(BTSInterchangeID, LastStateID )
			SELECT  ams.BTSInterchangeID
					, MAX(ArchMessageStateID) 
			FROM dbmDILMessagesArchive.dbo.ArchMessageState AMS WITH (NOLOCK) 
			join dbmDILMessagesArchive.dbo.ArchMessage AM WITH (NOLOCK) 
				on AMS.BTSInterchangeID = AM.BTSInterchangeID 
			WHERE  LoadingStateDate > @EventMinDate 
				AND LoadingStateDate < @EventMaxDate 
				AND (AM.MessageID is not null 
					 or AM.MessageSourceSystem is not null 
					 or AM. MessageTriggerEvent is not null   
					 or AM. MessageType is not null 
					 or AM. MessagePatientIDExt is not null 
					 or AM. MessagePatientIDRoot is not null
					 )
			GROUP BY AMS.BTSInterchangeID


			CREATE CLUSTERED INDEX [REX_LastStateID] ON #lastStates2(LastStateID)
			SELECT A.ArchMessageStateID, A.BTSInterchangeID, LoadingState, LoadingStateDate, ErrorID, TrailMessageInterchangeID
			into #ArchMessageState2
			FROM dbmDILMessagesArchive.dbo.ArchMessageState AS A WITH(NOLOCK)
				 INNER JOIN #lastStates2 
					ON	A.[ArchMessageStateID]=#lastStates2.LastStateID
			WHERE A.ErrorID IS NOT NULL
			--------------------------------- INDEXES DEFINITION
			IF NOT EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE [name] = N'PK_#ArchMessageState2_ArchMessageStateID' AND [type] = 'PK' and [parent_object_id] = OBJECT_ID('tempdb..#ArchMessageState2'))
					ALTER TABLE #ArchMessageState2 ADD 
						CONSTRAINT [PK_#ArchMessageState2_ArchMessageStateID] PRIMARY KEY CLUSTERED 
						(
							[ArchMessageStateID]
						) ON [PRIMARY];

			IF NOT EXISTS(SELECT 1 FROM tempdb.sys.indexes WITH(NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb..#ArchMessageState2') AND [name] = N'IX_#ArchMessageState2_BTSInterchangeID')
			CREATE INDEX IX_#ArchMessageState2_BTSInterchangeID ON #ArchMessageState2(BTSInterchangeID)


			IF NOT EXISTS(SELECT 1 FROM tempdb.sys.indexes WITH(NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb..#ArchMessageState2') AND [name] = N'PK_#ArchMessageState2_LoadingState')
			CREATE INDEX PK_#ArchMessageState2_LoadingState ON #ArchMessageState2(LoadingState)

			----------------------------- Events\Extended properties definition
					--							 All relevant events types from DIL
					SELECT		EventID
					INTO		#DILEvent2
					FROM       dbmVCDRStage.Common.DILEvent
					WHERE     (LogLevelID IN (1, 2, 4))

					--							All relevant Events from dbmSTLRepository database
					SELECT Event_ID, EventDefID, OccurrenceTime, LogLevel, [Message], EventGroup, EventCategory, EventType, SourceType, SourcePublicKeyToken, SourceProcessUserName, SourceProcessName, SourceProcessID, SourceMethodName, SourceVersion, SourceAssemblyName, SourcedbMApplicationName, SourceDbmNode, SourceComputerName, UserTokenID, UserName, UserID, CoordinationID, CoordinationParentID, CoordinationRootID, CoordinationOperations, CoordinationName, CoordinationInitiator
					INTO #EventLog2
					FROM #DILEvent2 AS DL 
					INNER JOIN dbmSTLRepository.STLData.EventLog AS EL WITH(NOLOCK)
							ON DL.EventID = EL.EventDefID
					WHERE OccurrenceTime BETWEEN @EventMinDate AND @EventMaxDate
						AND LogLevel = 'Error'

					--							All relevant Events from dbmSTLRepositoryArchive database
					INSERT INTO #EventLog2(Event_ID, EventDefID, OccurrenceTime, LogLevel, [Message], EventGroup, EventCategory, EventType, SourceType, SourcePublicKeyToken, SourceProcessUserName, SourceProcessName, SourceProcessID, SourceMethodName, SourceVersion, SourceAssemblyName, SourcedbMApplicationName, SourceDbmNode, SourceComputerName, UserTokenID, UserName, UserID, CoordinationID, CoordinationParentID, CoordinationRootID, CoordinationOperations, CoordinationName, CoordinationInitiator)
					SELECT Event_ID, EventDefID, OccurrenceTime, LogLevel, [Message], EventGroup, EventCategory, EventType, SourceType, SourcePublicKeyToken, SourceProcessUserName, SourceProcessName, SourceProcessID, SourceMethodName, SourceVersion, SourceAssemblyName, SourcedbMApplicationName, SourceDbmNode, SourceComputerName, UserTokenID, UserName, UserID, CoordinationID, CoordinationParentID, CoordinationRootID, CoordinationOperations, CoordinationName, CoordinationInitiator
					FROM #DILEvent2 AS DL 
					INNER JOIN dbmSTLRepositoryArchive.dbo.EventLog AS EL WITH(NOLOCK)
							ON DL.EventID = EL.EventDefID
					WHERE OccurrenceTime BETWEEN @EventMinDate AND @EventMaxDate
						AND LogLevel = 'Error'

					--							Index on #EventLog.[Event_ID] Field
					IF NOT EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE [name] = N'PK_#EventLog2_Event_ID' AND [type] = 'PK' and [parent_object_id] = OBJECT_ID('tempdb..#EventLog2'))
							ALTER TABLE #EventLog2 ADD 
								CONSTRAINT [PK_#EventLog2_Event_ID] PRIMARY KEY CLUSTERED 
								(
									[Event_ID]
								) ON [PRIMARY]; 
						
					--							All relevant Extended Properties for Events selected below from dbmSTLRepository
					SELECT B.Event_ID, B.Name, B.Type, LTRIM(RTRIM(B.[Value])) AS [Value]
					INTO #ExtendedProperties2
					FROM #EventLog2 AS C
					INNER JOIN dbmSTLRepository.STLData.ExtendedProperties AS B WITH(NOLOCK)
							ON C.Event_ID = B.Event_ID
					
					--							All relevant Extended Properties for Events selected below from dbmSTLRepositoryArchive
					INSERT INTO #ExtendedProperties2(Event_ID, [Name], [Type], [Value])
					SELECT B.Event_ID, B.Name, B.Type, LTRIM(RTRIM(B.[Value]))
					FROM #EventLog2 AS C
					INNER JOIN dbmSTLRepositoryArchive.dbo.ExtendedProperties AS B WITH(NOLOCK)
							ON C.Event_ID = B.Event_ID

					--							Index on #ExtendedProperties.[Event_ID] Field
					IF NOT EXISTS(SELECT 1 FROM tempdb.sys.indexes WITH(NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb..#ExtendedProperties2') AND [name] = N'CX_#ExtendedProperties2_Event_ID')
					CREATE CLUSTERED INDEX CX_#ExtendedProperties2_Event_ID ON #ExtendedProperties2(Event_ID)

			--		IF NOT EXISTS(SELECT 1 FROM tempdb.sys.indexes WITH(NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb..#ExtendedProperties2') AND [name] = N'IX_#ExtendedProperties2_Type')
			--		CREATE INDEX IX_#ExtendedProperties2_Type ON #ExtendedProperties(Type)

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
					
					Into #SummaryErrors2
			FROM #ArchMessageState2 AS A
			LEFT OUTER JOIN dbmDILMessagesArchive.dbo.ArchMessage AS K WITH(NOLOCK)
					ON A.BTSInterchangeID = K.BTSInterchangeID
			INNER JOIN dbmDILMessagesArchive.dbo.luLoadingState As S WITH(NOLOCK)
					ON A.LoadingState = S.LoadingStateID
			LEFT OUTER JOIN #ExtendedProperties2 AS B
					ON A.BTSInterchangeID = B.[Value]
					AND Name = 'InterchangeId'
			LEFT JOIN #EventLog2 AS C
					ON B.Event_ID = C.Event_ID
			LEFT OUTER JOIN #ExtendedProperties2 AS D
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

set ANSI_Warnings OFF


		select @body=@body+
		 N'<H2> Message Error Summary </H2>' +
			N'<table border="1">' +
			N'<tr><th> Type/Trigger </th><th>Source</th><th>Error </th><th>Occurrences</th><th>Last Message ID </th><th>Last Occurrence time</th>' +
			CAST ( (
		SELECT	td=cast (MessageType as varchar(3) ) + ' '+cast(MessageTriggerEvent as varchar(3)) ,  '',
				td=cast(MessageSourceSystem as varchar(35)),  '',
				td= case when [Error Description] is null then 'Unknown' else cast ([Error Description]  as varchar(75)) end,  '',
				td=cast(COUNT(*) as varchar(8)),  '',
			--	[Error Message In EventLog] ,
			--	max( case when [InternalErrorMessage] is null then 'Unknown'  else [InternalErrorMessage] end )  as [InternalErrorMessage],		
				td=cast(MAX(MessageID)as varchar(17)),  '',
				--Cast(MAX(BTSInterchangeID) as varchar(42)) as [Last BTSInterchangeID],
				td=cast(MAX(ArchTime)as varchar(18)) ,  ''

		from #SummaryErrors2

		Group by MessageType,
				MessageTriggerEvent,
				MessageSourceSystem,
				[Error Description],
				[Error Message In EventLog],
				left([InternalErrorMessage],200)	
			order by 
			COUNT(*) desc
				FOR XML PATH('tr'), TYPE 
			) AS NVARCHAR(MAX) ) +
			N'</table>' ;
			
	IF OBJECT_ID('tempdb..#lastStates2') IS NOT NULL
				drop TABLE #lastStates2
	IF OBJECT_ID('tempdb..#ArchMessageState2') IS NOT NULL
				drop TABLE #ArchMessageState2  
	IF OBJECT_ID('tempdb..#DILEvent2') IS NOT NULL
				drop TABLE #DILEvent2    
	IF OBJECT_ID('tempdb..#SummaryErrors2') IS NOT NULL
				drop TABLE #SummaryErrors2 
	IF OBJECT_ID('tempdb..#EventLog2') IS NOT NULL
				drop TABLE #EventLog2 
	IF OBJECT_ID('tempdb..#ExtendedProperties2') IS NOT NULL
				drop TABLE #ExtendedProperties2   			
			
			
END

/**********************************************************************************************/
/*** begin Error Detail Portion */
  --USE dbmDILMessagesArchive
 If @SendMessageErrorDetail ='Y'
	begin
    IF OBJECT_ID('tempdb..#lastStates3') IS NOT NULL
				drop TABLE #lastStates3
	IF OBJECT_ID('tempdb..#ArchMessageState3') IS NOT NULL
				drop TABLE #ArchMessageState3  
	IF OBJECT_ID('tempdb..#DILEvent3') IS NOT NULL
				drop TABLE #DILEvent3    
	IF OBJECT_ID('tempdb..#SummaryErrors3') IS NOT NULL
				drop TABLE #SummaryErrors3 			     
    IF OBJECT_ID('tempdb..#EventLog3') IS NOT NULL
				drop TABLE #EventLog3    
    IF OBJECT_ID('tempdb..#ExtendedProperties3') IS NOT NULL
				drop TABLE #ExtendedProperties3 
				 			
             CREATE TABLE #lastStates3
                  (
                          BTSInterchangeID varchar(50),
                          LastStateID bigint
                  )


                  INSERT INTO #lastStates3(BTSInterchangeID, LastStateID )
                  SELECT  ams.BTSInterchangeID
                              , MAX(ArchMessageStateID) 
                  FROM dbmDILMessagesArchive.dbo.ArchMessageState AMS WITH (NOLOCK) 
                  join dbmDILMessagesArchive.dbo.ArchMessage AM WITH (NOLOCK) 
                        on AMS.BTSInterchangeID = AM.BTSInterchangeID 
                  WHERE  LoadingStateDate > @EventMinDate 
                        AND LoadingStateDate < @EventMaxDate 
                        AND (AM.MessageID is not null 
                               or AM.MessageSourceSystem is not null 
                               or AM. MessageTriggerEvent is not null   
                               or AM. MessageType is not null 
                               or AM. MessagePatientIDExt is not null 
                               or AM. MessagePatientIDRoot is not null
                              )
                  GROUP BY AMS.BTSInterchangeID


                  CREATE CLUSTERED INDEX [REX_LastStateID] ON #lastStates3(LastStateID)



                  SELECT A.ArchMessageStateID, A.BTSInterchangeID, LoadingState, LoadingStateDate, ErrorID, TrailMessageInterchangeID
                  into #ArchMessageState3
                  FROM dbmDILMessagesArchive.dbo.ArchMessageState AS A WITH(NOLOCK)
                        INNER JOIN #lastStates3 
                              ON    A.[ArchMessageStateID]=#lastStates3.LastStateID
                  WHERE A.ErrorID IS NOT NULL


                  --------------------------------- INDEXES DEFINITION
                  IF NOT EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE [name] = N'PK_#ArchMessageState3_ArchMessageStateID' AND [type] = 'PK' and [parent_object_id] = OBJECT_ID('tempdb..#ArchMessageState3'))
                              ALTER TABLE #ArchMessageState3 ADD 
                                    CONSTRAINT [PK_#ArchMessageState3_ArchMessageStateID] PRIMARY KEY CLUSTERED 
                                    (
                                          [ArchMessageStateID]
                                    ) ON [PRIMARY];

                  IF NOT EXISTS(SELECT 1 FROM tempdb.sys.indexes WITH(NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb..#ArchMessageState3') AND [name] = N'IX_#ArchMessageState3_BTSInterchangeID')
                  CREATE INDEX IX_#ArchMessageState3_BTSInterchangeID ON #ArchMessageState3(BTSInterchangeID)

                  IF NOT EXISTS(SELECT 1 FROM tempdb.sys.indexes WITH(NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb..#ArchMessageState3') AND [name] = N'PK_#ArchMessageState3_LoadingState')
                  CREATE INDEX PK_#ArchMessageState3_LoadingState ON #ArchMessageState3(LoadingState)

                  ----------------------------- Events\Extended properties definition
                              --                                        All relevant events types from DIL
                              SELECT            EventID
                              INTO        #DILEvent3
                              FROM       dbmVCDRStage.Common.DILEvent
                              WHERE     (LogLevelID IN (1, 2, 4))

                              --                                        All relevant Events from dbmSTLRepository database
                              SELECT Event_ID, EventDefID, OccurrenceTime, LogLevel, [Message], EventGroup, EventCategory, EventType, SourceType, SourcePublicKeyToken, SourceProcessUserName, SourceProcessName, SourceProcessID, SourceMethodName, SourceVersion, SourceAssemblyName, SourcedbMApplicationName, SourceDbmNode, SourceComputerName, UserTokenID, UserName, UserID, CoordinationID, CoordinationParentID, CoordinationRootID, CoordinationOperations, CoordinationName, CoordinationInitiator
                              INTO #EventLog3
                              FROM #DILEvent3 AS DL 
                              INNER JOIN dbmSTLRepository.STLData.EventLog AS EL WITH(NOLOCK)
                                          ON DL.EventID = EL.EventDefID
                              WHERE OccurrenceTime BETWEEN @EventMinDate AND @EventMaxDate
                                    AND LogLevel = 'Error'

                              --                                        All relevant Events from dbmSTLRepositoryArchive database
                              INSERT INTO #EventLog3(Event_ID, EventDefID, OccurrenceTime, LogLevel, [Message], EventGroup, EventCategory, EventType, SourceType, SourcePublicKeyToken, SourceProcessUserName, SourceProcessName, SourceProcessID, SourceMethodName, SourceVersion, SourceAssemblyName, SourcedbMApplicationName, SourceDbmNode, SourceComputerName, UserTokenID, UserName, UserID, CoordinationID, CoordinationParentID, CoordinationRootID, CoordinationOperations, CoordinationName, CoordinationInitiator)
                              SELECT Event_ID, EventDefID, OccurrenceTime, LogLevel, [Message], EventGroup, EventCategory, EventType, SourceType, SourcePublicKeyToken, SourceProcessUserName, SourceProcessName, SourceProcessID, SourceMethodName, SourceVersion, SourceAssemblyName, SourcedbMApplicationName, SourceDbmNode, SourceComputerName, UserTokenID, UserName, UserID, CoordinationID, CoordinationParentID, CoordinationRootID, CoordinationOperations, CoordinationName, CoordinationInitiator
                              FROM #DILEvent3 AS DL 
                              INNER JOIN dbmSTLRepositoryArchive.dbo.EventLog AS EL WITH(NOLOCK)
                                          ON DL.EventID = EL.EventDefID
                              WHERE OccurrenceTime BETWEEN @EventMinDate AND @EventMaxDate
                                    AND LogLevel = 'Error'

                              --                                        Index on #EventLog.[Event_ID] Field
                              IF NOT EXISTS (SELECT 1 FROM tempdb.sys.objects WHERE [name] = N'PK_#EventLog3_Event_ID' AND [type] = 'PK' and [parent_object_id] = OBJECT_ID('tempdb..#EventLog3'))
                                          ALTER TABLE #EventLog3 ADD 
                                                CONSTRAINT [PK_#EventLog3_Event_ID] PRIMARY KEY CLUSTERED 
                                                (
                                                      [Event_ID]
                                                ) ON [PRIMARY]; 
                                    
                              --                                        All relevant Extended Properties for Events selected below from dbmSTLRepository
                              SELECT B.Event_ID, B.Name, B.Type, LTRIM(RTRIM(B.[Value])) AS [Value]
                              INTO #ExtendedProperties3
                              FROM #EventLog3 AS C
                              INNER JOIN dbmSTLRepository.STLData.ExtendedProperties AS B WITH(NOLOCK)
                                          ON C.Event_ID = B.Event_ID
                              
                              --                                        All relevant Extended Properties for Events selected below from dbmSTLRepositoryArchive
                              INSERT INTO #ExtendedProperties3(Event_ID, [Name], [Type], [Value])
                              SELECT B.Event_ID, B.Name, B.Type, LTRIM(RTRIM(B.[Value]))
                              FROM #EventLog3 AS C
                              INNER JOIN dbmSTLRepositoryArchive.dbo.ExtendedProperties AS B WITH(NOLOCK)
                                          ON C.Event_ID = B.Event_ID

                              --                                        Index on #ExtendedProperties.[Event_ID] Field
                              IF NOT EXISTS(SELECT 1 FROM tempdb.sys.indexes WITH(NOLOCK) WHERE [object_id] = OBJECT_ID('tempdb..#ExtendedProperties3') AND [name] = N'CX_#ExtendedProperties3_Event_ID')
                              CREATE CLUSTERED INDEX CX_#ExtendedProperties3_Event_ID ON #ExtendedProperties3(Event_ID)


                  SELECT      K.MessageID,
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
                              
                              Into #SummaryErrors3
                  FROM #ArchMessageState3 AS A
                  LEFT OUTER JOIN dbmDILMessagesArchive.dbo.ArchMessage AS K WITH(NOLOCK)
                              ON A.BTSInterchangeID = K.BTSInterchangeID
                  INNER JOIN dbmDILMessagesArchive.dbo.luLoadingState As S WITH(NOLOCK)
                              ON A.LoadingState = S.LoadingStateID
                  LEFT OUTER JOIN #ExtendedProperties3 AS B
                              ON A.BTSInterchangeID = B.[Value]
                              AND Name = 'InterchangeId'
                  LEFT JOIN #EventLog3 AS C
                              ON B.Event_ID = C.Event_ID
                  LEFT OUTER JOIN #ExtendedProperties3 AS D
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

set ANSI_Warnings OFF

---
            select @body=@body+
            N'<H2> Message Error Detail </H2>' 
            +      N'<table border="1" style="font-size:12px;">'  +
                  N'<tr><th> Type/Trigger </th>'
						+N'<th>Source</th>'
						+N'<th>Error </th>'
						+N'<th>Error Message in EventLog</th>'
						+N'<th>Internal Error Message</th>'
						+N'<th>Message ID</th>' +
						+N'<th>BTSInterchangeID</th>'
						+N'<th>Archive Time</th>'
						+N'<th>PatientId</th>'
						+
                  CAST ( (
            SELECT      td=cast(MessageType as varchar(3) ) + ' '+cast(MessageTriggerEvent as varchar(3)) ,  '',
                        td=cast(MessageSourceSystem as varchar(15)),  '',
                        td=cast([Error Description]as varchar(75)),  '',
                        td=cast([Error Message in EventLog] as varchar(100)) ,  '',
                        td=cast([InternalErrorMessage] as varchar(400)) ,  '',           
                        td=cast(MessageID as varchar(17)),  '',
                        td=Cast(BTSInterchangeID as varchar(42)),  '',
                        td=cast(ArchTime as varchar(18)) ,  '',
						td=cast(PatientIDExt as varchar(18)) ,  ''
            from #SummaryErrors3
          
            FOR XML PATH('tr'), TYPE 
                  ) AS NVARCHAR(MAX) ) +
                  N'</table>' ;
                  
    IF OBJECT_ID('tempdb..#lastStates3') IS NOT NULL
				drop TABLE #lastStates3
	IF OBJECT_ID('tempdb..#ArchMessageState3') IS NOT NULL
				drop TABLE #ArchMessageState3  
	IF OBJECT_ID('tempdb..#DILEvent3') IS NOT NULL
				drop TABLE #DILEvent3    
	IF OBJECT_ID('tempdb..#SummaryErrors3') IS NOT NULL
				drop TABLE #SummaryErrors3 			     
    IF OBJECT_ID('tempdb..#EventLog3') IS NOT NULL
				drop TABLE #EventLog3    
    IF OBJECT_ID('tempdb..#ExtendedProperties3') IS NOT NULL
				drop TABLE #ExtendedProperties3 			          
                  
END
/**********************************************************************************************/
/**********************************************************************************************/
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
IF OBJECT_ID('tempdb..#SummaryErrors') IS NOT NULL
DROP TABLE #SummaryErrors
/************************************************************************************/
--Begining of Failed Init summary


IF OBJECT_ID('tempdb..#FailInits') IS NOT NULL
				drop TABLE #FailInits

Create Table #FailInits (
	BtsInterchangeid varchar(50) null
	,LeftMessageText varchar(50) null
	,TriggerEvent varchar(50) null
	,ErrorId varchar(255) null
	)
Insert into #FailInits (BtsInterchangeid ,LeftMessageText,TriggerEvent )
	select	 am.btsinterchangeid
		  , left(MessageText,50) 
		  ,am.MessageTriggerEvent

	from dbmDILMessagesArchive.dbo.ArchMessage am  with(index(PK_ArchMessage))
	 where  (am.ArchTime  between @EventMinDate and  @eventMaxDate)
	   and  (am.MessageID is null or am.MessageSourceSystem is null or  am.MessageTriggerEvent is null
		or  am.MessageType is null or  am.MessagePatientIDExt is null or  am.MessagePatientIDRoot is null)

	
update 	#FailInits
	set ErrorId=amx.MaxErrorID
	from 	#FailInits F
    join  (select BTSInterchangeID
				,max(ams.ErrorID)MaxErrorID
			from dbmDILMessagesArchive.dbo.ArchMessageState ams with (index(PK_ArchMessageState))
				 group by BTSInterchangeID) amx
	 on F.BtsInterchangeid=amx.BTSInterchangeID
     
select @body=@body+	
			N'<H2> Message Fail Init Summary </H2>' +
			N'<table border="1">' +
			N'<tr><th>Occurrences</th><th>Start of Failed Init Message</th> ' +
			N'<th>Error</th>' +
			CAST ( (
			select  td=cast( COUNT(f.BtsInterchangeid) as Varchar(10)),   ''
				   ,td=cast( left(f.LeftMessageText,50)as Varchar(50)),   ''
				   ,td=CAST(left(max(f.TriggerEvent),25)as Varchar(25)),   ''
			 from 	#FailInits f
			 group by f.LeftMessageText
		 	order by COUNT(*) desc
			FOR XML PATH('tr'), TYPE 
			  	) AS NVARCHAR(MAX) )
	 +
                  N'</table>' ;
	
	IF OBJECT_ID('tempdb..#FailInits') IS NOT NULL
				drop TABLE #FailInits	

/************************************************************************************/
/* Begin  CareEvent Errors Detail */
If @SendCareEventInfo='Y'
Begin
			create table  #CareEventErrorDetail (
				 ErrorType varchar(20) 
				, Acttype varchar(15)
				,ActExtension varchar(15) 
				,PatientExtension varchar(15)
				,ControlActID varchar(10)
				,MessageID varchar(10) 
				,InterchangeID varchar(38)
				) 

			insert into #CareEventErrorDetail
			SELECT  
				 cast (lute.TrackingError as varchar(20)) ErrorType
				,cast(lucet.CareEventTypeCode as varchar(15)) Acttype
			--	,cast(E.Id_Root as varchar(45))ActRoot
				,cast(E.Id_Extension as varchar(15)) ActExtension
			--	,cast(PID.Root as varchar(45)) PatientRoot
				,cast(PID.Extension  as varchar(15))PatientExtension
				,cast(E.ControlActID as varchar(10))ControlActID
				,cast(ca.MessageID as varchar(10)) MessageID
				,cast(m.InterchangeID as varchar(38)) InterchangeID
			--	,StatusUpdateDate
			FROM         dbmVCDRData.PatientAdministration.Encounter AS E 
			INNER JOIN  dbmInternalData.Tracking.CareEventDataWrapper AS C 
						 ON E.Id_Root = C.RefId_Root 
						AND E.Id_Extension = C.RefId_Extension 
						AND C.CareEventTypeId = 1
						AND TrackingErrorId not IN(5)
						AND E.IsVirtual=0
			 join dbmInternalData.Common.LuCareEventType lucet
			 on c.CareEventTypeId=lucet.CareEventTypeId
			join dbmInternalData.Tracking.LuTrackingError lute
			 on c.TrackingErrorId=lute.TrackingErrorId
			INNER JOIN	dbmVCDRData.PatientAdministration.PatientIdentifier PID
			ON PID.PatientRecordID=E.PatientRecordID
			AND PID.IsPrimary=1
			join dbmVCDRData.MessageWrapper.ControlAct ca on E.ControlActID=ca.ControlActID
			join dbmVCDRData.MessageWrapper.Message m on ca.MessageID=m.MessageID
			 Where StatusUpdateDate>@EventMinDate  and StatusUpdateDate<@EventMaxDate 
			 
			 /*************************/
			UNION 
			SELECT   
				 cast (lute.TrackingError as varchar(20)) ErrorType
				,cast(lucet.CareEventTypeCode as varchar(15)) Acttype
			--	,cast(E.Id_Root as varchar(45))ActRoot
				,cast(E.Id_Extension as varchar(15)) ActExtension
			--	,cast(PID.Root as varchar(45)) PatientRoot
				,cast(PID.Extension  as varchar(15))PatientExtension
				,cast(E.ControlActID as varchar(10))ControlActID
				,cast(ca.MessageID as varchar(10)) MessageID
				,cast(m.InterchangeID as varchar(38)) InterchangeID
			--	,StatusUpdateDate
			FROM         dbmVCDRData.ClinicalDocument.ClinicalDocument AS E 
			INNER JOIN   dbmInternalData.Tracking.CareEventDataWrapper AS C 
						 ON E.Id_Root = C.RefId_Root 
						AND E.Id_Extension = C.RefId_Extension 
					AND C.CareEventTypeId = 3
					AND TrackingErrorId not IN(5)
						AND E.IsVirtual=0
						 join dbmInternalData.Common.LuCareEventType lucet
			 on c.CareEventTypeId=lucet.CareEventTypeId
			join dbmInternalData.Tracking.LuTrackingError lute
			 on c.TrackingErrorId=lute.TrackingErrorId
			INNER JOIN	dbmVCDRData.PatientAdministration.PatientIdentifier PID
			ON PID.PatientRecordID=E.PatientRecordID
			AND PID.IsPrimary=1		
			join dbmVCDRData.MessageWrapper.ControlAct ca on E.ControlActID=ca.ControlActID
			join dbmVCDRData.MessageWrapper.Message m on ca.MessageID=m.MessageID
			 Where StatusUpdateDate>@EventMinDate  and StatusUpdateDate<@EventMaxDate 
			 /*************************/
			UNION 
			SELECT    
				 cast (lute.TrackingError as varchar(20)) ErrorType
				,cast(lucet.CareEventTypeCode as varchar(15)) Acttype
			--	,cast(E.Id_Root as varchar(45))ActRoot
				,cast(E.Id_Extension as varchar(15)) ActExtension
			--	,cast(PID.Root as varchar(45)) PatientRoot
				,cast(PID.Extension  as varchar(15))PatientExtension
				,cast(E.ControlActID as varchar(10))ControlActID
				,cast(ca.MessageID as varchar(10)) MessageID
				,cast(m.InterchangeID as varchar(38)) InterchangeID
			--	,StatusUpdateDate
			FROM         dbmVCDRData.Imaging.ImagingStudy AS E 
			INNER JOIN  dbmInternalData.Tracking.CareEventDataWrapper AS C 
						 ON E.Id_Root = C.RefId_Root 
						AND E.Id_Extension = C.RefId_Extension 
						AND C.CareEventTypeId = 2
						AND TrackingErrorId not IN(5)
						AND E.IsVirtual=0
			 join dbmInternalData.Common.LuCareEventType lucet
			 on c.CareEventTypeId=lucet.CareEventTypeId
			join dbmInternalData.Tracking.LuTrackingError lute
			 on c.TrackingErrorId=lute.TrackingErrorId
			INNER JOIN	dbmVCDRData.PatientAdministration.PatientIdentifier PID
			ON PID.PatientRecordID=E.PatientRecordID
			AND PID.IsPrimary=1		
			join dbmVCDRData.MessageWrapper.ControlAct ca on E.ControlActID=ca.ControlActID
			join dbmVCDRData.MessageWrapper.Message m on ca.MessageID=m.MessageID
			 Where StatusUpdateDate>@EventMinDate  and StatusUpdateDate<@EventMaxDate 
			 /*************************/
			UNION 
			SELECT    
				cast (lute.TrackingError as varchar(20)) ErrorType
				,cast(lucet.CareEventTypeCode as varchar(15)) Acttype
			--	,cast(E.Id_Root as varchar(45))ActRoot
				,cast(E.Id_Extension as varchar(15)) ActExtension
			--	,cast(PID.Root as varchar(45)) PatientRoot
				,cast(PID.Extension  as varchar(15))PatientExtension
				,cast(E.ControlActID as varchar(10))ControlActID
				,cast(ca.MessageID as varchar(10)) MessageID
				,cast(m.InterchangeID as varchar(38)) InterchangeID
			--	,StatusUpdateDate
			FROM         dbmVCDRData.Laboratory.LaboratoryEvent AS E 
			INNER JOIN dbmInternalData.Tracking.CareEventDataWrapper AS C 
						 ON E.Id_Root = C.RefId_Root 
						AND E.Id_Extension = C.RefId_Extension 
						AND C.CareEventTypeId = 4
						AND TrackingErrorId not IN(5)
						AND E.IsVirtual=0
			 join dbmInternalData.Common.LuCareEventType lucet
			 on c.CareEventTypeId=lucet.CareEventTypeId
			join dbmInternalData.Tracking.LuTrackingError lute
			 on c.TrackingErrorId=lute.TrackingErrorId
			INNER JOIN	dbmVCDRData.PatientAdministration.PatientIdentifier PID
			ON PID.PatientRecordID=E.PatientRecordID
			AND PID.IsPrimary=1		
			join dbmVCDRData.MessageWrapper.ControlAct ca on E.ControlActID=ca.ControlActID
			join dbmVCDRData.MessageWrapper.Message m on ca.MessageID=m.MessageID
			 Where StatusUpdateDate>@EventMinDate  and StatusUpdateDate<@EventMaxDate 
			  
			  
			  select @body=@body+
			 N'<H2> CareEvent Errors </H2>' +
				N'<table border="1">' +
				N'<tr><th> Error Type </th><th> ActType </th><th>Act Extension</th><th> Patient Extension </th><th>ControlActID</th><th> MessageID </th><th>InterchangeID</th>' +
				CAST ( (
			  
			  select  td=    ErrorType,'' 
				,td= Acttype,'' 
				,td= ActExtension,''  
				,td= PatientExtension,''
				,td= ControlActID,''
				,td= MessageID,''
				,td= InterchangeID,''
			  from #CareEventErrorDetail
			  
			  
			  
					FOR XML PATH('tr'), TYPE 
				) AS NVARCHAR(MAX) ) +
				N'</table>' ;
    
END    
select @body=@body+CHAR(10)+CHAR(13) 
/***************** Free space left *********************/ 
		if OBJECT_ID('tempdb..#freespace') is not null
		drop table #freespace
--
		CREATE Table #freespace( 
			        drive varchar(1),
					[MB Free] int
					)
--    
		insert into #freespace
		EXEC master..xp_fixeddrives
		select @body= @body+CHAR(10)+CHAR(13)+N'<H3> Free Space Drive '+' '
		select   @body=@body +coalesce('', '')+drive + ': '+ cast([MB Free] as varchar(10))+'MB'+'    '		  from #freespace 
		select @body= @body+CHAR(10)+CHAR(13)+'</H3>'
 /***************** END Free space left *********************/ 
 /***************** Begin of Execution time *********************/ 
	select @body=@body + CHAR(10)+CHAR(13)+N'<H4>'
	select @body=@body + 'Executed from server: ' + @@SERVERNAME + CHAR(10)+CHAR(13)
	select @processEnd = getdate()
	select @body=@body + CHAR(10)+CHAR(13)+'This query took ' + CAST(DATEDIFF(MILLISECOND , @processStart , @processEnd) as varchar(10)) +  N' ms to run.' + '<br>' + CHAR(10)+CHAR(13)
	select @body= @body+CHAR(10)+CHAR(13)+'</H4>'
 --	select N'This query took ' + CAST(DATEDIFF(microsecond , @processStart , @processEnd) as varchar(10)) +  N' ms to run.' + '<br>' + CHAR(10)+CHAR(13)
 /***************** END Execution time *********************/  
  -- select @body

	exec msdb..sp_send_dbmail 
		@profile_name=@profile_Name,
		@recipients=@recipients,

	 --  @copy_recipients='mySecondEmail?whoknows.com',
	     @subject=@eSubject,
   		 @body_format= 'HTML',
   		 @body=@body

IF OBJECT_ID('tempdb..#lastStates2') IS NOT NULL
DROP TABLE #lastStates2
IF OBJECT_ID('tempdb..#ArchMessageState2') IS NOT NULL
DROP TABLE #ArchMessageState2
IF OBJECT_ID('tempdb..#EventLog2') IS NOT NULL
DROP TABLE #EventLog2
IF OBJECT_ID('tempdb..#ExtendedProperties2') IS NOT NULL
DROP TABLE #ExtendedProperties2
IF OBJECT_ID('tempdb..#DILEvent2') IS NOT NULL
DROP TABLE #DILEvent2	
IF OBJECT_ID('tempdb..#SummaryErrors2') IS NOT NULL
DROP TABLE #SummaryErrors2	
IF OBJECT_ID('tempdb..#CareEventErrorDetail') IS NOT NULL
DROP TABLE #CareEventErrorDetail



   		