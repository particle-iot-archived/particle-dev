'use babel';

import { SelectView } from 'particle-dev-views';
import { packageName } from '../utils/package-helper';

let $$ = null;

export default class SelectBuildTargetView extends SelectView {
	initialize() {
		super.initialize(...arguments);

		({ $$ } = require('atom-space-pen-views'));

		this.prop('id', 'select-build-target-view');
		this.addClass(packageName());
		this.listBuildTargetsPromise = null;
		this.main = null;
		this.requestErrorHandler = null;
	}

	show(next=null) {
		this.setItems([]);
		this.next = next;
		this.setLoading('Loading build targets...');
		this.loadBuildTargets();
		return super.show(...arguments);
	}

	// Here you specify the view for an item
	viewForItem(item) {
		return $$(function render() {
			this.li(() => {
				this.div(() => {
					this.span(item.version);
					if (item.prerelease) {
						this.div({ class: 'pull-right' }, () => {
							this.span({ class: 'icon icon-alert status-modified', title: 'This is a pre-release' });
						});
					}
				});
			});
		});
	}

	confirmed(item) {
		this.main.setCurrentBuildTarget(item.version);
		this.hide();
		atom.commands.dispatch(this.workspaceElement, `${packageName()}:update-build-target`);
		if (this.next) {
			return this.next(item);
		}
	}

	getFilterKey() {
		return 'version';
	}

	loadBuildTargets() {
		this.listBuildTargetsPromise = this.main.getBuildTargets();
		return this.listBuildTargetsPromise.then(targets => {
			this.setItems(targets);
			this.listDevicesPromise = null;
		}
			, e => {
			this.listDevicesPromise = null;
			return this.requestErrorHandler(e);
		});
	}
}
