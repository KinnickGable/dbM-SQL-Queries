use dbmVCDRData 

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
--Set @PatIdRoot='2.16.840.1.113883.3.57.1.3.10.13.1.8.3' 
Set @PatIdExt='00367801' 
Set @PatIdExt='87654321' 
--set @PatientName='Hiram' 


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
				and (pnp.Value=COALESCE(@PatientName,pnp.value)))
)


Select 'Encounter table'
Select 
		enc.dbmavailabilityTime,pid.Root, pid.Extension as MRN
		,enc.EncounterId,enc.Id_Root,enc.Id_Extension,enc.EffectiveTime_Start,enc.EffectiveTime_End
	    ,CodeCSC.ConceptCode as Code, CodeCD.Designation as CodeDes, CodeCS.CodeSystem, CodeDM.DomainCode
		,AssOrg.Id_Extension as AssignedOrgIdExt ,AssOrg.Name as AssignedOrgName 
		,StatCSC.ConceptCode as StatusCode
		,PrioCSC.ConceptCode as PriorityCode ,PrioCD.Designation as PriorityDes
		,AdRefCSC.ConceptCode as AdmissionReferralCode ,AdRefCD.Designation as AdmissionReferralDes
		,DiscCSC.ConceptCode as DischargeDispositionCode,DiscCD.Designation as DischargeDispositionDes
		,RefOrg.Id_Extension as ReferrerOrgIdExt ,RefOrg.Name as ReferrerOrgName 
		,msg.Id_extension as MessageId
	    

from patientadministration.encounter enc 
	left join dbmVCDRData.vocabulary.CodeSystemConcept CodeCSC 
		on enc.CodeId=CodeCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation CodeCD 
		on enc.CodeId=CodeCD.cscid
	left join dbmVCDRData.vocabulary.CodeSystem CodeCS 
		on CodeCSC.CodeSystemId=CodeCS.CodeSystemId
	left join dbmVCDRData.vocabulary.DomainConcepts CodeDC
		on enc.CodeID=CodeDC.cscid
	left join dbmVCDRData.vocabulary.Domain CodeDM
		on CodeDC.DomainId=CodeDM.DomainId
	left join dbmVCDRData.vocabulary.CodeSystemConcept StatCSC 
		on enc.StatusCodeId=StatCSC.cscid
	left join dbmVCDRData.vocabulary.CodeSystemConcept PrioCSC 
		on enc.PriorityCodeId=PrioCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation PrioCD 
		on enc.PriorityCodeId=PrioCD.cscid
	left join dbmVCDRData.vocabulary.CodeSystemConcept AdRefCSC 
		on enc.AdmissionReferralSourceCodeID=AdRefCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation AdRefCD 
		on enc.AdmissionReferralSourceCodeID=AdRefCD.cscid	
	left join dbmVCDRData.vocabulary.CodeSystemConcept DiscCSC 
		on enc.DischargeDispositionCodeId=DiscCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation DiscCD 
		on enc.DischargeDispositionCodeId=DiscCD.cscid
	left join Common.Organization AssOrg
		on enc.AssignedOrganizationId=AssOrg.OrganizationId
	left join Common.Organization RefOrg
		on enc.ReferrerOrganizationId=RefOrg.OrganizationId
	inner join dbmVCDRData.MessageWrapper.ControlAct ca
		on enc.ControlActId=ca.ControlActId
	inner join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
	inner join PatientAdministration.PatientIdentifier pid
		on enc.PatientRecordId=pid.PatientRecordId and pid.isprimary=1

where enc.PatientRecordId=@PatRecId
order by enc.dbmavailabilityTime desc

