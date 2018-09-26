USE dbmVCDRData
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT D.DomainCode
FROM Vocabulary.CodeSystem CS
	 inner join Vocabulary.CodeSystemConcept CSC
		on CS.CodeSystemID = CSC.CodeSystemID
	 inner join Vocabulary.DomainConcepts DC
		on CSC.CSCID = DC.CSCID
	 inner join Vocabulary.Domain D
		on DC.DomainID = D.DomainID
	 inner join Vocabulary.ConceptDesignation CD
		on CSC.CSCID = CD.CSCID
WHERE CSC.ConceptCode like '%?%'