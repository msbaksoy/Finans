// CVRenderers_NEW.swift — 10 yeni format (tam içerik ENTEGRASYON rehberindeki ile değiştirilebilir)
import UIKit
import CoreText

enum CVFormatSecici_NEW {
    static let newFormats: [CVFormatTanim] = [
        CVFormatTanim(id: "elegant", isim: "Elegant", onizlemeRenk: UIColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1), render: CVRendererElegant.render),
        CVFormatTanim(id: "modern", isim: "Modern", onizlemeRenk: UIColor(red: 0.0, green: 0.45, blue: 0.75, alpha: 1), render: CVRendererModern.render),
        CVFormatTanim(id: "infographic", isim: "Infographic", onizlemeRenk: UIColor(red: 0.95, green: 0.35, blue: 0.15, alpha: 1), render: CVRendererInfogr.render),
        CVFormatTanim(id: "compact", isim: "Compact", onizlemeRenk: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1), render: CVRendererCompact.render),
        CVFormatTanim(id: "monochrome", isim: "Monochrome", onizlemeRenk: UIColor.black, render: CVRendererMono.render),
        CVFormatTanim(id: "twocolumn", isim: "Two Column", onizlemeRenk: UIColor(red: 0.0, green: 0.55, blue: 0.50, alpha: 1), render: CVRendererTwoCol.render),
        CVFormatTanim(id: "devjson", isim: "Dev JSON", onizlemeRenk: UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1), render: CVRendererDevJSON.render),
        CVFormatTanim(id: "devterminal", isim: "Dev Terminal", onizlemeRenk: UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1), render: CVRendererDevTerminal.render),
        CVFormatTanim(id: "gradient", isim: "Gradient", onizlemeRenk: UIColor(red: 0.60, green: 0.20, blue: 0.80, alpha: 1), render: CVRendererGradient.render),
        CVFormatTanim(id: "swiss", isim: "Swiss", onizlemeRenk: UIColor(red: 0.85, green: 0.10, blue: 0.10, alpha: 1), render: CVRendererSwiss.render),
    ]
}

private func newPageState(
    _ pdf: UIGraphicsPDFRendererContext,
    W: CGFloat, H: CGFloat,
    topPad: CGFloat = 40,
    onNewPage: @escaping (CGFloat) -> Void = { _ in }
) -> NewPS {
    NewPS(pdf: pdf, W: W, H: H, topPad: topPad, onNewPage: onNewPage)
}

private final class NewPS {
    let pdf: UIGraphicsPDFRendererContext
    let W: CGFloat, H: CGFloat
    var y: CGFloat
    let topPad: CGFloat
    let onNewPage: (CGFloat) -> Void

    init(pdf: UIGraphicsPDFRendererContext, W: CGFloat, H: CGFloat,
         topPad: CGFloat, onNewPage: @escaping (CGFloat) -> Void) {
        self.pdf = pdf; self.W = W; self.H = H
        self.y = topPad; self.topPad = topPad; self.onNewPage = onNewPage
    }

    func ensure(_ need: CGFloat) {
        if y + need > H - 36 {
            pdf.beginPage(withBounds: CGRect(x: 0, y: 0, width: W, height: H), pageInfo: [:])
            y = topPad
            onNewPage(y)
        }
    }

    func text(_ t: String, x: CGFloat, w: CGFloat, sz: CGFloat = 9.5,
              bold: Bool = false, color: UIColor = UIColor(white: 0.15, alpha: 1),
              align: NSTextAlignment = .justified) {
        let h = CVRenderKit.measureText(t, width: w, fontSize: sz, bold: bold)
        ensure(h)
        CVRenderKit.drawText(t, x: x, y: y, width: w, fontSize: sz,
                             bold: bold, color: color, alignment: align,
                             ctx: pdf.cgContext)
        y += h + 3
    }

    func sec(_ t: String, x: CGFloat, w: CGFloat, renk: UIColor) {
        ensure(26); y += 8
        CVRenderKit.drawText(t.uppercased(), x: x, y: y, width: w, fontSize: 8.5,
                             bold: true, color: renk, alignment: .left, ctx: pdf.cgContext)
        y += 13
        CVRenderKit.fillRect(CGRect(x: x, y: y, width: w, height: 0.8),
                             color: renk.withAlphaComponent(0.20), ctx: pdf.cgContext)
        y += 6
    }
}

// ============================================================
// FORMAT 1: ELEGANT — İnce çerçeve, zarif
// ============================================================
enum CVRendererElegant: CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk: UIColor) -> Data? {
        let W = CVRenderKit.pageWidth, H = CVRenderKit.pageHeight
        let lm: CGFloat = 56, rm: CGFloat = 56, cW = W - lm - rm

        return UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: W, height: H)).pdfData { pdf in
            let ps = newPageState(pdf, W: W, H: H, topPad: 50) { _ in
                let cg = pdf.cgContext
                cg.setStrokeColor(vurguRenk.withAlphaComponent(0.3).cgColor)
                cg.setLineWidth(0.5)
                cg.stroke(CGRect(x: 20, y: 20, width: W - 40, height: H - 40))
            }

            pdf.beginPage(withBounds: CGRect(x: 0, y: 0, width: W, height: H), pageInfo: [:])
            let cg = pdf.cgContext

            cg.setStrokeColor(vurguRenk.withAlphaComponent(0.3).cgColor)
            cg.setLineWidth(0.5)
            cg.stroke(CGRect(x: 20, y: 20, width: W - 40, height: H - 40))

            if let ph = CVRenderKit.loadPhoto() {
                CVRenderKit.drawPhoto(ph, cx: W / 2, cy: 60, radius: 40, ctx: cg)
                ps.y = 100
            }

            let adH = CVRenderKit.drawText(draft.kisisel.adSoyad, x: lm, y: ps.y,
                                           width: cW, fontSize: 20, bold: true,
                                           color: vurguRenk, alignment: .center, ctx: cg)
            ps.y += adH + 4

            if let u = draft.isDeneyimleri.first?.unvan, !u.isEmpty {
                let uH = CVRenderKit.drawText(u, x: lm, y: ps.y, width: cW,
                                              fontSize: 10, color: UIColor(white: 0.4, alpha: 1),
                                              alignment: .center, ctx: cg)
                ps.y += uH + 6
            }

            let k = draft.kisisel
            let kt = [k.email, k.telefon, k.sehirIlce, k.linkedIn].filter { !$0.isEmpty }.joined(separator: "  ·  ")
            CVRenderKit.drawText(kt, x: lm, y: ps.y, width: cW, fontSize: 8,
                                 color: UIColor(white: 0.5, alpha: 1), alignment: .center, ctx: cg)
            ps.y += 16

            CVRenderKit.drawLine(x1: lm + 60, y1: ps.y, x2: W - rm - 60, y2: ps.y,
                                 color: vurguRenk.withAlphaComponent(0.3), width: 0.5, ctx: cg)
            ps.y += 16

            if !draft.ozet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ps.sec("Profesyonel Özet", x: lm, w: cW, renk: vurguRenk)
                ps.text(draft.ozet, x: lm, w: cW, color: UIColor(white: 0.25, alpha: 1))
                ps.y += 6
            }

            if !draft.isDeneyimleri.isEmpty {
                ps.sec("İş Deneyimi", x: lm, w: cW, renk: vurguRenk)
                for d in draft.isDeneyimleri {
                    ps.ensure(44)
                    let tarih = CVRenderKit.tarihAralik(baslangic: d.baslangic, bitis: d.bitis, devamEdiyor: d.halaDevamEdiyor)
                    if !tarih.isEmpty {
                        CVRenderKit.drawText(tarih, x: W - rm - 90, y: ps.y, width: 90,
                                             fontSize: 8, color: UIColor(white: 0.5, alpha: 1),
                                             alignment: .right, ctx: cg)
                    }
                    ps.text("\(d.unvan)\(d.sirket.isEmpty ? "" : " — \(d.sirket)")", x: lm, w: cW - 92, bold: true)
                    if !d.aciklama.isEmpty { ps.text(d.aciklama, x: lm + 12, w: cW - 12, sz: 9, color: UIColor(white: 0.3, alpha: 1)) }
                    ps.y += 5
                }
            }

            if !draft.egitimler.isEmpty {
                ps.sec("Eğitim", x: lm, w: cW, renk: vurguRenk)
                for e in draft.egitimler {
                    ps.ensure(36)
                    ps.text(e.okul, x: lm, w: cW, bold: true)
                    if !e.bolum.isEmpty { ps.text(e.bolum, x: lm + 12, w: cW - 12, sz: 9) }
                    ps.y += 4
                }
            }

            if !draft.yetenekler.isEmpty {
                ps.sec("Yetenekler", x: lm, w: cW, renk: vurguRenk)
                ps.text(draft.yetenekler.joined(separator: "  ·  "), x: lm, w: cW)
            }
            if !draft.diller.isEmpty {
                ps.sec("Diller", x: lm, w: cW, renk: vurguRenk)
                ps.text(draft.diller.map { "\($0.dilAdi)\($0.seviye.isEmpty ? "" : " (\($0.seviye))")" }.joined(separator: "   "), x: lm, w: cW)
            }
        }
    }
}

// Aşağıdaki şablonlar ENTEGRASYON_REHBERI içindeki tam PDF tasarımlarıyla genişletilebilir.
// Şimdilik ayrı görünümlü PDF üretmek için mevcut renderer’lara yönlendirilir.

enum CVRendererModern: CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk: UIColor) -> Data? {
        CVRendererMinimal.render(draft: draft, vurguRenk: vurguRenk)
    }
}

enum CVRendererInfogr: CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk: UIColor) -> Data? {
        CVRendererCard.render(draft: draft, vurguRenk: vurguRenk)
    }
}

enum CVRendererCompact: CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk: UIColor) -> Data? {
        CVRendererMinimal.render(draft: draft, vurguRenk: vurguRenk)
    }
}

enum CVRendererMono: CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk: UIColor) -> Data? {
        CVRendererAcademic.render(draft: draft, vurguRenk: vurguRenk)
    }
}

enum CVRendererTwoCol: CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk: UIColor) -> Data? {
        CVRendererMinimal.render(draft: draft, vurguRenk: vurguRenk)
    }
}

enum CVRendererDevJSON: CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk: UIColor) -> Data? {
        CVRendererCreative.render(draft: draft, vurguRenk: vurguRenk)
    }
}

enum CVRendererDevTerminal: CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk: UIColor) -> Data? {
        CVRendererCreative.render(draft: draft, vurguRenk: vurguRenk)
    }
}

enum CVRendererGradient: CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk: UIColor) -> Data? {
        CVRendererExecutive.render(draft: draft, vurguRenk: vurguRenk)
    }
}

enum CVRendererSwiss: CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk: UIColor) -> Data? {
        CVRendererTimeline.render(draft: draft, vurguRenk: vurguRenk)
    }
}
