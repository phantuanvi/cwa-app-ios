////
// 🦠 Corona-Warn-App
//

@testable import ENA
import Foundation
import XCTest

final class HTTPClientDccRegisterPublicKeyTests: CWATestCase {
	
	func testGIVEN_ErrorLog_WHEN_DCCRegisterPublicKey_THEN_HappyCase_VoidIsReturned() throws {
		// GIVEN
		let stack = MockNetworkStack(
			httpStatus: 201,
			responseData: Data()
		)

		let expectation = self.expectation(description: "completion handler is called without an error")

		// WHEN
		var resultSuccess: Bool = false
		HTTPClient.makeWith(mock: stack).dccRegisterPublicKey(token: "myToken", publicKey: Data()) { result in
			switch result {
			case .success():
				resultSuccess = true
			case let .failure(error):
				XCTFail("Test should not fail. Error: \(error.localizedDescription)")
			}
			expectation.fulfill()
		}

		// THEN
		waitForExpectations(timeout: .short)
		XCTAssertTrue(resultSuccess)
	}

	func testGIVEN_ErrorLog_WHEN_DCCRegisterPublicKey_THEN_badRequest_ErrorIsReturned() throws {
		// GIVEN
		let stack = MockNetworkStack(
			httpStatus: 400,
			responseData: Data()
		)

		let expectation = self.expectation(description: "completion handler is called without an error")

		// WHEN
		var resultError: DCCErrors.RegistrationError?
		HTTPClient.makeWith(mock: stack).dccRegisterPublicKey(token: "myToken", publicKey: Data()) { result in
			switch result {
			case .success():
				XCTFail("Test should not succeed")
			case let .failure(error):
				resultError = error
			}
			expectation.fulfill()
		}

		// THEN
		waitForExpectations(timeout: .short)
		let realError = try XCTUnwrap(resultError)
		XCTAssertEqual(realError, .badRequest)
	}

}
