{%-
	if (!services.is_present("nlbwmon"))
		return;
	let upstream = false;
	let downstream = false;
	for (let k, v in state.interfaces)
		switch(v.role) {
		case 'upstream':
			upstream = true;
			break;
		case 'downstream':
			downstream = true;
			break;

		}
	services.set_enabled('nlbwmon', upstream && downstream);
%}
