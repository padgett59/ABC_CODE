--Add the DeltaAssignmentID column to the DeltaAssignment table 
IF NOT EXISTS (SELECT * FROM dbo.sysobjects SO INNER JOIN sys.schemas S ON SO.uid = s.schema_id WHERE SO.Name = 'DeltaAssignment' AND SO.xtype = 'U' AND S.name = 'Util')
	BEGIN
		RAISERROR ('Table Util.DeltaAssignment must exist before executing abc_AddDeltaAssignmentIdToDeltaAssignmentTable.sql', 16, 1) WITH NOWAIT
	END
ELSE
	BEGIN
		IF NOT EXISTS (
		  SELECT * 
		  FROM   sys.columns 
		  WHERE  object_id = OBJECT_ID(N'[Util].[DeltaAssignment]') 
				 AND name = 'DeltaAssignmentId'
		)
		BEGIN
			ALTER TABLE [util].[DeltaAssignment]
			ADD [DeltaAssignmentId] [int] IDENTITY(1,1) NOT NULL,
			CONSTRAINT [PK_DeltaAssignment_ID] PRIMARY KEY CLUSTERED([DeltaAssignmentId] ASC)

		END
	END



