import { ubus } from 'libubus';

export function internet() {
	let name = 'uplink';
	if (global.settings.type == 'ap')
		name = 'main';
	let iface = ubus.call(`network.interface.${name}`, 'status');
	let iface_4 = ubus.call(`network.interface.${name}_4`, 'status');
	let iface_6 = ubus.call(`network.interface.${name}_6`, 'status');

	let ret = {
		connected: iface.up,
		uptime: iface.uptime,
		ipv4: iface_4['ipv4-address'][0].address,
	};

	return ret;
};
