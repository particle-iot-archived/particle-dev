'use babel';

import { packageName } from './package-helper';

export default function(profileManager) {
	// Get root menu
	return {
		getMenu() {
			const devMenu = atom.menu.template.filter(value => value.label === 'Particle');

			return devMenu[0];
		},

		// Update menu
		update() {
			const devMenu = this.getMenu();

			if (profileManager.isLoggedIn) {
				// Menu items for logged in user
				const username = profileManager.get('username');

				devMenu.submenu = [{
					label: `Log out ${username}`,
					command: `${packageName()}:logout`
				},{
					type: 'separator'
				},{
					label: 'Select device...',
					command: `${packageName()}:select-device`
				}];

				if (profileManager.hasCurrentDevice) {
					let currentCoreName = profileManager.currentDevice.name;
					if (!currentCoreName) {
						currentCoreName = 'Unnamed';
					}
					// Menu items depending on current core
					devMenu.submenu = devMenu.submenu.concat([{
						label: `Rename ${currentCoreName}...`,
						command: `${packageName()}:rename-device`
					},{
						label: `Remove ${currentCoreName}...`,
						command: `${packageName()}:remove-device`
					},{
						label: `Flash ${currentCoreName} via the cloud`,
						command: `${packageName()}:flash-cloud`
					}]);
				}

				devMenu.submenu = devMenu.submenu.concat([{
					type: 'separator'
				},{
					label: 'Claim device...',
					command: `${packageName()}:claim-device`
				},{
					label: 'Identify device...',
					command: `${packageName()}:identify-device`
				},{
					//   label: "Setup device's WiFi...",
					//   command: "#{packageName()}:setup-wifi"
					// },{
					//   label: 'Flash device via USB',
					//   command: "#{packageName()}:try-flash-usb"
					// },{
					type: 'separator'
				},{
					label: 'Compile in the cloud',
					command: `${packageName()}:compile-cloud`
				}]);
			} else {
				// Logged out user can only log in
				devMenu.submenu = [{
					label: 'Log in to Particle Cloud...',
					command: `${packageName()}:login`
				}];
			}

			devMenu.submenu = devMenu.submenu.concat([{
				type: 'separator'
			},{
				label: 'Show serial monitor',
				command: `${packageName()}:show-serial-monitor`
			}]);

			// Refresh UI
			atom.menu.update();

			this.workspaceElement = atom.views.getView(atom.workspace);
			return atom.commands.dispatch(this.workspaceElement, `${packageName()}:append-menu`);
		},

		append(items) {
			const devMenu = this.getMenu();
			devMenu.submenu = devMenu.submenu.concat(items);
			return atom.menu.update();
		}
	};
}
