/* Copyright (C) 2024 John Crispin <john@phrozen.org> */

'use strict';

import { ulog_open, ulog, ULOG_SYSLOG, ULOG_STDIO, LOG_DAEMON, LOG_INFO } from 'log';
import { installed_modules } from 'modules';
import * as credentials from 'credentials';
import * as datamodel from 'cli.datamodel';
import { readfile, writefile } from 'fs';
import { generate } from 'wizard';
import * as digest from 'digest';
import * as users from 'users';
import { ubus } from 'libubus';
import * as state from 'state';
import { event } from 'event';
import { timer } from 'uloop';
import * as unet from 'unet';

ulog_open(ULOG_SYSLOG | ULOG_STDIO, LOG_DAEMON, 'uconfig.server');

unet.init();

global.connections = {};
global.ctx = {};
global.uconfig_webui = true;
global.shutdown = false;

global.settings = json(readfile('/etc/uconfig/webui/webui.json') || '{}');

function send(connection, data, no_log) {
	let peer = connection?.info()?.peer_address;
	if (!peer)
		return;
	if (!no_log)
		warn(`${peer}: TX ${data}\n`);
	connection.send(`${data}`);
}

function broadcast(data, no_log) {
	for (let name, connection in global.connections)
		send(connection, data, no_log);
}
global.broadcast = broadcast;

function shutdown_server() {
	global.shutdown = true;
	for (let name, connection in global.connections)
		connection.close(1012, 'Server is restarting');
}
global.shutdown_server = shutdown_server;

let ping_timer;
function ping() {
	ping_timer.set(5000);
	broadcast([ 'ping' ], true);
}
ping_timer = timer(1000, ping);

let model = datamodel.new({
	status_msg: (msg) => {
//		broadcast([ 'event', msg ]);
	},
});
model.add_modules();
model.init();
global.model = model;
let cli = model.context();
cli = cli.select([ 'uconfig' ]);
//cli.call(['event', 'subscribe']);

function send_authenticated(connection, event) {
	send(connection, [ event ? event : 'authenticated', { pending_changes: !!model.uconfig.changed, mode: global.settings.type, modules: installed_modules() }]);
}

function send_setup_required(connection) {
	send(connection, [ 'setup-required', { modules: installed_modules() }]);
}

function connect_cb(connection) {
	try {
		if (connection.data()?.authenticate)
			return send_authenticated(connection);
		if (!global.settings.configured)
			return send_setup_required(connection);

		send(connection, [ 'login-required' ]);
	} catch(e) {
		warn(`${e.stacktrace[0].context}\n`);
		return;
	}
}

function connection_name(connection) {
	let info = connection.info();

	return `${info.peer_address}:${info.peer_port}`;
}

export function onConnect(connection, protocols)
{
	if (global.shutdown)
		return connection.close(1012, 'Server is restarting');

	if (!('config' in protocols))
		return connection.close(1003, 'Unsupported protocol requested');
 
	let cli = model.context();
	cli = cli.select([ 'uconfig' ]);
	let ctx = {
		counter: 0,
		n_messages: 0,
		n_fragments: 0,
		msg: '',
		cli,
	};
	connection.data(ctx);

	let name = connection_name(connection);
	global.connections[name] = connection;
	global.ctx[name] = ctx;

	ulog(LOG_INFO, name + ' connected\n');
	timer(1000, () => connect_cb(connection));

	return connection.accept('config');
};

export function onClose(connection, code, reason)
{
	let name = connection_name(connection);
	ulog(LOG_INFO, name + ` disconnected ${connection.data().authenticated ? connection.data().user : ''}\n`);
	if (global.connections[name].cli)
		delete global.connections[name].cli;
	delete global.connections[name];
	delete global.ctx[name];
};

let states = {
	system: function(connection) {
		let ret = {
			board: ubus.call('system', 'board'),
			info: ubus.call('system', 'info'),
		};
		let thermal = readfile('/sys/class/hwmon/hwmon0/temp1_input');
		if (thermal)
			ret.thermal = +thermal / 1000;
		return ret;
	},

	devices: function(connection, data, cli) {
		switch(data[1]) {
		case 'hostname':
			if (length(data) < 4)
				return null;
			return ubus.call('state', 'device_hostname', { mac: data[2], hostname: data[3] });
		case 'delete':
			if (length(data) < 3)
				return null;
			return ubus.call('state', 'device_delete', { mac: data[2] });
		}
		return ubus.call('state', 'devices', { arp: data[1] == 'arp' });
	},

	ports: function(connection, data, cli) {
		return ubus.call('state', 'ports');
	},

	radios: function(connection, data, cli) {
		return ubus.call('state', 'radios');
	},

	traffic: function(connection, data, cli) {
		return ubus.call('state', 'traffic');
	},

	internet: function() {
		return state.internet();
	},

	events: function() {
		return ubus.call('event', 'log');
	},
};

let user = {
	list: function() {
		return users.list();
	},

	password: function(connection, data, cli) {
		return users.set_password(data)
	},
};

let actions = {
	reboot: function() {
		shutdown_server();
		timer(2000, () => {
			ulog(LOG_INFO, 'rebooting\n');
			ubus.call('system', 'reboot')
		});
	},

	factory: function() {
		shutdown_server();
		timer(2000, () => {
			ulog(LOG_INFO, 'factory resetting\n');
			system('factoryreset -y -r');
		});
	},
};

let handlers = {
	authenticate: function(connection, data) {
		if (connection?.data()?.authenticate) {
			send_authenticated(connection);
			return;
		}
		let name = connection_name(connection);

		if (length(data) != 2 ||
		    !credentials.login(data[0], data[1])) {
			ulog(LOG_INFO, `${name} wrong-password ${data[0]}\n`);
			send(connection, [ 'wrong-password' ]);
			return;
		}
	
		ulog(LOG_INFO, `${name} logged-in ${data[0]}\n`);
		connection.data().user = data[0];
		connection.data().authenticated = true;
		connection.data().unet = digest.sha256(data[1]);;
		send_authenticated(connection);
	},

	'log-out': function(connection, data) {
		let name = connection_name(connection);
		ulog(LOG_INFO, `${name} logged-out ${connection.data().user}\n`);
		connection.data().authenticated = false;
		connection.close(1000, 'Successful operation, connection not required anymore');
	},

	password: function(connection, data, cli) {
		if (length(data) < 1)
			return;
		cli.call([ 'edit', 'services', 'adguardhome', 'set', 'htpasswd', credentials.htpasswd(data[0]) ]);
		cli.call([ 'commit' ]);
		credentials.passwd('admin', data[0]);
	},

	command: function(connection, data, cli) {
		if (length(data) < 2)
			return;
		let id = shift(data); 
		let ret = cli.call(data);
		send(connection, [ 'result', id, ret ]);
	},

	commit: function(connection, data, cli) {
		let id = shift(data); 
		cli.call([ 'write' ]);
		let ret = unet.config_store();
		if (!ret.ok)
			return send(connection, [ 'result', id, ret ]);
		ret = unet.config_apply();
		if (!ret.ok)
			return send(connection, [ 'result', id, ret ]);
		ret = cli.call([ 'commit' ]);
		event('config', 'applied', {});
		return send(connection, [ 'result', id, ret ]);
	},

	get: function(connection, data, cli) {
		if (length(data) < 2)
			return;
		let id = shift(data); 
		let ret = { };
		for (let name, path in data[0]) {
			let data = cli.call(path);
			ret[name] = data.data;
		}
		send(connection, [ 'result', id, ret ]);
	},

	set: function(connection, data, cli) {
		if (length(data) < 2)
			return;

		cli.call([ 'push' ]);

		let id = shift(data); 
		let ret = {
			errors: [],
			ok: true
		};

		if (type(data[0]) == 'array')
			data[0] = { request: data[0] };

		for (let name, path in data[0]) {
			let data = cli.call(path);
			if (!data?.ok) {
				ret.ok = false;
				if (data)
					ret.errors = [ ...ret.errors, ...data?.errors ];
			}
		}
		if (!ret.ok)
			cli.call([ 'pop' ]);
		send(connection, [ 'result', id, ret ]);
	},

	action: function(connection, data) {
		if (!actions[data[0]])
			return;
		actions[data[0]]();
	},

	state: function(connection, data, cli) {
		if (length(data) < 2)
			return;
		let id = shift(data);
		let ret = { ok: false };
		if (states[data[0]]) {
			ret.data = states[data[0]](connection, data, cli) || {};
			ret.ok = true;
		}
		send(connection, [ 'result', id, ret ]);
	},

	user: function(connection, data, cli) {
		if (length(data) < 2)
			return;
		let id = shift(data);
		let cmd = shift(data);
		let ret = { ok: false };
		if (user[cmd]) {
			ret.data = user[cmd](connection, data, cli);
			ret.ok = !!ret.data;
		}
		send(connection, [ 'result', id, ret ]);
	},

	'setup-wizard': function(connection, data, cli) {
		ulog(LOG_INFO, `${data[0]} completed setup wizard\n`);
		
		generate(connection, data[0]);
		if (data[0].mode == 'managed')
			return;

		global.settings.configured = true;
		global.settings.mode = data[0].mode;
		global.settings.type = data[0].type;
		writefile('/etc/uconfig/webui/webui.json', global.settings);
		cli.call([ 'reset' ]);
		
		connection.data().authenticated = true;
		send_authenticated(connection, 'setup-complete');
	},

	'firmware-check': function(connection, data) {
		if (!length(data))
			return;
		let id = shift(data); 

		let ret = { ok: true, data: {}};
		if (!system('/usr/sbin/uconfig-upgrade check'))
			ret.data = json(readfile('/tmp/upgrade.json'));
		send(connection, [ 'result', id, ret ]);
	},

	'firmware-download': function(connection, data) {
		if (!length(data))
			return;
		let id = shift(data); 

		let ret = { ok: true, data: { confirmed: false }};
		if (!system('/usr/sbin/uconfig-upgrade download'))
			ret.data.confirmed = true;
		send(connection, [ 'result', id, ret ]);
	},
	
	unet: function(connection, data) {
		if (!length(data))
			return;
		let id = shift(data); 

		let ret = unet.handler(connection, data);
		send(connection, [ 'result', id, ret ]);
	},

	service: function(connection, data, cli) {
		if (length(data) < 3)
			return;
		let id = shift(data);
		let ret = {
			ok: false,
		};
		switch(data[0]) {
		case 'check':
			let service = ubus.call('service', 'list', { name: data[1] });
			ret.ok = true;
			ret.data = !!length(service);
			break;
		}
		send(connection, [ 'result', id, ret ]);
	},
};

export function onData(connection, data, final)
{
	if (global.shutdown)
		return connection.close(1012, 'Server is restarting');

	let ctx = connection.data();

	if (!ctx)
		return connection.close(1009, 'Message too big');

	if (length(ctx.msg) + length(data) > 32 * 1024)
		return connection.close(1009, 'Message too big');

	ctx.msg = ctx.n_fragments ? ctx.msg + data : data;
	if (final) {
		ctx.n_messages++;
		ctx.n_fragments = 0;
	} else {
		ctx.n_fragments++;
		return;
	}

	try {
		let msg = json(data);
		if (msg) {
			warn(`${connection.info().peer_address}: RX ${msg}\n`);

			let handler = shift(msg);
			if (!global.settings.configured) {
				if (handler != 'setup-wizard') {
					return send_setup_required(connection);
				}
			} else if (!connection.data().authenticated) {
				if (handler != 'authenticate') {
					return send(connection, [ 'login-required' ]);
				}
			}

			if (handlers[handler])
				handlers[handler](connection, msg, connection.data().cli)
		}

	} catch(e) {
		warn(`${e.stacktrace[0].context}\n`);
		return;
	}
};

export function onRequest(request, method, uri) {
//	return upload.onRequest(request, method, uri);
};

export function onBody(request, data) {
//	return upload.onBody(request, data);
};
