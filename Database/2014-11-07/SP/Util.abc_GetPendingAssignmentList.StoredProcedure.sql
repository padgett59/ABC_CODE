if object_id('Util.abc_GetPendingAssignmentList', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_GetPendingAssignmentList as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_GetPendingAssignmentList] 
AS
SET NOCOUNT ON

SELECT 
	BI.BuildId,BI.BuildNumber,BI.BuildDateTime, DA.RunType,DA.DeltaAssignmentId,DA.AssignedTo,ISNULL(CI.Baseline,'') Baseline,
	ISNULL(CI.ChangeSetId,0) ChangeSetId,ISNULL(CI.CheckinDate, '1900-01-01') CheckinDate,
	ISNULL(CI.SourceFile,'') SourceFile ,ISNULL(CI.TfsPath,'') TfsPath,ISNULL(CI.ChangeType,'') ChangeType, 
	DS.[Status] [AssignmentStatus],NR.FName +' '+ NR.LName [Assignee]
FROM 
Util.DeltaAssignment DA  
INNER JOIN Util.DeltaStatus DS ON DA.DeltaStatusId = DS.DeltaStatusId
INNER JOIN Util.BuildInfo BI ON BI.BuildId = DA.BuildId
INNER JOIN Util.NotifyRecipients NR ON DA.AssignedTo=NR.RecipientId
INNER JOIN Util.DeltaCheckIn CI on CI.DeltaAssignmentId = DA.DeltaAssignmentId
WHERE DA.DeltaStatusId  IN (SELECT DeltaStatusId FROM Util.DeltaStatus WHERE StatusClosedFlag = 0 )
ORDER BY BI.BuildId,DA.AssignedTo, BI.BuildNumber,NR.FName + ' ' + NR.LName

GO




