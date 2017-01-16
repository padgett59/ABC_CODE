if object_id('Util.abc_CurrentDayLoadSummary', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_CurrentDayLoadSummary as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_CurrentDayLoadSummary] 

AS
SET NOCOUNT ON

declare @nextTable varchar(200)
declare @SQLString nvarchar(500)
declare @recCount int

Create Table #LoadSummary (
TableName varchar(40),
RecCount int
)
--Get list of tables to operate on
select * into #TableNames from Util.ABC_TableNames where Enabled = 1

While (select COUNT(*) from #TableNames) > 0
begin
	--Get next table
	select top 1 @nextTable = BCTable from #TableNames
	
	
	--Select Records from Var table
	SET @SQLString =
		 N'	
			insert into #LoadSummary values (''' + @nextTable + ''', (select count(*) from ' + @nextTable + ' where Run = ''C''));
		 ';
	--select @SQLString
	EXECUTE sp_executesql @SQLString
	delete from #TableNames where BCTable like @nextTable
end

select * from #LoadSummary order by RecCount asc
GO
