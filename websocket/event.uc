import { ubus } from 'libubus';

export function event(object, verb, payload) {
	ubus.call('event', 'event', { object, verb, payload });
};
