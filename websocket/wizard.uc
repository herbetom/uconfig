import { readfile, writefile, unlink } from 'fs';
import * as credentials from 'credentials';
import * as unet from 'unet';

let zoneinfo = json(readfile('/usr/share/ucode/uconfig/zoneinfo.json') || '{}');

function load_config(file) {
	return json(readfile('/etc/uconfig/examples/' + file));
}

function generate_config(data, config) {
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
	config.interfaces.guest.ssids.guest.disable = data.guest_wifi != 'enable';
	if (!config.interfaces.guest.disable) {
		config.interfaces.guest.ssids.guest.ssid = data.name + '_Guest';
		config.interfaces.guest.ssids.guest.encryption.key = data.guestpsk;
	}

	writefile('/tmp/webui.cfg.json', config);
	system('uconfig_apply /tmp/webui.cfg.json');
	unlink('/tmp/webui.cfg.json');

	credentials.passwd('admin', data.password);
}

function configurable(data) {
	let config;
	switch(data.standalone) {
	case 'ap':
		config = load_config('webui-ap.wizard');
		break;
	case 'router':
		config = load_config('webui-router.wizard');
		break;
	}
	generate_config(data, config);
}

function managed(data) {
	unet.join(data);	
}

export function generate(data) {
	let config;
	switch(data.mode) {
	case 'configurable':
		configurable(data);
		break;
	case 'managed':
		managed(data);
		break;
	}
};
