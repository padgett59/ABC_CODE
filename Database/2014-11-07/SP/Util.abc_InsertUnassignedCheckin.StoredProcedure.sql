if object_id('Util.abc_InsertUnassignedCheckin', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_InsertUnassignedCheckin as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
SET NOCOUNT ON
GO 

-- Inserts unassigned check-ins to the DeltaCheckIn table
ALTER PROCEDURE [Util].[abc_InsertUnassignedCheckin] 
	@developerId smallint,
	@baseline varchar(200),
	@changeSetId int,
	@changeType varchar(40),
	@checkinDate datetime,
	@sourceFile varchar(200),
	@tfsPath varchar(200),
	@buildId int

AS
	Declare @deltaCheckInId int

	begin tran	

		-- Insert into DeltaCheckIn	
		insert into util.DeltaCheckIn values (
			0,
			@baseline,
			@changeSetId,
			@changeType,
			@checkinDate,
			@sourceFile,
			@tfsPath,
			@buildId
			)

		select @deltaCheckInId = max(DeltaCheckInId) from Util.DeltaCheckIn
		
		-- Insert into CheckInDetail
		insert into util.CheckInDetail values (
			@buildId,
			@developerId,
			@deltaCheckInId
			)
		
	commit tran
	
