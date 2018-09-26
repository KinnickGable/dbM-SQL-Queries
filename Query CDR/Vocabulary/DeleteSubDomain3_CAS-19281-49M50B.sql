USE dbmVCDRData
GO

/*
Replace %SubDomainCode% parameter with relevant 'Sub Domain Name to be remove' (for example: Neonatology_ad)

1.	Get 'Sub Domain Name to be remove' as parameter.
2.	Delete From Vocabulary and Vocabulary Admin Tables.
3.	Delete each sub domain from both schemas (Vocabulary, Vocabulary Admin) by transaction.
4.	For each sub domain check for both schemas (Vocabulary, Vocabulary Admin):
	a.	It exist – search by DomainCode={Specified domain name}
	b.	IsAttribute is not true (=0)
	c.	It does not have child sub domains (not exist any domain where ParentDomainId={current domain id})
	d.	It does not have any related domain concepts (exist any DomainConcepts with DomainId={current domain id}).
5.	If the sub domain fails in at least one of the above checks then:                
	a.	Roll back transaction
	b.	Display error message – “Could not remove the specified vocabulary sub domain because:
		i.	It was not found in {VocabularyAdmin\Vocabulary} tables
		ii.	It is an Attribute domain, which is not allowed to be removed
		iii.	It has child sub domains
		iv.	It has related concept codes.
else reports as succeed.
*/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


/*provide @SubDomainCode to delete*/
DECLARE @SubDomainCode varchar(255)
SET @SubDomainCode  = '%SubDomainCode%'



DECLARE 
	@ROWCOUNT smallint,
	@DomainID bigint,
	@DomainID_Adm bigint,
	@SchemaName varchar(100),
    @ErrMessage varchar (255)

SET @ErrMessage = 'Could not remove the specified vocabulary sub domain because: '



/*It exist – search by DomainCode={Specified domain name}*/


DECLARE @Domains_2_Delete_Admin TABLE 
(
	DomainCode varchar(255),
	DomainID bigint,
	IsAttribute bit,
	IsHasChildren bit,
	IsHasDomainConcepts bit
	
)

DECLARE @Domains_2_Delete TABLE 
(
	DomainCode varchar(255),
	DomainID bigint,
	IsAttribute bit,
	IsHasChildren bit,
	IsHasDomainConcepts bit
)

/*VocabularyAdmin Domain information*/
INSERT INTO @Domains_2_Delete_Admin
	(
	DomainCode,
	DomainID ,
	IsAttribute ,
	IsHasChildren ,
	IsHasDomainConcepts 
	)
SELECT 
	DomainCode,
	DomainID ,
	IsAttribute ,
	IsHasChildren = 0,
	IsHasDomainConcepts = 0
FROM dbmVCDRData.VocabularyAdmin.Domain 
WHERE DomainCode =  @SubDomainCode 

SELECT @DomainID_Adm = DomainID
FROM @Domains_2_Delete_Admin

/*has children as sub-domains*/
UPDATE D2D
SET IsHasChildren = 1
FROM @Domains_2_Delete_Admin D2D
	INNER JOIN (
			select top 1 ParentDomainID
			from dbmVCDRData.VocabularyAdmin.Domain 
			where ParentDomainID = @DomainID_Adm ) D
		ON D2D.DomainID = D.ParentDomainID


/*has relevant concepts related to it*/
UPDATE D2D
SET IsHasDomainConcepts = 1
FROM @Domains_2_Delete_Admin D2D
	INNER JOIN 
	( select top 1 DomainID 
	  from dbmVCDRData.VocabularyAdmin.DomainConcepts 
	  where DomainID = @DomainID_Adm) DC
	ON D2D.DomainID = DC.DomainID


SELECT 'Sub Domain Details - Vocabulary Admin:'
SELECT 
	DomainCode,
	DomainID ,
	IsAttribute ,
	IsHasChildren ,
	IsHasDomainConcepts  
FROM @Domains_2_Delete_Admin



/*Vocabulary Domain information*/
INSERT INTO @Domains_2_Delete
	(
	DomainCode,
	DomainID ,
	IsAttribute ,
	IsHasChildren ,
	IsHasDomainConcepts 
	)
SELECT 
	DomainCode,
	DomainID ,
	IsAttribute ,
	IsHasChildren = 0,
	IsHasDomainConcepts = 0
FROM dbmVCDRData.Vocabulary.Domain 
WHERE DomainCode =  @SubDomainCode 


SELECT @DomainID = DomainID
FROM @Domains_2_Delete

/*has children as sub-domains*/
UPDATE D2D
SET IsHasChildren = 1
FROM @Domains_2_Delete D2D
	INNER JOIN (
			select top 1 ParentDomainID
			from dbmVCDRData.Vocabulary.Domain 
			where ParentDomainID = @DomainID ) D
		ON D2D.DomainID = D.ParentDomainID


/*has relevant concepts related to it*/
UPDATE D2D
SET IsHasDomainConcepts = 1
FROM @Domains_2_Delete D2D
	INNER JOIN 
	( select top 1 DomainID 
	  from dbmVCDRData.Vocabulary.DomainConcepts 
	  where DomainID = @DomainID) DC
	ON D2D.DomainID = DC.DomainID

SELECT 'Sub Domain Details - Vocabulary :'
SELECT 
	DomainCode,
	DomainID ,
	IsAttribute ,
	IsHasChildren ,
	IsHasDomainConcepts 
FROM @Domains_2_Delete


/*Domain was not found in {VocabularyAdmin\Vocabulary} tables*/
IF @DomainID_Adm IS NULL
BEGIN 
	SELECT  [Removal Status] = @ErrMessage + 'It was not found in VocabularyAdmin tables'
	GOTO EXIT_MARK
END

IF @DomainID IS NULL 
BEGIN 
	SELECT  [Removal Status] = @ErrMessage + 'It was not found in Vocabulary tables'
	GOTO EXIT_MARK
END
 
/*IsAttribute must be =0 otherwise domain will not deleted*/

if exists (select DomainID from @Domains_2_Delete_Admin where IsAttribute = 1) 
BEGIN 
--	SET @SchemaName='VocabularyAdmin'
	SELECT  [Removal Status] = @ErrMessage + 'It is an VocabularyAdmin Attribute domain, which is not allowed to be removed'
	GOTO EXIT_MARK
END

if exists (select DomainID from @Domains_2_Delete where IsAttribute = 1) 
BEGIN 
--	SET @SchemaName='Vocabulary'
	SELECT  [Removal Status] = @ErrMessage + 'It is an Vocabulary Attribute domain, which is not allowed to be removed'
	GOTO EXIT_MARK
END

/*It does not have child sub domains (not exist any domain where ParentDomainId={current domain id})*/

if exists (select DomainID from @Domains_2_Delete_Admin where IsHasChildren = 1 ) 
BEGIN 
--	SET @SchemaName='VocabularyAdmin'
	SELECT  [Removal Status] = @ErrMessage + 'It has child sub domains in VocabularyAdmin' 
	GOTO EXIT_MARK
END

if exists (select DomainID from @Domains_2_Delete where IsHasChildren = 1 ) 
BEGIN 
--	SET @SchemaName='Vocabulary'
	SELECT  [Removal Status] = @ErrMessage + 'It has child sub domains in VocabularyAdmin'
	GOTO EXIT_MARK
END

/*It does not have any related domain concepts (exist any DomainConcepts with DomainId={current domain id}).*/

if exists (select DomainID from @Domains_2_Delete_Admin where IsHasDomainConcepts = 1 ) 
BEGIN 
--	SET @SchemaName='VocabularyAdmin'
	SELECT [Removal Status] =  @ErrMessage + 'It has related concept codes in VocabularyAdmin'
	GOTO EXIT_MARK
END

if exists (select DomainID from @Domains_2_Delete where IsHasDomainConcepts = 1 ) 
BEGIN 
--	SET @SchemaName='Vocabulary'
	SELECT  [Removal Status] = @ErrMessage + 'It has related concept codes in Vocabulary'
	GOTO EXIT_MARK
END

/*Delete Domain that answer to delete conditions*/
  BEGIN TRY
		BEGIN TRANSACTION DelDomain
-- Amir		
		DELETE FROM [dbmVCDRData].[VocabularyAdmin].[DomainDesignation]
		WHERE DomainID = @DomainID_Adm

        SELECT [Number of Deleted Rows from VocabularyAdmin.DomainDesignation] = @@ROWCOUNT
--
		DELETE FROM [dbmVCDRData].[VocabularyAdmin].[Domain]
		WHERE DomainID = @DomainID_Adm
		
        SELECT [Number of Deleted Rows from VocabularyAdmin.Domain] = @@ROWCOUNT

-- Amir		
		DELETE FROM [dbmVCDRData].[Vocabulary].[DomainDesignation]
		WHERE DomainID = @DomainID	

        SELECT [Number of Deleted Rows from Vocabulary.DomainDesignation] = @@ROWCOUNT	

--
		DELETE FROM [dbmVCDRData].[Vocabulary].[Domain]
		WHERE DomainID = @DomainID 
		
        SELECT [Number of Deleted Rows from Vocabulary.Domain] = @@ROWCOUNT
        
		COMMIT TRANSACTION DelDomain;

            END TRY 
      BEGIN CATCH
            SELECT
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_SEVERITY() AS ErrorSeverity,
            ERROR_STATE() as ErrorState,
            ERROR_PROCEDURE() as ErrorProcedure,
            ERROR_LINE() as ErrorLine,
            ERROR_MESSAGE() as ErrorMessage,
                  'Delete process failed' as [Error];
					BEGIN
						ROLLBACK TRANSACTION DelDomain;
					END
					            
      END CATCH;
-----------------------------------------------------------------------------
EXIT_MARK:



