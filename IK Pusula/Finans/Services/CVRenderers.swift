// CVRenderers.swift — 6 CV Formatı
import UIKit
import CoreText

struct CVFormatTanim {
    let id: String
    let isim: String
    let onizlemeRenk: UIColor
    let render: (OzgecmisDraft, UIColor) -> Data?
}

enum CVFormatSecici {
    static let allFormats: [CVFormatTanim] = [
        CVFormatTanim(id: "executive", isim: "Executive", onizlemeRenk: UIColor(red: 0.05, green: 0.20, blue: 0.45, alpha: 1), render: CVRendererExecutive.render),
        CVFormatTanim(id: "minimal", isim: "Minimal", onizlemeRenk: UIColor(red: 0.06, green: 0.46, blue: 0.43, alpha: 1), render: CVRendererMinimal.render),
        CVFormatTanim(id: "timeline", isim: "Timeline", onizlemeRenk: UIColor(red: 0.43, green: 0.16, blue: 0.85, alpha: 1), render: CVRendererTimeline.render),
        CVFormatTanim(id: "card", isim: "Card Grid", onizlemeRenk: UIColor(red: 0.93, green: 0.42, blue: 0.14, alpha: 1), render: CVRendererCard.render),
        CVFormatTanim(id: "creative", isim: "Creative", onizlemeRenk: UIColor(red: 0.85, green: 0.10, blue: 0.30, alpha: 1), render: CVRendererCreative.render),
        CVFormatTanim(id: "academic", isim: "Academic", onizlemeRenk: UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1), render: CVRendererAcademic.render),
    ] + CVFormatSecici_NEW.newFormats
}

// Ortak sayfa yöneticisi (tüm renderer'lar bunu kullanır)
private final class PageState {
    let pdfCtx: UIGraphicsPDFRendererContext
    let W: CGFloat, H: CGFloat
    var y: CGFloat
    let topPad: CGFloat
    private let onNewPage: (PageState) -> Void

    init(_ ctx: UIGraphicsPDFRendererContext, W: CGFloat, H: CGFloat,
         topPad: CGFloat = 40, onNewPage: @escaping (PageState) -> Void) {
        self.pdfCtx = ctx
        self.W = W
        self.H = H
        self.y = topPad
        self.topPad = topPad
        self.onNewPage = onNewPage
    }

    func ensure(_ need: CGFloat) {
        if y + need > H - 36 {
            pdfCtx.beginPage(withBounds: CGRect(x: 0, y: 0, width: W, height: H), pageInfo: [:])
            y = topPad
            onNewPage(self)
        }
    }

    func body(_ text: String, x: CGFloat, width: CGFloat, sz: CGFloat = 9.5,
              bold: Bool = false, color: UIColor = UIColor(white: 0.15, alpha: 1),
              alignment: NSTextAlignment = .justified) {
        let h = CVRenderKit.measureText(text, width: width, fontSize: sz, bold: bold)
        ensure(h)
        CVRenderKit.drawText(text, x: x, y: y, width: width, fontSize: sz,
                             bold: bold, color: color, alignment: alignment,
                             ctx: pdfCtx.cgContext)
        y += h + 3
    }
}

// MARK: ── FORMAT 1: EXECUTIVE ──────────────────────────────────
enum CVRendererExecutive: CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk: UIColor) -> Data? {
        let W = CVRenderKit.pageWidth, H = CVRenderKit.pageHeight
        let lm: CGFloat = 52, rm: CGFloat = 52, cW = W - lm - rm
        let headerH: CGFloat = 124

        return UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: W, height: H)).pdfData { pdf in
            let ps = PageState(pdf, W: W, H: H, topPad: headerH + 22) { s in
                CVRenderKit.fillRect(CGRect(x: 0, y: 0, width: W, height: 3), color: vurguRenk, ctx: pdf.cgContext)
            }
            pdf.beginPage(withBounds: CGRect(x: 0, y: 0, width: W, height: H), pageInfo: [:])
            let cg = pdf.cgContext

            CVRenderKit.fillRect(CGRect(x: 0, y: 0, width: W, height: headerH), color: vurguRenk, ctx: cg)
            CVRenderKit.fillRect(CGRect(x: 0, y: headerH, width: W, height: 2),
                                 color: vurguRenk.withAlphaComponent(0.4), ctx: cg)

            var nameX = lm
            if let ph = CVRenderKit.loadPhoto() {
                CVRenderKit.drawPhoto(ph, cx: lm + 40, cy: headerH / 2, radius: 48, ctx: cg)
                nameX = lm + 90
            }
            let adH = CVRenderKit.drawText(draft.kisisel.adSoyad, x: nameX, y: 20,
                                           width: W - nameX - rm, fontSize: 22, bold: true,
                                           color: .white, alignment: .left, ctx: cg)
            if let unvan = draft.isDeneyimleri.first?.unvan, !unvan.isEmpty {
                CVRenderKit.drawText(unvan, x: nameX, y: 20 + adH + 3, width: W - nameX - rm,
                                     fontSize: 10, color: UIColor.white.withAlphaComponent(0.72),
                                     alignment: .left, ctx: cg)
            }
            let k = draft.kisisel
            let kt = [k.email, k.telefon, k.sehirIlce, k.linkedIn].filter { !$0.isEmpty }.joined(separator: " · ")
            CVRenderKit.drawText(kt, x: lm, y: headerH - 22, width: cW, fontSize: 8,
                                 color: UIColor.white.withAlphaComponent(0.75), alignment: .left, ctx: cg)

            func sec(_ t: String) {
                ps.ensure(26)
                ps.y += 8
                CVRenderKit.drawText(t.uppercased(), x: lm, y: ps.y, width: cW, fontSize: 8.5,
                                     bold: true, color: vurguRenk, alignment: .left, ctx: pdf.cgContext)
                ps.y += 13
                CVRenderKit.fillRect(CGRect(x: lm, y: ps.y, width: cW, height: 1),
                                     color: vurguRenk.withAlphaComponent(0.20), ctx: pdf.cgContext)
                ps.y += 6
            }

            if !draft.ozet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sec("Özet"); ps.body(draft.ozet, x: lm, width: cW); ps.y += 6
            }
            if !draft.isDeneyimleri.isEmpty {
                sec("İş Deneyimi")
                for d in draft.isDeneyimleri {
                    ps.ensure(44)
                    let tarih = CVRenderKit.tarihAralik(baslangic: d.baslangic, bitis: d.bitis, devamEdiyor: d.halaDevamEdiyor)
                    if !tarih.isEmpty {
                        CVRenderKit.drawText(tarih, x: W - rm - 88, y: ps.y, width: 88,
                                             fontSize: 8, color: UIColor(white: 0.52, alpha: 1),
                                             alignment: .right, ctx: pdf.cgContext)
                    }
                    ps.body("\(d.unvan.isEmpty ? "" : d.unvan)\(d.sirket.isEmpty ? "" : " — \(d.sirket)")",
                            x: lm, width: cW - 90, bold: true)
                    if !d.firmaSektoru.isEmpty || !d.calismaSekli.isEmpty {
                        ps.body([d.firmaSektoru, d.calismaSekli].filter { !$0.isEmpty }.joined(separator: " · "),
                                 x: lm, width: cW, sz: 9, color: UIColor(white: 0.4, alpha: 1))
                    }
                    if !d.aciklama.isEmpty { ps.body(d.aciklama, x: lm + 10, width: cW - 10, sz: 9, color: UIColor(white: 0.28, alpha: 1)) }
                    ps.y += 5
                }
            }
            if !draft.egitimler.isEmpty {
                sec("Eğitim")
                for e in draft.egitimler {
                    ps.ensure(36)
                    let t = CVRenderKit.tarihAralik(baslangic: e.baslangic, bitis: e.bitis)
                    if !t.isEmpty {
                        CVRenderKit.drawText(t, x: W - rm - 88, y: ps.y, width: 88, fontSize: 8, color: UIColor(white: 0.52, alpha: 1), alignment: .right, ctx: pdf.cgContext)
                    }
                    ps.body(e.okul, x: lm, width: cW - 90, bold: true)
                    if !e.bolum.isEmpty { ps.body(e.bolum, x: lm + 10, width: cW - 10, sz: 9) }
                    ps.y += 4
                }
            }
            if !draft.yetenekler.isEmpty { sec("Yetenekler"); ps.body(draft.yetenekler.joined(separator: " · "), x: lm, width: cW) }
            if !draft.diller.isEmpty {
                sec("Diller")
                ps.body(draft.diller.map { "\($0.dilAdi)\($0.seviye.isEmpty ? "" : " (\($0.seviye))")" }.joined(separator: "   "), x: lm, width: cW)
            }
            if !draft.sertifikalar.isEmpty {
                sec("Sertifikalar")
                for s in draft.sertifikalar { ps.body("• \(s.ad)\(s.verenKurum.isEmpty ? "" : " — \(s.verenKurum)")", x: lm, width: cW) }
            }
        }
    }
}

// MARK: ── FORMAT 2: MINIMAL ────────────────────────────────────
enum CVRendererMinimal: CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk: UIColor) -> Data? {
        let W = CVRenderKit.pageWidth, H = CVRenderKit.pageHeight
        let barW: CGFloat = 4, leftW: CGFloat = 165
        let gutter: CGFloat = 20, rightX = leftW + gutter, rightW = W - rightX - 34

        return UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: W, height: H)).pdfData { pdf in
            var lY: CGFloat = 40, rY: CGFloat = 40
            let lX: CGFloat = barW + 12
            let lTW = leftW - barW - 20

            func drawBar() {
                CVRenderKit.fillRect(CGRect(x: 0, y: 0, width: barW, height: H), color: vurguRenk, ctx: pdf.cgContext)
            }
            func newPage() {
                pdf.beginPage(withBounds: CGRect(x: 0, y: 0, width: W, height: H), pageInfo: [:])
                drawBar()
                lY = 40; rY = 40
            }

            pdf.beginPage(withBounds: CGRect(x: 0, y: 0, width: W, height: H), pageInfo: [:])
            drawBar()

            if let ph = CVRenderKit.loadPhoto() {
                CVRenderKit.drawPhoto(ph, cx: lX + 30, cy: lY + 30, radius: 30, ctx: pdf.cgContext)
                lY += 68
            }
            func lDraw(_ t: String, sz: CGFloat = 9, bold: Bool = false, color: UIColor = UIColor(white: 0.12, alpha: 1)) {
                let h = CVRenderKit.measureText(t, width: lTW, fontSize: sz, bold: bold)
                if lY + h > H - 36 { newPage() }
                CVRenderKit.drawText(t, x: lX, y: lY, width: lTW, fontSize: sz, bold: bold, color: color, alignment: .left, ctx: pdf.cgContext)
                lY += h + 3
            }
            func rDraw(_ t: String, sz: CGFloat = 9.5, bold: Bool = false, color: UIColor = UIColor(white: 0.18, alpha: 1), indent: CGFloat = 0) {
                let h = CVRenderKit.measureText(t, width: rightW - indent, fontSize: sz, bold: bold)
                if rY + h > H - 36 { newPage() }
                CVRenderKit.drawText(t, x: rightX + indent, y: rY, width: rightW - indent, fontSize: sz, bold: bold, color: color, alignment: .justified, ctx: pdf.cgContext)
                rY += h + 3
            }
            func rSec(_ t: String) {
                rY += 8
                let h = CVRenderKit.measureText(t.uppercased(), width: rightW, fontSize: 7.5, bold: true)
                if rY + h > H - 36 { newPage() }
                CVRenderKit.drawText(t.uppercased(), x: rightX, y: rY, width: rightW, fontSize: 7.5, bold: true, color: vurguRenk, alignment: .left, ctx: pdf.cgContext)
                rY += h + 3
                CVRenderKit.fillRect(CGRect(x: rightX, y: rY, width: rightW, height: 0.6), color: vurguRenk.withAlphaComponent(0.18), ctx: pdf.cgContext)
                rY += 6
            }

            lDraw(draft.kisisel.adSoyad, sz: 15, bold: true)
            if let u = draft.isDeneyimleri.first?.unvan, !u.isEmpty { lDraw(u, sz: 9, color: vurguRenk) }
            lY += 10
            lDraw("İLETİŞİM", sz: 7, bold: true, color: UIColor(white: 0.55, alpha: 1))
            let k = draft.kisisel
            for t in [k.email, k.telefon, k.sehirIlce, k.linkedIn, k.webSitesi].filter({ !$0.isEmpty }) { lDraw(t, sz: 8) }
            lY += 12
            if !draft.yetenekler.isEmpty {
                lDraw("YETENEKler", sz: 7, bold: true, color: UIColor(white: 0.55, alpha: 1))
                for y in draft.yetenekler.prefix(12) { lDraw("· \(y)", sz: 8) }
                lY += 8
            }
            if !draft.diller.isEmpty {
                lDraw("DİLLER", sz: 7, bold: true, color: UIColor(white: 0.55, alpha: 1))
                for d in draft.diller { lDraw("\(d.dilAdi)\(d.seviye.isEmpty ? "" : "  \(d.seviye)")", sz: 8) }
                lY += 8
            }
            if !draft.sertifikalar.isEmpty {
                lDraw("SERTİFİKALAR", sz: 7, bold: true, color: UIColor(white: 0.55, alpha: 1))
                for s in draft.sertifikalar { lDraw(s.ad, sz: 8) }
            }
            CVRenderKit.drawLine(x1: rightX - 9, y1: 40, x2: rightX - 9, y2: H - 40, color: UIColor(white: 0.87, alpha: 1), width: 0.5, ctx: pdf.cgContext)
            if !draft.ozet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { rSec("Özet"); rDraw(draft.ozet); rY += 6 }
            if !draft.isDeneyimleri.isEmpty {
                rSec("İş Deneyimi")
                for d in draft.isDeneyimleri {
                    let t = CVRenderKit.tarihAralik(baslangic: d.baslangic, bitis: d.bitis, devamEdiyor: d.halaDevamEdiyor)
                    rDraw("\(d.unvan)\(d.sirket.isEmpty ? "" : "  ·  \(d.sirket)")", sz: 10, bold: true)
                    if !t.isEmpty { rDraw(t, sz: 8, color: UIColor(white: 0.55, alpha: 1)) }
                    if !d.aciklama.isEmpty { rDraw(d.aciklama, sz: 9, color: UIColor(white: 0.30, alpha: 1), indent: 8) }
                    rY += 5
                }
            }
            if !draft.egitimler.isEmpty {
                rSec("Eğitim")
                for e in draft.egitimler {
                    rDraw(e.okul, sz: 10, bold: true)
                    if !e.bolum.isEmpty { rDraw(e.bolum, sz: 9) }
                    let t = CVRenderKit.tarihAralik(baslangic: e.baslangic, bitis: e.bitis)
                    if !t.isEmpty { rDraw(t, sz: 8, color: UIColor(white: 0.55, alpha: 1)) }
                    rY += 4
                }
            }
        }
    }
}

// MARK: ── FORMAT 3: TIMELINE ───────────────────────────────────
enum CVRendererTimeline: CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk: UIColor) -> Data? {
        let W = CVRenderKit.pageWidth, H = CVRenderKit.pageHeight
        let lm: CGFloat = 44, rm: CGFloat = 44, cW = W - lm - rm
        let tlX: CGFloat = lm + 108

        return UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: W, height: H)).pdfData { pdf in
            var y: CGFloat = 40

            func newPage() {
                pdf.beginPage(withBounds: CGRect(x: 0, y: 0, width: W, height: H), pageInfo: [:])
                CVRenderKit.fillRect(CGRect(x: 0, y: 0, width: W, height: 3), color: vurguRenk, ctx: pdf.cgContext)
                y = 38
            }
            func ens(_ h: CGFloat) { if y + h > H - 36 { newPage() } }

            pdf.beginPage(withBounds: CGRect(x: 0, y: 0, width: W, height: H), pageInfo: [:])
            CVRenderKit.fillRect(CGRect(x: 0, y: 0, width: W, height: 3), color: vurguRenk, ctx: pdf.cgContext)
            let cg = pdf.cgContext

            var hX = lm
            if let ph = CVRenderKit.loadPhoto() { CVRenderKit.drawPhoto(ph, cx: lm + 34, cy: y + 34, radius: 34, ctx: cg); hX = lm + 78 }
            let adH = CVRenderKit.drawText(draft.kisisel.adSoyad, x: hX, y: y, width: cW - 78, fontSize: 21, bold: true, color: UIColor(white: 0.1, alpha: 1), alignment: .left, ctx: cg)
            if let u = draft.isDeneyimleri.first?.unvan, !u.isEmpty { CVRenderKit.drawText(u, x: hX, y: y + adH + 2, width: cW - 78, fontSize: 10, color: vurguRenk, alignment: .left, ctx: cg) }
            let k = draft.kisisel
            CVRenderKit.drawText([k.email, k.telefon, k.sehirIlce].filter { !$0.isEmpty }.joined(separator: " · "), x: hX, y: y + adH + 17, width: cW - 78, fontSize: 8, color: UIColor(white: 0.5, alpha: 1), alignment: .left, ctx: cg)
            y += 86
            CVRenderKit.fillRect(CGRect(x: lm, y: y, width: cW, height: 1.2), color: vurguRenk.withAlphaComponent(0.25), ctx: cg)
            y += 16

            if !draft.ozet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let h = CVRenderKit.measureText(draft.ozet, width: cW, fontSize: 9.5)
                ens(h)
                CVRenderKit.drawText(draft.ozet, x: lm, y: y, width: cW, fontSize: 9.5, color: UIColor(white: 0.28, alpha: 1), alignment: .justified, ctx: pdf.cgContext)
                y += h + 18
            }

            func sec(_ t: String) {
                ens(24)
                y += 6
                CVRenderKit.drawText(t.uppercased(), x: lm, y: y, width: cW, fontSize: 8, bold: true, color: vurguRenk, alignment: .left, ctx: pdf.cgContext)
                y += 13
                CVRenderKit.fillRect(CGRect(x: lm, y: y, width: cW, height: 0.7), color: vurguRenk.withAlphaComponent(0.15), ctx: pdf.cgContext)
                y += 8
            }

            func tlItem(tarih: String, baslik: String, alt: String = "", aciklama: String = "") {
                let itemX = tlX + 14, itemW = W - rm - itemX
                let fullText = "\(baslik)\(alt.isEmpty ? "" : "\n\(alt)")\(aciklama.isEmpty ? "" : "\n\(aciklama)")"
                let h = CVRenderKit.measureText(fullText, width: itemW, fontSize: 9.5) + 16
                ens(h)
                CVRenderKit.drawText(tarih, x: lm, y: y, width: tlX - lm - 6, fontSize: 8, color: UIColor(white: 0.55, alpha: 1), alignment: .right, ctx: pdf.cgContext)
                let dotR: CGFloat = 3.5
                pdf.cgContext.setFillColor(vurguRenk.cgColor)
                pdf.cgContext.fillEllipse(in: CGRect(x: tlX - dotR, y: y + 6 - dotR, width: dotR * 2, height: dotR * 2))
                CVRenderKit.drawLine(x1: tlX, y1: y + 6 + dotR, x2: tlX, y2: y + h, color: UIColor(white: 0.82, alpha: 1), width: 0.8, ctx: pdf.cgContext)
                CVRenderKit.drawText(baslik, x: itemX, y: y, width: itemW, fontSize: 10.5, bold: true, color: UIColor(white: 0.12, alpha: 1), alignment: .left, ctx: pdf.cgContext)
                var subY = y + CVRenderKit.measureText(baslik, width: itemW, fontSize: 10.5, bold: true) + 2
                if !alt.isEmpty {
                    CVRenderKit.drawText(alt, x: itemX, y: subY, width: itemW, fontSize: 9, color: UIColor(white: 0.40, alpha: 1), alignment: .left, ctx: pdf.cgContext)
                    subY += CVRenderKit.measureText(alt, width: itemW, fontSize: 9) + 2
                }
                if !aciklama.isEmpty { CVRenderKit.drawText(aciklama, x: itemX, y: subY, width: itemW, fontSize: 9, color: UIColor(white: 0.35, alpha: 1), alignment: .justified, ctx: pdf.cgContext) }
                y += h
            }

            if !draft.isDeneyimleri.isEmpty {
                sec("İş Deneyimi")
                for d in draft.isDeneyimleri {
                    tlItem(tarih: CVRenderKit.tarihAralik(baslangic: d.baslangic, bitis: d.bitis, devamEdiyor: d.halaDevamEdiyor),
                           baslik: "\(d.unvan.isEmpty ? "Pozisyon" : d.unvan)",
                           alt: d.sirket, aciklama: d.aciklama)
                    y += 4
                }
            }
            if !draft.egitimler.isEmpty {
                sec("Eğitim")
                for e in draft.egitimler {
                    tlItem(tarih: CVRenderKit.tarihAralik(baslangic: e.baslangic, bitis: e.bitis),
                           baslik: e.okul,
                           alt: "\(e.bolum)\(e.derece.isEmpty ? "" : " · \(e.derece)")")
                    y += 4
                }
            }
            if !draft.yetenekler.isEmpty {
                sec("Yetenekler")
                let h = CVRenderKit.measureText(draft.yetenekler.joined(separator: " · "), width: cW, fontSize: 9)
                ens(h)
                CVRenderKit.drawText(draft.yetenekler.joined(separator: " · "), x: lm, y: y, width: cW, fontSize: 9, color: UIColor(white: 0.30, alpha: 1), alignment: .left, ctx: pdf.cgContext)
                y += h + 8
            }
            if !draft.diller.isEmpty {
                sec("Diller")
                CVRenderKit.drawText(draft.diller.map { "\($0.dilAdi)\($0.seviye.isEmpty ? "" : " (\($0.seviye))")" }.joined(separator: "   ·   "), x: lm, y: y, width: cW, fontSize: 9, color: UIColor(white: 0.30, alpha: 1), alignment: .left, ctx: pdf.cgContext)
            }
        }
    }
}

// MARK: ── FORMAT 4: CARD GRID ──────────────────────────────────
enum CVRendererCard: CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk: UIColor) -> Data? {
        let W = CVRenderKit.pageWidth, H = CVRenderKit.pageHeight
        let lm: CGFloat = 34, rm: CGFloat = 34, cW = W - lm - rm

        return UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: W, height: H)).pdfData { pdf in
            var y: CGFloat = 34

            func newPage() { pdf.beginPage(withBounds: CGRect(x: 0, y: 0, width: W, height: H), pageInfo: [:]); y = 34 }
            func ens(_ h: CGFloat) { if y + h > H - 34 { newPage() } }

            pdf.beginPage(withBounds: CGRect(x: 0, y: 0, width: W, height: H), pageInfo: [:])
            let cg = pdf.cgContext

            let hH: CGFloat = 88
            CVRenderKit.fillRect(CGRect(x: lm, y: y, width: cW, height: hH), color: vurguRenk, ctx: cg)
            var nX = lm + 14
            if let ph = CVRenderKit.loadPhoto() { CVRenderKit.drawPhoto(ph, cx: lm + 28, cy: y + hH / 2, radius: 26, ctx: cg); nX = lm + 64 }
            CVRenderKit.drawText(draft.kisisel.adSoyad, x: nX, y: y + 14, width: cW - nX + lm - 12, fontSize: 19, bold: true, color: .white, alignment: .left, ctx: cg)
            let k = draft.kisisel
            CVRenderKit.drawText([k.email, k.telefon, k.sehirIlce].filter { !$0.isEmpty }.joined(separator: "   ·   "), x: nX, y: y + 46, width: cW - nX + lm - 12, fontSize: 8, color: UIColor.white.withAlphaComponent(0.75), alignment: .left, ctx: cg)
            y += hH + 14

            func kart(_ baslik: String, _ inner: () -> Void) {
                let startY = y
                CVRenderKit.fillRect(CGRect(x: lm, y: y, width: cW, height: 20), color: vurguRenk.withAlphaComponent(0.09), ctx: pdf.cgContext)
                CVRenderKit.drawText(baslik.uppercased(), x: lm + 8, y: y + 5, width: cW - 16, fontSize: 7.5, bold: true, color: vurguRenk, alignment: .left, ctx: pdf.cgContext)
                y += 20 + 6
                inner()
                y += 8
                pdf.cgContext.setStrokeColor(vurguRenk.withAlphaComponent(0.16).cgColor)
                pdf.cgContext.setLineWidth(0.7)
                pdf.cgContext.stroke(CGRect(x: lm, y: startY, width: cW, height: y - startY))
                y += 12
            }
            func sat(_ t: String, bold: Bool = false, indent: CGFloat = 0) -> CGFloat {
                let h = CVRenderKit.measureText(t, width: cW - 16 - indent, fontSize: 9.5, bold: bold)
                ens(h + 4)
                CVRenderKit.drawText(t, x: lm + 8 + indent, y: y, width: cW - 16 - indent, fontSize: 9.5, bold: bold, color: UIColor(white: bold ? 0.1 : 0.25, alpha: 1), alignment: .left, ctx: pdf.cgContext)
                y += h + 3
                return h + 3
            }

            if !draft.ozet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { kart("Özet") { _ = sat(draft.ozet) } }
            if !draft.isDeneyimleri.isEmpty {
                kart("İş Deneyimi") {
                    for d in draft.isDeneyimleri {
                        _ = sat("\(d.unvan)\(d.sirket.isEmpty ? "" : " — \(d.sirket)")", bold: true)
                        let t = CVRenderKit.tarihAralik(baslangic: d.baslangic, bitis: d.bitis, devamEdiyor: d.halaDevamEdiyor)
                        if !t.isEmpty { _ = sat(t, indent: 8) }
                        if !d.aciklama.isEmpty { _ = sat(d.aciklama, indent: 8) }
                        y += 3
                    }
                }
            }
            if !draft.egitimler.isEmpty {
                kart("Eğitim") {
                    for e in draft.egitimler {
                        _ = sat(e.okul, bold: true)
                        if !e.bolum.isEmpty { _ = sat(e.bolum, indent: 8) }
                        let t = CVRenderKit.tarihAralik(baslangic: e.baslangic, bitis: e.bitis)
                        if !t.isEmpty { _ = sat(t, indent: 8) }
                        y += 3
                    }
                }
            }
            if !draft.yetenekler.isEmpty || !draft.diller.isEmpty {
                ens(100)
                let hW = (cW - 10) / 2, col2X = lm + hW + 10
                let startY2 = y
                if !draft.yetenekler.isEmpty {
                    CVRenderKit.fillRect(CGRect(x: lm, y: y, width: hW, height: 18), color: vurguRenk.withAlphaComponent(0.09), ctx: pdf.cgContext)
                    CVRenderKit.drawText("YETENEKler", x: lm + 6, y: y + 4, width: hW - 12, fontSize: 7, bold: true, color: vurguRenk, alignment: .left, ctx: pdf.cgContext)
                    var subY = y + 22
                    for yy in draft.yetenekler.prefix(10) {
                        CVRenderKit.drawText("· \(yy)", x: lm + 6, y: subY, width: hW - 12, fontSize: 8.5, color: UIColor(white: 0.25, alpha: 1), alignment: .left, ctx: pdf.cgContext)
                        subY += CVRenderKit.measureText("· \(yy)", width: hW - 12, fontSize: 8.5) + 2
                    }
                    pdf.cgContext.setStrokeColor(vurguRenk.withAlphaComponent(0.14).cgColor)
                    pdf.cgContext.setLineWidth(0.6)
                    pdf.cgContext.stroke(CGRect(x: lm, y: startY2, width: hW, height: subY - startY2 + 6))
                }
                if !draft.diller.isEmpty {
                    CVRenderKit.fillRect(CGRect(x: col2X, y: startY2, width: hW, height: 18), color: vurguRenk.withAlphaComponent(0.09), ctx: pdf.cgContext)
                    CVRenderKit.drawText("DİLLER", x: col2X + 6, y: startY2 + 4, width: hW - 12, fontSize: 7, bold: true, color: vurguRenk, alignment: .left, ctx: pdf.cgContext)
                    var subY = startY2 + 22
                    for d in draft.diller {
                        CVRenderKit.drawText("\(d.dilAdi)\(d.seviye.isEmpty ? "" : "  \(d.seviye)")", x: col2X + 6, y: subY, width: hW - 12, fontSize: 8.5, color: UIColor(white: 0.25, alpha: 1), alignment: .left, ctx: pdf.cgContext)
                        subY += 14
                    }
                    pdf.cgContext.setStrokeColor(vurguRenk.withAlphaComponent(0.14).cgColor)
                    pdf.cgContext.setLineWidth(0.6)
                    pdf.cgContext.stroke(CGRect(x: col2X, y: startY2, width: hW, height: subY - startY2 + 6))
                }
                y = startY2 + 80
            }
        }
    }
}

// MARK: ── FORMAT 5: CREATIVE ───────────────────────────────────
enum CVRendererCreative: CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk: UIColor) -> Data? {
        let W = CVRenderKit.pageWidth, H = CVRenderKit.pageHeight
        let lm: CGFloat = 48, rm: CGFloat = 48, cW = W - lm - rm
        let nameH: CGFloat = 108

        return UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: W, height: H)).pdfData { pdf in
            var y: CGFloat = 0

            func newPage() {
                pdf.beginPage(withBounds: CGRect(x: 0, y: 0, width: W, height: H), pageInfo: [:])
                CVRenderKit.fillRect(CGRect(x: 0, y: 0, width: W, height: 3), color: vurguRenk, ctx: pdf.cgContext)
                y = 22
            }
            func ens(_ h: CGFloat) { if y + h > H - 36 { newPage() } }

            pdf.beginPage(withBounds: CGRect(x: 0, y: 0, width: W, height: H), pageInfo: [:])
            let cg = pdf.cgContext

            CVRenderKit.fillRect(CGRect(x: 0, y: 0, width: W, height: nameH), color: vurguRenk, ctx: cg)
            cg.setStrokeColor(UIColor.white.withAlphaComponent(0.06).cgColor)
            cg.setLineWidth(35)
            cg.move(to: CGPoint(x: W * 0.58, y: 0)); cg.addLine(to: CGPoint(x: W * 0.82, y: nameH)); cg.strokePath()

            var nX = lm
            if let ph = CVRenderKit.loadPhoto() { CVRenderKit.drawPhoto(ph, cx: W - rm - 32, cy: nameH / 2, radius: 40, ctx: cg); nX = lm }
            CVRenderKit.drawText(draft.kisisel.adSoyad, x: nX, y: 18, width: W - lm * 2 - 80, fontSize: 24, bold: true, color: .white, alignment: .left, ctx: cg)
            if let u = draft.isDeneyimleri.first?.unvan, !u.isEmpty { CVRenderKit.drawText(u, x: nX, y: 54, width: W - lm * 2 - 80, fontSize: 10, color: UIColor.white.withAlphaComponent(0.78), alignment: .left, ctx: cg) }
            let k = draft.kisisel
            CVRenderKit.drawText([k.email, k.telefon, k.sehirIlce].filter { !$0.isEmpty }.joined(separator: "   ·   "), x: lm, y: 80, width: cW, fontSize: 8, color: UIColor.white.withAlphaComponent(0.62), alignment: .left, ctx: cg)
            y = nameH + 20

            func sec(_ t: String) {
                ens(24); y += 4
                CVRenderKit.fillRect(CGRect(x: lm, y: y, width: 3, height: 15), color: vurguRenk, ctx: pdf.cgContext)
                CVRenderKit.drawText(t, x: lm + 10, y: y, width: cW - 10, fontSize: 11, bold: true, color: UIColor(white: 0.12, alpha: 1), alignment: .left, ctx: pdf.cgContext)
                y += 20
            }
            func bd(_ t: String, sz: CGFloat = 9.5, bold: Bool = false, color: UIColor = UIColor(white: 0.22, alpha: 1), indent: CGFloat = 0) {
                let h = CVRenderKit.measureText(t, width: cW - indent, fontSize: sz, bold: bold)
                ens(h)
                CVRenderKit.drawText(t, x: lm + indent, y: y, width: cW - indent, fontSize: sz, bold: bold, color: color, alignment: .justified, ctx: pdf.cgContext)
                y += h + 3
            }

            if !draft.ozet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { sec("Hakkımda"); bd(draft.ozet); y += 6 }
            if !draft.isDeneyimleri.isEmpty {
                sec("Deneyim")
                for d in draft.isDeneyimleri {
                    ens(44)
                    let tarih = CVRenderKit.tarihAralik(baslangic: d.baslangic, bitis: d.bitis, devamEdiyor: d.halaDevamEdiyor)
                    let rowH: CGFloat = 20
                    CVRenderKit.fillRect(CGRect(x: lm, y: y, width: cW, height: rowH), color: vurguRenk.withAlphaComponent(0.07), ctx: pdf.cgContext)
                    CVRenderKit.drawText("\(d.unvan)\(d.sirket.isEmpty ? "" : " · \(d.sirket)")", x: lm + 6, y: y + 5, width: cW - 100, fontSize: 9.5, bold: true, color: UIColor(white: 0.12, alpha: 1), alignment: .left, ctx: pdf.cgContext)
                    if !tarih.isEmpty { CVRenderKit.drawText(tarih, x: lm, y: y + 5, width: cW - 6, fontSize: 8, color: UIColor(white: 0.52, alpha: 1), alignment: .right, ctx: pdf.cgContext) }
                    y += rowH + 4
                    if !d.aciklama.isEmpty { bd(d.aciklama, indent: 8) }
                    y += 4
                }
            }
            if !draft.egitimler.isEmpty {
                sec("Eğitim")
                for e in draft.egitimler { bd(e.okul, bold: true); if !e.bolum.isEmpty { bd(e.bolum, indent: 10) }; y += 4 }
            }
            if !draft.yetenekler.isEmpty {
                sec("Yetenekler")
                var cx = lm
                for yy in draft.yetenekler {
                    let cW2 = CVRenderKit.measureText(yy, width: 300, fontSize: 8.5) + 18
                    if cx + cW2 > W - rm { cx = lm; y += 19 }
                    CVRenderKit.fillRect(CGRect(x: cx, y: y, width: cW2, height: 16), color: vurguRenk.withAlphaComponent(0.09), ctx: pdf.cgContext)
                    CVRenderKit.drawText(yy, x: cx + 7, y: y + 3, width: cW2 - 14, fontSize: 8.5, color: vurguRenk, alignment: .left, ctx: pdf.cgContext)
                    cx += cW2 + 5
                }
                y += 22
            }
            if !draft.diller.isEmpty { sec("Diller"); bd(draft.diller.map { "\($0.dilAdi)\($0.seviye.isEmpty ? "" : " · \($0.seviye)")" }.joined(separator: "   ")) }
        }
    }
}

// MARK: ── FORMAT 6: ACADEMIC ───────────────────────────────────
enum CVRendererAcademic: CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk _: UIColor) -> Data? {
        let W = CVRenderKit.pageWidth, H = CVRenderKit.pageHeight
        let lm: CGFloat = 58, rm: CGFloat = 58, cW = W - lm - rm

        return UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: W, height: H)).pdfData { pdf in
            var y: CGFloat = 42

            func newPage() { pdf.beginPage(withBounds: CGRect(x: 0, y: 0, width: W, height: H), pageInfo: [:]); y = 42 }
            func ens(_ h: CGFloat) { if y + h > H - 42 { newPage() } }

            pdf.beginPage(withBounds: CGRect(x: 0, y: 0, width: W, height: H), pageInfo: [:])
            let cg = pdf.cgContext

            CVRenderKit.drawLine(x1: lm, y1: y, x2: W - rm, y2: y, color: UIColor(white: 0.1, alpha: 1), width: 2.2, ctx: cg)
            CVRenderKit.drawLine(x1: lm, y1: y + 4, x2: W - rm, y2: y + 4, color: UIColor(white: 0.1, alpha: 1), width: 0.5, ctx: cg)
            y += 16

            let adH = CVRenderKit.measureText(draft.kisisel.adSoyad.uppercased(), width: cW, fontSize: 17, bold: true)
            CVRenderKit.drawText(draft.kisisel.adSoyad.uppercased(), x: lm, y: y, width: cW, fontSize: 17, bold: true, color: UIColor(white: 0.08, alpha: 1), alignment: .center, ctx: cg)
            y += adH + 5
            let k = draft.kisisel
            let kt = [k.email, k.telefon, k.sehirIlce, k.linkedIn].filter { !$0.isEmpty }.joined(separator: "  |  ")
            CVRenderKit.drawText(kt, x: lm, y: y, width: cW, fontSize: 8, color: UIColor(white: 0.45, alpha: 1), alignment: .center, ctx: cg)
            y += 13
            CVRenderKit.drawLine(x1: lm, y1: y, x2: W - rm, y2: y, color: UIColor(white: 0.1, alpha: 1), width: 0.5, ctx: cg)
            CVRenderKit.drawLine(x1: lm, y1: y + 3, x2: W - rm, y2: y + 3, color: UIColor(white: 0.1, alpha: 1), width: 2, ctx: cg)
            y += 18

            func sec(_ t: String) {
                ens(24); y += 6
                CVRenderKit.drawText(t.uppercased(), x: lm, y: y, width: cW, fontSize: 8.5, bold: true, color: UIColor(white: 0.15, alpha: 1), alignment: .left, ctx: pdf.cgContext)
                y += CVRenderKit.measureText(t.uppercased(), width: cW, fontSize: 8.5, bold: true) + 2
                CVRenderKit.drawLine(x1: lm, y1: y, x2: W - rm, y2: y, color: UIColor(white: 0.25, alpha: 1), width: 0.5, ctx: pdf.cgContext)
                y += 7
            }
            func bd(_ t: String, sz: CGFloat = 9.5, bold: Bool = false, indent: CGFloat = 0) {
                let h = CVRenderKit.measureText(t, width: cW - indent, fontSize: sz, bold: bold)
                ens(h)
                CVRenderKit.drawText(t, x: lm + indent, y: y, width: cW - indent, fontSize: sz, bold: bold, color: UIColor(white: bold ? 0.1 : 0.25, alpha: 1), alignment: .justified, ctx: pdf.cgContext)
                y += h + 3
            }

            if !draft.ozet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { sec("Özet"); bd(draft.ozet); y += 6 }
            if !draft.egitimler.isEmpty {
                sec("Eğitim")
                for e in draft.egitimler {
                    ens(44)
                    let t = CVRenderKit.tarihAralik(baslangic: e.baslangic, bitis: e.bitis)
                    if !t.isEmpty { CVRenderKit.drawText(t, x: W - rm - 84, y: y, width: 84, fontSize: 8, color: UIColor(white: 0.5, alpha: 1), alignment: .right, ctx: pdf.cgContext) }
                    bd(e.okul, bold: true)
                    if !e.bolum.isEmpty { bd("\(e.bolum)\(e.derece.isEmpty ? "" : ", \(e.derece)")", indent: 14) }
                    if !e.diplomaNotu.isEmpty { bd("Not: \(e.diplomaNotu)", sz: 8.5, indent: 14) }
                    y += 4
                }
            }
            if !draft.isDeneyimleri.isEmpty {
                sec("Mesleki Deneyim")
                for d in draft.isDeneyimleri {
                    ens(44)
                    let tarih = CVRenderKit.tarihAralik(baslangic: d.baslangic, bitis: d.bitis, devamEdiyor: d.halaDevamEdiyor)
                    if !tarih.isEmpty { CVRenderKit.drawText(tarih, x: W - rm - 84, y: y, width: 84, fontSize: 8, color: UIColor(white: 0.5, alpha: 1), alignment: .right, ctx: pdf.cgContext) }
                    bd("\(d.unvan)\(d.sirket.isEmpty ? "" : ", \(d.sirket)")", bold: true)
                    if !d.aciklama.isEmpty { bd(d.aciklama, indent: 14) }
                    y += 5
                }
            }
            if !draft.projeler.isEmpty {
                sec("Projeler")
                for p in draft.projeler {
                    bd("• \(p.projeAdi)\(p.tarih.isEmpty ? "" : " (\(p.tarih))")", bold: true)
                    if !p.aciklama.isEmpty { bd(p.aciklama, indent: 12) }
                    y += 3
                }
            }
            if !draft.yetenekler.isEmpty || !draft.diller.isEmpty {
                sec("Yetkinlikler")
                if !draft.yetenekler.isEmpty { bd("Teknik: " + draft.yetenekler.joined(separator: ", ")) }
                if !draft.diller.isEmpty { bd("Diller: " + draft.diller.map { "\($0.dilAdi)\($0.seviye.isEmpty ? "" : " (\($0.seviye))")" }.joined(separator: ", ")) }
            }
            if !draft.sertifikalar.isEmpty {
                sec("Sertifikalar")
                for s in draft.sertifikalar { bd("• \(s.ad)\(s.verenKurum.isEmpty ? "" : " — \(s.verenKurum)")\(s.tarih.isEmpty ? "" : " (\(s.tarih))")") }
            }
            CVRenderKit.drawLine(x1: lm, y1: H - 30, x2: W - rm, y2: H - 30, color: UIColor(white: 0.1, alpha: 1), width: 1.5, ctx: pdf.cgContext)
        }
    }
}
