--ABC: Add Delta Status 'Confirmed: No Impact'
--ABC: Delete Delta Status- Open and None
--ABC: Set status flag to 1 for status values - 'As Expected','Resolved','Closed','Confirmed: No Impact' .

if not exists (select 1 from Util.DeltaStatus where Status = 'Confirmed: No Impact')
begin
	insert into Util.DeltaStatus values ('Confirmed: No Impact',1)
end
Delete From Util.DeltaStatus where [Status]  in ('Open','None')
Update Util.DeltaStatus set StatusClosedFlag=1  where [Status] in ('As Expected','Resolved','Closed','Confirmed: No Impact')
