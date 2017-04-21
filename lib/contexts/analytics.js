'use babel';
const pipeline = require('when/pipeline');
import pkg from '../../package.json';

/**
 * Creates the context object for command execution.
 */

/**
 * Retrieves the unique ID for the current logged in user.
 */
function trackingUser() {
	// todo - fetch from `v1/user` endpoint
	return Promise.resolve({id: 'dev-test-user'});
}

function commandContext() {
	// todo - allow the API key to be overridden in the environment so that CLI use during development/testing
	// is tracked against a distinct source
	return pipeline([
			trackingUser,
			(user) => {
			return {
				user,
				tool: { name: 'dev', version: pkg.version },
				api: { key: 'DQN7XEETeBoQSFbPTlkOE8X01vyDeSRT' }
			}
		}
	]);
}

export {
	commandContext
};
