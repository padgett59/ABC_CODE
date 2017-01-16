/****** Object:  StoredProcedure [Util].[abc_GetUniqueRecords]    Script Date: 07/31/2014 15:02:26 ******/
if object_id('Util.abc_GetUniqueRecords', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_GetUniqueRecords as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_GetUniqueRecords] 
@tableAlias varchar (200),
@buildId int,
@product tinyint,
@returnRowCount int = 500,
@policy varchar(20) = ''


AS
SET NOCOUNT ON

declare @selectString nvarchar(500)
declare @SQLString nvarchar(2000)
declare @uniqueKeys char(40)
declare @buildNumber varchar(24)

-- Pull out uniqueIDs based on the table name
select @uniqueKeys = UniqueKeys from util.abc_tablenames where BCTable like 'Util.' + @tableAlias 

-- Convert BuildId to BuildName
select @buildNumber = BuildNumber from Util.BuildInfo where BuildId = @buildId

--Get ordered list of match records (P,C sets) as XML
if @returnRowCount = -1
	begin
		SET @selectString =
			 N'	
			select *
			 ';
	end
else
	begin
		SET @selectString =
			 N'	
			select top(' + Convert(varchar(20),@returnRowCount) + ') * 
			 ';
	end

SET @SQLString = @selectString +
	 N'	
	from util.' + @tableAlias + '_VAR where Build = ''' + @buildNumber + ''' 
	and DiffType = ''U'' and Product = ' + convert(varchar(4),@product) + ' 
	 ';

if len(@policy) > 0
begin
	SET @SQLString = @SQLString +
		 N'	
		 and Number = ' + @policy;
end

SET @SQLString = @SQLString +
	 N'	
	order by Run,' + @uniqueKeys + ' 
	 ';

	--select @SQLString
	EXECUTE sp_executesql @SQLString
