
--Delete ynPolicyTrx from RunControlFiles

if exists(
	select * from util.RunControlFiles where RunType = 'B' 
	and sourcetype = 's' 
	and value = 'ynPolicyTrx')
begin
	delete from util.RunControlFiles where RunType = 'B' 
	and sourcetype = 's' and
	value = 'ynPolicyTrx'
end
