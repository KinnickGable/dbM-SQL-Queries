/*
Author: Alen
Creation Date: 2010-02-27
Description: Returns amount of rows loaded to AddressPart in last 24 hours and contains symbol "?" in the value. 
*/

USE dbmVCDRData
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare @MinDate datetime,
		@MaxDate datetime

declare @minControlActID bigint
declare @maxControlActID bigint
declare @chunkSize int
declare @MsgCount int

--set @MaxDate = GETDATE()
/*@MaxDate needs to be defined hardcoded, becouse it have to be the same in all scripts*/
set @MaxDate = '2010-03-01'

set @MinDate = DATEADD(dd,-1,@MaxDate)
set @MsgCount = 0
set @chunkSize = 10000

--select @minControlActID = MIN(ControlActID) from MessageWrapper.ControlAct where LoadedDate > @MinDate
--
--select @maxControlActID = MAX(ControlActID) from MessageWrapper.ControlAct where LoadedDate < @MaxDate

/*by Alex C recommendation --> find MIN(ControlActID) and MAX(ControlActID) by one select */

select 
	@minControlActID = MIN(ControlActID),
	@maxControlActID = MAX(ControlActID)
from MessageWrapper.ControlAct 
where LoadedDate > @MinDate
and LoadedDate < @MaxDate

---------------------------------------------------------------------
while @minControlActID <= @maxControlActID
begin	
		
	SELECT @MsgCount = @MsgCount + count(AddressPartID)
	FROM  MessageWrapper.ControlAct (nolock)
		  INNER JOIN PatientAdministration.AddressPart (nolock)
			ON ControlAct.ControlActID = AddressPart.ControlActID
	WHERE ControlAct.ControlActID > @minControlActID 
		  and ControlAct.ControlActID < (@minControlActID + @chunkSize + 1) 
		  and AddressPart.[Value] like '%?%'

	set @minControlActID = @minControlActID + @chunkSize
end

select @MsgCount as AddressPart
