/*
Author: Alen
Creation Date: 2010-02-05
Description: Returns updated records amount from most of history tables (between defined dates)
*/

USE dbmVCDRDataHistory
GO

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @dtStart datetime,
		@dtEnd datetime

SELECT  @dtEnd = GETDATE(),
		@dtStart = DATEADD(dd,-1,@dtEnd)

SELECT  COUNT(PatientRecord.ObsoleteMetadataID) as PatientRecord,
		COUNT(PatientRelationship.ObsoleteMetadataID) as PatientRelationship,
		COUNT(Encounter.ObsoleteMetadataID) as Encounter,
		COUNT(LaboratoryRequest.ObsoleteMetadataID) as LaboratoryRequest,
		COUNT(LaboratoryEvent.ObsoleteMetadataID) as LaboratoryEvent,
		COUNT(Condition.ObsoleteMetadataID) as Condition,
		COUNT(SubstanceAdministration.ObsoleteMetadataID) as SubstanceAdministration,
		COUNT(MedicationSupply.ObsoleteMetadataID) as MedicationSupply,
		COUNT([Procedure].ObsoleteMetadataID) as [Procedure],
		COUNT(AllergyIntolerance.ObsoleteMetadataID) as AllergyIntolerance,
		COUNT(ClinicalDocument.ObsoleteMetadataID) as ClinicalDocument,
		COUNT(ImagingRequest.ObsoleteMetadataID) as ImagingRequest,
		COUNT(ImagingStudy.ObsoleteMetadataID) as ImagingStudy,
		COUNT(MedicalStaff.ObsoleteMetadataID) as MedicalStaff,
		COUNT(Organization.ObsoleteMetadataID) as Organization,
		COUNT(Device.ObsoleteMetadataID) as Device,
		COUNT(Microorganism.ObsoleteMetadataID) as Microorganism,
		COUNT(Material.ObsoleteMetadataID) as Material		
FROM MessageWrapper.ObsoleteMetadata
	 LEFT JOIN PatientAdministration.PatientRecord as PatientRecord
		ON ObsoleteMetadata.ObsoleteMetadataID = PatientRecord.ObsoleteMetadataID
	 LEFT JOIN PatientAdministration.PatientRelationship as PatientRelationship
		ON ObsoleteMetadata.ObsoleteMetadataID = PatientRelationship.ObsoleteMetadataID
	 LEFT JOIN PatientAdministration.Encounter  as Encounter
		ON ObsoleteMetadata.ObsoleteMetadataID = Encounter.ObsoleteMetadataID
	 LEFT JOIN Laboratory.LaboratoryRequest as LaboratoryRequest
		ON ObsoleteMetadata.ObsoleteMetadataID = LaboratoryRequest.ObsoleteMetadataID
	 LEFT JOIN Laboratory.LaboratoryEvent as LaboratoryEvent
		ON ObsoleteMetadata.ObsoleteMetadataID = LaboratoryEvent.ObsoleteMetadataID
	 LEFT JOIN Condition.Condition as Condition
		ON ObsoleteMetadata.ObsoleteMetadataID = Condition.ObsoleteMetadataID
	 LEFT JOIN Medication.SubstanceAdministration as SubstanceAdministration
		ON ObsoleteMetadata.ObsoleteMetadataID = SubstanceAdministration.ObsoleteMetadataID
	 LEFT JOIN Medication.MedicationSupply as MedicationSupply
		ON ObsoleteMetadata.ObsoleteMetadataID = MedicationSupply.ObsoleteMetadataID
	 LEFT JOIN [Procedure].[Procedure] as [Procedure]
		ON ObsoleteMetadata.ObsoleteMetadataID = [Procedure].ObsoleteMetadataID  
	 LEFT JOIN Allergy.AllergyIntolerance as AllergyIntolerance
		ON ObsoleteMetadata.ObsoleteMetadataID = AllergyIntolerance.ObsoleteMetadataID   
	 LEFT JOIN ClinicalDocument.ClinicalDocument as ClinicalDocument
		ON ObsoleteMetadata.ObsoleteMetadataID = ClinicalDocument.ObsoleteMetadataID  
	 LEFT JOIN Imaging.ImagingRequest as ImagingRequest
		ON ObsoleteMetadata.ObsoleteMetadataID = ImagingRequest.ObsoleteMetadataID    
	 LEFT JOIN Imaging.ImagingStudy as ImagingStudy
		ON ObsoleteMetadata.ObsoleteMetadataID = ImagingStudy.ObsoleteMetadataID    
	 LEFT JOIN Common.MedicalStaff as MedicalStaff
		ON ObsoleteMetadata.ObsoleteMetadataID = MedicalStaff.ObsoleteMetadataID  
	 LEFT JOIN Common.Organization as Organization
		ON ObsoleteMetadata.ObsoleteMetadataID = Organization.ObsoleteMetadataID    
	 LEFT JOIN Common.Device as Device
		ON ObsoleteMetadata.ObsoleteMetadataID = Device.ObsoleteMetadataID    
	 LEFT JOIN Common.Microorganism as Microorganism
		ON ObsoleteMetadata.ObsoleteMetadataID = Microorganism.ObsoleteMetadataID  
	 LEFT JOIN Common.Material as Material
		ON ObsoleteMetadata.ObsoleteMetadataID = Material.ObsoleteMetadataID
WHERE ObsoleteMetadata.dbmObsoleteTime > @dtStart
	  AND ObsoleteMetadata.dbmObsoleteTime < @dtEnd



