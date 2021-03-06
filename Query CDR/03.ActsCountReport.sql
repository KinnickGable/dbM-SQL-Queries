USE [dbmUtils]
GO

DECLARE  @FromDate datetime , 
         @ToDate datetime , 
         @SourceSystem varchar(500)  , 
         @isLabEvent bit ,
         @isPathology bit ,
         @isLabResult bit ,
         @isMedicationOrders bit , 
         @isDispenseMedications bit , 
		 @isImmunization bit ,
		 @isDiagnoses bit , 
		 @isProblems bit ,
		 @isAllergies bit ,
		 @isEncounter bit ,
		 @isClinicalDocument bit , 
		 @isImmagingStudy bit ,
		 @isProcedures bit 
SELECT 	---@FromDate, @ToDate  - dates for report filter
		@FromDate = <FromDate, datetime, NULL> , 	
	    @ToDate  = <ToDate, datetime, NULL>,
	    -- @SourceSystem - specific SourceSystem		
        @SourceSystem  = <SourceSystem, varchar(500) , NULL> , 
        --@is<ACT> - for retriving specefic act or not
        @isLabEvent  = <isLabEvent, bit, 1> , 
        @isPathology  = <isPathology, bit, 1> , 
        @isLabResult  = <isLabResult, bit, 1> , 
        @isMedicationOrders  = <isMedicationOrders, bit, 1> , 
        @isDispenseMedications  = <isDispenseMedications, bit, 1> , 
		@isImmunization  = <isImmunization, bit, 1> , 
		@isDiagnoses  = <isDiagnoses, bit, 1> ,  
		@isProblems  = <isProblems, bit, 1> , 
		@isAllergies  = <isAllergies, bit, 1> , 
		@isEncounter  = <isEncounter, bit, 1> , 
		@isClinicalDocument  = <isClinicalDocument, bit, 1> ,  
		@isImmagingStudy  = <isImmagingStudy, bit, 1> , 
		@isProcedures  = <isProcedures, bit, 1> 
EXEC LoadingReport.[GetActClassesAmount_prc]   	@FromDate =  @FromDate,   
												@ToDate = @ToDate , 
												@SourceSystem = @SourceSystem ,
												@isLabEvent  = @isLabEvent , 
												@isPathology  =@isPathology, 
												@isLabResult  = @isLabResult , 
												@isMedicationOrders  = @isMedicationOrders, 
												@isDispenseMedications  = @isDispenseMedications , 
												@isImmunization  = @isImmunization , 
												@isDiagnoses  = @isDiagnoses ,  
												@isProblems  = @isProblems , 
												@isAllergies  = @isAllergies, 
												@isEncounter  = @isEncounter, 
												@isClinicalDocument  = @isClinicalDocument ,  
												@isImmagingStudy  = @isImmagingStudy, 
												@isProcedures  =@isProcedures
												



GO
