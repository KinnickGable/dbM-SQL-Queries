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
		join ( -- labs
				SELECT   [CodeID]as codeID   ,COUNT(*)as Occurences
				FROM [dbmVCDRData].[Laboratory].[LaboratoryResult] group by [CodeID]
				union
				SELECT  [StatusCodeID]as codeID  ,COUNT(*)as Occurences
				FROM [dbmVCDRData].[Laboratory].[LaboratoryResult] group by StatusCodeID
				union
				SELECT    [PriorityCodeID]as codeID  ,COUNT(*)as Occurences
				FROM [dbmVCDRData].[Laboratory].[LaboratoryResult] group by PriorityCodeID
				union
				SELECT    [MethodCodeID]as codeID   ,COUNT(*)as Occurences
				FROM [dbmVCDRData].[Laboratory].[LaboratoryResult] group by MethodCodeID
	    		-- documents
	    		union
				select codeid,count(*) as Occurences
				from [dbmVCDRData].[ClinicalDocument].ClinicalDocument group by Codeid
				 		-- Imaging
	    		union 
				select codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingStudy group by Codeid
					union
				select methodcodeid as codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingStudy group by MethodCodeID
									union
				select codeid as codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingRequest group by Codeid
						-- Encounters
	    		union 
				select CodeID  as codeid,count(*) as Occurences
				from [dbmVCDRData].[PatientAdministration].[Encounter] group by  Codeid
					union 
				select PriorityCodeID  as codeid,count(*) as Occurences
				from [dbmVCDRData].[PatientAdministration].[Encounter] group by  PriorityCodeID
					union 
				select StatusCodeID  as codeid,count(*) as Occurences
				from [dbmVCDRData].[PatientAdministration].[Encounter] group by  StatusCodeID
					union 
				select dbmClassCodeID  as codeid,count(*) as Occurences
				from [dbmVCDRData].[PatientAdministration].[Encounter] group by  dbmClassCodeID
									union 
				select AdmissionReferralSourceCodeID  as codeid,count(*) as Occurences
				from [dbmVCDRData].[PatientAdministration].[Encounter] group by  AdmissionReferralSourceCodeID
									union 
				select DischargeDispositionCodeID  as codeid,count(*) as Occurences
				from [dbmVCDRData].[PatientAdministration].[Encounter] group by  DischargeDispositionCodeID
				 		-- Conditions
				
				 Union 
					select  codeid as codeid,count(*) as Occurences
				from [dbmVCDRData].[Condition].[Condition] group by  CodeID
				 Union
					select  valueid as codeid,count(*) as Occurences
				from [dbmVCDRData].[Condition].[Condition] group by  ValueID
				 Union 
					select  TargetSiteCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Condition].[Condition] group by  TargetSiteCodeID
						 Union 
					select  MethodCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Condition].[Condition] group by  methodCodeID
				 Union
					select  Materialid as codeid,count(*) as Occurences
				from [dbmVCDRData].[Condition].[Condition] group by  MaterialID
				 Union 
					select  dbmClassCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Condition].[Condition] group by  dbmClassCodeID
				 Union
				select StatusCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Condition].[Condition] group by  StatusCodeID
				 Union 
					select  ObservationStatus_ValueID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Condition].[Condition] group by  ObservationStatus_ValueID
				/*  SubstanceAdministration */
				 Union 
					select  codeid as codeid,count(*) as Occurences
				from [dbmVCDRData].[Medication].[SubstanceAdministration] 	 group by  CodeID
				 Union
					select  StatusCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Medication].[SubstanceAdministration] group by  StatusCodeID
				 Union 
					select  PriorityCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Medication].[SubstanceAdministration] group by  PriorityCodeID
				 Union 
					select AdministrationUnitCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Medication].[SubstanceAdministration] group by  AdministrationUnitCodeID
				 Union 
					select ApproachSiteCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Medication].[SubstanceAdministration] group by  ApproachSiteCodeID
				 Union 
					select  DoseQuantity_UnitCodeID as   codeid,count(*) as Occurences
				from [dbmVCDRData].[Medication].[SubstanceAdministration] group by  DoseQuantity_UnitCodeID
				 Union 
				select  RouteCodeID as   codeid,count(*) as Occurences
				from [dbmVCDRData].[Medication].[SubstanceAdministration] group by  RouteCodeID
				 Union 
				select  MaterialID as   codeid,count(*) as Occurences
				from [dbmVCDRData].[Medication].[SubstanceAdministration] group by  MaterialID
				 Union 
				select  GenericMaterialID as   codeid,count(*) as Occurences
				from [dbmVCDRData].[Medication].[SubstanceAdministration] group by  GenericMaterialID
				/* Material */
					 Union 
				select  Codeid as   codeid,count(*) as Occurences
				from [dbmVCDRData].[Common].[Material] group by  CodeID
				 Union 
				select  Codeid as   codeid,count(*) as Occurences
				from [dbmVCDRData].[Common].[Material] group by  CodeID
				) UsedCodes
			on csc.CSCID=codeID
		
	Order by cs.CodeSystem,d.DomainCode, usedcodes.Occurences desc