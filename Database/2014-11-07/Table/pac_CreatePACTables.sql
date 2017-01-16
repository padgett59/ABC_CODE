SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF OBJECT_ID('Util.TransactionAmountsArrayProj_PAC', 'U') IS NOT NULL DROP TABLE Util.TransactionAmountsArrayProj_PAC
IF OBJECT_ID('Util.TransactionAmountsArrayProj_PAC_VAR', 'U') IS NOT NULL DROP TABLE Util.TransactionAmountsArrayProj_PAC_VAR
IF OBJECT_ID('Util.TransactionAmountsProj_PAC', 'U') IS NOT NULL DROP TABLE Util.TransactionAmountsProj_PAC
IF OBJECT_ID('Util.TransactionAmountsProj_PAC_VAR', 'U') IS NOT NULL DROP TABLE Util.TransactionAmountsProj_PAC_VAR
IF OBJECT_ID('Util.TransactionFundsProj_PAC', 'U') IS NOT NULL DROP TABLE Util.TransactionFundsProj_PAC
IF OBJECT_ID('Util.TransactionFundsProj_PAC_VAR', 'U') IS NOT NULL DROP TABLE Util.TransactionFundsProj_PAC_VAR
IF OBJECT_ID('Util.TransactionsProj_PAC', 'U') IS NOT NULL DROP TABLE Util.TransactionsProj_PAC
IF OBJECT_ID('Util.TransactionsProj_PAC_VAR', 'U') IS NOT NULL DROP TABLE Util.TransactionsProj_PAC_VAR
GO

CREATE TABLE [Util].[TransactionAmountsArrayProj_PAC](
	[Number] [int] NOT NULL,
	[Effective] [datetime] NOT NULL,
	[TrxCode] [smallint] NOT NULL,
	[TrxSeq] [tinyint] NOT NULL,
	[TransactionID] [int] NULL,
	[AmountCode] [smallint] NOT NULL,
	[Amount] [float] NULL,
	[EffDate] [datetime] NULL,
	[Array] [smallint] NOT NULL,
	[RiderId] [tinyint] NOT NULL,
	[Run] [char](1) Null
) ON [PRIMARY]
ALTER TABLE [Util].[TransactionAmountsArrayProj_PAC] ADD  CONSTRAINT [DF_TransactionAmountsArrayProj_PAC_Run]  DEFAULT ('C') FOR [Run]
GO

CREATE TABLE [Util].[TransactionAmountsArrayProj_PAC_VAR](
	[Number] [int] NOT NULL,
	[Effective] [datetime] NOT NULL,
	[TrxCode] [smallint] NOT NULL,
	[TrxSeq] [tinyint] NOT NULL,
	[TransactionID] [int] NULL,
	[AmountCode] [smallint] NOT NULL,
	[Amount] [float] NULL,
	[EffDate] [datetime] NULL,
	[Array] [smallint] NOT NULL,
	[RiderId] [tinyint] NOT NULL,
	[Product] [tinyint] NULL,
	[Run] [char](1) Null,
	[Build] [varchar] (24) NULL,
	[DiffType] [varchar] (1) NULL
) ON [PRIMARY]
ALTER TABLE [Util].[TransactionAmountsArrayProj_PAC_VAR] ADD  CONSTRAINT [DF_TransactionAmountsArrayProj_PAC_VAR_DiffType]  DEFAULT ('V') FOR [DiffType]
GO

CREATE TABLE [Util].[TransactionAmountsProj_PAC](
	[Number] [int] NOT NULL,
	[Effective] [datetime] NOT NULL,
	[TrxCode] [smallint] NOT NULL,
	[TrxSeq] [tinyint] NOT NULL,
	[TransactionID] [int] NULL,
	[AmountCode] [smallint] NOT NULL,
	[RiderCode] [tinyint] NULL,
	[RiderType] [tinyint] NULL,
	[Amount] [float] NULL,
	[RiderId] [tinyint] NOT NULL,
	[Run] [char](1) Null
) ON [PRIMARY]
ALTER TABLE [Util].[TransactionAmountsProj_PAC] ADD  CONSTRAINT [DF_TransactionAmountsProj_PAC]  DEFAULT ('C') FOR [Run]
GO

CREATE TABLE [Util].[TransactionAmountsProj_PAC_VAR](
	[Number] [int] NOT NULL,
	[Effective] [datetime] NOT NULL,
	[TrxCode] [smallint] NOT NULL,
	[TrxSeq] [tinyint] NOT NULL,
	[TransactionID] [int] NULL,
	[AmountCode] [smallint] NOT NULL,
	[RiderCode] [tinyint] NULL,
	[RiderType] [tinyint] NULL,
	[Amount] [float] NULL,
	[RiderId] [tinyint] NOT NULL,
	[Product] [tinyint] NULL,
	[Run] [char](1) Null,
	[Build] [varchar] (24) NULL,
	[DiffType] [varchar] (1) NULL
) ON [PRIMARY]
ALTER TABLE [Util].[TransactionAmountsProj_PAC_VAR] ADD  CONSTRAINT [DF_TransactionAmountsProj_PAC_VAR_DiffType]  DEFAULT ('V') FOR [DiffType]
GO

CREATE TABLE [Util].[TransactionFundsProj_PAC](
	[Number] [int] NOT NULL,
	[Effective] [datetime] NOT NULL,
	[TrxCode] [smallint] NOT NULL,
	[TrxSeq] [tinyint] NOT NULL,
	[TransactionID] [int] NULL,
	[FundNumber] [int] NOT NULL,
	[FundType] [tinyint] NOT NULL,
	[AmountType] [tinyint] NULL,
	[UnitDollarPct] [float] NULL,
	[GainLoss] [float] NULL,
	[CumUnits] [float] NULL,
	[Units] [float] NULL,
	[ValuationDate] [datetime] NULL,
	[UnitValue] [float] NULL,
	[BuyUv] [float] NULL,
	[ReversalUv] [float] NULL,
	[Variation] [smallint] NOT NULL,
	[Dollars] [float] NULL,
	[Sequence] [tinyint] NOT NULL,
	[TermDate] [datetime] NULL,
	[GiveBackUnits] [float] NULL,
	[SubType] [tinyint] NOT NULL,
	[MaturityDate] [datetime] NULL,
	[FundDetailId] [uniqueidentifier] NULL, 
	[Run] [char](1) Null
) ON [PRIMARY]
ALTER TABLE [Util].[TransactionFundsProj_PAC] ADD  CONSTRAINT [DF_TransactionFundsProj_PAC]  DEFAULT ('C') FOR [Run]
ALTER TABLE [Util].[TransactionFundsProj_PAC] ADD  DEFAULT ((0)) FOR [SubType]
GO

CREATE TABLE [Util].[TransactionFundsProj_PAC_VAR](
	[Number] [int] NOT NULL,
	[Effective] [datetime] NOT NULL,
	[TrxCode] [smallint] NOT NULL,
	[TrxSeq] [tinyint] NOT NULL,
	[TransactionID] [int] NULL,
	[FundNumber] [int] NOT NULL,
	[FundType] [tinyint] NOT NULL,
	[AmountType] [tinyint] NULL,
	[UnitDollarPct] [float] NULL,
	[GainLoss] [float] NULL,
	[CumUnits] [float] NULL,
	[Units] [float] NULL,
	[ValuationDate] [datetime] NULL,
	[UnitValue] [float] NULL,
	[BuyUv] [float] NULL,
	[ReversalUv] [float] NULL,
	[Variation] [smallint] NOT NULL,
	[Dollars] [float] NULL,
	[Sequence] [tinyint] NOT NULL,
	[TermDate] [datetime] NULL,
	[GiveBackUnits] [float] NULL,
	[SubType] [tinyint] NOT NULL,
	[MaturityDate] [datetime] NULL,
	[FundDetailId] [uniqueidentifier] NULL, 
	[Product] [tinyint] NULL,
	[Run] [char](1) Null,
	[Build] [varchar] (24) NULL,
	[DiffType] [varchar] (1) NULL
) ON [PRIMARY]
ALTER TABLE [Util].[TransactionFundsProj_PAC_VAR] ADD  CONSTRAINT [DF_TransactionFundsProj_PAC_VAR_DiffType]  DEFAULT ('V') FOR [DiffType]
ALTER TABLE [Util].[TransactionFundsProj_PAC_VAR] ADD  DEFAULT ((0)) FOR [SubType]
GO

CREATE TABLE [Util].[TransactionsProj_PAC](
	[Status] [tinyint] NOT NULL,
	[TrxCode] [smallint] NULL,
	[TrxSeq] [tinyint] NOT NULL,
	[Number] [int] NOT NULL,
	[MemoCode] [tinyint] NULL,
	[MoneyType] [tinyint] NULL,
	[Amount] [float] NULL,
	[AmountType] [tinyint] NULL,
	[CostBasis] [float] NULL,
	[Effective] [datetime] NULL,
	[Valued] [datetime] NULL,
	[BuySell] [datetime] NULL,
	[Process] [datetime] NULL,
	[FirstProcessed] [datetime] NULL,
	[GainLossReason] [smallint] NULL,
	[ErrorNumber] [smallint] NULL,
	[OldId] [smallint] NULL,
	[ReportCodeNumber] [tinyint] NULL,
	[RiderId] [tinyint] NULL,
	[UserId] [smallint] NULL,
	[Run] [char](1) Null
) ON [PRIMARY]
ALTER TABLE [Util].[TransactionsProj_PAC] ADD  CONSTRAINT [DF_TransactionsProj_PAC]  DEFAULT ('C') FOR [Run]
GO

CREATE TABLE [Util].[TransactionsProj_PAC_VAR](
	[Status] [tinyint] NOT NULL,
	[TrxCode] [smallint] NULL,
	[TrxSeq] [tinyint] NOT NULL,
	[Number] [int] NOT NULL,
	[MemoCode] [tinyint] NULL,
	[MoneyType] [tinyint] NULL,
	[Amount] [float] NULL,
	[AmountType] [tinyint] NULL,
	[CostBasis] [float] NULL,
	[Effective] [datetime] NULL,
	[Valued] [datetime] NULL,
	[BuySell] [datetime] NULL,
	[Process] [datetime] NULL,
	[FirstProcessed] [datetime] NULL,
	[GainLossReason] [smallint] NULL,
	[ErrorNumber] [smallint] NULL,
	[OldId] [smallint] NULL,
	[ReportCodeNumber] [tinyint] NULL,
	[RiderId] [tinyint] NULL,
	[UserId] [smallint] NULL,
	[Product] [tinyint] NULL,
	[Run] [char](1) Null,
	[Build] [varchar] (24) NULL,
	[DiffType] [varchar] (1) NULL
) ON [PRIMARY]
ALTER TABLE [Util].[TransactionsProj_PAC_VAR] ADD  CONSTRAINT [DF_TransactionsProj_PAC_VAR_DiffType]  DEFAULT ('V') FOR [DiffType]
GO

