
USE dbmVCDRData
go
SET NOCOUNT ON
DECLARE @IntAct int ,@cntAct varchar(20), @OM varchar(100),@Id_Root varchar(100) ,@Id_Extension varchar(100)
--SET @IntAct=60926 --1610 --'1847' '385' --'1786'--

--SET @Id_Root='2.16.840.1.113883.3.57.1.3.10.13.1.1' ---MMC
--SET @Id_Root='2.16.840.1.113883.3.57.1.3.11.11.1.1' --UPMC Medipac
--SET @Id_Root='2.16.840.1.113883.3.57.1.3.10.12.1.1' --BLHC
--SET @Id_Root='2.16.840.1.113883.3.57.1.3.11.13.1.1' --UPMC EPIC
--SET @Id_Root='2.16.840.1.113883.3.57.1.3.11.14.1.1'-- UPMC CERNERH1
--SET @Id_Root='2.16.840.1.113883.3.57.1.3.11.15.1.1'-- UPMC CERNERH2
--SET @Id_Root='2.16.840.1.113883.3.57.1.3.11.16.1.1'-- UPMC CERNERH3
--SET @Id_Root='2.16.840.1.113883.3.57.1.3.11.45.1.1' --UPMC LABCORP 
--SET @Id_Root='2.16.840.1.113883.3.57.1.3.11.17.1.1' --UPMC Misys 
--SET @Id_Root='2.16.840.1.113883.3.57.1.3.11.24.1.1' --UPMC STARNORTHWEST
--SET @Id_Root='2.16.840.1.113883.3.57.1.3.16.1.1.1' -- Alatus RAVE
--SET @Id_Root='2.16.840.1.113883.3.57.1.3.16.2.1.1' -- Alatus TCI1
--SET @Id_Root='2.16.840.1.113883.3.57.1.3.11.33.1.1' --UPMC COPATH
--SET @Id_Root='2.16.840.1.113883.3.57.1.3.11.46.1.1' --UPMC EON
SET @Id_Root= '2.16.840.1.113883.3.379.2.11.1.1' 


SET @Id_Extension='MessageId_Test_000055_ScnA_1001'



 


SELECT @IntAct=ControlActID 
FROM MessageWrapper.ControlAct C INNER JOIN MessageWrapper.Message M
ON C.MessageID=M.MessageID
WHERE M.Id_Root= @Id_Root AND M.Id_Extension =@Id_Extension

SET @cntAct=CONVERT(varchar(20),@IntAct) 
--SET @cntAct=
SET @OM=''
SELECT   @OM= @OM+ CONVERT(Varchar(20),ObsoleteMetadataID)+','
FROM         dbmVCDRDataHistory.dbo.ObsoleteMetadata
WHERE ControlActID = @IntAct
IF @OM<>''
SELECT @OM='('+SUBSTRING(@OM, 1,LEN(@OM)-1)+')'

DECLARE @SQLStringVCD nvarchar(2000),@SQLStringH nvarchar(2000),@ParmXMLOUT nvarchar(2000) 
DECLARE @ParmXml XML,@ParmXmlH XML
SET @ParmXMLOUT = N'@XMLOUT XML OUTPUT'

DECLARE @strDatHis varchar(2000), @FieldList varchar(2000)
SET @strDatHis='USE dbmVCDRDataHistory
SELECT  T.name  INTO dbo.TBl FROM sys.columns C
JOIN sys.tables T ON C.object_id = T.object_id		
WHERE C.name=''ObsoleteMetadataID'''
EXEC(@strDatHis)
DECLARE @ApreCalc TABLE(
	TableId int NOT NULL,
	schema_id int NOT NULL,
	SchemaName varchar(50),
	TableName varchar(50),
	InsertName varchar(500)  NULL,
	FromName varchar(500)  NULL,
	SQLExecD varchar(2000) NULL,
	SQLExecH varchar(1000) NULL,
	SelectSQL varchar(1000) NULL
) 

INSERT INTO @ApreCalc
	(TableId,
	schema_id,
	SchemaName, 
	TableName,
 
	FromName, 
	SQLExecD, 
	SQLExecH,
	SelectSQL)
SELECT DISTINCT 
PT.Object_id,
	PT.schema_id,
	PS.name ,
	PT.name,
	
	'FROM dbmVCDRDataHistory.['+PS.name +'].['+PT.name+']His WHERE His.ObsoleteMetadataID IN'+@OM+' ',
'SELECT * FROM  dbmVCDRData.['+PS.name +'].['+PT.name+'] WHERE '+PF.name+'='+@cntAct, 

'SELECT * FROM dbmVCDRDataHistory.['+PS.name +'].['+PT.name+'] WHERE ObsoleteMetadataID IN'+@OM+' ' as SQLExecH,
'SELECT @CountOUT=COUNT(*) FROM dbmVCDRData.['+PS.name +'].['+PT.name+'] WHERE '+PF.name+'='+@cntAct+' '
FROM         sys.columns AS PF INNER JOIN
                      sys.tables AS PT 
ON PF.Object_id = PT.Object_id 
INNER JOIN sys.schemas AS PS 
ON PT.schema_id = PS.schema_id
WHERE     (PF.name = 'ControlActId')
--SELECT  * FROM @ApreCalc
--ORDER BY SchemaName,TableName

DELETE @ApreCalc
FROM @ApreCalc A LEFT OUTER JOIN dbmVCDRDataHistory.dbo.TBl T
ON A.TableName=T.name
WHERE T.name IS NULL

EXEC('USE dbmVCDRDataHistory 
DROP TABLE TBl')
DECLARE @Rep TABLE(
	Id int IDENTITY (1,1),
	SchemaName varchar(50),	
	LevL varchar(10),
	TableDataName varchar(200) NOT NULL,
	DatXml xml NULL,
	
	HisXml xml NULL
)

DECLARE @ParmDefinition nvarchar(500), @strNew nvarchar(2000)
DECLARE @Count int, @CountC int, @CountThr int 
DECLARE @Object_id int,@TableName varchar(200),@SchemaName varchar(50), @SQLExecD varchar(1000) ,@SQLExecH varchar(1000),@SQLFromD varchar(1000)
,@FromName varchar(1000), @SQLString nvarchar(1000),
@ScObject_id int,@STableName varchar(200),@ScDelDat varchar(1000),@ScFrom varchar(1000),@SQLsString nvarchar(1000)
DECLARE @ThrObject_id int,@ThrTableName varchar(200),@ThrDelDat varchar(1000),@ThrFrom varchar(1000),@SQLThrString nvarchar(1000)

DECLARE TableCursor CURSOR FOR 
SELECT  TableId ,SchemaName ,TableName,FromName,SQLExecD ,SQLExecH,SelectSQL
		FROM  @ApreCalc 
ORDER BY SchemaName, TableName
OPEN TableCursor 

FETCH NEXT FROM TableCursor INTO @Object_id,@SchemaName,@TableName,@FromName ,@SQLExecD,@SQLExecH ,@SQLString

WHILE @@FETCH_STATUS = 0 
BEGIN 

SET @ParmDefinition = N' @CountOUT int OUTPUT'
SET @FieldList=''
SELECT @FieldList=@FieldList+'['+name +'], '
FROM sys.columns WHERE Object_id = @Object_id 
SELECT @FieldList=SUBSTRING(@FieldList, 1,LEN(@FieldList)-1)

SELECT @FieldList='SELECT '+@FieldList +' '+CHAR(10)+@FromName
PRINT(@SQLExecD)
PRINT(@FieldList +CHAR(10))
EXECUTE sp_executesql @SQLString, @ParmDefinition,  @CountOUT =@Count OUTPUT
--SELECT @Count
--	SET @SQLStringVCD=''		
--	SET @SQLStringH=''
	SET @ParmXml=''
	SET @ParmXmlH =''
IF  @Count >0
BEGIN
	
	SET @SQLStringVCD=N'SET @XMLOUT = (' +@SQLExecD+'FOR XML RAW)'
	exec sp_executesql @SQLStringVCD,@ParmXMLOUT ,  @XMLOUT=@ParmXml OUT
	IF @OM<>''
			BEGIN
			SET @SQLStringH=N'SET @XMLOUT = ( '+@FieldList+'FOR XML RAW)'
			exec sp_executesql @SQLStringH,@ParmXMLOUT,  @XMLOUT=@ParmXmlH OUT
			END
	INSERT INTO @Rep
	(LevL ,SchemaName,TableDataName ,DatXml,HisXml )
	VALUES('Level1',@SchemaName,@TableName, @ParmXml, @ParmXmlH )			

END	
ELSE
BEGIN
	SET @strNew='SELECT @CountOUT=COUNT(*) ' +@FromName

	exec sp_executesql  @strNew, @ParmDefinition,  @CountOUT =@Count OUTPUT
	SET @ParmXml=''
	SET @ParmXmlH =''
	IF  @Count >0
	BEGIN
	IF @OM<>''
			BEGIN
			SET @SQLStringH=N'SET @XMLOUT = ( '+@FieldList+'FOR XML RAW)'
			exec sp_executesql @SQLStringH,@ParmXMLOUT,  @XMLOUT=@ParmXmlH OUT
			END
			INSERT INTO @Rep
			(LevL ,SchemaName,TableDataName ,DatXml,HisXml )
			VALUES('Level1',@SchemaName,@TableName, @ParmXml, @ParmXmlH )
	END		
END
DECLARE SECursor CURSOR FOR 
			SELECT  DISTINCT   TCh.Object_id ,TCh.name,
			'SELECT * FROM  dbmVCDRData.['+Ap.SchemaName +'].['+TCh.name+'] WHERE ControlActId='+@cntAct ScDelDat,
			'FROM dbmVCDRDataHistory.['+Ap.SchemaName +'].['+Ap.TableName+'] His INNER JOIN dbmVCDRDataHistory.['+Ap.SchemaName +'].['+TCh.name+'] AS Hsc ON His.'+Fl.name+'= Hsc.'
			+FCh.Name+' AND His.ControlActID= Hsc.ControlActID  AND His.ObsoleteMetadataID IN '+@OM + '' ScFrom,
			'SELECT @CountOUT=COUNT(*) FROM dbmVCDRData.['+Ap.SchemaName +'].['+TCh.name+'] WHERE ControlActId='+@cntAct+' ' ScSel

			FROM        @ApreCalc  Ap INNER JOIN
								  sys.columns Fl 
			ON Ap.TableId = Fl.Object_id 
			AND Fl.is_identity=1
			INNER JOIN sys.columns AS FCh 
			ON Fl.name=FCh.Name
			INNER JOIN sys.tables AS TCh 
			ON FCh.Object_id = TCh.Object_id 
			AND Ap.TableId <>TCh.Object_id 
			AND Ap.schema_id = TCh.schema_id
			AND Ap.TableId=@Object_id
			AND TCh.Object_id NOT IN (SELECT S.TableId FROM  @ApreCalc S)
			--ORDER BY TCh.Object_id
			UNION
			SELECT  DISTINCT   TCh.Object_id ,TCh.name,
			'SELECT * FROM  dbmVCDRData.['+Ap.SchemaName +'].['+TCh.name+'] WHERE ControlActId='+@cntAct ScDelDat,
			'FROM dbmVCDRDataHistory.['+Ap.SchemaName +'].['+Ap.TableName+'] His INNER JOIN dbmVCDRDataHistory.['+Ap.SchemaName +'].['+TCh.name+'] AS Hsc ON His.'+Fl.name+'= Hsc.'
			+FCh.Name+' AND His.ControlActID= Hsc.ControlActID  AND His.ObsoleteMetadataID IN '+@OM + '' ScFrom,
			'SELECT @CountOUT=COUNT(*) FROM dbmVCDRData.['+Ap.SchemaName +'].['+TCh.name+'] WHERE ControlActId='+@cntAct+' ' ScSel

			FROM        @ApreCalc  Ap INNER JOIN
								  sys.columns Fl 
			ON Ap.TableId = Fl.Object_id 
			AND Fl.is_identity=1
			INNER JOIN sys.columns AS FCh 
			ON Fl.name+'_Player'=FCh.Name
			INNER JOIN sys.tables AS TCh 
			ON FCh.Object_id = TCh.Object_id 
			AND Ap.TableId <>TCh.Object_id 
			AND Ap.schema_id = TCh.schema_id
			AND Ap.TableId=@Object_id
			AND TCh.Object_id NOT IN (SELECT S.TableId FROM  @ApreCalc S)
			ORDER BY TCh.Object_id
			
	OPEN SECursor 

			FETCH NEXT FROM SECursor INTO @ScObject_id ,@STableName,@ScDelDat ,@ScFrom ,@SQLsString 
			WHILE @@FETCH_STATUS = 0 
			BEGIN 
				SET @FieldList=''
				SELECT @FieldList=@FieldList+'Hsc.'+name +', '
				FROM sys.columns WHERE Object_id = @ScObject_id 
				SELECT @FieldList=SUBSTRING(@FieldList, 1,LEN(@FieldList)-1)
				PRINT(@ScDelDat)
				PRINT('SELECT '+@FieldList+ ' '+CHAR(10)+@ScFrom +CHAR(10))
				EXECUTE sp_executesql @SQLsString, @ParmDefinition,  @CountOUT =@CountC OUTPUT
				IF  @CountC >0
				BEGIN
			
			
					SET @SQLStringVCD=N'SET @XMLOUT = (' +@ScDelDat+'FOR XML RAW)'
					exec sp_executesql @SQLStringVCD,@ParmXMLOUT ,  @XMLOUT=@ParmXml OUT
					IF @OM<>''
					BEGIN
					SET @SQLStringH=N'SET @XMLOUT = ( SELECT '+@FieldList+ ' '+@ScFrom +'FOR XML RAW)'
					exec sp_executesql @SQLStringH,@ParmXMLOUT,  @XMLOUT=@ParmXmlH OUT
					END

					INSERT INTO @Rep
					(LevL ,SchemaName,TableDataName ,DatXml,HisXml )
					VALUES('Level2',@SchemaName,@STableName, @ParmXml, @ParmXmlH )			
				END
				ELSE
				BEGIN
					SET @strNew='SELECT @CountOUT=COUNT(*) ' +@ScFrom 

					exec sp_executesql  @strNew, @ParmDefinition,  @CountOUT =@Count OUTPUT
					SET @ParmXml=''
					SET @ParmXmlH =''
					IF  @Count >0
					BEGIN
					IF @OM<>''
							BEGIN
							SET @SQLStringH=N'SET @XMLOUT = ( SELECT '+@FieldList+ ' '+@ScFrom +'FOR XML RAW)'
							exec sp_executesql @SQLStringH,@ParmXMLOUT,  @XMLOUT=@ParmXmlH OUT
							END
							INSERT INTO @Rep
							(LevL ,SchemaName,TableDataName ,DatXml,HisXml )
							VALUES('Level1',@SchemaName,@TableName, @ParmXml, @ParmXmlH )
					END		
END
		DECLARE ThrCursor CURSOR FOR 
		SELECT  DISTINCT   TCh.Object_id ,TCh.name,
			'SELECT * FROM  dbmVCDRData.['+SH.name +'].['+TCh.name+'] WHERE ControlActId='+@cntAct ThrDelDat,
			
			' INNER JOIN dbmVCDRDataHistory.['+SH.name +'].['+TCh.name+'] AS Thr ON Hsc.'+Fl.name+'= Thr.'
			+Fl.name+' AND Thr.ControlActID= Hsc.ControlActID  ' ThrFrom,
			'SELECT @CountOUT=COUNT(*) FROM dbmVCDRData.['+SH.name +'].['+TCh.name+'] WHERE ControlActId='+@cntAct+' ' ThrSel

			FROM        sys.tables  Ap INNER JOIN
								  sys.columns Fl 
			ON Ap.Object_id = Fl.Object_id 
			AND Fl.is_identity=1
--			
			INNER JOIN sys.columns AS FCh 
			ON Fl.name=FCh.Name
			INNER JOIN sys.tables AS TCh 
			ON FCh.Object_id = TCh.Object_id 
			AND Ap.Object_id <>TCh.Object_id 
			--ON Rf.ForeignFieldId = FCh.FieldId AND 
			AND Ap.schema_id = TCh.schema_id
			INNER JOIN sys.schemas SH
			ON AP.schema_id=SH.schema_id
			AND Ap.Object_id=@ScObject_id
			AND TCh.Object_id NOT IN (SELECT S.TableId FROM  @ApreCalc S)
			ORDER BY TCh.Object_id
OPEN ThrCursor 

			FETCH NEXT FROM ThrCursor INTO @ThrObject_id ,@ThrTableName,@ThrDelDat ,@ThrFrom ,@SQLThrString 
			WHILE @@FETCH_STATUS = 0 
			BEGIN 
				SET @FieldList=''
				SELECT @FieldList=@FieldList+'Thr.'+name +', '
				FROM sys.columns WHERE Object_id = @ThrObject_id 
				SELECT @FieldList=SUBSTRING(@FieldList, 1,LEN(@FieldList)-1)
				PRINT(@ThrDelDat)
				PRINT('SELECT '+@FieldList+ ' '+CHAR(10)+@ScFrom +CHAR(10)+@ThrFrom +CHAR(10))
				EXECUTE sp_executesql @SQLThrString, @ParmDefinition,  @CountOUT =@CountThr OUTPUT
				IF  @CountThr >0
				BEGIN
				
						SET @SQLStringVCD=N'SET @XMLOUT = (' +@ThrDelDat+'FOR XML RAW)'
						exec sp_executesql @SQLStringVCD,@ParmXMLOUT ,  @XMLOUT=@ParmXml OUT
						IF @OM<>''
						BEGIN
						SET @SQLStringH=N'SET @XMLOUT = ( SELECT '+@FieldList+ ' '+@ScFrom +@ThrFrom+'FOR XML RAW)'
						exec sp_executesql @SQLStringH,@ParmXMLOUT,  @XMLOUT=@ParmXmlH OUT
						END
						INSERT INTO @Rep
						(LevL ,SchemaName,TableDataName ,DatXml,HisXml )
						VALUES('Level3',@SchemaName,@ThrTableName, @ParmXml, @ParmXmlH )			
				END
				
			FETCH NEXT FROM ThrCursor INTO @ThrObject_id ,@ThrTableName,@ThrDelDat ,@ThrFrom ,@SQLThrString 
			END 
			CLOSE ThrCursor 
			DEALLOCATE ThrCursor


		FETCH NEXT FROM SECursor INTO @ScObject_id ,@STableName,@ScDelDat ,@ScFrom ,@SQLsString 
		END 
		CLOSE SECursor 
		DEALLOCATE SECursor


	
FETCH NEXT FROM TableCursor INTO @Object_id,@SchemaName,@TableName,@FromName , @SQLExecD,@SQLExecH,@SQLString
END 
CLOSE TableCursor 
DEALLOCATE TableCursor

SELECT SchemaName,LevL ,TableDataName ,DatXml AS VCDRDATA,HisXml AS HistoryData
FROM @Rep ORDER BY ID FOR XML RAW , ROOT('MyRoot')
SET NOCOUNT Off