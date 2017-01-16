if object_id('Util.abc_LogABCEvent', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_LogABCEvent as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_LogABCEvent] 
@Logger varchar(80),
@LogMessage varchar(max),
@Severity tinyint = 0,
@BuildNumber varchar(24) = '',
@runType char(1) = ''

AS
SET NOCOUNT ON

declare @lastEntryId int
declare @thisEntryId int
declare @lastEntryTime datetime
declare @thisEntryTime datetime
declare @lastRunType char(1)

if LEN(@BuildNumber) = 0
begin
	set @BuildNumber = convert(varchar(24),(SELECT value FROM sys.extended_properties WHERE class = 0 and name = 'Version'))
end

insert into Util.RunLog (LogEntryDateTime, Application, Logger, LogMessage,	Severity, SecondsElapsed, BuildNumber) 
	values (getdate(), 'ABC', @Logger, @LogMessage, @Severity, NULL, @BuildNumber)

select @thisEntryId = MAX(LogEntryId) from Util.RunLog
select @thisEntryTime = LogEntryDateTime from Util.RunLog where LogEntryId = @thisEntryId
set @lastEntryId = @thisEntryId - 1
select @lastEntryTime = LogEntryDateTime from Util.RunLog where LogEntryId = @lastEntryId
select @lastRunType = RunType from Util.RunLog where LogEntryId = @lastEntryId

-- If no run type passed, use value of previous entry 
if LEN(@runType) = 0
	begin
		set @runType = @lastRunType
	end

--Set runType
update Util.RunLog 
	set RunType = @runType
	where LogEntryId = @thisEntryId

-- Set ElaspedTime, runType
if (@lastEntryId > 0)
	begin
		update Util.RunLog 
			set SecondsElapsed = Convert(varchar(40),DATEDIFF(MILLISECOND,@lastEntryTime,@thisEntryTime)/1000.0)
			where LogEntryId = @lastEntryId
	end
GO
