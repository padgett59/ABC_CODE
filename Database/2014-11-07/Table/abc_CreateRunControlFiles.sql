SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

IF NOT EXISTS (SELECT * FROM dbo.sysobjects SO INNER JOIN sys.schemas S ON SO.uid = s.schema_id WHERE SO.Name = 'RunControlFiles' AND SO.xtype = 'U' AND S.name = 'Util')
BEGIN
	CREATE TABLE [Util].[RunControlFiles](
		[RunType] [char] (1) NOT NULL,
		[SourceType] [char](2) NOT NULL,
		[Value] [varchar](180) NOT NULL
	PRIMARY KEY CLUSTERED 
	(
		[Value],
		[SourceType],
		[RunType]
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	--********************************************************************************************************
	--ABC
	--********************************************************************************************************

	-- Insert ABC DLL type records
	insert into Util.RunControlFiles values ('B', 'D', '\Prefix\TempUpdate\Net\Business Logic.Net')
	insert into Util.RunControlFiles values ('B', 'D', '\Prefix\TempUpdate\Net\FactorType.Net')
	insert into Util.RunControlFiles values ('B', 'D', '\Prefix\TempUpdate\Net\Output.Net')
	insert into Util.RunControlFiles values ('B', 'D', '\Prefix\TempUpdate\Net\Policies.Net')
	insert into Util.RunControlFiles values ('B', 'D', '\Prefix\TempUpdate\Net\Populate.Net')
	insert into Util.RunControlFiles values ('B', 'D', '\Lib\Internal\Prefix.Common')
	insert into Util.RunControlFiles values ('B', 'D', '\Prefix.PolicyValuation\Prefix.Services.Policy.Host')
	insert into Util.RunControlFiles values ('B', 'D', '\Prefix.PolicyValuation\Prefix.Services.Policy.Common')
	insert into Util.RunControlFiles values ('B', 'D', '\Prefix.PolicyValuation\Prefix.Services.Policy.Client')
	insert into Util.RunControlFiles values ('B', 'D', '\Prefix.PolicyValuation\Prefix.Services.Policy')
	insert into Util.RunControlFiles values ('B', 'D', '\Prefix.PolicyValuation\Prefix.Services.BusinessLogic.Host')
	insert into Util.RunControlFiles values ('B', 'D', '\Prefix.PolicyValuation\Prefix.Services.BusinessLogic')
	insert into Util.RunControlFiles values ('B', 'D', '\Prefix.Jobs\Prefix.Services')
	insert into Util.RunControlFiles values ('B', 'D', '\Prefix\TempUpdate\Net\Query.Net')
	insert into Util.RunControlFiles values ('B', 'D', '\Prefix\TempUpdate\Net\RateType.Net')
	insert into Util.RunControlFiles values ('B', 'D', '\Prefix\TempUpdate\Net\Shared.Net')
	insert into Util.RunControlFiles values ('B', 'D', '\Prefix\TempUpdate\Net\Structures.Net')

	-- Insert ABC SQL type records
	insert into Util.RunControlFiles values ('B', 'S', 'nRates')
	insert into Util.RunControlFiles values ('B', 'S', 'nPolicies')
	insert into Util.RunControlFiles values ('B', 'S', 'ynPolicies')
	insert into Util.RunControlFiles values ('B', 'S', 'ynPolicyTrx')
	insert into Util.RunControlFiles values ('B', 'S', 'nPolicyTrx')

	-- Insert ABC SQL Filter type records
	insert into Util.RunControlFiles values ('B', 'SF', 'Factor Table')
	insert into Util.RunControlFiles values ('B', 'SF', 'FactorTable')

	--********************************************************************************************************
	--PAC
	--********************************************************************************************************
	insert into Util.RunControlFiles values ('P', 'D', '\Prefix\TempUpdate\Net\Business Logic.Net')
	insert into Util.RunControlFiles values ('P', 'D', '\Prefix\TempUpdate\Net\FactorType.Net')
	insert into Util.RunControlFiles values ('P', 'D', '\Prefix\TempUpdate\Net\Output.Net')
	insert into Util.RunControlFiles values ('P', 'D', '\Prefix\TempUpdate\Net\Policies.Net')
	insert into Util.RunControlFiles values ('P', 'D', '\Prefix\TempUpdate\Net\Populate.Net')
	insert into Util.RunControlFiles values ('P', 'D', '\Lib\Internal\Prefix.Common')
	insert into Util.RunControlFiles values ('P', 'D', '\Prefix.PolicyValuation\Prefix.Services.Policy.Host')
	insert into Util.RunControlFiles values ('P', 'D', '\Prefix.PolicyValuation\Prefix.Services.Policy.Common')
	insert into Util.RunControlFiles values ('P', 'D', '\Prefix.PolicyValuation\Prefix.Services.Policy.Client')
	insert into Util.RunControlFiles values ('P', 'D', '\Prefix.PolicyValuation\Prefix.Services.Policy')
	insert into Util.RunControlFiles values ('P', 'D', '\Prefix.PolicyValuation\Prefix.Services.BusinessLogic.Host')
	insert into Util.RunControlFiles values ('P', 'D', '\Prefix.PolicyValuation\Prefix.Services.BusinessLogic')
	insert into Util.RunControlFiles values ('P', 'D', '\Prefix.Jobs\Prefix.Services')
	insert into Util.RunControlFiles values ('P', 'D', '\Prefix\TempUpdate\Net\Query.Net')
	insert into Util.RunControlFiles values ('P', 'D', '\Prefix\TempUpdate\Net\RateType.Net')
	insert into Util.RunControlFiles values ('P', 'D', '\Prefix\TempUpdate\Net\Shared.Net')
	insert into Util.RunControlFiles values ('P', 'D', '\Prefix\TempUpdate\Net\Structures.Net')
	
	insert into Util.RunControlFiles values ('P', 'S', 'nRates')
	insert into Util.RunControlFiles values ('P', 'S', 'nPolicies')
	insert into Util.RunControlFiles values ('P', 'S', 'ynPolicies')
	insert into Util.RunControlFiles values ('P', 'S', 'ynPolicyTrx')
	insert into Util.RunControlFiles values ('P', 'S', 'nPolicyTrx')
	insert into Util.RunControlFiles values ('P', 'S', 'nPolicyTrxProjection')
	insert into Util.RunControlFiles values ('P', 'S', 'nPolicyTrxProjectionVarProducts')

	insert into Util.RunControlFiles values ('P', 'SF', 'Factor Table')
	insert into Util.RunControlFiles values ('P', 'SF', 'FactorTable')

END
GO
SET ANSI_PADDING OFF
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


