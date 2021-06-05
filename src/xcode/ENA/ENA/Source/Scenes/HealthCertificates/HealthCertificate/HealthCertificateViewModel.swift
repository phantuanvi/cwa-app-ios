////
// 🦠 Corona-Warn-App
//

import UIKit
import OpenCombine
import HealthCertificateToolkit

final class HealthCertificateViewModel {

	// MARK: - Init

	init(
		healthCertifiedPerson: HealthCertifiedPerson?,
		healthCertificate: HealthCertificateData,
		vaccinationValueSetsProvider: VaccinationValueSetsProvider
	) {
		self.healthCertificate = healthCertificate
		self.vaccinationValueSetsProvider = vaccinationValueSetsProvider
		self.qrCodeCellViewModel = HealthCertificateQRCodeCellViewModel(
			healthCertificate: healthCertificate,
			accessibilityText: String(
				format: AppStrings.HealthCertificate.Details.QRCodeImageDescription,
				healthCertificate.doseNumber, healthCertificate.totalSeriesOfDoses
			)
		)

		if case .test = healthCertificate.type {
			gradientType = .green
		} else {
			healthCertifiedPerson?.$vaccinationState
				.sink { [weak self] in
					self?.gradientType = $0.gradientType
				}
				.store(in: &subscriptions)
		}

		updateHealthCertificateKeyValueCellViewModels()

		// load certificate value sets
		vaccinationValueSetsProvider.latestVaccinationCertificateValueSets()
			.sink(
				receiveCompletion: { result in
					switch result {
					case .finished:
						break
					case .failure(let error):
						if case CachingHTTPClient.CacheError.dataVerificationError = error {
							Log.error("Signature verification error.", log: .vaccination, error: error)
						}
						Log.error("Could not fetch Vaccination value sets protobuf.", log: .vaccination, error: error)
					}
				}, receiveValue: { [weak self] valueSets in
					self?.valueSets = valueSets
					self?.updateHealthCertificateKeyValueCellViewModels()
				}
			)
			.store(in: &subscriptions)

	}

	// MARK: - Internal

	enum TableViewSection: Int, CaseIterable {
		case headline
		case qrCode
		case topCorner
		case details
		case bottomCorner

		static var numberOfSections: Int {
			allCases.count
		}

		static func map(_ section: Int) -> TableViewSection? {
			guard let section = TableViewSection(rawValue: section) else {
				Log.error("unknown TableViewSection", log: .vaccination)
				return nil
			}
			return section
		}
	}

	let qrCodeCellViewModel: HealthCertificateQRCodeCellViewModel

	@OpenCombine.Published private(set) var gradientType: GradientView.GradientType = .solidGrey
	@OpenCombine.Published private(set) var healthCertificateKeyValueCellViewModel: [HealthCertificateKeyValueCellViewModel] = []

	var headlineCellViewModel: HealthCertificateSimpleTextCellViewModel {
		let centerParagraphStyle = NSMutableParagraphStyle()
		centerParagraphStyle.alignment = .center
		centerParagraphStyle.lineSpacing = 10.0

		let title: String
		let subtitle: String
		switch healthCertificate.type {
		case .vaccination:
			title = String(format: AppStrings.HealthCertificate.Details.vaccinationCount, healthCertificate.doseNumber, healthCertificate.totalSeriesOfDoses)
			subtitle = AppStrings.HealthCertificate.Details.certificate
		case .test:
			title = AppStrings.HealthCertificate.Details.TestCertificate.title
			subtitle = AppStrings.HealthCertificate.Details.TestCertificate.subtitle
		}

		let attributedTitle = NSAttributedString(
			string: title,
			attributes: [
				.font: UIFont.enaFont(for: .headline),
				.foregroundColor: UIColor.enaColor(for: .textContrast),
				.paragraphStyle: centerParagraphStyle
			]
		)

		let attributedSubtitle = NSAttributedString(
			string: subtitle,
			attributes: [
				.font: UIFont.enaFont(for: .body),
				.foregroundColor: UIColor.enaColor(for: .textContrast),
				.paragraphStyle: centerParagraphStyle
			]
		)

		return HealthCertificateSimpleTextCellViewModel(
			backgroundColor: .clear,
			textAlignment: .center,
			attributedText: [attributedTitle, attributedSubtitle]
				.joined(with: "\n"),
			topSpace: 18.0,
			font: .enaFont(for: .headline),
			accessibilityTraits: .staticText,
			accessibilityIdentifier: AccessibilityIdentifiers.HealthCertificate.Certificate.headline
		)
	}

	func numberOfItems(in section: TableViewSection) -> Int {
		switch section {
		case .headline:
			return 1
		case .qrCode:
			return 1
		case .details:
			return healthCertificateKeyValueCellViewModel.count
		case .topCorner, .bottomCorner:
			return healthCertificateKeyValueCellViewModel.isEmpty ? 0 : 1
		}
	}

	// MARK: - Private

	private enum ValueSetType: String {
		case vaccineOrProphylaxis
		case vaccineMedicinalProduct
		case marketingAuthorizationHolder
		case diseaseOrAgentTargeted
		case typeOfTest
		case testResult
	}

	private let healthCertificate: HealthCertificateData
	private let vaccinationValueSetsProvider: VaccinationValueSetsProvider

	private var valueSets: SAP_Internal_Dgc_ValueSets?
	private var subscriptions = Set<AnyCancellable>()

	private func updateHealthCertificateKeyValueCellViewModels() {
		switch healthCertificate.type {
		case .vaccination(let vaccinationEntry):
			updateVaccinationCertificateKeyValueCellViewModels(vaccinationEntry: vaccinationEntry)
		case .test(let testEntry):
			updateTestCertificateKeyValueCellViewModels(testEntry: testEntry)
		}
	}

	private func updateVaccinationCertificateKeyValueCellViewModels(vaccinationEntry: VaccinationEntry) {
		// person cell - always visible
		var dateOfBirth: String = ""
		if let date = healthCertificate.dateOfBirthDate {
			dateOfBirth = DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
		}
		let nameCellViewModel = HealthCertificateKeyValueCellViewModel(
			key: healthCertificate.name.fullName,
			value: String(format: AppStrings.HealthCertificate.Details.dateOfBirth, dateOfBirth),
			topSpace: 2.0
		)

		// all vaccinationCertificate cell data - optional values
		var dateCellViewModel: HealthCertificateKeyValueCellViewModel?
		if	let date = healthCertificate.dateOfVaccination {
			dateCellViewModel = HealthCertificateKeyValueCellViewModel(
				key: AppStrings.HealthCertificate.Details.dateOfVaccination,
				value: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
			)
		}

		let vaccineCellViewModel = HealthCertificateKeyValueCellViewModel(
			key: AppStrings.HealthCertificate.Details.vaccine,
			value: determineValue(
				key: vaccinationEntry.vaccineMedicinalProduct,
				valueSet: valueSet(by: .vaccineMedicinalProduct)
			)
		)

		let manufacturerCellViewModel = HealthCertificateKeyValueCellViewModel(
			key: AppStrings.HealthCertificate.Details.manufacture,
			value: determineValue(
				key: vaccinationEntry.marketingAuthorizationHolder,
				valueSet: valueSet(by: .marketingAuthorizationHolder)
			)
		)

		let vaccineTypeCellViewModel = HealthCertificateKeyValueCellViewModel(
			key: AppStrings.HealthCertificate.Details.vaccineType,
			value: determineValue(
				key: vaccinationEntry.vaccineOrProphylaxis,
				valueSet: valueSet(by: .vaccineOrProphylaxis)
			)
		)

		let issuerCellViewModel = HealthCertificateKeyValueCellViewModel(
			key: AppStrings.HealthCertificate.Details.issuer,
			value: vaccinationEntry.certificateIssuer
		)

		let localizedCountryName = Country(countryCode: vaccinationEntry.countryOfVaccination)?.localizedName
		let countryCellViewModel = HealthCertificateKeyValueCellViewModel(
			key: AppStrings.HealthCertificate.Details.country,
			value: localizedCountryName ?? vaccinationEntry.countryOfVaccination
		)

		let certificateNumberCellViewModel = HealthCertificateKeyValueCellViewModel(
			key: AppStrings.HealthCertificate.Details.identifier,
			value: vaccinationEntry.uniqueCertificateIdentifier,
			isBottomSeparatorHidden: true,
			bottomSpace: 2.0
		)

		healthCertificateKeyValueCellViewModel = [
			nameCellViewModel,
			dateCellViewModel,
			vaccineCellViewModel,
			manufacturerCellViewModel,
			vaccineTypeCellViewModel,
			issuerCellViewModel,
			countryCellViewModel,
			certificateNumberCellViewModel
		]
		.compactMap { $0 }
	}

	private func updateTestCertificateKeyValueCellViewModels(testEntry: TestEntry) {
		let nameCellViewModel = HealthCertificateKeyValueCellViewModel(
			key: "Name, Vorname / Name, First Name",
			value: healthCertificate.name.fullName,
			topSpace: 2.0
		)

		var dateOfBirthCellViewModel: HealthCertificateKeyValueCellViewModel?
		if let dateOfBirthDate = healthCertificate.dateOfBirthDate {
			dateOfBirthCellViewModel = HealthCertificateKeyValueCellViewModel(
				key: "Geburtsdatum / Date of Birth",
				value: DateFormatter.localizedString(from: dateOfBirthDate, dateStyle: .medium, timeStyle: .none)
			)
		}

		let diseaseOrAgentTargetedCellViewModel = HealthCertificateKeyValueCellViewModel(
			key: "Zielkrankheit oder. -erreger / Disease or Agent Targeted",
			value: determineValue(
				key: testEntry.diseaseOrAgentTargeted,
				valueSet: valueSet(by: .diseaseOrAgentTargeted)
			)
		)

		let typeOfTestCellViewModel = HealthCertificateKeyValueCellViewModel(
			key: "Art des Tests / Type of Test",
			value: determineValue(
				key: testEntry.typeOfTest,
				valueSet: valueSet(by: .typeOfTest)
			)
		)

		var naaTestNameCellViewModel: HealthCertificateKeyValueCellViewModel?
		if let naaTestName = testEntry.naaTestName {
			naaTestNameCellViewModel = HealthCertificateKeyValueCellViewModel(
				key: "Produktname / Test Name",
				value: naaTestName
			)
		}

		var ratTestNameCellViewModel: HealthCertificateKeyValueCellViewModel?
		if let ratTestName = testEntry.ratTestName {
			ratTestNameCellViewModel = HealthCertificateKeyValueCellViewModel(
				key: "Testhersteller / Test Manufacturer",
				value: determineValue(
					key: ratTestName,
					valueSet: valueSet(by: .marketingAuthorizationHolder)
				)
			)
		}

		var dateTimeOfSampleCollectionCellViewModel: HealthCertificateKeyValueCellViewModel?
		if let dateTimeOfSampleCollectionDate = ISO8601DateFormatter().date(from: testEntry.dateTimeOfSampleCollection) {
			dateTimeOfSampleCollectionCellViewModel = HealthCertificateKeyValueCellViewModel(
				key: "Datum und Uhrzeit der Probenahme / Date and Time of Sample Collection",
				value: DateFormatter.localizedString(from: dateTimeOfSampleCollectionDate, dateStyle: .medium, timeStyle: .short)
			)
		}

		let testResultCellViewModel = HealthCertificateKeyValueCellViewModel(
			key: "Testergebnis / Test Result",
			value: determineValue(
				key: testEntry.testResult,
				valueSet: valueSet(by: .testResult)
			)
		)

		let testCenterCellViewModel = HealthCertificateKeyValueCellViewModel(
			key: "Testzentrum oder -einrichtung / Testing Center or Facility",
			value: testEntry.testCenter
		)

		let localizedCountryName = Country(countryCode: testEntry.countryOfTest)?.localizedName
		let countryCellViewModel = HealthCertificateKeyValueCellViewModel(
			key: "Land der Testung / Member State of Test",
			value: localizedCountryName ?? testEntry.countryOfTest
		)

		let issuerCellViewModel = HealthCertificateKeyValueCellViewModel(
			key: "Zertifikataussteller / Certificate Issuer",
			value: testEntry.certificateIssuer
		)

		let certificateNumberCellViewModel = HealthCertificateKeyValueCellViewModel(
			key: "Zertifikatkennung / Unique Certificate Identifier",
			value: testEntry.uniqueCertificateIdentifier,
			isBottomSeparatorHidden: true,
			bottomSpace: 2.0
		)

		healthCertificateKeyValueCellViewModel = [
			nameCellViewModel,
			dateOfBirthCellViewModel,
			diseaseOrAgentTargetedCellViewModel,
			typeOfTestCellViewModel,
			naaTestNameCellViewModel,
			ratTestNameCellViewModel,
			dateTimeOfSampleCollectionCellViewModel,
			testResultCellViewModel,
			testCenterCellViewModel,
			countryCellViewModel,
			issuerCellViewModel,
			certificateNumberCellViewModel
		]
		.compactMap { $0 }
	}

	private func valueSet(by type: ValueSetType) -> SAP_Internal_Dgc_ValueSet? {
		guard let valueSets = valueSets else {
			Log.error("tried to read from unavailable value sets", log: .vaccination)
			return nil
		}
		switch type {
		case .vaccineOrProphylaxis:
			return valueSets.hasVp ? valueSets.vp : nil
		case .vaccineMedicinalProduct:
			return valueSets.hasMp ? valueSets.mp : nil
		case .marketingAuthorizationHolder:
			return valueSets.hasMa ? valueSets.ma : nil
		case .diseaseOrAgentTargeted:
			return valueSets.hasTg ? valueSets.tg : nil
		case .typeOfTest:
			return valueSets.hasTcTt ? valueSets.tcTt : nil
		case .testResult:
			return valueSets.hasTcTr ? valueSets.tcTr : nil
		}
	}

	private func determineValue(key: String, valueSet: SAP_Internal_Dgc_ValueSet?) -> String {
		let displayText = valueSet?.items
			.first { $0.key == key }
			.map { $0.displayText }

		return displayText ?? key
	}

}
