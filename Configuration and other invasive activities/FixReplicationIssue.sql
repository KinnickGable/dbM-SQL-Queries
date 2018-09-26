use dbmVCDRData
go
begin tran
select * from vocabularyAdmin.DomainConcepts dc
where not exists (select 1 from vocabulary.DomainConcepts Vdc where Vdc.DomainConceptsID = dc.DomainConceptsRelatedID)
update dc
   set DomainConceptsRelatedID = NULL,
       ApprovalStatus = 8
  from vocabularyAdmin.DomainConcepts dc
where not exists (select 1 from vocabulary.DomainConcepts Vdc where Vdc.DomainConceptsID = dc.DomainConceptsRelatedID)
exec VCDRMaster.dbo.VocabularyAdmin_Syncronize_prc
exec VCDRMaster.dbo.VocabularyAdmin_ApplyPublished_prc ''
select * from vocabularyAdmin.DomainConcepts dc
where not exists (select 1 from vocabulary.DomainConcepts Vdc where Vdc.DomainConceptsID = dc.DomainConceptsRelatedID)
commit tran
