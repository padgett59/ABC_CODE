
--Non Clustered Index on TransactionAmounts_BC_VAR
if not exists(
	SELECT 1
			FROM sys.indexes 
			WHERE name = 'nc_TransactionAmounts_BC_VAR_7'
			AND object_id = OBJECT_ID('[Util].[TransactionAmounts_BC_VAR]'))

Begin
	CREATE NONCLUSTERED INDEX [nc_TransactionAmounts_BC_VAR_7] ON [Util].[TransactionAmounts_BC_VAR] 
	(
		[Build] ASC,
		[Number] ASC,
		[Effective] ASC,
		[TrxCode] ASC,
		[TrxSeq] ASC,
		[RiderId] ASC,
		[AmountCode] ASC
	)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
end 
go

--Non Clustered Index on TransactionFunds_BC_VAR
if not exists(
	SELECT 1
			FROM sys.indexes 
			WHERE name = 'nc_TransactionFunds_BC_VAR_7'
			AND object_id = OBJECT_ID('[Util].[TransactionFunds_BC_VAR]'))
Begin
CREATE NONCLUSTERED INDEX [nc_TransactionFunds_BC_VAR_7] ON [Util].[TransactionFunds_BC_VAR] 
(
	[Build] ASC,
	[Number] ASC,
	[Effective] ASC,
	[TrxCode] ASC,
	[TrxSeq] ASC,
	[FundNumber] ASC,
	[Sequence] ASC,
	[FundType] ASC,
	[Variation] ASC,
	[SubType] ASC
)WITH (SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
End
go
