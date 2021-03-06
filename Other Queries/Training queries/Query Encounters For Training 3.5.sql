use dbmVCDRData
-- use dbmVCDRDataHistory -- uncomment for querying the history CDR
--Use for query of current Encounter record
declare @EncIdExt varchar(100)
declare @EncId bigint
declare @PatientName varchar(100)

/* 

	*** Execution Steps ***
	1. Set the Value of the @EncIdExt (Encouter Id Extension) parameter.
	2. Run the query - the query will return the selected encounter details.

*/


--- *** Queries Parameters  *** ---
set @EncIdExt='Trainee1_Encounter1' 

Set @EncId=(select top 1 enc.EncounterId
			from patientadministration.encounter enc
			where enc.id_extension=@EncIdExt ) --and enc.id_root!='2.16.840.1.113883.3.57.1.3.11.13.1.9')


Select 'Encounter table'
Select 
		pid.Root, pid.Extension as MRN
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

where enc.EncounterId=@EncId

Select 'ServiceProviderUnit table'
Select 
		spu.EncounterId
		,spu.ServiceProviderUnitID,spu.Id_Extension,spu.Time_Start
		,SPUCCSC.ConceptCode ServiceCode ,SPUCCD.Designation ServiceDes
		,SPUStatCSC.ConceptCode StatusCode
		,SPUOrg.Id_Extension as OrgIdExt, SPUOrg.Name as OrgName
		,spu.dbmAvailabilityTime
		,msg.Id_extension as MessageId
	   
		--,arc.MessageText,arc.archtime
from PatientAdministration.ServiceProviderUnit spu
	left join dbmVCDRData.vocabulary.CodeSystemConcept SPUCCSC
		on spu.codeid=SPUCCSC.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation SPUCCD
		on spu.codeid=SPUCCD.cscid
	left join dbmVCDRData.vocabulary.CodeSystemConcept SPUStatCSC
		on spu.StatusCodeId=SPUStatCSC.cscid
	left join Common.Organization SPUOrg
		on spu.OrganizationID=SPUOrg.OrganizationID
	inner join dbmVCDRData.MessageWrapper.ControlAct ca
		on spu.ControlActId=ca.ControlActId
	inner join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
	inner join dbmDILMessagesArchive.dbo.ArchMessage arc
		on msg.InterchangeId=arc.BTSInterchangeID

where spu.EncounterId=@EncId
order by spu.dbmAvailabilityTime desc

Select 'AttenderPractitioner Table'
Select 
		atp.EncounterId
		,atp.AttenderPracticionerId
	    ,atp.id_extension
		,ptcsc.ConceptCode as PracticionerTypeCode ,ptcd.designation as PracticionerTypeDes
		,msid.extension as MedicalStaffIdExt, ms.name as MedicalStaffName, atp.dbmAvailabilityTime
		,msg.Id_extension as MessageId

From PatientAdministration.AttenderPracticioner atp
	left join dbmVCDRData.vocabulary.CodeSystemConcept ptcsc
		on atp.TypeCodeId=ptcsc.cscid
	left join dbmVCDRData.vocabulary.ConceptDesignation ptcd
		on atp.TypeCodeId=ptcd.cscid
	left join common.MedicalStaff ms
		on atp.MedicalStaffId=ms.MedicalStaffId
	left join common.MedicalStaffIdentifier msid
		on ms.MedicalStaffId=msid.MedicalStaffId and msid.isprimary=1
	inner join dbmVCDRData.MessageWrapper.ControlAct ca
		on atp.ControlActId=ca.ControlActId
	inner join dbmVCDRData.MessageWrapper.Message msg
		on msg.MessageId=ca.MessageId
where atp.EncounterId=@EncId
order by atp.dbmAvailabilityTime desc

Select 'CoveredParty Table'
Select 
		cp.EncounterId
		,cp.CoveredPartyId
		,cp.sequenceNumber
		,CodeCSC.ConceptCode as Code,CodeCD.Designation as CodeDes
		,InsOrg.Id_extension as InsurerOrgIdExt, InsOrg.Name as InsurerOrgName
		,msg.Id_extension as MessageId
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
where cp.EncounterId=@EncId
		