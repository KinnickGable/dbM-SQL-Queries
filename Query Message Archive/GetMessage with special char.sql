

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 
SELECT [MessageID],MessageText
      
  FROM [dbmDILMessagesArchive].[dbo].[ArchMessage]
  where ArchTime>='2011-4-14 08:00' and ArchTime <='2011-4-14 10:00' and  [MessageText] like '%' + CHAR(0x01) + '%'
GO
