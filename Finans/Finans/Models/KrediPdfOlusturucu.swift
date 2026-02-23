import Foundation
import UIKit

struct KrediPdfOlusturucu {
    
    private static var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        f.decimalSeparator = ","
        f.groupingSeparator = "."
        f.locale = Locale(identifier: "tr_TR")
        return f
    }
    
    private static func fm(_ n: Double) -> String {
        formatter.string(from: NSNumber(value: n)) ?? "0,00"
    }
    
    // Renkler (hex)
    private static let bgDark = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 1)
    private static let cardBg = UIColor.white.withAlphaComponent(0.08)
    private static let white90 = UIColor.white.withAlphaComponent(0.9)
    private static let white75 = UIColor.white.withAlphaComponent(0.75)
    private static let purple = UIColor(red: 139/255, green: 92/255, blue: 246/255, alpha: 1)
    private static let cyan = UIColor(red: 6/255, green: 182/255, blue: 212/255, alpha: 1)
    private static let amber = UIColor(red: 245/255, green: 158/255, blue: 11/255, alpha: 1)
    private static let green = UIColor(red: 52/255, green: 211/255, blue: 153/255, alpha: 1)
    
    enum KrediTipi { case tuketici, konut, tasit }
    
    private static func temaRengi(_ tip: KrediTipi) -> UIColor {
        switch tip {
        case .tuketici: return purple
        case .konut: return cyan
        case .tasit: return amber
        }
    }
    
    private static func baslik(_ tip: KrediTipi) -> String {
        switch tip {
        case .tuketici: return "Tüketici Kredisi"
        case .konut: return "Konut Kredisi"
        case .tasit: return "Taşıt Kredisi"
        }
    }
    
    /// Tüketici kredisi PDF - dashboard tarzı, renkli
    static func tuketiciPdf(anapara: String, vade: String, faiz: String, plan: [KrediCalculator.OdemeSatiri],
                            aylikTaksit: Double, toplamFaiz: Double, toplamMaliyet: Double) -> Data? {
        guard !plan.isEmpty else { return nil }
        return ortakPdf(tip: .tuketici, anapara: anapara, vade: vade, faiz: faiz,
                        aylikTaksit: aylikTaksit, toplamFaiz: toplamFaiz, toplamMaliyet: toplamMaliyet,
                        tuketiciPlan: plan, konutPlan: nil)
    }
    
    /// Konut kredisi PDF - dashboard tarzı
    static func konutPdf(anapara: String, vade: String, faiz: String, plan: [KrediCalculator.KonutOdemeSatiri]) -> Data? {
        guard !plan.isEmpty else { return nil }
        let aylikTaksit = plan.first?.taksitTutari ?? 0
        let toplamFaiz = plan.reduce(0) { $0 + $1.faiz }
        let toplamMaliyet = plan.reduce(0) { $0 + $1.taksitTutari }
        return ortakPdf(tip: .konut, anapara: anapara, vade: vade, faiz: faiz,
                        aylikTaksit: aylikTaksit, toplamFaiz: toplamFaiz, toplamMaliyet: toplamMaliyet,
                        tuketiciPlan: nil, konutPlan: plan)
    }
    
    /// Taşıt kredisi PDF - dashboard tarzı (tüketici ile aynı yapı)
    static func tasitPdf(anapara: String, vade: String, faiz: String, plan: [KrediCalculator.OdemeSatiri],
                         aylikTaksit: Double, toplamFaiz: Double, toplamMaliyet: Double) -> Data? {
        guard !plan.isEmpty else { return nil }
        return ortakPdf(tip: .tasit, anapara: anapara, vade: vade, faiz: faiz,
                        aylikTaksit: aylikTaksit, toplamFaiz: toplamFaiz, toplamMaliyet: toplamMaliyet,
                        tuketiciPlan: plan, konutPlan: nil)
    }
    
    private static func ortakPdf(tip: KrediTipi, anapara: String, vade: String, faiz: String,
                                 aylikTaksit: Double, toplamFaiz: Double, toplamMaliyet: Double,
                                 tuketiciPlan: [KrediCalculator.OdemeSatiri]?,
                                 konutPlan: [KrediCalculator.KonutOdemeSatiri]?) -> Data? {
        let pageWidth: CGFloat = 842
        let pageHeight: CGFloat = 595
        let margin: CGFloat = 36
        let font = UIFont.systemFont(ofSize: 9)
        let headerFont = UIFont.boldSystemFont(ofSize: 10)
        let renk = temaRengi(tip)
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextCreator: "Finans - \(baslik(tip))"] as [String: Any]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        
        return renderer.pdfData { ctx in
            ctx.beginPage()
            ctx.cgContext.setFillColor(bgDark.cgColor)
            ctx.cgContext.fill(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
            
            var y: CGFloat = margin
            let baslikFont = UIFont.boldSystemFont(ofSize: 22)
            "\(baslik(tip)) Ödeme Planı".draw(in: CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: 28), withAttributes: [
                .font: baslikFont, .foregroundColor: renk
            ])
            y += 36
            
            // Kredi bilgileri kartı
            let kartW = pageWidth - 2*margin
            let kartH: CGFloat = 72
            let kartRect = CGRect(x: margin, y: y, width: kartW, height: kartH)
            ctx.cgContext.setFillColor(cardBg.cgColor)
            ctx.cgContext.fill(kartRect)
            ctx.cgContext.setStrokeColor(renk.withAlphaComponent(0.4).cgColor)
            ctx.cgContext.setLineWidth(1)
            ctx.cgContext.stroke(kartRect)
            let infoFont = UIFont.systemFont(ofSize: 11)
            let infoBold = UIFont.boldSystemFont(ofSize: 11)
            "Kredi Bilgileri".draw(in: CGRect(x: margin + 16, y: y + 10, width: 200, height: 14), withAttributes: [.font: infoBold, .foregroundColor: white90])
            "Anapara: \(anapara) ₺".draw(in: CGRect(x: margin + 16, y: y + 28, width: 200, height: 14), withAttributes: [.font: infoFont, .foregroundColor: white75])
            "Vade: \(vade) ay  •  Aylık Faiz: %\(faiz)".draw(in: CGRect(x: margin + 16, y: y + 46, width: 300, height: 14), withAttributes: [.font: infoFont, .foregroundColor: white75])
            y += kartH + 20
            
            // Özet kartları
            let ozetW = (pageWidth - 2*margin - 24) / 3
            let ozetH: CGFloat = 50
            let ozetData: [(String, Double)] = [("Aylık Taksit", aylikTaksit), ("Toplam Faiz", toplamFaiz), ("Toplam Maliyet", toplamMaliyet)]
            var ox = margin
            for (title, val) in ozetData {
                let rect = CGRect(x: ox, y: y, width: ozetW, height: ozetH)
                ctx.cgContext.setFillColor(renk.withAlphaComponent(0.12).cgColor)
                ctx.cgContext.fill(rect)
                ctx.cgContext.setStrokeColor(renk.withAlphaComponent(0.3).cgColor)
                ctx.cgContext.setLineWidth(1)
                ctx.cgContext.stroke(rect)
                title.draw(in: CGRect(x: ox + 10, y: y + 6, width: ozetW - 20, height: 12), withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: white75])
                "₺\(fm(val))".draw(in: CGRect(x: ox + 10, y: y + 22, width: ozetW - 20, height: 16), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: renk])
                ox += ozetW + 12
            }
            y += ozetH + 20
            
            // Tablo
            if let plan = tuketiciPlan {
                let colW: [CGFloat] = [44, 85, 85, 78, 70, 70, 85]
                let headers = ["No", "Taksit", "Anapara", "Faiz", "KKDF", "BSMV", "Kalan"]
                // Header
                var x = margin
                let headerRect = CGRect(x: margin, y: y, width: colW.reduce(0,+), height: 28)
                ctx.cgContext.setFillColor(renk.withAlphaComponent(0.25).cgColor)
                ctx.cgContext.fill(headerRect)
                ctx.cgContext.setStrokeColor(renk.withAlphaComponent(0.4).cgColor)
                ctx.cgContext.stroke(headerRect)
                for (i, h) in headers.enumerated() {
                    let align: NSTextAlignment = i == 0 ? .center : .right
                    let p = NSMutableParagraphStyle()
                    p.alignment = align
                    h.draw(in: CGRect(x: x, y: y + 6, width: colW[i], height: 16), withAttributes: [.font: headerFont, .foregroundColor: white90, .paragraphStyle: p])
                    x += colW[i]
                }
                y += 28
                
                for (idx, s) in plan.enumerated() {
                    let rowBg = idx % 2 == 0 ? UIColor.white.withAlphaComponent(0.03) : UIColor.clear
                    ctx.cgContext.setFillColor(rowBg.cgColor)
                    ctx.cgContext.fill(CGRect(x: margin, y: y, width: colW.reduce(0,+), height: 24))
                    x = margin
                    let pCenter = NSMutableParagraphStyle()
                    pCenter.alignment = .center
                    let pRight = NSMutableParagraphStyle()
                    pRight.alignment = .right
                    "\(s.taksitNo)".draw(in: CGRect(x: x, y: y + 4, width: colW[0], height: 14), withAttributes: [.font: font, .foregroundColor: white90, .paragraphStyle: pCenter])
                    x += colW[0]
                    for (i, v) in [s.taksitTutari, s.anapara, s.faiz, s.kkdf, s.bsmv, s.kalanAnapara].enumerated() {
                        let c: UIColor = i == 1 ? green : white90
                        fm(v).draw(in: CGRect(x: x, y: y + 4, width: colW[i+1], height: 14), withAttributes: [.font: font, .foregroundColor: c, .paragraphStyle: pRight])
                        x += colW[i+1]
                    }
                    y += 24
                }
            } else if let plan = konutPlan {
                let colW: [CGFloat] = [48, 100, 100, 100, 100]
                let headers = ["No", "Taksit", "Anapara", "Faiz", "Kalan"]
                var x = margin
                let headerRect = CGRect(x: margin, y: y, width: colW.reduce(0,+), height: 28)
                ctx.cgContext.setFillColor(renk.withAlphaComponent(0.25).cgColor)
                ctx.cgContext.fill(headerRect)
                ctx.cgContext.setStrokeColor(renk.withAlphaComponent(0.4).cgColor)
                ctx.cgContext.stroke(headerRect)
                for (i, h) in headers.enumerated() {
                    let align: NSTextAlignment = i == 0 ? .center : .right
                    let p = NSMutableParagraphStyle()
                    p.alignment = align
                    h.draw(in: CGRect(x: x, y: y + 6, width: colW[i], height: 16), withAttributes: [.font: headerFont, .foregroundColor: white90, .paragraphStyle: p])
                    x += colW[i]
                }
                y += 28
                let pCenter = NSMutableParagraphStyle()
                pCenter.alignment = .center
                let pRight = NSMutableParagraphStyle()
                pRight.alignment = .right
                for (idx, s) in plan.enumerated() {
                    let rowBg = idx % 2 == 0 ? UIColor.white.withAlphaComponent(0.03) : UIColor.clear
                    ctx.cgContext.setFillColor(rowBg.cgColor)
                    ctx.cgContext.fill(CGRect(x: margin, y: y, width: colW.reduce(0,+), height: 24))
                    x = margin
                    "\(s.taksitNo)".draw(in: CGRect(x: x, y: y + 4, width: colW[0], height: 14), withAttributes: [.font: font, .foregroundColor: white90, .paragraphStyle: pCenter])
                    x += colW[0]
                    for (i, v) in [s.taksitTutari, s.anapara, s.faiz, s.kalanAnapara].enumerated() {
                        let c: UIColor = i == 1 ? green : white90
                        fm(v).draw(in: CGRect(x: x, y: y + 4, width: colW[i+1], height: 14), withAttributes: [.font: font, .foregroundColor: c, .paragraphStyle: pRight])
                        x += colW[i+1]
                    }
                    y += 24
                }
            }
        }
    }
}
