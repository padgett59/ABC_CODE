if object_id('Util.abc_FindDailyVariance', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_FindDailyVariance as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_FindDailyVariance] 
@tableName varchar(80),
@runType char(1)

AS
SET NOCOUNT ON

declare @pTableName varchar(80)
declare @varTableName varchar(80)
declare @pRecCount int
declare @SQLString nvarchar(max)
declare @Build nvarchar(24)

set @pTableName = @tableName

if @runType = 'P'
	begin
		set @tableName = 'Util.' + @tableName + '_PAC'
	end
else if @runType = 'B'
	begin
		set @tableName = 'Util.' + @tableName + '_BC'
	end


set @varTableName = @tableName + '_VAR'

--Drop global temps if existing
	if object_id('tempdb..##c') is not null
	begin
		drop table ##c
	end

	if object_id('tempdb..##p') is not null
	begin
		drop table ##p
	end

	if object_id('tempdb..##pRecCount') is not null
	begin
		drop table ##pRecCount
	end

SET @SQLString =
     N'	select count(*) as RecordCount into ##pRecCount from ' + @tableName + ' where Run = ''P'';
     ';
EXECUTE sp_executesql @SQLString

select @Build = convert(varchar(24), (select value FROM sys.extended_properties WHERE class = 0 and name = 'Version'))

--Don't compare if there is no Prior run
select @pRecCount = RecordCount from ##pRecCount
if @pRecCount > 0
	begin

		--Make re-runnable for the same build 
		SET @SQLString =
			 N'	Delete from ' + @varTableName + ' where [Build] = ''' + @Build + '''
			 ';
		--select @SQLString
		EXECUTE sp_executesql @SQLString

		--Set up temp compare tables
		SET @SQLString =
			 N'	select * into ##c from ' + @tableName + ' where Run = ''C'';
			 alter table ##c drop column [Run];
			 select * into ##p from ' + @tableName + ' where Run = ''P'';
			 alter table ##p drop column [Run];
			 ';
		--select @SQLString
		EXECUTE sp_executesql @SQLString

		--Capture Current records varying or unique
		SET @SQLString =
			 N'	select * into #cdiff from ##c T1 
				except
				select * from ##p T2; 

				alter table #cdiff add Product tinyint null, Run varchar(1) null, [Build] varchar(24) null, DiffType varchar(1) null;
				update #cdiff set Run = ''C'', 
					[Build] = ''' + @Build + ''',
					DiffType = ''V'';

				insert into ' + @varTableName + ' select * from #cdiff;
			 ';
		--select @SQLString
		EXECUTE sp_executesql @SQLString



		--Capture Prior records varying or unique
		SET @SQLString =
			 N'	select * into #pdiff from ##p T1 
				except
				select * from ##c T2; 

				alter table #pdiff add Product tinyint null, Run varchar(1) null, [Build] varchar(24) null, DiffType varchar(1) null;
				update #pdiff set Run = ''P'', 
					[Build] = ''' + @Build + ''',
					DiffType = ''V'';

				insert into ' + @varTableName + ' select * from #pdiff;
			 ';
		--select @SQLString
		EXECUTE sp_executesql @SQLString

		--Drop global temp tables
		Drop table ##c
		Drop table ##p
		Drop table ##pRecCount
		
		
		--Update DiffType column for rows unique to each data set
		set @SQLString =
			CASE @pTableName

				--========================================================================================
				--ABC (Build) Tables
				--========================================================================================
				WHEN 'AmountType' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.AmountCode, T1.StartDate, T1.RiderId, T1.Life, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and 
							T2.AmountCode  = T1.AmountCode  and 
							T2.StartDate = T1.StartDate and 
							T2.RiderId = T1.RiderId and 
							T2.Life = T1.Life and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.Number, T1.AmountCode, T1.StartDate, T1.RiderId, T1.Life, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.AmountCode = UR.AmountCode
						and U1.StartDate = UR.StartDate
						and U1.RiderId = UR.RiderId 
						and U1.Life = UR.Life
						and U1.Build = UR.Build 
					'

				WHEN 'Funds' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.FundNumber, T1.FundType, T1.Variation,
									T1.RiderId, T1.Sequence, T1.SubType, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and 
							T2.FundNumber = T1.FundNumber  and 
							T2.FundType = T1.FundType and 
							T2.Variation = T1.Variation and 
							T2.RiderId = T1.RiderId and 
							T2.Sequence = T1.Sequence and 
							T2.SubType = T1.SubType and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.Number, T1.FundNumber, T1.FundType, T1.Variation,
									T1.RiderId, T1.Sequence, T1.SubType, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.FundNumber = UR.FundNumber
						and U1.FundType = UR.FundType
						and U1.Variation = UR.Variation 
						and U1.RiderId = UR.RiderId
						and U1.Sequence = UR.Sequence
						and U1.SubType = UR.SubType
						and U1.Build = UR.Build 
					'

				WHEN 'PolicyDollars' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.AmountCode, T1.RiderId, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and 
							T2.AmountCode  = T1.AmountCode  and 
							T2.RiderId = T1.RiderId and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.Number, T1.AmountCode, T1.RiderId, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.AmountCode = UR.AmountCode
						and U1.RiderId = UR.RiderId
						and U1.Build = UR.Build 
					'

				--NOTE: this reflects best guess at primary key
				-- May need to remove TransactionID from the compare above
				WHEN 'Transactions' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.Effective, T1.TrxCode, T1.TrxSeq, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and 
							T2.Effective = T1.Effective and 
							T2.TrxCode = T1.TrxCode and 
							T2.TrxSeq = T1.TrxSeq and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.Number, T1.Effective, T1.TrxCode, T1.TrxSeq, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.Effective = UR.Effective
						and U1.TrxCode = UR.TrxCode
						and U1.TrxSeq = UR.TrxSeq
						and U1.Build = UR.Build 
					'

				WHEN 'TransactionAmounts' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.Effective, T1.TrxCode, T1.TrxSeq, T1.RiderId, T1.AmountCode, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
						T2.Number = T1.Number and 
						T2.Effective = T1.Effective and 
						T2.TrxCode = T1.TrxCode and 
						T2.TrxSeq = T1.TrxSeq and 
						T2.RiderId = T1.RiderId and 
						T2.AmountCode = T1.AmountCode and 
						T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.Number, T1.Effective, T1.TrxCode, T1.TrxSeq, T1.RiderId, T1.AmountCode, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.Effective = UR.Effective
						and U1.TrxCode = UR.TrxCode
						and U1.TrxSeq = UR.TrxSeq 
						and U1.RiderId = UR.RiderId 
						and U1.AmountCode = UR.AmountCode 
						and U1.Build = UR.Build 
					'


				WHEN 'Policies' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.Build 
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.number, T1.Build 
						having count(T1.Number) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.Build = UR.Build
					'

				WHEN 'TransactionFunds' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.Effective, T1.TrxCode, T1.TrxSeq, 
							T1.FundNumber, T1.Sequence, T1.FundType, T1.Variation, T1.SubType, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and 
							T2.Effective = T1.Effective and 
							T2.TrxCode = T1.TrxCode and 
							T2.TrxSeq = T1.TrxSeq and 
							T2.FundNumber = T1.FundNumber and 
							T2.Sequence = T1.Sequence and 
							T2.FundType = T1.FundType and 
							T2.Variation = T1.Variation  and 
							T2.SubType = T1.SubType and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.Number, T1.Effective, T1.TrxCode, T1.TrxSeq, 
							T1.FundNumber, T1.Sequence, T1.FundType, T1.Variation, T1.SubType, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.Effective = UR.Effective
						and U1.TrxCode = UR.TrxCode
						and U1.TrxSeq = UR.TrxSeq 
						and U1.FundNumber = UR.FundNumber 
						and U1.Sequence = UR.Sequence 
						and U1.FundType = UR.FundType 
						and U1.Variation = UR.Variation 
						and U1.SubType = UR.SubType  
						and U1.Build = UR.Build 
					'

				WHEN 'Amount2Type' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.AmountCode, T1.Array, T1.RiderId, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and 
							T2.AmountCode = T1.AmountCode and 
							T2.Array = T1.Array and 
							T2.RiderId = T1.RiderId and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.number, T1.AmountCode, T1.Array, T1.RiderId, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.AmountCode = UR.AmountCode
						and U1.Array = UR.Array
						and U1.RiderId = UR.RiderId
						and U1.Build = UR.Build 
					'

				WHEN 'FutureAllocations' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.FundNumber, T1.FundType, T1.Variation, T1.RiderId, 
								T1.InitiatedType, T1.AllocType, T1.StartDate, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and 
							T2.FundNumber = T1.FundNumber and 
							T2.FundType = T1.FundType and 
							T2.Variation = T1.Variation and 
							T2.RiderId = T1.RiderId and 
							T2.InitiatedType = T1.InitiatedType and 
							T2.AllocType = T1.AllocType and 
							T2.StartDate = T1.StartDate and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.Number, T1.FundNumber, T1.FundType, T1.Variation, T1.RiderId, 
								T1.InitiatedType, T1.AllocType, T1.StartDate, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.FundNumber = UR.FundNumber
						and U1.FundType = UR.FundType
						and U1.Variation = UR.Variation
						and U1.RiderId = UR.RiderId 
						and U1.InitiatedType = UR.InitiatedType
						and U1.AllocType = UR.AllocType
						and U1.StartDate = UR.StartDate
						and U1.Build = UR.Build 
					'
					
				WHEN 'Rider' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.RiderCode, T1.RiderSequence, T1.AssocCode, T1.AssocSequence, 
									T1.RiderType, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and 
							T2.RiderCode = T1.RiderCode and 
							T2.RiderSequence = T1.RiderSequence and 
							T2.AssocCode = T1.AssocCode and 
							T2.AssocSequence = T1.AssocSequence and 
							T2.RiderType = T1.RiderType and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.Number, T1.RiderCode, T1.RiderSequence, T1.AssocCode, T1.AssocSequence, 
									T1.RiderType, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.RiderCode = UR.RiderCode
						and U1.RiderSequence = UR.RiderSequence
						and U1.AssocCode = UR.AssocCode
						and U1.AssocSequence = UR.AssocSequence 
						and U1.RiderType = UR.RiderType
						and U1.Build = UR.Build 
					'

				WHEN 'RiderOptions' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.RiderId, T1.AmountCode, T1.StartDate, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and 
							T2.RiderId = T1.RiderId and 
							T2.AmountCode = T1.AmountCode and 
							T2.StartDate = T1.StartDate and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.Number, T1.RiderId, T1.AmountCode, T1.StartDate, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.RiderId = UR.RiderId
						and U1.AmountCode = UR.AmountCode
						and U1.StartDate = UR.StartDate
						and U1.Build = UR.Build 
					'

				WHEN 'Underwriting' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.Life, T1.RiderId, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and 
							T2.Life = T1.Life and 
							T2.RiderId = T1.RiderId and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.Number, T1.Life, T1.RiderId, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.Life = UR.Life
						and U1.RiderId = UR.RiderId
						and U1.Build = UR.Build 
					'

				WHEN 'FundDetail' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.FundDetailId, T1.RiderId, T1.AmountCode, T1.OriginalEffectiveDate, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and 
							T2.FundDetailId = T1.FundDetailId and 
							T2.RiderId = T1.RiderId and 
							T2.AmountCode = T1.AmountCode and 
							T2.OriginalEffectiveDate = T1.OriginalEffectiveDate and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.Number, T1.FundDetailId, T1.RiderId, T1.AmountCode, T1.OriginalEffectiveDate, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.FundDetailId = UR.FundDetailId
						and U1.RiderId = UR.RiderId
						and U1.AmountCode = UR.AmountCode 
						and U1.OriginalEffectiveDate = UR.OriginalEffectiveDate
						and U1.Build = UR.Build 
					'

				WHEN 'TransactionFundsDetail' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.FundDetailId, T1.TransactionId, T1.RiderId, T1.AmountCode, T1.OriginalEffectiveDate, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.FundDetailId = T1.FundDetailId and 
							T2.TransactionId = T1.TransactionId and 
							T2.RiderId = T1.RiderId and 
							T2.AmountCode = T1.AmountCode and 
							T2.OriginalEffectiveDate = T1.OriginalEffectiveDate and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.FundDetailId, T1.TransactionId, T1.RiderId, T1.AmountCode, T1.OriginalEffectiveDate, T1.Build
						having count(T1.FundDetailId) = 1 ) UR
					where 
						    U1.FundDetailId = UR.FundDetailId
						and U1.TransactionId = UR.TransactionId
						and U1.RiderId = UR.RiderId
						and U1.AmountCode = UR.AmountCode 
						and U1.OriginalEffectiveDate = UR.OriginalEffectiveDate
						and U1.Build = UR.Build 
					'
					
				WHEN 'PolicyDollarsArray' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.Array, T1.AmountCode, T1.RiderId, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and 
							T2.Array = T1.Array and 
							T2.AmountCode = T1.AmountCode and 
							T2.RiderId = T1.RiderId and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.Number, T1.Array, T1.AmountCode, T1.RiderId, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.Array = UR.Array
						and U1.AmountCode = UR.AmountCode
						and U1.RiderId = UR.RiderId
						and U1.Build = UR.Build 
					'

				WHEN 'TransactionAmountsArray' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.Effective, T1.TrxCode, T1.TrxSeq, T1.AmountCode, T1.Array, 
								T1.RiderId, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and 
							T2.Effective = T1.Effective and 
							T2.TrxCode = T1.TrxCode and 
							T2.TrxSeq = T1.TrxSeq and 
							T2.AmountCode = T1.AmountCode and 
							T2.Array = T1.Array and 
							T2.RiderId = T1.RiderId and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.Number, T1.Effective, T1.TrxCode, T1.TrxSeq, T1.AmountCode, T1.Array, 
								T1.RiderId, T1.Build
						having count(T1.AmountCode) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.Effective = UR.Effective
						and U1.TrxCode = UR.TrxCode
						and U1.TrxSeq = UR.TrxSeq
						and U1.AmountCode = UR.AmountCode
						and U1.Array = UR.Array
						and U1.RiderId = UR.RiderId
						and U1.Build = UR.Build 
					'
					
				WHEN 'ShortTermFunds' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.FundNumber, T1.Sequence, T1.FundType, T1.Array, T1.RiderId, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and 
							T2.FundNumber = T1.FundNumber and 
							T2.Sequence = T1.Sequence and 
							T2.FundType = T1.FundType and 
							T2.Array = T1.Array and 
							T2.RiderId = T1.RiderId and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.Number, T1.FundNumber, T1.Sequence, T1.FundType, T1.Array, T1.RiderId, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.FundNumber = UR.FundNumber
						and U1.Sequence = UR.Sequence
						and U1.FundType = UR.FundType 
						and U1.Array = UR.Array
						and U1.RiderId = UR.RiderId
						and U1.Build = UR.Build 
					'

				WHEN 'TransactionShortTermFunds' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.Effective, T1.TrxCode, T1.TrxSeq, T1.FundNumber, T1.Sequence, 
							T1.FundType, T1.Array, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and 
							T2.Effective = T1.Effective and 
							T2.TrxCode = T1.TrxCode and 
							T2.TrxSeq = T1.TrxSeq and 
							T2.FundNumber = T1.FundNumber and 
							T2.Sequence = T1.Sequence and 
							T2.FundType = T1.FundType and 
							T2.Array = T1.Array and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.Number, T1.Effective, T1.TrxCode, T1.TrxSeq, T1.FundNumber, T1.Sequence, 
							T1.FundType, T1.Array, T1.Build
						having count(T1.FundNumber) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.Effective = UR.Effective
						and U1.TrxCode = UR.TrxCode
						and U1.TrxSeq = UR.TrxSeq
						and U1.FundNumber = UR.FundNumber 
						and U1.Sequence = UR.Sequence 
						and U1.FundType = UR.FundType 
						and U1.Array = UR.Array 
						and U1.Build = UR.Build 
					'
					
				--========================================================================================
				--PAC Tables
				--========================================================================================
				WHEN 'TransactionAmountsArrayProj' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.TransactionID, T1.AmountCode, T1.Array, T1.RiderId, T1.Build 
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.TransactionID = T1.TransactionID and
							T2.AmountCode = T1.AmountCode and
							T2.Array = T1.Array and
							T2.RiderId = T1.RiderId and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.TransactionID, T1.AmountCode, T1.Array, T1.RiderId, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.TransactionID = UR.TransactionID
						and U1.AmountCode = UR.AmountCode
						and U1.Array = UR.Array
						and U1.RiderId = UR.RiderId
						and U1.Build = UR.Build
					'

				WHEN 'TransactionAmountsProj' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.TransactionID, T1.AmountCode, T1.RiderId, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.TransactionID = T1.TransactionID and
							T2.AmountCode = T1.AmountCode and
							T2.RiderId = T1.RiderId and
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.TransactionID, T1.AmountCode, T1.RiderId, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.TransactionID = UR.TransactionID
						and U1.AmountCode = UR.AmountCode
						and U1.RiderId = UR.RiderId
						and U1.Build = UR.Build
					'
					
				WHEN 'TransactionFundsProj' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.TransactionID, T1.FundNumber, T1.FundType, T1.Variation, T1.Sequence, T1.SubType, T1.Build
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.TransactionID = T1.TransactionID and
							T2.FundNumber = T1.FundNumber and
							T2.FundType = T1.FundType and
							T2.Variation = T1.Variation and
							T2.Sequence = T1.Sequence and
							T2.SubType = T1.SubType and 
							T2.Build = T1.Build
						where 
						T1.Build = ''' + @Build + '''
						group by T1.TransactionID, T1.FundNumber, T1.FundType, T1.Variation, T1.Sequence, T1.SubType, T1.Build
						having count(T1.Number) = 1 ) UR
					where 
						    U1.TransactionID = UR.TransactionID
						and U1.FundNumber = UR.FundNumber
						and U1.FundType = UR.FundType
						and U1.Variation = UR.Variation
						and U1.Sequence = UR.Sequence
						and U1.SubType = UR.SubType
						and U1.Build = UR.Build
					'
					
				WHEN 'TransactionsProj' THEN
					N'
					update U1
					set U1.DiffType = ''U''
					from ' + @varTableName + ' U1,
						(select T1.Number, T1.Effective, T1.TrxCode, T1.TrxSeq, T1.Build 
						from ' + @varTableName + ' T1
						inner join ' + @varTableName + ' T2 on 
							T2.Number = T1.Number and 
							T2.Effective = T1.Effective and 
							T2.TrxCode = T1.TrxCode and 
							T2.TrxSeq = T1.TrxSeq and 
							T2.Build = T1.Build 
						where 
						T1.Build = ''' + @Build + '''
						group by T1.Number, T1.Effective, T1.TrxCode, T1.TrxSeq, T1.Build  
						having count(T1.Number) = 1 ) UR
					where 
						    U1.Number = UR.Number
						and U1.Effective = UR.Effective
						and U1.TrxCode = UR.TrxCode
						and U1.TrxSeq = UR.TrxSeq
						and U1.Build = UR.Build
					'
			END
		
		--select @SQLString
		EXECUTE sp_executesql @SQLString
		
		-- Update the Product # from the Policies table
		SET @SQLString =
			 N'	
				update VT set VT.Product = P.Product
				from ' + @varTableName + ' VT 
				inner join Policies P on P.Number = VT.number			 
			 ';
			 
		--select @SQLString
		EXECUTE sp_executesql @SQLString
		
		
	end
	
GO
