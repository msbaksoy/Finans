// ================================================================
// MulakatPdfOlusturucu.swift
// ================================================================
// Mülakat raporu PDF — mevcut CV PDF stili (sol panel + sağ içerik)
// ================================================================

import UIKit
import CoreText

enum MulakatPdfOlusturucu {

    private static let pageWidth:  CGFloat = 595
    private static let pageHeight: CGFloat = 842
    private static let margin:     CGFloat = 50
    private static let black    = UIColor.black
    private static let darkGray = UIColor.darkGray
    private static let white    = UIColor.white

    private static func font(_ size: CGFloat, bold: Bool = false) -> UIFont {
        bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
    }

    private static func drawText(
        _ text: String,
        in rect: CGRect,
        fontSize: CGFloat,
        bold: Bool = false,
        color: UIColor = .black,
        cgContext: CGContext? = nil,
        alignment: NSTextAlignment = .left
    ) -> CGFloat {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }

        let para = NSMutableParagraphStyle()
        para.alignment = alignment
        para.lineSpacing = 3.0
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font(fontSize, bold: bold),
            .foregroundColor: color,
            .paragraphStyle: para,
            .kern: -0.2
        ]
        let att = NSAttributedString(string: trimmed, attributes: attrs)
        let fs = CTFramesetterCreateWithAttributedString(att as CFAttributedString)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(
            fs, CFRangeMake(0, att.length), nil,
            CGSize(width: rect.width, height: .greatestFiniteMagnitude), nil
        )
        let h = ceil(size.height) + 5

        guard let cg = cgContext else {
            att.draw(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: h))
            return h
        }
        cg.saveGState()
        cg.translateBy(x: rect.minX, y: rect.minY + h)
        cg.scaleBy(x: 1, y: -1)
        let path = CGPath(rect: CGRect(x: 0, y: 0, width: rect.width, height: h), transform: nil)
        let frame = CTFramesetterCreateFrame(fs, CFRangeMake(0, att.length), path, nil)
        CTFrameDraw(frame, cg)
        cg.restoreGState()
        return h
    }

    private static func fillRect(_ rect: CGRect, color: UIColor, cg: CGContext) {
        cg.setFillColor(color.cgColor)
        cg.fill(rect)
    }

    static func olustur(
        oturum: MulakatOturumu,
        konusmaMesajlari: [KonusmaMesaji] = []
    ) -> Data? {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextCreator: "KariyerLens - Mülakat Raporu"] as [String: Any]
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )

        return renderer.pdfData { ctx in
            let pageBounds = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
            let sideW: CGFloat = pageWidth * 0.30
            let mainX: CGFloat = sideW + 12
            let mainW: CGFloat = pageWidth - mainX - 30
            var rightY: CGFloat = margin
            var pageCount = 0

            let sidePrimary: UIColor
            switch oturum.moduEnum {
            case .soruCevap:     sidePrimary = UIColor(red: 0.055, green: 0.640, blue: 0.914, alpha: 1)
            case .senaryo:       sidePrimary = UIColor(red: 0.545, green: 0.361, blue: 0.965, alpha: 1)
            case .tamSimulasyon: sidePrimary = UIColor(red: 0.937, green: 0.267, blue: 0.267, alpha: 1)
            }

            func drawSidebar() {
                let cg = ctx.cgContext
                fillRect(CGRect(x: 0, y: 0, width: sideW, height: pageHeight), color: UIColor(red: 0.063, green: 0.125, blue: 0.157, alpha: 1), cg: cg)
                fillRect(CGRect(x: 0, y: 0, width: 5, height: pageHeight), color: sidePrimary, cg: cg)
            }

            func drawSidebarContent() {
                let cg = ctx.cgContext
                var y: CGFloat = 16
                let pad: CGFloat = 14
                let sw = sideW - pad * 2

                func sLine(_ text: String, size: CGFloat = 9, bold: Bool = false, color: UIColor = .white) {
                    let rect = CGRect(x: pad, y: y, width: sw, height: 400)
                    y += drawText(text, in: rect, fontSize: size, bold: bold, color: color, cgContext: cg)
                }

                func sSep() {
                    cg.setFillColor(UIColor.white.withAlphaComponent(0.15).cgColor)
                    cg.fill(CGRect(x: pad, y: y, width: sw, height: 1))
                    y += 8
                }

                func sTitle(_ t: String) {
                    let rect = CGRect(x: pad, y: y, width: sw, height: 400)
                    y += drawText(t.uppercased(), in: rect, fontSize: 8, bold: true,
                                  color: sidePrimary, cgContext: cg)
                    sSep()
                }

                sLine("KariyerLens", size: 11, bold: true, color: sidePrimary)
                sLine("Mülakat Raporu", size: 9, color: UIColor.white.withAlphaComponent(0.6))
                y += 14

                sTitle("Genel Puan")
                let puan = oturum.toplamPuan
                let puanRenk: UIColor
                if puan >= 8 { puanRenk = UIColor(red: 0.063, green: 0.722, blue: 0.506, alpha: 1) }
                else if puan >= 6 { puanRenk = UIColor(red: 0.961, green: 0.620, blue: 0.043, alpha: 1) }
                else { puanRenk = UIColor(red: 0.937, green: 0.267, blue: 0.267, alpha: 1) }

                sLine(String(format: "%.1f / 10", puan), size: 22, bold: true, color: puanRenk)
                sLine(puan.mulakatPuanEtiketi, size: 10, color: UIColor.white.withAlphaComponent(0.8))
                y += 12

                sTitle("Mülakat Detayları")
                sLine("Pozisyon:", size: 8, color: UIColor.white.withAlphaComponent(0.55))
                sLine(oturum.pozisyon, size: 9, bold: true)
                y += 4
                if !oturum.hedefSirket.isEmpty {
                    sLine("Hedef Şirket:", size: 8, color: UIColor.white.withAlphaComponent(0.55))
                    sLine(oturum.hedefSirket, size: 9, bold: true)
                    y += 4
                }
                sLine("Sektör:", size: 8, color: UIColor.white.withAlphaComponent(0.55))
                sLine(oturum.sektor, size: 9)
                y += 4
                sLine("Mod:", size: 8, color: UIColor.white.withAlphaComponent(0.55))
                sLine(oturum.moduEnum.rawValue, size: 9)
                y += 4
                sLine("Süre:", size: 8, color: UIColor.white.withAlphaComponent(0.55))
                sLine("\(oturum.sureDakika) dakika", size: 9)
                y += 4
                sLine("Tarih:", size: 8, color: UIColor.white.withAlphaComponent(0.55))
                sLine(oturum.tarihFormatlı, size: 8)
                y += 12

                if !oturum.aiGucluYonler.isEmpty {
                    sTitle("Güçlü Yönler")
                    for g in oturum.aiGucluYonler {
                        sLine("✓  \(g)", size: 8.5, color: UIColor(red: 0.063, green: 0.722, blue: 0.506, alpha: 1))
                        y += 2
                    }
                    y += 8
                }

                if !oturum.aiGelistirilecek.isEmpty {
                    sTitle("Geliştirilecek")
                    for g in oturum.aiGelistirilecek {
                        sLine("→  \(g)", size: 8.5, color: UIColor(red: 0.961, green: 0.620, blue: 0.043, alpha: 1))
                        y += 2
                    }
                }
            }

            func beginPage() {
                ctx.beginPage(withBounds: pageBounds, pageInfo: [:])
                pageCount += 1
                drawSidebar()
                if pageCount == 1 { drawSidebarContent() }
                rightY = margin
            }

            func ensureSpace(_ needed: CGFloat) {
                if rightY + needed > pageHeight - margin { beginPage() }
            }

            func mainTitle(_ text: String) {
                ensureSpace(60)
                rightY += 12
                let cg = ctx.cgContext
                cg.setFillColor(UIColor(white: 0.88, alpha: 1).cgColor)
                cg.fill(CGRect(x: mainX, y: rightY + 16, width: mainW, height: 1))
                let r = CGRect(x: mainX, y: rightY, width: mainW, height: 400)
                rightY += drawText(text, in: r, fontSize: 13, bold: true, cgContext: cg)
                rightY += 4
            }

            func mainPara(_ text: String, size: CGFloat = 10, bold: Bool = false, color: UIColor = black) {
                ensureSpace(30)
                let r = CGRect(x: mainX, y: rightY, width: mainW, height: 800)
                rightY += drawText(text, in: r, fontSize: size, bold: bold, color: color, cgContext: ctx.cgContext)
            }

            beginPage()

            let cg = ctx.cgContext
            fillRect(CGRect(x: mainX, y: rightY, width: mainW, height: 44), color: sidePrimary.withAlphaComponent(0.08), cg: cg)
            cg.setFillColor(sidePrimary.cgColor)
            cg.fill(CGRect(x: mainX, y: rightY, width: 3, height: 44))
            let titleR = CGRect(x: mainX + 10, y: rightY + 8, width: mainW - 10, height: 400)
            _ = drawText("Mülakat Performans Raporu", in: titleR, fontSize: 16, bold: true, cgContext: cg)
            let subR = CGRect(x: mainX + 10, y: rightY + 28, width: mainW - 10, height: 400)
            _ = drawText("\(oturum.pozisyon)\(oturum.hedefSirket.isEmpty ? "" : " · \(oturum.hedefSirket)")",
                         in: subR, fontSize: 9, color: darkGray, cgContext: cg)
            rightY += 52

            if !oturum.aiGenelYorum.isEmpty {
                mainTitle("Genel Değerlendirme")
                mainPara(oturum.aiGenelYorum, size: 10, color: darkGray)
                rightY += 6
            }

            if oturum.moduEnum != .tamSimulasyon && !oturum.sorular.isEmpty {
                mainTitle("Soru Bazlı Analiz")
                for soru in oturum.sorular {
                    ensureSpace(80)
                    let soruR = CGRect(x: mainX, y: rightY, width: mainW - 60, height: 400)
                    rightY += drawText("S\(soru.siraNo): \(soru.soru)", in: soruR, fontSize: 10, bold: true, cgContext: cg)

                    if let p = soru.aiPuani {
                        let puanStr = String(format: "%.1f/10", p)
                        let puanR = CGRect(x: mainX + mainW - 50, y: rightY - 16, width: 50, height: 400)
                        let puanColor: UIColor
                        if p >= 8 { puanColor = UIColor(red: 0.063, green: 0.722, blue: 0.506, alpha: 1) }
                        else if p >= 6 { puanColor = UIColor(red: 0.961, green: 0.620, blue: 0.043, alpha: 1) }
                        else { puanColor = UIColor(red: 0.937, green: 0.267, blue: 0.267, alpha: 1) }
                        _ = drawText(puanStr, in: puanR, fontSize: 10, bold: true, color: puanColor, cgContext: cg, alignment: .right)
                    }

                    if !soru.kullaniciYaniti.isEmpty {
                        let yanitR = CGRect(x: mainX + 8, y: rightY + 2, width: mainW - 8, height: 400)
                        rightY += 2 + drawText("Yanıt: \(soru.kullaniciYaniti.prefix(300))", in: yanitR, fontSize: 9, color: darkGray, cgContext: cg)
                    }
                    if !soru.aiYorum.isEmpty {
                        let yorumR = CGRect(x: mainX + 8, y: rightY + 2, width: mainW - 8, height: 400)
                        rightY += 2 + drawText("Değerlendirme: \(soru.aiYorum)", in: yorumR, fontSize: 9, color: darkGray, cgContext: cg)
                    }
                    if !soru.aiOneri.isEmpty {
                        let oneriR = CGRect(x: mainX + 8, y: rightY + 2, width: mainW - 8, height: 400)
                        rightY += 2 + drawText("Öneri: \(soru.aiOneri)", in: oneriR, fontSize: 9, color: UIColor(red: 0.961, green: 0.620, blue: 0.043, alpha: 1), cgContext: cg)
                    }
                    rightY += 10
                    cg.setFillColor(UIColor(white: 0.9, alpha: 1).cgColor)
                    cg.fill(CGRect(x: mainX, y: rightY - 4, width: mainW, height: 0.5))
                }
            }

            if oturum.moduEnum == .tamSimulasyon && !konusmaMesajlari.isEmpty {
                mainTitle("Mülakat Konuşması Özeti")
                let kullaniciMesajlari = konusmaMesajlari.filter { $0.rol == .kullanici }
                for (i, mesaj) in kullaniciMesajlari.prefix(8).enumerated() {
                    ensureSpace(50)
                    mainPara("Yanıt \(i + 1): \(mesaj.icerik.prefix(250))", size: 9, color: darkGray)
                    rightY += 4
                }
            }

            let footerY = pageHeight - 30
            cg.setFillColor(UIColor(white: 0.85, alpha: 1).cgColor)
            cg.fill(CGRect(x: mainX, y: footerY - 2, width: mainW, height: 0.5))
            _ = drawText("Bu rapor KariyerLens tarafından oluşturulmuştur. Bilgi amaçlıdır.",
                         in: CGRect(x: mainX, y: footerY, width: mainW, height: 30),
                         fontSize: 7, color: UIColor(white: 0.65, alpha: 1), cgContext: cg, alignment: .center)
        }
    }
}
