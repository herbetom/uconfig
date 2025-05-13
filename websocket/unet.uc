import { ulog, LOG_INFO } from 'log';
import * as unetmsg from 'unetmsg.client';
import * as digest from 'digest';
import { ubus } from 'libubus';
import * as fs from 'fs';

let chan;
let cli;

function log(msg) {
	ulog(LOG_INFO, `uconfig: ${msg}`);
}

function unet_enroll(data) {
	global.broadcast([ 'unet', data ]);
	switch(data) {
	case 'join_done':
		system('(uconfig_apply /etc/uconfig/webui/webui-managed.json)&');
		break;
	}
}

function open_cli() {
	if (cli)
		return;
	cli = global.model.context();
	cli = cli.select([ 'unet' ]);
	global.model.add_hook('unet_enroll', unet_enroll);
}

function create_network(connection) {
	if (fs.stat('/etc/uconfig/data/unetd.json'))
		return;
	log('creating unetd network');
	let passwd = connection.data().unet;
	let ret = cli.call([ 'create', 'password', passwd ]);
	log(ret);
	sleep(3000);
}

function onboard(connection, data) {
	if (length(data) < 2)
		return;
	create_network(connection);
	log(`onboard device ${data[0]} ${data[1]}`);
	let edit = cli.select([ 'edit',  'unet',]);
	let ret = edit?.call([ 'invite', data[0], 'access-key', '' + data[1], 'timeout', '60', 'password', connection.data().unet ]);
	log(ret);
	return ret;
}

function delete_host(connection, data) {
	if (length(data) < 1)
		return;
	let edit = cli.select([ 'edit',  'unet' ]);
	let ret = edit?.call([ 'destroy', 'host', data[0] ]);
	edit?.call([ 'apply', 'password', connection.data().unet ]);
	return ret;
}

function list(connection, password) {
	if (!fs.stat('/etc/uconfig/data/unetd.json'))
		return { ok: true };
	open_cli();
	let ret = cli.call([ 'status', 'unet' ]);
	chan.request('uconfig', 'info', {}, (msg) => {
		if (!ret.data[msg.host])
			return;
		for (let k, v in msg.info)
			ret.data[msg.host][k] = v;
	});
	return ret;
}

function reboot(connection, data) {
	if (length(data) < 1)
		return { ok: false };
	chan.send('uconfig', 'reboot', { ok: true });
	return { ok: true };
}

export function password(connection, password) {
	if (!fs.stat('/etc/uconfig/data/unetd.json'))
		return;
	open_cli();
	password = digest.sha256(password);
	let edit = cli.select([ 'edit',  'unet',]);
	let ret = edit?.call([ 'password', 'password', connection.data().unet, 'new-password', password ]);
	edit?.call([ 'apply' ]);
};

export function handler(connection, data) {
	let cmd = shift(data);

	open_cli();

	switch(cmd) {
	case 'delete':
		return delete_host(connection, data);
	case 'reboot':
		return reboot(connection, data);
	case 'onboard':
		return onboard(connection, data);
	case 'list':
		return list(connection, data);
	}
	return { ok: false };
};

function generate_config() {
	let active = fs.readfile('/tmp/uconfig.pending');
	if (!active)
		active = fs.readfile('/etc/uconfig/configs/uconfig.active');
	active = json(active);
	let config = {
		uuid: active.uuid,
		unit: {
			timezone: active.unit.timezone,
			'leds-active' : active.unit['leds-active'],
		},

		main: {
			ssids: active.interfaces.main.ssids,
		},

		guest: {
			disable: active.interfaces.guest.disable || false,
			ssids: active.interfaces.guest.ssids,
		},
	};

        if ('ssh' in active.interfaces.main.services) {
		config.ssh = {
			'authorized-keys': active.services.ssh['authorized-keys'],
		};
	}

	return config;
}

export function config_store() {
	let validate = {
		ok: true
	};
	chan.request('uconfig', 'config-store', generate_config(), (msg) => {
		validate[msg.host] = msg.validate;
		validate.ok &&= msg.validate;
	});
	return validate;
};

export function config_apply() {
	chan.request('uconfig', 'config-apply', {}, (msg) => {
		warn(`Got reply: ${msg}\n`);
	});
	return { ok: true };
};

export function join(data) {
	open_cli();
	log('start onboarding');
	let ret = cli.call([ 'join', 'access-key', data['access-key'], 'local-network', 'uplink_4' ]); 
	log(ret);
};

export function init() {
	chan = unetmsg.open(ubus);
	chan.publish('uconfig', (req) => {});
	chan.subscribe('uconfig', (req) => {
		/* ... */
		}, () => {
			log('client list changed');
			chan.request('uconfig', 'config-push', generate_config(), (msg) => {
	        	        warn(`Got reply: ${msg}\n`);
			});
		});

};
