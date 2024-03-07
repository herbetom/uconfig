import { readfile, popen } from 'fs';
import { ubus } from 'libubus';

let l3_devices;

function add_mac(stations, mac) {
	stations[mac] ??= {
		mac,
	};
}

function icon(name, value) {
	switch (lc(name)) {
	case 'tv':
	case 'printer':
	case 'laptop':
	case 'speaker':
	case 'apple':
	case 'microsoft':
		return lc(name);
	case 'gaming':
		return 'controller';
	case 'google':
		return 'android';
	}
	return value;
}

function network_interfaces() {
	let ifaces = ubus.call('network.interface', 'dump');
	l3_devices = {};

	for (let iface in ifaces.interface) {
		if (iface.interface in ['main', 'guest', 'uplink'])
			l3_devices[iface.l3_device] = iface.interface;
	}
}

function arp(stations) {
	let pipe = popen('ip neigh');
	let neigh = pipe.read("all");
	pipe.close();

	let lines = split(neigh, '\n');

	for (let line in lines) {
		let values = split(line, ' ');
		if (length(values) < 6)
			continue;

		let mac = uc(values[4]);
		add_mac(stations, mac);

		if (l3_devices[values[2]])
			stations[mac].network = l3_devices[values[2]];

		if (length(values[0]) < 16) {
			stations[mac].ipv4 ??= values[0];
		} else {
			stations[mac].ipv6 ??= [];
			push(stations[mac].ipv6, values[0]);
		}
	}
}

function assoc_list(stations) {
	let status = ubus.call('network.wireless', 'status');

	for (let phy, radio in status) {
		for (let iface in radio.interfaces) {
			if (iface.config.mode != 'ap')
				continue;

			let clients = ubus.call(`hostapd.${iface.ifname}`, 'get_clients');
			for (let mac, client in clients.clients) {
				mac = uc(mac);
				add_mac(stations, mac);
				stations[mac].network = iface.config.network[0];;
				stations[mac].wifi = {
					band: radio.config.band,
					ssid: iface.config.ssid,
					tx_bytes: client.bytes.tx,
					rx_bytes: client.bytes.rx,
					signal: client.signal,
				};
			}
		}
	}
}

function fingerprint(stations) {
	for (let mac, fingerprint in ubus.call('fingerprint', 'fingerprint')) {
		mac = uc(mac);
		add_mac(stations, mac);
		stations[mac].fingerprint = fingerprint;
		if (fingerprint.device_name || fingerprint.device)
			stations[mac].hostname = fingerprint.device_name || fingerprint.device;
	}
}

function dhcp_leases(stations, cli) {
	let static = {
		lan: cli.call(['edit', 'interface', 'main', 'ipv4', 'list', 'dhcp-lease']).data,
		guest: cli.call(['edit', 'interface', 'guest', 'ipv4', 'list', 'dhcp-lease']).data,
	};

	let leases = readfile('/tmp/dhcp.leases');
	let lines = split(leases, '\n');

	for (let line in lines) {
		let values = split(line, ' ');
		if (length(values) != 5)
			continue;
		
		let mac = uc(values[1]);

		add_mac(stations, mac);
		stations[mac].ipv4 = values[2];
		stations[mac].dhcp = (mac in static[stations[mac].network]) ? 'static' : 'dynamic';
		if (values[3] != '*')
			stations[mac].hostname ??= values[3];
	}
}

export function devices(cli) {
	let stations = {};

	network_interfaces();
	arp(stations);

	assoc_list(stations);
	fingerprint(stations);
	dhcp_leases(stations, cli);

	for (let mac, station in stations) {
		station.class_icon = icon(station.fingerprint?.class, 'pc-display-horizontal');
		if (!station.fingerprint)
			continue;
          	if (station.fingerprint.vendor)
			station.vendor_icon = icon(station.fingerprint.vendor, false);
	}

	let ret = {};

	for (let mac, station in stations) {
		if (!station?.network)
			continue;
		ret[station.network] ??= {};
		ret[station.network][mac] = station;	
		if (station.mac)
			delete station.mac;
		if (station.network)
			delete station.network;
	}

	return ret;
};
