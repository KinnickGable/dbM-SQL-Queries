declare @dbmAvailabilityTime datetime
select @dbmAvailabilityTime=GETDATE()-300

Select d.domaincode
	,csc.ConceptCode
	,cd.designation
	,cs.CodeSystem
	,cs.CodeSystemName
	,cs.OriginalCodeSystem
	,cs.Description
	,csc.EffectiveTimeStart
	,csc.EffectiveTimeEnd
	,bcsc.ConceptCode as BaselineCode
	,bcs.CodeSystem as BaselineCodeSystem
	,bcs.CodeSystemName as BaselineCodeSystemName
	,*
from  dbmVCDRData.Vocabulary.CodeSystem cs
		inner join dbmVCDRData.Vocabulary.codesystemconcept csc
			on cs.CodeSystemId=csc.CodeSystemId
		inner join dbmVCDRData.Vocabulary.ConceptDesignation cd
			on csc.cscid=cd.cscid
		inner join dbmVCDRData.Vocabulary.DomainConcepts dc
			on csc.cscid=dc.cscid
		inner join dbmVCDRData.Vocabulary.Domain d
			on dc.domainid=d.domainid
		left join dbmVCDRData.Vocabulary.CodeSystemConcept bcsc
			on dc.MappedToDomCon=bcsc.cscid
		left join dbmVCDRData.Vocabulary.CodeSystem bcs
			on bcs.CodeSystemId=bcsc.CodeSystemId
		left join dbmVCDRData.Vocabulary.Domain rd
			on d.RootId=rd.DomainId
		join ( 
	
			-- labs
				SELECT   [CodeID]as codeID   ,COUNT(*)as Occurences
				FROM [dbmVCDRData].[Laboratory].[LaboratoryResult] 
				where dbmAvailabilityTime>@dbmAvailabilityTime 
				group by  Codeid 
				
				union
				SELECT  [StatusCodeID]as codeID  ,COUNT(*)as Occurences
				FROM [dbmVCDRData].[Laboratory].[LaboratoryResult]
				where dbmAvailabilityTime>@dbmAvailabilityTime 
				 group by StatusCodeID
				union
				SELECT    [PriorityCodeID]as codeID  ,COUNT(*)as Occurences
				FROM [dbmVCDRData].[Laboratory].[LaboratoryResult] 
				where dbmAvailabilityTime>@dbmAvailabilityTime 
				group by PriorityCodeID
				union
				SELECT    [MethodCodeID]as codeID   ,COUNT(*)as Occurences
				FROM [dbmVCDRData].[Laboratory].[LaboratoryResult] 
				where dbmAvailabilityTime>@dbmAvailabilityTime 
				group by MethodCodeID
	  		-- documents
	    		union
				select codeid,count(*) as Occurences
				from [dbmVCDRData].[ClinicalDocument].ClinicalDocument  
				where dbmAvailabilityTime>@dbmAvailabilityTime 
				group by Codeid
			-- Imaging
	    		union 
				select codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingStudy 
				where dbmAvailabilityTime>@dbmAvailabilityTime
				group by Codeid
					union
				select methodcodeid as codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingStudy 
				where dbmAvailabilityTime>@dbmAvailabilityTime
				group by MethodCodeID
									union
				select codeid as codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingRequest 
				where dbmAvailabilityTime>@dbmAvailabilityTime
				group by Codeid
		-- Encounters
	    		union 
				select CodeID  as codeid,count(*) as Occurences
				from [dbmVCDRData].[PatientAdministration].[Encounter] 
					where dbmAvailabilityTime>@dbmAvailabilityTime group by  Codeid
					union 
				select PriorityCodeID  as codeid,count(*) as Occurences
				from [dbmVCDRData].[PatientAdministration].[Encounter] 
					where dbmAvailabilityTime>@dbmAvailabilityTime group by  PriorityCodeID
					union 
				select StatusCodeID  as codeid,count(*) as Occurences
				from [dbmVCDRData].[PatientAdministration].[Encounter] 
					where dbmAvailabilityTime>@dbmAvailabilityTime group by  StatusCodeID
					union 
				select dbmClassCodeID  as codeid,count(*) as Occurences
				from [dbmVCDRData].[PatientAdministration].[Encounter] 
					where dbmAvailabilityTime>@dbmAvailabilityTime group by  dbmClassCodeID
									union 
				select AdmissionReferralSourceCodeID  as codeid,count(*) as Occurences
				from [dbmVCDRData].[PatientAdministration].[Encounter]
					where dbmAvailabilityTime>@dbmAvailabilityTime  group by  AdmissionReferralSourceCodeID
									union 
				select DischargeDispositionCodeID  as codeid,count(*) as Occurences
				from [dbmVCDRData].[PatientAdministration].[Encounter] 
					where dbmAvailabilityTime>@dbmAvailabilityTime group by  DischargeDispositionCodeID
		-- Conditions
				
				 Union 
					select  codeid as codeid,count(*) as Occurences
				from [dbmVCDRData].[Condition].[Condition]
					where dbmAvailabilityTime>@dbmAvailabilityTime  group by  CodeID
				 Union
					select  valueid as Valueid,count(*) as Occurences
				from [dbmVCDRData].[Condition].[Condition] 
					where dbmAvailabilityTime>@dbmAvailabilityTime group by  ValueID
				 Union 
					select  TargetSiteCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Condition].[Condition] 
					where dbmAvailabilityTime>@dbmAvailabilityTime group by  TargetSiteCodeID
				
				Union
					select  codeid as codeid,count(*) as Occurences
				from [dbmVCDRData].[Allergy].[AllergyIntolerance] 
					where dbmAvailabilityTime>@dbmAvailabilityTime group by  CodeID
		--Allergy
				 Union
					select  valueid as codeid,count(*) as Occurences
				from [dbmVCDRData].[Allergy].[AllergyIntolerance]  
					where dbmAvailabilityTime>@dbmAvailabilityTime group by ValueID
				
				 Union 
					select  MethodCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Allergy].[AllergyIntolerance]  
					where dbmAvailabilityTime>@dbmAvailabilityTime group by  MethodCodeID
				
				Union 
					select  SeverityValueID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Allergy].[AllergyIntolerance]  
				where dbmAvailabilityTime>@dbmAvailabilityTime group by  SeverityValueID 
			
			
				) UsedCodes
			on csc.CSCID=codeID
		
	Order by  cd.Designation,cs.CodeSystem,d.DomainCode, usedcodes.Occurences desc