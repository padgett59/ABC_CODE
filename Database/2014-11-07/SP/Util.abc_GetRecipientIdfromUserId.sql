-- Returns RecipientId for a short id 
-- If optional first and last name are set, a new record will get created if not existing

if object_id('Util.abc_GetRecipientIdFromUserId', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_GetRecipientIdFromUserId as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_GetRecipientIdFromUserId] 
@userId varchar(80),
@firstName varchar(60) = null,
@lastName varchar(60) = null

AS
SET NOCOUNT ON

declare @retVal as smallint

--Get RecipientId by message UserId
select @retVal = RecipientId from Util.Notifyrecipients where EmailAddress like @userId + '@nationwide.com'

--If not found and firstName and lastName were passed, insert a new record and return the new value
if @retVal is null and @firstName is not null and @lastName is not null 
begin
	if LEN(@firstName) > 0 AND LEN(@lastName) > 0
	begin
		insert into Util.NotifyRecipients values (@userId + '@nationwide.com', @firstName, @lastName, NULL)
		select @retVal = RecipientId from Util.Notifyrecipients where EmailAddress like @userId + '@nationwide.com'	
	end 
end

select @retVal RecipientId
GO
