if object_id('Util.abc_CheckinsByBuildId', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_CheckinsByBuildId as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
SET NOCOUNT ON
GO 

-- Inserts unassigned check-ins to the DeltaCheckIn table
ALTER PROCEDURE [Util].[abc_CheckinsByBuildId] 
	@buildId int

AS
	--DeltaAssigment records will exist only for checkins associated with a DeltaAssigment
	select 
		CAST(1 AS BIT) 'DeltaAssigned', NR.FName + ' ' + NR.LName Developer, DC.SourceFile,  DC.TfsPath Path, DC.ChangeType, DC.CheckinDate, DC.Baseline Release, DC.ChangeSetId 
	from Util.DeltaCheckIn DC
	inner join Util.DeltaAssignment DA on DC.DeltaAssignmentId = DA.DeltaAssignmentId
	inner join Util.NotifyRecipients NR on DA.AssignedTo = NR.RecipientId
	where DC.BuildId = @buildId
	
	Union
	
	--CheckIn Detail records will exist only for checkins not associated with a DeltaAssigment
	select 
		CAST(0 AS BIT) 'DeltaAssigned', NR.FName + ' ' + NR.LName Developer, DC.SourceFile,  DC.TfsPath Path, DC.ChangeType, DC.CheckinDate, DC.Baseline Release, DC.ChangeSetId 
	from Util.DeltaCheckIn DC
	inner join Util.CheckinDetail CD on CD.DeltaCheckInId = DC.DeltaCheckInId
	inner join Util.NotifyRecipients NR on NR.RecipientId = CD.Developer
	where DC.BuildId = @buildId
	
	
