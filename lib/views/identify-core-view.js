'use babel';

import { DialogView } from 'particle-dev-views';
import { packageName } from '../utils/package-helper';

export default class IdentifyCoreView extends DialogView {
	constructor(coreID) {
		super({
			prompt: 'Your device ID is:',
			initialText: coreID,
			select: true,
			iconClass: '',
			hideOnBlur: false
		});

		this.claimPromise = null;
		this.prop('id', 'identify-core-view');
		this.addClass(packageName());
	}
}
