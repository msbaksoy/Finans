import SwiftUI
import UIKit

// MARK: - Sayfa bölme ve yükseklik tahmini
private enum CVPagination {
    static let pageHeight: CGFloat = 842
    static let rightColWidth: CGFloat = (595 * 0.70) - 48 // padding
    static let rightColMaxHeight: CGFloat = 750 // 1. sayfa sağ kolon için yaklaşık alan
    static let leftColWidth: CGFloat = (595 * 0.30) - 40
    static let leftColPadding: CGFloat = 20
    static let ozetLineSpacing: CGFloat = 3
    
    /// Sol panelde Özet'ten önce kullanılan yükseklik — dinamik (Diller, Kişisel Bilgiler uzunluğuna göre)
    private static func leftPanelHeightBeforeOzet(model: CVModel) -> CGFloat {
        let font10 = UIFont.systemFont(ofSize: 10)
        var h: CGFloat = leftColPadding
        h += 88 + 4 + 12 // fotoğraf + boşluk
        h += 10 + 18 + 8 // Kişisel Bilgiler başlık + ad
        if !model.email.isEmpty { h += 15 }
        if !model.telefon.isEmpty { h += 15 }
        if !model.adres.isEmpty { h += 15 }
        if !model.dogumTarihi.isEmpty { h += 15 }
        if !model.uyruk.isEmpty { h += 15 }
        h += 1 // divider
        if !model.diller.trimmingCharacters(in: .whitespaces).isEmpty {
            h += 10 + 6
            h += textHeight(model.diller, font: font10, width: leftColWidth - 20)
            h += 12 // padding vertical
            h += 6
        }
        h += 1 // divider
        h += 10 + 8 // Özet başlık + spacing
        h += leftColPadding
        return h
    }
    
    static func estimateRightColumnHeight(
        egitimler: [EgitimGirisi],
        deneyimler: [DeneyimGirisi],
        yetkinlikler: String,
        sertifikalar: String
    ) -> CGFloat {
        let font10 = UIFont.systemFont(ofSize: 10)
        let font11 = UIFont.systemFont(ofSize: 11)
        let font12 = UIFont.systemFont(ofSize: 12)
        let w = rightColWidth
        
        var h: CGFloat = 24
        let sectionSpacing: CGFloat = 20
        let blockSpacing: CGFloat = 16
        
        if !egitimler.isEmpty {
            h += 12 + font12.lineHeight
            for _ in egitimler {
                h += 4
                h += font10.lineHeight + font11.lineHeight + font10.lineHeight
            }
            h += sectionSpacing
        }
        
        if !deneyimler.isEmpty {
            h += blockSpacing + font12.lineHeight
            for d in deneyimler {
                h += 6
                h += font10.lineHeight
                h += font11.lineHeight + font10.lineHeight
                let lines = d.gorevler.split(separator: "\n")
                for ln in lines {
                    h += 6 + textHeight(String(ln), font: font10, width: w - 30)
                }
                h += 10
            }
            h += sectionSpacing
        }
        
        if !yetkinlikler.trimmingCharacters(in: .whitespaces).isEmpty {
            h += 8 + font12.lineHeight
            for line in yetkinlikler.split(separator: "\n") {
                let s = String(line).trimmingCharacters(in: .whitespaces)
                if !s.isEmpty { h += 6 + textHeight(s, font: font10, width: w) }
            }
            h += sectionSpacing
        }
        
        if !sertifikalar.trimmingCharacters(in: .whitespaces).isEmpty {
            h += 8 + font12.lineHeight
            for line in sertifikalar.split(separator: "\n") {
                let s = String(line).trimmingCharacters(in: .whitespaces)
                if !s.isEmpty { h += 6 + textHeight(s, font: font10, width: w) }
            }
        }
        h += 24
        return h
    }
    
    private static func textHeight(_ s: String, font: UIFont, width: CGFloat) -> CGFloat {
        let ns = s as NSString
        let rect = ns.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                   options: [.usesLineFragmentOrigin, .usesFontLeading],
                                   attributes: [.font: font], context: nil)
        return ceil(rect.height)
    }
    
    /// Özet metninin yüksekliği — view'da lineSpacing(3) kullanıldığı için eklenir
    private static func ozetTextHeight(_ s: String, font: UIFont, width: CGFloat) -> CGFloat {
        let h = textHeight(s, font: font, width: width)
        guard h > 0 else { return 0 }
        let lineCount = max(1, Int(ceil(h / font.lineHeight)))
        let extra = CGFloat(lineCount - 1) * ozetLineSpacing
        return h + extra
    }
    
    /// Özet metnini maxHeight'a sığacak şekilde böler; devam 2. sayfada (lineSpacing dahil)
    private static func splitOzetText(_ text: String, font: UIFont, width: CGFloat, maxHeight: CGFloat) -> (part1: String, part2: String) {
        let t = text.trimmingCharacters(in: .whitespaces)
        if t.isEmpty { return ("", "") }
        let fullH = ozetTextHeight(t, font: font, width: width)
        if fullH <= maxHeight { return (t, "") }
        let words = t.split(separator: " ", omittingEmptySubsequences: false).map { String($0) }
        if words.isEmpty { return (t, "") }
        var part1Words: [String] = []
        for w in words {
            let candidate = (part1Words + [w]).joined(separator: " ")
            let nh = ozetTextHeight(candidate, font: font, width: width)
            if nh > maxHeight { break }
            part1Words.append(w)
        }
        let p1 = part1Words.joined(separator: " ").trimmingCharacters(in: .whitespaces)
        let p2 = Array(words.dropFirst(part1Words.count)).joined(separator: " ").trimmingCharacters(in: .whitespaces)
        return (p1, p2)
    }
    
    struct PageSplit {
        let page1Ozet: String
        let page2Ozet: String
        let page1Deneyimler: [DeneyimGirisi]
        let page1Yetkinlikler: String
        let page1Sertifikalar: String
        let page2Deneyimler: [DeneyimGirisi]
        let page2Yetkinlikler: String
        let page2Sertifikalar: String
        let needsPage2: Bool
    }
    
    static func split(model: CVModel) -> PageSplit {
        let font10 = UIFont.systemFont(ofSize: 10)
        let usedBeforeOzet = leftPanelHeightBeforeOzet(model: model)
        let ozetMaxHeight = max(60, pageHeight - usedBeforeOzet - 20) // 20pt güvenlik payı
        let (page1Ozet, page2Ozet) = splitOzetText(
            model.ozet,
            font: font10,
            width: leftColWidth,
            maxHeight: ozetMaxHeight
        )
        
        let sorted = model.deneyimler.sorted { a, b in
            let ma = a.baslangicAy.count == 1 ? "0" + a.baslangicAy : a.baslangicAy
            let mb = b.baslangicAy.count == 1 ? "0" + b.baslangicAy : b.baslangicAy
            let ya = Int(a.baslangicYil + ma) ?? 0
            let yb = Int(b.baslangicYil + mb) ?? 0
            return ya > yb
        }
        var total: CGFloat = 24
        let font11 = UIFont.systemFont(ofSize: 11)
        let font12 = UIFont.systemFont(ofSize: 12)
        let w = rightColWidth
        let sectionSpacing: CGFloat = 20
        let blockSpacing: CGFloat = 16
        
        if !model.egitimler.isEmpty {
            total += 12 + font12.lineHeight
            for _ in model.egitimler {
                total += 4 + font10.lineHeight + font11.lineHeight + font10.lineHeight
            }
            total += sectionSpacing
        }
        
        if !sorted.isEmpty {
            total += blockSpacing + font12.lineHeight
        }
        
        var n = 0
        for d in sorted {
            var blockH: CGFloat = 6
            blockH += font10.lineHeight + font11.lineHeight + font10.lineHeight
            for ln in d.gorevler.split(separator: "\n") {
                blockH += 6 + textHeight(String(ln), font: font10, width: w - 30)
            }
            blockH += 10
            if total + blockH > rightColMaxHeight { break }
            total += blockH
            n += 1
        }
        
        let rest = Array(sorted.dropFirst(n))
        var page1Yetkinlikler = model.yetkinlikler
        var page1Sertifikalar = model.sertifikalar
        var page2Yetkinlikler = ""
        var page2Sertifikalar = ""
        
        if !rest.isEmpty {
            page1Yetkinlikler = ""
            page1Sertifikalar = ""
            page2Yetkinlikler = model.yetkinlikler
            page2Sertifikalar = model.sertifikalar
        } else {
            let yetkinlikH: CGFloat = {
                var y: CGFloat = 8 + font12.lineHeight
                for line in model.yetkinlikler.split(separator: "\n") {
                    let s = String(line).trimmingCharacters(in: .whitespaces)
                    if !s.isEmpty { y += 6 + textHeight(s, font: font10, width: w) }
                }
                return y
            }()
            if total + yetkinlikH > rightColMaxHeight {
                page1Yetkinlikler = ""
                page1Sertifikalar = ""
                page2Yetkinlikler = model.yetkinlikler
                page2Sertifikalar = model.sertifikalar
            } else {
                total += yetkinlikH
                let sertifikaH: CGFloat = {
                    var y: CGFloat = 8 + font12.lineHeight
                    for line in model.sertifikalar.split(separator: "\n") {
                        let s = String(line).trimmingCharacters(in: .whitespaces)
                        if !s.isEmpty { y += 6 + textHeight(s, font: font10, width: w) }
                    }
                    return y
                }()
                if total + sertifikaH > rightColMaxHeight {
                    page1Sertifikalar = ""
                    page2Sertifikalar = model.sertifikalar
                }
            }
        }
        
        let needs2 = !rest.isEmpty || !page2Yetkinlikler.isEmpty || !page2Sertifikalar.isEmpty || !page2Ozet.isEmpty
        return PageSplit(
            page1Ozet: page1Ozet,
            page2Ozet: page2Ozet,
            page1Deneyimler: Array(sorted.prefix(n)),
            page1Yetkinlikler: page1Yetkinlikler,
            page1Sertifikalar: page1Sertifikalar,
            page2Deneyimler: rest,
            page2Yetkinlikler: page2Yetkinlikler,
            page2Sertifikalar: page2Sertifikalar,
            needsPage2: needs2
        )
    }
}

/// A4 oranında, iki sütunlu profesyonel CV şablonu (EE-CV1 / cv.docx referans).
/// Sol %30 (koyu mavi): Fotoğraf, CV, Kişisel Bilgiler, Diller, Özet
/// Sağ %70 (beyaz): Eğitimler (üstte), Profesyonel Deneyim, Yetkinlikler, Sertifikalar
struct CVTemplateView: View {
    let model: CVModel
    /// PDF sayfa bölmesi için: sağ kolonda gösterilecek deneyimler (nil = hepsi)
    var deneyimlerOverride: [DeneyimGirisi]? = nil
    var yetkinliklerOverride: String? = nil
    var sertifikalarOverride: String? = nil
    /// 2. sayfa için sol panel boş (sadece mavi arka plan)
    var solPanelBos: Bool = false
    /// 2. sayfa için eğitim gösterme (nil = modelden al)
    var egitimlerOverride: [EgitimGirisi]? = nil
    /// 1. sayfa sol panelde gösterilecek Özet (nil = model.ozet)
    var ozetOverride: String? = nil
    /// 2. sayfa sağ panelde Özet devamı
    var ozetDevamOverride: String? = nil
    
    // EE-CV1 referans renkleri
    private let accentColor = Color(hex: "D97706")      // Amber 600 — başlıklar
    private let accentLight = Color(hex: "F59E0B")      // Amber 500 — vurgular
    private let leftBg = Color(red: 26/255, green: 53/255, blue: 101/255)  // Sol panel koyu mavi (R:26 G:53 B:101)
    private let rightBg = Color.white
    private let textDark = Color(hex: "1F2937")         // Koyu metin (sağ panel)
    private let textMuted = Color(hex: "6B7280")        // İkincil metin (sağ panel)
    private let leftPanelText = Color.white             // Sol panel metin rengi
    private let leftPanelTextMuted = Color.white.opacity(0.85)  // Sol panel ikincil metin
    
    /// Sağ kolonda gösterilecek deneyimler (override varsa o, yoksa sıralanmış model)
    private var displayDeneyimler: [DeneyimGirisi] {
        if let o = deneyimlerOverride { return o }
        return model.deneyimler.sorted { a, b in
            let ma = a.baslangicAy.count == 1 ? "0" + a.baslangicAy : a.baslangicAy
            let mb = b.baslangicAy.count == 1 ? "0" + b.baslangicAy : b.baslangicAy
            let ya = Int(a.baslangicYil + ma) ?? 0
            let yb = Int(b.baslangicYil + mb) ?? 0
            return ya > yb
        }
    }
    
    private var displayYetkinlikler: String {
        yetkinliklerOverride ?? model.yetkinlikler
    }
    
    private var displaySertifikalar: String {
        sertifikalarOverride ?? model.sertifikalar
    }
    
    private var displayEgitimler: [EgitimGirisi] {
        if let o = egitimlerOverride { return o }
        return model.egitimler
    }
    
    private var displayOzet: String {
        ozetOverride ?? model.ozet
    }
    
    private let leftWidthRatio: CGFloat = 0.30
    private let rightWidthRatio: CGFloat = 0.70
    
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .top, spacing: 0) {
                if solPanelBos {
                    Color(leftBg)
                        .frame(width: geo.size.width * leftWidthRatio)
                } else {
                    leftColumn
                        .frame(width: geo.size.width * leftWidthRatio)
                        .background(leftBg)
                }
                rightColumn
                    .frame(width: geo.size.width * rightWidthRatio)
                    .background(rightBg)
            }
        }
        .font(.system(size: 10, weight: .regular))
    }
    
    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Yuvarlak çerçevede fotoğraf (sol panelin en üstü)
            ZStack {
                Circle()
                    .fill(leftPanelText)
                    .overlay(Circle().stroke(leftPanelText.opacity(0.9), lineWidth: 2))
                    .frame(width: 88, height: 88)
                if let data = model.fotografData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 84, height: 84)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundColor(leftPanelTextMuted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, 4)
            
            // "CV" başlık (fotoğrafın altında, ortalanmış)
            Text("CV")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(leftPanelText)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 12)
            
            // Kişisel Bilgiler
            VStack(alignment: .leading, spacing: 8) {
                cvSectionTitleLeft("Kişisel Bilgiler")
                Text(model.adSoyad)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(leftPanelText)
                if !model.email.isEmpty {
                    cvInfoRowLeft(icon: "envelope.fill", text: model.email)
                }
                if !model.telefon.isEmpty {
                    cvInfoRowLeft(icon: "phone.fill", text: model.telefon)
                }
                if !model.adres.isEmpty {
                    cvInfoRowLeft(icon: "location.fill", text: model.adres)
                }
                if !model.dogumTarihi.isEmpty {
                    cvInfoRowLeft(icon: "calendar", text: model.dogumTarihi)
                }
                if !model.uyruk.isEmpty {
                    cvInfoRowLeft(icon: "flag.fill", text: model.uyruk)
                }
            }
            
            cvDivider
            
            // Diller (referans: beyaz kutu içinde koyu mavi yazı)
            if !model.diller.trimmingCharacters(in: .whitespaces).isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    cvSectionTitleLeft("Diller")
                    Text(model.diller)
                        .font(.system(size: 10))
                        .foregroundColor(leftBg)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(leftPanelText)
                }
            }
            
            cvDivider
            
            // Özet
            if !displayOzet.trimmingCharacters(in: .whitespaces).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    cvSectionTitleLeft("Özet")
                    Text(displayOzet)
                        .font(.system(size: 10))
                        .foregroundColor(leftPanelText)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(20)
    }
    
    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
                // Özet devamı (2. sayfada, sağ panelin en üstü)
                if let devam = ozetDevamOverride, !devam.trimmingCharacters(in: .whitespaces).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        cvSectionTitleRight("Özet (devam)")
                        Text(devam)
                            .font(.system(size: 10))
                            .foregroundColor(textDark)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // Eğitimler (sağ panelin en üstü — referans format)
                if !displayEgitimler.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        cvSectionTitleRight("Eğitimler")
                        ForEach(displayEgitimler) { e in
                            cvEgitimRowRight(e)
                        }
                    }
                }
                
                // Profesyonel Deneyim
                if !displayDeneyimler.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        cvSectionTitleRight("Profesyonel Deneyim")
                        ForEach(displayDeneyimler) { d in
                            cvDeneyimBlock(d)
                        }
                    }
                }
                
                // Yetkinlikler
                if !displayYetkinlikler.trimmingCharacters(in: .whitespaces).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        cvSectionTitleRight("Yetkinlikler")
                        ForEach(bulletLines(displayYetkinlikler), id: \.self) { line in
                            cvBulletRight(line)
                        }
                    }
                }
                
                // Sertifikalar
                if !displaySertifikalar.trimmingCharacters(in: .whitespaces).isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        cvSectionTitleRight("Sertifikalar")
                        ForEach(bulletLines(displaySertifikalar), id: \.self) { line in
                            cvBulletRight(line)
                        }
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var cvDivider: some View {
        Rectangle()
            .fill(leftPanelText.opacity(0.35))
            .frame(height: 1)
    }
    
    private func cvSectionTitleLeft(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(leftPanelText)
            .tracking(0.8)
    }
    
    private func cvInfoRowLeft(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundColor(accentLight)
                .frame(width: 14, alignment: .leading)
            Text(text)
                .font(.system(size: 9))
                .foregroundColor(leftPanelText)
        }
    }
    
    private func cvEgitimRowLeft(_ e: EgitimGirisi) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(e.baslangicYil) - \(e.bitisYil)")
                .font(.system(size: 9))
                .foregroundColor(leftPanelTextMuted)
            Text("\(e.derece) - \(e.bolum)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(leftPanelText)
            Text("\(e.universite), \(e.sehir)")
                .font(.system(size: 9))
                .foregroundColor(leftPanelTextMuted)
        }
    }
    
    private func cvBulletLeft(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.system(size: 10))
                .foregroundColor(accentLight)
            Text(trimBullet(text))
                .font(.system(size: 9))
                .foregroundColor(leftPanelText)
        }
    }
    
    private func cvSectionTitleRight(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(textDark)
    }
    
    private func cvEgitimRowRight(_ e: EgitimGirisi) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 12) {
                Text("\(e.baslangicYil) - \(e.bitisYil)")
                    .font(.system(size: 10))
                    .foregroundColor(textMuted)
                    .frame(width: 70, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(e.derece) - \(e.bolum)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(textDark)
                    Text("\(e.universite), \(e.sehir)")
                        .font(.system(size: 10))
                        .foregroundColor(textMuted)
                        .padding(.leading, 0)
                }
            }
        }
    }
    
    private func cvBulletRight(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 10))
                .foregroundColor(textDark)
            Text(trimBullet(text))
                .font(.system(size: 10))
                .foregroundColor(textDark)
        }
    }
    
    private func cvInfoRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundColor(accentColor)
                .frame(width: 14, alignment: .leading)
            Text(text)
                .font(.system(size: 9))
                .foregroundColor(textDark)
        }
    }
    
    private func cvDeneyimBlock(_ d: DeneyimGirisi) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(deneyimTarihStr(d))
                    .font(.system(size: 9))
                    .foregroundColor(textMuted)
                    .frame(width: 70, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    Text(d.pozisyon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(textDark)
                    Text("\(d.sirket), \(d.sehir)")
                        .font(.system(size: 9))
                        .foregroundColor(textMuted)
                }
            }
            ForEach(bulletLines(d.gorevler), id: \.self) { line in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(textDark)
                    Text(line)
                        .font(.system(size: 10))
                        .foregroundColor(textDark)
                        .lineSpacing(2)
                }
            }
        }
    }
    
    private func cvBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .font(.system(size: 10))
                .foregroundColor(accentLight)
            Text(trimBullet(text))
                .font(.system(size: 9))
                .foregroundColor(textDark)
        }
    }
    
    private func deneyimTarihStr(_ d: DeneyimGirisi) -> String {
        d.devamEdiyor
            ? "\(d.baslangicAy).\(d.baslangicYil) – Devam"
            : "\(d.baslangicAy).\(d.baslangicYil) – \(d.bitisAy).\(d.bitisYil)"
    }
    
    private func bulletLines(_ s: String) -> [String] {
        s.split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    private func trimBullet(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespaces)
        if t.hasPrefix("•") { t = String(t.dropFirst()).trimmingCharacters(in: .whitespaces) }
        return t
    }
}

/// A4 oranında sarmalayıcı (595:842)
struct CVTemplateA4Wrapper: View {
    let model: CVModel
    
    var body: some View {
        CVTemplateView(model: model)
            .frame(width: 595, height: 842)
    }
}

// MARK: - ImageRenderer ile PDF Dönüşümü (çok sayfa — her sayfa 595×842 sabit)
struct CVTemplatePdfExporter {
    private static let pageWidth: CGFloat = 595
    private static let pageHeight: CGFloat = 842
    private static let scale: CGFloat = 2.0
    
    /// SwiftUI görünümünü PDF'e dönüştürür. İçerik sığmazsa 2. sayfa: sol boş, sağ devam.
    @MainActor
    static func pdfData(from model: CVModel) -> Data? {
        let split = CVPagination.split(model: model)
        
        let page1View = CVTemplateView(
            model: model,
            deneyimlerOverride: split.page1Deneyimler,
            yetkinliklerOverride: split.page1Yetkinlikler,
            sertifikalarOverride: split.page1Sertifikalar,
            ozetOverride: split.page1Ozet.isEmpty ? nil : split.page1Ozet
        )
        .frame(width: pageWidth, height: pageHeight)
        
        let renderer1 = ImageRenderer(content: page1View)
        renderer1.scale = scale
        guard let img1 = renderer1.uiImage else { return nil }
        
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextCreator: "Finans - CV Oluşturucu"] as [String: Any]
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        if !split.needsPage2 {
            return pdfRenderer.pdfData { ctx in
                ctx.beginPage()
                img1.draw(in: pageRect)
            }
        }
        
        let page2View = CVTemplateView(
            model: model,
            deneyimlerOverride: split.page2Deneyimler,
            yetkinliklerOverride: split.page2Yetkinlikler,
            sertifikalarOverride: split.page2Sertifikalar,
            solPanelBos: true,
            egitimlerOverride: [],
            ozetDevamOverride: split.page2Ozet.isEmpty ? nil : split.page2Ozet
        )
        .frame(width: pageWidth, height: pageHeight)
        
        let renderer2 = ImageRenderer(content: page2View)
        renderer2.scale = scale
        guard let img2 = renderer2.uiImage else { return nil }
        
        return pdfRenderer.pdfData { ctx in
            ctx.beginPage()
            img1.draw(in: pageRect)
            ctx.beginPage()
            img2.draw(in: pageRect)
        }
    }
}

#Preview {
    CVTemplateA4Wrapper(model: CVModel.ornek)
        .border(Color.gray.opacity(0.3))
}
