'use babel';

let libraryManager;

/**
 * Map local filenames to virtual paths sent to the server
 *
 * @param  {Array} files    Input files
 * @param  {path} rootPath Root path for the project
 * @return {array}          Array containing mapped files and the mapping object
 */
export function mapLocalToServerFilenames(files, rootPath) {
	let filenameMap = Array.isArray(files) ? mapCommonPrefix(files, rootPath) : files;
	filenameMap = mapKeys(filenameMap, makeAbsolute);
	files = Object.keys(filenameMap).map((key) => filenameMap[key]);
	return [files, filenameMap];
}

/**
 * @param  {array} files                   Input files
 * @param  {string} basePath Base path to be used as root
 * @return {object}                         Mapped paths
 */
export function mapCommonPrefix(files, basePath=process.cwd()) {
	let relative = [];

	libraryManager = !libraryManager ? require('particle-library-manager') : libraryManager;
	libraryManager.pathsCommonPrefix(files, relative, basePath);

	let map = {}
	for (var i = 0; i < files.length; i++) {
		map[relative[i]] = files[i];
	}
	return map;
}

/**
 * Map object keys using provided mapper callback
 *
 * @param  {object} source Object to be mapped
 * @param  {function} mapper Mapper callback
 * @return {object}        Mapped object
 */
export function mapKeys(source, mapper) {
	let result = {};

	for (let k of Object.keys(source)) {
		let v = source[k];
		mapped = mapper(k, v);
		result[mapped] = v;
	}
	return result;
}

/**
 * Prepend filename with slash and make it absolute path
 *
 * @param  {string} filename Filename to make absolute
 * @return {string}          Absolute filename
 */
export function makeAbsolute(filename) {
	let sep = '/';

	if (!filename.startsWith(sep)) {
		filename = sep + filename;
	}
	return filename;
}
