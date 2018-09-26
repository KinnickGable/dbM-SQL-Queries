/*
Author: Alen
Creation Date: 2010-02-05
Description: Creates message files on Data server from query result.
File name contains Autonumber and BTSInterchangeID
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
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare @autoNumber int,
		@counter varchar(10),
		@MessageTxt varchar(max),
		@BTSInterchangeID varchar(50),
		@strQuery nvarchar(255),
		@bcpQuery varchar(255),
		@DataServerFolder varchar(255)

SELECT  @autoNumber = 0,
	    @counter = '000',
		@DataServerFolder = 'C:\dbMotionInstallations\DataTeamStaff\Messages\'

IF OBJECT_ID('tempdb..#InterchangeIds') IS NOT NULL
DROP TABLE #InterchangeIds

CREATE TABLE #InterchangeIds
(
      BTSInterchangeID varchar(50)
)

-----------------------------------------Query-----------------------------------------
INSERT INTO #InterchangeIds 
SELECT DISTINCT BTSInterchangeID
FROM dbo.ArchMessageState
WHERE BTSInterchangeID IN(
'288071f6-2d46-4495-ae24-6967ecc0e274',
'e50dcb72-dc8f-40b9-ada7-3c35d8147b03',
'b7189267-b031-4aab-9bf1-b42399e72d1b'

)
----------------------------------Getting Message Text from STL----------------------------------------

IF OBJECT_ID('dbo.AD_MessagesList') IS NOT NULL
DROP TABLE dbo.AD_MessagesList

CREATE TABLE dbo.AD_MessagesList(
MessageText varchar(max),
BTSInterchangeID varchar(50)
)

INSERT INTO dbo.AD_MessagesList
SELECT B.[Value] as MessageText, #InterchangeIds.BTSInterchangeID
FROM #InterchangeIds
	 inner join dbmSTLRepositoryArchive.dbo.ExtendedProperties A
		on #InterchangeIds.BTSInterchangeID = A.[Value]
	 inner join dbmSTLRepositoryArchive.dbo.ExtendedProperties B
		on A.Event_ID = B.Event_ID
where A.[Name] = 'InterchangeId'
	  AND B.[Name] = 'MessageText'

------------------------------------------BCP Command-----------------------------

IF OBJECT_ID('dbo.MessageText_T') IS NOT NULL
DROP TABLE dbo.MessageText_T

CREATE TABLE dbo.MessageText_T(
MessageText varchar(max)
)

DECLARE msg_cursor CURSOR FOR  
select MessageText, BTSInterchangeID
from dbo.AD_MessagesList

OPEN msg_cursor   
FETCH NEXT FROM msg_cursor INTO @MessageTxt, @BTSInterchangeID

WHILE @@FETCH_STATUS = 0   
BEGIN
	SET @autoNumber = @autoNumber + 1
	SET @counter = RIGHT('000' + CONVERT(varchar(10),@autoNumber),3)
	SET @strQuery = 'SELECT MessageText FROM dbo.AD_MessagesList WHERE BTSInterchangeID = ''' +  @BTSInterchangeID + ''''

	INSERT INTO dbo.MessageText_T
	EXEC sp_executesql @strQuery

SET @bcpQuery = 'bcp "SELECT MessageText FROM dbmDILMessagesArchive.dbo.MessageText_T" queryout '+ @DataServerFolder + '' + @counter + '_' + @BTSInterchangeID + '.txt -T -c -C65001'
exec master..xp_cmdshell @bcpQuery

	TRUNCATE TABLE dbo.MessageText_T

       FETCH NEXT FROM msg_cursor INTO @MessageTxt, @BTSInterchangeID
END   

CLOSE msg_cursor   
DEALLOCATE msg_cursor 

-----------------------------------------------------------------------------------------
IF OBJECT_ID('dbo.MessageText_T') IS NOT NULL
DROP TABLE dbo.MessageText_T
IF OBJECT_ID('dbo.AD_MessagesList') IS NOT NULL
DROP TABLE dbo.AD_MessagesList
IF OBJECT_ID('tempdb..#InterchangeIds') IS NOT NULL
DROP TABLE #InterchangeIds



