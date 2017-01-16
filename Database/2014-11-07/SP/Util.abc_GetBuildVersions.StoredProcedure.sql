if object_id('Util.abc_GetBuildVersions', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_GetBuildVersions as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_GetBuildVersions] 
@runType char(1)

AS
SET NOCOUNT ON

--Get info by message alias
select BuildNumber from util.buildInfo where RunType = @runType order by BuildId desc
GO
