select * from [dbmVCDRStage].[Common].[DILConfigurationSettings]
where entityName+SystemName in
(SELECT entityName+SystemName
  FROM [dbmVCDRStage].[Common].[DILConfigurationSettings]
group by entityName,SystemName
having count(*)>1)


--delete from [dbmVCDRStage].[Common].[DILConfigurationSettings]
--where DILConfigurationSettingsID in
--(SELECT max(DILConfigurationSettingsID)
--  FROM [dbmVCDRStage].[Common].[DILConfigurationSettings]
--group by entityName,SystemName
--having count(*)>1)
