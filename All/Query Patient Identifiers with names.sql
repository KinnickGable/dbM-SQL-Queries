use dbmvcdrdata

SELECT pi.root,pi.extension, pi.assigningauthorityname,fn_pnp.value as 'Last Name',gn_pnp.value as 'Given Name'
		  FROM PatientAdministration.PatientIdentifier pi
			inner join PatientAdministration.PatientName pn 
				on pi.PatientRecordId=pn.PatientRecordId 
			inner join [PatientAdministration].[PatientNamePart] fn_pnp
				on fn_pnp.PatientNameId=pn.PatientNameId
			inner join dbmVCDRData.vocabulary.CodeSystemConcept fn_pnptype
				on fn_pnp.PartTypeId=fn_pnptype.cscid and fn_pnptype.conceptcode='FAM'
			inner join [PatientAdministration].[PatientNamePart] gn_pnp
				on gn_pnp.PatientNameId=pn.PatientNameId
			inner join dbmVCDRData.vocabulary.CodeSystemConcept gn_pnptype
				on gn_pnp.PartTypeId=gn_pnptype.cscid and gn_pnptype.conceptcode='GIV'
			
		where (pi.isprimary=1) and fn_pnp.value='Releasea'