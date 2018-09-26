SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

use dbmDILMessagesArchive

declare @startTime as datetime

set @startTime='2009-04-08 18:00:00'

SELECT     
		arc.ArchMessageID
		--,arc.ReplacingMessageArchiveID
		,arc.MessageType
		,arc.MessageTriggerEvent
		,arc.BTSInterchangeID as interchangeId
		,arc.MessageID
		,lust.LoadingStateName
		,arcst.LoadingState 
		,arc.ArchTime
		,arcst.LoadingStateDate
		--,arcst.LoadingErrorMsg
		,arc.MessageSourceSystem
		,arc.MessageText
		,arc.MessageFormat
		,arc.MessagePatientIDRoot
		,arc.MessagePatientIDExt
		,arc.MessageCreationTime
		,arc.BTSReceiveLocationName
		,arc.BTSReceivePortName
		,arc.BTSSize
		,arc.ArchFileName
FROM	ArchMessage arc 
			LEFT JOIN ArchMessageState arcst
				ON arc.BTSInterchangeID = arcst.BTSInterchangeID and arc.archtime>=@startTime
			Left JOIN luLoadingState lust 
				ON arcst.LoadingState = lust.LoadingStateID
where arc.MessageId like '%APCase%'
 and arcst.LoadingState in (3,4,5,7,8,11,12,17,21,30,9)
--where arcst.LoadingState in (14)
-- WHERE     (arc.MessageID = 'BL20083170000032')
--Where arc.BTSInterchangeID='805a2eee-887e-4abe-bfc2-a935f4f6bbe7'
--where arc.ArchTime>='2008-11-24 15:36:00' and arc.ArchTime<='2008-11-24 15:37:00'
--Where arc.MessageTy
ORDER BY arc.ArchMessageID desc , arcst.LoadingStateDate DESC
