-- Update abc messages to include clickable URL
update Util.NotifyMessage set Message =   
	'You have been assigned an ABC delta for build ~b~ in test region: ~r~. Please login to ~url~ to view the delta details and add comments.'
	where Alias = 'DeltaAssigned'
	
update Util.NotifyMessage set Message =   
	'For build ~b~ in test region: ~r~, the Automated Build Compare run completed at ~t~ with ~ec~ run errors and ~dc~ deltas. Run elapsed time was: ~et~ Please login to ~url~ to assign the deltas for resolution.'
	where Alias = 'RunComplete'

update Util.NotifyMessage set Message =   
	'The status of the ABC Delta for build ~b~ in test region: ~r~ has been changed to ~s~. Log in to ~url~ to view the change.'
	where Alias = 'DeltaStatus'

update Util.NotifyMessage set Message =   
	'The status of ABC Delta for build ~b~ in test region: ~r~ has been changed to resolved. Log in to ~url~ to view the change.'
	where Alias = 'DeltaResolved'

update Util.NotifyMessage set Message =   
	'One or more Deltas have occurred for build ~b~ in test region: ~r~. Please login to ~url~ and assign the Deltas to a developer.'
	where Alias = 'RunDeltas'
