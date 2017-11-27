'use babel';

import { SelectView } from 'particle-dev-views';
import { packageName } from '../utils/package-helper';

let $$ = null;
const path = null;

export default class CompileErrorsView extends SelectView {
	initialize() {
		super.initialize(...arguments);

		({ $$ } = require('atom-space-pen-views'));

		this.prop('id', 'compile-errors-view');
		this.main = null;
		this.addClass(packageName());
	}

	fixFilePath(filename) {
		const splitFilename = filename.split(path.sep);
		return path.join.apply(this, splitFilename.slice(2));
	}

	show() {
		const compileStatus = this.main.profileManager.getLocal('compile-status');
		if ((compileStatus != null ? compileStatus.errors : undefined)) {
			this.setItems(compileStatus.errors);
		} else {
			this.setLoading('There were no compile errors');
		}
		return super.show(...arguments);
	}

	viewForItem(item) {
		return $$(function render() {
			this.li({ class: 'two-lines' }, () => {
				this.div({ class: 'primary-line' }, item.text);
				this.div({ class: 'secondary-line' }, `${item.filename}:${item.line}:${item.column}`);
			});
		});
	}

	confirmed(item) {
		const { filename } = item;

		// Open file with error in editor
		const opening = atom.workspace.open(filename, { searchAllPanes: true });
		opening.done(editor => editor.setCursorBufferPosition([item.line-1, item.column-1]));
		return this.hide();
	}

	getFilterKey() {
		return 'message';
	}
}
