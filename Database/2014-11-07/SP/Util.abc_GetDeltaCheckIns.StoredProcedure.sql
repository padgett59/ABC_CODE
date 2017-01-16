if object_id('Util.abc_GetDeltaCheckIns', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_GetDeltaCheckIns as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_GetDeltaCheckIns] 
@deltaAssignmentId int

AS
SET NOCOUNT ON

select * from Util.DeltaCheckIn where DeltaAssignmentId = @deltaAssignmentId

GO
