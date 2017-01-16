
-- Populate UniqueKeys column in Util.ABC_Tablenames table
update Util.ABC_Tablenames set UniqueKeys = '1,2,4,6,7' where BCTable = 'Util.AmountType_BC'
update Util.ABC_Tablenames set UniqueKeys = '1,2,3,4,10,11,13' where BCTable = 'Util.Funds_BC'
update Util.ABC_Tablenames set UniqueKeys = '1,2,4' where BCTable = 'Util.PolicyDollars_BC'
update Util.ABC_Tablenames set UniqueKeys = '4,10,2,3' where BCTable = 'Util.Transactions_BC'
update Util.ABC_Tablenames set UniqueKeys = '1,2,3,4,10,6' where BCTable = 'Util.TransactionAmounts_BC'
update Util.ABC_Tablenames set UniqueKeys = '1' where BCTable = 'Util.Policies_BC'
update Util.ABC_Tablenames set UniqueKeys = '1,2,3,4,6,19,7,17,22' where BCTable = 'Util.TransactionFunds_BC'
update Util.ABC_Tablenames set UniqueKeys = '1,2,5,6' where BCTable = 'Util.Amount2Type_BC'
update Util.ABC_Tablenames set UniqueKeys = '1,2,3,4,6,7,8,9' where BCTable = 'Util.FutureAllocations_BC'
update Util.ABC_Tablenames set UniqueKeys = '4,6,7,8,9,10' where BCTable = 'Util.Rider_BC'
update Util.ABC_Tablenames set UniqueKeys = '1,2,3,5' where BCTable = 'Util.RiderOptions_BC'
update Util.ABC_Tablenames set UniqueKeys = '1,3,10' where BCTable = 'Util.Underwriting_BC'
update Util.ABC_Tablenames set UniqueKeys = '2,1,3,4,7' where BCTable = 'Util.FundDetail_BC'
-- NOTE: TransactionFundsDetail not sorted on Number
update Util.ABC_Tablenames set UniqueKeys = '1,2,5,6,13' where BCTable = 'Util.TransactionFundsDetail_BC'
update Util.ABC_Tablenames set UniqueKeys = '1,2,3,5' where BCTable = 'Util.PolicyDollarsArray_BC'
update Util.ABC_Tablenames set UniqueKeys = '1,2,3,4,6,9,10' where BCTable = 'Util.TransactionAmountsArray_BC'
update Util.ABC_Tablenames set UniqueKeys = '1,2,3,4,8,9' where BCTable = 'Util.ShortTermFunds_BC'
update Util.ABC_Tablenames set UniqueKeys = '1,2,3,4,6,7,8,12' where BCTable = 'Util.TransactionShortTermFunds_BC'
-- NOTE: TransactionAmountsArrayProj not sorted on Number
update Util.ABC_Tablenames set UniqueKeys = '5,6,9,10' where BCTable = 'Util.TransactionAmountsArrayProj_PAC'
-- NOTE: not sorted on Number
update Util.ABC_Tablenames set UniqueKeys = '5,6,10' where BCTable = 'Util.TransactionAmountsProj_PAC'
-- NOTE: not sorted on Number
update Util.ABC_Tablenames set UniqueKeys = '5,6,7,17,19,22' where BCTable = 'Util.TransactionFundsProj_PAC'
update Util.ABC_Tablenames set UniqueKeys = '4,10,2,3' where BCTable = 'Util.TransactionsProj_PAC'