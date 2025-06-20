{%
	let controller = !!(interface.easymesh in [ 'hybrid', 'controller' ]);
	if (controller && !services.is_present("umap-controller")) {
		warn('umap-controller is not installed\n');
		return;
	}
	services.set_enabled("umap-controller", controller);

	let agent = !!(interface.easymesh in [ 'hybrid', 'agent' ]);
	if (agent && !services.is_present("umap-agent")) {
		warn('umap-agent is not installed\n');
		return;
	}
	services.set_enabled("umap-agent", agent);

	if (!controller && !agent)
		return;

	let handler = controller ? 'umap-controller' : 'umap-agent';
	let button = uci.get('umapd', '@button[0]', 'wps_button') || 'wps';

	if (interface.easymesh in [ 'hybrid', 'controller' ])
		for (let i, ssid in interface.easymesh_fronthaul) {
			include('easymesh-fronthaul.uc', {
				location: location + '/easymesh-fronthaul/',
				ssid,
			});
		}

	if (interface.easymesh in [ 'hybrid', 'controller' ])
		include('easymesh-backhaul.uc', {
			location: location + '/easymesh-backhaul/',
			ssid: interface.easymesh_backhaul,
		});
	
	if (interface.easymesh in [ 'hybrid', 'controller' ])
		include('easymesh-controller.uc', {
			location: location + '/easymesh-controller/',
			bridgedev,
		});

	if (interface.easymesh in [ 'hybrid', 'agent' ])
		include('easymesh-agent.uc', {
			location: location + '/easymesh-agent/',
			bridgedev,
			no_ubus: interface.easymesh != 'agent',
		});
%}

set system.{{button}}=button
set system.{{button}}.handler={{s('/etc/rc.button/' + handler)}}
