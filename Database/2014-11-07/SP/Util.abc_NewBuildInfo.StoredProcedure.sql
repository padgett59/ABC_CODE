if object_id('Util.abc_NewBuildInfo', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_NewBuildInfo as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_NewBuildInfo] 
@runType as char(1)

AS
SET NOCOUNT ON

declare @codeVersion varchar(24)
declare @codeVersionBak varchar(24)

	--Get code version
	set @codeVersion = convert(varchar(24),(SELECT value FROM sys.extended_properties WHERE class = 0 and name = 'Version'))
	set @codeVersionBak = @codeVersion + '.BAK'
	
	-- Make re-runnable if already a BuildInfo record for this version
	if (select COUNT(*) from Util.BuildInfo where BuildNumber = @codeVersion) > 0
	begin
		delete from Util.BuildInfo where BuildNumber = @codeVersion and RunType = @runType
		delete from Util.RunLog where BuildNumber = @codeVersionBak and RunType = @runType
		update Util.RunLog set BuildNumber = @codeVersionBak where BuildNumber = @codeVersion and RunType = @runType
		exec Util.abc_DeleteRunFromVars @codeVersion, @runType
	end
	
	--Create new record
	insert into Util.BuildInfo values (
		convert(varchar(24),(SELECT value FROM sys.extended_properties WHERE class = 0 and name = 'Version')),
		getdate(),
		Null,
		Null,
		Null,
		@runType,
		0
		)
	
	--Return info
	select BuildId, BuildNumber, BuildDateTime from Util.BuildInfo 
	where  BuildId = 
		(select max(BuildId) from Util.BuildInfo)
		and RunType = @runType
GO
