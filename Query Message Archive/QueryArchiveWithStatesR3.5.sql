SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

use dbmDILMessagesArchive

declare @startTime as datetime

set @startTime='2008-11-26'

SELECT     
		arc.ArchMessageID
		,arc.ReplacingMessageArchiveID
		,arc.BTSInterchangeID
		,arc.MessageID
		,arc.ArchTime
		,arcst.LoadingStateDate
		,lust.LoadingStateName
		,DED.ErrorMessage
		,arc.MessageSourceSystem
		,arc.MessageType
		,arc.MessageTriggerEvent
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
				ON arc.BTSInterchangeID = arcst.BTSInterchangeID -- and arc.archtime>=@startTime
			Left JOIN luLoadingState lust 
				ON arcst.LoadingState = lust.LoadingStateID 
			left join 
				dbmVCDRStage.Common.DILEventDesignation DED
				on arcst.ErrorId=DED.EventId
-- WHERE     (arc.MessageID = 'BL20083170000032')
--Where arc.BTSInterchangeID='8c83669d-b596-4c1b-8c14-4bfbcf3b0d24'
--where arc.ArchTime>='2008-11-24 15:36:00' and arc.ArchTime<='2008-11-24 15:37:00'
ORDER BY arc.ArchMessageID desc , arcst.LoadingStateDate DESC
