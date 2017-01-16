SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF NOT EXISTS (SELECT * FROM dbo.sysobjects SO INNER JOIN sys.schemas S ON SO.uid = s.schema_id WHERE SO.Name = 'DeltaAssignment' AND SO.xtype = 'U' AND S.name = 'Util')
BEGIN
	CREATE TABLE [Util].[DeltaAssignment](
		[BuildId] [int] NOT NULL,
		[RunType] char(1) NOT NULL,
		[AutoAssigned] bit NOT NULL DEFAULT(0),
		[AssignedTo] [smallint] Not null,
		[Baseline] varchar (200) Null,
		[ChangeSetId] [int] Null,
		[ChangeType] varchar (40) Null,
		[CheckinDate] datetime Null,
		[SourceFile] varchar (200) Null,
		[TfsPath] varchar (200) Null,
		[DeltaStatusId] [tinyint] Null,
		[Comments] varchar(max) NULL
		)

		--One time move of Assignment records into new table. Use dynamic SQL to avoid column presence check
		declare @sqlText nvarchar (2000)
		set @sqlText = 
		N'
		BEGIN TRY
			select * into Util.BuildInfoBAK from Util.BuildInfo
		END TRY
		BEGIN CATCH
		END CATCH
		
		insert into Util.DeltaAssignment (BuildId, AssignedTo, DeltaStatusId, Comments, RunType)
		select BuildId, AssignedTo, DeltaStatusId, Comments, RunType from Util.BuildInfo where AssignedTo Is Not NULL;
		
		Alter Table Util.BuildInfo drop column AssignedTo, DeltaStatusId, Comments
		'
		--select @sqlText
		EXECUTE sp_executesql @sqlText

END


