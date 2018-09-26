USE [dbmUtils]
GO

DECLARE  @FromDate as DATETIME ,
		 @ToDate as DATETIME, 
		  @Chunk  as int  
		 --@FromDate, @ToDate  - dates for report filter
SELECT  @ToDate  = <ToDate, datetime, GETDATE()>,
		@FromDate = <FromDate, datetime, DATEADD(dd,-1,@ToDate )>  , ---- default  --- ONE DAY
		@Chunk    = <Chunk , int, 10000>   
EXEC LoadingReport.[GetMessageStatus_prc]  @FromDate =  @FromDate,   @ToDate = @ToDate, @Chunk  = @Chunk 


CREATE TABLE #OUTPUT
(
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[MessageStatusID] [varchar](50)  NULL,
	[MessageType] [varchar](50) NULL,
	[MessageSourceSystem] [varchar](255) NULL,
	[MessageTriggerEvent] [varchar](50) NULL,
	[ReceiveLocationName] [varchar](255) NULL,
	[FirstMsgDate] [datetime] NULL,
	[LastMsgDate] [datetime] NULL,
	[CompletedCDRAmount] [bigint] NULL,
	[InProgressAmount] [bigint] NULL,
	[FailedAmount] [bigint] NULL,
	[Summary] [bigint] NULL)

INSERT INTO #OUTPUT
(MessageStatusID, MessageType, MessageSourceSystem, MessageTriggerEvent, ReceiveLocationName, FirstMsgDate, LastMsgDate, CompletedCDRAmount, InProgressAmount, FailedAmount, Summary)
 ---output recordset
SELECT  
	MessageStatusID , 
	MessageType, 
	MessageSourceSystem, 
	MessageTriggerEvent, 
	ReceiveLocationName , 
	FirstMsgDate, 
	LastMsgDate, 
	CompletedCDRAmount, 
	InProgressAmount, 
	FailedAmount, 
	Summary
FROM  LoadingReport.MessageStatus
ORDER BY MessageStatusID

INSERT INTO #OUTPUT
(MessageStatusID, MessageType, MessageSourceSystem, MessageTriggerEvent, ReceiveLocationName, FirstMsgDate, LastMsgDate, CompletedCDRAmount, InProgressAmount, FailedAmount, Summary)

SELECT 'Total'  , 
	   NULL as MessageType, 
	   NULL as MessageSourceSystem, 
	   NULL as MessageTriggerEvent , 
	   NULL as ReceiveLocationName , 
	   NULL as FirstMsgDate , 
	   NULL as LastMsgDate , 
	   SUM(CompletedCDRAmount) as CompletedCDRAmount , 
	   SUM(InProgressAmount) as InProgressAmount , 
	   SUM(FailedAmount) as FailedAmount , 
	   SUM(Summary) as Summary
FROM  LoadingReport.MessageStatus


SELECT MessageStatusID as #, 
	   MessageType, 
	   MessageSourceSystem, 
	   MessageTriggerEvent, 
	   ReceiveLocationName, 
	   FirstMsgDate, 
	   LastMsgDate, 
	   CompletedCDRAmount, 
	   InProgressAmount, 
	   FailedAmount, 
	   Summary 
FROM #OUTPUT 
ORDER BY ID


DROP TABLE #OUTPUT


		

