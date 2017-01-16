if object_id('Util.abc_LoadSummaryByRun', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_LoadSummaryByRun as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_LoadSummaryByRun] 
@runType char(1)
AS
SET NOCOUNT ON

declare @nextTable varchar(200)
declare @SQLString nvarchar(500)
declare @recCount int

Create Table #LoadSummary (
TableName varchar(40),
RecCount_Prior int,
RecCount_Current int,
RecCount_Diff int 
)
--Get list of tables to operate on
select * into #TableNames from Util.ABC_TableNames where RunType = @runType and Enabled = 1

While (select COUNT(*) from #TableNames) > 0
begin
	--Get next table
	select top 1 @nextTable = BCTable from #TableNames
	
	
	--Select Records from Var table
	SET @SQLString =
		 N'	
			declare @RecCount_Prior int;
			declare @RecCount_Current int;
			select @RecCount_Prior = count(*) from ' + @nextTable + ' where Run = ''P'';
			select @RecCount_Current = count(*) from ' + @nextTable + ' where Run = ''C'';
			insert into #LoadSummary values (''' + @nextTable + ''', @RecCount_Prior ,@RecCount_Current, (@RecCount_Current - @RecCount_Prior));
		 ';
	--select @SQLString
	EXECUTE sp_executesql @SQLString
	delete from #TableNames where BCTable like @nextTable
end

select * from #LoadSummary order by RecCount_Current asc
GO
