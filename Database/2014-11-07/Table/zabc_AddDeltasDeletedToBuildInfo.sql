
--Add the DeltasDeleted column to the BuildInfo table 
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'[Util].[BuildInfo]') AND name = 'DeltasDeleted')
BEGIN
	ALTER TABLE Util.BuildInfo
	  ADD DeltasDeleted bit not null 
	  CONSTRAINT BuildInfo_DeltasDeleted_DfTo_0 DEFAULT '0'
END