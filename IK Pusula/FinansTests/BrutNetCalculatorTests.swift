import XCTest
@testable import Finans

final class BrutNetCalculatorTests: XCTestCase {

    // MARK: - Senaryo 1: Asgari Ücret Kontrolü
    func testAsgariUcretHesaplama() {
        let brut = 33_030.00
        let sonuc = BrutNetCalculator.hesapla(brut: brut, kumulatifMatrah: 0)

        XCTAssertEqual(sonuc.vergi, 0, "Asgari ücrette ödenecek vergi 0 olmalı")
        XCTAssertEqual(sonuc.damga, 0, "Asgari ücrette damga vergisi 0 olmalı")

        let beklenenNet = (brut * 0.85).rounded()
        XCTAssertEqual(sonuc.net.rounded(), beklenenNet, accuracy: 1, "Asgari ücret net hesabı hatalı")
    }

    // MARK: - Senaryo 2: SGK Tavanı Aşımı
    func testSgkTavaniAsimi() {
        let cokYuksekBrut = 500_000.00
        let tavan = BrutNetCalculator.sgkTavani

        let sonuc = BrutNetCalculator.hesapla(brut: cokYuksekBrut, kumulatifMatrah: 0)

        let beklenenSgk = (tavan * 0.15).rounded()
        XCTAssertEqual(sonuc.sgk.rounded(), beklenenSgk, accuracy: 1, "SGK tavanı sınırı uygulanmıyor!")
    }

    // MARK: - Senaryo 3: Vergi Dilimi Geçişi (%15 -> %20)
    func testVergiDilimiGecisi() {
        let kumulatif = 190_000.00
        let aylikMatrah = 10_000.00

        let vergi = BrutNetCalculator.dilimliHesapla(matrah: aylikMatrah, baslangicKumulatif: kumulatif)

        XCTAssertEqual(vergi, 2_000.0, accuracy: 0.01, "Vergi dilimi geçişi hatalı hesaplanıyor")
    }

    // MARK: - Senaryo 4: Parçalı Dilim Hesaplama
    func testParcaliDilimHesaplama() {
        let vergi = BrutNetCalculator.dilimliHesapla(matrah: 10_000, baslangicKumulatif: 185_000)

        let beklenen = (5_000 * 0.15) + (5_000 * 0.20)
        XCTAssertEqual(vergi, beklenen, accuracy: 0.01, "Parçalı vergi dilimi hesabı hatalı!")
    }
}
