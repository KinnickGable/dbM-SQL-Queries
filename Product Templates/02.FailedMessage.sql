USE [dbmUtils]
GO


DECLARE   @FromDate as DATETIME ,
		  @ToDate as DATETIME , 
		  @BTSInterchangeID varchar(50), 
		  @Chunk  as int  
----    @FromDate, @ToDate  - dates for report filter
SELECT  @ToDate  = <ToDate, datetime, GETDATE()>,
		@FromDate = <FromDate, datetime, DATEADD(dd,-1,@ToDate )> , --- DEFAULT -- ONE DAY
		@BTSInterchangeID = <BTSInterchangeID , varchar(50) , NULL> , 
		@Chunk    = <Chunk , int, 10000>  
		
EXEC LoadingReport.[GetFailedMessageStatus_prc] @FromDate =  @FromDate,   @ToDate = @ToDate , @BTSInterchangeID = @BTSInterchangeID, @Chunk  = @Chunk 



---output recordset----
SELECT  
	FailedMessageStatusID as #, 
	MessageID, 
	BTSInterchangeID, 
	ArchTime, 
	OccurrenceTimeInEventLog, 
	LoadingStateDateInArchMessageState, 
	MessageType, 
	MessageSourceSystem, 
	MessageTriggerEvent, 
	LoadingStateName as LastLoadingStateName , 
	PatientIDRoot , 
	PatientIDExt, 
	ErrorIDInArchMessageState, 
	EventIDInExtendedProperties, 
	LogLevel, 
	ErrorDescription, 
	ErrorMessageInEventLog, 
	InternalErrorMessage, 
	MessageTextFromArchive , 
	isReplacing , 
	ReplacingMessageBTSInterchangeID
FROM  LoadingReport.FailedMessageStatus
