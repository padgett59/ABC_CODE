if object_id('Util.abc_GetEmailFromId', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_GetEmailFromId as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_GetEmailFromId] 
@recipientId smallInt

AS
SET NOCOUNT ON

--Get info by message alias
select EMailAddress from Util.NotifyRecipients where RecipientId = @recipientId
GO
