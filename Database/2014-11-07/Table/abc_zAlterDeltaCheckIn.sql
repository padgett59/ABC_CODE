--DeltaCheckIn:
--   Add BuildId (nullable)
--   Change DeltaAssignmentId to nullable

IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[Util].[DeltaCheckIn]') 
         AND name = 'BuildId'
)
BEGIN

	alter table Util.DeltaCheckIn ADD  BuildId INT NOT NULL DEFAULT(0)

	--One time move of buildIds into DeltaCheckIn from DeltaAssignment table. Use dynamic SQL to avoid column presence check
	declare @sqlText nvarchar (2000)
	set @sqlText = 
	N'
	update CI set ci.buildId = da.buildid
	from util.deltacheckin ci
	inner join util.deltaAssignment da on da.DeltaAssignmentId = ci.deltaAssignmentid
	'
	EXECUTE sp_executesql @sqlText
	
END
