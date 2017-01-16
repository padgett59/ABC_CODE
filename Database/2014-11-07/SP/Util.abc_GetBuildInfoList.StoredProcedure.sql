/****** Object:  StoredProcedure [Util].[abc_GetBuildInfoList]    Script Date: 06/27/2014 16:06:04 ******/
if object_id('Util.abc_GetBuildInfoList', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_GetBuildInfoList as select 1') --create a simple stub procedure using dynamic sql
end

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_GetBuildInfoList] 

AS
SET NOCOUNT ON

	--Return info
	SELECT [BuildId]
		  ,[BuildNumber]
		  ,Case RunType when 'B' then 'ABC' 
			 when 'P' Then 'PAC' END RunType 
		  ,[BuildDateTime]
		  ,[ErrorCount]
		  ,[Deltas]
		  ,[DeltaCount]
		from Util.BuildInfo BI
