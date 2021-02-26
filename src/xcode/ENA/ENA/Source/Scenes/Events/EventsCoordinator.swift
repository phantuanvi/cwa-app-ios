////
// 🦠 Corona-Warn-App
//

import Foundation
import UIKit

final class EventsCoordinator {

	// MARK: - Init

	init() {

	}

	// MARK: - Overrides

	// MARK: - Protocol <#Name#>

	// MARK: - Public

	// MARK: - Internal

	lazy var viewController: UINavigationController = {
		let eventsListViewController = UITableViewController()
		return UINavigationController(rootViewController: eventsListViewController)
	}()

	// MARK: - Private

}
