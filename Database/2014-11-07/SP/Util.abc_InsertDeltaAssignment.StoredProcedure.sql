if object_id('Util.abc_InsertDeltaAssignment', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_InsertDeltaAssignment as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
SET NOCOUNT ON
GO 

ALTER PROCEDURE [Util].[abc_InsertDeltaAssignment] 
	@buildId int,	
	@runType char(1),
	@autoAssigned bit,
	@assignedTo smallint,
	@baseline varchar(200),
	@changeSetId int,
	@changeType varchar(40),
	@checkinDate datetime,
	@sourceFile varchar(200),
	@tfsPath varchar(200),
	@deltaStatusId tinyint
AS

declare @deltaAssignmentId int
declare @SQLString nvarchar(3000)

IF NOT EXISTS (SELECT * FROM dbo.sysobjects SO INNER JOIN sys.schemas S ON SO.uid = s.schema_id WHERE SO.Name = 'DeltaCheckIn' AND SO.xtype = 'U' AND S.name = 'Util')
	BEGIN
		RAISERROR('Table util.DeltaCheckIn has not been created. Please update from TFS before proceeding.',0,1)
	END
Else
	BEGIN
		--Get the DeltaAssignmentId for this buildId and assigned to OR if not existing, insert a new one 
		select @deltaAssignmentId = DeltaAssignmentId from util.DeltaAssignment 
			where BuildId = @buildId and AssignedTo = @assignedTo
		
		if (@deltaAssignmentId is null)
		begin
			insert into Util.DeltaAssignment Values (
				@buildId,
				@runType,
				@autoAssigned,
				@assignedTo,
				@deltaStatusId,
				''
				)
			
			select @deltaAssignmentId = DeltaAssignmentId from util.DeltaAssignment 
				where BuildId = @buildId and AssignedTo = @assignedTo
		end
		
		insert into util.DeltaCheckIn values (
			@deltaAssignmentId,
			@baseline,
			@changeSetId,
			@changeType,
			@checkinDate,
			@sourceFile,
			@tfsPath,
			@buildId
			)
	END
GO
