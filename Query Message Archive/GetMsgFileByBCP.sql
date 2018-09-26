/*
Author: Alen
Creation Date: 2010-02-05
Description: Creates message files on Data server from query result.
File name contains Autonumber and MessageID
File will be created with UTF-8 encoding if message contains unicode characters,
	 else it will be created with ANSI encoding

Important!
All message files will be created in Data server using bcp command, then it can be used by admin only.
Before running check:
	1. if you're administrator on Data server
	2. check if folder is exists
	3. check amount of rows returned by query(very important). 
		Recommendation create no more than 100 messages in one execution
*/

USE dbmDILMessagesArchive
GO
set transaction isolation level read uncommitted

declare @autoNumber int,
		@counter varchar(10),
		@MessageID varchar(255),
		@MessageTxt varchar(max),
		@strQuery nvarchar(255),
		@bcpQuery varchar(255),
		@DataServerFolder varchar(255)

SELECT  @autoNumber = 0,
	    @counter = '000',
		@DataServerFolder = 'C:\dbMotionInstallations\DataTeamStaff\Messages\'

IF OBJECT_ID('dbo.AD_MessagesList') IS NOT NULL DROP TABLE dbo.AD_MessagesList
CREATE TABLE dbo.AD_MessagesList(MessageID varchar(255),MessageText varchar(max))

------------------------------------------------Query-------------------------------------------------------------

INSERT INTO dbo.AD_MessagesList(MessageID, MessageText)
SELECT MessageID, MessageText
from dbo.ArchMessage with(nolock)
where BTSInterchangeID IN (
'5f2a3018-61d6-4209-9e5e-a9da9626ab07',
'78bf929a-18c5-4e1f-9ea3-c0e66e098adf'
)

----------------------------------------------BCP Command---------------------------------------------------------
IF OBJECT_ID('dbo.MessageText_T') IS NOT NULL
DROP TABLE dbo.MessageText_T

CREATE TABLE dbo.MessageText_T(
MessageText varchar(max)
)

DECLARE msg_cursor CURSOR FOR  
select MessageID,MessageText
from dbo.AD_MessagesList

OPEN msg_cursor   
FETCH NEXT FROM msg_cursor INTO @MessageID, @MessageTxt

WHILE @@FETCH_STATUS = 0   
BEGIN
	SET @autoNumber = @autoNumber + 1
	SET @counter = RIGHT('000' + CONVERT(varchar(10),@autoNumber),3)
	SET @strQuery = 'SELECT MessageText FROM dbo.AD_MessagesList WHERE MessageID = ''' + @MessageID + ''''

	INSERT INTO dbo.MessageText_T
	EXEC sp_executesql @strQuery


SET @bcpQuery = 'bcp "SELECT MessageText FROM dbmDILMessagesArchive.dbo.MessageText_T" queryout ' + @DataServerFolder + '' + @counter + '_' + @MessageID +'.txt -T -c'
exec master..xp_cmdshell @bcpQuery

	TRUNCATE TABLE dbo.MessageText_T

       FETCH NEXT FROM msg_cursor INTO @MessageID, @MessageTxt
END   

CLOSE msg_cursor   
DEALLOCATE msg_cursor 


IF OBJECT_ID('dbo.AD_MessagesList') IS NOT NULL
DROP TABLE dbo.AD_MessagesList
IF OBJECT_ID('dbo.MessageText_T') IS NOT NULL
DROP TABLE dbo.MessageText_T
