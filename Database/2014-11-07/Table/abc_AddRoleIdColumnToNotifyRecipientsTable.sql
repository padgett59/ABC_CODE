--Add  RoleId column to the NotifyRecipients table 
IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[Util].[NotifyRecipients]') 
         AND name = 'RoleId'
)
BEGIN
	alter table Util.NotifyRecipients
	add RoleId int  null 
END

