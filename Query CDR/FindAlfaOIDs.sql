
-- This script looking for values suspected as Alfa-OIDs
-- by searching for "_" character.
-- 02/01/2012 by Zachar Rise

USE dbmVCDRData
GO


print 'This scrip checks dbmVCDRData Tables for the values suspected as Alfa-OIDs'
print '__________________________________________________________________________'

print 'Checking Vocabulary.CodeSystem Table'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Vocabulary.CodeSystem
WHERE CodeSystem LIKE '%[_]%' 

SELECT  *
FROM         Vocabulary.CodeSystem
WHERE CodeSystem LIKE '%[_]%'
-----------------------------------------------------------

print 'Checking Allergy.AllergyIntolerance'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Allergy.AllergyIntolerance
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Allergy.AllergyIntolerance
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking ClinicalDocument.ClinicalDocument'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         ClinicalDocument.ClinicalDocument
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         ClinicalDocument.ClinicalDocument
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Common.Device'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Common.Device
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Common.Device
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Common.Material'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Common.Material
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Common.Material
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Common.Microorganism'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Common.Microorganism
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Common.Microorganism
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Common.Organization'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Common.Organization
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Common.Organization
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Condition.Condition'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Condition.Condition
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Condition.Condition
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Imaging.ImagingRequest'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Imaging.ImagingRequest
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Imaging.ImagingRequest
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Imaging.ImagingStudy'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Imaging.ImagingStudy
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Imaging.ImagingStudy
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Laboratory.LaboratoryEvent'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Laboratory.LaboratoryEvent
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Laboratory.LaboratoryEvent
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Laboratory.LaboratoryRequest'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Laboratory.LaboratoryRequest
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Laboratory.LaboratoryRequest
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Laboratory.LaboratoryResult'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Laboratory.LaboratoryResult
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Laboratory.LaboratoryResult
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Laboratory.MicrobiologyFinding'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Laboratory.MicrobiologyFinding
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Laboratory.MicrobiologyFinding
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Laboratory.PathologyFinding'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Laboratory.PathologyFinding
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Laboratory.PathologyFinding
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Laboratory.SpecimenMaterial'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Laboratory.SpecimenMaterial
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Laboratory.SpecimenMaterial
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Measurements.Measurements'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Measurements.Measurements
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Measurements.Measurements
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Measurements.MeasurementsEvent'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Measurements.MeasurementsEvent
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Measurements.MeasurementsEvent
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Medication.MedicationSupply'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Medication.MedicationSupply
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Medication.MedicationSupply
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Medication.SubstanceAdministration'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         Medication.SubstanceAdministration
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         Medication.SubstanceAdministration
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking MessageWrapper.Message'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         MessageWrapper.[Message]
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         MessageWrapper.[Message]
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking PatientAdministration.Encounter'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         PatientAdministration.Encounter
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         PatientAdministration.Encounter
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------

print 'Checking Procedure.Procedure'
print 'Numer of Alfa-OIDs found:'

SELECT  COUNT (*)
FROM         [Procedure].[Procedure]
WHERE  Id_Root LIKE '%[_]%' 

SELECT  *
FROM         [Procedure].[Procedure]
WHERE  Id_Root LIKE '%[_]%' 
-----------------------------------------------------------
