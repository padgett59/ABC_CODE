
-- Create clustered indexes on the _BC _PAC (on Run) and corresponding _VAR tables (on Build)
declare @nextTable varchar(200)
declare @SQLString nvarchar(2000)

IF OBJECT_ID('tempdb..#TableNames') IS NOT NULL DROP TABLE #TableNames

--Get list of tables to operate on
select BCTable into #TableNames from Util.ABC_TableNames where Enabled = 1

While (select COUNT(*) from #TableNames) > 0
begin

	--Get next table
	select top 1 @nextTable = BCTable from #TableNames

	-- BC tables
	SET @SQLString =
		 N'	
			if not exists(
				SELECT 1
					   FROM sys.indexes 
					   WHERE name = ''ClIndexRun''
					   AND object_id = OBJECT_ID(''' + @nextTable + '''))
			begin
				CREATE CLUSTERED INDEX ClIndexRun ON ' + @nextTable + ' (Run)
				Print ''Clustered index ClIndexRun successfully created on table ' + @nextTable + '''
			end
			else begin
				Print ''Index ClIndexRun already exists on ' + @nextTable + '''
			end
		 ';
	--select @SQLString
	EXECUTE sp_executesql @SQLString


	-- VAR tables
	SET @SQLString =
		 N'	
			if not exists(
				SELECT 1
					   FROM sys.indexes 
					   WHERE name = ''ClIndexBuild''
					   AND object_id = OBJECT_ID(''' + @nextTable + '_Var''))
			begin
				CREATE CLUSTERED INDEX ClIndexBuild ON ' + @nextTable + '_Var (Build)
				Print ''Clustered index ClIndexBuild successfully created on table ' + @nextTable + '_Var''
			end
			else begin
				Print ''Index ClIndexBuild already exists on ' + @nextTable + '_Var''
			end
		 ';
	--select @SQLString
	EXECUTE sp_executesql @SQLString
	delete from #TableNames where BCTable = @nextTable
end
GO 