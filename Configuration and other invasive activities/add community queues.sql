USE [dbmDILMessagesArchive]
GO
INSERT INTO [dbmDILMessagesArchive].[dbo].[ReceiveLocationConfiguration]
           ([ReceiveLocationName]
           ,[OIDCalculationType]
           ,[ExtendedProperty])
     VALUES
           (<ReceiveLocationName, varchar(255),>
           ,<OIDCalculationType, tinyint,>
           ,<ExtendedProperty, varchar(500),>)
WHERE NOT EXISTS
      (SELECT TOP 1 1 FROM [dbmDILMessagesArchive].[dbo].[ReceiveLocationConfiguration] 
       WHERE [ReceiveLocationName] = <ReceiveLocationName, varchar(255),>)
      
GO


