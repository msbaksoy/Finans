import SwiftUI

struct MevduatFaiziView: View {
    @EnvironmentObject var appTheme: AppTheme
    @EnvironmentObject var mevduatConfig: MevduatConfigService
    @State private var tutarText = ""
    @State private var yillikFaizText = ""
    @State private var vadeText = ""
    @State private var birlesikFaiz = false
    @State private var pdfData: Data?
    @State private var showPdfShare = false
    @State private var showStopajBilgi = false
    @State private var isRefreshing = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    private let temaRengi = Color("06B6D4")
    
    private var anapara: Double { parseFormattedNumber(tutarText) ?? 0 }
    private var yillikFaiz: Double { parseFormattedNumber(yillikFaizText) ?? 0 }
    private var vade: Int { Int(parseFormattedNumber(vadeText) ?? 0) }
    
    /// Basit faiz: Faiz = P * (r/100) * (vade/12)
    private var basitFaizHesaplama: (toplam: Double, faiz: Double)? {
        guard anapara > 0, vade >= 1 else { return nil }
        let faiz = anapara * (yillikFaiz / 100) * Double(vade) / 12
        return (anapara + faiz, faiz)
    }
    
    /// Birleşik faiz: Ay ay bakiye tablosu
    private var birlesikFaizTablo: [MevduatAylikSatir] {
        guard anapara > 0, vade >= 1 else { return [] }
        let aylikOran = yillikFaiz / 100 / 12
        var satirlar: [MevduatAylikSatir] = []
        var bakiye = anapara
        for ay in 1...vade {
            let oncekiBakiye = bakiye
            bakiye = oncekiBakiye * (1 + aylikOran)
            let kazanilanFaiz = bakiye - oncekiBakiye
            satirlar.append(MevduatAylikSatir(
                ay: ay,
                oncekiBakiye: oncekiBakiye,
                kazanilanFaiz: kazanilanFaiz,
                yeniBakiye: bakiye
            ))
        }
        return satirlar
    }
    
    private var isLandscape: Bool { verticalSizeClass == .compact }
    
    var body: some View {
        ZStack {
            appTheme.background.ignoresSafeArea()
            
            if isLandscape && (!birlesikFaiz ? basitFaizHesaplama != nil : !birlesikFaizTablo.isEmpty) {
                mevduatLandscapeView
            } else {
                mevduatPortraitView
            }
        }
        .navigationTitle("Mevduat Faizi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
        .toolbarBackground(appTheme.background, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isRefreshing = true
                    Task {
                        await mevduatConfig.refresh()
                        isRefreshing = false
                    }
                } label: {
                    Label("Oranları Yenile", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                }
                .disabled(isRefreshing)
            }
        }
        .sheet(isPresented: $showPdfShare) {
            if let data = pdfData {
                PdfShareSheet(pdfData: data)
            }
        }
    }
    
    private var mevduatLandscapeView: some View {
        ZStack(alignment: .topTrailing) {
            if birlesikFaiz, !birlesikFaizTablo.isEmpty {
                MevduatBirlesikTablo(tablo: birlesikFaizTablo, temaRengi: temaRengi)
            } else if let basit = basitFaizHesaplama {
                let stopajO = mevduatConfig.stopajOrani(vadeAy: vade)
                let stopajT = basit.faiz * stopajO
                MevduatBasitOzetView(toplam: basit.toplam, faiz: basit.faiz, anapara: anapara, stopajOran: stopajO, stopajTutar: stopajT, netFaiz: basit.faiz - stopajT, netToplam: anapara + (basit.faiz - stopajT))
            }
            pdfButonOverlay
        }
    }
    
    private var mevduatPortraitView: some View {
        ScrollView {
            VStack(spacing: 16) {
                girisAlani
                if !girisGecerli { EmptyView() }
                else if birlesikFaiz {
                    birlesikSonucView
                } else {
                    basitSonucView
                }
            }
            .padding(16)
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    private var girisGecerli: Bool {
        anapara > 0 && vade >= 1
    }
    
    private var girisAlani: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    KrediTextField(title: "Tutar (₺)", text: $tutarText, placeholder: "100.000", keyboardType: .decimalPad, formatThousands: true)
                        .frame(maxWidth: .infinity)
                    KrediTextField(title: "Vade (ay)", text: $vadeText, placeholder: "12", keyboardType: .numberPad, formatThousands: true)
                        .frame(maxWidth: .infinity)
                }
                KrediTextField(title: "Yıllık Faiz Oranı (%)", text: $yillikFaizText, placeholder: "50", keyboardType: .decimalPad, suffix: "%", formatThousands: true, allowDecimals: true)
                
                Button {
                    birlesikFaiz.toggle()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: birlesikFaiz ? "checkmark.circle.fill" : "circle")
                            .font(AppTypography.title2)
                            .foregroundColor(birlesikFaiz ? temaRengi : .white.opacity(0.5))
                        Text("Birleşik Faiz")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(appTheme.textPrimary)
                        Spacer()
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(birlesikFaiz ? temaRengi.opacity(0.15) : appTheme.listRowBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(birlesikFaiz ? temaRengi.opacity(0.5) : appTheme.cardStroke.opacity(0.5), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(appTheme.listRowBackground)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(temaRengi.opacity(0.25), lineWidth: 1))
                    .shadow(color: .black.opacity(appTheme.isLight ? 0.03 : 0), radius: appTheme.isLight ? 8 : 0, y: 4)
            )
            
            HStack(spacing: 6) {
                Text("Vadeli hesaplarda stopaj uygulanır.")
                    .font(.caption2)
                    .foregroundColor(appTheme.textSecondary)
                Button {
                    showStopajBilgi = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(temaRengi)
                }
            }
        }
        .sheet(isPresented: $showStopajBilgi) {
            StopajBilgiSheet(config: mevduatConfig.config)
                .environmentObject(appTheme)
        }
    }
    
    private var basitSonucView: some View {
        Group {
            if let b = basitFaizHesaplama {
                let stopajOran = mevduatConfig.stopajOrani(vadeAy: vade)
                let stopajTutar = b.faiz * stopajOran
                let netFaiz = b.faiz - stopajTutar
                let netToplam = anapara + netFaiz
                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        OzetKrediKart(title: "Faiz Geliri (Brüt)", value: b.faiz, color: temaRengi, icon: "percent")
                        OzetKrediKart(title: "Faiz Geliri (Net)", value: netFaiz, color: Color("34D399"), icon: "checkmark.circle")
                        OzetKrediKart(title: "Toplam Bakiye (Net)", value: netToplam, color: Color("34D399"), icon: "sum")
                    }
                    MevduatBasitOzetView(toplam: b.toplam, faiz: b.faiz, anapara: anapara, stopajOran: stopajOran, stopajTutar: stopajTutar, netFaiz: netFaiz, netToplam: netToplam)
                    pdfButon
                }
            }
        }
    }
    
    private var birlesikSonucView: some View {
        Group {
            if !birlesikFaizTablo.isEmpty {
                let sonSatir = birlesikFaizTablo.last!
                VStack(spacing: 16) {
                    HStack(spacing: 10) {
                        OzetKrediKart(title: "Toplam Faiz (Brüt)", value: sonSatir.yeniBakiye - anapara, color: temaRengi, icon: "percent")
                        OzetKrediKart(title: "Vade Sonu Bakiye", value: sonSatir.yeniBakiye, color: Color("34D399"), icon: "sum")
                    }
                    MevduatBirlesikTablo(tablo: birlesikFaizTablo, temaRengi: temaRengi)
                    pdfButon
                }
            }
        }
    }
    
    private var pdfButonOverlay: some View {
        Button {
            olusturVePaylasPdf()
        } label: {
            Label("PDF", systemImage: "square.and.arrow.up")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(temaRengi)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(appTheme.backgroundSecondary.opacity(0.95))
                .cornerRadius(12)
        }
        .padding(16)
    }
    
    private var pdfButon: some View {
        Button {
            olusturVePaylasPdf()
        } label: {
            Label("PDF Olarak Dışa Aktar", systemImage: "square.and.arrow.up")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(temaRengi.opacity(0.2))
                .foregroundColor(temaRengi)
                .cornerRadius(14)
        }
    }
    
    private func olusturVePaylasPdf() {
        pdfData = MevduatPdfOlusturucu.olustur(
            tutar: anapara, yillikFaiz: yillikFaiz, vade: vade,
            birlesikFaiz: birlesikFaiz,
            basitSonuc: basitFaizHesaplama,
            birlesikTablo: birlesikFaizTablo
        )
        showPdfShare = true
    }
}

struct MevduatAylikSatir: Identifiable {
    let id = UUID()
    let ay: Int
    let oncekiBakiye: Double
    let kazanilanFaiz: Double
    let yeniBakiye: Double
}

struct MevduatBasitOzetView: View {
    let toplam: Double
    let faiz: Double
    let anapara: Double
    var stopajOran: Double? = nil
    var stopajTutar: Double? = nil
    var netFaiz: Double? = nil
    var netToplam: Double? = nil
    var temaRengi: Color = Color("06B6D4")
    @EnvironmentObject var appTheme: AppTheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Basit Faiz Özeti")
                .font(.headline)
                .foregroundColor(appTheme.textPrimary)
            VStack(spacing: 10) {
                mevduatOzetSatir(label: "Anapara", value: anapara)
                mevduatOzetSatir(label: "Faiz Geliri (Brüt)", value: faiz, renk: temaRengi)
                if let st = stopajTutar, let nf = netFaiz, let nt = netToplam {
                    mevduatOzetSatir(label: "Stopaj (\(Int((stopajOran ?? 0) * 100))%)", value: -st, renk: Color("F87171"))
                    mevduatOzetSatir(label: "Faiz Geliri (Net)", value: nf, renk: Color("34D399"))
                    mevduatOzetSatir(label: "Toplam Bakiye (Net)", value: nt, renk: Color("34D399"))
                } else {
                    mevduatOzetSatir(label: "Toplam Bakiye", value: toplam, renk: Color(hex: "34D399"))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(appTheme.listRowBackground)
            )
        }
    }
    
    private func mevduatOzetSatir(label: String, value: Double, renk: Color? = nil) -> some View {
        HStack {
            Text(label)
                .foregroundColor(appTheme.textSecondary)
            Spacer()
            Text(formatCurrency(value))
                .font(AppTypography.amountSmall)
                .monospacedDigit()
                .foregroundColor(renk ?? appTheme.textPrimary)
        }
    }
}

struct MevduatBirlesikTablo: View {
    let tablo: [MevduatAylikSatir]
    var temaRengi: Color = Color("06B6D4")
    @EnvironmentObject var appTheme: AppTheme
    @State private var tumunuGoster = false
    private let ilkGosterim = 5
    
    private var gosterilecekSatirlar: [MevduatAylikSatir] {
        if tumunuGoster || tablo.count <= ilkGosterim {
            return tablo
        }
        return Array(tablo.prefix(ilkGosterim))
    }
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    TabloBaslik(text: "Ay", width: 44)
                    TabloBaslik(text: "Önceki Bakiye", width: 100)
                    TabloBaslik(text: "Faiz (Brüt)", width: 90)
                    TabloBaslik(text: "Yeni Bakiye", width: 100)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [temaRengi.opacity(0.25), temaRengi.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                Divider().background(Color.white.opacity(0.2))
                ForEach(gosterilecekSatirlar) { satir in
                    MevduatTabloSatir(satir: satir, temaRengi: temaRengi)
                }
                if tablo.count > ilkGosterim {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { tumunuGoster.toggle() }
                    } label: {
                        HStack(spacing: 6) {
                            Text(tumunuGoster ? "Daha Az Göster" : "Tümünü Göster (\(tablo.count) ay)")
                                .font(AppTypography.footnote.weight(.semibold))
                            Image(systemName: tumunuGoster ? "chevron.up" : "chevron.down")
                                .font(AppTypography.caption1.weight(.semibold))
                        }
                        .foregroundColor(temaRengi)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(appTheme.listRowBackground)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1))
        )
    }
}

struct MevduatTabloSatir: View {
    let satir: MevduatAylikSatir
    var temaRengi: Color = Color(hex: "06B6D4")
    @EnvironmentObject var appTheme: AppTheme
    
    var body: some View {
        HStack(spacing: 0) {
            Text(ayIsmi(satir.ay))
                .frame(width: 44, alignment: .leading)
                .font(.subheadline.weight(.medium))
                .foregroundColor(appTheme.textPrimary)
            Text(formatCurrency(satir.oncekiBakiye))
                .frame(width: 100, alignment: .trailing)
                .font(AppTypography.footnote)
                .monospacedDigit()
                .foregroundColor(appTheme.textSecondary)
            Text(formatCurrency(satir.kazanilanFaiz))
                .frame(width: 90, alignment: .trailing)
                .font(AppTypography.footnote)
                .monospacedDigit()
                .foregroundColor(temaRengi)
            Text(formatCurrency(satir.yeniBakiye))
                .frame(width: 100, alignment: .trailing)
                .font(AppTypography.amountSmall)
                .monospacedDigit()
                .foregroundColor(Color(hex: "34D399"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(satir.ay.isMultiple(of: 2) ? appTheme.textSecondary.opacity(0.05) : Color.clear)
    }
    
    private func ayIsmi(_ ay: Int) -> String {
        return "\(ay)"
    }
}

struct MevduatPdfOlusturucu {
    static func olustur(
        tutar: Double, yillikFaiz: Double, vade: Int,
        birlesikFaiz: Bool,
        basitSonuc: (toplam: Double, faiz: Double)?,
        birlesikTablo: [MevduatAylikSatir]
    ) -> Data? {
        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 40
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [kCGPDFContextCreator: "Finans - Mevduat Faizi"] as [String: Any]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = margin
            
            "Mevduat Faizi Hesaplama".draw(in: CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: 24), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.darkGray
            ])
            y += 28
            "Brüt tutarlar gösterilmektedir, stopaj kesintisi dahil değildir.".draw(in: CGRect(x: margin, y: y, width: pageWidth - 2*margin, height: 18), withAttributes: [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.gray
            ])
            y += 24
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            formatter.decimalSeparator = ","
            formatter.groupingSeparator = "."
            formatter.locale = Locale(identifier: "tr_TR")
            
            let fmt: (Double) -> String = { formatter.string(from: NSNumber(value: $0)) ?? "0,00" }
            let font = UIFont.systemFont(ofSize: 11)
            
            "Tutar: \(fmt(tutar)) ₺".draw(in: CGRect(x: margin, y: y, width: 300, height: 18), withAttributes: [.font: font, .foregroundColor: UIColor.darkGray])
            y += 22
            "Yıllık Faiz: \(yillikFaiz)%".draw(in: CGRect(x: margin, y: y, width: 300, height: 18), withAttributes: [.font: font, .foregroundColor: UIColor.darkGray])
            y += 22
            "Vade: \(vade) ay".draw(in: CGRect(x: margin, y: y, width: 300, height: 18), withAttributes: [.font: font, .foregroundColor: UIColor.darkGray])
            y += 28
            
            if birlesikFaiz, !birlesikTablo.isEmpty {
                "Birleşik Faiz - Aylık Tablo".draw(in: CGRect(x: margin, y: y, width: 400, height: 18), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: UIColor.darkGray])
                y += 24
                let son = birlesikTablo.last!
                "Toplam Faiz (Brüt): \(fmt(son.yeniBakiye - tutar)) ₺".draw(in: CGRect(x: margin, y: y, width: 300, height: 18), withAttributes: [.font: font, .foregroundColor: UIColor.darkGray])
                y += 22
                "Vade Sonu: \(fmt(son.yeniBakiye)) ₺".draw(in: CGRect(x: margin, y: y, width: 300, height: 18), withAttributes: [.font: font, .foregroundColor: UIColor.darkGray])
                y += 24
                for s in birlesikTablo.prefix(24) {
                    "\(s.ay). Ay: \(fmt(s.oncekiBakiye)) → +\(fmt(s.kazanilanFaiz)) = \(fmt(s.yeniBakiye))".draw(in: CGRect(x: margin, y: y, width: 500, height: 16), withAttributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.darkGray])
                    y += 18
                }
                if birlesikTablo.count > 24 {
                    "... (\(birlesikTablo.count) ay toplam)".draw(in: CGRect(x: margin, y: y, width: 300, height: 16), withAttributes: [.font: font, .foregroundColor: UIColor.gray])
                }
            } else if let b = basitSonuc {
                "Basit Faiz".draw(in: CGRect(x: margin, y: y, width: 200, height: 18), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 12), .foregroundColor: UIColor.darkGray])
                y += 24
                "Faiz Geliri (Brüt): \(fmt(b.faiz)) ₺".draw(in: CGRect(x: margin, y: y, width: 300, height: 18), withAttributes: [.font: font, .foregroundColor: UIColor.darkGray])
                y += 22
                "Toplam Bakiye: \(fmt(b.toplam)) ₺".draw(in: CGRect(x: margin, y: y, width: 300, height: 18), withAttributes: [.font: font, .foregroundColor: UIColor.darkGray])
            }
        }
        return data
    }
}

// MARK: - Stopaj Bilgi Sheet (info ikonuna tıklanınca)
struct StopajBilgiSheet: View {
    let config: MevduatStopajConfig
    @EnvironmentObject var appTheme: AppTheme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                appTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Vadeli mevduat faiz getirisi stopaja tabidir. Brüt tutardan yapılan kesinti oranları vadeye göre değişir:")
                            .font(.subheadline)
                            .foregroundColor(appTheme.textSecondary)
                        VStack(alignment: .leading, spacing: 12) {
                            stopajSatir(vade: "6 aya kadar", oran: config.stopaj0_6)
                            stopajSatir(vade: "1 yıla kadar (1 yıl dahil)", oran: config.stopaj6_12)
                            stopajSatir(vade: "1 yıldan uzun", oran: config.stopaj12_plus)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(appTheme.listRowBackground)
                        )
                        Text("Birleşik faiz hesaplamasında vade 1 yıldan uzun olsa bile aylık bazda stopaj uygulanır.")
                            .font(.caption)
                            .foregroundColor(appTheme.textSecondary)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Stopaj Oranları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") { dismiss() }
                        .foregroundColor(Color(hex: "06B6D4"))
                }
            }
        }
    }
    
    private func stopajSatir(vade: String, oran: Double) -> some View {
        HStack {
            Text(vade)
                .foregroundColor(appTheme.textPrimary)
            Spacer()
            Text("%\(Int(oran * 100))")
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "06B6D4"))
        }
    }
}

#Preview {
    NavigationStack {
        MevduatFaiziView()
            .environmentObject(AppTheme())
            .environmentObject(MevduatConfigService.shared)
    }
}
