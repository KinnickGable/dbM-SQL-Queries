USE dbmDILMessagesArchive


DECLARE @INTERCHANGE_ID AS  varchar(50);
SET  @INTERCHANGE_ID = '2227eabf-2a32-4ec7-b588-f0e34b59bd79'

DECLARE @MRN_ROOT AS  varchar(50);
DECLARE @MRN_EXT AS  varchar(50);
DECLARE @ARCH_TIME AS  DATETIME;
DECLARE @CREATION_TIME AS  DATETIME ;
DECLARE @REPLY_INTERCHANGEID AS  varchar(50);

SELECT [INFO] = 'Original  messages to replay'

SELECT 
a.BTSInterchangeID as 'Orig BTSInterchangeID'
,a.MessageCreationTime as 'Orig creation time'
,a.ArchTime as 'Orig arch time'
,a.ArchMessageID as 'Orig ArchMessageID'
,a.MessagePatientIDExt as MRN
,a.ReplacingMessageArchiveID
, b.BTSInterchangeID as 'Replay BTSInterchangeID'
,b.ArchTime as 'Reply time'
,b.MessageText as 'Reply Msg'
, a.MessageText as 'Orig Msg'

FROM dbo.ArchMessage a WITH(NOLOCK)
LEFT JOIN dbo.ArchMessage b WITH(NOLOCK)
ON a.ReplacingMessageArchiveID = b.ArchMessageID
where a.BTSInterchangeID = @INTERCHANGE_ID 

SET @MRN_ROOT =  (SELECT a.MessagePatientIDRoot FROM dbo.ArchMessage a WITH(NOLOCK) WHERE a.BTSInterchangeID = @INTERCHANGE_ID )
SET @MRN_EXT =   (SELECT a.MessagePatientIDExt  FROM dbo.ArchMessage a WITH(NOLOCK) WHERE a.BTSInterchangeID = @INTERCHANGE_ID )
SET @ARCH_TIME = (SELECT a.ArchTime  FROM dbo.ArchMessage a WITH(NOLOCK) WHERE a.BTSInterchangeID = @INTERCHANGE_ID )
SET @CREATION_TIME = (SELECT a.MessageCreationTime FROM dbo.ArchMessage a WITH(NOLOCK) WHERE a.BTSInterchangeID = @INTERCHANGE_ID )

SET @REPLY_INTERCHANGEID = 
(   SELECT b.BTSInterchangeID
	FROM dbo.ArchMessage a WITH(NOLOCK)
	LEFT JOIN dbo.ArchMessage b WITH(NOLOCK)
	ON a.ReplacingMessageArchiveID = b.ArchMessageID
	where a.BTSInterchangeID = @INTERCHANGE_ID 
)

SELECT [INFO] = 'Message Trail'

SELECT Arch.BTSInterchangeID
,Arch.MessageCreationTime
,Arch.ArchTime
,Arch.MessagePatientIDExt AS 'MRN'
,Arch.MessageID
,Arch.ReplacingMessageArchiveID 
,b.ArchTime as 'Replay Arch time'
,b.BTSInterchangeID,Arch.MessageType
, Arch.MessageTriggerEvent
, Arch.MessageText
FROM dbo.ArchMessage Arch WITH(NOLOCK)
LEFT JOIN dbo.ArchMessage b WITH(NOLOCK)
ON Arch.ReplacingMessageArchiveID = b.ArchMessageID
where Arch.MessagePatientIDRoot = @MRN_ROOT AND Arch.MessagePatientIDExt = @MRN_EXT AND Arch.MessageCreationTime > @CREATION_TIME 
--AND Arch.BTSInterchangeID != @REPLY_INTERCHANGEID
--
