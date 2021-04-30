////
// 🦠 Corona-Warn-App
//

import Foundation
import OpenCombine
import HealthCertificateToolkit

class HealthCertificateService {

	// MARK: - Init

	init(
		store: HealthCertificateStoring,
		healthCertificateToolkit: HealthCertificateToolkit
	) {
		self.store = store
		self.healthCertificateToolkit = healthCertificateToolkit

		updatePublishersFromStore()
	}

	// MARK: - Internal

	@OpenCombine.Published var healthCertifiedPersons: [HealthCertifiedPerson] = [] {
		didSet {
			store.healthCertifiedPersons = healthCertifiedPersons

			updateSubscriptions()
		}
	}

	func register(payload: String) -> Result<HealthCertifiedPerson, RegistrationError> {
		Log.info("[HealthCertificateService] Registering health certificate from payload: \(private: payload)", log: .api)

		return .success((HealthCertifiedPerson(proofCertificate: nil, healthCertificates: [])))
	}

	func updateProofCertificate(
		for healthCertifiedPerson: HealthCertifiedPerson,
		completion: (Result<Void, ProofRequestError>) -> Void
	) {
		Log.info("[HealthCertificateService] Requesting proof for health certified person: \(private: healthCertifiedPerson)", log: .api)

		healthCertificateToolkit.fetchProofCertificate(
			for: healthCertifiedPerson.healthCertificates.map { $0.representations },
			completion: { [weak self] result in
				switch result {
				case .success(let proofCertificate):
					healthCertifiedPerson.proofCertificate = proofCertificate
					completion(.success(()))
				case .failure(let error):
					completion(.failure(error))
				}
			}
		)
	}

	func updatePublishersFromStore() {
		Log.info("[HealthCertificateService] Updating publishers from store", log: .api)

		healthCertifiedPersons = store.healthCertifiedPersons
	}

	// MARK: - Private

	private var store: HealthCertificateStoring
	private var healthCertificateToolkit: HealthCertificateToolkit
	private var subscriptions = Set<AnyCancellable>()

	private func updateSubscriptions() {
		subscriptions = []

		healthCertifiedPersons.forEach { healthCertifiedPerson in
			healthCertifiedPerson.objectWillChange
				.receive(on: DispatchQueue.main.ocombine)
				.sink { [weak self] in
					guard let self = self else { return }
					// Trigger publisher to inform subscribers and update store
					self.healthCertifiedPersons = self.healthCertifiedPersons
				}
				.store(in: &subscriptions)
		}
	}

}
