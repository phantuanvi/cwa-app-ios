////
// 🦠 Corona-Warn-App
//

import XCTest
import Base32

class Base32DecodingTests: XCTestCase {

    func testBase32DecodingSampleDataNoPadding() throws {
		for sample in sampleDataNoPadding {
			base32DecodeAndVerify(data: sample)
		}
    }
	func testBase32DecodingSampleDataWithPadding() throws {
		for sample in sampleDataWithPadding {
			base32DecodeAndVerify(data: sample)
		}
	}
	
	private func base32DecodeAndVerify(data: Dictionary<String, String>.Element) {
		let encodedString = data.key
		let decodedString = encodedString.base32DecodedString()
		let targetString = data.value
		XCTAssertEqual(decodedString, targetString)
	}

	private let sampleDataNoPadding: [String: String] = [
		"ORUGKIDROVUWG2ZAMJZG653OEBTG66BANJ2W24DTEBXXMZLSEB2GQZJANRQXU6JAMRXWO": "the quick brown fox jumps over the lazy dog",
		"KREEKICRKVEUGSZAIJJE6V2OEBDE6WBAJJKU2UCTEBHVMRKSEBKEQRJAJRAVUWJAIRHUO": "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG",
		"MRUWKIDIMVU4HH3FEB5HS4DFOJXHG33ONZSSA4LVYOSGY5DFEBWWC6BAOVXGIIDWNFRXI33SNFQSA2TBEBRMHNTTMUQGC5LGEBSGK3JAO5SWOIDCNFZSA6TVOIQGXQ54ON2GKLQ": "die heiße zypernsonne quälte max und victoria ja böse auf dem weg bis zur küste.",
		"IREUKICIIVEVGU2FEBNFSUCFKJHFGT2OJZCSAUKVYOCEYVCFEBGUCWBAKVHEIICWJFBVIT2SJFASASSBEBBMHFSTIUQECVKGEBCEKTJAK5CUOICCJFJSAWSVKIQEXQ44KNKEKLQ": "DIE HEISSE ZYPERNSONNE QUÄLTE MAX UND VICTORIA JA BÖSE AUF DEM WEG BIS ZUR KÜSTE.",
		"JBSWY3DPEBLW64TMMQQQ": "Hello World!"
	]
	
	private let sampleDataWithPadding: [String: String] = [
		"ORUGKIDROVUWG2ZAMJZG653OEBTG66BANJ2W24DTEBXXMZLSEB2GQZJANRQXU6JAMRXWO===": "the quick brown fox jumps over the lazy dog",
		"KREEKICRKVEUGSZAIJJE6V2OEBDE6WBAJJKU2UCTEBHVMRKSEBKEQRJAJRAVUWJAIRHUO===": "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG",
		"MRUWKIDIMVU4HH3FEB5HS4DFOJXHG33ONZSSA4LVYOSGY5DFEBWWC6BAOVXGIIDWNFRXI33SNFQSA2TBEBRMHNTTMUQGC5LGEBSGK3JAO5SWOIDCNFZSA6TVOIQGXQ54ON2GKLQ=": "die heiße zypernsonne quälte max und victoria ja böse auf dem weg bis zur küste.",
		"IREUKICIIVEVGU2FEBNFSUCFKJHFGT2OJZCSAUKVYOCEYVCFEBGUCWBAKVHEIICWJFBVIT2SJFASASSBEBBMHFSTIUQECVKGEBCEKTJAK5CUOICCJFJSAWSVKIQEXQ44KNKEKLQ=": "DIE HEISSE ZYPERNSONNE QUÄLTE MAX UND VICTORIA JA BÖSE AUF DEM WEG BIS ZUR KÜSTE.",
		"JBSWY3DPEBLW64TMMQQQ====": "Hello World!"
	]
}
