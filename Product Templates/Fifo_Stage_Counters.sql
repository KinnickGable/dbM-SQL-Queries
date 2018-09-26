/*
Author: Alen
Creation Date: 2010-02-03
Description: Returns number of messages from FIFO and Stage Queue
*/

select count(*) as FIFO, min(RegTime) as min_FIFO_RegTime
from dbmDILFIFOQueue.dbo.FIFOQueue with(nolock)

select count(*) as Stage
from dbmVCDRStage.dbo.Stage2CDR_Q with(nolock)

