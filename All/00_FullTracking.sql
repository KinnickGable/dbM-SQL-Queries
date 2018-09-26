USE dbmVCDRData
go
SELECT     TOP (2) CreationTime, Id_Extension, InterchangeID
FROM         MessageWrapper.Message
ORDER BY CreationTime DESC
--***********************************************
USE dbmVCDRData
go

DECLARE @INTERCHANGE_ID AS  varchar(50);

SET  @INTERCHANGE_ID = (
                           SELECT TOP (1) InterchangeID
                           FROM  MessageWrapper.Message
                           ORDER BY CreationTime DESC
                        );
--SET  @INTERCHANGE_ID = '106415b0-2689-4c4e-af87-54532c36963c'

USE dbmDILMessagesArchive

SELECT     ArchMessageState.ArchMessageStateID, ArchMessageState.LoadingState, luLoadingState.LoadingStateName AS Expr1, 
                      ArchMessageState.BTSInterchangeID, ArchMessageState.LoadingStateDate, ArchMessageState.ErrorID
FROM         ArchMessageState WITH (NOLOCK) INNER JOIN
                      luLoadingState ON ArchMessageState.LoadingState = luLoadingState.LoadingStateID
WHERE     (ArchMessageState.BTSInterchangeID = @INTERCHANGE_ID)

--***********************************************

USE dbmSTLRepository

SELECT     *, OccurrenceTime AS Expr1
FROM         STLData.EventLog
ORDER BY Expr1 DESC
--***********************************************
SELECT     STLData.EventLog.Event_ID, STLData.EventLog.EventDefID, STLData.ExtendedProperties.Name, STLData.ExtendedProperties.Type, 
                      STLData.ExtendedProperties.Value, STLData.EventLog.OccurrenceTime
FROM         STLData.EventLog INNER JOIN
                      STLData.ExtendedProperties ON STLData.EventLog.Event_ID = STLData.ExtendedProperties.Event_ID
ORDER BY STLData.EventLog.OccurrenceTime DESC
--***********************************************