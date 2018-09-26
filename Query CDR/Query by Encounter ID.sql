use dbmVCDRData

set transaction isolation level read uncommitted

declare @intEncounterID varchar(255)
declare @strOID varchar(128)

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
----     SET PARAMETERS VALUES !     ------
--XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

set @intEncounterID = '26288368'
--set @strOID = '2.16.840.1.113883.3.57.1.3.15.1.1.1.9'
set @strOID = '2.16.840.1.113883.3.57.1.3.15.1.4.1.9'

if object_id('tempdb..#D1') is not null
	drop table #D1

if object_id('tempdb..#D2') is not null
	drop table #D2


select --*
	rec.PatientRecordID,
	MRN = id.Extension,
	FirstName = PnamePart.[Value],
	rec.BirthTime,
	enc.ControlActID
into #D1
from PatientAdministration.Encounter enc
	inner join PatientAdministration.PatientRecord rec
		on Id_Root = @strOID
		and Id_Extension = @intEncounterID
		and enc.PatientRecordID = rec.PatientRecordID
    inner join PatientAdministration.PatientIdentifier id 
        on rec.PatientRecordID = id.PatientRecordID
        and id.IsPrimary = 1
    inner join PatientAdministration.PatientName Pname
        on rec.PatientRecordID = Pname.PatientRecordID
    inner join PatientAdministration.PatientNamePart PnamePart
        on Pname.PatientNameID = PnamePart.PatientNameID
    inner join Vocabulary.CodeSystemConcept v_csc
        on PnamePart.PartTypeID = v_csc.CSCID
    left join Vocabulary.CodeSystem v_cs
        on v_csc.CodeSystemID = v_cs.CodeSystemID
    inner join Vocabulary.ConceptDesignation v_cd
        on v_csc.CSCID = v_cd.CSCID
		and v_cd.Designation = 'Given'
   left join Vocabulary.CodeSystemConcept v_csc_1
        on id.IdentifierTypeID = v_csc_1.CSCID
    left join Vocabulary.CodeSystem v_cs_1
        on v_csc_1.CodeSystemID = v_cs_1.CodeSystemID
    inner join Vocabulary.ConceptDesignation v_cd_1
        on v_csc_1.CSCID = v_cd_1.CSCID
		and v_cd_1.Designation = 'Medical Record Number'
	
--select * from #D1

create index ind_PRecID_D1 on #D1 (PatientRecordID)

select 
	rec.PatientRecordID,
	EncounterID = @intEncounterID,
	System = 
		case 
			when @strOID = '2.16.840.1.113883.3.57.1.3.15.1.4.1.9' then 'IDX'
			when @strOID = '2.16.840.1.113883.3.57.1.3.15.1.1.1.9' then 'Meditech'
			else 'Other'
		end,
	rec.MRN ,
	SSN = id.Extension,
	rec.FirstName ,
	FamilyName = PnamePart.[Value],
	rec.BirthTime,
	rec.ControlActID
into #D2
	from #D1 rec
    left join (PatientAdministration.PatientIdentifier id 
   inner join Vocabulary.CodeSystemConcept v_csc_1
        on id.IdentifierTypeID = v_csc_1.CSCID
    inner join Vocabulary.CodeSystem v_cs_1
        on v_csc_1.CodeSystemID = v_cs_1.CodeSystemID
    inner join Vocabulary.ConceptDesignation v_cd_1
        on v_csc_1.CSCID = v_cd_1.CSCID
		and v_cd_1.Designation = 'SSN')
			    on rec.PatientRecordID = id.PatientRecordID
				and id.IsPrimary = 1
	left join (PatientAdministration.PatientName Pname
    inner join PatientAdministration.PatientNamePart PnamePart
        on Pname.PatientNameID = PnamePart.PatientNameID
    inner join Vocabulary.CodeSystemConcept v_csc
        on PnamePart.PartTypeID = v_csc.CSCID
    inner join Vocabulary.CodeSystem v_cs
        on v_csc.CodeSystemID = v_cs.CodeSystemID
    inner join Vocabulary.ConceptDesignation v_cd
        on v_csc.CSCID = v_cd.CSCID
		and v_cd.Designation = 'Family')
			    on rec.PatientRecordID = Pname.PatientRecordID

select #D2.PatientRecordID,
	#D2.EncounterID,
	#D2.System,
	#D2.MRN ,
	#D2.SSN ,
	#D2.FirstName ,
	#D2.FamilyName,
	#D2.BirthTime,
	MessageID = m.Id_Extension,
	arch.MessageText
	from #D2
		left join MessageWrapper.ControlAct ca
			on #D2.ControlActID = ca.ControlActID
		left join MessageWrapper.[Message] m
			on ca.MessageID = m.MessageID
		left join dbmDILMessagesArchive.dbo.ArchMessage arch
			on m.InterchangeID = arch.BTSInterchangeID


if object_id('tempd..#D1') is not null
	drop table #D1

if object_id('tempdb..#D2') is not null
	drop table #D2