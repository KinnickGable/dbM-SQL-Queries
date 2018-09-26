USE dbmDILMessagesArchive
GO
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
------------------------- DECLARATION AREA
DECLARE @EventMaxDate DATETIME,
            @EventMinDate DATETIME

IF OBJECT_ID('tempdb..#DuplicateMessages') IS NOT NULL
DROP TABLE #DuplicateMessages


-------------------------- INITIAL AREA
SELECT  -->> (-1) parameter means from yesterday 
            @EventMaxDate = GETDATE(),
            @EventMinDate = DATEADD(yy,-1,GETDATE())

SELECT distinct L.MessageID, L.MessageSourceSystem
INTO #DuplicateMessages
FROM  dbmDILMessagesArchive.dbo.ArchMessageState AS P WITH(NOLOCK)
      INNER JOIN dbmDILMessagesArchive.dbo.ArchMessage AS L WITH(NOLOCK)
            ON P.BTSInterchangeID = L.BTSInterchangeID
WHERE LoadingStateDate BETWEEN @EventMinDate AND @EventMaxDate
      AND P.ErrorID = '56018'
	  



SELECT  K.ArchMessageID,
		K.MessageID,
        K.MessageSourceSystem,
		MessagePatientIDExt, 
        Status = CASE 
				 WHEN A.LoadingState = 9 
					THEN 'Loaded'
				WHEN A.ErrorID = '56018'
					THEN 'Failed'
				END
FROM 
      #DuplicateMessages AS B WITH(NOLOCK)
      INNER JOIN dbmDILMessagesArchive.dbo.ArchMessage AS K WITH(NOLOCK)
            ON K.MessageID = B.MessageID
            AND K.MessageSourceSystem = B.MessageSourceSystem
      INNER JOIN dbmDILMessagesArchive.dbo.ArchMessageState AS A WITH(NOLOCK)
	        ON A.BTSInterchangeID = K.BTSInterchangeID
WHERE a.LoadingState = 9 OR A.ErrorID = '56018'
order by K.MessageID,
      K.ArchMessageID

IF OBJECT_ID('tempdb..#DuplicateMessages') IS NOT NULL
DROP TABLE #DuplicateMessages
