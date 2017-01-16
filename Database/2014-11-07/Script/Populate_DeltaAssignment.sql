
if (select COUNT(*) from Util.DeltaCheckIn) = 0
BEGIN

	--Populate DeltaAssignment table
	SET IDENTITY_INSERT util.deltaAssignment ON 
	insert into util.deltaAssignment([BuildId],	[RunType],	[AutoAssigned],	[AssignedTo],[DeltaStatusId],	[Comments]	,[DeltaAssignmentId])	
		select 	
		[BuildId],
		[RunType],
		[AutoAssigned],
		[AssignedTo],
		[DeltaStatusId],
		Null
		--,[Comments]
		,[DeltaAssignmentId]
		from Util.zBAK_deltaAssignment
		group by 
			[RunType],
			[AssignedTo],
			[BuildId],
			[DeltaStatusId],
			[AutoAssigned],
			[DeltaAssignmentId]
		order by BuildId, AssignedTo
		SET IDENTITY_INSERT util.deltaAssignment OFF 

	--Remove rows with > 1 DeltaAssigment per BuildId per AssigedTo
	Delete from Util.DeltaAssignment where DeltaAssignmentId not in
	(SELECT DeltaAssignmentId FROM 
	 Util.DeltaAssignment DA
	  LEFT JOIN 
		   (
			SELECT BuildId, AssignedTo, MAX(DeltaStatusId) 'DeltaStatusId' 
			 FROM Util.DeltaAssignment 
			 GROUP BY BuildId, AssignedTo, RunType)
			  DB ON DA.BuildId=DB.BuildId AND DA.AssignedTo=DB.AssignedTo AND DA.DeltaStatusId=DB.DeltaStatusId
	  where DB.DeltaStatusId is not null)
	
	--Bring in comments for the surviving records and update DeltaAssignmentId field
	update DA set DA.Comments = DAB.Comments
	from util.deltaAssignment DA 
	inner join Util.zBAK_deltaAssignment DAB on DA.buildId = DAB.buildId 
		and DA.AssignedTo = DAB.AssignedTo 
		and DA.DeltaStatusId = DAB.DeltaStatusId
		
	--Populate DeltaCheckIn table
	insert into Util.DeltaCheckin
	select
  		DA.DeltaAssignmentId,
		DAB.[Baseline],
		DAB.[ChangeSetId],
		DAB.[ChangeType],
		DAB.[CheckinDate],
		DAB.[SourceFile],
		DAB.[TfsPath],
		DAB.[buildId]
	from Util.zBAK_deltaAssignment DAB
	inner join Util.deltaAssignment DA on DA.buildId = DAB.buildId 
		and DA.AssignedTo = DAB.AssignedTo 
		and DA.DeltaStatusId = DAB.DeltaStatusId

END



