/****** Object:  StoredProcedure [Util].[abc_GetDeltaAssignmentList]    Script Date: 06/27/2014 16:06:04 ******/
if object_id('Util.abc_GetDeltaAssignmentList', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_GetDeltaAssignmentList as select 1') --create a simple stub procedure using dynamic sql
end

go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_GetDeltaAssignmentList] 

AS
SET NOCOUNT ON

	--Return info
	SELECT 
		DA.BuildId,
		Case RunType when 'B' then 'ABC' 
			 when 'P' Then 'PAC' END RunType,
		NR.FName + ' ' + NR.LName Name,
		DA.AssignedTo,
		NR.RecipientId RecipientId,
		DA.DeltaStatusId,
		DS.Status Status,
		Comments,
		DA.DeltaAssignmentId,
		(Select COUNT(DCI.DeltaAssignmentId) from Util.DeltaCheckIn DCI where DCI.DeltaAssignmentId = DA.DeltaAssignmentId) AssignmentCheckInCount
		from Util.DeltaAssignment DA
		inner join Util.NotifyRecipients NR on NR.RecipientId = DA.AssignedTo
		inner join Util.DeltaStatus DS on DS.DeltaStatusId = DA.DeltaStatusId 
GO

