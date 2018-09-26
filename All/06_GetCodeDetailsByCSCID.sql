
USE dbmVCDRData
go
DECLARE @CSCID int
SET @CSCID='22'

SELECT     Vocabulary.CodeSystemConcept.CSCID, Vocabulary.CodeSystemConcept.ConceptCode, Vocabulary.ConceptDesignation.Designation, 
                      Vocabulary.CodeSystem.CodeSystem, Vocabulary.CodeSystem.CodeSystemName, Vocabulary.Domain.DomainCode, 
                      Vocabulary.DomainConcepts.IsBaseline
FROM         Vocabulary.CodeSystemConcept INNER JOIN
                      Vocabulary.CodeSystem ON Vocabulary.CodeSystemConcept.CodeSystemID = Vocabulary.CodeSystem.CodeSystemID INNER JOIN
                      Vocabulary.ConceptDesignation ON Vocabulary.CodeSystemConcept.CSCID = Vocabulary.ConceptDesignation.CSCID INNER JOIN
                      Vocabulary.DomainConcepts ON Vocabulary.CodeSystemConcept.CSCID = Vocabulary.DomainConcepts.CSCID INNER JOIN
                      Vocabulary.Domain ON Vocabulary.DomainConcepts.DomainID = Vocabulary.Domain.DomainID AND 
                      Vocabulary.DomainConcepts.DomainID = Vocabulary.Domain.DomainID

WHERE     (Vocabulary.CodeSystemConcept.CSCID = @CSCID)