import { glob } from 'fs';


export function installed_modules() {
	return map(glob('/etc/uconfig/modules/*'), (x) => split(x, '/')[4]);
};
