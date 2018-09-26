SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

use dbmVCDRData

Select d.domaincode,csc.ConceptCode,cd.designation,cs.CodeSystem,cs.CodeSystemName,cs.OriginalCodeSystem,cs.Description,csc.EffectiveTimeStart,csc.EffectiveTimeEnd
	,bcsc.ConceptCode as BaselineCode,bcs.CodeSystem as BaselineCodeSystem,bcs.CodeSystemName as BaselineCodeSystemName
from Vocabulary.CodeSystem cs
		inner join Vocabulary.codesystemconcept csc
			on cs.CodeSystemId=csc.CodeSystemId
		inner join Vocabulary.ConceptDesignation cd
			on csc.cscid=cd.cscid
		inner join Vocabulary.DomainConcepts dc
			on csc.cscid=dc.cscid
		inner join Vocabulary.Domain d
			on dc.domainid=d.domainid
		left join Vocabulary.CodeSystemConcept bcsc
			on dc.MappedToDomCon=bcsc.cscid
		left join Vocabulary.CodeSystem bcs
			on bcs.CodeSystemId=bcsc.CodeSystemId
		left join Vocabulary.Domain rd
			on d.RootId=rd.DomainId
--where cd.designation like '%preliminary%' and d.domaincode='ActStatus'
--where d.domaincode='ClusterType'
--where cs.codeSystem='2.16.840.1.113883.3.57.1.3.11.17.2.68'
-- where (d.domaincode='TestType' or d.domaincode='BatteryType') and dc.IsBaseline=1 --dc.MappedToDomCon>0
--where csc.ConceptCode='Deleted'
where cs.CodeSystem like '2.16.840.1.113883.3.57.1.3.100.13.%'

Select pd.DomainCode as RootDomain,d.domaincode,csc.ConceptCode,cd.designation,cs.CodeSystem,cs.CodeSystemName,cs.OriginalCodeSystem,cs.Description,csc.EffectiveTimeStart,csc.EffectiveTimeEnd
	,bcsc.ConceptCode as BaselineCode,bcs.CodeSystem as BaselineCodeSystem,bcs.CodeSystemName as BaselineCodeSystemName, csc.lastpublished,csc.lastmodified,csc.approvalstatus
from VocabularyAdmin.CodeSystem cs
		inner join VocabularyAdmin.codesystemconcept csc
			on cs.CodeSystemId=csc.CodeSystemId
		inner join VocabularyAdmin.ConceptDesignation cd
			on csc.cscid=cd.cscid
		left join VocabularyAdmin.DomainConcepts dc
			on csc.cscid=dc.cscid
		left join VocabularyAdmin.Domain d
			on dc.domainid=d.domainid
		left join VocabularyAdmin.Domain pd
			on d.rootid=pd.domainid
		left join VocabularyAdmin.CodeSystemConcept bcsc
			on dc.MappedToDomCon=bcsc.cscid
		left join VocabularyAdmin.CodeSystem bcs
			on bcs.CodeSystemId=bcsc.CodeSystemId
--where cd.designation like '%preliminary%' and d.domaincode='ActStatus'
--where d.domaincode='ClusterType'
--where cs.codeSystem='2.16.840.1.113883.3.57.1.3.11.17.2.68'
-- where (d.domaincode='TestType' or d.domaincode='BatteryType') and dc.IsBaseline=1 --dc.MappedToDomCon>0
--where csc.ConceptCode='Deleted'
--where dc.domainid is null
where dc.state=8