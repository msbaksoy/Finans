import SwiftUI
import SwiftData
import UIKit

struct BrutNetView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appTheme: AppTheme
    @Query(sort: [SortDescriptor(\AylikMaas.yil, order: .reverse), SortDescriptor(\AylikMaas.ay)]) private var aylikMaaslar: [AylikMaas]
    @State private var stableAylikMaaslar: [AylikMaas] = []
    @State private var isLoaded: Bool = false
    @State private var showMaasGirisSheet = false
    @State private var showPdfShare = false
    @State private var pdfData: Data?
    @State private var yil: Int = Calendar.current.component(.year, from: Date())
    @State private var detayTabloAcik = false
    @State private var seciliAylikDetay: AylikBrutNetDetay?
    @StateObject private var viewModel = BrutNetViewModel()
    @State private var triggerBrutFocus: [Bool] = Array(repeating: false, count: 12)
    @State private var triggerPrimFocus: [Bool] = Array(repeating: false, count: 12)
    @State private var yillikDetayGoster = false
    @State private var saveErrorMessage: String?

    private var yilMaaslar: [AylikMaas] {
        let source = isLoaded ? stableAylikMaaslar : aylikMaaslar
        return source.filter { $0.yil == yil }.sorted { $0.ay < $1.ay }
    }
    
    /// Tablo gösterimi için detaylı hesaplama (kaydedilmiş veriden)
    private var detayliSonuclar: [AylikBrutNetDetay] {
        let b = (1...12).map { ay in yilMaaslar.first { $0.ay == ay }?.brutTutar ?? 0 }
        let p = (1...12).map { ay in yilMaaslar.first { $0.ay == ay }?.primTutar ?? 0 }
        return BrutNetCalculator.hesaplaYillikDetayli(brutlar: b, primler: p)
    }

    /// Görsel hub ve vergi takvimi: form doluysa canlı, değilse kayıtlı
    private var gosterilenDetaylar: [AylikBrutNetDetay] {
        viewModel.hasValidInput ? viewModel.liveDetayliSonuclar : detayliSonuclar
    }

    private var toplamNet: Double {
        yilMaaslar.reduce(0) { $0 + $1.netTutar }
    }

    private var aylikOrtalamaNet: Double {
        guard !yilMaaslar.isEmpty else { return 0 }
        return toplamNet / Double(yilMaaslar.count)
    }

    private var toplamNetGosterilen: Double { viewModel.toplamNetGosterilen }

    private var aylikOrtalamaNetGosterilen: Double {
        let d = gosterilenDetaylar.filter { $0.brutToplam > 0 }
        guard !d.isEmpty else { return 0 }
        return toplamNetGosterilen / Double(d.count)
    }

    private var toplamKesintiGosterilen: Double {
        gosterilenDetaylar.reduce(0) { r, d in
            r + d.sgkIsci + d.issizlikIsci + d.aylikGelirVergisi + d.damgaVergisi
        }
    }
    
    private var toplamKesinti: Double {
        yilMaaslar.reduce(0) { sum, maas in
            sum + maas.kesintiler.reduce(0) { $0 + $1.tutar }
        }
    }

    private func toplamBrutNetFromDetay(_ detaylar: [AylikBrutNetDetay]) -> Double {
        detaylar.reduce(0) { $0 + $1.brutToplam }
    }
    
    var body: some View {
        BrutNetView_YENI()
    }

    /// Mevcut yıl verisini forma doldurur
    private func yilMaaslariFormaYukle() {
        var newBrut = viewModel.brutlar
        var newPrim = viewModel.primler
        for maas in yilMaaslar {
            let ay = maas.ay
            guard ay >= 1, ay <= 12 else { continue }
            let i = ay - 1
            if maas.brutTutar > 0 { newBrut[i] = "\(Int(maas.brutTutar))" }
            if maas.primTutar > 0 { newPrim[i] = "\(Int(maas.primTutar))" }
        }
        viewModel.brutlar = newBrut
        viewModel.primler = newPrim
    }

    private func bindingBrutForAy(_ ay: Int) -> Binding<String> {
        let idx = ay - 1
        return Binding(
            get: { viewModel.brutlar[idx] },
            set: { newValue in
                var copy = viewModel.brutlar
                for i in idx..<12 { copy[i] = newValue }
                viewModel.brutlar = copy
            }
        )
    }

    private func bindingPrimForAy(_ ay: Int) -> Binding<String> {
        Binding(
            get: { viewModel.primler[ay - 1] },
            set: { viewModel.primler[ay - 1] = $0 }
        )
    }

    /// Inline girişten kaydet (sheet’teki kaydetVeKapat ile aynı mantık)
    private func maasGirisKaydet() {
        viewModel.saveToDatabase(context: modelContext, yil: yil)
    }

    private func setAylikMaas(_ maas: AylikMaas) {
        let existing = aylikMaaslar.first { $0.ay == maas.ay && $0.yil == maas.yil }
        if let existing {
            existing.brutTutar = maas.brutTutar
            existing.primTutar = maas.primTutar
            existing.netTutar = maas.netTutar
            existing.kesintiler = maas.kesintiler
        } else {
            modelContext.insert(maas)
        }
        do {
            try modelContext.save()
        } catch {
            saveErrorMessage = "Maaş verisi kaydedilirken bir hata oluştu. Lütfen daha sonra tekrar deneyin."
            print("SwiftData save error in BrutNetView.setAylikMaas: \\(error)")
        }
    }

    // MARK: - Finansal Kokpit (Etkileşimli halka + Vergi dilimi ilerlemesi + İçgörüler)
    private var donutChartCard: some View {
        let detaylar = gosterilenDetaylar.filter { $0.brutToplam > 0 }
        let toplamSGK = detaylar.reduce(0) { r, d in r + d.sgkIsci + d.issizlikIsci }
        let toplamVergi = detaylar.reduce(0) { r, d in r + d.aylikGelirVergisi + d.damgaVergisi }
        let toplamNet = detaylar.reduce(0) { $0 + $1.toplamNetEleGecen }
        let toplam = toplamSGK + toplamVergi + toplamNet
        let sgkOran = toplam > 0 ? (toplamSGK / toplam) : 0.0
        let vergiOran = toplam > 0 ? (toplamVergi / toplam) : 0.0
        let netOran = toplam > 0 ? (toplamNet / toplam) : 0.0
        let sonKumulatif = detaylar.sorted(by: { $0.ay < $1.ay }).last?.kumulatifVergiMatrahi ?? 0
        let (kalanMatrah, sonrakiDilimYuzde, ilerlemeOrani) = vergiDilimiIlerleme(kumulatifMatrah: sonKumulatif)
        let toplamMaliyet = detaylar.reduce(0) { $0 + $1.toplamMaliyet }
        let aylikOrtNet = detaylar.isEmpty ? 0 : toplamNet / Double(detaylar.count)
        let gunlukNet = aylikOrtNet > 0 ? aylikOrtNet / 30.0 : 0

        return VStack(spacing: 25) {
            // 1. Etkileşimli halka — tüm daire dokunulabilir (geniş hit alanı), dokunulunca seçim döner
            ZStack {
                Circle()
                    .stroke(Color(uiColor: .tertiarySystemFill), lineWidth: 25)
                if toplam > 0 {
                    Circle()
                        .trim(from: 0, to: sgkOran)
                        .stroke(Color.blue.opacity(0.9), style: StrokeStyle(lineWidth: 25, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: sgkOran, to: sgkOran + vergiOran)
                        .stroke(appTheme.warningColor.opacity(0.9), style: StrokeStyle(lineWidth: 25, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .trim(from: sgkOran + vergiOran, to: 1)
                        .stroke(appTheme.successColor.opacity(0.9), style: StrokeStyle(lineWidth: 25, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                VStack(spacing: 4) {
                    Text(ortadaBaslik(viewModel.donutSecilen))
                        .font(.caption2.weight(.bold))
                        .foregroundColor(appTheme.textSecondary)
                    Text(ortadaTutar(viewModel.donutSecilen, sgk: toplamSGK, vergi: toplamVergi, net: toplamNet, netOran: netOran))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(appTheme.primaryAccent)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 8)
            }
            .frame(width: 260, height: 260)
            .contentShape(Circle())
            .onTapGesture {
                switch viewModel.donutSecilen {
                case "net": viewModel.donutSecilen = "sgk"
                case "sgk": viewModel.donutSecilen = "vergi"
                default: viewModel.donutSecilen = "net"
                }
                HapticHelper.triggerImpact(.light)
            }
            HStack(spacing: 20) {
                kokpitLegendButon(label: "SGK", tutar: toplamSGK, secili: viewModel.donutSecilen == "sgk") { viewModel.donutSecilen = "sgk" }
                kokpitLegendButon(label: "Vergi", tutar: toplamVergi, secili: viewModel.donutSecilen == "vergi") { viewModel.donutSecilen = "vergi" }
                kokpitLegendButon(label: "Net", tutar: toplamNet, secili: viewModel.donutSecilen == "net") { viewModel.donutSecilen = "net" }
            }
            .font(.caption.weight(.medium))
            .foregroundColor(appTheme.textSecondary)

            // 2. Vergi dilimi ilerleme çubuğu
            if sonKumulatif < 5_000_000 && toplam > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Vergi Dilimi İlerlemesi")
                            .font(.caption.weight(.bold))
                            .foregroundColor(appTheme.textPrimary)
                        Spacer()
                        if kalanMatrah > 0 {
                            Text("%\(Int(sonrakiDilimYuzde)) dilimine kalan: \(formatCurrency(kalanMatrah, decimals: 0))")
                                .font(.caption2)
                                .foregroundColor(appTheme.warningColor)
                        }
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(uiColor: .tertiarySystemFill))
                            RoundedRectangle(cornerRadius: 10)
                                .fill(LinearGradient(colors: [appTheme.successColor, appTheme.warningColor], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(0, geo.size.width * ilerlemeOrani))
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal, 4)
            }

            // 3. İçgörü kartları
            HStack(spacing: 12) {
                kokpitInsight(icon: "building.2", title: "Şirket Maliyeti", value: formatCurrency(toplamMaliyet, decimals: 0), subtitle: "İşverenin toplam maliyeti")
                kokpitInsight(icon: "sun.max", title: "Günlük Net", value: formatCurrency(gunlukNet, decimals: 0), subtitle: "Ort. günlük kazanç")
            }
        }
        .frame(maxWidth: .infinity)
        .premiumCard(theme: appTheme)
    }

    private func vergiDilimiIlerleme(kumulatifMatrah: Double) -> (kalanMatrah: Double, sonrakiDilimYuzde: Int, ilerlemeOrani: Double) {
        let sinirlar: [(sinir: Double, oran: Int)] = [(190_000, 20), (400_000, 27), (1_500_000, 35), (5_000_000, 40)]
        guard let idx = sinirlar.firstIndex(where: { kumulatifMatrah < $0.sinir }) else {
            return (0, 40, 1)
        }
        let next = sinirlar[idx]
        let oncekiSinir = idx > 0 ? sinirlar[idx - 1].sinir : 0.0
        let kalan = next.sinir - kumulatifMatrah
        let dilimGenisligi = next.sinir - oncekiSinir
        let ilerleme = dilimGenisligi > 0 ? (kumulatifMatrah - oncekiSinir) / dilimGenisligi : 0
        return (kalan, next.oran, min(1, max(0, ilerleme)))
    }

    private func ortadaBaslik(_ secim: String) -> String {
        switch secim {
        case "sgk": return "SGK + İşsizlik"
        case "vergi": return "Vergi (GV + DV)"
        default: return "NET ORAN"
        }
    }

    private func ortadaTutar(_ secim: String, sgk: Double, vergi: Double, net: Double, netOran: Double) -> String {
        switch secim {
        case "sgk": return formatCurrency(sgk, decimals: 0)
        case "vergi": return formatCurrency(vergi, decimals: 0)
        default: return "%\(Int(netOran * 100))\n\(formatCurrency(net, decimals: 0))"
        }
    }

    private func kokpitLegendButon(label: String, tutar: Double, secili: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(secili ? (label == "SGK" ? Color.blue : (label == "Vergi" ? appTheme.warningColor : appTheme.successColor)) : Color(uiColor: .tertiarySystemFill))
                    .frame(width: 8, height: 8)
                Text(label)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 10).fill(secili ? (label == "SGK" ? Color.blue.opacity(0.15) : (label == "Vergi" ? appTheme.warningColor.opacity(0.15) : appTheme.successColor.opacity(0.15))) : Color.clear))
        }
        .buttonStyle(.plain)
    }

    private func kokpitInsight(icon: String, title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(appTheme.primaryAccent)
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundColor(appTheme.textSecondary)
            }
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundColor(appTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(appTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(uiColor: .secondarySystemGroupedBackground)))
    }

    // MARK: - Birleştirilmiş Giriş Kartı (Önce Veri, Sonra Analiz — onCommit ile otomatik hesaplama)
    private var inputKarti: some View {
        VStack(spacing: 20) {
            Text("MAAŞ VE PRİM BİLGİLERİ")
                .font(.caption2.weight(.bold))
                .foregroundColor(appTheme.textSecondary)
                .tracking(1.2)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Aylık Brüt (₺)").font(.caption2.weight(.bold)).foregroundColor(appTheme.textSecondary)
                    FormattedNumberField(
                        text: bindingBrutForAy(1),
                        placeholder: "0",
                        allowDecimals: false,
                        focusTrigger: $triggerBrutFocus[0],
                        isLightMode: appTheme.isLight,
                        onCommit: { maasGirisKaydet() }
                    )
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.cardBackgroundSecondary))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Yıllık Prim (₺)").font(.caption2.weight(.bold)).foregroundColor(appTheme.textSecondary)
                    FormattedNumberField(
                        text: bindingPrimForAy(1),
                        placeholder: "0",
                        allowDecimals: false,
                        focusTrigger: $triggerPrimFocus[0],
                        isLightMode: appTheme.isLight,
                        onCommit: { maasGirisKaydet() }
                    )
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(appTheme.cardBackgroundSecondary))
                }
            }

            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    yillikDetayGoster.toggle()
                }
            } label: {
                HStack {
                    Text(yillikDetayGoster ? "Girişleri Gizle" : "Ay Ay Özelleştir")
                    Image(systemName: yillikDetayGoster ? "chevron.up" : "chevron.down")
                }
                .font(.footnote.weight(.bold))
                .foregroundColor(appTheme.warningColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(appTheme.warningColor.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            if yillikDetayGoster {
                VStack(spacing: 8) {
                    ForEach(1...12, id: \.self) { ay in
                        maasGirisSatiri(ay: ay)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .premiumCard(theme: appTheme)
    }

    // MARK: - Vergi Dilimi Takvimi (20% / 27% vurgusu)
    private var vergiDilimiTakvimiKarti: some View {
        let detaylar = gosterilenDetaylar.filter { $0.brutToplam > 0 }
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundColor(appTheme.warningColor)
                Text("Vergi Dilimi Takvimi")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(appTheme.textPrimary)
            }
            Text("Hangi ayda %20 veya %27 dilimine girildiği ve aylık net tutar")
                .font(.caption)
                .foregroundColor(appTheme.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(1...12, id: \.self) { ay in
                        vergiDilimiPilon(ay: ay, detaylar: detaylar)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCard(theme: appTheme)
    }

    private func vergiDilimiPilon(ay: Int, detaylar: [AylikBrutNetDetay]) -> some View {
        let d = detaylar.first { $0.ay == ay }
        let kum = d?.kumulatifVergiMatrahi ?? 0
        let netTutar = d?.toplamNetEleGecen ?? 0
        let (oran, is20, is27) = vergiDilimiOraniVeVurgu(kumulatifMatrah: kum)
        let label = d != nil ? "\(Aylar.isim(ay: ay).prefix(3))." : ""
        let netStr: String = {
            guard netTutar > 0 else { return "" }
            let yuvarlanmis = Int(netTutar.rounded())
            let f = NumberFormatter()
            f.locale = Locale(identifier: "tr_TR")
            f.numberStyle = .decimal
            f.maximumFractionDigits = 0
            return f.string(from: NSNumber(value: yuvarlanmis)) ?? "\(yuvarlanmis)"
        }()
        return VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundColor(appTheme.textSecondary)
            Text("%\(Int(oran * 100))")
                .font(.caption.weight(.bold))
                .foregroundColor(is20 || is27 ? .white : appTheme.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(is27 ? appTheme.dangerColor : (is20 ? appTheme.warningColor : Color(uiColor: .tertiarySystemFill)))
                )
            if !netStr.isEmpty {
                Text(netStr + " ₺")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(appTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(minWidth: 60)
    }

    private func vergiDilimiOraniVeVurgu(kumulatifMatrah: Double) -> (oran: Double, is20: Bool, is27: Bool) {
        if kumulatifMatrah <= 0 { return (0.15, false, false) }
        if kumulatifMatrah <= 190_000 { return (0.15, false, false) }
        if kumulatifMatrah <= 400_000 { return (0.20, true, false) }
        if kumulatifMatrah <= 1_500_000 { return (0.27, false, true) }
        if kumulatifMatrah <= 5_000_000 { return (0.35, false, false) }
        return (0.40, false, false)
    }

    /// Bu ayda vergi dilimi bir üst dilime çıktı mı? (Örn. %15 → %20 veya %20 → %27)
    private func vergiDilimiDegisti(detay: AylikBrutNetDetay, tumDetaylar: [AylikBrutNetDetay]) -> Bool {
        let oncekiKum = tumDetaylar.first { $0.ay == detay.ay - 1 }?.kumulatifVergiMatrahi ?? 0
        let (buAyOran, is20, is27) = vergiDilimiOraniVeVurgu(kumulatifMatrah: detay.kumulatifVergiMatrahi)
        let (oncekiOran, _, _) = vergiDilimiOraniVeVurgu(kumulatifMatrah: oncekiKum)
        return buAyOran > oncekiOran && (is20 || is27)
    }

    private func vergiDilimiDegistiCaption(_ detay: AylikBrutNetDetay, _ tumDetaylar: [AylikBrutNetDetay]) -> String? {
        let (_, is20, is27) = vergiDilimiOraniVeVurgu(kumulatifMatrah: detay.kumulatifVergiMatrahi)
        guard vergiDilimiDegisti(detay: detay, tumDetaylar: tumDetaylar) else { return nil }
        if is20 { return "%20 Dilimine Girildi" }
        if is27 { return "%27 Dilimine Girildi" }
        return nil
    }

    private func maasGirisSatiri(ay: Int) -> some View {
        HStack(spacing: 12) {
            Text(Aylar.isim(ay: ay))
                .font(.subheadline.weight(.medium))
                .foregroundColor(appTheme.textPrimary)
                .frame(width: 70, alignment: .leading)

            FormattedNumberField(
                text: bindingBrutForAy(ay),
                placeholder: "0",
                allowDecimals: false,
                focusTrigger: Binding(
                    get: { triggerBrutFocus.indices.contains(ay - 1) ? triggerBrutFocus[ay - 1] : false },
                    set: { if triggerBrutFocus.indices.contains(ay - 1) { triggerBrutFocus[ay - 1] = $0 } }
                ),
                isLightMode: appTheme.isLight
            )
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(appTheme.cardBackgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
            .onTapGesture { triggerBrutFocus[ay - 1] = true }

            FormattedNumberField(
                text: bindingPrimForAy(ay),
                placeholder: "0",
                allowDecimals: false,
                focusTrigger: Binding(
                    get: { triggerPrimFocus.indices.contains(ay - 1) ? triggerPrimFocus[ay - 1] : false },
                    set: { if triggerPrimFocus.indices.contains(ay - 1) { triggerPrimFocus[ay - 1] = $0 } }
                ),
                isLightMode: appTheme.isLight
            )
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(appTheme.cardBackgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1)
                    )
            )
            .contentShape(Rectangle())
            .onTapGesture { triggerPrimFocus[ay - 1] = true }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
    }

    private func tarihFormatla(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.locale = Locale(identifier: "tr_TR")
        return f.string(from: date)
    }
    
    private var bosDurumView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundColor(appTheme.textSecondary.opacity(0.6))
            Text("Henüz maaş verisi yok")
                .font(.headline)
                .foregroundColor(appTheme.textPrimary)
            Text("Brüt maaş ve prim girişi yapmak için Brütten Nete ve Prim Hesaplama alanına tıklayın")
                .font(.subheadline)
                .foregroundColor(appTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(48)
    }
    
    private var ozetKartlari: some View {
        let useLive = gosterilenDetaylar.contains(where: { $0.brutToplam > 0 })
        let ortNet = useLive ? aylikOrtalamaNetGosterilen : aylikOrtalamaNet
        let kesinti = useLive ? toplamKesintiGosterilen : toplamKesinti
        let net = useLive ? toplamNetGosterilen : toplamNet
        return VStack(spacing: 16) {
            HStack(spacing: 16) {
                OzetKart(
                    title: "Aylık Ort. Net",
                    value: formatCurrency(ortNet, decimals: 0),
                    icon: "chart.bar.fill",
                    color: appTheme.successColor
                )
                OzetKart(
                    title: "Toplam Kesinti",
                    value: formatCurrency(kesinti, decimals: 0),
                    icon: "arrow.down.circle.fill",
                    color: appTheme.dangerColor
                )
            }
            .animation(.easeInOut(duration: 0.3), value: net)

            HStack {
                Image(systemName: "sum")
                    .font(AppTypography.title2)
                    .foregroundColor(appTheme.primaryAccent)
                Text("Yıllık Toplam Net")
                    .font(.headline)
                    .foregroundColor(appTheme.textPrimary)
                Spacer()
                Text(formatCurrency(net, decimals: 0))
                    .font(AppTypography.amountMedium)
                    .monospacedDigit()
                    .foregroundColor(appTheme.primaryAccent)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: net)
            }
            .premiumCard(theme: appTheme)
        }
    }
    
    private var aylikNetListesi: some View {
        let detaylar = gosterilenDetaylar.filter { $0.brutToplam > 0 }
        let tumDetaylar = gosterilenDetaylar
        return VStack(alignment: .leading, spacing: 16) {
            Text("Aylık Net Maaş")
                .font(.headline)
                .foregroundColor(appTheme.textPrimary)
            LazyVStack(spacing: 12) {
                if !yilMaaslar.isEmpty {
                    ForEach(yilMaaslar) { maas in
                        aylikNetSatir(maas: maas, tumDetaylar: tumDetaylar)
                    }
                } else {
                    ForEach(detaylar, id: \.ay) { d in
                        aylikNetSatirDetay(detay: d, tumDetaylar: tumDetaylar)
                    }
                }
            }
        }
        .sheet(item: $seciliAylikDetay) { detay in
            AylikKesintiDetaySheet(detay: detay)
                .environmentObject(appTheme)
        }
    }

    private func aylikNetSatir(maas: AylikMaas, tumDetaylar: [AylikBrutNetDetay]) -> some View {
        let d = tumDetaylar.first { $0.ay == maas.ay }
        let dilimDegisti = d.map { vergiDilimiDegisti(detay: $0, tumDetaylar: tumDetaylar) } ?? false
        let caption = d.flatMap { vergiDilimiDegistiCaption($0, tumDetaylar) }
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 16) {
                Text(Aylar.isim(ay: maas.ay))
                    .font(AppTypography.headline)
                    .foregroundColor(appTheme.textPrimary)
                    .frame(width: 70, alignment: .leading)
                Text(maas.primTutar > 0 ? "\(formatCurrency(maas.brutTutar)) + \(formatCurrency(maas.primTutar))" : formatCurrency(maas.brutTutar))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(appTheme.textSecondary)
                Spacer()
                Text(formatCurrency(maas.netTutar))
                    .font(AppTypography.amountSmall)
                    .monospacedDigit()
                    .foregroundColor(appTheme.successColor)
            }
            if let caption = caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundColor(appTheme.warningColor)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(uiColor: .systemBackground))
                .overlay(RoundedRectangle(cornerRadius: 30).fill(dilimDegisti ? appTheme.warningColor.opacity(0.12) : Color.clear))
                .shadow(color: .black.opacity(appTheme.isLight ? 0.08 : 0.2), radius: 16, x: 0, y: 6)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if let detay = d {
                seciliAylikDetay = detay
            }
        }
    }

    private func aylikNetSatirDetay(detay: AylikBrutNetDetay, tumDetaylar: [AylikBrutNetDetay]) -> some View {
        let dilimDegisti = vergiDilimiDegisti(detay: detay, tumDetaylar: tumDetaylar)
        let caption = vergiDilimiDegistiCaption(detay, tumDetaylar)
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 16) {
                Text(Aylar.isim(ay: detay.ay))
                    .font(AppTypography.headline)
                    .foregroundColor(appTheme.textPrimary)
                    .frame(width: 70, alignment: .leading)
                Text(formatCurrency(detay.brutToplam))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(appTheme.textSecondary)
                Spacer()
                Text(formatCurrency(detay.toplamNetEleGecen))
                    .font(AppTypography.amountSmall)
                    .monospacedDigit()
                    .foregroundColor(appTheme.successColor)
            }
            if let caption = caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundColor(appTheme.warningColor)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(uiColor: .systemBackground))
                .overlay(RoundedRectangle(cornerRadius: 30).fill(dilimDegisti ? appTheme.warningColor.opacity(0.12) : Color.clear))
                .shadow(color: .black.opacity(appTheme.isLight ? 0.08 : 0.2), radius: 16, x: 0, y: 6)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            seciliAylikDetay = detay
        }
    }
    
    // MARK: - Detay Tablosu Butonu (Sheet tetikleyici)
    private var detayTablosuButonu: some View {
        Button {
            detayTabloAcik = true
        } label: {
            HStack {
                Image(systemName: "tablecells.fill")
                    .foregroundColor(appTheme.primaryAccent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Aylık Detay Tablosu")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(appTheme.textPrimary)
                    Text("Vergi dilimleri ve kesinti detaylarını gör")
                        .font(.caption2)
                        .foregroundColor(appTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.footnote)
                    .foregroundColor(appTheme.warningColor)
            }
            .padding(20)
            .background(appTheme.cardBackground)
            .cornerRadius(20)
            .cardShadow(theme: appTheme)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $detayTabloAcik) {
            FullDetayTableView(detaylar: gosterilenDetaylar, yil: yil)
                .environmentObject(appTheme)
        }
    }
    
    private var pdfExportButonu: some View {
        Button {
            pdfData = BrutNetPdfOlusturucu.olustur(detaylar: gosterilenDetaylar, yil: yil, baslik: "Bordro Özeti")
            showPdfShare = true
        } label: {
            Label("Bordro Özeti PDF", systemImage: "square.and.arrow.up")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle(color: appTheme.warningColor))
        .accessibilityLabel("Bordro Özeti PDF")
        .accessibilityHint("Bordro analizini PDF olarak paylaşır")
        .padding(.top, 8)
    }
}

// MARK: - FullDetayTableView (Sheet: tam ekran bordro detay tablosu)
struct FullDetayTableView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appTheme: AppTheme
    let detaylar: [AylikBrutNetDetay]
    let yil: Int

    var body: some View {
        NavigationStack {
            ZStack {
                appTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(appTheme.primaryAccent)
                        Text("Tabloyu sağa kaydırarak tüm detayları inceleyebilirsiniz.")
                            .font(.caption)
                            .foregroundColor(appTheme.textSecondary)
                        Spacer()
                    }
                    .padding()
                    .background(appTheme.primaryAccent.opacity(0.1))

                    BrutNetDetayTablosu(detaylar: detaylar, yil: yil)
                        .padding(.top, 10)
                }
            }
            .navigationTitle("\(yil) Bordro Detayları")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(appTheme.warningColor)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Özet Kart (Premium 30pt)
struct OzetKart: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @EnvironmentObject var appTheme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(AppTypography.headline)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(appTheme.textSecondary)
            }
            Text(value)
                .font(AppTypography.amountMedium)
                .monospacedDigit()
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(appTheme.isLight ? 0.08 : 0.2), radius: 16, x: 0, y: 6)
        )
    }
}

// MARK: - Aylık Net Satır (Premium kart)
struct AylikNetRow: View {
    let maas: AylikMaas
    @EnvironmentObject var appTheme: AppTheme

    var body: some View {
        HStack(spacing: 16) {
            Text(Aylar.isim(ay: maas.ay))
                .font(AppTypography.headline)
                .foregroundColor(appTheme.textPrimary)
                .frame(width: 70, alignment: .leading)
            Text(maas.primTutar > 0 ? "\(formatCurrency(maas.brutTutar)) + \(formatCurrency(maas.primTutar))" : formatCurrency(maas.brutTutar))
                .font(.caption)
                .monospacedDigit()
                .foregroundColor(appTheme.textSecondary)
            Spacer()
            Text(formatCurrency(maas.netTutar))
                .font(AppTypography.amountSmall)
                .monospacedDigit()
                .foregroundColor(appTheme.successColor)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(appTheme.isLight ? 0.08 : 0.2), radius: 16, x: 0, y: 6)
        )
    }
}

// MARK: - Maaş Giriş Sheet
struct MaasGirisSheetView: View {
    @EnvironmentObject var appTheme: AppTheme
    @Environment(\.dismiss) var dismiss
    let yil: Int
    let mevcutMaaslar: [AylikMaas]
    let onSaveMaas: (AylikMaas) -> Void
    let onTamam: () -> Void
    
    /// Brüt: fill-down — ay N güncellenince N ve sonrası yeni değeri alır. Prim: ay bazlı.
    @State private var brutlar: [String] = Array(repeating: "", count: 12)
    @State private var primler: [String] = Array(repeating: "", count: 12)
    @State private var triggerBrutFocus: [Bool] = Array(repeating: false, count: 12)
    @State private var triggerPrimFocus: [Bool] = Array(repeating: false, count: 12)
    
    var body: some View {
        NavigationStack {
            ZStack {
                appTheme.background
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Üç sütun başlık: Ay | Brüt | Prim
                        HStack(spacing: 12) {
                            Text("Ay")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(appTheme.textSecondary)
                                .frame(width: 70, alignment: .leading)
                            Text("Brüt (₺)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(appTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text("Prim (₺)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(appTheme.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        
                        ForEach(1...12, id: \.self) { ay in
                            HStack(spacing: 12) {
                                Text(Aylar.isim(ay: ay))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(appTheme.textPrimary)
                                    .frame(width: 70, alignment: .leading)
                                
                                FormattedNumberField(
                                    text: bindingBrutForAy(ay),
                                    placeholder: "0",
                                    allowDecimals: false,
                                    focusTrigger: Binding(
                                        get: { triggerBrutFocus.indices.contains(ay - 1) ? triggerBrutFocus[ay - 1] : false },
                                        set: { if triggerBrutFocus.indices.contains(ay - 1) { triggerBrutFocus[ay - 1] = $0 } }
                                    ),
                                    isLightMode: appTheme.isLight
                                )
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(appTheme.cardBackgroundSecondary)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture { triggerBrutFocus[ay - 1] = true }
                                
                                FormattedNumberField(
                                    text: bindingPrimForAy(ay),
                                    placeholder: "0",
                                    allowDecimals: false,
                                    focusTrigger: Binding(
                                        get: { triggerPrimFocus.indices.contains(ay - 1) ? triggerPrimFocus[ay - 1] : false },
                                        set: { if triggerPrimFocus.indices.contains(ay - 1) { triggerPrimFocus[ay - 1] = $0 } }
                                    ),
                                    isLightMode: appTheme.isLight
                                )
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(appTheme.cardBackgroundSecondary)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(appTheme.cardStroke.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture { triggerPrimFocus[ay - 1] = true }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(AppSpacing.xxl)
                }
            }
            .navigationTitle("Brütten Nete ve Prim Hesaplama")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(appTheme.isLight ? .light : .dark, for: .navigationBar)
            .toolbarBackground(appTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                    .foregroundColor(appTheme.neutralSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") {
                        kaydetVeKapat()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(appTheme.warningColor)
                }
            }
        }
        .onAppear {
            // Her açılışta boş form — eski veriler yüklensin istemiyoruz
        }
    }
    
    /// Brüt: ay N'ye yazınca N ve sonrası aylar aynı değeri alır (fill-down).
    private func bindingBrutForAy(_ ay: Int) -> Binding<String> {
        let idx = ay - 1
        return Binding(
            get: { brutlar[idx] },
            set: { newValue in
                for i in idx..<12 { brutlar[i] = newValue }
            }
        )
    }
    
    private func bindingPrimForAy(_ ay: Int) -> Binding<String> {
        Binding(
            get: { primler[ay - 1] },
            set: { primler[ay - 1] = $0 }
        )
    }
    
    private func kaydetVeKapat() {
        var brutListesi: [Double] = []
        for i in 0..<12 {
            brutListesi.append(parseFormattedNumber(brutlar[i]) ?? 0)
        }
        var primListesi: [Double] = []
        for i in 0..<12 {
            primListesi.append(parseFormattedNumber(primler[i]) ?? 0)
        }
        let sonBrutlar = brutListesi
        
        if sonBrutlar.contains(where: { $0 > 0 }) {
            let sonuclar = BrutNetCalculator.hesaplaYillik(brutlar: sonBrutlar, primler: primListesi)
            for (index, sonuc) in sonuclar.enumerated() {
                let ay = index + 1
                let brut = sonBrutlar[index]
                let prim = primListesi[index]
                let kesintiCodable = sonuc.kesintiler.map { KesintiKalemCodable(ad: $0.ad, tutar: $0.tutar, oran: $0.oran) }
                let maas = AylikMaas(ay: ay, brutTutar: brut, primTutar: prim, netTutar: sonuc.net, kesintiler: kesintiCodable, yil: yil)
                onSaveMaas(maas)
            }
        }
        onTamam()
        dismiss()
    }
}

// MARK: - BrutNetDetayTablosu (Geniş Hücreler)
struct BrutNetDetayTablosu: View {
    let detaylar: [AylikBrutNetDetay]
    let yil: Int
    @EnvironmentObject var appTheme: AppTheme

    private let sutunGenislikleri: [CGFloat] = [
        45,   // Ay
        120,  // Brüt+Prim
        100,  // SSK İşçi
        90,   // İşsizlik
        130,  // G.V. Matrahı
        105,  // Gelir Ver.
        95,   // Damga V.
        140   // Net Ele Geçen
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                // Header Row
                HStack(spacing: 0) {
                    baslikHucresi("Ay", width: sutunGenislikleri[0], isLeading: true)
                    baslikHucresi("Brüt+Prim", width: sutunGenislikleri[1])
                    baslikHucresi("SSK İşçi", width: sutunGenislikleri[2])
                    baslikHucresi("İşsizlik", width: sutunGenislikleri[3])
                    baslikHucresi("G.V. Matrahı", width: sutunGenislikleri[4])
                    baslikHucresi("Gelir Ver.", width: sutunGenislikleri[5])
                    baslikHucresi("Damga V.", width: sutunGenislikleri[6])
                    baslikHucresi("Net Ele Geçen", width: sutunGenislikleri[7])
                }
                .padding(.vertical, 14)
                .background(appTheme.cardBackgroundSecondary)

                Divider()

                ForEach(detaylar.filter { $0.brutToplam > 0 }, id: \.ay) { d in
                    HStack(spacing: 0) {
                        veriHucresi(String(format: "%02d", d.ay), width: sutunGenislikleri[0], isLeading: true)
                        veriHucresi(formatCurrency(d.brutToplam, decimals: 2), width: sutunGenislikleri[1])
                        veriHucresi(formatCurrency(d.sgkIsci, decimals: 2), width: sutunGenislikleri[2], color: .red)
                        veriHucresi(formatCurrency(d.issizlikIsci, decimals: 2), width: sutunGenislikleri[3], color: .red)
                        veriHucresi(formatCurrency(d.netVergiOncesi, decimals: 2), width: sutunGenislikleri[4], color: .secondary)
                        veriHucresi(formatCurrency(d.aylikGelirVergisi, decimals: 2), width: sutunGenislikleri[5], color: .red)
                        veriHucresi(formatCurrency(d.damgaVergisi, decimals: 2), width: sutunGenislikleri[6], color: .red)
                        veriHucresi(formatCurrency(d.toplamNetEleGecen, decimals: 2), width: sutunGenislikleri[7], isBold: true, color: .green)
                    }
                    Divider()
                }

                toplamSatiri
            }
            .padding(.horizontal, 16)
        }
        .scrollIndicators(.visible)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func baslikHucresi(_ text: String, width: CGFloat, isLeading: Bool = false) -> some View {
        Text(text).font(.caption.weight(.bold)).foregroundColor(.secondary)
            .frame(width: width, alignment: isLeading ? .leading : .trailing)
            .padding(.horizontal, 4)
    }

    private func veriHucresi(_ text: String, width: CGFloat, isLeading: Bool = false, isBold: Bool = false, color: Color = .primary) -> some View {
        Text(text)
            .font(.system(size: 13, weight: isBold ? .bold : .medium, design: .monospaced))
            .foregroundColor(color)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(width: width, alignment: isLeading ? .leading : .trailing)
            .padding(.horizontal, 4)
            .padding(.vertical, 12)
    }

    @ViewBuilder
    private var toplamSatiri: some View {
        let filtrelenmis = detaylar.filter { $0.brutToplam > 0 }
        if !filtrelenmis.isEmpty {
            Divider()
            HStack(spacing: 0) {
                Text("TOPLAM")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(appTheme.warningColor)
                    .frame(width: sutunGenislikleri[0], alignment: .leading)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 12)
                veriHucresi(formatCurrency(filtrelenmis.reduce(0) { $0 + $1.brutToplam }, decimals: 2), width: sutunGenislikleri[1], color: appTheme.warningColor)
                veriHucresi(formatCurrency(filtrelenmis.reduce(0) { $0 + $1.sgkIsci }, decimals: 2), width: sutunGenislikleri[2], color: appTheme.warningColor)
                veriHucresi(formatCurrency(filtrelenmis.reduce(0) { $0 + $1.issizlikIsci }, decimals: 2), width: sutunGenislikleri[3], color: appTheme.warningColor)
                veriHucresi(formatCurrency(filtrelenmis.reduce(0) { $0 + $1.netVergiOncesi }, decimals: 2), width: sutunGenislikleri[4], color: appTheme.warningColor)
                veriHucresi(formatCurrency(filtrelenmis.reduce(0) { $0 + $1.aylikGelirVergisi }, decimals: 2), width: sutunGenislikleri[5], color: appTheme.warningColor)
                veriHucresi(formatCurrency(filtrelenmis.reduce(0) { $0 + $1.damgaVergisi }, decimals: 2), width: sutunGenislikleri[6], color: appTheme.warningColor)
                veriHucresi(formatCurrency(filtrelenmis.reduce(0) { $0 + $1.toplamNetEleGecen }, decimals: 2), width: sutunGenislikleri[7], isBold: true, color: appTheme.warningColor)
            }
            .padding(.vertical, 12)
            .background(appTheme.warningColor.opacity(0.15))
        }
    }
}

// MARK: - PDF Oluşturucu (Profesyonel bordro analiz raporu)
// MARK: - PDF Oluşturucu (Profesyonel Detaylı Bordro Analiz Raporu)
struct BrutNetPdfOlusturucu {
    private static let primaryBlue  = UIColor(red: 59/255,  green: 130/255, blue: 246/255, alpha: 1)
    private static let successGreen = UIColor(red: 16/255,  green: 185/255, blue: 129/255, alpha: 1)
    private static let warningAmber = UIColor(red: 245/255, green: 158/255, blue: 11/255,  alpha: 1)
    private static let dangerRed    = UIColor(red: 239/255, green: 68/255,  blue: 68/255,  alpha: 1)
    private static let textDark     = UIColor(red: 15/255,  green: 23/255,  blue: 42/255,  alpha: 1)
    private static let textGray     = UIColor(red: 100/255, green: 116/255, blue: 139/255, alpha: 1)
    private static let bgLight      = UIColor(red: 248/255, green: 250/255, blue: 252/255, alpha: 1)

    static func olustur(detaylar: [AylikBrutNetDetay], yil: Int, baslik: String? = nil) -> Data? {
        let aylik = detaylar.filter { $0.brutToplam > 0 }
        guard !aylik.isEmpty else { return nil }

        // A4 Landscape
        let pageWidth:  CGFloat = 842
        let pageHeight: CGFloat = 595
        let margin:     CGFloat = 30
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            bgLight.setFill()
            ctx.fill(pageRect)

            var currentY: CGFloat = margin

            // Başlık
            let titleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 22),
                .foregroundColor: textDark
            ]
            let subtitleAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: textGray
            ]
            (baslik ?? "Detaylı Bordro & Maliyet Analiz Raporu").draw(
                at: CGPoint(x: margin, y: currentY), withAttributes: titleAttr)
            currentY += 28
            "\(yil) Yılı Tüm Kesinti ve İstisna Detayları | Oluşturulma: \(Date().formatted(date: .long, time: .shortened))".draw(
                at: CGPoint(x: margin, y: currentY), withAttributes: subtitleAttr)
            currentY += 35

            // Özet Kartları
            let cardWidth  = (pageWidth - (margin * 2) - 32) / 3
            let cardHeight: CGFloat = 64

            let toplamNet     = aylik.reduce(0) { $0 + $1.toplamNetEleGecen }
            let toplamMaliyet = aylik.reduce(0) { $0 + $1.toplamMaliyet }
            let toplamKesinti = aylik.reduce(0) { $0 + $1.sgkIsci + $1.issizlikIsci + $1.aylikGelirVergisi + $1.damgaVergisi }

            drawSummaryCard(at: CGPoint(x: margin, y: currentY),
                width: cardWidth, height: cardHeight,
                title: "YILLIK TOPLAM NET", value: pdfFormatCurrency(toplamNet), color: successGreen)
            drawSummaryCard(at: CGPoint(x: margin + cardWidth + 16, y: currentY),
                width: cardWidth, height: cardHeight,
                title: "TOPLAM İŞVEREN MALİYETİ", value: pdfFormatCurrency(toplamMaliyet), color: warningAmber)
            drawSummaryCard(at: CGPoint(x: margin + (cardWidth + 16) * 2, y: currentY),
                width: cardWidth, height: cardHeight,
                title: "TOPLAM İŞÇİ KESİNTİSİ", value: pdfFormatCurrency(toplamKesinti), color: dangerRed)

            currentY += cardHeight + 30

            // 12 Sütunlu Tablo — toplam 772pt, kullanılabilir 782pt
            let headers: [String] = [
                "Ay", "Brüt Toplam", "SGK İşçi", "İşsz.İşçi", "Küm.Matrah",
                "Gelir Ver.", "Damga V.", "GV İstis.", "DV İstis.",
                "NET MAAŞ", "İşveren SGK", "Top.Maliyet"
            ]
            let colWidths: [CGFloat] = [32, 75, 62, 54, 75, 62, 54, 60, 54, 78, 76, 90]

            var currentX = margin

            // Tablo başlığı arka planı
            let headerRect = CGRect(x: margin, y: currentY, width: pageWidth - (margin * 2), height: 35)
            let headerPath = UIBezierPath(roundedRect: headerRect,
                byRoundingCorners: [.topLeft, .topRight],
                cornerRadii: CGSize(width: 8, height: 8))
            textDark.setFill()
            headerPath.fill()

            let headerTextAttr: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 9),
                .foregroundColor: UIColor.white
            ]
            for (i, h) in headers.enumerated() {
                let style = NSMutableParagraphStyle()
                style.alignment = i == 0 ? .left : .right
                let attr = headerTextAttr.merging([.paragraphStyle: style]) { $1 }
                h.draw(in: CGRect(x: currentX, y: currentY + 11, width: colWidths[i], height: 20).insetBy(dx: 4, dy: 0),
                       withAttributes: attr)
                currentX += colWidths[i]
            }
            currentY += 35

            let dataFont     = UIFont.monospacedDigitSystemFont(ofSize: 8.5, weight: .medium)
            let dataBoldFont = UIFont.monospacedDigitSystemFont(ofSize: 9,   weight: .bold)

            // Veri satırları
            for (index, d) in aylik.enumerated() {
                (index % 2 == 0 ? UIColor.white : UIColor(white: 0.96, alpha: 1)).setFill()
                ctx.fill(CGRect(x: margin, y: currentY, width: pageWidth - (margin * 2), height: 28))

                currentX = margin
                let isverenToplamSGK = d.sgkIsveren + d.issizlikIsveren
                let rowData: [String] = [
                    String(Aylar.isim(ay: d.ay).prefix(3)) + ".",   // Substring hatası düzeltildi
                    pdfFormatCurrency(d.brutToplam),
                    pdfFormatCurrency(d.sgkIsci),
                    pdfFormatCurrency(d.issizlikIsci),
                    pdfFormatCurrency(d.kumulatifVergiMatrahi),
                    pdfFormatCurrency(d.aylikGelirVergisi),
                    pdfFormatCurrency(d.damgaVergisi),
                    pdfFormatCurrency(d.asgariUcretGVIstisnasi),
                    pdfFormatCurrency(d.asgariUcretDVIstisnasi),
                    pdfFormatCurrency(d.toplamNetEleGecen),
                    pdfFormatCurrency(isverenToplamSGK),
                    pdfFormatCurrency(d.toplamMaliyet)
                ]

                for (i, val) in rowData.enumerated() {
                    let style = NSMutableParagraphStyle()
                    style.alignment = i == 0 ? .left : .right

                    var color: UIColor = textDark
                    var font  = dataFont
                    if i == 9 {                            // NET MAAŞ — yeşil + bold
                        color = successGreen; font = dataBoldFont
                    } else if (i >= 2 && i <= 6) && i != 4 { // Kesintiler — kırmızı
                        color = dangerRed
                    } else if i == 7 || i == 8 {           // İstisnalar — mavi
                        color = primaryBlue
                    } else if i == 11 {                    // Toplam Maliyet — amber + bold
                        color = warningAmber; font = dataBoldFont
                    }

                    val.draw(in: CGRect(x: currentX, y: currentY + 8, width: colWidths[i], height: 20).insetBy(dx: 4, dy: 0),
                             withAttributes: [.font: font, .foregroundColor: color, .paragraphStyle: style])
                    currentX += colWidths[i]
                }
                currentY += 28
            }

            // Toplam satırı
            let footerRect = CGRect(x: margin, y: currentY, width: pageWidth - (margin * 2), height: 35)
            warningAmber.withAlphaComponent(0.15).setFill()
            ctx.fill(footerRect)

            let toplamBrut      = aylik.reduce(0) { $0 + $1.brutToplam }
            let tSgkIsci        = aylik.reduce(0) { $0 + $1.sgkIsci }
            let tIssizlikIsci   = aylik.reduce(0) { $0 + $1.issizlikIsci }
            let tGv             = aylik.reduce(0) { $0 + $1.aylikGelirVergisi }
            let tDv             = aylik.reduce(0) { $0 + $1.damgaVergisi }
            let tGvIstisna      = aylik.reduce(0) { $0 + $1.asgariUcretGVIstisnasi }
            let tDvIstisna      = aylik.reduce(0) { $0 + $1.asgariUcretDVIstisnasi }
            let tSgkIsveren     = aylik.reduce(0) { $0 + $1.sgkIsveren + $1.issizlikIsveren }

            let footerData: [String] = [
                "TOPLAM",
                pdfFormatCurrency(toplamBrut),
                pdfFormatCurrency(tSgkIsci),
                pdfFormatCurrency(tIssizlikIsci),
                "",   // Kümülatif matrah toplanmaz
                pdfFormatCurrency(tGv),
                pdfFormatCurrency(tDv),
                pdfFormatCurrency(tGvIstisna),
                pdfFormatCurrency(tDvIstisna),
                pdfFormatCurrency(toplamNet),
                pdfFormatCurrency(tSgkIsveren),
                pdfFormatCurrency(toplamMaliyet)
            ]

            currentX = margin
            for (i, val) in footerData.enumerated() {
                guard !val.isEmpty else { currentX += colWidths[i]; continue }
                let style = NSMutableParagraphStyle()
                style.alignment = i == 0 ? .left : .right
                val.draw(
                    in: CGRect(x: currentX, y: currentY + 11, width: colWidths[i], height: 20).insetBy(dx: 4, dy: 0),
                    withAttributes: [
                        .font: UIFont.boldSystemFont(ofSize: 9.5),
                        .foregroundColor: textDark,
                        .paragraphStyle: style
                    ])
                currentX += colWidths[i]
            }
        }
    }

    private static func drawSummaryCard(at point: CGPoint, width: CGFloat, height: CGFloat,
                                        title: String, value: String, color: UIColor) {
        let rect = CGRect(origin: point, size: CGSize(width: width, height: height))
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 10)
        UIColor.white.setFill()
        path.fill()

        let stripe = UIBezierPath(
            roundedRect: CGRect(x: point.x, y: point.y, width: 5, height: height),
            byRoundingCorners: [.topLeft, .bottomLeft],
            cornerRadii: CGSize(width: 10, height: 10))
        color.setFill()
        stripe.fill()

        title.draw(
            in: CGRect(x: point.x + 14, y: point.y + 12, width: width - 18, height: 14),
            withAttributes: [.font: UIFont.systemFont(ofSize: 9, weight: .bold), .foregroundColor: textGray])
        value.draw(
            in: CGRect(x: point.x + 14, y: point.y + 30, width: width - 18, height: 24),
            withAttributes: [.font: UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .bold), .foregroundColor: color])
    }

    private static func pdfFormatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "0,00"
    }
}

// MARK: - PDF Paylaşım Sheet
struct PdfShareSheet: UIViewControllerRepresentable {
    let pdfData: Data
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("BrutNet_\(Date().timeIntervalSince1970).pdf")
        try? pdfData.write(to: tempURL)
        return UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Aylık Kesinti Detay Sheet (bordro kartı)
struct AylikKesintiDetaySheet: View {
    let detay: AylikBrutNetDetay
    @EnvironmentObject var appTheme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @State private var paylasimGoster = false
    @State private var kartGorsel: UIImage? = nil

    private var toplamIsciKesinti: Double {
        detay.sgkIsci + detay.issizlikIsci + detay.aylikGelirVergisi + detay.damgaVergisi
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    walletKarti
                        .padding(.horizontal, 16)

                    Text("Kartı paylaşmak için sağ üstteki paylaş ikonuna dokunun")
                        .font(.caption)
                        .foregroundColor(appTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Color.clear.frame(height: 20)
                }
                .padding(.top, 16)
            }
            .background(appTheme.backgroundMain.ignoresSafeArea())
            .navigationTitle("Aylık Bordro Kartı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(appTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if kartGorsel == nil { kartGorsel = renderKartGorsel() }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            paylasimGoster = true
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(appTheme.primaryAccent)
                    }
                }
            }
            .sheet(isPresented: $paylasimGoster) {
                if let gorsel = kartGorsel {
                    GoselPaylasSheet(gorsel: gorsel)
                }
            }
            .task { kartGorsel = renderKartGorsel() }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var walletKarti: some View {
        walletKartiForRender
    }

    private var walletKartiForRender: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color(hex: "0B1220"), Color(hex: "1a1f35")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 120)

                Circle()
                    .fill(Color(hex: "34D399").opacity(0.12))
                    .frame(width: 150).blur(radius: 30)
                    .offset(x: 240, y: 20)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "creditcard.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "34D399"))
                        Text("BORDRO KARTI")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(Color(hex: "34D399"))
                            .tracking(2)
                        Spacer()
                        Text("İK Pusula")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    Text("\(Aylar.isim(ay: detay.ay))")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(20)
            }

            VStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("NET ELE GEÇEN")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(Color(hex: "34D399").opacity(0.7))
                        .tracking(1.5)
                    Text(formatCurrencyCard(detay.toplamNetEleGecen))
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "34D399"))
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(hex: "0d1424"))

                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(height: 0.5)

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        bordroSatiri("Brüt Toplam", formatCurrencyCard(detay.brutToplam), renk: .white)
                        Rectangle().fill(Color.white.opacity(0.07)).frame(width: 0.5)
                        bordroSatiri("SGK İşçi", formatCurrencyCard(detay.sgkIsci), renk: Color(hex: "F87171"))
                    }
                    Rectangle().fill(Color.white.opacity(0.07)).frame(height: 0.5)
                    HStack(spacing: 0) {
                        bordroSatiri("Gelir Vergisi", formatCurrencyCard(detay.aylikGelirVergisi), renk: Color(hex: "FB923C"))
                        Rectangle().fill(Color.white.opacity(0.07)).frame(width: 0.5)
                        bordroSatiri("Damga Vergisi", formatCurrencyCard(detay.damgaVergisi), renk: Color(hex: "FB923C"))
                    }
                    Rectangle().fill(Color.white.opacity(0.07)).frame(height: 0.5)
                    HStack(spacing: 0) {
                        bordroSatiri("İşsizlik Fonu", formatCurrencyCard(detay.issizlikIsci), renk: Color(hex: "F87171"))
                        Rectangle().fill(Color.white.opacity(0.07)).frame(width: 0.5)
                        bordroSatiri("Toplam Kesinti", formatCurrencyCard(toplamIsciKesinti), renk: Color(hex: "F87171"), bold: true)
                    }
                    if detay.asgariUcretGVIstisnasi > 0 || detay.asgariUcretDVIstisnasi > 0 {
                        Rectangle().fill(Color.white.opacity(0.07)).frame(height: 0.5)
                        HStack(spacing: 0) {
                            bordroSatiri("GV İstisnası", "-" + formatCurrencyCard(detay.asgariUcretGVIstisnasi), renk: Color(hex: "34D399"))
                            Rectangle().fill(Color.white.opacity(0.07)).frame(width: 0.5)
                            bordroSatiri("DV İstisnası", "-" + formatCurrencyCard(detay.asgariUcretDVIstisnasi), renk: Color(hex: "34D399"))
                        }
                    }
                }
                .background(Color(hex: "0d1424"))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color(hex: "34D399").opacity(0.15), radius: 20, y: 8)
    }

    private func bordroSatiri(_ baslik: String, _ deger: String, renk: Color, bold: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(baslik)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.40))
                .tracking(0.5)
            Text(deger)
                .font(.system(size: 13, weight: bold ? .heavy : .semibold, design: .rounded))
                .foregroundColor(renk)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
    }

    private func formatCurrencyCard(_ val: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        return (f.string(from: NSNumber(value: val.rounded())) ?? "0") + " ₺"
    }

    private func renderKartGorsel() -> UIImage? {
        guard #available(iOS 16.0, *) else { return nil }
        let renderer = ImageRenderer(
            content: walletKartiForRender
                .frame(width: 390, height: 420)
                .background(Color(hex: "090f1d"))
        )
        renderer.scale = 3.0
        return renderer.uiImage
    }
}

#Preview {
    NavigationStack {
        BrutNetView()
            .modelContainer(DataManager.previewContainer)
            .environmentObject(AppTheme())
    }
}
