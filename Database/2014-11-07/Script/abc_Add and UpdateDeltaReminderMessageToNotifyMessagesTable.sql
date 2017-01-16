
if not exists (select 1 from Util.NotifyMessage where Alias = 'DeltaReminder')
begin
	insert into Util.NotifyMessage  select  'DeltaReminder','ABC Delta Assignment Reminder','This is an automated reminder to resolve the below assigned ABC Delta(s) from region : ~r~. Please resolve and update the status at ~url~ as soon as possible.Thank You!',NULL,1 
end
update util.NotifyMessage set LogMessage=0 where Alias <> 'DeltaReminder'






