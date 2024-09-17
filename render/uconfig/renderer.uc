"use strict";

global.topdir = sourcepath(0, true);

import * as fs from 'fs';
global.fs = fs;

import { uci } from 'uconfig.uci';
import { ubus } from 'uconfig.ubus';
import { capabilities } from 'uconfig.capabilities';
global.capabilities = capabilities;

import * as ethernet from 'uconfig.ethernet';
import * as routing_table from 'uconfig.routing_table';
import * as shell from 'uconfig.shell';
import * as wiphy from 'uconfig.wiphy';
import * as ipcalc from 'uconfig.ipcalc';

function b(val) {
	return val ? '1' : '0';
}

function s(str) {
	if (str === null || str === '')
		return '';

	return sprintf("'%s'", replace(str, /'/g, "'\\''"));
}

function tryinclude(path, scope) {
	if (!match(path, /^[A-Za-z0-9_\/-]+\.uc$/)) {
		warn("Refusing to handle invalid include path '%s'", path);
		return;
	}

	let parent_path = sourcepath(1, true);

	assert(parent_path, "Unable to determine calling template path");

	try {
		include(parent_path + "/" + path, scope);
	}
	catch (e) {
		warn("Unable to include path '%s': %s\n%s", path, e, e.stacktrace[0].context);
	}
}

let serial = uci.get("uconfig", "config", "serial");
let board = json(fs.readfile("/etc/board.json"));

export function generate(state, logs, scope) {
	logs = logs || [];

	ethernet.init();
	ipcalc.init();
	routing_table.init();

	return render('templates/toplevel.uc', {
		b,
		s,
		tryinclude,
		state,

		location: '/',
		serial,
		board,

		uci,
		ubus,
		ethernet,
		ipcalc,
		routing_table,
		shell,
		wiphy,
		
		...scope,

		warn: (fmt, ...args) => push(logs, sprintf("[W] (In %s) ", location || '/') + sprintf(fmt, ...args)),

		error: (fmt, ...args) => push(logs, sprintf("[E] (In %s) ", location || '/') + sprintf(fmt, ...args)),

		info: (fmt, ...args) => push(logs, sprintf("[!] (In %s) ", location || '/') + sprintf(fmt, ...args))
	});
};
