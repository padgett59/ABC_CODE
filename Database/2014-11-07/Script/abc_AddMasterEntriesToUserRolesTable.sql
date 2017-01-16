if not exists (select 1 from Util.UserRoles where [Role] = 'Administrator')
 begin
	Insert into Util.UserRoles([Role]) select  'Administrator'
 end
if not exists (select 1 from Util.UserRoles where [Role] = 'TechLead')
begin
	Insert into Util.UserRoles([Role]) select  'TechLead'
end

