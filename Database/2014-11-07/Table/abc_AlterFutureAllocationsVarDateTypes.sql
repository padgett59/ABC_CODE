--Util.FutureAllocations_BC_VAR 
--Change StartDate, EndDate columns from DateTime to varchar(12)
--Rerunnable As-Is

Alter table Util.FutureAllocations_BC_VAR 
alter column StartDate varchar(12) NULL

Alter table Util.FutureAllocations_BC_VAR 
alter column EndDate varchar(12) NULL
