if object_id('Util.abc_BulkInsert', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_BulkInsert as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER PROCEDURE [Util].[abc_BulkInsert] 
@loadPath varchar(400),
@runType char(1)

AS
SET NOCOUNT ON

declare @nextFile varchar(200)
declare @fullPath varchar(600)
declare @SQLString nvarchar(4000)
declare @nextTable varchar(200)

--Get list of tables to operate on
select * into #TableNames from Util.ABC_TableNames where RunType = @runType and Enabled = 1

While (select COUNT(*) from #TableNames) > 0
begin
	--Get next table
	select top 1 @nextTable = BCTable from #TableNames

	--To support repeating a run for the same build 
	SET @SQLString =
		 N'	
			exec Util.abc_LogABCEvent ''BulkInsert_ABC'', '' Clearing table ' + @nextTable + ' ''; 
			Declare @errMessage varchar(500);
			BEGIN TRY
				delete from ' + @nextTable + ' where Run = ''C'';
			END TRY
			BEGIN CATCH
			   select @errMessage = ERROR_MESSAGE();
			   select @errMessage;
			   exec Util.abc_LogABCEvent ''Util.abc_BulkInsert'', @errMessage, 2
			END CATCH
		 ';
		--select @SQLString;
		EXECUTE sp_executesql @SQLString
	
	delete from #TableNames where BCTable like @nextTable

end

create table #files (FileName varchar(200), Depth tinyint, isFile bit )

insert into #files 
EXEC Master.dbo.xp_DirTree @loadPath,1,1

--Exclude non-files
delete from #files where isFile <> 1
--Exclude .csvs
delete from #files where CharIndex('.csv', FileName ) > 0

--Add load table target
alter table #files add TableName varchar(200)
update #files set TableName = 'Util.' + Replace(Replace(FileName, Left(FileName, PATINDEX('%[^0-9]%',FileName) - 1), ''),'.txt','') + '_BC' 

select * from #files

Declare @nextMsg varchar(400);
Declare @numRemaining smallint;
While (select COUNT(*) from #files) > 0
begin
	--Get the load parameters
	select top 1 @nextFile = FileName, @nextTable = TableName from #files
	set @fullPath = @loadPath + '\' + @nextFile
	--Load the data
	select @numRemaining = count(*) from #files

	--log every 50
	if @numRemaining % 50 = 0
	begin
		set @nextMsg = Convert(varchar(max),(select count(*) from #files)) + ' remaining. Loading data file ' + @fullPath + ' '
		exec Util.abc_LogABCEvent 'abc_BulkInsert', @nextMsg, 0;
	end

	exec Util.[abc_LoadTable] @fullPath, @nextTable
	delete from #files where FileName like @nextFile
end

drop table #files

