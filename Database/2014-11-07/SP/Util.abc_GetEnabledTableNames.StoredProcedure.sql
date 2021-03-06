if object_id('Util.abc_GetEnabledTableNames', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_GetEnabledTableNames as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_GetEnabledTableNames]
@runType char(1) 

AS
SET NOCOUNT ON

--Get list of tables to operate on
select BCTable TableName from Util.ABC_TableNames where RunType = @runType and Enabled = 1

