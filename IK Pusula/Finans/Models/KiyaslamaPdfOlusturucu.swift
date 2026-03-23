import Foundation
import UIKit

/// PDF oluşturma için main thread’den alınan draft verisi (value type, arka planda güvenle kullanılır).
struct KiyaslamaPdfDraftSnapshot {
    var mevcutBrutMaas: Double
    var teklifBrutMaas: Double
    var mevcutUnvanYil: Int
    var mevcutUnvan: String
    var teklifUnvan: String
    var terfiVarMi: Bool
    var mevcutCalismaModeli: String
    var teklifCalismaModeli: String
    var mevcutSigortaTipi: String
    var teklifSigortaTipi: String
    var mevcutYemekTipi: String
    var teklifYemekTipi: String
    var mevcutGunlukYemekUcreti: Double
    var teklifGunlukYemekUcreti: Double
    var mevcutBesVarMi: Bool
    var teklifBesVarMi: Bool
    var mevcutYillikIzin: Int
    var teklifYillikIzin: Int
    var mevcutAracSegment: String
    var teklifAracSegment: String
}

enum KiyaslamaPdfOlusturucu {

    private static let bgDark    = UIColor(red: 0.05, green: 0.05, blue: 0.14, alpha: 1)
    private static let bgCard    = UIColor(red: 0.10, green: 0.10, blue: 0.20, alpha: 1)
    private static let accent1   = UIColor(red: 0.23, green: 0.51, blue: 0.89, alpha: 1)
    private static let accent2   = UIColor(red: 0.55, green: 0.36, blue: 0.96, alpha: 1)
    private static let green     = UIColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1)
    private static let orange    = UIColor(red: 0.93, green: 0.47, blue: 0.10, alpha: 1)
    private static let red       = UIColor(red: 0.96, green: 0.44, blue: 0.44, alpha: 1)
    private static let blue1     = UIColor(red: 0.29, green: 0.56, blue: 0.89, alpha: 1)
    private static let teal1     = UIColor(red: 0.31, green: 0.89, blue: 0.76, alpha: 1)
    private static let lime1     = UIColor(red: 0.72, green: 0.91, blue: 0.52, alpha: 1)
    private static let textW     = UIColor.white
    private static let textW5    = UIColor.white.withAlphaComponent(0.50)
    private static let textD     = UIColor(red: 0.08, green: 0.08, blue: 0.18, alpha: 1)

    private static let W: CGFloat = 595
    private static let H: CGFloat = 842
    private static let M: CGFloat = 36

    static func olustur(
        draft: KiyaslamaPdfDraftSnapshot,
        sirket1: String, sirket2: String,
        trueM1: Double, trueM2: Double,
        yalinM1: Double, yalinM2: Double,
        primM1: Double, primM2: Double,
        gizliM1: Double, gizliM2: Double,
        kidemRisk: Double,
        kirilimlar: [GizliServetKalemi],
        kidemAnalizMetni: String
    ) -> Data? {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Kariyer Kıyaslama Raporu",
            kCGPDFContextAuthor as String: "KariyerLens",
            kCGPDFContextSubject as String: "\(sirket1) ↔ \(sirket2)"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: W, height: H), format: format)
        return renderer.pdfData { ctx in
            ctx.beginPage()
            sayfaBir(ctx: ctx, sirket1: sirket1, sirket2: sirket2, trueM1: trueM1, trueM2: trueM2,
                     yalinM1: yalinM1, yalinM2: yalinM2, primM1: primM1, primM2: primM2,
                     gizliM1: gizliM1, gizliM2: gizliM2, draft: draft)
            ctx.beginPage()
            sayfaIki(ctx: ctx, sirket1: sirket1, sirket2: sirket2, kirilimlar: kirilimlar,
                     gizliM1: gizliM1, gizliM2: gizliM2, kidemRisk: kidemRisk,
                     trueM1: trueM1, trueM2: trueM2, draft: draft, kidemAnalizMetni: kidemAnalizMetni)
            ctx.beginPage()
            sayfaUc(ctx: ctx, sirket1: sirket1, sirket2: sirket2, draft: draft, trueM1: trueM1, trueM2: trueM2)
        }
    }

    private static func sayfaBir(ctx: UIGraphicsPDFRendererContext,
                                 sirket1: String, sirket2: String,
                                 trueM1: Double, trueM2: Double,
                                 yalinM1: Double, yalinM2: Double,
                                 primM1: Double, primM2: Double,
                                 gizliM1: Double, gizliM2: Double,
                                 draft: KiyaslamaPdfDraftSnapshot) {
        let cg = ctx.cgContext
        let headerH: CGFloat = 200
        let headerRect = CGRect(x: 0, y: 0, width: W, height: headerH)
        cg.saveGState()
        let headerColors = [bgDark.cgColor, bgCard.cgColor] as CFArray
        let headerGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: headerColors, locations: [0, 1])!
        cg.addRect(headerRect)
        cg.clip()
        cg.drawLinearGradient(headerGrad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: W, y: headerH), options: [])
        cg.restoreGState()

        cg.setFillColor(accent1.cgColor)
        cg.fill(CGRect(x: 0, y: 0, width: 5, height: headerH))

        drawText("KARIYER", at: CGPoint(x: M, y: 20), font: .boldSystemFont(ofSize: 11), color: accent1, tracking: 3)
        drawText("LENS", at: CGPoint(x: M + 62, y: 20), font: .boldSystemFont(ofSize: 11), color: accent2, tracking: 3)

        let df = DateFormatter()
        df.dateFormat = "dd MMMM yyyy"
        df.locale = Locale(identifier: "tr_TR")
        drawTextRight("Rapor: \(df.string(from: Date()))", x: W - M, y: 22, font: .systemFont(ofSize: 9), color: textW5)

        drawText("KARİYER KIYAS RAPORU", at: CGPoint(x: M, y: 50), font: .systemFont(ofSize: 28, weight: .heavy), color: textW)

        let s1W = (sirket1 as NSString).size(withAttributes: [.font: UIFont.boldSystemFont(ofSize: 18)]).width
        drawText(sirket1, at: CGPoint(x: M, y: 90), font: .boldSystemFont(ofSize: 18), color: accent1)
        drawText("  ↔  ", at: CGPoint(x: M + s1W, y: 90), font: .systemFont(ofSize: 16), color: textW5)
        let arrowW = ("  ↔  " as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 16)]).width
        drawText(sirket2, at: CGPoint(x: M + s1W + arrowW, y: 90), font: .boldSystemFont(ofSize: 18), color: accent2)

        let artis = trueM2 >= trueM1
        let pillColor = artis ? green : red
        let pillText = artis
            ? "✓  Teklif Finansal Açıdan Güçlü  +\(yuzde(trueM1, trueM2))%"
            : "⚠  Teklif Finansal Açıdan Zayıf  -\(yuzde(trueM2, trueM1))%"
        roundedRect(cg, rect: CGRect(x: M, y: 128, width: 340, height: 28), color: pillColor, cornerR: 6)
        drawText(pillText, at: CGPoint(x: M + 10, y: 134), font: .boldSystemFont(ofSize: 11), color: .white)

        let chartY: CGFloat = 220
        drawText("YILLIK PAKET KARŞILAŞTIRMASI", at: CGPoint(x: M, y: chartY), font: .boldSystemFont(ofSize: 9), color: textD, tracking: 2)
        drawText("Tüm bileşenler dahil gerçek yıllık değer (₺)", at: CGPoint(x: M, y: chartY + 14), font: .systemFont(ofSize: 9), color: .gray)

        let barAreaY = chartY + 36
        let barMaxW = W - M * 2 - 120
        let maxVal = max(trueM1, trueM2, 1.0)

        drawStackedBarPDF(cg: cg, y: barAreaY, maas: yalinM1, prim: primM1, gizli: gizliM1, maxVal: maxVal, maxW: barMaxW, label: sirket1, totalLabel: fp(trueM1))
        drawStackedBarPDF(cg: cg, y: barAreaY + 56, maas: yalinM2, prim: primM2, gizli: gizliM2, maxVal: maxVal, maxW: barMaxW, label: sirket2, totalLabel: fp(trueM2))

        let legY = barAreaY + 120
        legendItem(cg, x: M, y: legY, renk: blue1, metin: "Net Maaş")
        legendItem(cg, x: M + 90, y: legY, renk: teal1, metin: "Net Prim")
        legendItem(cg, x: M + 180, y: legY, renk: lime1, metin: "Yan Haklar")

        let tableY: CGFloat = 380
        sectionBaslik(cg, y: tableY, metin: "MAAŞ VE KAZANÇ TABLOSU")

        let rows: [(String, String, String)] = [
            ("Aylık Net Maaş", fp(yalinM1 / 12), fp(yalinM2 / 12)),
            ("Yıllık Net Maaş", fp(yalinM1), fp(yalinM2)),
            ("Yıllık Prim", primM1 > 0 ? fp(primM1) : "-", primM2 > 0 ? fp(primM2) : "-"),
            ("Yıllık Yan Haklar", fp(gizliM1), fp(gizliM2)),
            ("GERÇEK YILLIK PAKET", fp(trueM1), fp(trueM2)),
        ]

        var rowY = tableY + 24
        tableRow(cg, y: rowY, col1: "Kalem", col2: sirket1, col3: sirket2, isHeader: true, highlight: false)
        rowY += 24
        for (i, row) in rows.enumerated() {
            let isTotal = i == rows.count - 1
            tableRow(cg, y: rowY, col1: row.0, col2: row.1, col3: row.2, isHeader: false, highlight: isTotal)
            rowY += isTotal ? 28 : 22
        }

        let kdY = rowY + 20
        sectionBaslik(cg, y: kdY, metin: "MAAŞ KESİNTİ DÖKÜMÜ (TAHMINI)")

        let m1B = draft.mevcutBrutMaas
        let m2B = draft.teklifBrutMaas
        let m1Net = yalinM1 / 12
        let m2Net = yalinM2 / 12

        let kdRows: [(String, String, String)] = [
            ("Brüt Maaş", fp(m1B), fp(m2B)),
            ("SGK + İşsizlik (%15)", "-" + fp(m1B * 0.15), "-" + fp(m2B * 0.15)),
            ("Gelir Vergisi (tahmini)", "-" + fp(max(0, m1B - m1B*0.15) * 0.15), "-" + fp(max(0, m2B - m2B*0.15) * 0.15)),
            ("Damga Vergisi (%0.759)", "-" + fp(m1B * 0.00759), "-" + fp(m2B * 0.00759)),
            ("Net Ele Geçen", fp(m1Net), fp(m2Net)),
        ]

        var kdRowY = kdY + 24
        tableRow(cg, y: kdRowY, col1: "Kalem", col2: sirket1, col3: sirket2, isHeader: true, highlight: false)
        kdRowY += 24
        for (i, row) in kdRows.enumerated() {
            tableRow(cg, y: kdRowY, col1: row.0, col2: row.1, col3: row.2, isHeader: false, highlight: i == kdRows.count - 1)
            kdRowY += 22
        }

        sayfaFooter(cg, sayfaNo: 1)
    }

    private static func sayfaIki(ctx: UIGraphicsPDFRendererContext,
                                 sirket1: String, sirket2: String,
                                 kirilimlar: [GizliServetKalemi],
                                 gizliM1: Double, gizliM2: Double,
                                 kidemRisk: Double,
                                 trueM1: Double, trueM2: Double,
                                 draft: KiyaslamaPdfDraftSnapshot,
                                 kidemAnalizMetni: String) {
        let cg = ctx.cgContext
        sayfaHeaderBant(cg, metin: "YAN HAKLAR & GİZLİ SERVET ANALİZİ", sayfa: 2)

        var y: CGFloat = 80

        sectionBaslik(cg, y: y, metin: "GİZLİ SERVET HESAP FİŞİ — YILLIK (₺)")
        y += 28

        tableRow(cg, y: y, col1: "Yan Hak Kalemi", col2: sirket1, col3: sirket2, isHeader: true, highlight: false)
        y += 24

        if kirilimlar.isEmpty {
            drawText("Yan hak verisi girilmemiş.", at: CGPoint(x: M, y: y), font: .italicSystemFont(ofSize: 10), color: .gray)
            y += 22
        } else {
            for kalem in kirilimlar {
                let kazanan = kalem.mevcutDeger >= kalem.teklifDeger
                tableRow(cg, y: y, col1: kalem.baslik,
                         col2: fp(kalem.mevcutDeger) + (kazanan ? " ✓" : ""),
                         col3: fp(kalem.teklifDeger) + (!kazanan ? " ✓" : ""),
                         isHeader: false, highlight: false,
                         col2Color: kazanan ? green : nil,
                         col3Color: !kazanan ? accent2 : nil)
                y += 22
            }
            tableRow(cg, y: y, col1: "TOPLAM YAN HAK", col2: fp(gizliM1), col3: fp(gizliM2), isHeader: false, highlight: true)
            y += 28
        }

        y += 8
        sectionBaslik(cg, y: y, metin: "YAN HAK DAĞILIMI GÖRSEL KARŞILAŞTIRMASI")
        y += 28

        let maxGizli = max(gizliM1, gizliM2, 1.0)
        let barW: CGFloat = W - M * 2 - 100

        drawSingleBarPDF(cg: cg, y: y, val: gizliM1, maxVal: maxGizli, maxW: barW, renk: accent1, label: sirket1, valueLabel: fp(gizliM1))
        y += 44
        drawSingleBarPDF(cg: cg, y: y, val: gizliM2, maxVal: maxGizli, maxW: barW, renk: accent2, label: sirket2, valueLabel: fp(gizliM2))
        y += 52

        y += 8
        sectionBaslik(cg, y: y, metin: "KIDEM TAZMİNATI & AMORTİSMAN ANALİZİ")
        y += 28

        if kidemRisk > 0 {
            let aylikArtis = max(0, (trueM2 - trueM1) / 12)
            let amortismanAy = aylikArtis > 0 ? kidemRisk / aylikArtis : -1
            let calismaYil = Double(draft.mevcutUnvanYil)

            infoBox(cg, x: M, y: y, w: 170, h: 60, baslik: "İçeride Bırakılan Tazminat", deger: fp(kidemRisk), renk: orange)
            infoBox(cg, x: M + 182, y: y, w: 170, h: 60,
                    baslik: "Amortisman Süresi",
                    deger: amortismanAy > 0 ? (amortismanAy >= 12 ? String(format: "%.1f Yıl", amortismanAy/12) : String(format: "%.0f Ay", amortismanAy)) : "N/A",
                    renk: (0.0...18.0).contains(amortismanAy) ? green : orange)
            infoBox(cg, x: M + 364, y: y, w: 155, h: 60, baslik: "Çalışma Süresi", deger: String(format: "%.0f Yıl", calismaYil), renk: accent1)
            y += 72

            if amortismanAy > 0 {
                let timelineW = barW
                let maxYil = max(calismaYil, amortismanAy/12, 3.0)

                drawText("AMORTİSMAN ÇİZELGESİ", at: CGPoint(x: M, y: y), font: .boldSystemFont(ofSize: 8), color: .gray, tracking: 2)
                y += 14

                cg.setFillColor(UIColor.gray.withAlphaComponent(0.12).cgColor)
                cg.fill(CGRect(x: M, y: y, width: timelineW, height: 10))

                let calismaRatio = CGFloat(min(calismaYil / maxYil, 1))
                cg.setFillColor(orange.withAlphaComponent(0.5).cgColor)
                cg.fill(CGRect(x: M, y: y, width: timelineW * calismaRatio, height: 10))

                if amortismanAy / 12 <= maxYil {
                    let amortiRatio = CGFloat(amortismanAy / 12 / maxYil)
                    let pointX = M + timelineW * amortiRatio
                    cg.setFillColor(green.cgColor)
                    cg.fillEllipse(in: CGRect(x: pointX - 6, y: y - 3, width: 16, height: 16))
                    drawText("✓ Amorti", at: CGPoint(x: pointX - 20, y: y + 15), font: .boldSystemFont(ofSize: 8), color: green)
                }
                y += 38
            }

            let kidemText = kidemAnalizMetni.replacingOccurrences(of: "**", with: "")
            drawMultilineText(kidemText, rect: CGRect(x: M, y: y, width: W - M*2, height: 80), font: .systemFont(ofSize: 9.5), color: .darkGray, lineSpacing: 4)
            y += 85
        } else {
            drawText("Mevcut şirkette 1 yılı doldurmadığından kıdem tazminatı riski bulunmuyor.", at: CGPoint(x: M, y: y), font: .italicSystemFont(ofSize: 10), color: .gray)
        }

        sayfaFooter(cg, sayfaNo: 2)
    }

    private static func sayfaUc(ctx: UIGraphicsPDFRendererContext,
                               sirket1: String, sirket2: String,
                               draft: KiyaslamaPdfDraftSnapshot,
                               trueM1: Double, trueM2: Double) {
        let cg = ctx.cgContext
        sayfaHeaderBant(cg, metin: "KARİYER STRATEJİSİ & YAN HAK KARŞILAŞTIRMASI", sayfa: 3)

        var y: CGFloat = 80

        sectionBaslik(cg, y: y, metin: "KARİYER VE UNVAN STRATEJİSİ")
        y += 28

        let kariyerRows: [(String, String, String)] = [
            ("Mevcut Unvan", draft.mevcutUnvan.isEmpty ? "Belirtilmedi" : draft.mevcutUnvan, ""),
            ("Teklif Unvanı", "", draft.teklifUnvan.isEmpty ? "Belirtilmedi" : draft.teklifUnvan),
            ("Terfi Durumu", "", draft.terfiVarMi ? "✓ Terfi Var" : "Yatay Geçiş"),
            ("Çalışma Modeli", draft.mevcutCalismaModeli.isEmpty ? "-" : draft.mevcutCalismaModeli, draft.teklifCalismaModeli.isEmpty ? "-" : draft.teklifCalismaModeli),
            ("Mevcut Kıdem", "\(draft.mevcutUnvanYil) Yıl", ""),
        ]

        tableRow(cg, y: y, col1: "Kariyer Kalemi", col2: sirket1, col3: sirket2, isHeader: true, highlight: false)
        y += 24
        for row in kariyerRows {
            tableRow(cg, y: y, col1: row.0, col2: row.1, col3: row.2, isHeader: false, highlight: false)
            y += 22
        }

        let artisOrani = trueM1 > 0 ? (trueM2 - trueM1) / trueM1 : 0.0
        y += 10
        let artisStr = String(format: artisOrani >= 0 ? "+%.1f%%" : "%.1f%%", artisOrani * 100)
        let artisColor = artisOrani >= 0 ? green : red
        roundedRect(cg, rect: CGRect(x: M, y: y, width: W - M*2, height: 40), color: artisColor.withAlphaComponent(0.1), cornerR: 8)
        cg.setStrokeColor(artisColor.withAlphaComponent(0.4).cgColor)
        cg.setLineWidth(1)
        cg.stroke(CGRect(x: M, y: y, width: W - M*2, height: 40).insetBy(dx: 0.5, dy: 0.5))
        drawText("Gerçek Yıllık Paket Değişimi:  \(fp(trueM1)) → \(fp(trueM2))  (\(artisStr))", at: CGPoint(x: M + 16, y: y + 14), font: .boldSystemFont(ofSize: 11), color: artisColor)
        y += 52

        sectionBaslik(cg, y: y, metin: "YAN HAK & ÇALIŞMA KOŞULLARI")
        y += 28

        let yanHakRows: [(String, String, String)] = [
            ("Sağlık Sigortası", draft.mevcutSigortaTipi.isEmpty ? "-" : draft.mevcutSigortaTipi, draft.teklifSigortaTipi.isEmpty ? "-" : draft.teklifSigortaTipi),
            ("Yemek İmkânı", draft.mevcutYemekTipi.isEmpty ? "-" : draft.mevcutYemekTipi, draft.teklifYemekTipi.isEmpty ? "-" : draft.teklifYemekTipi),
            ("Günlük Yemek Değeri", draft.mevcutGunlukYemekUcreti > 0 ? fp(draft.mevcutGunlukYemekUcreti) : "-", draft.teklifGunlukYemekUcreti > 0 ? fp(draft.teklifGunlukYemekUcreti) : "-"),
            ("BES Desteği", draft.mevcutBesVarMi ? "✓ Var" : "—", draft.teklifBesVarMi ? "✓ Var" : "—"),
            ("Yıllık İzin", "\(draft.mevcutYillikIzin) Gün", "\(draft.teklifYillikIzin) Gün"),
            ("Şirket Aracı", draft.mevcutAracSegment.isEmpty || draft.mevcutAracSegment == "Yok" ? "—" : draft.mevcutAracSegment, draft.teklifAracSegment.isEmpty || draft.teklifAracSegment == "Yok" ? "—" : draft.teklifAracSegment),
        ]

        tableRow(cg, y: y, col1: "Yan Hak", col2: sirket1, col3: sirket2, isHeader: true, highlight: false)
        y += 24
        for row in yanHakRows {
            tableRow(cg, y: y, col1: row.0, col2: row.1, col3: row.2, isHeader: false, highlight: false)
            y += 22
        }

        y += 20
        let sonucRect = CGRect(x: M, y: y, width: W - M*2, height: 90)
        roundedRect(cg, rect: sonucRect, color: bgCard, cornerR: 10)
        cg.setFillColor(accent1.cgColor)
        cg.fill(CGRect(x: M, y: y, width: 4, height: 90))

        drawText("SONUÇ VE DEĞERLENDİRME", at: CGPoint(x: M + 16, y: y + 10), font: .boldSystemFont(ofSize: 9), color: accent1, tracking: 1.5)

        let fark = trueM2 - trueM1
        let sonucMetin = fark >= 0
            ? "\(sirket2) teklifinin gerçek yıllık toplam paketi \(fp(abs(fark))) daha yüksek (%\(yuzde(trueM1, trueM2))). Maaş, prim ve tüm yan hakların nakit karşılığı dahil edildiğinde teklif finansal açıdan güçlü görünüyor. Nihai kararı verirken kariyer gelişimi, şirket kültürü ve kıdem tazminatı riskini de göz önünde bulundurmanı öneririz."
            : "\(sirket1) şirketindeki mevcut paket, teklife göre \(fp(abs(fark))) daha yüksek (%\(yuzde(trueM2, trueM1))). Teklifin finansal cazibesini artırmak için müzakere fırsatı değerlendirilebilir."

        drawMultilineText(sonucMetin, rect: CGRect(x: M + 16, y: y + 26, width: W - M*2 - 32, height: 60), font: .systemFont(ofSize: 9.5), color: .white.withAlphaComponent(0.9), lineSpacing: 4)
        y += 100

        drawMultilineText("Bu rapor bilgi amaçlıdır; resmi bordro belgesi veya yatırım/hukuk tavsiyesi yerine geçmez. Vergi hesaplamaları tahminidir. Kesin bilgi için İK departmanına veya mali müşavire başvurunuz.",
                          rect: CGRect(x: M, y: y, width: W - M*2, height: 36), font: .italicSystemFont(ofSize: 8), color: .gray.withAlphaComponent(0.7), lineSpacing: 3)

        sayfaFooter(cg, sayfaNo: 3)
    }

    private static func sayfaHeaderBant(_ cg: CGContext, metin: String, sayfa: Int) {
        let headerH: CGFloat = 60
        cg.setFillColor(bgDark.cgColor)
        cg.fill(CGRect(x: 0, y: 0, width: W, height: headerH))
        cg.setFillColor(accent1.cgColor)
        cg.fill(CGRect(x: 0, y: 0, width: 5, height: headerH))
        drawText(metin, at: CGPoint(x: M, y: 22), font: .boldSystemFont(ofSize: 10), color: textW, tracking: 2)
        drawTextRight("Sayfa \(sayfa)/3", x: W - M, y: 24, font: .systemFont(ofSize: 9), color: textW5)
    }

    private static func sayfaFooter(_ cg: CGContext, sayfaNo: Int) {
        let y = H - 30
        cg.setFillColor(UIColor.gray.withAlphaComponent(0.1).cgColor)
        cg.fill(CGRect(x: 0, y: y - 2, width: W, height: 32))
        let df = DateFormatter()
        df.dateFormat = "yyyy"
        df.locale = Locale(identifier: "tr_TR")
        drawText("KariyerLens  •  Kariyer Kıyaslama Raporu  •  \(df.string(from: Date()))", at: CGPoint(x: M, y: y + 8), font: .systemFont(ofSize: 8), color: .gray)
        drawTextRight("Sayfa \(sayfaNo) / 3", x: W - M, y: y + 8, font: .systemFont(ofSize: 8), color: .gray)
    }

    private static func sectionBaslik(_ cg: CGContext, y: CGFloat, metin: String) {
        cg.setFillColor(bgDark.withAlphaComponent(0.06).cgColor)
        cg.fill(CGRect(x: M, y: y, width: W - M*2, height: 20))
        cg.setFillColor(accent1.cgColor)
        cg.fill(CGRect(x: M, y: y, width: 3, height: 20))
        drawText(metin, at: CGPoint(x: M + 10, y: y + 5), font: .boldSystemFont(ofSize: 8.5), color: textD, tracking: 1.5)
    }

    private static func tableRow(_ cg: CGContext, y: CGFloat, col1: String, col2: String, col3: String, isHeader: Bool, highlight: Bool, col2Color: UIColor? = nil, col3Color: UIColor? = nil) {
        let colW = (W - M*2) / 3
        let rowH: CGFloat = isHeader ? 22 : 20

        if isHeader {
            cg.setFillColor(bgDark.withAlphaComponent(0.85).cgColor)
        } else if highlight {
            cg.setFillColor(accent1.withAlphaComponent(0.1).cgColor)
        } else {
            cg.setFillColor(UIColor.clear.cgColor)
        }
        cg.fill(CGRect(x: M, y: y, width: W - M*2, height: rowH))

        cg.setFillColor(UIColor.gray.withAlphaComponent(0.12).cgColor)
        cg.fill(CGRect(x: M, y: y + rowH - 0.5, width: W - M*2, height: 0.5))

        let font: UIFont = isHeader ? .boldSystemFont(ofSize: 9) : (highlight ? .boldSystemFont(ofSize: 9.5) : .systemFont(ofSize: 9))
        let txtColor: UIColor = isHeader ? textW : (highlight ? textD : .darkGray)

        drawText(col1, at: CGPoint(x: M + 6, y: y + 5), font: font, color: isHeader ? textW : txtColor)
        drawTextRight(col2, x: M + colW * 2 - 6, y: y + 5, font: font, color: col2Color ?? (isHeader ? textW : txtColor))
        drawTextRight(col3, x: W - M - 6, y: y + 5, font: font, color: col3Color ?? (isHeader ? accent2 : (highlight ? accent1 : txtColor)))
    }

    private static func drawStackedBarPDF(cg: CGContext, y: CGFloat, maas: Double, prim: Double, gizli: Double, maxVal: Double, maxW: CGFloat, label: String, totalLabel: String) {
        let barH: CGFloat = 20
        let maasW = maxVal > 0 ? CGFloat(maas / maxVal) * maxW : 0
        let primW = maxVal > 0 ? CGFloat(prim / maxVal) * maxW : 0
        let gizliW = maxVal > 0 ? CGFloat(gizli / maxVal) * maxW : 0

        drawText(label, at: CGPoint(x: M, y: y), font: .boldSystemFont(ofSize: 9), color: textD)
        drawTextRight(totalLabel, x: W - M, y: y, font: .boldSystemFont(ofSize: 9), color: textD)

        cg.setFillColor(UIColor.gray.withAlphaComponent(0.1).cgColor)
        let path = UIBezierPath(roundedRect: CGRect(x: M, y: y + 14, width: maxW, height: barH), cornerRadius: 4)
        cg.addPath(path.cgPath)
        cg.fillPath()

        var xPos = M
        if maasW > 0 {
            cg.setFillColor(blue1.cgColor)
            cg.fill(CGRect(x: xPos, y: y + 14, width: maasW, height: barH))
            xPos += maasW
        }
        if primW > 0 {
            cg.setFillColor(teal1.cgColor)
            cg.fill(CGRect(x: xPos, y: y + 14, width: primW, height: barH))
            xPos += primW
        }
        if gizliW > 0 {
            cg.setFillColor(lime1.cgColor)
            cg.fill(CGRect(x: xPos, y: y + 14, width: gizliW, height: barH))
        }
    }

    private static func drawSingleBarPDF(cg: CGContext, y: CGFloat, val: Double, maxVal: Double, maxW: CGFloat, renk: UIColor, label: String, valueLabel: String) {
        let barH: CGFloat = 18
        let barW = maxVal > 0 ? CGFloat(val / maxVal) * maxW : 0

        drawText(label, at: CGPoint(x: M, y: y), font: .boldSystemFont(ofSize: 9), color: textD)
        drawTextRight(valueLabel, x: W - M, y: y, font: .boldSystemFont(ofSize: 9), color: textD)

        cg.setFillColor(renk.withAlphaComponent(0.12).cgColor)
        cg.fill(CGRect(x: M, y: y + 14, width: maxW, height: barH))
        cg.setFillColor(renk.cgColor)
        cg.fill(CGRect(x: M, y: y + 14, width: max(barW, 4), height: barH))
    }

    private static func legendItem(_ cg: CGContext, x: CGFloat, y: CGFloat, renk: UIColor, metin: String) {
        cg.setFillColor(renk.cgColor)
        cg.fill(CGRect(x: x, y: y + 3, width: 10, height: 10))
        drawText(metin, at: CGPoint(x: x + 14, y: y + 2), font: .systemFont(ofSize: 8.5), color: .darkGray)
    }

    private static func infoBox(_ cg: CGContext, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat, baslik: String, deger: String, renk: UIColor) {
        roundedRect(cg, rect: CGRect(x: x, y: y, width: w, height: h), color: renk.withAlphaComponent(0.08), cornerR: 8)
        cg.setStrokeColor(renk.withAlphaComponent(0.3).cgColor)
        cg.setLineWidth(0.8)
        let path = UIBezierPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: 8)
        cg.addPath(path.cgPath)
        cg.strokePath()
        drawText(baslik, at: CGPoint(x: x + 8, y: y + 8), font: .systemFont(ofSize: 8), color: .gray)
        drawText(deger, at: CGPoint(x: x + 8, y: y + 24), font: .boldSystemFont(ofSize: 16), color: renk)
    }

    private static func drawText(_ text: String, at point: CGPoint, font: UIFont, color: UIColor, tracking: CGFloat = 0) {
        var attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        if tracking != 0 { attrs[.kern] = tracking }
        (text as NSString).draw(at: point, withAttributes: attrs)
    }

    private static func drawTextRight(_ text: String, x: CGFloat, y: CGFloat, font: UIFont, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
        let size = (text as NSString).size(withAttributes: attrs)
        (text as NSString).draw(at: CGPoint(x: x - size.width, y: y), withAttributes: attrs)
    }

    private static func drawMultilineText(_ text: String, rect: CGRect, font: UIFont, color: UIColor, lineSpacing: CGFloat) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        style.lineBreakMode = .byWordWrapping
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: style]
        (text as NSString).draw(in: rect, withAttributes: attrs)
    }

    private static func roundedRect(_ cg: CGContext, rect: CGRect, color: UIColor, cornerR: CGFloat) {
        cg.setFillColor(color.cgColor)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerR)
        path.fill()
    }

    private static func fp(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencySymbol = "₺"
        f.maximumFractionDigits = 0
        f.locale = Locale(identifier: "tr_TR")
        return f.string(from: NSNumber(value: v)) ?? "₺0"
    }

    private static func yuzde(_ base: Double, _ yeni: Double) -> String {
        guard base > 0 else { return "0" }
        return String(format: "%.1f", abs((yeni - base) / base * 100))
    }
}
