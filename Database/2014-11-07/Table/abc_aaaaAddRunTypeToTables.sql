--Add the RunType column to the Run Log table 
IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[Util].[RunLog]') 
         AND name = 'RunType'
)
BEGIN
	alter table Util.RunLog
	  add RunType char(1) not null 
	  constraint RunLog_RunType_DfTo_B DEFAULT 'B'
END


--Add the RunType column to the BuildInfo table 
IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[Util].[BuildInfo]') 
         AND name = 'RunType'
)
BEGIN
	alter table Util.BuildInfo
	  add RunType char(1) not null 
	  constraint BuildInfo_RunType_DfTo_B DEFAULT 'B'
END

--Add the RunType column to the BuildSummary table 
IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[Util].[BuildSummary]') 
         AND name = 'RunType'
)
BEGIN
	alter table Util.BuildSummary
	  add RunType char(1) not null 
	  constraint BuildSummary_RunType_DfTo_B DEFAULT 'B'
END
