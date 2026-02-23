import Foundation

/// Tüketici kredisi hesaplama - KKDF ve BSMV oranları parametre ile verilir
/// HangiKredi referans hesaplaması ile uyumlu
struct KrediCalculator {
    
    struct OdemeSatiri: Identifiable {
        let id = UUID()
        let taksitNo: Int
        let taksitTutari: Double
        let anapara: Double
        let faiz: Double
        let kkdf: Double
        let bsmv: Double
        let kalanAnapara: Double
    }
    
    /// Tüketici kredisi ödeme planı hesapla
    /// - Parameters:
    ///   - anapara: Kredi tutarı (TL)
    ///   - vade: Ay sayısı (1-60)
    ///   - aylikFaizOrani: Aylık faiz oranı - bankaların gösterdiği oran (örn. %4,99 için 4.99)
    ///   - kkdfOrani: KKDF oranı (örn. 0.15 = %15)
    ///   - bsmvOrani: BSMV oranı (örn. 0.15 = %15)
    /// - Returns: Ödeme planı satırları
    static func tuketiciKredisiHesapla(anapara: Double, vade: Int, aylikFaizOrani: Double, kkdfOrani: Double = 0.15, bsmvOrani: Double = 0.15) -> [OdemeSatiri] {
        guard anapara > 0, vade >= 1, vade <= 60 else { return [] }
        
        let aylikOran = aylikFaizOrani / 100  // %4.99 → 0.0499
        let vergiCarpani = 1 + kkdfOrani + bsmvOrani
        let etkinAylikOran = aylikOran * vergiCarpani
        
        // Sabit taksit tutarı (annuity formülü)
        let taksit: Double
        if etkinAylikOran == 0 {
            taksit = anapara / Double(vade)
        } else {
            let faktor = pow(1 + etkinAylikOran, Double(vade))
            taksit = anapara * etkinAylikOran * faktor / (faktor - 1)
        }
        
        var satirlar: [OdemeSatiri] = []
        var kalanAnapara = anapara
        
        for ay in 1...vade {
            let faiz = (kalanAnapara * aylikOran).yuvarla()
            let kkdf = (faiz * kkdfOrani).yuvarla()
            let bsmv = (faiz * bsmvOrani).yuvarla()
            
            var anaparaOdeme = (taksit - faiz - kkdf - bsmv).yuvarla()
            
            // Son taksitte kalan anaparayı tam öde
            if ay == vade {
                anaparaOdeme = kalanAnapara
            }
            
            let buAyTaksit = (anaparaOdeme + faiz + kkdf + bsmv).yuvarla()
            kalanAnapara = max(0, (kalanAnapara - anaparaOdeme).yuvarla())
            
            satirlar.append(OdemeSatiri(
                taksitNo: ay,
                taksitTutari: buAyTaksit,
                anapara: anaparaOdeme,
                faiz: faiz,
                kkdf: kkdf,
                bsmv: bsmv,
                kalanAnapara: kalanAnapara
            ))
        }
        
        return satirlar
    }
    
    // MARK: - Konut Kredisi (KKDF/BSMV yok)
    
    struct KonutOdemeSatiri: Identifiable {
        let id = UUID()
        let taksitNo: Int
        let taksitTutari: Double
        let anapara: Double
        let faiz: Double
        let kalanAnapara: Double
    }
    
    /// Konut kredisi ödeme planı - KKDF ve BSMV uygulanmaz
    static func konutKredisiHesapla(anapara: Double, vade: Int, aylikFaizOrani: Double) -> [KonutOdemeSatiri] {
        guard anapara > 0, vade >= 1 else { return [] }
        
        let aylikOran = aylikFaizOrani / 100
        
        let taksit: Double
        if aylikOran == 0 {
            taksit = anapara / Double(vade)
        } else {
            let faktor = pow(1 + aylikOran, Double(vade))
            taksit = anapara * aylikOran * faktor / (faktor - 1)
        }
        
        var satirlar: [KonutOdemeSatiri] = []
        var kalanAnapara = anapara
        
        for ay in 1...vade {
            let faiz = (kalanAnapara * aylikOran).yuvarla()
            var anaparaOdeme = (taksit - faiz).yuvarla()
            if ay == vade { anaparaOdeme = kalanAnapara }
            
            let buAyTaksit = (anaparaOdeme + faiz).yuvarla()
            kalanAnapara = max(0, (kalanAnapara - anaparaOdeme).yuvarla())
            
            satirlar.append(KonutOdemeSatiri(
                taksitNo: ay,
                taksitTutari: buAyTaksit,
                anapara: anaparaOdeme,
                faiz: faiz,
                kalanAnapara: kalanAnapara
            ))
        }
        return satirlar
    }
}

private extension Double {
    func yuvarla() -> Double {
        (self * 100).rounded() / 100
    }
}
