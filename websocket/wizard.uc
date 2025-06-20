import { readfile, writefile, unlink } from 'fs';
import * as credentials from 'credentials';
import * as digest from 'digest';
import { ubus } from 'libubus';
import * as unet from 'unet';

let zoneinfo = json(readfile('/usr/share/ucode/uconfig/zoneinfo.json') || '{}');

function load_config(file) {
	return json(readfile('/etc/uconfig/webui/' + file));
}

function generate_config(connection, data, config) {
	config.unit.hostname = 'OpenWrt';

	if (zoneinfo[data.timezone]) {
		config.unit.timezone = data.timezone;
		config['country-code'] = zoneinfo[data.timezone].iso2;
	}

	config.interfaces.main.ssids.main.ssid = data.name;
	config.interfaces.main.ssids.main.encryption.key = data.wifipsk;

	config.interfaces.main.ssids.mesh.disable = data.mesh_wifi != 'enable';
	config.interfaces.main.ssids.mesh.ssid = data.name + '_Mesh';
	
	config.interfaces.guest.disable = data.guest_wifi != 'enable';
	if (!config.interfaces.guest.disable) {
		config.interfaces.guest.ssids.guest.ssid = data.name + '_Guest';
		config.interfaces.guest.ssids.guest.encryption.key = data.guestpsk;
	}

	let dns_4 = ubus.call('network.interface.uplink_4', 'status');
	let dns_6 = ubus.call('network.interface.uplink_6', 'status');
	config.services['adguardhome'] = {
			'webui-port': 3000,
			'dns-intercept': false,
			servers: [...dns_4['dns-server'] || [], ...dns_6['dns-server'] || []],
			htpasswd: credentials.htpasswd(data.password),
	};

	writefile('/tmp/webui.cfg.json', config);
	system('uconfig_apply /tmp/webui.cfg.json');
	unlink('/tmp/webui.cfg.json');

	credentials.passwd('admin', data.password);
	connection.data().unet = digest.sha256(data.password);;
}

function configurable(connection, data) {
	let config;
	switch(data.type) {
	case 'ap':
		config = load_config('webui-ap.wizard');
		break;
	case 'router':
		config = load_config('webui-router.wizard');
		break;
	}
	generate_config(connection, data, config);
}

function managed(data) {
	unet.join(data);	
}

export function generate(connection, data) {
	let config;
	switch(data.mode) {
	case 'configurable':
		configurable(connection, data);
		break;
	case 'managed':
		managed(data);
		break;
	}
};
