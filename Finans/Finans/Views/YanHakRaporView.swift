import SwiftUI

/// Yan Hak karşılaştırma dashboard'u — profesyonel, görsel karşılaştırmalı rapor.
/// Ücret grafiği, KPI kartları, yan hak kıyaslamaları ve AI yorumu.
/// embedded: true ise NavigationStack/dismiss yok, aynı akışta gösterilir.
struct YanHakRaporView: View {
    @EnvironmentObject var appTheme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @AppStorage("gemini_api_key") private var geminiAPIKey = "AIzaSyCJdtERkLNrG2DBUSCU5FwEGqdrJEue5ew"
    
    let mevcutIs: YanHakVerisi
    let teklif: YanHakVerisi
    var embedded: Bool = false
    
    @State private var aiYorumText: String?
    @State private var aiYorumHata: String?
    @State private var aiYorumLoading = false
    
    private let temaRengi = Color(hex: "F59E0B")
    private let mevcutRengi = Color(hex: "3B82F6")
    private let teklifRengi = Color(hex: "F59E0B")
    
    private var yillikFark: Double {
        teklif.yillikNetMaas - mevcutIs.yillikNetMaas
    }
    
    var body: some View {
        Group {
            if embedded {
                dashboardContent
            } else {
                NavigationStack {
                    dashboardContent
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Yan Hak Analizi")
                                .font(.headline)
                                .foregroundColor(appTheme.textPrimary)
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button { dismiss() } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(appTheme.textSecondary.opacity(0.8))
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if !geminiAPIKey.isEmpty, aiYorumText == nil, aiYorumHata == nil {
                Task { await aiYorumAl() }
            }
        }
    }
    
    private var dashboardContent: some View {
        let icerik = VStack(alignment: .leading, spacing: 28) {
            headerSection
            maasKarsilastirmaKarti
            primDahilYillikBarGrafigi
            kpiKartlari
            yanHakKarsilastirmalari
            aiYorumSection
        }
        .padding(24)
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(appTheme.background)
        
        return Group {
            if embedded {
                icerik
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    icerik
                }
                .frame(maxWidth: .infinity)
                .background(appTheme.background)
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("İş Teklifi Karşılaştırması")
                .font(.title2.weight(.bold))
                .foregroundColor(appTheme.textPrimary)
            Text("Mevcut iş yeriniz ile teklif edilen pozisyonun kapsamlı analizi")
                .font(.subheadline)
                .foregroundColor(appTheme.textSecondary.opacity(0.9))
        }
    }
    
    // MARK: - Maaş Karşılaştırma — Aylık Bazda Çizgi Grafik
    private var maasKarsilastirmaKarti: some View {
        let mevcutAylik = mevcutIs.aylikNetMaaslar
        let teklifAylik = teklif.aylikNetMaaslar
        let maxVal = max(mevcutAylik.max() ?? 0, teklifAylik.max() ?? 0) * 1.1
        let minVal: Double = 0
        let hasData = maxVal > 0
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title3)
                    .foregroundColor(temaRengi)
                Text("Aylık Net Maaş Karşılaştırması")
                    .font(.headline)
                    .foregroundColor(appTheme.textPrimary)
            }
            
            if hasData {
                maasCizgiGrafik(mevcut: mevcutAylik, teklif: teklifAylik, maxVal: maxVal)
                
                HStack(spacing: 24) {
                    HStack(spacing: 6) {
                        Circle().fill(mevcutRengi).frame(width: 8, height: 8)
                        Text("Mevcut İş").font(.caption).foregroundColor(appTheme.textSecondary)
                    }
                    HStack(spacing: 6) {
                        Circle().fill(teklifRengi).frame(width: 8, height: 8)
                        Text("Teklif").font(.caption).foregroundColor(appTheme.textSecondary)
                    }
                }
                
                Divider().background(appTheme.textSecondary.opacity(0.3))
                HStack {
                    Text("Yıllık fark")
                        .font(.subheadline)
                        .foregroundColor(appTheme.textSecondary)
                    Spacer()
                    Text(formatNumberGoster(yillikFark))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(yillikFark >= 0 ? Color(hex: "22C55E") : Color(hex: "EF4444"))
                    Text("₺/yıl")
                        .font(.caption)
                        .foregroundColor(appTheme.textSecondary)
                }
            } else {
                Text("Maaş bilgisi girildiğinde grafik burada görünecek.")
                    .font(.subheadline)
                    .foregroundColor(appTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(appTheme.listRowBackground)
                .shadow(color: .black.opacity(appTheme.isLight ? 0.06 : 0.2), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Prim Dahil Yıllık Toplam — Yatay Bar Grafik
    private var primDahilYillikBarGrafigi: some View {
        let mevcutToplam = mevcutIs.primDahilYillikToplam
        let teklifToplam = teklif.primDahilYillikToplam
        let maxVal = max(mevcutToplam, teklifToplam)
        let hasData = maxVal > 0
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.title3)
                    .foregroundColor(temaRengi)
                Text("Prim Dahil Yıllık Toplam")
                    .font(.headline)
                    .foregroundColor(appTheme.textPrimary)
            }
            
            if hasData {
                let barHeight: CGFloat = 28
                GeometryReader { geo in
                    let barAlaniGenislik = geo.size.width - 170
                    VStack(alignment: .leading, spacing: 20) {
                        yatayBarSatir(label: "Mevcut İş", deger: mevcutToplam, maxVal: maxVal, renk: mevcutRengi, barHeight: barHeight, barMaxW: barAlaniGenislik)
                        yatayBarSatir(label: "Teklif", deger: teklifToplam, maxVal: maxVal, renk: teklifRengi, barHeight: barHeight, barMaxW: barAlaniGenislik)
                    }
                }
                .frame(height: 100)
            } else {
                Text("Maaş bilgisi girildiğinde grafik burada görünecek.")
                    .font(.subheadline)
                    .foregroundColor(appTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(appTheme.listRowBackground)
                .shadow(color: .black.opacity(appTheme.isLight ? 0.06 : 0.2), radius: 12, x: 0, y: 4)
        )
    }
    
    private func yatayBarSatir(label: String, deger: Double, maxVal: Double, renk: Color, barHeight: CGFloat, barMaxW: CGFloat) -> some View {
        let fillW = maxVal > 0 ? max(8, barMaxW * CGFloat(deger / maxVal)) : CGFloat(0)
        return HStack(spacing: 10) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundColor(appTheme.textPrimary)
                .frame(width: 70, alignment: .leading)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(renk.opacity(0.2))
                    .frame(height: barHeight)
                RoundedRectangle(cornerRadius: 6)
                    .fill(renk)
                    .frame(width: fillW, height: barHeight)
            }
            .frame(maxWidth: .infinity)
            Text(formatNumberGoster(deger) + " ₺")
                .font(.caption.weight(.semibold))
                .foregroundColor(appTheme.textPrimary)
                .lineLimit(1)
                .frame(width: 80, alignment: .trailing)
        }
    }
    
    private func maasCizgiGrafik(mevcut: [Double], teklif: [Double], maxVal: Double) -> some View {
        let yAxisWidth: CGFloat = 44
        let xAxisHeight: CGFloat = 56
        let chartHeight: CGFloat = 180
        let chartPadding: CGFloat = 8
        
        return HStack(alignment: .top, spacing: 0) {
            // Y ekseni etiketleri
            VStack(alignment: .trailing, spacing: 0) {
                Text(formatKisaTutar(maxVal))
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(appTheme.textSecondary)
                Spacer()
                Text("0")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(appTheme.textSecondary)
            }
            .frame(width: yAxisWidth, height: chartHeight + xAxisHeight)
            .padding(.top, chartPadding)
            
            VStack(spacing: 0) {
                GeometryReader { geo in
                    let w = geo.size.width - chartPadding * 2
                    let h = chartHeight - chartPadding * 2
                    let stepX = w / CGFloat(max(1, 11))
                    
                    ZStack(alignment: .topLeading) {
                        // Grid çizgileri
                        ForEach(1..<4, id: \.self) { i in
                            let y = h * CGFloat(i) / 4
                            Path { p in
                                p.move(to: CGPoint(x: 0, y: y + chartPadding))
                                p.addLine(to: CGPoint(x: w + chartPadding * 2, y: y + chartPadding))
                            }
                            .stroke(appTheme.textSecondary.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        }
                        
                        // Mevcut İş çizgisi
                        if maxVal > 0 {
                            cizgiPath(values: mevcut, maxVal: maxVal, width: w, height: h, stepX: stepX, padding: chartPadding)
                                .stroke(mevcutRengi, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                            cizgiNoktalari(values: mevcut, maxVal: maxVal, width: w, height: h, stepX: stepX, padding: chartPadding, renk: mevcutRengi)
                        }
                        
                        // Teklif çizgisi
                        if maxVal > 0 {
                            cizgiPath(values: teklif, maxVal: maxVal, width: w, height: h, stepX: stepX, padding: chartPadding)
                                .stroke(teklifRengi, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                            cizgiNoktalari(values: teklif, maxVal: maxVal, width: w, height: h, stepX: stepX, padding: chartPadding, renk: teklifRengi)
                        }
                    }
                }
                .frame(height: chartHeight)
                
                // X ekseni — ay adları eğimli
                HStack(spacing: 0) {
                    ForEach(0..<12, id: \.self) { i in
                        Text(ayIsimleri[i])
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(appTheme.textSecondary)
                            .rotationEffect(.degrees(-45))
                            .frame(maxWidth: .infinity)
                            .fixedSize(horizontal: true, vertical: true)
                    }
                }
                .frame(height: xAxisHeight)
            }
        }
    }
    
    private func cizgiPath(values: [Double], maxVal: Double, width: CGFloat, height: CGFloat, stepX: CGFloat, padding: CGFloat) -> Path {
        var p = Path()
        guard maxVal > 0, !values.isEmpty else { return p }
        for (i, v) in values.enumerated() {
            let x = padding + CGFloat(i) * stepX
            let y = padding + height - (CGFloat(v / maxVal) * (height - padding * 2))
            if i == 0 {
                p.move(to: CGPoint(x: x, y: y))
            } else {
                p.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return p
    }
    
    private func cizgiNoktalari(values: [Double], maxVal: Double, width: CGFloat, height: CGFloat, stepX: CGFloat, padding: CGFloat, renk: Color) -> some View {
        Group {
            ForEach(0..<values.count, id: \.self) { i in
                let v = values[i]
                let x = padding + CGFloat(i) * stepX
                let y = padding + height - (CGFloat(v / maxVal) * (height - padding * 2))
                ZStack(alignment: .bottom) {
                    Circle()
                        .fill(renk)
                        .frame(width: 6, height: 6)
                    Text(formatNumberGoster(v))
                        .font(.system(size: 7, weight: .medium, design: .rounded))
                        .foregroundColor(appTheme.textPrimary)
                        .rotationEffect(.degrees(-45))
                        .offset(y: -18)
                }
                .position(x: x, y: y)
            }
        }
    }
    
    private func formatKisaTutar(_ d: Double) -> String {
        if d >= 1_000_000 { return String(format: "%.1fM", d / 1_000_000) }
        if d >= 1_000 { return String(format: "%.0fK", d / 1_000) }
        return formatNumberGoster(d)
    }
    
    // MARK: - KPI Kartları
    private var kpiKartlari: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            kpiKart(ikon: "banknote", baslik: "Yıllık Net", mevcut: mevcutIs.yillikNetMaas > 0 ? formatNumberGoster(mevcutIs.yillikNetMaas) + " ₺" : "—", teklif: teklif.yillikNetMaas > 0 ? formatNumberGoster(teklif.yillikNetMaas) + " ₺" : "—")
            kpiKart(ikon: "calendar", baslik: "Yılda Maaş", mevcut: "\(mevcutIs.maasPeriyodu)", teklif: "\(teklif.maasPeriyodu)")
            kpiKart(ikon: "sun.max", baslik: "Yıllık İzin", mevcut: mevcutIs.yillikIzinGunu.map { "\($0) gün" } ?? "—", teklif: teklif.yillikIzinGunu.map { "\($0) gün" } ?? "—")
            kpiKart(ikon: "building.2", baslik: "Çalışma", mevcut: mevcutIs.calismaModeli?.rawValue ?? "—", teklif: teklif.calismaModeli?.rawValue ?? "—")
            kpiKart(ikon: "gift", baslik: "Prim/Bonus", mevcut: mevcutIs.yillikPrimBonusTutar.map { formatNumberGoster($0) + " ₺" } ?? "—", teklif: teklif.yillikPrimBonusTutar.map { formatNumberGoster($0) + " ₺" } ?? "—")
            kpiKart(ikon: "clock", baslik: "Yolda Süre", mevcut: formatYoldaSure(mevcutIs), teklif: formatYoldaSure(teklif))
        }
    }
    
    private func kpiKart(ikon: String, baslik: String, mevcut: String, teklif: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: ikon)
                    .font(.subheadline)
                    .foregroundColor(temaRengi)
                Text(baslik)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(appTheme.textSecondary)
            }
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mevcut")
                        .font(.caption2)
                        .foregroundColor(appTheme.textSecondary)
                    Text(mevcut)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(appTheme.textPrimary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Rectangle()
                    .fill(appTheme.textSecondary.opacity(0.2))
                    .frame(width: 1, height: 28)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Teklif")
                        .font(.caption2)
                        .foregroundColor(appTheme.textSecondary)
                    Text(teklif)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(appTheme.textPrimary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(appTheme.listRowBackground)
        )
    }
    
    // MARK: - Yan Hak Karşılaştırmaları
    private var yanHakKarsilastirmalari: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Yan Haklar")
                .font(.headline)
                .foregroundColor(appTheme.textPrimary)
            
            yanHakSatir(ikon: "shield.checkered", baslik: "Sigorta", mevcut: formatSigorta(mevcutIs), teklif: formatSigorta(teklif))
            yanHakSatir(ikon: "fork.knife", baslik: "Yemek", mevcut: formatYemek(mevcutIs), teklif: formatYemek(teklif))
            yanHakSatir(ikon: "car.fill", baslik: "Ulaşım", mevcut: formatUlasim(mevcutIs), teklif: formatUlasim(teklif))
            yanHakSatir(ikon: "iphone", baslik: "Telefon", mevcut: mevcutIs.telefonVeriliyor ? "Evet" : "Hayır", teklif: teklif.telefonVeriliyor ? "Evet" : "Hayır")
            yanHakSatir(ikon: "wifi", baslik: "İnternet/Elektrik", mevcut: mevcutIs.internetElektrikDestekVar ? "\(formatNumberGoster(mevcutIs.internetElektrikToplamTutar ?? 0)) ₺/ay" : "Yok", teklif: teklif.internetElektrikDestekVar ? "\(formatNumberGoster(teklif.internetElektrikToplamTutar ?? 0)) ₺/ay" : "Yok")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(appTheme.listRowBackground)
                .shadow(color: .black.opacity(appTheme.isLight ? 0.06 : 0.2), radius: 12, x: 0, y: 4)
        )
    }
    
    private func yanHakSatir(ikon: String, baslik: String, mevcut: String, teklif: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: ikon)
                .font(.body)
                .foregroundColor(temaRengi)
                .frame(width: 28, alignment: .center)
            Text(baslik)
                .font(.subheadline.weight(.medium))
                .foregroundColor(appTheme.textPrimary)
                .frame(width: 100, alignment: .leading)
            HStack(spacing: 12) {
                Text(mevcut)
                    .font(.subheadline)
                    .foregroundColor(appTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .foregroundColor(appTheme.textSecondary.opacity(0.6))
                Text(teklif)
                    .font(.subheadline)
                    .foregroundColor(appTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatSigorta(_ d: YanHakVerisi) -> String {
        var p: [String] = []
        if d.tamamlayiciSaglikVar { p.append("Tamamlayıcı") }
        if d.ozelSaglikVar { p.append("Özel") }
        if d.gozDisDestegiVar { p.append("Göz/Diş") }
        return p.isEmpty ? "Yok" : p.joined(separator: ", ")
    }
    
    private func formatYemek(_ d: YanHakVerisi) -> String {
        switch d.yemekTipi {
        case .yemekhane: return "Yemekhane\(d.yemekhaneKalitePuan.map { " (\($0)/5)" } ?? "")"
        case .yemekKarti: return "Kart\(d.yemekKartiGunlukTutar.map { " \(formatNumberGoster($0)) ₺/gün" } ?? "")"
        case .none: return "Yok"
        }
    }
    
    private func formatUlasim(_ d: YanHakVerisi) -> String {
        guard let t = d.ulasimTipi else { return "—" }
        switch t {
        case .yolUcreti: return "Yol \(d.yolUcretiAylik.map { formatNumberGoster($0) + " ₺" } ?? "")"
        case .sirketAraci: return "Araç"
        case .servis: return "Servis"
        case .hicbiri: return "Yok"
        }
    }
    
    private func formatYoldaSure(_ d: YanHakVerisi) -> String {
        let s = d.yoldaSureSaat ?? 0
        let m = d.yoldaSureDakika ?? 0
        if s == 0 && m == 0 { return "—" }
        return "\(s) sa \(m) dk"
    }
    
    // MARK: - AI Yorum Bölümü
    private var aiYorumSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundColor(temaRengi)
                Text("AI Değerlendirmesi")
                    .font(.headline)
                    .foregroundColor(appTheme.textPrimary)
            }
            
            if aiYorumLoading {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(temaRengi)
                    Text("Analiz ediliyor...")
                        .font(.subheadline)
                        .foregroundColor(appTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(appTheme.textSecondary.opacity(0.3), lineWidth: 1)
                        .background(RoundedRectangle(cornerRadius: 16).fill(appTheme.listRowBackground.opacity(0.5)))
                )
            } else if let hata = aiYorumHata {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(hata)
                        .font(.subheadline)
                        .foregroundColor(appTheme.textSecondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.orange.opacity(0.1))
                )
            } else if let yorum = aiYorumText {
                Text(yorum)
                    .font(.body)
                    .foregroundColor(appTheme.textPrimary)
                    .lineSpacing(6)
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(appTheme.listRowBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(temaRengi.opacity(0.4), lineWidth: 1)
                            )
                    )
            } else if geminiAPIKey.isEmpty {
                Text("AI değerlendirmesi için Gemini API anahtarınızı kaydedin.")
                    .font(.subheadline)
                    .foregroundColor(appTheme.textSecondary)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(appTheme.listRowBackground.opacity(0.5))
                    )
            }
        }
    }
    
    private func aiYorumAl() async {
        aiYorumLoading = true
        aiYorumHata = nil
        aiYorumText = nil
        do {
            let yorum = try await GeminiService.shared.fetchYorum(mevcutIs: mevcutIs, teklif: teklif, apiKey: geminiAPIKey)
            await MainActor.run {
                aiYorumText = yorum
                aiYorumLoading = false
            }
        } catch {
            await MainActor.run {
                aiYorumHata = error.localizedDescription
                aiYorumLoading = false
            }
        }
    }
    
    private func formatNumberGoster(_ d: Double) -> String {
        guard d != 0 else { return "0" }
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.maximumFractionDigits = 0
        fmt.decimalSeparator = ","
        fmt.groupingSeparator = "."
        return fmt.string(from: NSNumber(value: d)) ?? "—"
    }
}
