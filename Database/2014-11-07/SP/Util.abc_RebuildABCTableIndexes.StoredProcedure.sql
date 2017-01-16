if object_id('Util.abc_RebuildABCTableIndexes', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_RebuildABCTableIndexes as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_RebuildABCTableIndexes] 
@runType char(1)

AS
SET NOCOUNT ON

declare @TableName varchar(255)
, @IndexName varchar(255)
, @IndexType varchar(255)
, @avg_fragmentation_in_percent decimal(18,10)
, @PageCount int
, @tsql varchar(512)
, @logMsg varchar(max)

exec Util.abc_LogABCEvent  'RebuildABCTableIndexes', 'START: RebuildABCTableIndexes', 0, '', @runType; 

declare curIndex cursor 
for
SELECT OBJECT_NAME(ind.OBJECT_ID) AS TableName
, ind.name AS IndexName
, indexstats.index_type_desc AS IndexType
, indexstats.avg_fragmentation_in_percent 
, indexstats.page_count 
, 'alter index [' + ind.name + '] on ' + schema_name(t.schema_id) + '.[' + OBJECT_NAME(ind.OBJECT_ID) + '] rebuild' 
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats 
INNER JOIN sys.indexes ind  ON ind.object_id = indexstats.object_id  AND ind.index_id = indexstats.index_id 
inner join sys.tables t on ind.object_id = t.object_id
inner join util.ABC_TableNames ATN on REPLACE(ATN.BCTable,'Util.','') = REPLACE(OBJECT_NAME(ind.OBJECT_ID),'_VAR','')
WHERE 
indexstats.avg_fragmentation_in_percent > 30 and 
ind.name is not null
and indexstats.page_count > 9  --small index won't really rebuild, so just exclude them.
and ATN.Enabled = 1
ORDER BY indexstats.avg_fragmentation_in_percent DESC

open curIndex

FETCH NEXT FROM curIndex
INTO @TableName, @IndexName, @IndexType, @avg_fragmentation_in_percent, @PageCount, @tsql
	

WHILE @@FETCH_STATUS = 0
BEGIN
    
    Set @logMsg = 'Rebuilding Index on Table ' + @TableName;
    exec Util.abc_LogABCEvent  'RebuildABCTableIndexes', @logMsg, 0, '', @runType; 
	print @tsql
	exec (@tsql)

	FETCH NEXT FROM curIndex
	INTO @TableName, @IndexName, @IndexType, @avg_fragmentation_in_percent, @PageCount, @tsql
END
CLOSE curIndex;
DEALLOCATE curIndex;

exec Util.abc_LogABCEvent  'RebuildABCTableIndexes', 'END: RebuildABCTableIndexes', 0, '', @runType; 

GO