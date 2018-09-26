USE dbmVCDRStage
GO
UPDATE    Common.DILEvent
SET              RegardAsWarningInd = 1
WHERE     (EventID BETWEEN 56040 AND 56051) OR
                      (EventID = 56020)
