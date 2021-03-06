use dbmVCDRData

SELECT top 4
org.[OrganizationID]
,org.[Id_Root]
,org.[Id_Extension]
,org.[Name]
,org.[Telecom]
,code_csc.conceptcode as OrgTypeCode
,part_csc.conceptcode as OrgPartCode
,parent_org.Id_Extension as ParentOrgId

FROM [dbmVCDRData].[Common].[Organization] org
	left join vocabulary.codesystemconcept code_csc
		on org.codeid=code_csc.cscid
	left join vocabulary.codesystemconcept part_csc
		on org.[OrgPartCodeID]=part_csc.cscid
	left join [Common].[Organization] parent_org
		on org.[ParentOrganizationID]=parent_org.organizationid
where part_csc.conceptcode='INS'
order by organizationid

