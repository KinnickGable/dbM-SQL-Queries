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
		/*	select R.PriorityCodeID   as CodeID,COUNT(*)as Occurences
					from  dbmVCDRData.Laboratory.LaboratoryRequest r group by PriorityCodeID
						union
			select R.StatusCodeID   as CodeID,COUNT(*)as Occurences
					from  dbmVCDRData.Laboratory.LaboratoryRequest r group by StatusCodeID
						union
				select e.ClusterCodeID as CodeID,COUNT(*)as Occurences
					from  dbmVCDRData.Laboratory.LaboratoryEvent e group by ClusterCodeID
						union
				select e.CodeID   as CodeID,COUNT(*)as Occurences
					from  dbmVCDRData.Laboratory.LaboratoryEvent e group by CodeID
						union
				select e.PriorityCodeID   as CodeID,COUNT(*)as Occurences
					from  dbmVCDRData.Laboratory.LaboratoryEvent e group by PriorityCodeID
						union
				select e.StatusCodeID   as CodeID,COUNT(*)as Occurences
					from  dbmVCDRData.Laboratory.LaboratoryEvent e group by StatusCodeID
						union
				select e.StructureTypeCodeID   as CodeID,COUNT(*)as Occurences
					from  dbmVCDRData.Laboratory.LaboratoryEvent e group by StructureTypeCodeID
						union
				--select e.dbmClassCodeID   as CodeID
				--	from  dbmVCDRData.Laboratory.LaboratoryEvent e group by e.dbmClassCodeID
				--		union
						
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
				from [dbmVCDRData].[ClinicalDocument].ClinicalDocument d group by Codeid
				union
				select d.CompletionCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[ClinicalDocument].ClinicalDocument d group by CompletionCodeID
								union
				select d.StatusCodeID,count(*) as Occurences
				from [dbmVCDRData].[ClinicalDocument].ClinicalDocument d group by StatusCodeID 
				-- Imaging 
				 		
	    		union  */
	    		 	select r.CodeID as codeid ,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingRequest r group by CodeID
	    		Union
	    		select r.DeviceID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingRequest r group by DeviceID
					union
				select r.ImagingTypeCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingRequest r group by ImagingTypeCodeID
					union	
				select r.MoodCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingRequest r group by MoodCodeID
					union	
				select r.PriorityCodeID as CodeID,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingRequest r group by PriorityCodeID
					union
				select r.StatusCodeID codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingRequest r group by StatusCodeID
							union
	    		select r.TargetCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingRequest r group by TargetCodeID

					union
				select i.codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingStudy i group by Codeid
					union
				select i.DeviceID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingStudy i group by DeviceID
					union
				select i.ImagingTypeCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingStudy i group by ImagingTypeCodeID
					union
				select i.InterpretationCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingStudy i group by InterpretationCodeID
					union
	    		select i.MoodCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingStudy i group by MoodCodeID
					union
	    		select i.PriorityCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingStudy i group by PriorityCodeID
									union
	    		select i.StatusCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingStudy i group by StatusCodeID
									union
	    		select i.TargetCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingStudy i group by TargetCodeID
									union
	    		select i.UncertaintyCodeID as codeid,count(*) as Occurences
				from [dbmVCDRData].[Imaging].ImagingStudy i group by UncertaintyCodeID
						-- Encounters
	    /*		union 
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
				*/
				) UsedCodes
			on csc.CSCID=codeID
		
	Order by cs.CodeSystem,d.DomainCode, usedcodes.Occurences desc