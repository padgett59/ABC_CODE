IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[Util].[ABC_TableNames]') 
		 AND name = 'UniqueKeys'
		 )

BEGIN

		Declare @SQLString As nvarchar (2000)
		--For re-runnability
		IF NOT EXISTS (SELECT * FROM dbo.sysobjects SO INNER JOIN sys.schemas S ON SO.uid = s.schema_id 
		   WHERE SO.Name = 'PAC_TableNames' AND SO.xtype = 'U' AND S.name = 'Util')
		Begin
			select * into Util.PAC_TableNames from Util.ABC_TableNames
			delete from Util.PAC_TableNames
		End

		--Back up the original static tables
		IF NOT EXISTS (SELECT * FROM dbo.sysobjects SO INNER JOIN sys.schemas S ON SO.uid = s.schema_id 
		   WHERE SO.Name = 'zBAK_ABC_TableNames' AND SO.xtype = 'U' AND S.name = 'Util')
		Begin
			select * into Util.zBAK_ABC_TableNames from Util.ABC_TableNames
		End

		IF NOT EXISTS (SELECT * FROM dbo.sysobjects SO INNER JOIN sys.schemas S ON SO.uid = s.schema_id 
		   WHERE SO.Name = 'zBAK_PAC_TableNames' AND SO.xtype = 'U' AND S.name = 'Util')
		Begin
				IF EXISTS (SELECT * FROM dbo.sysobjects SO INNER JOIN sys.schemas S ON SO.uid = s.schema_id 
				   WHERE SO.Name = 'PAC_TableNames' AND SO.xtype = 'U' AND S.name = 'Util')
				Begin
					select * into Util.zBAK_PAC_TableNames from Util.PAC_TableNames
				End
		End

		--Add the RunType column to the ABC_TableNames table
		IF NOT EXISTS (
		  SELECT * 
		  FROM   sys.columns 
		  WHERE  object_id = OBJECT_ID(N'[Util].[ABC_TableNames]') 
				 AND name = 'RunType'
		)
		BEGIN
			alter table Util.ABC_TableNames
			  add RunType char(1) not null 
			  constraint TableNames_RunType_DfTo_B DEFAULT 'B'
		END

		--Add the RunType column to the PAC_TableNames table
		IF NOT EXISTS (
		  SELECT * 
		  FROM   sys.columns 
		  WHERE  object_id = OBJECT_ID(N'[Util].[PAC_TableNames]') 
				 AND name = 'RunType'
		)
		BEGIN
			alter table Util.PAC_TableNames
			  add RunType char(1) not null 
			  constraint TableNames_RunType_DfTo_P DEFAULT 'P'
		END


		--Consolidate the tables and add the UniqueKeys column to the ABC_TableNames table
		IF NOT EXISTS (
		  SELECT * 
		  FROM   sys.columns 
		  WHERE  object_id = OBJECT_ID(N'[Util].[ABC_TableNames]') 
				 AND name = 'UniqueKeys'
			)
		
		
		Begin
			--Delete existing P records and make current records prior
			SET @SQLString =
				 N'	
				 insert into [Util].[ABC_TableNames]
			   select * from [Util].[PAC_TableNames];

			alter table Util.ABC_TableNames
			  add UniqueKeys char(40) null 					
				 ';
			--select @SQLString
			EXECUTE sp_executesql @SQLString
		End

		drop table [Util].[PAC_TableNames]

		--Revert if needed
		--drop table util.abc_tablenames
		--select * into util.abc_tablenames from util.zBAK_abc_tablenames
		--select * into util.pac_tablenames from util.zBAK_pac_tablenames
		--select * from util.abc_tablenames
		--select * from util.pac_tablenames


END
