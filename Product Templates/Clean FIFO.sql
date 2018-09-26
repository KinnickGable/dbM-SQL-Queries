USE [dbmDILMessagesArchive]
GO
/****** Object:  Table [dbo].[DeadArchMessageState]    Script Date: 01/20/2010 12:14:17 ******/
IF NOT  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DeadArchMessageState]') AND type in (N'U'))
BEGIN
	SET ANSI_NULLS ON

	SET QUOTED_IDENTIFIER ON

	SET ANSI_PADDING ON

	CREATE TABLE [dbo].[DeadArchMessageState](
		[ArchMessageStateID] [bigint] NOT NULL,
		[BTSInterchangeID] [varchar](50) NOT NULL,
		[LoadingState] [tinyint] NOT NULL,
		[LoadingStateDate] [datetime] NOT NULL,
		[ErrorID] [varchar](255) NULL,
		[TrailMessageInterchangeID] [varchar](50) NULL,
	 CONSTRAINT [PK_DeadArchMessageState] PRIMARY KEY NONCLUSTERED 
	(
		[ArchMessageStateID] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	SET ANSI_PADDING OFF
END

DECLARE @InterchangeID varchar(50),
	@LastState tinyint,
	@MessageId bigint,
	@ToDeleteState bit

---Here to insert Param
SELECT @InterchangeID='d' ,
@ToDeleteState=1 ---(1 for History, 0 for Life)

IF EXISTS (SELECT TOP (1) 1  FROM dbmDILFIFOQueue.dbo.FIFOQueue  WHERE InterchangeID=@InterchangeID)
	BEGIN

	SELECT @LastState=MAX(LoadingState)
	FROM dbmDILMessagesArchive.dbo.ArchMessageState
	WHERE BTSInterchangeID=@InterchangeID


	IF @LastState=1 OR @LastState=2
		BEGIN
		BEGIN TRAN
		DELETE	 F
		FROM dbmDILFIFOQueue.dbo.FIFOQueue   F
		WHERE InterchangeID=@InterchangeID
		IF @ToDeleteState=1
			DELETE A
			OUTPUT DELETED.*
				 INTO dbmDILMessagesArchive.dbo.DeadArchMessageState
			FROM dbmDILMessagesArchive.dbo.ArchMessageState A
			WHERE BTSInterchangeID=@InterchangeID
		IF @LastState=2
		BEGIN
			SELECT @MessageId=MessageID
			FROM dbmVCDRData.MessageWrapper.Message
			WHERE InterchangeID=@InterchangeID
			IF @@ROWCOUNT>0
			BEGIN
				DELETE  M
				FROM dbmVCDRData.MessageWrapper.Message M
				WHERE M.MessageId=@MessageID

				DELETE  C
				FROM dbmVCDRData.MessageWrapper.ControlAct C
				WHERE C.MessageId=@MessageID
			END

		END
		
		COMMIT TRAN
		
		END
	IF @LastState=6 OR @LastState=16
			EXEC dbmVCDRStage.Common.ReloadToSB_Err_prc

END
