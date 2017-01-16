if object_id('Util.abc_ClearBCData', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_ClearBCData as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_ClearBCData] 
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
	--Clear Records
	SET @SQLString =
		 N'	delete from ' + @nextTable + ';
		 ';
	--select @SQLString
	EXECUTE sp_executesql @SQLString
	delete from Util.#TableNames where BCTable like @nextTable
end
GO
