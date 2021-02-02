////
// 🦠 Corona-Warn-App
//
#if !RELEASE
import UIKit

class DMPPACViewController: UITableViewController {

	// MARK: - Init

	init( _ store: Store) {
		#if targetEnvironment(simulator)
		self.viewModel = DMPPCViewModel(store, deviceCheck: PPACDeviceCheckMock(true, deviceToken: "Simulator DeviceCheck unavailable"))
		#else
		self.viewModel = DMPPCViewModel(store, deviceCheck: PPACDeviceCheck())
		#endif

		if #available(iOS 13.0, *) {
			super.init(style: .insetGrouped)
		} else {
			super.init(style: .grouped)
		}
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Overrides

	override func viewDidLoad() {
		super.viewDidLoad()

		title = "PPAC Service 🏄‍♂️"
		setupTableView()
	}

	// MARK: - Protocol UITableViewDataSource

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cellViewModel = viewModel.cellViewModel(by: indexPath)
		if cellViewModel is DMKeyValueCellViewModel {
			let cell = tableView.dequeueReusableCell(cellType: DMKeyValueTableViewCell.self, for: indexPath)
			cell.configure(cellViewModel: cellViewModel)
			return cell
		} else {
			fatalError("unsopported cellViewModel - can't find a matching cell")
		}
	}

	override func numberOfSections(in tableView: UITableView) -> Int {
		viewModel.numberOfSections
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		viewModel.numberOfRows(in: section)
	}

	// MARK: - Public

	// MARK: - Internal

	// MARK: - Private

	private let viewModel: DMPPCViewModel

	private func setupTableView() {
		tableView.estimatedRowHeight = 45.0
		tableView.rowHeight = UITableView.automaticDimension

		tableView.register(DMKeyValueTableViewCell.self, forCellReuseIdentifier: DMKeyValueTableViewCell.reuseIdentifier)
	}

}
#endif
