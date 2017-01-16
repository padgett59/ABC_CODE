SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF NOT EXISTS (SELECT * FROM dbo.sysobjects SO INNER JOIN sys.schemas S ON SO.uid = s.schema_id WHERE SO.Name = 'CheckinDetail' AND SO.xtype = 'U' AND S.name = 'Util')
BEGIN
	CREATE TABLE [Util].[CheckinDetail](
		[BuildId] [int] NOT NULL,
		[Developer] [smallint] NOT NULL,
		[DeltaCheckInId] [int] FOREIGN KEY REFERENCES Util.DeltaCheckIn(DeltaCheckInId)
		)

END
GO
SET ANSI_PADDING OFF
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


