--Add the LogMessage column to the NotifyMessage table 
IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[Util].[NotifyMessage]') 
         AND name = 'LogMessage'
) 
BEGIN
	ALTER TABLE Util.NotifyMessage
	  ADD LogMessage BIT NOT NULL 
	  CONSTRAINT NotifyMessage_LogMessage_DfTo_0 DEFAULT 0
END


