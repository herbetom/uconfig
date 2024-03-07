import { stat } from 'fs';

//cli unet edit unet : password password 1234567890ab new-password 1234567890aa : apply

let cli;

function open_cli() {
	if (cli)
		return;
	cli = global.model.context();
	cli = cli.select([ 'unet' ]);
}

function create_network(connection) {
	if (stat('/etc/uconfig/data/unetd.json'))
		return;
	let passwd = connection.data().unet;
	cli.call([ 'create', 'password', passwd ]);
}

function onboard(connection, data) {
	if (length(data) < 2)
		return;
		create_network();
	cli.call([ 'edit',  'unet', ':', 'invite', data[0], 'access-key', data[1], 'timeout', '60', 'password', connection.data().unet ]);
	return {};
}

export function handler(connection, data) {
	open_cli();
	create_network(connection);

	let cmd = shift(data);
	switch(cmd) {
	case 'onboard':
		return onboard(connection, data);
	}
};
