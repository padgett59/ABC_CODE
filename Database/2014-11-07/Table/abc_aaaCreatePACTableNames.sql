IF OBJECT_ID('Util.PAC_TableNames', 'U') IS NOT NULL
  DROP TABLE Util.PAC_TableNames
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO


CREATE TABLE [Util].[PAC_TableNames](
	[BCTable] [varchar](200) NOT NULL,
	[Enabled] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[BCTable] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

Insert into [Util].[PAC_TableNames] values ('Util.TransactionAmountsArrayProj_PAC',1)
Insert into Util.PAC_TableNames values ('Util.TransactionAmountsProj_PAC',1)
Insert into Util.PAC_TableNames values ('Util.TransactionFundsProj_PAC',1)
Insert into Util.PAC_TableNames values ('Util.TransactionsProj_PAC',1)


