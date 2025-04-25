{%
	let interfaces = services.lookup_interfaces('client');
	services.set_enabled("uconfig-client", !!length(interfaces));
%}
