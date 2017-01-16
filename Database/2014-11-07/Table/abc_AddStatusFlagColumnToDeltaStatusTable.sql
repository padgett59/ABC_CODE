--Add the StatusClosedFlag column to the DetlaStatus table 


IF EXISTS(SELECT * FROM sys.columns
WHERE Name = N'StatusOpenFlag' AND OBJECT_ID = OBJECT_ID(N'Util.DeltaStatus'))
BEGIN
	 ALTER TABLE Util.DeltaStatus 
     DROP CONSTRAINT DeltaStatus_StatusOpenFlag_DfTo_0, 
     COLUMN StatusOpenFlag 

END

GO

IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[Util].[DeltaStatus]') 
         AND name = 'StatusClosedFlag'
)
BEGIN
ALTER TABLE Util.DeltaStatus
	ADD StatusClosedFlag BIT NOT NULL 
	CONSTRAINT DeltaStatus_StatusClosedFlag_0 DEFAULT 0
END




