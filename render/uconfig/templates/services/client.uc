{%
	if (!services.is_present('uconfig-client'))
		return;
	let interfaces = services.lookup_interfaces('client');
	services.set_enabled("uconfig-client", !!length(interfaces));
%}
