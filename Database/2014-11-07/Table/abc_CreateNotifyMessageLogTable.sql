SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO


IF NOT EXISTS (SELECT * FROM dbo.sysobjects SO INNER JOIN sys.schemas S ON SO.uid = s.schema_id WHERE SO.Name = 'NotifyMessageLog' AND SO.xtype = 'U' AND S.name = 'Util')
BEGIN
	CREATE TABLE [Util].[NotifyMessageLog](
	[LogEntryId] [int] IDENTITY(1,1) NOT NULL,
	[MessageId] [smallint] NOT NULL,
	[RecipientId] [smallint] NOT NULL,
	[Region] [varchar](80) NOT NULL,
	[Subject] [Varchar] (200) NULL,
	[MessageSent] Varchar(MAX)  NULL,
	[MessageSentOn] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_NotifyMessageLog] PRIMARY KEY CLUSTERED 
(
	[LogEntryId] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

END

