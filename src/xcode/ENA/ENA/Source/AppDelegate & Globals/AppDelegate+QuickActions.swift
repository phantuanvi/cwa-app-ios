////
// 🦠 Corona-Warn-App
//

import UIKit

// MARK: - Quick Actions

extension AppDelegate {

	private static let shortcutIdDiaryNewEntry = "de.rki.coronawarnapp.shortcut.diarynewentry"

	func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
		Log.debug("\(#function)", log: .default)
		handleShortcutItem(shortcutItem)
	}

	func handleQuickActions(with launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
			Log.debug("\(#function)", log: .default)
			handleShortcutItem(shortcutItem)
			return false // TODO: review
		}
		return true
	}

	
	func setupQuickActions() {
		guard store.isOnboarded else { return }
		
		let application = UIApplication.shared
		application.shortcutItems = [
			UIApplicationShortcutItem(type: AppDelegate.shortcutIdDiaryNewEntry, localizedTitle: AppStrings.QuickActions.contactDiaryNewEntry, localizedSubtitle: nil, icon: UIApplicationShortcutIcon(templateImageName: "book.closed"))
		]
	}

	func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
		Log.debug("Did open app via shortcut \(shortcutItem.type)", log: .ui)
		if shortcutItem.type == AppDelegate.shortcutIdDiaryNewEntry {
			Log.info("Shortcut: Open new diary entry", log: .ui)
			guard let tabBarController = coordinator.tabBarController else { return }
			tabBarController.selectedIndex = 1
		}
	}
}

extension RootCoordinator {

	/// Direct access to the tabbar controller
	var tabBarController: UITabBarController? {
		viewController.children.compactMap({ $0 as? UITabBarController }).first
	}
}
