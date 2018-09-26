
USE dbmVCDRData
go
DECLARE @CSCID int
SET @CSCID='14932'

SELECT     Vocabulary.CodeSystemConcept.CSCID, Vocabulary.CodeSystemConcept.ConceptCode, Vocabulary.ConceptDesignation.Designation, 
                      Vocabulary.CodeSystem.CodeSystem, Vocabulary.CodeSystem.CodeSystemName, Vocabulary.Domain.DomainCode, 
                      Vocabulary.DomainConcepts.IsBaseline
FROM         Vocabulary.CodeSystemConcept with (NOLOCK) INNER JOIN
                      Vocabulary.CodeSystem with (NOLOCK) ON Vocabulary.CodeSystemConcept.CodeSystemID = Vocabulary.CodeSystem.CodeSystemID INNER JOIN
                      Vocabulary.ConceptDesignation with (NOLOCK) ON Vocabulary.CodeSystemConcept.CSCID = Vocabulary.ConceptDesignation.CSCID INNER JOIN
                      Vocabulary.DomainConcepts with (NOLOCK) ON Vocabulary.CodeSystemConcept.CSCID = Vocabulary.DomainConcepts.CSCID INNER JOIN
                      Vocabulary.Domain with (NOLOCK) ON Vocabulary.DomainConcepts.DomainID = Vocabulary.Domain.DomainID AND 
                      Vocabulary.DomainConcepts.DomainID = Vocabulary.Domain.DomainID

WHERE     (Vocabulary.CodeSystemConcept.CSCID = @CSCID)