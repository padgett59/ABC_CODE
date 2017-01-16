if object_id('Util.abc_UpdateBuildInfo', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_UpdateBuildInfo as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_UpdateBuildInfo] 
@BuildId int,
@runType char(1)

AS
SET NOCOUNT ON

declare @deltaCount int
declare @buildNumber varchar(24)

select @buildNumber = BuildNumber from Util.BuildInfo where BuildId = @BuildId and RunType = @runType


--======================================================================
--Update BuildInfo record
--======================================================================

	--ErrorCount
	update Util.BuildInfo set ErrorCount = 
			(Select COUNT(*) from Util.RunLog 
			where BuildNumber = @buildNumber and RunType = @runType
			and Severity > 1) 
	where BuildNumber = @buildNumber and RunType = @runType
	
	--Deltas
	Exec @deltaCount = Util.abc_GetDeltaCount @buildNumber, @runType
	update Util.BuildInfo set Deltas = (Select Case when @deltaCount > 0 then 1 else 0 end) 
		where BuildId = @BuildId and RunType = @runType
	update Util.BuildInfo set DeltaCount = @deltaCount 
		where BuildId = @BuildId and RunType = @runType

	--Return info
	SELECT [BuildId]
		  ,[BuildNumber]
		  ,[BuildDateTime]
		  ,[ErrorCount]
		  ,[Deltas]
		  ,[DeltaCount]
		from Util.BuildInfo BI
		where  BuildId = @BuildId and RunType = @runType

--======================================================================
-- Update BuildSummary Table
--======================================================================

	-- Made re-runnable
	delete from Util.BuildSummary where BuildId = @BuildId and RunType = @runType;
	
	--Add all NULL records
	Declare @initStr varchar(100);
	set @initStr = 'Initializing BuildSummary Records for build ' + Convert(varchar(8),@BuildId);
	exec Util.abc_LogABCEvent 'UpdateBuildInfo', @initStr ;


	--Get list of tables to operate on
	select * into #TableNames from Util.ABC_TableNames where RunType = @runType and Enabled = 1
	
	insert into Util.BuildSummary
	select distinct @BuildId, TN.BCTable, P.Product, NULL, NULL, @runType from #TableNames TN
	inner join Products P on P.Product > 0
	where TN.Enabled = 1

	declare @nextTable varchar(200)
	declare @nextTableVar varchar(200)
	declare @SQLString nvarchar(500)
	
	While (select COUNT(*) from #TableNames) > 0
	begin
		--Get next table, next table VAR
		select top 1 @nextTable = BCTable from #TableNames
		set @nextTableVar = @nextTable + '_VAR'
		
		--Set diff record counts
			SET @SQLString =
				 N'	
				exec Util.abc_LogABCEvent ''UpdateBuildInfo'', ''Calculating diff records for ' + @nextTable + ' ''; 
				 ';
			EXECUTE sp_executesql @SQLString

			SET @SQLString =
				 N'	
				Update BS
				set BS.DiffRecords = VC.DiffRecords
				from Util.BuildSummary BS
				inner join 
				(select ''' + @nextTable + ''' TableName, P.Product, COUNT(P.Product) DiffRecords from ' + @nextTableVar + ' DT
				inner join policies P on DT.Number = P.Number
				where DT.Build = ''' + @buildNumber + ''' 
				group by P.Product) VC 
					on BS.TableName = VC.TableName and BS.Product = VC.Product
				where  
					BS.BuildId = ' + Convert(varchar(8),@BuildId) + ' and BS.RunType = ''' + @runType + '''
				 ';
			--select 'Variant count sql:' + @SQLString
			EXECUTE sp_executesql @SQLString
		
		--Set total record counts. NOTE: Total record count is not exact
			SET @SQLString =
				 N'	
				exec Util.abc_LogABCEvent ''UpdateBuildInfo'', ''Calculating total records for ' + @nextTable + ' ''; 
				 ';
			EXECUTE sp_executesql @SQLString

			SET @SQLString =
				 N'	
				Update BS
				set BS.TotalRecords = TR.TotalRecords
				from Util.BuildSummary BS
				inner join 
				(select ''' + @nextTable + ''' TableName, P.Product, COUNT(P.Product) TotalRecords from ' + @nextTable + ' TR
				inner join policies P on TR.Number = P.Number 
				group by P.Product) TR
					on BS.TableName = TR.TableName and BS.Product = TR.Product
				where  
					BS.BuildId = ' + Convert(varchar(8),@BuildId) + 'and BS.RunType = ''' + @runType + '''
				 ';
			--select 'Total count sql:' + @SQLString
			EXECUTE sp_executesql @SQLString

		delete from #TableNames where BCTable like @nextTable
	end

GO

