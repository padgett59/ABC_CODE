
if not exists (select 1 from Util.DeltaStatus where [Status] = 'None')
begin
	insert into Util.DeltaStatus  select  'None',0
end







