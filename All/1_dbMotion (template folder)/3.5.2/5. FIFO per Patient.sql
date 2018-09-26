/*
Author: Alen
Creation Date: 2010-02-03
Description: Returns top number of messages per PatientID
*/

SELECT TOP 10
PIDExst, COUNT(*) AS MsgInQueue, MIN(RegTime) AS FirstMsgDate
FROM dbmDILFIFOQueue.dbo.FIFOQueue WITH(nolock)
GROUP BY PIDExst
ORDER BY COUNT(*) DESC, MIN(RegTime)