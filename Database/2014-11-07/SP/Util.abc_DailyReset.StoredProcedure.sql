if object_id('Util.abc_DailyReset', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_DailyReset as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_DailyReset] 
@runType char(1)

AS
SET NOCOUNT ON

DECLARE @BuildNumber varchar(24),
		@nextTable varchar(200),
		@SQLString nvarchar(500)

CREATE TABLE #ResolvedBuilds
(
	[BuildNumber] varchar(24)
)

--Get list of tables to operate on
select * into #TableNames from Util.ABC_TableNames where RunType = @runType and Enabled = 1

While (select COUNT(*) from #TableNames) > 0
begin
	--Get next table
	select top 1 @nextTable = BCTable from #TableNames
	--Delete existing P records and make current records prior
	SET @SQLString =
		 N'	
			exec Util.abc_LogABCEvent ''DailyReset'', '' Resetting table ' + @nextTable + ' ''; 
			delete from ' + @nextTable + ' where Run = ''P''
			update ' + @nextTable + ' set Run = ''P'' where Run = ''C''
		 ';
	--select @SQLString
	EXECUTE sp_executesql @SQLString
	delete from #TableNames where BCTable = @nextTable
end


-- LOOP TROUGH THE LIST OF BUILDS THAT HAD ALL OF THEIR DELTAS RESOLVED SINCE LAST RUN THAT ARE MORE THAN 12 DAYS OLD
--   Delete the Var records for each one
--
INSERT INTO #ResolvedBuilds
	SELECT BuildNumber
		FROM Util.BuildInfo BI
		WHERE BI.DeltasDeleted = 0 AND BI.Deltas = 1
		AND  DATEDIFF (d, BI.BuildDateTime, getdate()) > 12
		AND BI.BuildId NOT IN (
			(SELECT BI2.BuildId
				FROM Util.BuildInfo BI2
				INNER JOIN Util.DeltaAssignment DA ON BI2.BuildId = DA.BuildId
				INNER JOIN Util.DeltaStatus DS ON DA.DeltaStatusId = DS.DeltaStatusId
				WHERE BI2.DeltasDeleted = 0 AND BI2.Deltas = 1 AND DS.StatusClosedFlag = 0) )


WHILE ((SELECT COUNT(1) FROM #ResolvedBuilds) > 0)
BEGIN
	SELECT TOP 1 @BuildNumber = BuildNumber FROM #ResolvedBuilds

	-- Delete the vars
	exec Util.abc_DeleteRunFromVars @BuildNumber, @runType

	-- Update the BuildInfo so we do not have to check this build again
	UPDATE Util.BuildInfo
		SET DeltasDeleted = 1
		WHERE BuildNumber = @BuildNumber

	DELETE FROM #ResolvedBuilds WHERE BuildNumber = @BuildNumber
END
GO

