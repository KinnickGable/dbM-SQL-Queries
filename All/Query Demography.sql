use dbmVCDRData
-- use dbmVCDRDataHistory -- uncomment for querying the history CDR

declare @PatIdRoot varchar(100) 
declare @PatIdExt varchar(100)
declare @PatRecId bigint
declare @EncIdExt varchar(100)
declare @EncId bigint
declare @PatientName varchar(100)

/* 

	*** Execution Steps ***
	1. Set the values of the following parameters: 
		@PatientName - set one of the patient parts. The query will return results for the first patient that satisfy the name.
			OR
		@PatIdExt (The patient MRN)
			And optional
		@PatIdRoot (The patient MRN Root) - if not provided then query will return results for the first patient that satisfy the extension.
	2. Comment the rest of the patient parameters (by adding '-- ' before the "Set" instruction)
	3. Run the query - the query will return the selected patient details.
*/


--- *** Queries Parameters  *** ---
--Set @PatIdRoot='2.16.840.1.113883.3.57.1.3.10.14.1.8.3' 
Set @PatIdExt='00367801' 

-- set @PatientName='One' 


-- Retreives the internal PatientRecordId for the requrested patient
Set @PatRecId=
(
SELECT top 1
	    pi.PatientRecordId
		  FROM PatientAdministration.PatientRecord pr 
			left join PatientAdministration.PatientName pn 
				on pr.PatientRecordId=pn.PatientRecordId 
			left join [PatientAdministration].[PatientNamePart] pnp
				on pnp.PatientNameId=pn.PatientNameId
			left join dbmVCDRData.vocabulary.CodeSystemConcept gcsc
				on pr.AdministrativeGenderCodeID=gcsc.cscid
			left join PatientAdministration.PatientIdentifier pi
				on pr.PatientRecordId=pi.PatientRecordId
			
		where (pi.isprimary=1 and pi.extension=COALESCE(@PatIdExt,extension)
				and pi.root=COALESCE(@PatIdRoot,pi.root) 
				and (pnp.Value=COALESCE(@PatientName,pnp.value) or pnp.Value is null))
)

Select 'PatinetRecord Table'
Select 
	msg.Id_extension as MessageId,
	pr.PatientRecordId,prid.Extension as PrimaryIdExtension,prid.Root as PrimaryIdRoot,prid.AssigningAuthorityName as PrimaryIdAssigningAuthority
	,pr.BirthTime,GendCSC.ConceptCode as AdministrativeGenderCode, GendCD.Designation as AdministrativeGenderDes
	,GendCS.CodeSystem as GenderCodeSystem, GendDM.DomainCode as GenderDomain
	,MariCSC.ConceptCode as MaritalStatusCode, MariCD.Designation as MaritalStatusDes
	,EthnCSC.ConceptCode as EthnicGroupCode, EthnCD.Designation as EthnicGroupDes
	,ReliCSC.ConceptCode as ReligiousAffiliationCode, ReliCD.Designation as ReligiousAffiliationDes
	,RaceCSC.ConceptCode as RaceCode, RaceCD.Designation as RaceDes
	

From PatientAdministration.PatientRecord pr 
	left join PatientAdministration.PatientIdentifier prid
		on pr.PatientRecordId=prid.PatientRecordId and prid.IsPrimary=1
	left join dbmVCDRData.vocabulary.CodeSystemConcept GendCSC
		on pr.AdministrativeGenderCodeID=GendCSC.CSCID
	left join dbmVCDRData.vocabulary.CodeSystem GendCS 
		on GendCSC.CodeSystemId=GendCS.CodeSystemId
	left join dbmVCDRData.vocabulary.DomainConcepts GendDC
		on pr.AdministrativeGenderCodeID=GendDC.cscid
	left join dbmVCDRData.vocabulary.Domain GendDM
		on GendDC.DomainId=GendDM.DomainId
	left join dbmVCDRData.vocabulary.CodeSystemConcept MariCSC
		on pr.MaritalStatusCodeID=MariCSC.CSCID
	left join dbmVCDRData.vocabulary.CodeSystemConcept EthnCSC
		on pr.EthnicGroupCodeID=EthnCSC.CSCID
	left join dbmVCDRData.vocabulary.CodeSystemConcept ReliCSC
		on pr.ReligiousAffiliationCodeID=ReliCSC.CSCID
	left join dbmVCDRData.vocabulary.CodeSystemConcept RaceCSC
		on pr.RaceCodeID=RaceCSC.CSCID
	left join dbmVCDRData.vocabulary.ConceptDesignation GendCD
		on pr.AdministrativeGenderCodeID=GendCD.CSCID
	left join dbmVCDRData.vocabulary.ConceptDesignation MariCD
		on pr.MaritalStatusCodeID=MariCD.CSCID
	left join dbmVCDRData.vocabulary.ConceptDesignation EthnCD
		on pr.EthnicGroupCodeID=EthnCD.CSCID
	left join dbmVCDRData.vocabulary.ConceptDesignation ReliCD
		on pr.ReligiousAffiliationCodeID=ReliCD.CSCID
	left join dbmVCDRData.vocabulary.ConceptDesignation RaceCD
		on pr.RaceCodeID=RaceCD.CSCID
	inner join dbmVCDRData.MessageWrapper.ControlAct ca
		on Pr.ControlActId=ca.ControlActId
	inner join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
where pr.patientRecordId=@patrecid
	
Select 'PatientName and PatientNamePart tables'
Select 
	msg.Id_extension as MessageId,
	pn.PatientRecordId
	,pn.PatientNameID
	,ptcsc.conceptcode as namePartCode,pnp.value as namePartValue

from patientadministration.patientname pn 
	inner join patientadministration.patientnamepart pnp
		on pn.PatientNameID=pnp.PatientNameID
	inner join dbmVCDRData.vocabulary.CodeSystemConcept ptcsc
		on pnp.PartTypeID=ptcsc.cscid
	inner join dbmVCDRData.MessageWrapper.ControlAct ca
		on pn.ControlActId=ca.ControlActId
	inner join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
where pn.patientRecordId=@patrecid

Select 'PostalAddress and PostalAddressPart tables'
Select 
	msg.Id_extension as MessageId,
	pa.PatientRecordID
	,pa.PostalAddressID
	,pacsc.conceptcode as AddressPartCode,pacd.Designation as AddressPartDes,ap.value

from patientadministration.PostalAddress pa 
	left join patientadministration.AddressPart ap
		on pa.PostalAddressID=ap.PostalAddressID
	left join dbmVCDRData.vocabulary.CodeSystemConcept pacsc
		on ap.PartTypeID=pacsc.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation pacd
		on ap.PartTypeID=pacd.cscid
	left join dbmVCDRData.MessageWrapper.ControlAct ca
		on Pa.ControlActId=ca.ControlActId
	left join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
where pa.patientRecordId=@patrecid

Select 'PatientTelecom table'
Select 
	msg.Id_extension as MessageId,
	pt.PatientRecordId
	,pt.PatientTelecomID
	,pt_use_csc.conceptcode as TelecomUseCode,pt_use_cd.designation as TelecomUseDes
	,pt_sch_csc.conceptcode as SchemeCode,pt_sch_cd.designation as SchemeDes
	,pt.value

from patientadministration.PatientTelecom pt 
	left join dbmVCDRData.vocabulary.CodeSystemConcept pt_use_csc
		on pt.UseID=pt_use_csc.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation pt_use_cd
		on pt.UseID=pt_use_cd.cscid
	left join dbmVCDRData.vocabulary.CodeSystemConcept pt_sch_csc
		on pt.SchemeID=pt_sch_csc.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation pt_sch_cd
		on pt.SchemeID=pt_sch_cd.cscid
	inner join dbmVCDRData.MessageWrapper.ControlAct ca
		on Pt.ControlActId=ca.ControlActId
	inner join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
where pt.patientRecordId=@patrecid

Select 'PrimaryCareProvider table'
Select 
	msg.Id_extension as MessageId,
	pcp.PatientRecordID
	,pcp.Id_Root ,pcp.Id_Extension
	,pcp_code.ConceptCode,pcp_cd.Designation
	,msid.extension as MedicalStaffIdExt, ms.name as MedicalStaffName
	
From patientadministration.primarycareprovider pcp
	left join dbmVCDRData.vocabulary.CodeSystemConcept pcp_code
		on pcp.CodeId=pcp_code.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation pcp_cd
		on pcp.CodeId=pcp_cd.cscid
	left join common.MedicalStaff ms
		on pcp.MedicalStaffId=ms.MedicalStaffId
	left join common.MedicalStaffIdentifier msid
		on ms.MedicalStaffId=msid.MedicalStaffId and msid.isprimary=1
	inner join dbmVCDRData.MessageWrapper.ControlAct ca
		on pcp.ControlActId=ca.ControlActId
	inner join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
where pcp.patientRecordId=@patrecid

Select 'CoveredParty Table'
Select 
		msg.Id_extension as MessageId,
		cp.PatientRecordId
		,cp.CoveredPartyId
		,cp.sequenceNumber
		,CodeCSC.ConceptCode as Code,CodeCD.Designation as CodeDes
		,InsOrg.Id_extension as InsurerOrgIdExt, InsOrg.Name as InsurerOrgName
		--,pid.extension
From PatientAdministration.CoveredParty cp
	left join dbmVCDRData.vocabulary.CodeSystemConcept CodeCSC
		on cp.CodeId=CodeCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation CodeCD
		on cp.CodeId=CodeCD.cscid
	left join Common.Organization InsOrg
		on cp.OrganizationId=InsOrg.OrganizationId
	left join PatientAdministration.Encounter enc
		on cp.EncounterId=enc.EncounterId
	left join PatientAdministration.PatientIdentifier pid
		on enc.PatientRecordId=pid.PatientRecordId and pid.isprimary=1
	inner join dbmVCDRData.MessageWrapper.ControlAct ca
		on cp.ControlActId=ca.ControlActId
	inner join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
where cp.patientRecordId=@patrecid

Select 'PatientRelationship Table'
Select 
	prel.PatientRecordId_scoper as [PatientRecordId_Scoper (New)]
	,rel_pid.Extension as [PatientIdExt_Player (Old)]
	,rel_pid.root as [PatientIdRoot_Player (Old)]
	,ClassCSC.ConceptCode as RelationClassCode

From PatientAdministration.PatientRelationship prel
	inner join PatientAdministration.PatientIdentifier rel_pid
		on prel.PatientRecordID_Player=rel_pid.PatientRecordId
	inner join Vocabulary.CodeSystemConcept ClassCSC
		on prel.ClassCodeID=ClassCSC.cscid
where prel.patientRecordId_Scoper=@patrecid

	