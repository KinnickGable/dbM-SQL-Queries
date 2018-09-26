SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

use dbmVCDRData
-- use dbmVCDRDataHistory -- uncomment for querying the history CDR
go

declare @startTime as datetime

set @startTime='2011-01-31 00:00:00'

	
IF OBJECT_ID('#EncountersCount') IS NOT NULL DROP TABLE #EncountersCount
IF OBJECT_ID('#DiagnosesCount') IS NOT NULL DROP TABLE #DiagnosesCount
IF OBJECT_ID('#AllergiesCount') IS NOT NULL DROP TABLE  #AllergiesCount
IF OBJECT_ID('#ProblemsCount') IS NOT NULL DROP TABLE  #ProblemsCount
IF OBJECT_ID('#ImmunizationsCount') IS NOT NULL DROP TABLE  #ImmunizationsCount
IF OBJECT_ID('#MedicationsCount') IS NOT NULL DROP TABLE  #MedicationsCount
IF OBJECT_ID('#LabEventsCount') IS NOT NULL DROP TABLE  #LabEventsCount
IF OBJECT_ID('#ImagingCount') IS NOT NULL DROP TABLE  #ImagingCount
IF OBJECT_ID('#ProceduresCount') IS NOT NULL DROP TABLE  #ProceduresCount
IF OBJECT_ID('#DocumentsCount') IS NOT NULL DROP TABLE  #DocumentsCount			
IF OBJECT_ID('#ActsCount') IS NOT NULL DROP TABLE  #ActsCount
IF OBJECT_ID('#PatientForDemoRepositiory_Raw') IS NOT NULL DROP TABLE #PatientForDemoRepositiory_Raw

CREATE TABLE  #EncountersCount (PatientRecordID bigint,RecNumber bigint)
CREATE TABLE  #DiagnosesCount (PatientRecordID bigint,RecNumber bigint)
CREATE TABLE  #AllergiesCount (PatientRecordID bigint,RecNumber bigint)
CREATE TABLE  #ProblemsCount (PatientRecordID bigint,RecNumber bigint)
CREATE TABLE  #ImmunizationsCount (PatientRecordID bigint,RecNumber bigint)
CREATE TABLE  #MedicationsCount (PatientRecordID bigint,RecNumber bigint)
CREATE TABLE  #LabEventsCount (PatientRecordID bigint,RecNumber bigint)
CREATE TABLE  #ImagingCount (PatientRecordID bigint,RecNumber bigint)
CREATE TABLE  #ProceduresCount (PatientRecordID bigint,RecNumber bigint)
CREATE TABLE  #DocumentsCount (PatientRecordID bigint,RecNumber bigint)
CREATE TABLE  #ActsCount 
	(PatientRecordID bigint
		,EncountersCount bigint,DiagnosesCount bigint, AllergiesCount bigint
		,ProblemsCount bigint,ImmunizationsCount bigint, MedicationsCount bigint
		,LabEventsCount bigint,ImagingCount bigint, ProceduresCount bigint, DocumentsCount bigint
	)


INSERT INTO #EncountersCount (PatientRecordID,RecNumber)
SELECT
	PatientRecordID,COUNT(main.EncounterID)
FROM dbmVCDRData.PatientAdministration.Encounter main
Group by PatientRecordID

INSERT INTO #DiagnosesCount (PatientRecordID,RecNumber)
SELECT
	PatientRecordID,COUNT(main.ConditionID)
FROM dbmVCDRData.Condition.Condition main
Where main.dbmClassCodeID=65536
Group by PatientRecordID

INSERT INTO #AllergiesCount (PatientRecordID,RecNumber)
SELECT
	PatientRecordID,COUNT(main.AllergyIntoleranceID)
FROM dbmVCDRData.Allergy.AllergyIntolerance main
--Where main.dbmClassCodeID=65536
Group by PatientRecordID

INSERT INTO #ProblemsCount (PatientRecordID,RecNumber)
Select
	PatientRecordID,COUNT(main.ConditionID)
FROM dbmVCDRData.Condition.Condition main
Where main.dbmClassCodeID=16384
Group by PatientRecordID

INSERT INTO #ImmunizationsCount (PatientRecordID,RecNumber)
Select
	PatientRecordID,COUNT(main.SubstanceAdministrationID)
FROM dbmVCDRData.Medication.SubstanceAdministration main
Where main.dbmClassCodeID=131072
Group by PatientRecordID

INSERT INTO #MedicationsCount (PatientRecordID,RecNumber)
Select
	PatientRecordID,COUNT(main.SubstanceAdministrationID)
FROM dbmVCDRData.Medication.SubstanceAdministration main
Where main.dbmClassCodeID=128
Group by PatientRecordID

INSERT INTO #LabEventsCount (PatientRecordID,RecNumber)
Select
	PatientRecordID,COUNT(main.LaboratoryEventID)
FROM dbmVCDRData.Laboratory.LaboratoryEvent main
Where main.dbmClassCodeID=8192
Group by PatientRecordID

INSERT INTO #ProceduresCount (PatientRecordID,RecNumber)
Select
	PatientRecordID,COUNT(main.ProcedureID)
FROM dbmVCDRData.[Procedure].[Procedure] main
--Where main.dbmClassCodeID=8192
Group by PatientRecordID

INSERT INTO #ImagingCount (PatientRecordID,RecNumber)
Select
	PatientRecordID,COUNT(main.ImagingStudyID)
FROM dbmVCDRData.Imaging.ImagingStudy main
--Where main.dbmClassCodeID=8192
Group by PatientRecordID

INSERT INTO #DocumentsCount (PatientRecordID,RecNumber)
Select
	PatientRecordID,COUNT(main.ClinicalDocumentID)
FROM dbmVCDRData.ClinicalDocument.ClinicalDocument main
Where main.ClinicalDocumentID not in -- check the the clinical document is not already related to other act which is not encnouter, e.g. imaging
	(select  actrel.TargetActID
		from dbmVCDRData.Common.ActRelationship actrel
		where actrel.TargetActClassID=4096 and actrel.SourceActClassID!=1
		)
Group by PatientRecordID

INSERT INTO #ActsCount
	(PatientRecordID
		,EncountersCount,DiagnosesCount, AllergiesCount
		,ProblemsCount,ImmunizationsCount, MedicationsCount
		,LabEventsCount,ImagingCount, ProceduresCount, DocumentsCount)
Select
	pr.PatientRecordID
	,#EncountersCount.RecNumber,#DiagnosesCount.RecNumber,#AllergiesCount.RecNumber
	,#ProblemsCount.RecNumber,#ImmunizationsCount.RecNumber,#MedicationsCount.RecNumber
	,#LabEventsCount.RecNumber,#ImagingCount.RecNumber,#ProceduresCount.RecNumber
	,#DocumentsCount.RecNumber
		
FROM dbmVCDRData.PatientAdministration.PatientRecord pr
	left join #EncountersCount on
		pr.PatientRecordID=#EncountersCount.PatientRecordID
	left join #DiagnosesCount on
		pr.PatientRecordID=#DiagnosesCount.PatientRecordID
	left join #AllergiesCount on
		pr.PatientRecordID=#AllergiesCount.PatientRecordID
	left join #ProblemsCount on
		pr.PatientRecordID=#ProblemsCount.PatientRecordID
	left join #ImmunizationsCount on
		pr.PatientRecordID=#ImmunizationsCount.PatientRecordID
	left join #MedicationsCount on
		pr.PatientRecordID=#MedicationsCount.PatientRecordID
	left join #LabEventsCount on
		pr.PatientRecordID=#LabEventsCount.PatientRecordID
	left join #ImagingCount on
		pr.PatientRecordID=#ImagingCount.PatientRecordID
	left join #ProceduresCount on
		pr.PatientRecordID=#ProceduresCount.PatientRecordID
	left join #DocumentsCount on
		pr.PatientRecordID=#DocumentsCount.PatientRecordID
		
	
--Select 'PatinetRecord Table'
--Select 
--	pr.PatientRecordId,prid.Extension as PrimaryIdExtension,prid.Root as PrimaryIdRoot,prid.AssigningAuthorityName as PrimaryIdAssigningAuthority
--	,pr.BirthTime,GendCSC.ConceptCode as AdministrativeGenderCode
--	,pnpGiv.value as FirstName,pnpFam.value as LastName
----	,pt.Value as Phone
--	,apSAL.value as Street,apCTY.value as City, apValCodeSTA.ConceptCode as 'State',apZIP.value as ZIP
--	--,pridSSN.Extension as SSN

Create table #PatientForDemoRepositiory_Raw
	(PatientRecordID varchar(255),
	 PrimaryIDExtension varchar(255),
	 PrimaryIDRoot varchar(255),
	 PrimaryIdAssigningAuthority  varchar(255),
	 BirthTime datetime,
	AdministrativeGenderCode varchar(255),
	FirstName varchar(255),
	LastName varchar(255),
	Phone varchar(255),
	Street varchar(255),
	City varchar(255),
	"State" varchar(255),
	Zip varchar(255),
	SSN varchar(255),
	InterchangeId varchar(255)
	)

Insert into #PatientForDemoRepositiory_Raw(PatientRecordID,PrimaryIDExtension,PrimaryIDRoot ,
	  PrimaryIdAssigningAuthority , BirthTime,AdministrativeGenderCode,FirstName,
	   LastName,Phone ,Street,City ,"State" ,Zip,SSN ,InterchangeId )
Select 
	pr.PatientRecordId,prid.Extension,prid.Root,prid.AssigningAuthorityName
	,pr.BirthTime,GendCSC.ConceptCode,pnpGiv.value,pnpFam.value,Null
	,Null,Null, Null,Null as ZIP,Null
	--,pridSSN.Extension as SSN
	,msg.InterchangeID 

From PatientAdministration.PatientRecord pr 
	left join PatientAdministration.PatientIdentifier prid
		on pr.PatientRecordId=prid.PatientRecordId and prid.IsPrimary=1
	--left join PatientAdministration.PatientIdentifier pridSSN
	--	on pr.PatientRecordId=pridSSN.PatientRecordId 
	--left join dbmVCDRData.vocabulary.CodeSystemConcept SSNCSC
	--	on pridSSN.IdentifierTypeId=SSNCSC.cscid
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
	inner join
		patientadministration.patientname pnGiv 
		on pr.PatientRecordId=pnGiv.PatientRecordId
	inner join patientadministration.patientnamepart pnpGiv 
		on pnGiv.PatientNameID=pnpGiv.PatientNameID
	inner join dbmVCDRData.vocabulary.CodeSystemConcept ptcscGiv
		on pnpGiv.PartTypeID=ptcscGiv.cscid
	inner join
		patientadministration.patientname pnFAM 
		on pr.PatientRecordId=pnFAM.PatientRecordId
	inner join patientadministration.patientnamepart pnpFam 
		on pnFAM.PatientNameID=pnpFAM.PatientNameID
	inner join dbmVCDRData.vocabulary.CodeSystemConcept ptcscFAM
		on pnpFAM.PartTypeID=ptcscFAM.cscid
	--left join
	--	patientadministration.PostalAddress paSAL
	--	on pr.PatientRecordId=paSAL.PatientRecordId
	--left join patientadministration.AddressPart apSAL
	--	on paSAL.PostalAddressID=apSAL.PostalAddressID
	--left join dbmVCDRData.vocabulary.CodeSystemConcept pacscSAL
	--	on apSAL.PartTypeID=pacscSAL.cscid
	--left join
	--	patientadministration.PostalAddress paCTY
	--	on pr.PatientRecordId=paCTY.PatientRecordId
	--left join patientadministration.AddressPart apCTY
	--	on paCTY.PostalAddressID=apCTY.PostalAddressID
	--left join dbmVCDRData.vocabulary.CodeSystemConcept pacscCTY
	--	on apCTY.PartTypeID=pacscCTY.cscid
	--left join
	--	patientadministration.PostalAddress paSTA
	--	on pr.PatientRecordId=paSTA.PatientRecordId
	--left join patientadministration.AddressPart apSTA
	--	on paSTA.PostalAddressID=apSTA.PostalAddressID
	--left join dbmVCDRData.vocabulary.CodeSystemConcept pacscSTA
	--	on apSTA.PartTypeID=pacscSTA.cscid
	--left join dbmVCDRData.vocabulary.CodeSystemConcept apValCodeSTA
	--	on apSTA.ValueCodeID=apValCodeSTA.cscid
	--left join
	--	patientadministration.PostalAddress paZIP
	--	on pr.PatientRecordId=paZIP.PatientRecordId
	--left join patientadministration.AddressPart apZIP
	--	on paZIP.PostalAddressID=apZIP.PostalAddressID
	--left join dbmVCDRData.vocabulary.CodeSystemConcept pacscZIP
	--	on apZIP.PartTypeID=pacscZIP.cscid
--	left join
--		patientadministration.PatientTelecom pt 
--		on pr.PatientRecordId=pt.PatientRecordId
--	left join
--		dbmVCDRData.vocabulary.CodeSystemConcept ptUseCode
--		on pt.UseId=ptUseCode.cscid

where ptcscGiv.ConceptCode='GIV' and ptcscFam.ConceptCode='Fam'
	--and (pacscSAL.ConceptCode='SAL' or pacscSAL.ConceptCode is null)
	--and (pacscCTY.ConceptCode='CTY' or pacscCTY.ConceptCode is null)
	--and (pacscSTA.ConceptCode='STA' or pacscSTA.ConceptCode is null)
	--and (pacscZIP.ConceptCode='ZIP' or pacscZIP.ConceptCode is null)
	--and (SSNCSC.conceptcode='SSN' or SSNCSC.conceptcode is null)
	--and (ptUseCode.conceptcode='H' or ptUseCode.conceptCode is null)

Select * from #PatientForDemoRepositiory_Raw for xml raw, ROOT('Patients')

--select * from #ActsCount 

Select arc.ArchTime as LastUpdateTime,pat.*,#ActsCount.* ,arc.ArchMessageID
from 
	#PatientForDemoRepositiory_Raw pat 
		left join
			#ActsCount on pat.PatientRecordID=#ActsCount.PatientRecordId
		left join
			dbmDILMessagesArchive.dbo.ArchMessage arc
				on arc.BTSInterchangeID=pat.InterchangeID
	where arc.ArchTime>@startTime
	--and arc.MessageType='ADT' and  arc.MessageTriggerEvent!='A60' 
	--and pat.PrimaryIDExtension='105707782'
	order by arc.ArchTime desc

			
			
--where
--	#ActsCount.EncountersCount>0
--	and #ActsCount.AllergiesCount>5
--	and #ActsCount.DocumentsCount>0
--	and #ActsCount.LabEventsCount>0
--	and #ActsCount.ImagingCount>0
--	and #ActsCount.DiagnosesCount>0
	--and #ActsCount.ProblemsCount>0
	--and #ActsCount.ImmunizationsCount>0
	--and #ActsCount.MedicationsCount>0
	--and #ActsCount.ProceduresCount>0


go
