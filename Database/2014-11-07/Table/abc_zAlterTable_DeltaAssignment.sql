
-- Repopulate DeltaAssignment and DeltaCheckIn from zBAK_deltaAssignment
-- hasn't been run if Baseline column still exists in DeltaAssignment [gets moved to the new DeltaCheckIn table]
IF EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[Util].[DeltaAssignment]') 
         AND name = 'Baseline'
)
BEGIN

	-- Save existing for rollback if necessary
	IF EXISTS (SELECT * FROM dbo.sysobjects SO INNER JOIN sys.schemas S ON SO.uid = s.schema_id 
	   WHERE SO.Name = 'zBAK_DeltaAssignment' AND SO.xtype = 'U' AND S.name = 'Util')
	Begin
		IF EXISTS (SELECT * FROM dbo.sysobjects SO INNER JOIN sys.schemas S ON SO.uid = s.schema_id 
		   WHERE SO.Name = 'zBAKOLD_DeltaAssignment' AND SO.xtype = 'U' AND S.name = 'Util')
		Begin
			drop table Util.zBAKOLD_DeltaAssignment
		END
		--Exec sp_rename 'Util.zBAK_DeltaAssignment', 'Util.zBAKOLD_DeltaAssignment'
		select * into Util.zBAKOLD_DeltaAssignment from Util.zBAK_DeltaAssignment
		drop table Util.zBAK_DeltaAssignment
	End

	-- copy DeltaAssignment records into zBAK_DeltaAssignment
	IF NOT EXISTS (SELECT * FROM dbo.sysobjects SO INNER JOIN sys.schemas S ON SO.uid = s.schema_id 
	   WHERE SO.Name = 'Util.zBAK_DeltaAssignment' AND SO.xtype = 'U' AND S.name = 'Util')
	Begin
		select * into Util.zBAK_DeltaAssignment from Util.DeltaAssignment
	End

	--select * From Util.zBAK_DeltaAssignment
	delete from util.deltaAssignment

	Alter Table Util.DeltaAssignment drop column 
		[Baseline],
		[ChangeSetId],
		[ChangeType],
		[CheckinDate],
		[SourceFile],
		[TfsPath]
END

