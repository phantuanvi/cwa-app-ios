////
// 🦠 Corona-Warn-App
//

import Foundation
import HealthCertificateToolkit

protocol HealthCertificateData {
	var base45: Base45 { get }
	var version: String { get }
	var name: HealthCertificateToolkit.Name { get }
	var dateOfBirth: String { get }
	var dateOfBirthDate: Date? { get }
	var vaccinationEntry: VaccinationEntry? { get }
	var testEntry: TestEntry? { get }
	var isLastDoseInASeries: Bool { get }
	var expirationDate: Date { get }
	var dateOfVaccination: Date? { get }
	var doseNumber: Int { get }
	var totalSeriesOfDoses: Int { get }
}

struct HealthCertificate: HealthCertificateData, Codable, Equatable, Comparable {

	// MARK: - Init

	init(base45: Base45) throws {
		// Ensure the data will be decodable on the fly later on, even though we don't store the decoded data
		if case .failure(let error) = DigitalGreenCertificateAccess().extractCBORWebTokenHeader(from: base45) {
			Log.error("Failed to decode header of health certificate with error", log: .vaccination, error: error)
			throw error
		}

		if case .failure(let error) = DigitalGreenCertificateAccess().extractDigitalGreenCertificate(from: base45) {
			Log.error("Failed to decode health certificate with error", log: .vaccination, error: error)
			throw error
		}

		self.base45 = base45
	}

	// MARK: - Protocol Comparable

	static func < (lhs: HealthCertificate, rhs: HealthCertificate) -> Bool {
		guard
			let lhsVaccinationDate = lhs.vaccinationEntry?.dateOfVaccination,
			let rhsVaccinationDate = rhs.vaccinationEntry?.dateOfVaccination
		else {
			return false
		}

		return lhsVaccinationDate < rhsVaccinationDate
	}

	// MARK: - Internal

	enum CertificateType {
		case vaccination
		case test
		case unsupported
	}

	let base45: Base45

	var version: String {
		digitalGreenCertificate.version
	}

	var name: HealthCertificateToolkit.Name {
		digitalGreenCertificate.name
	}

	var dateOfBirth: String {
		digitalGreenCertificate.dateOfBirth
	}

	var dateOfBirthDate: Date? {
		return ISO8601DateFormatter.justLocalDateFormatter.date(from: digitalGreenCertificate.dateOfBirth)
	}

	var vaccinationEntry: VaccinationEntry? {
		let vaccinationCertificates = digitalGreenCertificate.vaccinationEntries ?? []

		return vaccinationCertificates.first
	}

	var testEntry: TestEntry? {
		let testCertificates = digitalGreenCertificate.testEntries ?? []

		return testCertificates.first
	}

	var type: CertificateType {
		if vaccinationEntry != nil {
			return .vaccination
		} else if testEntry != nil {
			return .test
		} else {
			return .unsupported
		}
	}

	var isLastDoseInASeries: Bool {
		vaccinationEntry?.isLastDoseInASeries ?? false
	}

	var expirationDate: Date {
		#if DEBUG
		if isUITesting, let dateOfVaccination = dateOfVaccination {
			return Calendar.current.date(byAdding: .year, value: 1, to: dateOfVaccination) ?? Date(timeIntervalSince1970: TimeInterval(cborWebTokenHeader.expirationTime))
		}
		#endif

		return Date(timeIntervalSince1970: TimeInterval(cborWebTokenHeader.expirationTime))
	}

	var dateOfVaccination: Date? {
		guard let dateString = vaccinationEntry?.dateOfVaccination else {
			return nil
		}
		return ISO8601DateFormatter.justLocalDateFormatter.date(from: dateString)
	}

	var doseNumber: Int {
		return vaccinationEntry?.doseNumber ?? 0
	}
	
	var totalSeriesOfDoses: Int {
		return vaccinationEntry?.totalSeriesOfDoses ?? 0
	}

	// MARK: - Private

	private var cborWebTokenHeader: CBORWebTokenHeader {
		let result = DigitalGreenCertificateAccess().extractCBORWebTokenHeader(from: base45)

		switch result {
		case .success(let cborWebTokenHeader):
			return cborWebTokenHeader
		case .failure(let error):
			Log.error("Failed to decode header of health certificate with error", log: .vaccination, error: error)
			fatalError("Decoding the cborWebTokenHeader failed even though decodability was checked at initialization.")
		}
	}

	private var digitalGreenCertificate: DigitalGreenCertificate {
		let result = DigitalGreenCertificateAccess().extractDigitalGreenCertificate(from: base45)

		switch result {
		case .success(let digitalGreenCertificate):
			return digitalGreenCertificate
		case .failure(let error):
			Log.error("Failed to decode health certificate with error", log: .vaccination, error: error)
			fatalError("Decoding the digitalGreenCertificate failed even though decodability was checked at initialization.")
		}
	}
}
