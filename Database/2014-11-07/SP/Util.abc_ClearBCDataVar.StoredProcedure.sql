if object_id('Util.abc_ClearBCDataVar', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_ClearBCDataVar as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_ClearBCDataVar] 
@runType char(1),
@build varchar(24) = null

AS
SET NOCOUNT ON
declare @nextTable varchar(200)
declare @nextTableVar varchar(200)
declare @SQLString nvarchar(500)

--Get list of tables to operate on
select * into #TableNames from Util.ABC_TableNames where RunType = @runType and Enabled = 1

--Clear the var tables
While (select COUNT(*) from Util.#TableNames) > 0
begin
	--Get next table
	select top 1 @nextTable = BCTable from Util.#TableNames
	set @nextTableVar = @nextTable + '_VAR'

	if len(@build) > 0
		begin
			--Select Records from Var table
			SET @SQLString =
				 N'	
					delete from ' + @nextTableVar + ' where Build = ''' + @build + '''
				 ';
		end
	else
		begin
			--Select Records from Var table
			SET @SQLString =
				 N'	
					delete from ' + @nextTableVar + '
				 ';
		end	
	--select @SQLString
	EXECUTE sp_executesql @SQLString
	delete from Util.#TableNames where BCTable = @nextTable
	
end
GO
