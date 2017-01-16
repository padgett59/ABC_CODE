-- If version is new, return new version, else return empty string

if object_id('Util.abc_NewVersionCheck', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_NewVersionCheck as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_NewVersionCheck] 
@runType char(1)

AS
SET NOCOUNT ON

declare @codeVersion varchar(24)

	--Get code version
	set @codeVersion = convert(varchar(24),(SELECT value FROM sys.extended_properties WHERE class = 0 and name = 'Version'))
	
	-- If version is already in BuildInfo return empty string, else return new version number
	if (select COUNT(*) from Util.BuildInfo where BuildNumber = @codeVersion and RunType = @runType) > 0
		begin
			select '' as BuildNumber
		end
	else
		begin
			select @codeVersion as BuildNumber
		end
	
GO
