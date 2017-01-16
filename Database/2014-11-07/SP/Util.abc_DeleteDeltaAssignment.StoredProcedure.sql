if object_id('Util.abc_DeleteDeltaAssignment', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_DeleteDeltaAssignment as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
SET NOCOUNT ON
GO 

ALTER PROCEDURE [Util].[abc_DeleteDeltaAssignment] 
	@deltaAssignmentId int
AS

IF NOT EXISTS (SELECT * FROM dbo.sysobjects SO INNER JOIN sys.schemas S ON SO.uid = s.schema_id WHERE SO.Name = 'DeltaCheckIn' AND SO.xtype = 'U' AND S.name = 'Util')
	BEGIN
		RAISERROR('Table util.DeltaCheckIn has not yet been created. Please update from TFS before proceeding.',0,1)
	END
Else
	BEGIN
		-- Delete DeltaCheckin Record(s)
		Delete from util.DeltaCheckIn where DeltaAssignmentId = @deltaAssignmentId
		
		-- Delete DeltaAssignment Record
		Delete from util.DeltaAssignment where DeltaAssignmentId = @deltaAssignmentId
	END
GO
