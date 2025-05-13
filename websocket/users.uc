import { readfile, writefile } from 'fs';

let users;

export function load() {
	users = json(readfile('/etc/uconfig/users') || '{}') || {};
};

export function commit() {
	writefile('/etc/uconfig/users', users);
};

export function list() {
	return users;	
};

export function set_password(data) {
	if (length(data) != 3)
		return false;
	let user = users[data[0]]?.[data[1]];
	if (!user)
		return false;

	user.key = data[2];

	return {};
};

load();
