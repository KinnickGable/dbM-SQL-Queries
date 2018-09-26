USE dbmDILMessagesArchive
GO

set transaction isolation level read uncommitted

DECLARE @Rows int
DECLARE @MessageId varchar (255)

SET @Rows = 100

SET ROWCOUNT @Rows

SELECT 
AMS.[BTSInterchangeID],
A.ArchTime,
AMS.LoadingStateDate as CurrentStateDate,
A.MessageID,
A.MessageSourceSystem,
A.MessageType,
A.MessageTriggerEvent,
S.LoadingStateName,
A.MessageText
FROM [dbo].[ArchMessageState] AMS WITH (NOLOCK)
	 INNER JOIN
           (SELECT BTSInterchangeID,MAX([ArchMessageStateID]) MaxID
            FROM [dbo].[ArchMessageState] WITH (NOLOCK)
            GROUP BY BTSInterchangeID) as lastStates 
				ON AMS.[ArchMessageStateID]=lastStates.MaxID
	 LEFT JOIN dbo.ArchMessage A WITH(NOLOCK)
		ON AMS.BTSInterchangeID = A.BTSInterchangeID
	 LEFT JOIN dbo.luLoadingState S WITH(NOLOCK)
		ON AMS.LoadingState = S.LoadingStateID
Where A.MessageId = COALESCE (@MessageId,A.MessageId)
order by [ArchMessageStateID] desc

SET ROWCOUNT 0
