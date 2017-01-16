
--============================================================================================================
-- Stored Procedure abc_ConditionPoliciesForPac
--
-- Returns nNumberProcess records for executing PAC Projections against the Census policies 
-- for the ABC application
--
-- Created by Anthony Padgett 6/18/2014
--============================================================================================================

-- Determine which policies are elgible for Projections
-- Build Policy List with correct numbers for each type
-- Filter from PolicyList if policy is not in build table
-- Insert Records into TransactionsDaily for the PAC Projections
-- Return list of PAC policies to run projections for
-- 
if object_id('Util.abc_ConditionPoliciesForPac', 'P') is null  --does the object already exist
begin
     exec('create procedure util.abc_ConditionPoliciesForPac as select 1') --create a simple stub procedure using dynamic sql
end

go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
ALTER PROCEDURE [Util].[abc_ConditionPoliciesForPac] 

AS
SET NOCOUNT ON


-- Set up Temp Tables
IF OBJECT_ID('tempdb..#ProjectionResultSet') IS NOT NULL DROP TABLE #ProjectionResultSet
IF OBJECT_ID('tempdb..#PolicyList') IS NOT NULL DROP TABLE #PolicyList
IF OBJECT_ID('tempdb..#AnnivTemp') IS NOT NULL DROP TABLE #AnnivTemp


create table #PolicyList (
Number [INT] NOT NULL,
TrxCode [SMALLINT] NOT NULL,
PRIMARY KEY (Number, TrxCode)
)
--================================================================================================================

--==========================================================
-- Determine which policies are elgible for Projections
--==========================================================


--10s -- NNP for 1,1,1,0
        select 0 EDBG, p.FactorTable FT, t.[Transaction], 
        p.NUMBER, t.effective effdate, 1 corrective, cast(1 as tinyint) coitype, cast(1 as tinyint) premiumtype,   
               p.factortable, cast(0 as tinyint) QueryType
		into #ProjectionResultSet
        from policies p   
        inner join products pr on p.reportcodenumber = pr.reportcodenumber   
        inner join transactions t on p.NUMBER = t.NUMBER   
        inner join status s on s.code = p.status  
        left join Transactions A on P.Number = A.Number and A.[Transaction] = 20 and A.Status = 2 
			and A.Process = (Select CycleDate from Batch)
        inner join Rider r on r.Number = p.Number
        --left join TransactionsDaily lapse on lapse.Number = p.Number and t.process = lapse.process and lapse.[Transaction] = 220 and lapse.Status = 2 and lapse.RiderId = r.RiderId 
        where pr.groupind in (2, 4)   
        and pr.fundbase = 'F0'   
        and t.[transaction] = 10   
        and t.status = 2   
        --and t.process = @pDate   
        and s.activity = 1 
        and A.Number is null   
        --and ((r.RiderCode = 1 and lapse.Number is null) or r.RiderCode <> 1)
        --order by product

		union 
		
-- Same for 1,2,1,0
        select   0 EDBG, p.FactorTable FT, t.[Transaction],
        p.NUMBER, t.effective effdate, 1 corrective, cast(2 as tinyint) coitype, cast(1 as tinyint) premiumtype,   
               p.factortable, cast(0 as tinyint) QueryType

        from policies p   
        inner join products pr on p.reportcodenumber = pr.reportcodenumber   
        inner join transactions t on p.NUMBER = t.NUMBER   
        inner join status s on s.code = p.status  
        left join Transactions A on P.Number = A.Number and A.[Transaction] = 20 and A.Status = 2 
			and A.Process = (Select CycleDate from Batch)
        inner join Rider r on r.Number = p.Number
        --left join TransactionsDaily lapse on lapse.Number = p.Number and t.process = lapse.process and lapse.[Transaction] = 220 and lapse.Status = 2 and lapse.RiderId = r.RiderId 
        where pr.groupind in (2, 4)   
        and pr.fundbase = 'F0'   
        and t.[transaction] = 10   
        and t.status = 2   
        --and t.process = @pDate   
        and s.activity = 1 
        and A.Number is null   
        --and ((r.RiderCode = 1 and lapse.Number is null) or r.RiderCode <> 1)
        --order by product

		union

-- Same for 1,1,3,0
        select 0 EDBG, p.FactorTable FT, t.[Transaction], 
        p.NUMBER, t.effective effdate, 1 corrective, cast(1 as tinyint) coitype, cast(3 as tinyint) premiumtype,   
               p.factortable, cast(0 as tinyint) QueryType
        from policies p   
        inner join products pr on p.reportcodenumber = pr.reportcodenumber   
        inner join transactions t on p.NUMBER = t.NUMBER   
        inner join status s on s.code = p.status  
        left join Transactions A on P.Number = A.Number and A.[Transaction] = 20 and A.Status = 2 
			and A.Process = (Select CycleDate from Batch)
        inner join Rider r on r.Number = p.Number
        --left join TransactionsDaily lapse on lapse.Number = p.Number and t.process = lapse.process and lapse.[Transaction] = 220 and lapse.Status = 2 and lapse.RiderId = r.RiderId 
        where pr.groupind in (2, 4)   
        and pr.fundbase = 'F0'   
        and t.[transaction] = 10   
        and t.status = 2   
        --and t.process = @pDate   
        and s.activity = 1 
        and A.Number is null   
        --and ((r.RiderCode = 1 and lapse.Number is null) or r.RiderCode <> 1)
        --order by product

		union

-- Same for 1,2,3,0
        select 0 EDBG, p.FactorTable FT, t.[Transaction], 
        p.NUMBER, t.effective effdate, 1 corrective, cast(2 as tinyint) coitype, cast(3 as tinyint) premiumtype,   
               p.factortable, cast(0 as tinyint) QueryType
        from policies p   
        inner join products pr on p.reportcodenumber = pr.reportcodenumber   
        inner join transactions t on p.NUMBER = t.NUMBER   
        inner join status s on s.code = p.status  
        left join Transactions A on P.Number = A.Number and A.[Transaction] = 20 and A.Status = 2 
			and A.Process = (Select CycleDate from Batch)
        inner join Rider r on r.Number = p.Number
        --left join TransactionsDaily lapse on lapse.Number = p.Number and t.process = lapse.process and lapse.[Transaction] = 220 and lapse.Status = 2 and lapse.RiderId = r.RiderId 
        where pr.groupind in (2, 4)   
        and pr.fundbase = 'F0'   
        and t.[transaction] = 10   
        and t.status = 2   
        --and t.process = @pDate   
        and s.activity = 1 
        and A.Number is null   
        --and ((r.RiderCode = 1 and lapse.Number is null) or r.RiderCode <> 1)
        --order by product
        
        union
        
--PA EDBG Issue (10s) 1,2,1,0
        select 
        1 EDBG, p.FactorTable FT, t.[Transaction], 
        p.NUMBER, t.effective effdate, 1 corrective, cast(2 as tinyint) coitype, cast(1 as tinyint) premiumtype,   
               p.factortable, cast(0 as tinyint) QueryType   
        from policies p   
        inner join products pr on p.reportcodenumber = pr.reportcodenumber   
        inner join transactions t on p.NUMBER = t.NUMBER   
        inner join status s on s.code = p.status 
        inner join Rider ri on ri.Number = p.Number
        inner join RiderOptions ro on ro.Number = ri.Number and ro.RiderId = ri.RiderId
        left join Transactions A on P.Number = A.Number and A.[Transaction] = 20 and A.Status = 2 and A.Process = (SELECT CYCLEDATE FROM BATCH)  
        inner join xFactors varProjToMonthlyFixed on varProjToMonthlyFixed.FactorTable = p.FactorTable and varProjToMonthlyFixed.Code = 19 
        inner join xFactors edbgActive on edbgActive.FactorTable = p.FactorTable and edbgActive.Code = 190		
        inner join Rider r on r.Number = p.Number
        --left join TransactionsDaily lapse on lapse.Number = p.Number and t.process = lapse.process and lapse.[Transaction] = 220 and lapse.Status = 2 and lapse.RiderId = r.RiderId 
        where pr.groupind in (2, 4) and pr.fundbase <> 'F0' and t.[transaction] = 10 and t.status = 2   
        --and t.process = @pDate 
        and s.activity = 1 and A.Number is null 
        and p.State = varProjToMonthlyFixed.Amount
        and ro.AmountCode = edbgActive.Amount
        and ro.Amount <> 0 -- 0=inactive edbg  
        --and ((r.RiderCode = 1 and lapse.Number is null) or r.RiderCode <> 1)
        --and ((r.RiderCode = 1 ) or r.RiderCode <> 1)
        --order by product

		union

--20s 

--1,1,0, [0 or 1]

        select 
        0 EDBG, p.FactorTable FT, t.[Transaction], 
        p.NUMBER, max(t.effective) effdate, 1 corrective, cast(1 as tinyint) coitype, cast(0 as tinyint) premiumtype,   
        p.factortable, case when Pr.FundBase = 'F0' then cast(0 as tinyint)  else cast(1 as tinyint) end QueryType   
        from policies p   
        inner join products pr on p.reportcodenumber = pr.reportcodenumber   
        --inner join transactionsdaily t on p.NUMBER = t.NUMBER   
        inner join transactions t on p.NUMBER = t.NUMBER   
        inner join dailyreportsdriver d on p.product = d.product and t.[transaction] = d.[transaction] 
        inner join Rider r on r.Number = p.Number
        --left join TransactionsDaily lapse on lapse.Number = p.Number and t.process = lapse.process and lapse.[Transaction] = 220 and lapse.Status = 2 and lapse.RiderId = r.RiderId 
        where pr.groupind in (2, 4)
        and t.[transaction] = 20   
        and t.status = 2   
        --and t.process = @pDate 
        --and ((r.RiderCode = 1 and lapse.Number is null) or r.RiderCode <> 1)
        group by p.NUMBER, p.factortable, pr.FundBase   
        ,t.[Transaction]
        --order by p.FactorTable FT
        
        union

--1,2,0,[0 or 1]

        select 
        0 EDBG, p.FactorTable FT, t.[Transaction], 
        p.NUMBER, max(t.effective) effdate, 1 corrective, cast(2 as tinyint) coitype, cast(0 as tinyint) premiumtype,   
        p.factortable, case when Pr.FundBase = 'F0' then cast(0 as tinyint)  else cast(1 as tinyint) end QueryType   
        from policies p   
        inner join products pr on p.reportcodenumber = pr.reportcodenumber   
        --inner join transactionsdaily t on p.NUMBER = t.NUMBER   
        inner join transactions t on p.NUMBER = t.NUMBER   
        inner join dailyreportsdriver d on p.product = d.product and t.[transaction] = d.[transaction] 
        inner join Rider r on r.Number = p.Number
        --left join TransactionsDaily lapse on lapse.Number = p.Number and t.process = lapse.process and lapse.[Transaction] = 220 and lapse.Status = 2 and lapse.RiderId = r.RiderId 
        where pr.groupind in (2, 4)
        and t.[transaction] = 20   
        and t.status = 2   
        --and t.process = @pDate 
        --and ((r.RiderCode = 1 and lapse.Number is null) or r.RiderCode <> 1)
        group by p.NUMBER, p.factortable, pr.FundBase   
        , t.[Transaction]
        --order by p.FactorTable FT
        
        union

--1,1,1,0

        select 
        0 EDBG, p.FactorTable FT, t.[Transaction], 
        p.NUMBER, max(t.effective) effdate, 1 corrective, cast(1 as tinyint) coitype, cast(1 as tinyint) premiumtype,   
        p.factortable, cast(0 as tinyint) QueryType    
        from policies p   
        inner join products pr on p.reportcodenumber = pr.reportcodenumber   
        --inner join transactionsdaily t on p.NUMBER = t.NUMBER   
        inner join transactions t on p.NUMBER = t.NUMBER   
        inner join dailyreportsdriver d on p.product = d.product and t.[transaction] = d.[transaction] 
        inner join Rider r on r.Number = p.Number
        --left join TransactionsDaily lapse on lapse.Number = p.Number and t.process = lapse.process and lapse.[Transaction] = 220 and lapse.Status = 2 and lapse.RiderId = r.RiderId 
        where pr.groupind in (2, 4)
        and t.[transaction] = 20   
        and t.status = 2   
        --and t.process = @pDate 
        --and ((r.RiderCode = 1 and lapse.Number is null) or r.RiderCode <> 1)
        group by p.NUMBER, p.factortable, pr.FundBase   
        , t.[Transaction]
        --order by p.FactorTable FT
        
        union

--1,2,1,0

        select 
        0 EDBG, p.FactorTable FT, t.[Transaction], 
        p.NUMBER, max(t.effective) effdate, 1 corrective, cast(2 as tinyint) coitype, cast(1 as tinyint) premiumtype,   
        p.factortable, cast(0 as tinyint) QueryType    
        from policies p   
        inner join products pr on p.reportcodenumber = pr.reportcodenumber   
        --inner join transactionsdaily t on p.NUMBER = t.NUMBER   
        inner join transactions t on p.NUMBER = t.NUMBER   
        inner join dailyreportsdriver d on p.product = d.product and t.[transaction] = d.[transaction] 
        inner join Rider r on r.Number = p.Number
        --left join TransactionsDaily lapse on lapse.Number = p.Number and t.process = lapse.process and lapse.[Transaction] = 220 and lapse.Status = 2 and lapse.RiderId = r.RiderId 
        where pr.groupind in (2, 4)
        and t.[transaction] = 20   
        and t.status = 2   
        --and t.process = @pDate 
        --and ((r.RiderCode = 1 and lapse.Number is null) or r.RiderCode <> 1)
        group by p.NUMBER, p.factortable, pr.FundBase   
        , t.[Transaction]
        --order by p.FactorTable FT

		union
		
--1,1,2,0

        select 
        0 EDBG, p.FactorTable FT, t.[Transaction], 
        p.NUMBER, max(t.effective) effdate, 1 corrective, cast(1 as tinyint) coitype, cast(2 as tinyint) premiumtype,   
        p.factortable, cast(0 as tinyint) QueryType    
        from policies p   
        inner join products pr on p.reportcodenumber = pr.reportcodenumber   
        --inner join transactionsdaily t on p.NUMBER = t.NUMBER   
        inner join transactions t on p.NUMBER = t.NUMBER   
        inner join dailyreportsdriver d on p.product = d.product and t.[transaction] = d.[transaction] 
        inner join Rider r on r.Number = p.Number
        --left join TransactionsDaily lapse on lapse.Number = p.Number and t.process = lapse.process and lapse.[Transaction] = 220 and lapse.Status = 2 and lapse.RiderId = r.RiderId 
        where pr.groupind in (2, 4)
        and t.[transaction] = 20   
        and t.status = 2   
        --and t.process = @pDate 
        --and ((r.RiderCode = 1 and lapse.Number is null) or r.RiderCode <> 1)
        group by p.NUMBER, p.factortable, pr.FundBase   
        , t.[Transaction]
        --order by p.FactorTable FT
        
--select COUNT(*) from  #ProjectionResultSet --order by 1 desc,3,2,4
--select Number, count(Number) from  #ProjectionResultSet group by Number order by count(Number) desc



	
--==========================================================
-- Get specific quantities of each type for PAC projection
--==========================================================


-- EDBG
	insert into #PolicyList
		select top 1 Number, 10 from #ProjectionResultSet 
		where factortable = 4 and EDBG = 1 and [Transaction] = 10
	insert into #PolicyList
		select top 1 Number, 10  from #ProjectionResultSet 
		where factortable = 43 and EDBG = 1 and [Transaction] = 10
	
--Variable Annuals
	insert into #PolicyList
		select top 10 Number, 20 from #ProjectionResultSet PRS
		where 
			factortable = 2 and EDBG = 0 and [Transaction] = 20
			and Number not in (select Number from #PolicyList where TrxCode = 10)
		group by Number
	
	insert into #PolicyList
		select top 10 Number, 20 from #ProjectionResultSet 
		where factortable = 46 and EDBG = 0 and [Transaction] = 20
			and Number not in (select Number from #PolicyList where TrxCode = 10)
		group by Number

	insert into #PolicyList
		select top 10 Number, 20 from #ProjectionResultSet 
		where factortable = 50 and EDBG = 0 and [Transaction] = 20
			and Number not in (select Number from #PolicyList where TrxCode = 10)
		group by Number

	insert into #PolicyList
		select top 8 Number, 20 from #ProjectionResultSet 
		where factortable = 4 and EDBG = 0 and [Transaction] = 20
			and Number not in (select Number from #PolicyList where TrxCode = 10)
		group by Number

	insert into #PolicyList
		select top 8 Number, 20 from #ProjectionResultSet 
		where factortable = 43 and EDBG = 0 and [Transaction] = 20
			and Number not in (select Number from #PolicyList where TrxCode = 10)
		group by Number

--Fixed Annual
	insert into #PolicyList
		select top 5 Number, 20 from #ProjectionResultSet 
		where factortable = 12 and EDBG = 0 and [Transaction] = 20
			and Number not in (select Number from #PolicyList where TrxCode = 10)
		group by Number

	insert into #PolicyList
		select top 5 Number, 20 from #ProjectionResultSet 
		where factortable = 16 and EDBG = 0 and [Transaction] = 20
			and Number not in (select Number from #PolicyList where TrxCode = 10)
		group by Number

	insert into #PolicyList
		select top 5 Number, 20 from #ProjectionResultSet 
		where factortable = 20 and EDBG = 0 and [Transaction] = 20
			and Number not in (select Number from #PolicyList where TrxCode = 10)
		group by Number

	insert into #PolicyList
		select top 5 Number, 20 from #ProjectionResultSet 
		where factortable = 22 and EDBG = 0 and [Transaction] = 20
			and Number not in (select Number from #PolicyList where TrxCode = 10)
		group by Number

	insert into #PolicyList
		select top 5 Number, 20 from #ProjectionResultSet 
		where factortable = 27 and EDBG = 0 and [Transaction] = 20
			and Number not in (select Number from #PolicyList where TrxCode = 10)
		group by Number

	insert into #PolicyList
		select top 5 Number, 20 from #ProjectionResultSet 
		where factortable = 42 and EDBG = 0 and [Transaction] = 20
			and Number not in (select Number from #PolicyList where TrxCode = 10)
		group by Number

	insert into #PolicyList
		select top 5 Number, 20 from #ProjectionResultSet 
		where factortable = 44 and EDBG = 0 and [Transaction] = 20
			and Number not in (select Number from #PolicyList where TrxCode = 10)
		group by Number

	insert into #PolicyList
		select top 5 Number, 20 from #ProjectionResultSet 
		where factortable = 45 and EDBG = 0 and [Transaction] = 20
			and Number not in (select Number from #PolicyList where TrxCode = 10)
		group by Number


--Fixed Issue
	insert into #PolicyList
		select top 5 Number, 10 from #ProjectionResultSet 
		where factortable = 12 and EDBG = 0 and [Transaction] = 10
			and Number not in (select Number from #PolicyList where TrxCode = 20)
		group by Number

	insert into #PolicyList
		select top 5 Number, 10 from #ProjectionResultSet 
		where factortable = 16 and EDBG = 0 and [Transaction] = 10
			and Number not in (select Number from #PolicyList where TrxCode = 20)
		group by Number

	insert into #PolicyList
		select top 5 Number, 10 from #ProjectionResultSet 
		where factortable = 20 and EDBG = 0 and [Transaction] = 10
			and Number not in (select Number from #PolicyList where TrxCode = 20)
		group by Number

	insert into #PolicyList
		select top 5 Number, 10 from #ProjectionResultSet 
		where factortable = 22 and EDBG = 0 and [Transaction] = 10
			and Number not in (select Number from #PolicyList where TrxCode = 20)
		group by Number

	insert into #PolicyList
		select top 5 Number, 10 from #ProjectionResultSet 
		where factortable = 27 and EDBG = 0 and [Transaction] = 10
			and Number not in (select Number from #PolicyList where TrxCode = 20)
		group by Number

	insert into #PolicyList
		select top 5 Number, 10 from #ProjectionResultSet 
		where factortable = 42 and EDBG = 0 and [Transaction] = 10
			and Number not in (select Number from #PolicyList where TrxCode = 20)
		group by Number

	insert into #PolicyList
		select top 5 Number, 10 from #ProjectionResultSet 
		where factortable = 44 and EDBG = 0 and [Transaction] = 10
			and Number not in (select Number from #PolicyList where TrxCode = 20)
		group by Number

	insert into #PolicyList
		select top 5 Number, 10 from #ProjectionResultSet 
		where factortable = 45 and EDBG = 0 and [Transaction] = 10
			and Number not in (select Number from #PolicyList where TrxCode = 20)
		group by Number


--================================================================
-- Filter from PolicyList if policy is not in build table
--================================================================
delete from #PolicyList where Number not in (select Number from Build)
	

--================================================================
-- Insert Records into TransactionsDaily for the PAC Projections
--================================================================
delete from TransactionsDaily

--10s
insert into TransactionsDaily (
	[Status], [Transaction], TrxSeq, Number, MemoCode, MoneyType, Amount, AmountType, 
	CostBasis, Effective, Valued, BuySell, Process, FirstProcessed, ReversalCv, 
	GainLossReason, ErrorNumber, OldId, ReportCodeNumber, RiderId, UserId, ArchiveID
)
select distinct
	T.[Status], T.[Transaction], TrxSeq, T.Number, MemoCode, MoneyType, Amount, 
	AmountType, CostBasis, Effective, Valued, (select cycleDate from batch) BuySell, (select cycleDate from batch) Process, FirstProcessed, 
	ReversalCv, GainLossReason, ErrorNumber, OldId, ReportCodeNumber, RiderId, 
	UserId, DailyID
from transactions T
inner join #ProjectionResultSet PRS on PRS.Number = T.number and PRS.[Transaction] = T.[Transaction]
inner join #PolicyList PLI on PLI.Number = T.number and PLI.TrxCode = T.[Transaction]
where PRS.[Transaction] = 10 and T.Status = 2 

--select * from TransactionsDaily where [Transaction] = 10

-- for 20s copy in the latest anniversary from Transactions table
select ATV.* into #AnnivTemp
from 
(Select distinct
	T.[Status], T.[Transaction], TrxSeq, T.Number, MemoCode, MoneyType, Amount, 
	AmountType, CostBasis, Effective, Valued, (select cycleDate from batch) BuySell, (select cycleDate from batch) Process, FirstProcessed, 
	ReversalCv, GainLossReason, ErrorNumber, OldId, ReportCodeNumber, RiderId, 
	UserId, DailyID
from transactions T
inner join #ProjectionResultSet PRS on PRS.Number = T.number and PRS.[Transaction] = T.[Transaction]
inner join #PolicyList PLI on PLI.Number = T.number and PLI.TrxCode = T.[Transaction]
where PRS.[Transaction] = 20 and T.Status = 2) ATV

insert into TransactionsDaily (
	[Status], [Transaction], TrxSeq, Number, MemoCode, MoneyType, Amount, AmountType, 
	CostBasis, Effective, Valued, BuySell, Process, FirstProcessed, ReversalCv, 
	GainLossReason, ErrorNumber, OldId, ReportCodeNumber, RiderId, UserId, ArchiveID
)
select 
	A1.[Status], A1.[Transaction], A1.TrxSeq, A1.Number, A1.MemoCode, A1.MoneyType, A1.Amount, 
	A1.AmountType, A1.CostBasis, A1.Effective, A1.Valued, (select cycleDate from batch) BuySell, (select cycleDate from batch) Process, 
	A1.FirstProcessed, 
	A1.ReversalCv, A1.GainLossReason, A1.ErrorNumber, A1.OldId, A1.ReportCodeNumber, A1.RiderId, 
	A1.UserId, A1.DailyID
from #AnnivTemp A1
left outer join #AnnivTemp  A2 on 
	(A2.Number = A1.number 
	and A2.[Transaction] = A1.[Transaction] 
	and A1.Effective < A2.Effective)
where A2.Effective is null

--select * from TransactionsDaily where [Transaction] = 20
--select COUNT(*) from TransactionsDaily 


--================================================================
-- Return Policies conditioned
--================================================================
select * from #PolicyList
