-- Backs out records from most recent run... as if it never happened

if object_id('Util.abc_RevertRunFromBCTables', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_RevertRunFromBCTables as select 1') --create a simple stub procedure using dynamic sql
end

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_RevertRunFromBCTables] 
@runType char(1)

AS
SET NOCOUNT ON

declare @nextTable varchar(200)
declare @SQLString nvarchar(500)

--Get list of tables to operate on
select * into #TableNames from Util.ABC_TableNames where RunType = @runType and Enabled = 1

While (select COUNT(*) from Util.#TableNames) > 0
begin
	--Get next table
	select top 1 @nextTable = BCTable from Util.#TableNames
	
	--Revert P Records to C Records
	SET @SQLString =
		 N'	
		 delete from ' + @nextTable + ' where Run = ''C'';
		 update ' + @nextTable + ' set Run = ''C'' where Run = ''P'';
		 ';
	--select @SQLString
	EXECUTE sp_executesql @SQLString
	delete from Util.#TableNames where BCTable like @nextTable
end
GO
