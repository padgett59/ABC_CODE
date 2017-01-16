if object_id('Util.abc_LoadTable', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_LoadTable as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER PROCEDURE [Util].[abc_LoadTable] 
@dataFile varchar(200),
@tableName varchar(80)

AS
SET NOCOUNT ON

Declare @FileOK  INT
declare @SQLString nvarchar(2000)
Declare @tempTable varchar(100)

set @tempTable = '#' + Replace(@tableName, 'Util.','')

exec xp_fileExist @dataFile ,@FileOK OUTPUT
if @FileOK = 1
	begin
	
		SET @SQLString =
			 N'	
			   Declare @eMsg varchar(max);
				select top(1) * into ' + @tempTable + ' from ' + @tableName + '
				delete from ' + @tempTable + '
				alter table ' + @tempTable + ' drop Column Run
			   bulk insert ' + @tempTable + 
					' from ''' + @dataFile + '''
					with (FIELDTERMINATOR = ''%'', ROWTERMINATOR = ''\n''); 
			   set @eMsg = Convert(varchar(max), (select ERROR_MESSAGE() as errormessage));
			   if (len(@eMsg) > 0)
			   begin
				   exec Util.abc_LogABCEvent ''LoadTable_ABC'', @eMsg, 2;
			   end
			   
			insert into ' + @tableName + '
			select BCT.*, ''C'' from ' + @tempTable + ' BCT

			--select * from Util.Policies_BC where Run = ''C''
			
			drop table ' + @tempTable + '			
			   
			 ';
		--select @SQLString
		EXECUTE sp_executesql @SQLString

	end
else
	begin
		declare @errMessage varchar (400);
		set @errMessage = 'Input file ' + @dataFile + ' was not found.';
		exec Util.abc_LogABCEvent 'Util.abc_LoadTable', @errMessage, 2
	end

