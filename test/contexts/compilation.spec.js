import {expect} from 'chai';
import path from 'path';

let compilationContext = require('../../lib/contexts/compilation')

describe('Compilation context', () => {
	let files = [
		'foo.ino',
		'../src/bar.cpp',
		'../src/bar.h'
	];
	let root = path.resolve(path.join(__dirname, '..', 'data', 'libraryexample', 'examples'));

	describe('mapCommonPrefix', () => {
		it('prefixes the files', () => {
			let result = compilationContext.mapCommonPrefix(files, root);
			expect(result).to.eql({
				'examples/foo.ino': 'foo.ino',
				'src/bar.cpp': '../src/bar.cpp',
				'src/bar.h': '../src/bar.h'
			});
		});
	});

	describe('mapKeys', () => {
		it('maps the source using mapper', () => {
			const input = {
				foo: 'bar'
			};
			let result = compilationContext.mapKeys(input, (k, v) => k.toUpperCase());
			expect(result).to.eql({FOO: 'bar'});
		});
	});

	describe('makeAbsolute', () => {
		it('prefixes filename', () => {
			expect(compilationContext.makeAbsolute('foo')).to.equal('/foo');
		});
	});
});
