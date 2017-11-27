'use babel';

let cachedPackageName = undefined;

export function packageName() {
	return cachedPackageName = cachedPackageName || fetchPackageName('../../package.json', 'particle-dev');
}

export function fetchPackageName(module, defaultName) {
	try {
		const pjson = require(module);
		return pjson.name;
	} catch (error) {
		return defaultName;
	}
}
