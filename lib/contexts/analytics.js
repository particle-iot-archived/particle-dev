'use babel';

import { analytics } from 'particle-commands';

/**
 * Creates the context object for command execution.
 */

function commandContext(settings, apiClient, pkg = require('../../package.json')) {
	const tool = { name: 'dev', version: pkg.version };
	const api = { key: 'DQN7XEETeBoQSFbPTlkOE8X01vyDeSRT' }; //settings.get('trackingApiKey') };
	const trackingIdentity = settings.fetchUpdate('trackingIdentity');
	return analytics.buildContext({ tool, api, trackingIdentity, apiClient });
}


export {
	commandContext
};
