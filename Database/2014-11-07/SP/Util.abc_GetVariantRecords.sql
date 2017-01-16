if object_id('Util.abc_GetVariantRecords', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_GetVariantRecords as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_GetVariantRecords] 
@dataTable varchar(200),
@product tinyint,
@buildId int

AS

SET NOCOUNT ON

declare @SQLString nvarchar(500)

SET @SQLString =
	 N'	
		select DT.* from ' + @dataTable + '_VAR DT
		inner join Util.BuildInfo BI on BI.BuildNumber = DT.Build
		where DT.Product = ' + Convert(varchar(4),@product) + ' and BI.BuildId = ' + Convert(varchar(6),@buildId) + '
		order by DT.DiffType, 1 
	 ';
--select @SQLString
EXECUTE sp_executesql @SQLString
	
GO
