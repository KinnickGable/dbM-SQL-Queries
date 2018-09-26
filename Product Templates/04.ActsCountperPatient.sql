USE [dbmUtils]
GO

DECLARE @MinPatientAmount as int , 
		@Chunk  as int  
SELECT  --@MinPatientAmount -  MIN patient amount to insert into output table
		@MinPatientAmount  = <MinPatientAmount, int, 100>  , 
		-- @Chunk  -chunk size   for scanning CDR tables
		@Chunk    = <Chunk , int, 10000>  
EXEC LoadingReport.[GET_PersonsActsAmount_prc] @MinPatientAmount=@MinPatientAmount, @Chunk  = @Chunk 

--- output recordset
SELECT 
	PatientRecordID, 
	[Root], 
	MRN, 
	Patient_FirstName, 
	Patient_LastName, 
	Patient_MiddleName, 
	AssigningAuthorityName, 
	BirthTime, 
	Gender, 
	MaritalStatus, 
	EthnicGroup, 
	PreferredLanguage, 
	ReligiousAffiliation, 
	BirthCountry, 
	EncounterAmount, 
	LabRequestAmount, 
	LabEventAmount, 
	LabResultAmount, 
	AllergyAmount, 
	ClinicalDocumentAmount, 
	MedicationRequestAmount, 
	ImmunizationAmount, 
	ConditionAmount, 
	ProblemAmount, 
	ImagingRequestAmount, 
	ImagingStudyAmount, 
	MedicationSupplyAmount, 
	ProcedureAmount, 
	DiagnosisAmount, 
	DispenceMedicationAmount, 
	PathologyEventAmount, 
	SumRecords
FROM LoadingReport.PersonsActsAmount
