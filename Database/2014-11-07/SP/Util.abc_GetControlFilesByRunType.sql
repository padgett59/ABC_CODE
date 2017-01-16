-- If version is new, return new version, else return empty string

if object_id('Util.abc_GetControlFilesByRunType', 'P') is null  --does the object already exist
begin
     exec('create procedure Util.abc_GetControlFilesByRunType as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_GetControlFilesByRunType] 
@runType char(1)

AS
SET NOCOUNT ON

	select SourceType, Value from Util.RunControlFiles where RunType = @runType
	
GO
