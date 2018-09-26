USE dbmDILMessagesArchive
GO

set transaction isolation level read uncommitted

declare @PatIdRoot varchar(100) 
declare @PatIdExt varchar(100)
DECLARE @EventMaxDate DATETIME
DECLARE @EventMinDate DATETIME

--- *** Query Parameters  *** ---
Set @PatIdRoot='2.16.840.1.113883.3.57.1.3.15.1.4.1.8.1'
Set @PatIdExt='123456789'
Set @EventMaxDate = GETDATE()
Set @EventMinDate = '2010-01-01' 


SELECT 
AMS.[BTSInterchangeID],
A.ArchTime,
AMS.LoadingStateDate as CurrentStateDate,
A.MessageID,
A.MessageSourceSystem,
A.MessageType,
A.MessageTriggerEvent,
S.LoadingStateName,
A.MessageText,
A.MessagePatientIDRoot,
A.MessagePatientIDExt

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
Where (A.MessagePatientIDRoot = @PatIdRoot) and (A.MessagePatientIDExt= @PatIdExt)and (A.ArchTime <= @EventMaxDate) and (A.ArchTime >= @EventMinDate)
order by A.ArchTime desc
