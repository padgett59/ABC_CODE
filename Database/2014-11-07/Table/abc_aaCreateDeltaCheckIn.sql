/****** Object:  Table [Util].[DeltaAssignment]    Script Date: 08/08/2014 10:18:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

IF NOT EXISTS (SELECT * FROM dbo.sysobjects SO INNER JOIN sys.schemas S ON SO.uid = s.schema_id WHERE SO.Name = 'DeltaCheckIn' AND SO.xtype = 'U' AND S.name = 'Util')
BEGIN

	CREATE TABLE [Util].[DeltaCheckIn](
		[DeltaCheckInId] [int] IDENTITY(1,1) NOT NULL,
		[DeltaAssignmentId] [int] NOT NULL,
		[Baseline] [varchar](200) NULL,
		[ChangeSetId] [int] NULL,
		[ChangeType] [varchar](40) NULL,
		[CheckinDate] [datetime] NULL,
		[SourceFile] [varchar](200) NULL,
		[TfsPath] [varchar](200) NULL,
	 CONSTRAINT [PK_DeltaCheckIn_ID] PRIMARY KEY CLUSTERED 
	(
		[DeltaCheckInId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

END

SET ANSI_PADDING OFF
GO


