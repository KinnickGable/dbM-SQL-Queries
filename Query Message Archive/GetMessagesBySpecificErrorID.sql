USE dbmDILMessagesArchive
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


DECLARE @ErrorID varchar(255),
		@MinDate datetime,
		@MaxDate datetime

SELECT  @ErrorID = '55051',
		@MinDate = '2007-01-12',
		@MaxDate = '2008-11-02'

--Jan 12, 2007 through Nov. 02, 2008. 

DECLARE @MinArchMessageStateID bigint,
		@MaxArchMessageStateID bigint,
		@ChunkSize int

SELECT  @MinArchMessageStateID = MIN(ArchMessageStateID) - 1,
		@MaxArchMessageStateID = MAX(ArchMessageStateID),
		@ChunkSize = 50000
FROM dbo.ArchMessageState with(nolock)
WHERE LoadingStateDate > @MinDate and LoadingStateDate < @MaxDate


IF @MinArchMessageStateID is null 
	SELECT 'No messages were loaded in this period of time.' as [Message]
ELSE
BEGIN

IF OBJECT_ID('tempdb..#DSTFailedMessages') IS NOT NULL
DROP TABLE #DSTFailedMessages

CREATE TABLE #DSTFailedMessages(
BTSInterchangeID uniqueidentifier, 
ErrorID varchar(255)
)


PRINT 'Proceeding messages from ArchMessageStateID ' + CONVERT(varchar(30), @MinArchMessageStateID) + ' >> ' + CONVERT(varchar(30), @MaxArchMessageStateID)


WHILE @MinArchMessageStateID < @MaxArchMessageStateID
BEGIN

PRINT 'Proceeding messages from ArchMessageID ' + CONVERT(varchar(30), @MinArchMessageStateID) + ' >> ' + CONVERT(varchar(30), (@MinArchMessageStateID + @ChunkSize))

INSERT INTO #DSTFailedMessages
SELECT  BTSInterchangeID, 
		ErrorID
FROM  ArchMessageState S with(nolock)
WHERE ArchMessageStateID > @MinArchMessageStateID 
	  AND ArchMessageStateID < (@MinArchMessageStateID + @ChunkSize + 1) 
	  AND ErrorID = @ErrorID


SET @MinArchMessageStateID = (@MinArchMessageStateID + @ChunkSize)

END


CREATE INDEX DSTFailedMessages_BTSInterchangeID ON #DSTFailedMessages(BTSInterchangeID)


SELECT  F.BTSInterchangeID, 
		F.ErrorID, 
		M.MessageSourceSystem, 
		M.MessageType, 
		M.MessageTriggerEvent, 
		M.MessageText, 
		M.ArchTime
FROM #DSTFailedMessages F
	 left join dbo.ArchMessage M with(nolock)
		on F.BTSInterchangeID = M.BTSInterchangeID

IF OBJECT_ID('tempdb..#DSTFailedMessages') IS NOT NULL
DROP TABLE #DSTFailedMessages

END