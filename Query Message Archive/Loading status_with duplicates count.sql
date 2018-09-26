/*
Author: Alen
Creation Date: 2010-01-31
Description: Returns loading status between defined dates
*/

USE dbmDILMessagesArchive
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @EventMaxDate DATETIME,
		@EventMinDate DATETIME

SELECT  -->> (-1) parameter means from yesterday 
		@EventMaxDate = GETDATE(),
		@EventMinDate = '2010-09-21 08:30'

IF OBJECT_ID('tempdb..#lastStates') IS NOT NULL
DROP TABLE #lastStates

IF OBJECT_ID('temypdb..#ClinicalDomains') IS NOT NULL
DROP TABLE #ClinicalDomains

IF OBJECT_ID('tempdb..#ArchMessageState') IS NOT NULL
DROP TABLE #ArchMessageState

CREATE TABLE #lastStates
(
      BTSInterchangeID varchar(50),
      LastStateID bigint
)

INSERT INTO #lastStates(BTSInterchangeID, LastStateID )
SELECT BTSInterchangeID, MAX(ArchMessageStateID)
FROM dbmDILMessagesArchive.dbo.ArchMessageState WITH (NOLOCK)
WHERE  LoadingStateDate > @EventMinDate
		AND LoadingStateDate < @EventMaxDate
GROUP BY BTSInterchangeID


CREATE CLUSTERED INDEX [REX_LastStateID] ON #lastStates(LastStateID)


CREATE TABLE #ArchMessageState
(
      [BTSInterchangeID] [varchar](50),
	  [ErrorID] [varchar](255),
      [LoadingState] [tinyint]
)

INSERT INTO #ArchMessageState
		(
		[BTSInterchangeID], 
		[ErrorID],
		[LoadingState]
		)
SELECT 
	  AMS.[BTSInterchangeID],
	  AMS.[ErrorID],
	  AMS.[LoadingState]
FROM [dbmDILMessagesArchive].[dbo].[ArchMessageState] AMS WITH (NOLOCK)
	 INNER JOIN #lastStates 
		ON	AMS.[ArchMessageStateID]=#lastStates.LastStateID



CREATE NONCLUSTERED INDEX [REX_BTSInterchangeID] ON #ArchMessageState (BTSInterchangeID) 


CREATE TABLE #ClinicalDomains(
	[Clinical Domain] varchar(255) NULL,
	MessageType varchar(255) NULL,
	MessageSourceSystem varchar(255) NULL,
	MessageTriggerEvent varchar(255) NULL,
	Purpose varchar(255) NULL
)


INSERT INTO #ClinicalDomains VALUES ('ADT', 'ADT','UMMHC-MEDITECH','A01','Patient Administration')
INSERT INTO #ClinicalDomains VALUES ('ADT', 'ADT','UMMHC-MEDITECH','A02','Patient Administration')
INSERT INTO #ClinicalDomains VALUES ('ADT', 'ADT','UMMHC-MEDITECH','A03','Patient Administration')
INSERT INTO #ClinicalDomains VALUES ('ADT', 'ADT','UMMHC-MEDITECH','A04','Patient Administration')
INSERT INTO #ClinicalDomains VALUES ('ADT', 'ADT','UMMHC-MEDITECH','A05','Patient Administration')
INSERT INTO #ClinicalDomains VALUES ('ADT', 'ADT','UMMHC-MEDITECH','A06','Patient Administration')
INSERT INTO #ClinicalDomains VALUES ('ADT', 'ADT','UMMHC-MEDITECH','A07','Patient Administration')
INSERT INTO #ClinicalDomains VALUES ('ADT', 'ADT','UMMHC-MEDITECH','A08','Patient Administration')
INSERT INTO #ClinicalDomains VALUES ('ADT', 'ADT','UMMHC-MEDITECH','A11','Patient Administration')
INSERT INTO #ClinicalDomains VALUES ('ADT', 'ADT','UMMHC-MEDITECH','A12','Patient Administration')
INSERT INTO #ClinicalDomains VALUES ('ADT', 'ADT','UMMHC-MEDITECH','A13','Patient Administration')
INSERT INTO #ClinicalDomains VALUES ('Allergy', 'ADT','UMMHC-MEDITECH','A31','Allergy')
INSERT INTO #ClinicalDomains VALUES ('ADT', 'ADT','UMMHC-IDX','A04','Patient Administration')
INSERT INTO #ClinicalDomains VALUES ('ADT', 'ADT','UMMHC-IDX','A08','Patient Administration')
INSERT INTO #ClinicalDomains VALUES ('ADT', 'ADT','UMMHC-IDX','A11','Patient Administration')
INSERT INTO #ClinicalDomains VALUES ('ADT', 'ADT','UMMHC-IDX','A40','Patient Administration')
INSERT INTO #ClinicalDomains VALUES ('Allergy', 'ADT','UMMHC-ALLSCRIPTS','A60','Allergy')
INSERT INTO #ClinicalDomains VALUES ('Medical Staff', 'MFN','UMMHC-MEDITECH','M02','Medical Staff')
INSERT INTO #ClinicalDomains VALUES ('Medical Staff', 'MFN','UMMHC-MTSTAFF','M02','Medical Staff')
INSERT INTO #ClinicalDomains VALUES ('Meds Orders', 'ORM','UMMHC-ALLSCRIPTS','O01','Meds Orders')
INSERT INTO #ClinicalDomains VALUES ('Immunization', 'VXU','UMMHC-MEDITECH','V04','Immunization')
INSERT INTO #ClinicalDomains VALUES ('Immunization', 'VXU','UMMHC-ALLSCRIPTS','V04','Immunization')
INSERT INTO #ClinicalDomains VALUES ('Problems', 'PPR','UMMHC-ALLSCRIPTS','PC1','Problems')
INSERT INTO #ClinicalDomains VALUES ('Labs', 'ORU','UMMHC-MEDITECH','R01','Labs')
INSERT INTO #ClinicalDomains VALUES ('Documents', 'MDM','UMMHC-MEDITECH','T02','Documents')
INSERT INTO #ClinicalDomains VALUES ('Documents', 'MDM','UMMHC-ALLSCRIPTS','T02','Documents')
INSERT INTO #ClinicalDomains VALUES ('Documents', 'MDM','UMMHC-CENTRICITY','T02','Documents')
INSERT INTO #ClinicalDomains VALUES ('Documents', 'MDM','UMMHC-PROVATION','T02','Documents')
INSERT INTO #ClinicalDomains VALUES ('Documents', 'MDM','UMMHC-MEDQUIST','T02','Documents')
INSERT INTO #ClinicalDomains VALUES ('Documents', 'MDM','UMMHC-MUSE','T02','Documents')
INSERT INTO #ClinicalDomains VALUES ('Documents', 'MDM','UMMHC-IMAGECAST','T02','Documents')
INSERT INTO #ClinicalDomains VALUES ('Documents', 'MDM','UMMHC-SOFTMED','T02','Documents')
INSERT INTO #ClinicalDomains VALUES ('Documents', 'MDM','UMMHC-VASCUPRO','T02','Documents')
INSERT INTO #ClinicalDomains VALUES ('Documents', 'MDM','UMMHC-IMAGECAST','T02','Documents')




--Message state and count from one day
SELECT	   lm.BTSReceiveLocationName,
		   lm.MessageType,
		   lm.MessageSourceSystem,
		   lm.MessageTriggerEvent,
		   [Clinical Domain],
		   MIN(lm.ArchTime) as FirstMsgDate,
		   MAX(lm.ArchTime) as LastMsgDate,
           SUM(CASE WHEN ams.LoadingState = 9 THEN 1 ELSE 0 END) as Loaded,
		   SUM(CASE WHEN ams.LoadingState not in(3,4,5,7,8,11,17,21,9) THEN 1 ELSE 0 END) as [In Progress],
		   SUM(CASE WHEN ams.ErrorID IS NOT NULL AND ams.ErrorID <> '56018' THEN 1 ELSE 0 END) as Failed,
		   SUM(CASE WHEN ams.ErrorID = '56018' THEN 1 ELSE 0 END) as Duplicated,		   
		   COUNT(MessageID) as Summary
FROM    #ArchMessageState ams
		LEFT JOIN [dbmDILMessagesArchive].[dbo].[ArchMessage] lm WITH (NOLOCK)
			ON ams.BTSInterchangeID=lm.BTSInterchangeID
		LEFT JOIN #ClinicalDomains
			ON lm.MessageType = #ClinicalDomains.MessageType
			AND lm.MessageSourceSystem = #ClinicalDomains.MessageSourceSystem
			AND lm.MessageTriggerEvent = #ClinicalDomains.MessageTriggerEvent
WHERE  lm.ReplacingMessageArchiveID IS NULL --AND lm.MessageTriggerEvent = 'A04'
GROUP BY   lm.BTSReceiveLocationName,
		   lm.MessageType,
		   lm.MessageSourceSystem,
		   lm.MessageTriggerEvent,
		   [Clinical Domain]
ORDER BY MAX(lm.ArchTime) desc



IF OBJECT_ID('tempdb..#ArchMessageState') IS NOT NULL
DROP TABLE #ArchMessageState

IF OBJECT_ID('tempdb..#ClinicalDomains') IS NOT NULL
DROP TABLE #ClinicalDomains

IF OBJECT_ID('tempdb..#lastStates') IS NOT NULL
DROP TABLE #lastStates