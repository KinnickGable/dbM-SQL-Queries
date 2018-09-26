/****** Script for researching Message Wrappers for CareEvent by BTS InterchangeID  ******/
 --CollaborateCareEventsandViewbyBTSInterchange
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 -- set the message you are tracing
 Declare @BTSInterchangeID varchar(255)
 select @BTSInterchangeID=
--'c204883f-8262-4fec-b5b6-9108ac5f9c69'
--'39ae774f-55c1-4647-af1e-276ff09f4418'
'77959110-37d9-402d-8728-bf4721702f3c'
 -------------------------------------------------------------------
 
 --RoleId	 RoleCode (CTS ID)					Human Designation
--1			7a609afaa6856dd93c053b6afd87e044  --GPCP  general Primary Care Provider
--2			dca262ca8e77ac43aea1f4ff92930cbe  -ATND	attending
--3			0761dac22c36f6d542a2914017f6449f -PRF perfomer
--4			f266ca69c7ddd5c0c027f628023319a1 -- AUT  author
--5			2ffd265db37f0587705b128017af48f8  --AUTH  Authenticator 
--6			d2ec99e8f0dcbc1c6d1b51749b816f44  - RFR  Referrer
--7			08b00f5650d6e1aa2373902d47b84d99 --REF reffering/ordering
--8			fa25f3012259ea0575329218156dc663 --CON  consulting
--9			9f214ee2d719efe5bc175f34520f48aa  --ADM   admitter

 SELECT *
  FROM [dbmVCDRData].[MessageWrapper].[Message] with (Nolock)
		where InterchangeID=@BTSInterchangeID
--	find ControlActs being identified	
select * 
	from  [dbmVCDRData].[MessageWrapper].[ControlAct]CA with (Nolock)
	 join  [dbmVCDRData].[MessageWrapper].[Message] M with (Nolock)
		on CA.MessageID=M.MessageID
		where M.InterchangeID=@BTSInterchangeID

--- Find the results of the Service building CareEvents
select CEDW.*,
		LSC.*,
		LEC.*, 
		SCA.*
		FROM [dbmInternalData].[Tracking].[CareEventDataWrapper] CEDW with (Nolock)
		left outer join [dbmInternalData].[Tracking].[LuTrackingStatus] LSC  with (Nolock)
			on CEDW.TrackingStatusId=LSC.TrackingStatusId
		left outer join [dbmInternalData].[Tracking].[LuTrackingError] LEC  with (Nolock)
			on CEDW.TrackingErrorId=LEC.TrackingErrorId 
			
		JOIN 
		(	SELECT Id_Root,Id_Extension,'LaboratoryRequest'as ActType  FROM [dbmVCDRData].[Laboratory].[LaboratoryRequest] with (Nolock)
			where ControlActID in 
				(select ControlActID 
					from  [dbmVCDRData].[MessageWrapper].[ControlAct]CA with (Nolock)
				 join  [dbmVCDRData].[MessageWrapper].[Message] M with (Nolock)
					on CA.MessageID=M.MessageID
					where M.InterchangeID=@BTSInterchangeID)
			Union		
					SELECT Id_Root,Id_Extension,'LaboratoryEvent'as ActType  FROM [dbmVCDRData].[Laboratory].[LaboratoryEvent] with (Nolock)
			where ControlActID in 
				(select ControlActID 
					from  [dbmVCDRData].[MessageWrapper].[ControlAct]CA with (Nolock)
				 join  [dbmVCDRData].[MessageWrapper].[Message] M with (Nolock)
					on CA.MessageID=M.MessageID
					where M.InterchangeID=@BTSInterchangeID)
			Union		
			
					SELECT Id_Root,Id_Extension,'LaboratoryResult'as ActType  FROM [dbmVCDRData].[Laboratory].[LaboratoryResult] with (Nolock)
				where ControlActID in 
				(select ControlActID 
					from  [dbmVCDRData].[MessageWrapper].[ControlAct]CA with (Nolock)
				 join  [dbmVCDRData].[MessageWrapper].[Message] M with (Nolock)
					on CA.MessageID=M.MessageID
					where M.InterchangeID=@BTSInterchangeID)
		union 
			select Id_Root,Id_Extension,'ClinicalDocument'as ActType from dbmVCDRData.ClinicalDocument.ClinicalDocument  with (Nolock)
			where ControlActID in 
				(select ControlActID 
					from  [dbmVCDRData].[MessageWrapper].[ControlAct]CA with (Nolock)
				 join  [dbmVCDRData].[MessageWrapper].[Message] M with (Nolock)
					on CA.MessageID=M.MessageID
					where M.InterchangeID=@BTSInterchangeID)
		union 
			select Id_Root,Id_Extension,'Encounter'as ActType from dbmVCDRData.PatientAdministration.Encounter  with (Nolock)
				where ControlActID in 
				(select ControlActID 
					from  [dbmVCDRData].[MessageWrapper].[ControlAct]CA with (Nolock)
				 join  [dbmVCDRData].[MessageWrapper].[Message] M with (Nolock)
					on CA.MessageID=M.MessageID
					where M.InterchangeID=@BTSInterchangeID)
					
				union 
			select Id_Root,Id_Extension,'ImageRequest'as ActType from dbmVCDRData.Imaging.ImagingRequest with (Nolock)
				where ControlActID in 
				(select ControlActID 
					from  [dbmVCDRData].[MessageWrapper].[ControlAct]CA with (Nolock)
				 join  [dbmVCDRData].[MessageWrapper].[Message] M with (Nolock)
					on CA.MessageID=M.MessageID
					where M.InterchangeID=@BTSInterchangeID)
			union 
			select Id_Root,Id_Extension,'ImageStudy'as ActType from dbmVCDRData.Imaging.ImagingStudy with (Nolock)
				where ControlActID in 
				(select ControlActID 
					from  [dbmVCDRData].[MessageWrapper].[ControlAct]CA with (Nolock)
				 join  [dbmVCDRData].[MessageWrapper].[Message] M with (Nolock)
					on CA.MessageID=M.MessageID
					where M.InterchangeID=@BTSInterchangeID)
			)SCA
			on SCA.Id_Root=CEDW.RefId_Root
			and SCA.Id_Extension=CEDW.RefId_Extension	
			
			
--- who in message	
			
	Select CE.*
			,CEV.* 
			,MSP.*
			,MS.*
		from dbmInternalData.CareEvents.CareEvent CE with (Nolock)
		join dbmInternalData.CareEvents.CareEventView CEV with (Nolock)
			on CE.CareEventId=CEV.CareEventId
		left outer join dbmInternalData.Common.MedicalStaffPointer MSP with (Nolock)
			on CEV.RecipientMedicalStaffId=MSP.MedicalStaffPointerId 
		left outer join dbmVCDRData.Common.MedicalStaffIdentifier MSI with (Nolock)
			on MSP.Orig_Id_Root=MSI.Root
			and MSP.Orig_Id_Root=MSI.Extension
		left outer Join dbmVCDRData.Common.MedicalStaff ms with (Nolock)
			on MSI.MedicalStaffIdentifierID=MS.MedicalStaffID
			
		join (
		
				select 
					  CEDW.RefId_Root
					, CEDW.RefId_Extension
				FROM [dbmInternalData].[Tracking].[CareEventDataWrapper] CEDW with (Nolock)
				left outer join [dbmInternalData].[Tracking].[LuTrackingStatus] LSC  with (Nolock)
					on CEDW.TrackingStatusId=LSC.TrackingStatusId
				left outer join [dbmInternalData].[Tracking].[LuTrackingError] LEC  with (Nolock)
					on CEDW.TrackingErrorId=LEC.TrackingErrorId 	
							JOIN 
				(	SELECT Id_Root,Id_Extension,'LaboratoryRequest'as ActType  FROM [dbmVCDRData].[Laboratory].[LaboratoryRequest] with (Nolock)
					where ControlActID in 
						(select ControlActID 
							from  [dbmVCDRData].[MessageWrapper].[ControlAct]CA with (Nolock)
						 join  [dbmVCDRData].[MessageWrapper].[Message] M with (Nolock)
							on CA.MessageID=M.MessageID
							where M.InterchangeID=@BTSInterchangeID)
					Union		
							SELECT Id_Root,Id_Extension,'LaboratoryEvent'as ActType  FROM [dbmVCDRData].[Laboratory].[LaboratoryEvent] with (Nolock)
					where ControlActID in 
						(select ControlActID 
							from  [dbmVCDRData].[MessageWrapper].[ControlAct]CA with (Nolock)
						 join  [dbmVCDRData].[MessageWrapper].[Message] M with (Nolock)
							on CA.MessageID=M.MessageID
							where M.InterchangeID=@BTSInterchangeID)
					Union		
					
							SELECT Id_Root,Id_Extension,'LaboratoryResult'as ActType  FROM [dbmVCDRData].[Laboratory].[LaboratoryResult] with (Nolock)
						where ControlActID in 
						(select ControlActID 
							from  [dbmVCDRData].[MessageWrapper].[ControlAct]CA with (Nolock)
						 join  [dbmVCDRData].[MessageWrapper].[Message] M with (Nolock)
							on CA.MessageID=M.MessageID
							where M.InterchangeID=@BTSInterchangeID)
				union 
					select Id_Root,Id_Extension,'ClinicalDocument'as ActType from dbmVCDRData.ClinicalDocument.ClinicalDocument  with (Nolock)
					where ControlActID in 
						(select ControlActID 
							from  [dbmVCDRData].[MessageWrapper].[ControlAct]CA with (Nolock)
						 join  [dbmVCDRData].[MessageWrapper].[Message] M with (Nolock)
							on CA.MessageID=M.MessageID
							where M.InterchangeID=@BTSInterchangeID)
				union 
					select Id_Root,Id_Extension,'Encounter'as ActType from dbmVCDRData.PatientAdministration.Encounter  with (Nolock)
						where ControlActID in 
						(select ControlActID 
							from  [dbmVCDRData].[MessageWrapper].[ControlAct]CA with (Nolock)
						 join  [dbmVCDRData].[MessageWrapper].[Message] M with (Nolock)
							on CA.MessageID=M.MessageID
							where M.InterchangeID=@BTSInterchangeID)
							
						union 
					select Id_Root,Id_Extension,'ImageRequest'as ActType from dbmVCDRData.Imaging.ImagingRequest with (Nolock)
						where ControlActID in 
						(select ControlActID 
							from  [dbmVCDRData].[MessageWrapper].[ControlAct]CA with (Nolock)
						 join  [dbmVCDRData].[MessageWrapper].[Message] M with (Nolock)
							on CA.MessageID=M.MessageID
							where M.InterchangeID=@BTSInterchangeID)
							union 
					select Id_Root,Id_Extension,'ImageStudy'as ActType from dbmVCDRData.Imaging.ImagingStudy with (Nolock)
						where ControlActID in 
						(select ControlActID 
							from  [dbmVCDRData].[MessageWrapper].[ControlAct]CA with (Nolock)
						 join  [dbmVCDRData].[MessageWrapper].[Message] M with (Nolock)
							on CA.MessageID=M.MessageID
							where M.InterchangeID=@BTSInterchangeID)
					)SCA
					on SCA.Id_Root=CEDW.RefId_Root
					and SCA.Id_Extension=CEDW.RefId_Extension	
				
		) what
		on CE.RefId_Extension=what.RefId_Extension
		and CE.RefId_Root=what.RefId_Root
				