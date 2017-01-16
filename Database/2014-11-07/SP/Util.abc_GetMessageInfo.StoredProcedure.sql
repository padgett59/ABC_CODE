if object_id('Util.abc_GetMessageInfo', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_GetMessageInfo as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_GetMessageInfo] 
@Alias varchar(40)

AS
SET NOCOUNT ON

Declare @GroupId tinyint

--Get info by message alias
select @GroupId = GroupId from Util.NotifyMessage where alias = @Alias


--Return result set(s)

	-- Message Info
	select * from Util.NotifyMessage where alias = @Alias

	-- Recipients in Group
	if @GroupId is not null
	begin
		select * from Util.NotifyRecipients where RecipientId in 
			(select RecipientId from Util.NotifyGroupMembers where GroupId = @GroupId)
end
GO
