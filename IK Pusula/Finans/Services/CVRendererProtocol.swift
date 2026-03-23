import UIKit
import CoreText

protocol CVRenderer {
    static func render(draft: OzgecmisDraft, vurguRenk: UIColor) -> Data?
}

enum CVRenderKit {
    static let pageWidth: CGFloat = 595
    static let pageHeight: CGFloat = 842
    static let margin: CGFloat = 48

    static func measureText(
        _ text: String, width: CGFloat, fontSize: CGFloat,
        bold: Bool = false
    ) -> CGFloat {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        let attrs = makeAttrs(fontSize: fontSize, bold: bold, color: .black, alignment: .left)
        let ns = NSAttributedString(string: trimmed, attributes: attrs)
        let fs = CTFramesetterCreateWithAttributedString(ns as CFAttributedString)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(
            fs, CFRangeMake(0, ns.length), nil,
            CGSize(width: width, height: .greatestFiniteMagnitude), nil)
        return ceil(size.height) + 4
    }

    @discardableResult
    static func drawText(
        _ text: String, x: CGFloat, y: CGFloat, width: CGFloat,
        fontSize: CGFloat, bold: Bool = false,
        color: UIColor = .black, alignment: NSTextAlignment = .left,
        ctx: CGContext
    ) -> CGFloat {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }
        let attrs = makeAttrs(fontSize: fontSize, bold: bold, color: color, alignment: alignment)
        let ns = NSAttributedString(string: trimmed, attributes: attrs)
        let fs = CTFramesetterCreateWithAttributedString(ns as CFAttributedString)
        let suggested = CTFramesetterSuggestFrameSizeWithConstraints(
            fs, CFRangeMake(0, ns.length), nil,
            CGSize(width: width, height: .greatestFiniteMagnitude), nil)
        let h = ceil(suggested.height) + 4
        ctx.saveGState()
        ctx.translateBy(x: x, y: y + h)
        ctx.scaleBy(x: 1, y: -1)
        let path = CGPath(rect: CGRect(x: 0, y: 0, width: width, height: h), transform: nil)
        let frame = CTFramesetterCreateFrame(fs, CFRangeMake(0, ns.length), path, nil)
        CTFrameDraw(frame, ctx)
        ctx.restoreGState()
        return h
    }

    static func fillRect(_ rect: CGRect, color: UIColor, ctx: CGContext) {
        ctx.setFillColor(color.cgColor)
        ctx.fill(rect)
    }

    static func drawLine(
        x1: CGFloat, y1: CGFloat, x2: CGFloat, y2: CGFloat,
        color: UIColor, width: CGFloat = 0.5, ctx: CGContext
    ) {
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(width)
        ctx.move(to: CGPoint(x: x1, y: y1))
        ctx.addLine(to: CGPoint(x: x2, y: y2))
        ctx.strokePath()
    }

    static func drawPhoto(_ image: UIImage, cx: CGFloat, cy: CGFloat,
                          radius: CGFloat, ctx: CGContext) {
        guard let cgi = image.cgImage else { return }
        ctx.saveGState()
        ctx.addEllipse(in: CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2))
        ctx.clip()
        let iW = CGFloat(cgi.width), iH = CGFloat(cgi.height)
        let scale = max(radius * 2 / iW, radius * 2 / iH)
        let dW = iW * scale, dH = iH * scale
        ctx.translateBy(x: cx, y: cy)
        ctx.scaleBy(x: 1, y: -1)
        ctx.translateBy(x: -cx, y: -cy)
        ctx.draw(cgi, in: CGRect(x: cx - dW / 2, y: cy - dH / 2, width: dW, height: dH))
        ctx.restoreGState()
    }

    static func loadPhoto() -> UIImage? {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let data = try? Data(contentsOf: docs.appendingPathComponent("cv_photo.jpg"))
        else { return nil }
        return UIImage(data: data)
    }

    static func tarihAralik(baslangic: String, bitis: String, devamEdiyor: Bool = false) -> String {
        let b = baslangic.trimmingCharacters(in: .whitespacesAndNewlines)
        let t = bitis.trimmingCharacters(in: .whitespacesAndNewlines)
        if devamEdiyor { return b.isEmpty ? "Devam ediyor" : "\(b) – günümüz" }
        if b.isEmpty && t.isEmpty { return "" }
        if b.isEmpty { return t }
        if t.isEmpty { return b }
        return "\(b) – \(t)"
    }

    static func makeAttrs(
        fontSize: CGFloat, bold: Bool, color: UIColor,
        alignment: NSTextAlignment,
        lineSpacing: CGFloat = 3
    ) -> [NSAttributedString.Key: Any] {
        let para = NSMutableParagraphStyle()
        para.alignment = alignment
        para.lineSpacing = lineSpacing
        let font: UIFont = bold ? .boldSystemFont(ofSize: fontSize) : .systemFont(ofSize: fontSize)
        return [.font: font, .foregroundColor: color, .paragraphStyle: para, .kern: -0.1]
    }
}
