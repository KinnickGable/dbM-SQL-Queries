/****** Script for researching Message Wrappers for CareEvent by BTS InterchangeID  ******/
 --
 
 Declare @BTSInterchangeID varchar(255)
 select @BTSInterchangeID='24c782ab-aa01-4c2b-81bb-8eb054fbfd9f'
 
 
 -------------------------------------------------------------------
 
 declare @MessageID bigint
 
 
 		SELECT *
			 FROM [dbmVCDRData].[MessageWrapper].[Message]
		where InterchangeID=@BTSInterchangeID
		
	select @MessageID = MessageID	
		 FROM [dbmVCDRData].[MessageWrapper].[Message]
		where InterchangeID=@BTSInterchangeID
		
select * 
	from  [dbmVCDRData].[MessageWrapper].[ControlAct]CA
		where MessageID=@MessageID

			
select * 
		FROM [dbmInternalData].[Tracking].[CareEventDataWrapper] 
			where TrackingMessageID=@messageID
			