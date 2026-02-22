import Foundation
import UIKit

struct BudgetPdfOlusturucu {
    
    private static var formatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "tr_TR")
        f.maximumFractionDigits = 2
        f.minimumFractionDigits = 2
        return f
    }
    
    private static func fm(_ n: Double) -> String {
        formatter.string(from: NSNumber(value: n)) ?? "₺0,00"
    }
    
    private static func dateStr(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateStyle = .medium
        return f.string(from: d)
    }
    
    static func olustur(incomes: [Income], expenses: [Expense]) -> Data? {
        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 36
        let font = UIFont.systemFont(ofSize: 9)
        let headerFont = UIFont.boldSystemFont(ofSize: 10)
        let bgDark = UIColor(red: 15/255, green: 23/255, blue: 42/255, alpha: 1)
        let cardBg = UIColor.white.withAlphaComponent(0.08)
        let white90 = UIColor.white.withAlphaComponent(0.9)
        let green = UIColor(red: 52/255, green: 211/255, blue: 153/255, alpha: 1)
        let red = UIColor(red: 248/255, green: 113/255, blue: 113/255, alpha: 1)
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextCreator: "Finans - Bütçe Özeti"] as [String: Any]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        
        return renderer.pdfData { ctx in
            ctx.beginPage()
            ctx.cgContext.setFillColor(bgDark.cgColor)
            ctx.cgContext.fill(CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
            
            var y: CGFloat = margin
            let baslikFont = UIFont.boldSystemFont(ofSize: 20)
            "Bütçe Özeti".draw(in: CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: 24), withAttributes: [
                .font: baslikFont, .foregroundColor: white90
            ])
            y += 32
            
            let totalIncome = incomes.reduce(0) { $0 + $1.amount }
            let totalExpense = expenses.reduce(0) { $0 + $1.amount }
            let balance = totalIncome - totalExpense
            
            // Özet kartları
            let ozetW = (pageWidth - 2*margin - 20) / 3
            let ozetH: CGFloat = 44
            let ozetData: [(String, Double, UIColor)] = [
                ("Toplam Gelir", totalIncome, green),
                ("Toplam Gider", totalExpense, red),
                ("Bakiye", balance, balance >= 0 ? green : red)
            ]
            var ox = margin
            for (title, val, color) in ozetData {
                let rect = CGRect(x: ox, y: y, width: ozetW, height: ozetH)
                ctx.cgContext.setFillColor(color.withAlphaComponent(0.15).cgColor)
                ctx.cgContext.fill(rect)
                ctx.cgContext.setStrokeColor(color.withAlphaComponent(0.4).cgColor)
                ctx.cgContext.setLineWidth(1)
                ctx.cgContext.stroke(rect)
                title.draw(in: CGRect(x: ox + 8, y: y + 6, width: ozetW - 16, height: 12), withAttributes: [.font: font, .foregroundColor: white90])
                fm(val).draw(in: CGRect(x: ox + 8, y: y + 20, width: ozetW - 16, height: 14), withAttributes: [.font: headerFont, .foregroundColor: color])
                ox += ozetW + 10
            }
            y += ozetH + 24
            
            // Gelirler tablosu
            if !incomes.isEmpty {
                "Gelirler".draw(in: CGRect(x: margin, y: y, width: 200, height: 14), withAttributes: [.font: headerFont, .foregroundColor: green])
                y += 20
                let colW: [CGFloat] = [80, 100, 120]
                let headers = ["Tarih", "Kaynak", "Tutar"]
                var x = margin
                for (i, h) in headers.enumerated() {
                    let p = NSMutableParagraphStyle()
                    p.alignment = i == 2 ? .right : .left
                    h.draw(in: CGRect(x: x, y: y, width: colW[i], height: 12), withAttributes: [.font: font, .foregroundColor: white90, .paragraphStyle: p])
                    x += colW[i]
                }
                y += 16
                for inc in incomes.sorted(by: { $0.date > $1.date }) {
                    x = margin
                    dateStr(inc.date).draw(in: CGRect(x: x, y: y, width: colW[0], height: 12), withAttributes: [.font: font, .foregroundColor: white90])
                    x += colW[0]
                    inc.source.draw(in: CGRect(x: x, y: y, width: colW[1], height: 12), withAttributes: [.font: font, .foregroundColor: white90])
                    x += colW[1]
                    let p = NSMutableParagraphStyle()
                    p.alignment = .right
                    fm(inc.amount).draw(in: CGRect(x: x, y: y, width: colW[2], height: 12), withAttributes: [.font: font, .foregroundColor: green, .paragraphStyle: p])
                    y += 18
                }
                y += 20
            }
            
            // Giderler tablosu
            if !expenses.isEmpty {
                if y > pageHeight - 200 { ctx.beginPage(); y = margin }
                "Giderler".draw(in: CGRect(x: margin, y: y, width: 200, height: 14), withAttributes: [.font: headerFont, .foregroundColor: red])
                y += 20
                let colW: [CGFloat] = [80, 80, 120, 100]
                let headers = ["Tarih", "Kategori", "Detay", "Tutar"]
                var x = margin
                for (i, h) in headers.enumerated() {
                    let p = NSMutableParagraphStyle()
                    p.alignment = i == 3 ? .right : .left
                    h.draw(in: CGRect(x: x, y: y, width: colW[i], height: 12), withAttributes: [.font: font, .foregroundColor: white90, .paragraphStyle: p])
                    x += colW[i]
                }
                y += 16
                for exp in expenses.sorted(by: { $0.date > $1.date }) {
                    if y > pageHeight - 40 { ctx.beginPage(); y = margin }
                    x = margin
                    dateStr(exp.date).draw(in: CGRect(x: x, y: y, width: colW[0], height: 12), withAttributes: [.font: font, .foregroundColor: white90])
                    x += colW[0]
                    exp.category.draw(in: CGRect(x: x, y: y, width: colW[1], height: 12), withAttributes: [.font: font, .foregroundColor: white90])
                    x += colW[1]
                    String(exp.detail.prefix(25)).draw(in: CGRect(x: x, y: y, width: colW[2], height: 12), withAttributes: [.font: font, .foregroundColor: white90])
                    x += colW[2]
                    let p = NSMutableParagraphStyle()
                    p.alignment = .right
                    ("-" + fm(exp.amount)).draw(in: CGRect(x: x, y: y, width: colW[3], height: 12), withAttributes: [.font: font, .foregroundColor: red, .paragraphStyle: p])
                    y += 18
                }
            }
        }
    }
}
