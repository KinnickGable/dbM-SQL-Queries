USE dbmDILMessagesArchive
GO

set transaction isolation level read uncommitted

DECLARE @PatIdRoot VARCHAR(100) 
DECLARE @PatIdExt VARCHAR(100)
DECLARE @EventMaxDate DATETIME
DECLARE @EventMinDate DATETIME

--- *** Queries Parameters  *** ---
SET @PatIdRoot='2.16.840.1.113883.3.57.1.3.15.1.4.1.8.1' 
SET @PatIdExt='000014704'
SET @EventMaxDate = GETDATE()
SET @EventMinDate = '2010-01-01'

--- *** Chunck Mechanizm Parameters  *** ---
DECLARE @MinArchMessageID bigint
DECLARE @MaxArchMessageID bigint
DECLARE @ChunkSize int

SET @ChunkSize = 10000

SELECT  @MinArchMessageID = MIN(ArchMessageID),
            @MaxArchMessageID = MAX(ArchMessageID)
FROM dbo.ArchMessage with(nolock)
WHERE ArchTime > @EventMinDate
        AND ArchTime < @EventMaxDate


IF OBJECT_ID('tempdb..#PatMessages') IS NOT NULL
DROP TABLE #PatMessages

CREATE TABLE #PatMessages(
BTSInterchangeID varchar(50),
ArchTime datetime,
MessageID varchar(255),
MessageSourceSystem varchar(255),
MessageType varchar(50),
MessageTriggerEvent varchar(50),
MessageText varchar(max),
MessagePatientIDRoot varchar(128),
MessagePatientIDExt varchar(255)
)


WHILE @MinArchMessageID < @MaxArchMessageID
BEGIN
      PRINT 'Processing dbo.ArchMessage from ArchMessageID = ' + CAST(@MinArchMessageID as varchar(15)) + ' to ArchMessageID = ' + CAST(@MaxArchMessageID as varchar(15))

      INSERT INTO #PatMessages
      SELECT 
      A.BTSInterchangeID,
      A.ArchTime,
      A.MessageID,
      A.MessageSourceSystem,
      A.MessageType,
      A.MessageTriggerEvent,
      A.MessageText,
      A.MessagePatientIDRoot,
      A.MessagePatientIDExt
      FROM dbo.ArchMessage A WITH(NOLOCK)
      WHERE A.ArchMessageID > @MinArchMessageID
              AND A.ArchMessageID <  @MinArchMessageID + @ChunkSize
              AND A.MessagePatientIDExt= @PatIdExt
              AND A.MessagePatientIDRoot = @PatIdRoot

      SET @MinArchMessageID = @MinArchMessageID + @ChunkSize
END


SELECT
A.BTSInterchangeID,
A.ArchTime,
AMS.LoadingStateDate as CurrentStateDate,
A.MessageID,
A.MessageSourceSystem,
A.MessageType,
A.MessageTriggerEvent,
S.LoadingStateName as LastLoadingState,
A.MessageText,
A.MessagePatientIDRoot,
A.MessagePatientIDExt
FROM #PatMessages A
        INNER JOIN [dbo].[ArchMessageState] AMS WITH (NOLOCK)
            ON A.BTSInterchangeID = AMS.BTSInterchangeID
      INNER JOIN
           (SELECT BTSInterchangeID,MAX([ArchMessageStateID]) MaxID
            FROM [dbo].[ArchMessageState] WITH (NOLOCK)
            GROUP BY BTSInterchangeID) as lastStates 
                        ON AMS.[ArchMessageStateID]=lastStates.MaxID
      LEFT JOIN dbo.luLoadingState S WITH(NOLOCK)
            ON AMS.LoadingState = S.LoadingStateID
ORDER BY A.ArchTime


IF OBJECT_ID('tempdb..#PatMessages') IS NOT NULL
DROP TABLE #PatMessages
