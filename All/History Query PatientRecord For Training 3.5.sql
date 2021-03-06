use dbmVCDRData
use dbmVCDRDataHistory -- uncomment for querying the history CDR
--Use for querying Patient History
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
--Set @PatIdRoot='2.16.840.1.113883.3.57.1.3.11.11.1.8.2' 
Set @PatIdExt='Trainee1_Patient1' 
-- set @PatientName='One' 


-- Retreives the internal PatientRecordId for the requrested patient
Set @PatRecId=
(
SELECT top 1
	    pi.PatientRecordId
		  FROM PatientAdministration.PatientRecord pr 
			left join PatientAdministration.PatientIdentifier pi
				on pr.PatientRecordId=pi.PatientRecordId
			
		where (pi.isprimary=1 and pi.extension=COALESCE(@PatIdExt,extension)
				and pi.root=COALESCE(@PatIdRoot,pi.root)) 
)

select @PatRecId

Select 'PatinetRecord Table'
Select distinct
pr.PatientRecordId,prid.Extension as PrimaryIdExtension,prid.Root as PrimaryIdRoot,prid.AssigningAuthorityName as PrimaryIdAssigningAuthority
	,pr.BirthTime,GendCSC.ConceptCode as AdministrativeGenderCode, GendCD.Designation as AdministrativeGenderDes
	,GendCS.CodeSystem as GenderCodeSystem, GendDM.DomainCode as GenderDomain
	,MariCSC.ConceptCode as MaritalStatusCode, MariCD.Designation as MaritalStatusDes
	,EthnCSC.ConceptCode as EthnicGroupCode, EthnCD.Designation as EthnicGroupDes
	,ReliCSC.ConceptCode as ReligiousAffiliationCode, ReliCD.Designation as ReligiousAffiliationDes
	,RaceCSC.ConceptCode as RaceCode, RaceCD.Designation as RaceDes
	,msg.Id_extension as MessageId

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
	pn.PatientRecordId
	,pn.PatientNameID
	,ptcsc.conceptcode as namePartCode,pnp.value as namePartValue
	,msg.Id_extension as MessageId

from dbmVCDRData.patientadministration.patientname pn 
	inner join patientadministration.patientnamepart pnp
		on pn.PatientNameID=pnp.PatientNameID
	inner join dbmVCDRData.vocabulary.CodeSystemConcept ptcsc
		on pnp.PartTypeID=ptcsc.cscid
	inner join dbmVCDRData.MessageWrapper.ControlAct ca
		on pnp.ControlActId=ca.ControlActId
	inner join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
where pn.patientRecordId=@patrecid

Select 'PostalAddress and PostalAddressPart tables'
Select 
	pa.PatientRecordID
	,pa.PostalAddressID
	,pacsc.conceptcode as AddressPartCode,pacd.Designation as AddressPartDes,ap.value
	,msg.Id_extension as MessageId

from dbmVCDRData.patientadministration.PostalAddress pa 
	left join patientadministration.AddressPart ap
		on pa.PostalAddressID=ap.PostalAddressID
	left join dbmVCDRData.vocabulary.CodeSystemConcept pacsc
		on ap.PartTypeID=pacsc.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation pacd
		on ap.PartTypeID=pacd.cscid
	inner join dbmVCDRData.MessageWrapper.ControlAct ca
		on ap.ControlActId=ca.ControlActId
	inner join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
where pa.patientRecordId=@patrecid

Select 'PatientTelecom table'
Select 
	pt.PatientRecordId
	,pt.PatientTelecomID
	,pt_use_csc.conceptcode as TelecomUseCode,pt_use_cd.designation as TelecomUseDes
	,pt_sch_csc.conceptcode as SchemeCode,pt_sch_cd.designation as SchemeDes
	,pt.value
	,msg.Id_extension as MessageId

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

