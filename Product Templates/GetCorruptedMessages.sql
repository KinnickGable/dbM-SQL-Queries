/*
Author: Alen
Creation Date: 2010-02-27
Description: Returns amount of messages loaded in last 24 hours and contains symbol "?" in the message text. 
*/

USE dbmDILMessagesArchive
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare @MinDate datetime,
		@MaxDate datetime

declare @minArchMessageID bigint
declare @maxArchMessageID bigint
declare @chunkSize int
declare @MsgCount int

--set @MaxDate = GETDATE()
/*@MaxDate needs to be defined hardcoded, becouse it have to be the same in all scripts*/
set @MaxDate = '2010-03-01'

set @MinDate = DATEADD(dd,-1,@MaxDate)

set @MsgCount = 0
set @chunkSize = 10000

--select @minArchMessageID = MIN(ArchMessageID) from dbo.ArchMessage where ArchTime > @MinDate
--
--select @maxArchMessageID = MAX(ArchMessageID) from dbo.ArchMessage where ArchTime < @MaxDate


/*by Alex C recommendation --> find MIN(ControlActID) and MAX(ControlActID) by one select */
select 
	@minArchMessageID = MIN(ArchMessageID),
	@maxArchMessageID = MAX(ArchMessageID)
from dbo.ArchMessage 
where ArchTime > @MinDate
and ArchTime < @MaxDate


--select @minArchMessageID,@maxArchMessageID

while @minArchMessageID <= @maxArchMessageID
begin 
	SELECT @MsgCount = @MsgCount + count(MessageText)
	FROM dbo.ArchMessage (nolock)
	WHERE ArchMessageID > @minArchMessageID 
		  and ArchMessageID < (@minArchMessageID + @chunkSize + 1) 
		  and MessageText like '%?%'

	set @minArchMessageID = @minArchMessageID + @chunkSize
end

select @MsgCount as MessageText
GO


