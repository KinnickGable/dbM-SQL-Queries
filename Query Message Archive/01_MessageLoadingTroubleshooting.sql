--***********************************************
--- *** dbmDILMessagesArchive  *** ---
USE dbmDILMessagesArchive
go
DECLARE @LAST_INTERCHANGE_ID AS  varchar(50);
DECLARE @INTERCHANGE_ID AS  varchar(50);
DECLARE @ID_EXTENSION AS  varchar(50);

SET  @LAST_INTERCHANGE_ID = (
                           SELECT     TOP (1) BTSInterchangeID
                           FROM         ArchMessage WITH(NOLOCK)
                           ORDER BY ArchTime DESC
                        );
--SET  @INTERCHANGE_ID = @LAST_INTERCHANGE_ID
SET  @INTERCHANGE_ID = '69e42c02-bb9a-47a5-8e21-45aa6b82f5ca'

--********************* PRESENT LAST ARCHIVE MESSAGE DETAILS ************************
--- *** ArchMessage  *** ---
SELECT [INFO] = 'Information from dbmDILMessagesArchive.ArchMessage table'


SELECT     TOP (1) ArchTime, BTSInterchangeID
, arch.MessageID
,arch.MessageSourceSystem
, arch.MessageType
, arch.MessageTriggerEvent
,arch.MessageFormat
,arch.ReplacingMessageArchiveID
, arch.MessageText
,arch.MessagePatientIDRoot
,arch.MessagePatientIDExt
FROM         ArchMessage arch WITH(NOLOCK)
WHERE  (BTSInterchangeID = @INTERCHANGE_ID);

--- *** Reply Info  *** ---
SELECT 
b.ArchTime as 'Reply time'
--,a.BTSInterchangeID as 'Orig BTSInterchangeID'
--,a.ArchMessageID as 'Orig ArchMessageID'
--, a.MessageText as 'Orig Msg'
--,a.ArchTime as 'Orig time'
,a.ReplacingMessageArchiveID
, b.BTSInterchangeID as 'Replay BTSInterchangeID'
,b.MessageText as 'Reply Msg'

FROM dbo.ArchMessage a
LEFT JOIN dbo.ArchMessage b
ON a.ReplacingMessageArchiveID = b.ArchMessageID
where a.BTSInterchangeID = @INTERCHANGE_ID

--***************************** PRESENT  ALL LOADING STATES FOR LAST  MESSAGE  ***************
--- *** ArchMessageState  *** ---
SELECT [INFO] = 'Information about all message states from ArchMessageState'

SELECT     ArchMessageState.ArchMessageStateID, ArchMessageState.LoadingState, luLoadingState.LoadingStateName, 
                      ArchMessageState.BTSInterchangeID, ArchMessageState.LoadingStateDate, ArchMessageState.ErrorID,DILEventDesignation.ErrorMessage
FROM         ArchMessageState WITH (NOLOCK) INNER JOIN
                      luLoadingState ON ArchMessageState.LoadingState = luLoadingState.LoadingStateID LEFT JOIN
                            dbmVCDRStage.Common.DILEventDesignation ON ArchMessageState.ErrorID = dbmVCDRStage.Common.DILEventDesignation.EventID
WHERE     (ArchMessageState.BTSInterchangeID = @INTERCHANGE_ID);

--***********************************************
--- *** MessageWrapper  *** ---
SELECT [INFO] = 'Information from dbmVCDRData.MessageWrapper table'

USE dbmVCDRData

SELECT       MessageWrapper.Message.CreationTime, MessageWrapper.Message.Id_Extension, MessageWrapper.Message.InterchangeID,MessageWrapper.Message.IsVirtual, MessageWrapper.ControlAct.ControlActID
FROM         MessageWrapper.Message  INNER JOIN
                      MessageWrapper.ControlAct ON MessageWrapper.Message.MessageID = MessageWrapper.ControlAct.MessageID
WHERE (InterchangeID = @INTERCHANGE_ID);

SET  @ID_EXTENSION = (
                           SELECT      Id_Extension
                           FROM         MessageWrapper.Message
                           WHERE (InterchangeID = @INTERCHANGE_ID)
                        );

--************************ STL EVENTS AND EXT Prop**********************
-- Ask for all events that are errors and in the ext prop they are related to the wanted BTSint:
SELECT [INFO] = 'Information about errors from dbmSTLRepository'

USE dbmSTLRepository

-- *** QUERY 01 - Find relevant events ID and insert to temp table*************
IF OBJECT_ID('tempdb..#TempEventTable') IS NOT NULL
drop table #TempEventTable
IF OBJECT_ID('tempdb..#TepmEventTable2') IS NOT NULL
drop table #TepmEventTable2

SELECT     Ex.Event_ID
INTO  #TepmEventTable
FROM        STLData.ExtendedProperties AS Ex 
                           INNER JOIN STLData.EventLog AS El
                                  ON El.Event_ID = Ex.Event_ID
WHERE Ex.Name = 'InterchangeId' AND   Ex.Value = @INTERCHANGE_ID AND El.LogLevel = N'Error'  



-- *** QUERY 02 - Display relevant events info*******
SELECT     Event_ID, EventDefID, OccurrenceTime, LogLevel, Message, EventGroup, EventCategory, EventType, SourceType, SourcePublicKeyToken, 
                      SourceProcessUserName, SourceProcessName, SourceProcessID, SourceMethodName, SourceVersion, SourceAssemblyName, 
                      SourcedbMApplicationName, SourceDbmNode, SourceComputerName, UserTokenID, UserName, UserID, CoordinationID, CoordinationParentID, 
                      CoordinationRootID, CoordinationOperations, CoordinationName, CoordinationInitiator
FROM         STLData.EventLog AS El
WHERE       ( El.Event_ID IN (  
							select Event_ID
							from #TepmEventTable
                           )
													  
              )  
ORDER BY OccurrenceTime DESC


-- *** QUERY 03 - display ralated ExtendedProperties***************************************
SELECT [INFO] = 'Error ralated ExtendedProperties from STL'
SELECT *
FROM        STLData.ExtendedProperties AS Ex
WHERE Ex.Event_ID IN (  
					    select Event_ID
						from #TepmEventTable
                      )


drop table #TepmEventTable
--************************** STL Archive *******************
SELECT [INFO] = 'Information about errors from dbmSTLRepositoryArchive'
use dbmSTLRepositoryArchive

SELECT     Ex.Event_ID
INTO  #TepmEventTable2
FROM        dbo.ExtendedProperties AS Ex 
                           INNER JOIN dbo.EventLog AS El
                                  ON El.Event_ID = Ex.Event_ID
WHERE Ex.Name = 'InterchangeId' AND   Ex.Value = @INTERCHANGE_ID AND El.LogLevel = N'Error' 
-- *** QUERY 04 - Display relevant events info*******
SELECT     Event_ID, EventDefID, OccurrenceTime, LogLevel, Message, EventGroup, EventCategory, EventType, SourceType, SourcePublicKeyToken, 
                      SourceProcessUserName, SourceProcessName, SourceProcessID, SourceMethodName, SourceVersion, SourceAssemblyName, 
                      SourcedbMApplicationName, SourceDbmNode, SourceComputerName, UserTokenID, UserName, UserID, CoordinationID, CoordinationParentID, 
                      CoordinationRootID, CoordinationOperations, CoordinationName, CoordinationInitiator
FROM         dbo.EventLog AS El
WHERE       ( El.Event_ID IN (  
							select Event_ID
							from #TepmEventTable2
                           )
													  
              )  
ORDER BY OccurrenceTime DESC


-- *** QUERY 05 - display ralated ExtendedProperties***************************************
SELECT [INFO] = 'Error ralated ExtendedProperties from STL Archive'
SELECT *
FROM        dbo.ExtendedProperties AS Ex
WHERE Ex.Event_ID IN (  
					    select Event_ID
						from #TepmEventTable2
                      )


drop table #TepmEventTable2