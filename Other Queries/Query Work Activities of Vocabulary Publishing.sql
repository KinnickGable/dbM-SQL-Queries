---- Query Work activites of Vocabulary Publish
SELECT  --EventDefID,OccurrenceTime,Message,
*
FROM 
dbmSTLRepository.STLData.EventLog a WITH  (nolock)
join dbmSTLRepository.STLData.ExtendedProperties b WITH  (nolock)
on a.Event_ID=b.Event_ID

WHERE EventDefID between 61003 and 61008
--Modify for special events of interest here
--and eventdefid=61005

--Modify Time here...
and OccurrenceTime>GETDATE()-.02
ORDER BY OccurrenceTime desc
