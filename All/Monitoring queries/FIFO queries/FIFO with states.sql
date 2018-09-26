use dbmDILFIFOQueue

SELECT     dbmDILMessagesArchive.dbo.ArchMessageState.BTSInterchangeID, MAX(dbmDILMessagesArchive.dbo.ArchMessageState.LoadingState) 
                      AS [max state]
FROM         FIFOQueue INNER JOIN
                      dbmDILMessagesArchive.dbo.ArchMessageState ON 
                      FIFOQueue.InterchangeID = dbmDILMessagesArchive.dbo.ArchMessageState.BTSInterchangeID
GROUP BY dbmDILMessagesArchive.dbo.ArchMessageState.BTSInterchangeID
ORDER BY [max state] DESC