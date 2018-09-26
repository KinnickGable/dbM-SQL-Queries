USE dbmDILMessagesArchive

set transaction isolation level read uncommitted

DECLARE @Rows int,
		@MinDate datetime

SET @Rows = 1000


SET @MinDate = (Select Top 1 ArchTime from 
(
    select top (@Rows) ArchTime ,  ArchMessageID
    from ArchMessage with(nolock)
    where ArchMessageID > 0
    order by ArchMessageID desc

)A
Order By A.ArchMessageID 
);



WITH LastStates(ArchMessageStateID, BTSInterchangeID, LoadingStateDate, LoadingState)
AS
(
	SELECT AMS.ArchMessageStateID, AMS.BTSInterchangeID, AMS.LoadingStateDate, AMS.LoadingState
	FROM dbo.ArchMessageState AMS WITH (NOLOCK)
		 INNER JOIN
			   (SELECT BTSInterchangeID,MAX(ArchMessageStateID) MaxID
				FROM dbo.ArchMessageState WITH (index(IX_C_LoadingStateDate),NOLOCK)
				WHERE LoadingStateDate > @MinDate
				GROUP BY BTSInterchangeID) as lastStates 
					ON AMS.ArchMessageStateID=lastStates.MaxID
	WHERE LoadingStateDate > @MinDate
					
)
SELECT top (@Rows)
AMS.BTSInterchangeID,
A.ArchTime,
AMS.LoadingStateDate as CurrentStateDate,
A.MessageID,
A.MessageSourceSystem,
A.MessageType,
A.MessageTriggerEvent,
a.BTSReceiveLocationName,
a.MessagePatientIDExt,
S.LoadingStateName,
A.MessageText
FROM LastStates AMS
	 LEFT JOIN dbo.ArchMessage A WITH(NOLOCK)
		ON AMS.BTSInterchangeID = A.BTSInterchangeID
	 LEFT JOIN dbo.luLoadingState S WITH(NOLOCK)
		ON AMS.LoadingState = S.LoadingStateID
		
Where AMS.ArchMessageStateID>0
--AND A.MessagePatientIDExt='105102141'
--AND A.MessageType='MDM'
--AND A.MessageTriggerEvent='A60'
--AND A.MessageID='1856692'
--AND A.BTSReceiveLocationName like '%Imaging%'
--And S.ErrorIndication=1  -- Failed Messages
--And A.BTSInterchangeID

ORDER BY AMS.ArchMessageStateID DESC



