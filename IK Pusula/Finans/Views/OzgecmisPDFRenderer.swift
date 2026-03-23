// ================================================================
// OzgecmisPDFRenderer.swift — İKİ SORUN DÜZELTİLDİ
// ================================================================
//
// DÜZELTME 1 — Çok sayfalı PDF sorunu:
//   Sorun: beginPage() ve ensureSpace(), drawSidebarContent()
//   fonksiyonu kapandıktan SONRA tanımlandığı için bullet
//   satırlarındaki sayfa geçişi sessizce başarısız oluyordu.
//   Çözüm: Tüm iç fonksiyonlar (beginPage, ensureSpace,
//   drawMainSectionTitle, drawMainParagraph) pdfData bloğunun
//   en başına, drawSidebarContent()'ten ÖNCE taşındı.
//   drawMainParagraph artık çok satırlı metni satır satır
//   hesaplayıp sayfa sınırını test ediyor.
//
// DÜZELTME 2 — Sağ panel arka plan rengi değişmiyor:
//   Sorun: OzgecmisPDFKitView.updateUIView sadece document'ı
//   güncelliyordu; backgroundColor güncellemiyordu.
//   Çözüm: PDFKitView artık backgroundColor parametresi alıyor
//   ve updateUIView her çağrıda hem document hem backgroundColor
//   güncelliyor.
//   OzgecmisPreviewView'da onizlemeTema değiştiğinde PDF view
//   yeniden render edilmesi için id() modifier eklendi.
//
// ================================================================

import UIKit
import CoreText

enum OzgecmisPDFRenderer {
    private static let pageWidth:       CGFloat = 595
    private static let pageHeight:      CGFloat = 842
    private static let margin:          CGFloat = 50
    private static let lineSpacing:     CGFloat = 6
    private static let sectionSpacing:  CGFloat = 14
    private static let black    = UIColor.black
    private static let darkGray = UIColor.darkGray


    // Telefon formatla: "+90|532..." → "+90 532..."
    private static func telefonGoster(_ raw: String) -> String {
        let parts = raw.split(separator: "|", maxSplits: 1).map(String.init)
        if parts.count == 2 { return "\(parts[0]) \(parts[1])" }
        return raw
    }

    private static func font(_ size: CGFloat, bold: Bool = false) -> UIFont {
        bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size)
    }

    private static func commonAttributes(
        fontSize: CGFloat, bold: Bool,
        color: UIColor,
        alignment: NSTextAlignment = .justified
    ) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineSpacing = 3.5
        return [
            .font: font(fontSize, bold: bold),
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle,
            .kern: -0.2
        ]
    }

    // MARK: - Temel metin çizici
    private static func drawText(
        _ text: String,
        in rect: CGRect,
        fontSize: CGFloat,
        bold: Bool = false,
        color: UIColor = black,
        cgContext: CGContext? = nil,
        alignment: NSTextAlignment? = nil
    ) -> CGFloat {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }

        let align = alignment ?? .justified
        let attributes = commonAttributes(fontSize: fontSize, bold: bold, color: color, alignment: align)
        let attributed = NSAttributedString(string: trimmed, attributes: attributes)

        let framesetter = CTFramesetterCreateWithAttributedString(attributed as CFAttributedString)
        let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRangeMake(0, attributed.length),
            nil,
            CGSize(width: rect.width, height: CGFloat.greatestFiniteMagnitude),
            nil
        )
        let actualHeight = ceil(suggestedSize.height) + 6

        guard let cg = cgContext else {
            attributed.draw(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: actualHeight))
            return actualHeight
        }

        cg.saveGState()
        cg.translateBy(x: rect.minX, y: rect.minY + actualHeight)
        cg.scaleBy(x: 1.0, y: -1.0)
        let drawRect = CGRect(x: 0, y: 0, width: rect.width, height: actualHeight)
        let path = CGPath(rect: drawRect, transform: nil)
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attributed.length), path, nil)
        CTFrameDraw(frame, cg)
        cg.restoreGState()

        return actualHeight
    }

    // MARK: - Metin yüksekliği ölçer (çizmeden)
    private static func measureText(
        _ text: String,
        width: CGFloat,
        fontSize: CGFloat,
        bold: Bool = false
    ) -> CGFloat {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        let attributes = commonAttributes(fontSize: fontSize, bold: bold, color: black)
        let attributed = NSAttributedString(string: trimmed, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(attributed as CFAttributedString)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRangeMake(0, attributed.length),
            nil,
            CGSize(width: width, height: .greatestFiniteMagnitude),
            nil
        )
        return ceil(size.height) + 6
    }

    private static func loadPhoto() -> UIImage? {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        guard let data = try? Data(contentsOf: docs.appendingPathComponent("cv_photo.jpg")) else { return nil }
        return UIImage(data: data)
    }

    private static func drawPhoto(_ image: UIImage, in rect: CGRect, cgContext: CGContext?) {
        guard let cg = cgContext, let cgImage = image.cgImage else { return }
        cg.saveGState()
        cg.translateBy(x: rect.minX, y: rect.minY + rect.height)
        cg.scaleBy(x: 1.0, y: -1.0)
        let iW = CGFloat(cgImage.width), iH = CGFloat(cgImage.height)
        let iR = iW / iH, rR = rect.width / rect.height
        var drawRect: CGRect
        if iR > rR {
            let s = rect.height / iH
            drawRect = CGRect(x: (rect.width - iW * s) / 2, y: 0, width: iW * s, height: rect.height)
        } else {
            let s = rect.width / iW
            drawRect = CGRect(x: 0, y: (rect.height - iH * s) / 2, width: rect.width, height: iH * s)
        }
        cg.addEllipse(in: CGRect(x: 0, y: 0, width: rect.width, height: rect.height))
        cg.clip()
        cg.draw(cgImage, in: drawRect)
        cg.restoreGState()
    }

    // MARK: - Ana render fonksiyonu
    static func render(draft: OzgecmisDraft) -> Data? {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextCreator: "İK Pusula - Özgeçmiş"] as [String: Any]
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight),
            format: format
        )

        return renderer.pdfData { ctx in
            let sidebarWidth:     CGFloat = pageWidth * 0.32
            let sidebarPadding:   CGFloat = 18
            let mainX:            CGFloat = sidebarWidth + 10
            let mainRightMargin:  CGFloat = 34
            let mainWidth:        CGFloat = pageWidth - mainX - mainRightMargin
            let pageBounds = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

            var pageCount = 0
            var rightY: CGFloat = margin

            // ────────────────────────────────────────────────────────
            // DÜZELTME: Tüm sayfa yönetim fonksiyonları ÖNCE tanımlandı
            // ────────────────────────────────────────────────────────

            func drawSidebarBackground() {
                let cg = ctx.cgContext
                let rect = CGRect(x: 0, y: 0, width: sidebarWidth, height: pageHeight)
                let color = UIColor(solPanelHex: draft.solPanelRenkHex)
                    ?? UIColor(red: 0.05, green: 0.24, blue: 0.45, alpha: 1.0)
                cg.setFillColor(color.cgColor)
                cg.fill(rect)
            }

            // ensureSpace ve beginPage ÖNCE tanımlanıyor
            func ensureSpace(_ needed: CGFloat) {
                if rightY + needed > pageHeight - margin {
                    // beginPage çağrısı
                    ctx.beginPage(withBounds: pageBounds, pageInfo: [:])
                    pageCount += 1
                    drawSidebarBackground()
                    rightY = margin
                }
            }

            func beginPage() {
                ctx.beginPage(withBounds: pageBounds, pageInfo: [:])
                pageCount += 1
                drawSidebarBackground()
                rightY = margin
            }

            func drawMainSectionTitle(_ title: String) {
                // Başlık için yeterli alan var mı? (başlık + en az 1 satır içerik)
                let needed: CGFloat = sectionSpacing + 20 + 6 + 20 // spacing + başlık + çizgi + içerik
                if rightY + needed > pageHeight - margin {
                    beginPage()
                }
                rightY += sectionSpacing
                let titleRect = CGRect(x: mainX, y: rightY, width: mainWidth, height: 400)
                rightY += drawText(title, in: titleRect, fontSize: 12, bold: true, cgContext: ctx.cgContext)
                let lineY = rightY + 2
                ctx.cgContext.setFillColor(UIColor(white: 0.8, alpha: 1.0).cgColor)
                ctx.cgContext.fill(CGRect(x: mainX, y: lineY, width: mainWidth, height: 1))
                rightY = lineY + 4
            }

            /// Çok satırlı metni satır satır sayfa sınırını test ederek çizer
            func drawMainParagraph(
                _ text: String,
                fontSize: CGFloat = 10,
                bold: Bool = false,
                color: UIColor = black
            ) {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }

                // Metnin gerçek yüksekliğini ölç
                let textHeight = measureText(trimmed, width: mainWidth, fontSize: fontSize, bold: bold)

                // Eğer tüm metin bu sayfaya sığıyorsa, direkt çiz
                if rightY + textHeight <= pageHeight - margin {
                    let rect = CGRect(x: mainX, y: rightY, width: mainWidth, height: textHeight + 10)
                    rightY += drawText(trimmed, in: rect, fontSize: fontSize, bold: bold, color: color, cgContext: ctx.cgContext)
                    return
                }

                // Sığmıyorsa: mevcut sayfada kalan boşluğa sığanı çiz, sonra yeni sayfa
                // Satır bazlı bölme: her satırı test et
                let lines = trimmed.components(separatedBy: "\n")
                var buffer: [String] = []

                for line in lines {
                    buffer.append(line)
                    let joined = buffer.joined(separator: "\n")
                    let h = measureText(joined, width: mainWidth, fontSize: fontSize, bold: bold)
                    if rightY + h > pageHeight - margin {
                        // Bu satır sığmadı → önceki buffer'ı çiz ve yeni sayfa
                        let prev = buffer.dropLast().joined(separator: "\n")
                        if !prev.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let rect = CGRect(x: mainX, y: rightY, width: mainWidth, height: 800)
                            rightY += drawText(prev, in: rect, fontSize: fontSize, bold: bold, color: color, cgContext: ctx.cgContext)
                        }
                        beginPage()
                        buffer = [line]
                    }
                }
                // Kalan buffer'ı çiz
                let remaining = buffer.joined(separator: "\n")
                if !remaining.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let rect = CGRect(x: mainX, y: rightY, width: mainWidth, height: 800)
                    rightY += drawText(remaining, in: rect, fontSize: fontSize, bold: bold, color: color, cgContext: ctx.cgContext)
                }
            }

            // ────────────────────────────────────────────────────────
            // Sol panel içeriği (taşınca yeni sayfada devam eder)
            // ────────────────────────────────────────────────────────
            func drawSidebarContent() {
                let k = draft.kisisel
                var yLeft: CGFloat = 10

                func sidebarEnsureSpace(_ needed: CGFloat) {
                    if yLeft + needed > pageHeight - 20 {
                        ctx.beginPage(withBounds: pageBounds, pageInfo: [:])
                        pageCount += 1
                        drawSidebarBackground()
                        yLeft = 10
                    }
                }

                if let photo = loadPhoto() {
                    let size: CGFloat = 120
                    let x = (sidebarWidth - size) / 2
                    let rect = CGRect(x: x, y: yLeft + 8, width: size, height: size)
                    drawPhoto(photo, in: rect, cgContext: ctx.cgContext)
                    yLeft = rect.maxY + 14
                }

                let nameWidth = sidebarWidth - 2 * sidebarPadding
                let nameX = (sidebarWidth - nameWidth) / 2
                let nameRect = CGRect(x: nameX, y: yLeft, width: nameWidth, height: 400)
                yLeft += drawText(k.adSoyad, in: nameRect, fontSize: 18, bold: true,
                                  color: .white, cgContext: ctx.cgContext, alignment: .center)
                yLeft += 10

                // Sidebar'da doğrudan çizim yapan yardımcılar
                func sidebarSectionTitle(_ title: String) {
                    sidebarEnsureSpace(24)
                    let titleRect = CGRect(x: sidebarPadding, y: yLeft,
                                          width: sidebarWidth - 2 * sidebarPadding, height: 400)
                    yLeft += drawText(title, in: titleRect, fontSize: 10, bold: true,
                                      color: .white, cgContext: ctx.cgContext)
                    ctx.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.7).cgColor)
                    ctx.cgContext.fill(CGRect(x: sidebarPadding, y: yLeft,
                                             width: sidebarWidth - 2 * sidebarPadding, height: 1))
                    yLeft += 8
                }

                func sidebarLine(_ text: String) {
                    let h = measureText(text, width: sidebarWidth - 2 * sidebarPadding, fontSize: 9)
                    sidebarEnsureSpace(h + 2)
                    let rect = CGRect(x: sidebarPadding, y: yLeft,
                                     width: sidebarWidth - 2 * sidebarPadding, height: 400)
                    yLeft += drawText(text, in: rect, fontSize: 9, bold: false,
                                      color: .white, cgContext: ctx.cgContext)
                }

                func sidebarIconLine(icon: String, text: String) {
                    guard !text.isEmpty else { return }
                    let iconSize: CGFloat = 12
                    let gap: CGFloat = 6
                    let textX = sidebarPadding + iconSize + gap
                    let textW = sidebarWidth - textX - sidebarPadding
                    let h = measureText(text, width: textW, fontSize: 9)
                    sidebarEnsureSpace(h + 2)
                    if let img = UIImage(systemName: icon), let cgi = img.cgImage {
                        let ir = CGRect(x: sidebarPadding, y: yLeft + 2, width: iconSize, height: iconSize)
                        ctx.cgContext.saveGState()
                        ctx.cgContext.translateBy(x: ir.midX, y: ir.midY)
                        ctx.cgContext.scaleBy(x: 1, y: -1)
                        ctx.cgContext.translateBy(x: -ir.midX, y: -ir.midY)
                        ctx.cgContext.clip(to: ir, mask: cgi)
                        ctx.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.6).cgColor)
                        ctx.cgContext.fill(ir)
                        ctx.cgContext.restoreGState()
                    }
                    let rect = CGRect(x: textX, y: yLeft,
                                     width: textW, height: 400)
                    yLeft += drawText(text, in: rect, fontSize: 9, bold: false,
                                      color: .white, cgContext: ctx.cgContext)
                }

                sidebarSectionTitle("Kişisel Bilgiler")
                if !k.dogumTarihi.isEmpty {
                    sidebarIconLine(icon: "birthday.cake.fill", text: "Doğum: \(k.dogumTarihi)")
                }
                if !k.email.isEmpty         { sidebarIconLine(icon: "envelope.fill",           text: k.email) }
                if !k.telefon.isEmpty        { sidebarIconLine(icon: "phone.fill",              text: telefonGoster(k.telefon)) }
                if !k.sehirIlce.isEmpty      { sidebarIconLine(icon: "mappin.and.ellipse",      text: k.sehirIlce) }
                if !k.ulke.isEmpty           { sidebarIconLine(icon: "globe",                   text: k.ulke) }
                if !k.surucuBelgesi.isEmpty  { sidebarIconLine(icon: "car.fill",                text: "Sürücü Belgesi: \(k.surucuBelgesi)") }
                if !k.askerlikDurumu.isEmpty {
                    var line = "Askerlik: \(k.askerlikDurumu)"
                    if k.askerlikDurumu == "Tecilli", !k.askerlikTecilBitis.isEmpty {
                        line += " (\(k.askerlikTecilBitis))"
                    }
                    sidebarIconLine(icon: "shield.fill", text: line)
                }
                if !k.medeniDurum.isEmpty    { sidebarIconLine(icon: "person.2",               text: "Medeni Durum: \(k.medeniDurum)") }
                if !k.linkedIn.isEmpty       { sidebarIconLine(icon: "link",                   text: k.linkedIn) }
                if !k.webSitesi.isEmpty      { sidebarIconLine(icon: "globe.badge.chevron.backward", text: k.webSitesi) }
                if !k.sosyalMedya.isEmpty    { sidebarIconLine(icon: "at",                     text: k.sosyalMedya) }

                if !draft.ozet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   draft.ozetKonum == .solPanel {
                    yLeft += 10
                    sidebarSectionTitle("Profesyonel Özet")
                    let temizOzet = draft.ozet
                        .components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")
                    sidebarLine(temizOzet)
                }

                if !draft.diller.isEmpty {
                    yLeft += 10
                    sidebarSectionTitle("Diller")
                    for d in draft.diller {
                        let ad  = d.dilAdi.isEmpty  ? "Dil" : d.dilAdi
                        let sev = d.seviye.isEmpty  ? ""    : " – \(d.seviye)"
                        let rating: String = {
                            guard let r = d.yildizSeviye, r > 0 else { return "" }
                            let filled = String(repeating: "★", count: min(r, 5))
                            let empty  = String(repeating: "☆", count: max(0, 5 - r))
                            return "  \(filled)\(empty)"
                        }()
                        sidebarLine(ad + sev + rating)
                    }
                }

                if !draft.yetenekler.isEmpty {
                    yLeft += 10
                    sidebarSectionTitle("Yetenekler")
                    sidebarLine(draft.yetenekler.joined(separator: ", "))
                }

                if !draft.sertifikalar.isEmpty {
                    yLeft += 10
                    sidebarSectionTitle("Sertifikalar")
                    for s in draft.sertifikalar {
                        let adStr = s.ad.isEmpty ? "Sertifika" : s.ad
                        sidebarLine(adStr)
                        let alt = [s.verenKurum, s.tarih].filter { !$0.isEmpty }.joined(separator: " · ")
                        if !alt.isEmpty { sidebarLine("  \(alt)") }
                        let aciklama = s.aciklama.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !aciklama.isEmpty { sidebarLine("  \(aciklama)") }
                    }
                }

                if !draft.hobiler.isEmpty {
                    yLeft += 10
                    sidebarSectionTitle("Hobiler ve İlgi Alanları")
                    sidebarLine(draft.hobiler.joined(separator: ", "))
                }
            }

            // ────────────────────────────────────────────────────────
            // İLK SAYFAYI BAŞLAT
            // ────────────────────────────────────────────────────────
            ctx.beginPage(withBounds: pageBounds, pageInfo: [:])
            pageCount = 1
            drawSidebarBackground()
            drawSidebarContent()
            rightY = margin

            // ────────────────────────────────────────────────────────
            // SAĞ PANEL İÇERİĞİ
            // ────────────────────────────────────────────────────────

            // Profesyonel Özet (sağ panel en üstte)
            if !draft.ozet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               draft.ozetKonum == .sagUst {
                rightY = margin / 2
                let titleRect = CGRect(x: mainX, y: rightY, width: mainWidth, height: 400)
                rightY += drawText("Profesyonel Özet", in: titleRect, fontSize: 12, bold: true,
                                   cgContext: ctx.cgContext)
                let lineY = rightY + 2
                ctx.cgContext.setFillColor(UIColor(white: 0.8, alpha: 1.0).cgColor)
                ctx.cgContext.fill(CGRect(x: mainX, y: lineY, width: mainWidth, height: 1))
                rightY = lineY + 4

                ensureSpace(120)
                let temizOzet = draft.ozet
                    .components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                drawMainParagraph(temizOzet, fontSize: 10, bold: false, color: darkGray)
                rightY += 4
            }

            // Eğitim
            if !draft.egitimler.isEmpty {
                drawMainSectionTitle("Eğitim")
                for e in draft.egitimler {
                    let isLise = e.derece.lowercased().contains("lise")
                    let tarih: String = {
                        let bas = e.baslangic.trimmingCharacters(in: .whitespacesAndNewlines)
                        let bit = e.bitis.trimmingCharacters(in: .whitespacesAndNewlines)
                        if bas.isEmpty && bit.isEmpty { return "" }
                        if bit.isEmpty { return bas }
                        if bas.isEmpty { return bit }
                        return "\(bas) - \(bit)"
                    }()

                    let dateWidth: CGFloat = 80
                    let gap: CGFloat = 8

                    // Yeterli alan var mı?
                    ensureSpace(isLise ? 30 : 80)
                    let y = rightY

                    if !tarih.isEmpty {
                        let dateRect = CGRect(x: mainX, y: y, width: dateWidth, height: 400)
                        _ = drawText("(\(tarih))", in: dateRect, fontSize: 9, bold: false,
                                     color: darkGray, cgContext: ctx.cgContext)
                    }

                    let textX     = mainX + dateWidth + gap
                    let textWidth = mainWidth - dateWidth - gap

                    if isLise {
                        var line1 = e.okul.trimmingCharacters(in: .whitespacesAndNewlines)
                        if line1.isEmpty { line1 = e.derece }
                        if !line1.isEmpty {
                            let rect = CGRect(x: textX, y: y, width: textWidth, height: 400)
                            rightY = y + drawText(line1, in: rect, fontSize: 11, bold: true,
                                                  color: black, cgContext: ctx.cgContext)
                        } else { rightY = y }
                    } else {
                        var currentY = y
                        let uni = e.okul.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !uni.isEmpty {
                            let rect = CGRect(x: textX, y: currentY, width: textWidth, height: 400)
                            currentY += drawText(uni, in: rect, fontSize: 11, bold: true,
                                                 color: black, cgContext: ctx.cgContext)
                        }

                        var ikinciParcalar: [String] = []
                        let fakulte = e.fakulte.trimmingCharacters(in: .whitespacesAndNewlines)
                        let bolum   = e.bolum.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !fakulte.isEmpty { ikinciParcalar.append(fakulte) }
                        if !bolum.isEmpty   { ikinciParcalar.append(bolum) }
                        let secondLine = ikinciParcalar.joined(separator: ", ")
                        if !secondLine.isEmpty {
                            let rect = CGRect(x: textX, y: currentY + 2, width: textWidth, height: 400)
                            currentY += 2 + drawText(secondLine, in: rect, fontSize: 10,
                                                     bold: false, color: darkGray, cgContext: ctx.cgContext)
                        }

                        var thirdParts: [String] = []
                        let dipNot = e.diplomaNotu.trimmingCharacters(in: .whitespacesAndNewlines)
                        let ogTipi = e.ogretimTipi.trimmingCharacters(in: .whitespacesAndNewlines)
                        let ogDili = e.ogretimDili.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !dipNot.isEmpty {
                            let sistem = e.diplomaNotSistemi == "100" ? "/100" : "/4"
                            thirdParts.append("Diploma Notu: \(dipNot)\(sistem)")
                        }
                        if !ogTipi.isEmpty { thirdParts.append("Öğretim Tipi: \(ogTipi)") }
                        if !ogDili.isEmpty { thirdParts.append("Öğretim Dili: \(ogDili)") }
                        if !thirdParts.isEmpty {
                            let rect = CGRect(x: textX, y: currentY + 2, width: textWidth, height: 400)
                            currentY += 2 + drawText(thirdParts.joined(separator: "  "), in: rect,
                                                     fontSize: 9, bold: false, color: darkGray, cgContext: ctx.cgContext)
                        }

                        let bursTipi  = e.bursTipi.trimmingCharacters(in: .whitespacesAndNewlines)
                        let bursOrani = e.bursOrani.trimmingCharacters(in: .whitespacesAndNewlines)
                        var bursLine  = ""
                        if !bursTipi.isEmpty && !bursOrani.isEmpty { bursLine = "\(bursTipi), \(bursOrani)" }
                        else if !bursTipi.isEmpty  { bursLine = bursTipi }
                        else if !bursOrani.isEmpty { bursLine = bursOrani }
                        if !bursLine.isEmpty {
                            let rect = CGRect(x: textX, y: currentY + 2, width: textWidth, height: 400)
                            currentY += 2 + drawText(bursLine, in: rect, fontSize: 9,
                                                     bold: false, color: darkGray, cgContext: ctx.cgContext)
                        }

                        let aciklamaLines = e.aciklama
                            .components(separatedBy: "\n")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                        let egitimAciklama: String
                        if aciklamaLines.contains(where: { $0.hasPrefix("•") }) {
                            egitimAciklama = aciklamaLines.joined(separator: "\n")
                        } else {
                            egitimAciklama = aciklamaLines.joined(separator: " ")
                        }
                        if !egitimAciklama.isEmpty {
                            // Açıklama sayfa taşmasını handle et
                            let neededH = measureText(egitimAciklama, width: textWidth, fontSize: 9)
                            if currentY + neededH > pageHeight - margin {
                                beginPage()
                                currentY = rightY
                            }
                            let rect = CGRect(x: textX, y: currentY + 2, width: textWidth, height: 800)
                            currentY += 2 + drawText(egitimAciklama, in: rect, fontSize: 9,
                                                     bold: false, color: darkGray, cgContext: ctx.cgContext)
                        }
                        rightY = currentY
                    }
                    rightY += 4
                }
            }

            // İş Deneyimi
            if !draft.isDeneyimleri.isEmpty {
                drawMainSectionTitle("İş Deneyimi")
                for d in draft.isDeneyimleri {
                    ensureSpace(60)
                    let dateWidth: CGFloat = 70
                    let gap: CGFloat = 8
                    let y = rightY

                    let tarih: String = {
                        if d.baslangic.isEmpty && d.bitis.isEmpty { return "" }
                        if d.halaDevamEdiyor {
                            return d.baslangic.isEmpty ? "Devam ediyor" : "\(d.baslangic) – Devam ediyor"
                        }
                        if d.bitis.isEmpty   { return d.baslangic }
                        if d.baslangic.isEmpty { return d.bitis }
                        return "\(d.baslangic) – \(d.bitis)"
                    }()

                    let pozisyonSirket: String = {
                        let u = d.unvan.trimmingCharacters(in: .whitespacesAndNewlines)
                        let s = d.sirket.trimmingCharacters(in: .whitespacesAndNewlines)
                        if u.isEmpty && s.isEmpty { return "İş Deneyimi" }
                        if u.isEmpty { return s }
                        if s.isEmpty { return u }
                        return "\(u) — \(s)"
                    }()

                    let dateRect = CGRect(x: mainX, y: y, width: dateWidth, height: 400)
                    let textRect = CGRect(x: mainX + dateWidth + gap, y: y,
                                         width: mainWidth - dateWidth - gap, height: 400)

                    let h1 = drawText(tarih, in: dateRect, fontSize: 9, bold: false,
                                      color: darkGray, cgContext: ctx.cgContext)
                    let h2 = drawText(pozisyonSirket, in: textRect, fontSize: 11, bold: true,
                                      color: black, cgContext: ctx.cgContext)
                    var used = max(h1, h2)
                    rightY = y + used

                    // Firma sektörü, departman, çalışma şekli
                    let detaylar = [d.firmaSektoru, d.departman, d.calismaSekli]
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                        .joined(separator: " · ")
                    if !detaylar.isEmpty {
                        let detayRect = CGRect(x: mainX + dateWidth + gap, y: rightY,
                                              width: mainWidth - dateWidth - gap, height: 400)
                        let h3 = drawText(detaylar, in: detayRect, fontSize: 9,
                                          bold: false, color: darkGray, cgContext: ctx.cgContext)
                        used += h3
                        rightY = y + used
                    }

                    if !d.aciklama.isEmpty {
                        let descLines = d.aciklama
                            .components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }

                        let isBullet = descLines.contains(where: { $0.hasPrefix("•") })
                        let descX    = mainX + dateWidth + gap
                        let descWidth = mainWidth - dateWidth - gap

                        if isBullet {
                            var bulletY = rightY + 2
                            for line in descLines {
                                let lineH = measureText(line, width: descWidth, fontSize: 9)
                                // DÜZELTME: her bullet satırı için sayfa kontrolü
                                if bulletY + lineH > pageHeight - margin {
                                    beginPage()
                                    bulletY = rightY
                                }
                                let lineRect = CGRect(x: descX, y: bulletY, width: descWidth, height: 400)
                                bulletY += drawText(line, in: lineRect, fontSize: 9,
                                                    bold: false, color: darkGray, cgContext: ctx.cgContext)
                            }
                            rightY = bulletY
                        } else {
                            let temiz = descLines.joined(separator: " ")
                            // DÜZELTME: Sayfa taşması kontrolü
                            let neededH = measureText(temiz, width: descWidth, fontSize: 9)
                            if rightY + 2 + neededH > pageHeight - margin {
                                beginPage()
                            }
                            let descRect = CGRect(x: descX, y: rightY + 2, width: descWidth, height: 800)
                            rightY += drawText(temiz, in: descRect, fontSize: 9,
                                               bold: false, color: darkGray, cgContext: ctx.cgContext)
                        }
                    }
                    rightY += 4
                }
            }

            // Projeler
            if !draft.projeler.isEmpty {
                drawMainSectionTitle("Projeler")
                for p in draft.projeler {
                    ensureSpace(60)
                    var baslik = p.projeAdi.isEmpty ? "Proje" : p.projeAdi
                    if !p.tarih.isEmpty { baslik += " (\(p.tarih))" }
                    drawMainParagraph(baslik, fontSize: 10, bold: true)

                    if !p.aciklama.isEmpty {
                        let projeLines = p.aciklama
                            .components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                        let temiz = projeLines.contains(where: { $0.hasPrefix("•") })
                            ? projeLines.joined(separator: "\n")
                            : projeLines.joined(separator: " ")
                        if !temiz.isEmpty { drawMainParagraph(temiz, fontSize: 9, bold: false, color: darkGray) }
                    }
                    if !p.link.isEmpty {
                        drawMainParagraph("Bağlantı: \(p.link)", fontSize: 9, bold: false, color: darkGray)
                    }
                    rightY += 4
                }
            }

            // Referanslar
            if !draft.referanslar.isEmpty {
                drawMainSectionTitle("Referanslar")
                for r in draft.referanslar {
                    ensureSpace(50)
                    var line1 = r.adSoyad
                    if !r.unvan.isEmpty  { line1 += " — \(r.unvan)" }
                    if !r.firma.isEmpty  { line1 += ", \(r.firma)" }
                    drawMainParagraph(line1, fontSize: 10, bold: true)

                    var contact: [String] = []
                    if !r.telefon.isEmpty { contact.append("Tel: \(r.telefon)") }
                    if !r.email.isEmpty   { contact.append("E-posta: \(r.email)") }
                    if !contact.isEmpty   { drawMainParagraph(contact.joined(separator: "    "), fontSize: 9, bold: false, color: darkGray) }
                    rightY += 4
                }
            }

            // Ödüller
            let odullerTemiz = draft.oduller
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if !odullerTemiz.isEmpty {
                drawMainSectionTitle("Ödüller & Başarılar")
                for o in odullerTemiz {
                    ensureSpace(30)
                    drawMainParagraph("• \(o)", fontSize: 9, bold: false, color: darkGray)
                    rightY += 2
                }
            }

            // Ek Bilgiler
            if !draft.ekBilgiler.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                drawMainSectionTitle("Ek Bilgiler")
                drawMainParagraph(draft.ekBilgiler, fontSize: 9, bold: false, color: darkGray)
            }
        }
    }
}

// MARK: - Hex → UIColor (sol panel rengi)
extension UIColor {
    static let solPanelDefaultHex = "0D3D73"

    convenience init?(solPanelHex hex: String?) {
        guard let hex = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !hex.isEmpty else { return nil }
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard h.count == 6,
              let r = Int(h.prefix(2), radix: 16),
              let g = Int(h.dropFirst(2).prefix(2), radix: 16),
              let b = Int(h.suffix(2), radix: 16)
        else { return nil }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
    }
}
