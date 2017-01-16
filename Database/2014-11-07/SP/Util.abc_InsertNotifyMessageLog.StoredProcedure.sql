if object_id('Util.abc_InsertNotifyMessageLog', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_InsertNotifyMessageLog as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
SET NOCOUNT ON
GO 

ALTER PROCEDURE [Util].[abc_InsertNotifyMessageLog] 
	@MessageId smallint,	
	@RecipientId smallint,
	@Region varchar(80),
	@Subject varchar(200),
	@MessageSent Varchar(MAX),
	@MessageSentOn smalldatetime
AS

INSERT INTO [Util].[NotifyMessageLog] VALUES (
	@MessageId,
	@RecipientId,
	@Region,
	@Subject,
	@MessageSent,
	@MessageSentOn
	)
GO
