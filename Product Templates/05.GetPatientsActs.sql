USE [dbmUtils]
GO

DECLARE  @FromDate as DATETIME ,
		 @ToDate as DATETIME , 
		 @PatientRoot as varchar(128),
         @PatientExtension as varchar(255), 
         @ActClass as varchar(100) 
SELECT  --@PatientRoot , @PatientExtension  - Person parameters
		@PatientRoot = N'<PatientRoot, varchar(128),>',
        @PatientExtension  = N'<PatientExtension, varchar(255),>' , 
        --@FromDate, @ToDate  - dates for report filter
		@ToDate  = <ToDate, datetime, NULL>,
		@FromDate = <FromDate, datetime, NULL> , 	
        @ActClass  = <ActClass, varchar(100) , NULL>
        
        /*@ActClass - one value from the list
         LabEvent,Pathology,LabResult , MedicationOrders, DispenseMedications , 
		 Immunization , Diagnoses , Problems , Allergies , Encounter , ClinicalDocument , 
		 ImmagingStudy , Procedures OR NULL for all Acts
        */
EXEC LoadingReport.[GetPatientActDetails_prc]   @PatientRoot = @PatientRoot,
												@PatientExtension =  @PatientExtension, 
												@FromDate =  @FromDate,   
												@ToDate = @ToDate , 
												@ActClass = @ActClass
