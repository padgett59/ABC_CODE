if object_id('Util.abc_GetDeltaCount', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_GetDeltaCount as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_GetDeltaCount] 
@BuildNumber varchar(24),
@runType char(1)

AS
SET NOCOUNT ON

declare @nextTable varchar(200)
declare @nextTableVar varchar(200)
declare @SQLString nvarchar(500)
declare @deltaCount int


--Get list of tables to operate on
select * into #TableNames from Util.ABC_TableNames where RunType = @runType and Enabled = 1

create table Util.##deltaCountTemp(
deltaCounter int
)
insert into Util.##deltaCountTemp values(0);

While (select COUNT(*) from #TableNames) > 0
begin
	--Get next table
	select top 1 @nextTable = BCTable from #TableNames
		set @nextTableVar = @nextTable + '_VAR'

		SET @SQLString =
			 N'
			 update Util.##deltaCountTemp set deltaCounter = deltaCounter + 
				(select ( ( select count(*) from ' + @nextTableVar + ' where Build = ''' + @BuildNumber + ''' and DiffType = ''V'' )/2 + 
				(select count(*) from ' + @nextTableVar + ' where Build = ''' + @BuildNumber + ''' and DiffType = ''U'')));
			 ';
			--select @SQLString
			EXECUTE sp_executesql @SQLString
		
		delete from #TableNames where BCTable like @nextTable
end

select @deltaCount = deltaCounter from Util.##deltaCountTemp
drop table Util.##deltaCountTemp
return @deltaCount
GO
